#!/usr/bin/env bash
# lnbase DIR [FILES...]

if [[ $1 == -h || $1 == --help ]];then
    echo "Usage: lnbase DIR [FILES...]"
    echo ""
    echo "create symbolic link for FILES, the link name is the basename with suffix removed"
    exit 0
fi

dir=$1
shift
[[ ! -d $dir ]] && echo "directory '$dir' is empty or does not exist" >&2 && exit 1

while [[ $# -gt 0 ]];do
   file=$1
   [[ ! -f $file ]] && echo "file '$file' is not a file or does not exist" >&2 && exit 1
   basename=$(basename "$file")
   # remvoe .* suffix
   basename=${basename%.*}
   fullFrom=$(realpath "$file") || exit
   fullLink=$dir/$basename
   ln -s "$fullFrom" "$fullLink" || exit
   shift
done