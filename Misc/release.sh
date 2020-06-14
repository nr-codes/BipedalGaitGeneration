#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo 'release version [message]'
    exit
fi

ver="$1"
ver="${ver:1}"

if [ -z "$2" ]; then
    msg="new release"
else
    msg="$2"
fi

# get latest version number
#ver=$(git tag | tail -1)

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

set -x
git tag -d v$ver
git push origin --delete v$ver
git commit -a
git push


git commit -a
git tag -a v$ver -m "$msg"
git push origin v$ver

# to delete
# git tag -d v0.0.0
# git push origin --delete v0.0.0
