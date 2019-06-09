#!/usr/bin/env bash
help=$(cat << 'EOF'
Usage: remove-backup [DIR...]

Remove all .bak files under DIR
EOF
)

if [[ $1 = -h || $1 = --help ]];then
   echo "$help"
   exit 0
fi

function remove_bak {
   [[ ! -d $1 ]] && return 0
   find "$1" -type f -name "*.bak"|xargs -i rm -rf '{}'
}

while [[ $# -gt 0 ]];do
    remove_bak "$1" || exit 1
    shift
done