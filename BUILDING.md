# Dependencies
* [git-scm](https://git-scm.com/downloads)
* (Windows Only) Microsoft Visual Studio - refer to [this line] for specifics
* (Linux Only) VLC
* [Haxe](https://haxe.org/download/) 4.2.5 or greater

## Haxelib Libraries
* HaxeFlixel - `haxelib install flixel 5.5.0`
* OpenFL - `haxelib install openfl 9.3.3`
* Lime - `haxelib install lime 8.1.2`
* HaxeFlixel Addons - `haxelib install flixel-addons 3.2.2`
* HaxeFlixel UI - `haxelib install flixel-ui 2.5.0`
* SScript - `haxelib install SScript 17.2.618`
* hxvlc - `haxelib install hxvlc 1.3.0`
* hxcpp - `haxelib install hxcpp 4.3.2`

## Github Libraries
* LINC_LuaJIT - `haxelib git linc_luajit https://github.com/superpowers04/linc_luajit`
* hxDiscord_RPC - `haxelib git hxdiscord_rpc https://github.com/MAJIGSAW77/hxdiscord_rpc`
* FlxAnimate - `haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev`

* NOTE: If you don't want to manually install all of these libraries, you can run `setup/libraries.bat` that installs all of them for you.

# Compiling

## Windows Specific
Windows needs Microsoft Visual Studio binaries to be able to compile to C++.
These 2 commands will do that for you, without having to download the installer yourself.
```
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
```

* NOTE: In Mac and Linux distributions, you need to run `mkdir ~/haxelib && haxelib setup ~/haxelib` to make a folder that you can put all of your Haxe stuff into.

### Linux Specific

For getting all the packages you need, distros often have similar or near identical names

On pretty much every distro, install the `git`, `haxe`, and `vlc` packages

Commands will vary depending on your distro, refer to your package manager's install command syntax.
### Installation for common Linux distros
#### Ubuntu/Debian based Distros:
```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
mkdir ~/haxelib && haxelib setup ~/haxelib
```
#### Arch based Distros:
```bash
sudo pacman -Syu haxe git vlc --noconfirm
mkdir ~/haxelib;
haxelib setup ~/haxelib
```
#### Gentoo:
```
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Some packages may be "masked", so please refer to [this page](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) in the Gentoo Wiki.

After everything is set up and all of the libaries are installed, the last thing to do is run `lime test cpp`.

# FAQ
## "Why is it taking so long?"
First time compilations take a long time, usually 15-30 minutes. But it mainly depends on your hardware.

## "I had an error relating to g++ on Linux!"
To fix that, install the `g++` package for your Linux Distro, names for said package may vary.
e.g: Fedora is `gcc-c++`, Gentoo is `sys-devel/gcc`, and so on.