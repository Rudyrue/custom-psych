@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel 5.5.0
haxelib install flixel-addons 3.2.2
haxelib install flixel-ui 2.5.0
haxelib install SScript 17.2.618
haxelib install hxvlc
haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc
echo Finished!
pause
