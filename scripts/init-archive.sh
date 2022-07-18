#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


# Confirm that the path was passed and is a valid directory
rootOfArchive=${1:-}
if [ ! -d "$rootOfArchive" ]; then
    echo "usage: init-archive.sh /root/of/archive"
    exit 1
fi

cd "$rootOfArchive"

# -p = make parent directories as needed

mkdir -p '01 Personal/00 Records/00 Important Documents'
mkdir -p '01 Personal/00 Records/01 Error Messages'
mkdir -p '01 Personal/00 Records/02 Confirmation Messages'
mkdir -p '01 Personal/00 Records/10 Financial/00 Receipts'
mkdir -p '01 Personal/00 Records/11 Medical'
mkdir -p '01 Personal/11 Writing'
mkdir -p '01 Personal/99 Pictures/00 Pics of Me'

mkdir -p '02 School'
mkdir -p '03 Work'

mkdir -p '04 Projects/00 Playground'
mkdir -p '04 Projects/01 Experiments'

mkdir -p '05 Downloaded Files/Books'
mkdir -p '05 Downloaded Files/Documents/Lego Instructions'
mkdir -p '05 Downloaded Files/ISOs'
mkdir -p '05 Downloaded Files/Movies'
mkdir -p '05 Downloaded Files/Music'
mkdir -p '05 Downloaded Files/TV Shows'
mkdir -p '05 Downloaded Files/Websites'

mkdir -p '06 Backups/Sessions'

mkdir -p '07 Application Files/Calibre Library'
mkdir -p '07 Application Files/Zotero'

mkdir -p '99 Trash'

echo "set up Archive in $rootOfArchive!"
