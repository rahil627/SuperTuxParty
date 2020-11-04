#!/bin/sh -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: release <target> <version>"
    exit 1
fi

if [ "$1" != "release" ] &&  [ "$1" != "nightly" ]; then
	echo "target must be either 'release' or 'nightly'"
	exit 1
fi

finalize_build () {
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
}

finalize_build

ITCH_URL=supertuxparty/super-tux-party-nightly

if [ "$1" = "release" ]; then
	ITCH_URL=anti/super-tux-party
	curl --header "X-API-Token: $API_TOKEN"\
		 -F "data=@super-tux-party-linux-64.zip" https://supertux.party/upload/"$2"/linux
	curl --header "X-API-Token: $API_TOKEN"\
		 -F "data=@super-tux-party-windows-64.zip" https://supertux.party/upload/"$2"/windows
	curl --header "X-API-Token: $API_TOKEN"\
		 -F "data=@super-tux-party-osx-64.zip" https://supertux.party/upload/"$2"/macos
	curl --header "X-API-Token: $API_TOKEN"\
		 -F "data=@super-tux-party-sources.zip" https://supertux.party/upload/"$2"/source
fi

butler push super-tux-party-linux-64.zip "${ITCH_URL}:linux-64" --userversion="$2"
butler push super-tux-party-windows-64.zip "${ITCH_URL}:windows-64" --userversion="$2"
butler push super-tux-party-osx-64.zip "${ITCH_URL}:osx-64" --userversion="$2"
butler push super-tux-party-sources.zip "${ITCH_URL}:sources" --userversion="$2"
