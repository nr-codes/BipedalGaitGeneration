#!/usr/bin/env bash

help='release [-du] version [message]
\t -d delete tag
\t -u update tag to latest commit \

The two options \e[1mcannot\e[0m be used together.'

# parse options and args
while getopts ":hdu" option; do
    case $option in
        h) echo -e "$help"; exit 0;;
        d) delete=true;;
        u) update=true;;
    esac
done

shift $(( OPTIND - 1 ))

if [ -n "$delete" -a -n "$update" ]; then
    echo -e "release: \e[1mcannot\e[0m have both -d and -u."
    exit -1
fi

if [ -z "$1" ]; then
    echo -e "$help"
    exit 0
fi

ver="$1"
ver="${ver:1}"

if [ -z "$2" ]; then
    msg="new release"
else
    msg="$2"
fi

# get script directory, https://stackoverflow.com/questions/59895
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$dir/.."

# set version in notebooks
row='RowBox[{"VERSION", " ", "=", " ", "\\"\\<'
box='\\>\\""}]'
pat='[0-9]\+\.[0-9]\+\.[0-9]\+'
reg="$row$pat$box"
rep="$row$ver$box"
sed -i "s/$reg/$rep/" Installer.nb

# set version in package.json
sed -i "s/\"version\": \"$pat\"/\"version\": \"$ver\"/" GaitBrowser/package.json

# echo output
set -x

# push code
if [ -n "$delete" -o -n "$update" ]; then
    git tag -d v$ver
    git push origin --delete v$ver
fi

if [ -z "$delete" ]; then
    git commit -a
    git tag -a v$ver -m "$msg"
    git push origin v$ver
fi

# to delete
# git tag -d v0.0.0
# git push origin --delete v0.0.0
