#!/usr/bin/env bash

# get latest version number
ver=$(git tag | tail -1)
ver="${ver:1}"

# get script directory, https://stackoverflow.com/questions/59895
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$dir"

# remove previous packages
rm -f BipedalGaitGeneration*.zip GaitBrowser-*

cd ../

# create documentation
echo "The content in this directory contains a video showing animations of" \
     "all gaits presented in the figures of the paper as well as the source" \
     "code for computing walking gaits from equilibria using numerical" \
     "continuation methods.  Further information can be found in the" \
     "README.txt file." > SUMMARY.txt 

asciidoctor -a html_compact -a revnumber=v$ver README.adoc

w3m -dump -o display_charset=latin1 README.html > README.txt

# set version in notebooks
row='RowBox[{"VERSION", " ", "=", " ", "\\"\\<'
box='\\>\\""}]'
reg="$row[0-9]\+\.[0-9]\+\.[0-9]\+$box"
rep="$row$ver$box"
sed -i "s/$reg/$rep/" Installer.nb

# create downloadable archives
math="BipedalGaitGeneration-Mathematica-$ver.zip"
node="BipedalGaitGeneration-Node.js-$ver.zip"

zip -9 $math \
    README.txt \
    SUMMARY.txt \
    COPYING.txt \
    Installer.nb \
    RunModels.nb \
    BipedalGaitGeneration.mp4 \
    Figures \
    Models \
    SIMple \
    GaitBrowser/src/bipeds \
    GaitBrowser/app/imgs/*/*.png \
    -x \
    \*.gitignore

zip -r9 $math \
    Models \
    SIMple \
    -x \
    Models/\*/\*CompiledFunctions 

zip -r9 $node \
    GaitBrowser \
    -x \
    GaitBrowser/exe \
    GaitBrowser/node_modules \
    GaitBrowser/app/imgs \
    GaitBrowser/app/vids \
    GaitBrowser/app/bin \
    GaitBrowser/app/bipeds \
    GaitBrowser/app/bundle.js \
    GaitBrowser/package-lock.json

cp $math ../TRO

mv $math $node $dir

rm README.html README.txt SUMMARY.txt

# create executable web app
cd ./GaitBrowser/

rm -rf exe/
npm i
npm run build
npm run pkg-all

for f in exe/*
do
    [ -e "$f" ] || continue
    base="${f##*/}-x64"
    ext=""
    if [[ "$f" == *.* ]]; then
        ext=".${f##*.}"
    fi

    mv "$f" "$dir/$base-$ver$ext"
done


rm -rf exe/ node_modules/ package-lock.json app/bipeds app/bundle.js

cd ../
