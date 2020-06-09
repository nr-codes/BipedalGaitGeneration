#!/bin/bash

cd ../

# create documentation
echo "The content in this directory contains a video showing animations of all gaits presented in the figures of the paper as well as the source code for computing walking gaits from equilibria using numerical continuation methods.  Further information can be found in the README.txt file." > SUMMARY.txt 

asciidoctor -a html_compact README.adoc

w3m -dump -o display_charset=latin1 README.html > README.txt

# create downloadable archives
ver=$(git tag | tail -1)
ver="${ver:1}"
math="BipedalGaitGeneration-Mathematica-$ver.zip"
node="BipedalGaitGeneration-Node.js-$ver.zip"

zip -9 $math \
    README.txt \
    SUMMARY.txt \
    COPYING.txt \
    RunMeFirst.nb \
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

zip -9 $node \
    GaitBrowser/app/imgs

zip -r9 $node \
    GaitBrowser \
    -x \
    GaitBrowser/app/imgs/\*

cp $math ../TRO

mv $math $node Release

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

    mv "$f" "../Release/$base$ext"
done


rm -rf exe/ node_modules/ package-lock.json

cd ../
