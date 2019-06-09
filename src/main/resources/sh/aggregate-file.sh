#!/usr/bin/env bash

shortHelp=$(cat <<'EOF'
Usage: aggregate-file OPTION

aggregate file(s) from different directories into a single directory,by using copy,soft link or hard link

OPTIONs:

  -h, --help               help, for detailed help, use --help
  -T, --change-to DIR      change target base directory for subsequent files(first directory is current directory)
  -F, --change-from DIR    change directory for subsequent files(first directory is current directory)
  -f, --file     FILE      the path of a file,relative to current directory,but should be a child file of directory denoted by latest -F option(without --restore) or -T(with --restore),when --restore is set and -R is used,if the target file is a directory,the -F option is replaced by .aggregate map file
  -r, --relative-file FILE the path of a file,similar with -f,but it is relative to  option denoted by latest -F option(without --restore) or -T(with --restore)

Options for file operation:

  -R, --use-record        if FILE is a directory,use .aggregate under that directory as record file mapping for create and restore.This is useful when -L does not work in some circumstances such as Intellij IDEA which forces hard link to new files due to unknown reason
      --force              force override files

Options for create:

  -L, --link-source        use hard link instead of copying files(cannot be used with --restore and -R/--with-record)
      --remove-source      for create, remove files after they are copied out(used without --restore,otherwise ignored)
      --backup-source      instead of remove source or leave resource,backup it with .bak appended

Options for restore:

     --restore            aggregate files back,without this option the behavior is to aggregate files into directory denoted by -T in their appearance order
 -I, --ignore-unrecord    if an entry cannot be found in the .aggregate file, it is not processed(used with --restore,otherwise ignored)
     --backup-target      for any files to be overridden,backup it firstly

All options that will not take effect are ignored
EOF
)
additionalHelp=$(cat << 'EOF'
Examples:

  # copy f1,f2,d1(assume d1 is a dir in B) under dir B to dir A,and save the record map
  $ aggregate-file -R -T A -F B -r f1 -r f2 -r d1
  $ cat A/.aggregate
  $ cat A/d1/.aggregate
  #
  # restore files copied using above command,that is, copy f1,f2 under A back to B
  $ mv B C
  $ aggregate-file -R -I --restore -T A -r .
  # B and C should report the same
  $ diff B C
  #
  # real world example(1):
  #    aggregate some modules to one module
  $ aggregate-file -R -T module-X -F module-A -r src/main/java -F module-B -r src/main/java -F module-C -r src/main/java
  # do some unified-view modification,and restore single file back
  $ aggregate-file --restore -R -T module-X -F module-B -f module-X/src/main/java/com/fulton_shaw/example/query/QueryModel.java
  # restore all back
  $ aggregate-file --restore -R -T module-X -r .
  #
  # real world example(2):
  #     create,and restore back
  #  note that in the following example, if --restore is set, the -r option is restored each for once.So if you specify the same file more that once, the target will be restored for multiple times.You should absolutely avoid this situation.
  $ aggregate-file -R -T module-X -F module-A -r src/main/java -F module-B -r src/main/java --remove-source
  $ aggregate-file -R -T module-X -r src/main/java --remove-source --restore

EOF
)
shortOpt=hT:F:f:r:LRI
# must start with space
longOpt=" help change-to: change-from: file: relative-file: force restore link-source use-record ignore-unrecord backup-target backup-source remove-source"
function info {
    echo "$1" >&2
}
args=$(getopt -o "$shortOpt" ${longOpt// / -l } -- "$@") || exit
eval "set -- $args"

let toIdx=0
let fromIdx=0
let fileIdx=0
declare -a toDirs
toDirs[$((toIdx++))]=.
declare -a files
# dirs
declare -a fromDirs
fromDirs[$((fromIdx++))]=.
# determine which file belongs to which directory
declare -a fileFromMap
declare -a fileToMap
let isRelativeIdx=0
declare -a IS_RELATIVE_MAP
FORCE=no RESTORE=no LINK_SOURCE=no USE_RECORD=no IGNORE_UNRECORD=no BACKUP_TARGET=no BACKUP_SOURCE=no REMOVE_SOURCE=no
while true;do
    case $1 in
     -h)
       echo "$shortHelp"
       exit 0
       ;;
     --help)
       echo "$shortHelp"
       echo ""
       echo "$additionalHelp"
       exit 0
     ;;
    -T|--change-to)
       toDirs[$((toIdx++))]=$(cygpath "$2")
       shift 2
    ;;
    -F|--change-from)
       fromDirs[$((fromIdx++))]=$(cygpath "$2")
       shift 2
    ;;
    -f|--file|-r|--relative-file)
       fileFromMap[$fileIdx]=$((fromIdx-1))
       fileToMap[$fileIdx]=$((toIdx-1))
       if [[ $1 = '-r' || $1 = '--relative-file' ]];then
            files[$fileIdx]=$2
           IS_RELATIVE_MAP[$fileIdx]=yes
       else
            files[$fileIdx]=$(cygpath "$2")
           IS_RELATIVE_MAP[$fileIdx]=no
       fi
       let fileIdx++
       shift 2
    ;;
    --force) FORCE=yes;shift;;
    --restore) RESTORE=yes;shift;;
    -L|--link-resource) LINK_SOURCE=yes;shift;;
    -R|--use-record) USE_RECORD=yes;shift;;
    -I|--ignore-unrecord) IGNORE_UNRECORD=yes;shift;;
    --backup-target) BACKUP_TARGET=yes;shift;;
    --backup-source) BACKUP_SOURCE=yes;shift;;
    --remove-source) REMOVE_SOURCE=yes;shift;;
    --)
    shift
    break
    ;;
    *)
     info "Unknown option:'$1'"
     exit 1
    ;;
    esac
