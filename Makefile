
.PHONY: all clean linux windows linux_executable windows_executable macos macos_executable resources

all: linux windows macos

build:
	mkdir build

build/plugins:
	mkdir build/plugins

linux: linux_executable resources

linux_executable: build
	godot --export "Linux/X11" "build/supertuxparty" --no-window

resources: build build/plugins
	godot --export "Resources" "build/plugins/default.pck" --no-window


windows: windows_executable resources

windows_executable: build
	godot --export "Windows Desktop" "build/Supertuxparty.exe" --no-window

macos: macos_executable resources

macos_executable:
	godot --export "Mac OSX" "build/supertuxparty.app" --no-window


clean:
	rm -rf build
