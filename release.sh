#!/bin/sh

if [ "$#" -ne 2 ]; then
    echo "Usage: release <target> <version>"
    exit 1
fi

cd build

zip -r ../super-tux-party-linux-64.zip plugins supertuxparty supertuxparty.pck

zip -r ../super-tux-party-windows-64.zip plugins Supertuxparty.exe Supertuxparty.pck

mkdir tmp
cd tmp
unzip ../supertuxparty.app
cp -r ../plugins Super\ Tux\ Party.app/Contents/Resources/plugins
zip -r ../../super-tux-party-osx-64.zip Super\ Tux\ Party.app
cd ..
rm -rf tmp
cd ..

butler push super-tux-party-linux-64.zip "$1":linux-64 --userversion="$2"
butler push super-tux-party-windows-64.zip "$1":windows-64 --userversion="$2"
butler push super-tux-party-osx-64.zip "$1":osx-64 --userversion="$2"
butler push super-tux-party-sources.zip "$1":sources --userversion="$2"

