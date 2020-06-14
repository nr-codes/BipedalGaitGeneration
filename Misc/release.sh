#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo 'enter release version'
    exit;
fi

# get latest version number
ver="$1"
#ver=$(git tag | tail -1)
ver="${ver:1}"

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

git commit -a
git tag -a $ver -m "new release"
git push origin $ver
