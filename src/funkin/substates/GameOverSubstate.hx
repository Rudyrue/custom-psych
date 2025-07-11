package funkin.substates;

import funkin.objects.Character;

class GameOverSubstate extends FlxSubState {
	static inline var default_loopMusic:String = 'game over';
	static inline var default_initSFX:String = 'death';
	static inline var default_confirmSFX:String = 'game over end';
	static inline var default_characterName:String = 'bf-dead';
	static inline var default_bpm:Float = 100;

	public static var loopMusic:String = default_loopMusic;
	public static var initSFX:String = default_initSFX;
	public static var confirmSFX:String = default_confirmSFX;
	public static var characterName:String = default_characterName;
	public static var bpm:Float = default_bpm;

	var _character:Character;
	var _skipped:Bool = false;
	var _looping:Bool = false;
	public function new(playStateCharacter:Character) {
		_character = new Character(playStateCharacter.x, playStateCharacter.y, characterName);
		_character.autoIdle = false;
		_character.animation.finishCallback = _ -> {
			if (_character.animation.curAnim.name == 'idle') {
				startLoop();
			}
		}
		super();
	}

	var _music:FlxSound;

	// doing our own beat math
	// because we can't add a signal to the conductor
	// or extend any music functions
	var _crotchet:Float;
	var _lastBeat:Int = -1;
	
	override function create():Void {
		Conductor.stop();

		Conductor.rate = FlxG.animationTimeScale = 1;

		_music = FlxG.sound.load(Paths.music(loopMusic), 1, true);
		_crotchet = (60 / bpm) * 1000;

		add(_character);

		var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(_character.getGraphicMidpoint().x + _character.cameraOffset.x, _character.getGraphicMidpoint().y + _character.cameraOffset.y);
		camera.follow(camFollow, LOCKON, 0.04);
		//add(camFollow);

		FlxG.sound.play(Paths.sound(initSFX));
	}

	function startLoop():Void {
		_looping = true;
		_character.playAnim('loop');
		_music.play();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (_looping) {
			var curBeat:Int = Math.floor(_music.time / _crotchet);
			if (_lastBeat != curBeat) {
				_lastBeat = curBeat;
				_character.playAnim('loop');
			}
		}

		if (Controls.justPressed('accept')) skip();
		if (Controls.justPressed('back') && !_skipped) {
			Difficulty.reset();
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.play();

			if (PlayState.storyMode) {
				FunkinState.switchState(new StoryMenuState());
				PlayState.songList = [];
				PlayState.storyMode = false;
				PlayState.currentLevel = 0;
			} else FunkinState.switchState(new FreeplayState());
		}
	}

	function skip():Void {
		if (_skipped) return;

		_skipped = true;
		_looping = false;
		_music.stop();
		FlxG.sound.play(Paths.sound(confirmSFX));
		_character.playAnim('confirm');

		new FlxTimer().start(0.7, function(_) {
			camera.fade(FlxColor.BLACK, 2, false, function() FunkinState.resetState());
		});
	}

	override function destroy():Void {
		loopMusic = default_loopMusic;
		initSFX = default_initSFX;
		confirmSFX = default_confirmSFX;
		characterName = default_characterName;
		bpm = default_bpm;

		super.destroy();
	}
}