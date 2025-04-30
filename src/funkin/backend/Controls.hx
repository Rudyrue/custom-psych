package funkin.backend;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;
import flixel.util.FlxSave;
import lime.ui.KeyCode;

class Controls {
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx
	public static final default_binds:Map<String, Array<FlxKey>> = [
		'note_left'		=> [D, LEFT],
		'note_down'		=> [F, DOWN],
		'note_up'		=> [J, UP],
		'note_right'	=> [K, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var binds:Map<String, Array<Int>> = default_binds;

	static var _save:FlxSave;

	public static function justPressed(name:String):Bool return _getKeyStatus(name, JUST_PRESSED);
	public static function pressed(name:String):Bool return _getKeyStatus(name, PRESSED);
	public static function released(name:String):Bool return _getKeyStatus(name, JUST_RELEASED);

	// backend functions to reduce repetitive code
	static function _getKeyStatus(name:String, state:FlxInputState):Bool {
		var binds:Array<FlxKey> = binds[name];
		if (binds == null) {
			trace('Keybind "$name" doesn\'t exist.');
			return false;
		}

		var keyHasState:Bool = false;

		for (key in binds) {
			@:privateAccess
			if (FlxG.keys.getKey(key).hasState(state)) {
				keyHasState = true;
				break;
			}
		}

		return keyHasState;
	}

	public static function save() {
		_save.data.binds = binds;
		_save.flush();
	}

	public static function load() {
		if (_save == null) {
			_save = new FlxSave();
			_save.bind('controls', Util.getSavePath());
		}

		if (_save.data.binds != null) {
			var loadedKeys:Map<String, Array<FlxKey>> = _save.data.binds;
			for (control => keys in loadedKeys) {
				if (!binds.exists(control)) continue;
				binds.set(control, keys);
			}
		}

		reloadVolumeBinds();
	}

	public static function convertStrumKey(arr:Array<String>, key:FlxKey):Int {
		if (key == NONE) return -1;
		for (i in 0...arr.length) {
			for (possibleKey in binds[arr[i]]) {
				if (key == possibleKey) return i;
			}
		}

		return -1;
	}

	// because openfl inlines it for some reason
    public static function convertLimeKeyCode(code:KeyCode):Int {
        @:privateAccess
        return openfl.ui.Keyboard.__convertKeyCode(code);
    }


	public static function reset() {
		for (key in binds.keys()) {
			if (!default_binds.exists(key)) continue;
			binds.set(key, default_binds.get(key).copy());
		}
	}

	public static function reloadVolumeBinds() {
		Main.muteKeys = binds['volume_mute'].copy();
		Main.volumeDownKeys = binds['volume_down'].copy();
		Main.volumeUpKeys = binds['volume_up'].copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?enabled:Bool = true) {
		final emptyArray = [];

		FlxG.sound.muteKeys = enabled ? Main.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = enabled ? Main.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = enabled ? Main.volumeUpKeys : emptyArray;
	}
}