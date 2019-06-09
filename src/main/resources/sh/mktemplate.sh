#!/bin/bash

help=$(cat <<'EOF'
Usage:  mktemplate OPTION TEMPLATE_FILE

Based on history input,remake a template with these input argument,but ask only keys not yet set

OPTIONs:

    -h --help                      help
    -i --input-file                input history file(default .input)
    -p --pass-set                  only set these not set(default behavior is to ask every variable's input)
    -s --select KEYS               select keys to edit,if KEYS is a hyphen(-) or empty,then a menu is popup for selection
    -D    KEY=VALUE                define key with value,this will override default input file.If this option is used with -p,all options are set automatically,you can use -l to test which keys should be set.Note:this option may be specified multiple times
    -l --list                      list all required keys, keys that are set and keys that are not set
    -W --with-keys KEYS            tell which keys are to be set,by default mktemplate will read the first line of the target template file,get the '## required:' head to retrieve key information.Set this option to '' may let you have an overview of the target template.
Note: this program utilizes the Apache Velocity as backend template engine,so related java environment should be correctly set.The default java program on that path is firstly found will be used.
    -o  --output FILE              write output to  FILE,if not specified,write it to stdout
        --smart-base DIR           base directory used to store the generated file
        --smart-file-key KEY       select a key to automatically determine the output file
        --smart-type TYPE          smart file type, available TYPE: java.If not set,guess based on the --smart-file-key.If it is CLASS_NAME, then it is considered java;if it is MAPPER_CLASS_NAME,then it is considered mapper;else none
    -f  --force                    force overriding existing files

Environments:
    VELOCITY_TEMPLATE_ROOT   a list of comma separated root path of velocity template(default current path)
    VELOCITEE_MAIN_JAR       path to the main velocitee executable jar
EOF
)
shortOpt=hi:ps:D:lW:o:f
# must start with space
longOpt=" help input-file: pass-set select: list with-keys: output: smart-base: smart-file-key: smart-type: force"
function info {
    echo "$1" >&2
}
function check_required_options {
    [[ ! -f $VELOCITEE_MAIN_JAR ]] && info "requires VELOCITEE_MAIN_JAR" && return 1
    if [[ -z $VELOCITY_TEMPLATE_ROOT ]];then
        $VELOCITY_TEMPLATE_ROOT=.
    fi
    [[ ! -d $VELOCITY_TEMPLATE_ROOT ]] && info "requires VELOCITY_TEMPLATE_ROOT exists" && return 1
    return 0
}
args=$(getopt -o "$shortOpt" ${longOpt// / -l } -- "$@") || exit
eval "set -- $args"

# arg for this template
declare -A argMap
# arg from input file
declare -A inputArgMap
inputFile=.input
passSet=no
selectKeys=
let cmdPropIdx=0
declare -a cmdProp
doList=no
requiredParamsIsSet=no
OUTPUT= SMART_BASE=. SMART_FILE_KEY= SMART_TYPE= OUTPUT_MODE= FORCE=no
while true;do
  case $1 in
    -h|--help)
      echo "$help"
      exit 0
      ;;
    -i|--input-file)
    inputFile=$2
    shift 2
    ;;
   -p|--pass-set)
     passSet=yes
     shift
     ;;
   -s|--select)
     selectKeys=${2:--}
     shift 2
     ;;
    -D)
     cmdProp[$((cmdPropIdx++))]=$2
     shift 2
    ;;
    -l|--list)
    doList=yes
    shift
    ;;
    -W|--with-keys)
    requiredParams=(${2//,/ })
    requiredParamsIsSet=yes
    shift 2
    ;;
    -o|--output) OUTPUT=$(cygpath "$2");OUTPUT_MODE=output; shift 2;;
    --smart-base) SMART_BASE=$2;shift 2;;
    --smart-file-key) SMART_FILE_KEY=$2;OUTPUT_MODE=smart;shift 2;;
    --smart-type) SMART_TYPE=$2;shift 2;;
    --force|-f) FORCE=yes;shift;;
     --)shift;break;;
   esac
done

check_required_options || exit 1


function ensure_file_exists {
   [[ -z $1 ]] && return 1
   if [[ ! -f $1 ]];then
       { mkdir -p "$(dirname "$1")" && touch "$1" ;} || return 1
   fi
   return 0
}
ensure_file_exists "$inputFile" || { info "input-file:$inputFile does not exist"  ;exit 1;}

function array_contains {
  [[ -z $1 ]] && return 1
  eval "for tmp_array_contains_I in \"\${$1[@]}\";do if [[ \$tmp_array_contains_I = \$2 ]];then return 0;fi;done"
  return 1
}

templateFile=$1

[[ -z $templateFile ]] && info "requires template file" && exit 1

if [[ $templateFile = '-' || ! -f $templateFile ]];then
   info "$templateFile does not exist or is invalid"
   exit 1
fi


