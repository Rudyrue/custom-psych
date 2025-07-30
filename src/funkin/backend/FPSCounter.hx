package funkin.backend;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.util.FlxStringUtil;

import _external.memory.Memory;

class FPSCounter extends Sprite {
	// the background for the counter
	// so that the counter isn't hard to read on bright backgrounds
	public var background:Bitmap;
	public var text:TextField;

	// the rate at which the counter updates in milliseconds
	final pollingRate:Float = 1000;

	final font:String = 'assets/fonts/Nunito-Medium.ttf';

	public static var gcMemoryInBytes(get, never):Float;
	static function get_gcMemoryInBytes():Float {
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return openfl.system.System.totalMemory;
		#end
	}

	public static var appMemoryInBytes(get, never):Float;
	static function get_appMemoryInBytes():Float return Memory.getCurrentUsage();

	public function new(x:Float, y:Float, size:Int) {
		super();

		addChild(background = new Bitmap(new BitmapData(1, 1, true, 0x99000000)));
		background.x = x - 5;
		background.y = y - 5;

        addChild(text = new TextField());
        text.autoSize = LEFT;
		text.x = x;
		text.y = y;
        text.wordWrap = text.mouseEnabled = text.selectable = false;
        text.defaultTextFormat = new TextFormat(font, size, 0xFFFFFFF, JUSTIFY);
	}

	var _frames:Int;
	var _current:Int = 0;
	var _fpsTime:Float = 0.0;
	var _pollingRateTime:Float = 0.0;

	override function __enterFrame(delta:Float):Void {
		_frames++;
		_fpsTime += delta;

		// forcing fps to be updated every second instead
		// because basing it on `_pollingRate` would cause fps to be higher or lower
		// depending on what it is
		if (_fpsTime >= 1000) {
  			_current = _frames;
 			_fpsTime = _frames = 0;
		}

		// so instead we use polling rate just to update the text itself
		_pollingRateTime += delta;
		if (_pollingRateTime < pollingRate) return;

		updateText();
		_pollingRateTime = 0.0;
	}

	public dynamic function updateText() {
		final appMemory:String = Util.formatBytes(appMemoryInBytes);
		final gcMemory:String = Util.formatBytes(gcMemoryInBytes);

		// y'all are nerds smh.........................................
		text.text = '$_current FPS\nRAM: [APP: $appMemory / GC: $gcMemory]';
		
		background.width = text.width + 10;
		background.height = text.height + 10;
	}
}