package funkin.substates;

class PauseMenu extends flixel.FlxSubState {
	var options:Array<String> = ['Resume', 'Restart', 'Options', 'Exit to Menu'];
	var optionGrp:FlxTypedSpriteGroup<Alphabet>;

	var difficulty:String;
	var songName:String;
	var deaths:Int;

	var music:FlxSound;
	public static var musicPath:String = Settings.data.pauseMusic;
	public static var openCount:Int = 0;

	public static var wentToOptions:Bool = false;

	var curSelected:Int = 0;

	public function new(song:String, difficulty:String, deaths:Int) {
		super();
		this.songName = song;
		this.difficulty = difficulty;
		this.deaths = deaths;
	}

	override function create():Void {
		if (Settings.data.pauseType != 'Unlimited') {
			openCount++;
			if (openCount > 3 || Settings.data.pauseType == 'Disabled') options.remove('Resume');
		}

		music = FlxG.sound.load(Paths.music(musicPath), 0, true);
		music.play(FlxG.random.float(0, music.length * 0.5));

		var bg:FunkinSprite = new FunkinSprite().makeGraphic(1, 1, FlxColour.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		add(bg);

		var song:FlxText = new FlxText(20, 15, 0, songName, 32);
		song.font = Paths.font("vcr.ttf");
		song.x = FlxG.width - (song.width + 20);
		song.alpha = 0;
		add(song);

		var songDifficulty:FlxText = new FlxText(20, 47, 0, difficulty.toUpperCase(), 32);
		songDifficulty.font = Paths.font('vcr.ttf');
		songDifficulty.x = FlxG.width - (songDifficulty.width + 20);
		songDifficulty.alpha = 0;
		add(songDifficulty);

		var blueballed:FlxText = new FlxText(20, 15 + 64, 0, 'Blueballed: $deaths', 32);
		blueballed.font = Paths.font('vcr.ttf');
		blueballed.x = FlxG.width - (blueballed.width + 20);
		blueballed.alpha = 0;
		add(blueballed);

		add(optionGrp = new FlxTypedSpriteGroup<Alphabet>());

		for (index => option in options) {
			final alphabet:Alphabet = optionGrp.add(new Alphabet(90, 320, option, BOLD, LEFT));
			alphabet.isMenuItem = true;
			alphabet.targetY = index;
		}

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(song, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(songDifficulty, {alpha: 1, y: songDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballed, {alpha: 1, y: blueballed.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		changeSelection();

		FlxG.mouse.visible = true;
	}

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, optionGrp.length - 1);

    	for (index => obj in optionGrp.members) {
			obj.targetY = index - curSelected;
			obj.alpha = curSelected == index ? 1 : 0.5;
		}

		FlxG.sound.play(Paths.sound('scroll'));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (music.volume < 0.7) music.volume += elapsed;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) changeSelection(downJustPressed ? 1 : -1);

		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

		if (Controls.justPressed('accept') || (FlxG.mouse.overlaps(optionGrp.members[curSelected]) && FlxG.mouse.justPressed)) {
			switch (options[curSelected]) {
				case 'Resume':
					destroyMusic();
					Conductor.resume();
					FlxG.mouse.visible = false;
					parent.persistentUpdate = true;
					close();
					
				case 'Restart': 
					destroyMusic();
					FlxG.mouse.visible = false;
					MusicState.resetState();
					parent.persistentUpdate = true;
					
				case 'Options': 
					PauseMenu.wentToOptions = true;
					if (Settings.data.pauseMusic != 'None') {
						Conductor.inst = FlxG.sound.load(Paths.music(Settings.data.pauseMusic), music.volume);
						Conductor.inst.play();
						FlxTween.tween(Conductor.inst, {volume: 1}, 0.8);
						Conductor.inst.time = music.time;
					}
					MusicState.switchState(new OptionsState());

				case 'Exit to Menu': 
					destroyMusic();
					PlayState.self.endSong(true);
			}
		}
	}

	inline function destroyMusic() {
		music.stop();
		music.destroy();
		music = null;
	}

	override function close() {
		PauseMenu.wentToOptions = false; // reset
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);
		PlayState.self.paused = false;
		super.close();
	}
}