# auto detect
if [[ $requiredParamsIsSet = no ]];then
    firstLine=$(head -n1 "$templateFile") || exit

    if [[ ! $firstLine =~ ^##\ *required?\ *:\ * ]];then
        info "no '##required:' meta info in first line of file $templateFile"
        exit 1
    fi

    #delete *:
    metaInfo=${firstLine#*:}
    #delete any space
    #metaInfo=${metaInfo// /}
    #replace ',' with space
    metaInfo=${metaInfo//,/ }

    requiredParams=($metaInfo)
fi

# assign default value
function read_input_arg {
    while read line;do
        if [[ $line =~ ^\ *# || $line = ^\ *$ ]];then
           continue
        fi
        local key=${line%%=*}
        local value=${line#*=}
        inputArgMap[$key]=$value
        if ! array_contains requiredParams "$key";then continue;fi
        if [[ ${argMap[$key]+IS_SET} = IS_SET ]];then continue;fi
        argMap[$key]=$value
    done < "$inputFile"
}

function set_arg_from_cmdline {
    for i in "${cmdProp[@]}";do
            local key=${i%%=*}
            local value=${i#*=}
            if ! array_contains requiredParams "$key";then continue;fi
            argMap[$key]=$value
    done
}

# read, assign value read from cmd line
read_input_arg
set_arg_from_cmdline

declare -a presentKeys
declare -a notPresentKeys
let j=0
let k=0
for i in "${requiredParams[@]}";do
   if [[ ${argMap[$i]+IS_SET} = IS_SET ]];then
      presentKeys[$((j++))]=$i
   else
      notPresentKeys[$((k++))]=$i
   fi
done


function save_input_arg {
    echo -n '' > "$inputFile"
    for i in "${!inputArgMap[@]}";do
        echo "$i=${inputArgMap[$i]}" >> "$inputFile"
    done
}


function read_arg {
   [[ -z $1 ]] && return
   local defaultValue=${argMap[$1]}
   local prompt="Input $1${defaultValue:+(default $defaultValue)}:"
   read -p "$prompt" argMap[$1]
   : ${argMap[$1]:=$defaultValue}
   inputArgMap[$1]=${argMap[$1]}
}

if [[ $doList =  yes ]];then
    echo "Total Keys: ${#requiredParams[@]}  Set Keys:${#presentKeys[@]}  Not Set Keys:${#notPresentKeys[@]}"
    echo "Required keys:${requiredParams[@]}"
    echo "Value Set:"
    for i in "${presentKeys[@]}";do
      echo "    $i = ${argMap[$i]}"
    done
    if [[ ${#notPresentKeys[@]} -gt 0 ]];then
        echo  "Value Not Set:${notPresentKeys[@]}"
    fi
    exit
fi

# based on mode
if [[ -n $selectKeys ]];then
   if [[ $selectKeys == '-' ]];then
      info "Value Set:"
      for i in "${presentKeys[@]}";do
          info "    $i = ${argMap[$i]}"
      done
      info  "Value Not Set:${notPresentKeys[@]}"
      info "Now,select a key to edit:"
      select key in '--NOT SET--' "${notPresentKeys[@]}" '--SET--' "${presentKeys[@]}" '--End--';do
          if [[ $key = '--End--' ]];then break;fi
          if [[ $key =~ ^-- ]];then continue;fi
          read_arg "$key"
      done
   else
       for i in "${presentKeys[@]}";do
           info "set $i = ${argMap[$i]}"
       done
       declare -a selectKeyArr
       selectKeyArr=(${selectKeys//,/ })
       for i in "${selectKeyArr[@]}";do
           read_arg "$i"
       done
   fi
else
    info "Required keys:${requiredParams[@]}"
    for i in "${requiredParams[@]}";do
       if [[ $passSet = yes && ${argMap[$i]+IS_SET} = IS_SET ]];then
          info "set $i = ${argMap[$i]}"
       else
         read_arg "$i"
       fi
    done
fi


save_input_arg
info "-----------------"

declare -a argArr
let j=0
for i in "${!argMap[@]}";do
    argArr[$((j++))]="$i=${argMap[$i]}"
done

function check_redirect_to_file {
   [[ -z $1 ]] && return 1
   mkdir -p "$(dirname "$1")" || return
   if [[ -e $1 ]];then
      if [[ $FORCE = no ]];then
          info "file $1 already exists"
           return 1
      fi
   fi
   info "Write to file $1"
   exec >"$1"
}

if [[ -z $OUTPUT_MODE || $OUTPUT_MODE = output ]];then
    if [[ -n $OUTPUT ]];then
        check_redirect_to_file "$OUTPUT" || exit
    fi
elif [[ $OUTPUT_MODE = smart ]];then
   [[ -z $SMART_FILE_KEY ]] && info "--smart-file-key cannot be null" && exit 1
   fileKeyValue=${argMap[$SMART_FILE_KEY]}
   [[ -z $fileKeyValue ]] && info "value of '$SMART_FILE_KEY' cannot null" && exit 1
   if [[ -z $SMART_TYPE ]];then
      if [[ $SMART_FILE_KEY = CLASS_NAME ]];then
          SMART_TYPE=java
      elif [[ $SMART_FILE_KEY = MAPPER_CLASS_NAME ]];then
         SMART_TYPE=mapper
       fi
   fi
   [[ -z $SMART_TYPE ]] && info "cannot determine --smart-type" && exit 1
   outputFile=
   if [[ $SMART_TYPE = java ]];then
       outputFile=${fileKeyValue//.//}.java
   elif [[ $SMART_TYPE = mapper ]];then
       outputFile=${fileKeyValue//.//}.xml
   fi
   [[ -z $outputFile ]] && info "cannot determine outputFile for --smart-type:'$SMART_TYPE'" && exit 1
   fullFile=$SMART_BASE/$outputFile
   check_redirect_to_file "$fullFile" || exit
fi
java -Dfile.resource.loader.path="$VELOCITY_TEMPLATE_ROOT" -jar "$VELOCITEE_MAIN_JAR" template "$templateFile" "${argArr[@]}"
