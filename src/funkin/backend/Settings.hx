package funkin.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit
@:publicFields
class SaveVariables {
	// for readability/backwards compatability
	var downscroll(get, never):Bool;
	function get_downscroll():Bool return scrollDirection.toLowerCase() == 'down';

	// gameplay
	var scrollDirection:String = 'Up';
	var centeredNotes:Bool = false;
	var opponentNotes:Bool = true;
	var ghostTapping:Bool = true;
	var sickHitWindow:Int = 45;
	var goodHitWindow:Int = 90;
	var badHitWindow:Int = 135;
	var shitHitWindow:Int = 180;
	var canReset:Bool = true;
	var mechanics:Bool = true;
	var noteOffset:Float = 0;
	var assistClaps:Bool = false;
	var metronome:Bool = false;
	var pauseType:String = 'Unlimited';

	// graphics (that affect performance)
	var antialiasing:Bool = true;
	var reducedQuality:Bool = false;
	var shaders:Bool = true;
	var gpuCaching:Bool = false;
	var fullscreen:Bool = false;

	// visuals (that don't affect performance)

	// these also count as visuals
	// but these are in a different menu
	var comboPosition:Array<Float> = [300, 300];
	var judgePosition:Array<Float> = [300, 200];

	var scrollSpeed:Float = 1.0;
	var scrollType:String = 'Multiplied';

	var flashingLights:Bool = true;
	var noteSkin:String = 'Funkin';
	var noteSplashSkin:String = 'Psych';
	var noteSplashAlpha:Float = 0.6;
	var gameVisibility:Int = 100;
	var cameraZooms:Bool = true;
	var judgementAlpha:Float = 1;
	var judgementCounter:Bool = false;
	var comboAlpha:Float = 1;
	var healthBarAlpha:Float = 1;
	var scoreAlpha:Float = 1;
	var language:String = 'en-US';
	var fpsCounter:Bool = true;
	var transitions:Bool = true;
	var framerate:Int = 60;
	var strumlineSize:Float = 0.7;
	var timeBarType:String = 'Disabled';
	var pressAnimOnTap:Bool = true;
	var hideTightestJudge:Bool = false;

	// miscellaneous
	var discordRPC:Bool = true;
	var autoPause:Bool = true;
	var pauseMusic:String = 'Tea Time';
	var pauseMusicVolume:Float = 0.7;
	var gameplayModifiers:Map<String, Dynamic> = [
		'playbackRate' => 1.0,
		'instakill' => false,
		'onlySicks' => false,
		'noFail' => false,
		'botplay' => false,
		'mirroredNotes' => false,
		'randomizedNotes' => false,
		'sustains' => true,
		'mines' => true,
		'blind' => false,
		'opponentMode' => false
	];
}

class Settings {
	public static final default_data:SaveVariables = {};
	public static var data:SaveVariables = {};

	public static function save() {
		for (key in Reflect.fields(data)) {
			// ignores variables with getters
			if (Reflect.hasField(data, 'get_$key')) continue;
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.flush();
	}

	public static function load() {
		FlxG.save.bind('settings', Util.getSavePath());

		final fields:Array<String> = Type.getInstanceFields(SaveVariables);
		for (i in Reflect.fields(FlxG.save.data)) {
			if (i == 'gameplayModifiers' || !fields.contains(i)) continue;

			if (Reflect.hasField(data, 'set_$i')) Reflect.setProperty(data, i, Reflect.field(FlxG.save.data, i));
			else Reflect.setField(data, i, Reflect.field(FlxG.save.data, i));
		}

		if (FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 240));
		}

		if (FlxG.save.data.gameplayModifiers != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplayModifiers;
			for (name => value in map) data.gameplayModifiers.set(name, value);
		}
		funkin.objects.Strumline.size = data.strumlineSize;

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset() {
		data = default_data;
	}
}