done

# different mode, set for safety consideration
if [[ $RESTORE = yes ]];then
   LINK_SOURCE=no
   REMOVE_SOURCE=no
   BACKUP_SOURCE=no
else
    BACKUP_TARGET=no
   if [[ $LINK_SOURCE = yes ]];then
          USE_RECORD=no
   fi
    if [[ $BACKUP_SOURCE = yes && $REMOVE_SOURCE = yes ]];then
       info "cannot use --backup-source and --remove-source the same time"
       exit 1
    fi
fi

#######################
# read_record RECORD_MAP FILE
####################
function read_record {
 [[ -z $1 ]] && return 1
 unset "$1"
 declare -gA "$1"
 if [[ -f $2 ]];then
    while read tmp_read_record_LINE;do
        tmp_read_record_KEY=${tmp_read_record_LINE%% -> *}
        tmp_read_record_VALUE=${tmp_read_record_LINE#* -> }
        eval "$1[\$tmp_read_record_KEY]=\$tmp_read_record_VALUE"
    done < "$2"
 fi
}
######################
# save_record RECORD_MAP FILE
######################
function save_record {
   [[ -z $1 || -z $2 ]] && return 1
   mkdir -p "$(dirname "$2")" || return 1
   # remove file if empty
   eval "if [[ \${#$1[@]} -eq 0 ]];then rm -rf \"\$2\" >/dev/null 1>/dev/null;return 0;fi"
   echo -n '' > "$2"
   eval "for tmp_save_record_I in \"\${!$1[@]}\";do echo \"\$tmp_save_record_I -> \${$1[\$tmp_save_record_I]}\" >> \"\$2\";done"
}
#######################
# refresh_record TO_FILE FROM_FILE
#    refresh record file that the TO_FILE is copied from FROM_FILE
########################
function refresh_record {
   [[ -z $1 || -z $2 ]] && return 1
   basename=$(basename "$1")
   dirname=$(dirname "$1")
   recordFile=$dirname/.aggregate
   read_record recordMap "$recordFile" || exit
   recordMap[$basename]=$2
   save_record recordMap "$recordFile" || exit
}
#################
# backup_file FILE [move]
################
function backup_file {
  should_ignore_file "$1" && return 0
  [[ ! -f $1 ]] && return 0
  local let i=0
  local bakFile
  while true;do
     bakFile=$1.$i.bak
     [[ $i -eq 0 ]] && bakFile=$1.bak
     [[ ! -e $bakFile ]] && break
     let i++
  done
  if [[ $2 = move ]];then
      mv "$1" "$bakFile"
  else
     cp "$1" "$bakFile"
   fi
}
################
# sync_file FROM_FILE TO_FILE
################
function sync_file {
   mkdir -p "$(dirname "$2")" && sync_file_dir_existing "$1" "$2"
}
#####
# should file be ignored while process
######
function should_ignore_file {
   [[ -z $1 || $1 =~ \.bak$ ||  $1 = '.aggregate' || $1 = */.aggregate ]]
}
##############
# sync_file_dir_existing FROM_FILE TO_FILE
############
function sync_file_dir_existing {
   basename=$(basename "$1")
   should_ignore_file "$1" && return 0
   if [[ $RESTORE = yes ]];then
       if [[ $BACKUP_TARGET = yes ]];then backup_file "$2" || return 1;fi
       cp $CP_FLAGS "$1" "$2" || return 1
   else
        if [[ $LINK_SOURCE = yes ]];then
            ln "$1" "$2"
        else
            cp $CP_FLAGS "$1" "$2" || return 1
            if [[ $BACKUP_SOURCE = yes ]];then
              backup_file "$1" move || return 1
            elif [[ $REMOVE_SOURCE = yes ]];then
               rm -rf "$1" || return 1
            fi

       fi
   fi
   return 0
}

###################
# sync_dir  FROM TO
#   sync dir, and save records in TO
# must use -maxdepth and -mindepth to restrict find level， and filter . if necessary
###################
function sync_dir {
   mkdir -p "$2" || return 1
   pushd "$1" >/dev/null || return 1
   aggregateFile=$2/.aggregate
   if [[ $USE_RECORD = yes ]];then
      read_record recordMap "$aggregateFile" || return 1
   fi
   while read line;do
       [[ $line  = '.' ]] && continue
       line=${line#./}
       basename=$(basename "$line")
       sync_file_dir_existing "$basename" "$2/$basename" || return
       [[ $USE_RECORD = yes ]] &&   recordMap[$basename]=$1/$basename
   done < <(find . -mindepth 1 -maxdepth 1 -type f )
   if [[ $USE_RECORD = yes ]];then
        save_record recordMap "$aggregateFile" || return 1
   fi
   popd >/dev/null
   while read line;do
       [[ $line  = '.' ]] && continue
       line=${line#./}
       sync_dir "$1/$line" "$2/$line" || return 1
   done < <(cd "$1" && find . -maxdepth 1 -type d)

   return 0
}

##############
#  sync_dir_load_record FROM_DIR
#    the record is read from FROM_DIR/.aggregate
##############
function sync_dir_load_record {
   pushd "$1" >/dev/null || return 1
   aggregateFile=.aggregate
   read_record recordMap "$aggregateFile" || return 1
   while read line;do
       [[ $line  = '.' ]] && continue
       line=${line#./}
       basename=$(basename "$line")
       should_ignore_file "$basename" &&  continue
       fullToName=${recordMap[$basename]}
       [[ -z $fullToName ]] && {
         [[ $IGNORE_UNRECORD = yes ]] && continue;
         info "'$basename' in '$1' has no record"
         return 1
       }
       sync_file "$basename" "$fullToName" || exit
   done < <(find . -mindepth 1 -maxdepth 1 -type f )
   popd >/dev/null
   while read line;do
       [[ $line  = '.' ]] && continue
       line=${line#./}
       sync_dir_load_record "$1/$line"|| return 1
   done < <(cd "$1" && find . -mindepth 1 -maxdepth 1 -type d )

   return 0
}

CP_FLAGS=
[[ $FORCE = yes ]] && CP_FLAGS=-f
for((i=0;i<fileIdx;++i));do
    # ensure dir exists
    baseTo=${toDirs[${fileToMap[$i]}]}
    baseFrom=${fromDirs[${fileFromMap[$i]}]}
    if [[ $RESTORE = yes ]];then
      tmp=$baseFrom
      baseFrom=$baseTo
      baseTo=$tmp
    fi

    # to part
    mkdir -p "$baseTo" || exit
    fullBaseTo=$(realpath "$baseTo") || exit
    # from part
    fullBaseFrom=$(realpath "$baseFrom") || exit
    [[ $fullBaseFrom = $fullBaseTo ]] && continue
    # from part must exist
    [[ ! -e $fullBaseFrom ]] && echo "$baseFrom does not exist" && exit 1
    # the file
    file=${files[$i]}
    if [[ ${IS_RELATIVE_MAP[$i]} = yes ]];then
       realFile=$file
       file=$fullBaseFrom/$file
    else
       realFile=$(realpath --relative-base "$fullBaseFrom" "$file") || exit 1
    fi
    # check relative
    if [[ $realFile =~ ^/ ]];then
       info "relative file:'$file' for '$baseFrom' does not exist"
       exit 1
    fi

    # is a file,no need to ask record,we can reply it
    if [[ -f $file ]];then
        # ensure target file directory exist
        mkdir -p "$(dirname "$fullBaseTo/$realFile")" || exit
        sync_file_dir_existing  "$fullBaseFrom/$realFile" "$fullBaseTo/$realFile" || exit
        if [[ $RESTORE = no && $USE_RECORD = yes ]];then
           # to tracks from
           refresh_record "$fullBaseTo/$realFile" "$fullBaseFrom/$realFile" || exit
        fi
        continue
    fi

    # is a directory，we may need record
    if [[ -d  $file ]];then
       # find all files in FROM
       #  then copy or link them  to TO
       if [[ $RESTORE = yes && $USE_RECORD = yes ]];then
         sync_dir_load_record "$fullBaseFrom/$realFile" || exit
       else
         sync_dir "$fullBaseFrom/$realFile" "$fullBaseTo/$realFile" || exit
       fi
       continue
    fi

    # unknown file type
    info "file:'$file' does not exist, or is not file nor directory"
    exit 1
done