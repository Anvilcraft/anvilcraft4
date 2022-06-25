#!/bin/bash
set -e

VERSION="0.1.0"
BUILDPATH="build/zip"

rm -rf $BUILDPATH || true
mkdir -p $BUILDPATH
cp -r overrides $BUILDPATH/minecraft
mkdir -p $BUILDPATH/minecraft/mods
cp mmc-pack.json $BUILDPATH
echo "InstanceType=OneSix" > $BUILDPATH/instance.cfg

cd $BUILDPATH/minecraft/mods
while read -r mod; do
    echo "Downloading $mod"
    curl -LO "$mod"
done <../../../../mods.txt
cd ../..

rm ../*.zip || true
zip -r "../ac4-$VERSION.zip" ./*
