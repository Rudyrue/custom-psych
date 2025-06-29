 package funkin.states;

import openfl.media.Sound;

import flixel.util.FlxSort;

import funkin.objects.*;
import funkin.stages.*;
import funkin.huds.*;
import funkin.backend.Song.Chart;
import funkin.objects.Note.NoteData;
import funkin.objects.Strumline.Receptor;
import funkin.backend.EventHandler.Event;

import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

import funkin.substates.PauseMenu;
import funkin.substates.GameOverSubstate;

class PlayState extends MusicState {
	public static var self:PlayState;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// VSRG SPECIFIC
	// VSRG SPECIFIC
	// VSRG SPECIFIC
	///////////////////////////////////////////////////////////////////////////////////////////////

	// chart shit
	public static var song:Chart;
	public static var songID:String;
	var songName:String;

	// gameplay
	@:unreflective static var disqualified:Bool = false;
	var canPause:Bool = true;

	var downscroll:Bool;
	var canReset:Bool;
	var noFail:Bool;

	@:isVar var botplay(get, set):Bool;
	function get_botplay():Bool {
		if (playfield == null) return false;

		if (playfield.botplay) disqualified = true;
		return playfield.botplay;
	}

	function set_botplay(value:Bool):Bool {
		if (value) disqualified = true;

		playfield.botplay = value;
		if (hud != null) hud.botplay = value;
		return value;
	}

	@:isVar var playerID(get, set):Int;
	function get_playerID():Int 
		return playfield?.playerID ?? 0;

	function set_playerID(value:Int):Int {
		if (hud != null) hud.playerID = value;
		return playfield.playerID = value;
	}

	@:isVar var rate(get, set):Float;
	function get_rate():Float 
		return playfield?.rate ?? 1.0;

	function set_rate(value:Float):Float
		return playfield.rate = value;

	var _rawScrollSpeed:Float = 1.0;
	var scrollType:String;
	@:isVar var scrollSpeed(get, set):Float;
	function get_scrollSpeed():Float 
		return playfield?.scrollSpeed ?? 1.0;

	function set_scrollSpeed(value:Float):Float
		return playfield.scrollSpeed = value;

	public var combo:Int = 0;
	public var comboBreaks:Int = 0;
	public var score:Int = 0;
	public var accuracy:Float = 0.0;

	public var totalNotesPlayed:Float = 0.0;
	public var totalNotesHit:Int = 0;

	// objects
	var playfield:PlayField;
	var hud:HUD;

	var leftStrumline:Strumline;
	var rightStrumline:Strumline;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// FNF SPECIFIC
	// FNF SPECIFIC
	// FNF SPECIFIC
	///////////////////////////////////////////////////////////////////////////////////////////////
	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;
	public static var currentLevel:Int = 0;
	public static var weekData:WeekFile;

	var characterCache:Map<String, Character> = [];
	
	var stageName:String;

	public var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		if (!noFail && ((playerID == 1 && value <= 0) || (playerID == 0 && value >= 100)))
			die();

		hud.healthChange(health = value = FlxMath.bound(value, 0, 100));
		return value;
	}

	public var defaultCamZoom:Float = 1.05;
	var cameraSpeed:Float = 1;
	var gfSpeed:Int = 1;
	var skipCountdown:Bool = false;

	static var storyScore:Int = 0;

	public var paused:Bool = false;
	var updateTime:Bool = false;

	// objects
	var stage:Stage;

	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	var eventHandler:EventHandler;

	var countdown:Countdown;

	var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;

	// cameras
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// overrides
	///////////////////////////////////////////////////////////////////////////////////////////////
	override function create():Void {
		Language.reloadPhrases();

		super.create();
		self = this;

		Conductor.stop();

		if (storyMode) songID = songList[currentLevel];

		info('new song was loaded: $songID - ${Difficulty.current}');

		// precache the pause menu music
		// to prevent the pause menu freezing on first pause
		PauseMenu.musicPath = Settings.data.pauseMusic;
		Paths.music(PauseMenu.musicPath);

		// set up gameplay settings
		noFail = Settings.data.gameplaySettings['noFail'];
		canReset = Settings.data.canReset;
		downscroll = Settings.data.downscroll;
		scrollType = Settings.data.gameplaySettings['scrollType'];
		_rawScrollSpeed = Settings.data.gameplaySettings['scrollSpeed'];

		ScriptHandler.loadFromDir('scripts');

		eventHandler = new EventHandler();
		eventHandler.triggered = eventTriggered;
		eventHandler.pushed = eventPushed;

		// set up cameras
		FlxG.cameras.reset(camGame = new FlxCamera());

		camFollow = new FlxObject();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			camGame.visible = false;
			camHUD.bgColor.alphaFloat = 0;
		}

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		// start setting up the hud
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;
		leftStrumline = new Strumline(320, strumlineYPos);
		leftStrumline.healthMult = -1;
		rightStrumline = new Strumline(950, strumlineYPos);

		add(playfield = new PlayField([leftStrumline, rightStrumline], Settings.data.gameplaySettings['opponentMode'] ? 0 : 1));
		playfield.cameras = [camHUD];
		playfield.downscroll = downscroll;
		playfield.modifiers = true;
		rate = Settings.data.gameplaySettings['playbackRate'];

		playfield.noteHit = noteHit;
		playfield.sustainHit = sustainHit;
		playfield.noteMiss = noteMiss;
		playfield.ghostTap = ghostTap;
		playfield.noteSpawned = noteSpawned;

		playfield.add(noteSplashes = new FlxTypedSpriteGroup<NoteSplash>());
		for (i in 0...Strumline.keyCount) noteSplashes.add(new NoteSplash(i));
		noteSplashes.alpha = Settings.data.noteSplashAlpha * playfield.alpha;

		if (Settings.data.centeredNotes) {
			for (i => line in playfield.strumlines.members) {
				if (i == playerID) {
					line.screenCenter(X);
					continue;
				}

				line.visible = false;
				line.alpha = 0;
			}
		}
		
		loadSong();
		ScriptHandler.loadFromDir('songs/$songID');

		scrollSpeed = switch scrollType {
			case 'Constant': _rawScrollSpeed;
			case 'Multiplied': song.speed * _rawScrollSpeed;
			default: song.speed;
		}

		stage = switch stageName {
			case 'stage': new StageWeek1();
			case 'mansion': new Mansion();
			case 'philly': new Philly();
			case 'limo': new Limo();
			case 'mall': new Mall();
			case 'mall-evil': new MallEvil();
			case 'school': new School();
			case 'school-evil': new SchoolEvil();
			case 'warzone': new Warzone();
			case 'philly-street': new PhillyStreet();
			//case 'phillyBlazin': new PhillyBlazin();

			case _: new Stage(stageName);
		}
		ScriptHandler.loadFile('stages/$stageName.hx');

		// characters
		add(gf = new Character(stage.spectator.x, stage.spectator.y, song.meta.spectator, false));
		gf.visible = stage.isSpectatorVisible;

		add(dad = new Character(stage.opponent.x, stage.opponent.y, song.meta.enemy, false));
		leftStrumline.character = function() return dad;

		add(bf = new Character(stage.player.x, stage.player.y, song.meta.player));
		rightStrumline.character = function() return bf;

		// fix for the camera starting off in the stratosphere
		camFollow.setPosition(gf.getMidpoint().x + gf.cameraOffset.x, gf.getMidpoint().y + gf.cameraOffset.y);

		cameraSpeed = stage.cameraSpeed;
		camGame.zoom = defaultCamZoom = stage.zoom;
		camGame.follow(camFollow, LOCKON, 0);
		camGame.snapToTarget();
		
		moveCamera();

		stage.create();
		eventHandler.load(songID);

		add(hud = new DefaultHUD(songName, Difficulty.current));
		hud.cameras = [camHUD];
		hud.downscroll = downscroll;
		hud.playerID = playerID;
		
		botplay = Settings.data.gameplaySettings['botplay'];

		hud.add(countdown = new Countdown());
		countdown.screenCenter();
		countdown.onStart = function() {
			ScriptHandler.call('countdownStarted');
			Conductor.playing = true;
		}
		countdown.onFinish = function() {
			ScriptHandler.call('songStarted');
			Conductor.play();
			updateTime = true;
		}

		if (skipCountdown) {
			countdown.finished = true;
			countdown.onFinish();
		} else {
			Conductor.rawTime = (Conductor.crotchet * -5);
			countdown.start();
		}

		ScriptHandler.call('create');

		FlxG.mouse.visible = false;

		DiscordClient.changePresence('$songName - ${Difficulty.current}', storyMode ? 'Story Mode' : 'Freeplay', dad.icon, true);

		persistentUpdate = true;
	}

	override function update(delta:Float):Void {
		ScriptHandler.call('update', [delta]);
		super.update(delta);

		if ((Controls.justPressed('reset') && canReset)) die();

		updateCameraScale(delta);

		if (countdown.finished) eventHandler.update();
		stage.update(delta);

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (Controls.justPressed('pause') && canPause) openPauseMenu();
		camGame.followLerp = paused ? 0 : (0.04 * cameraSpeed * playfield.rate);

		hud.paused = paused;
		hud.update(delta);

		ScriptHandler.call('postUpdate', [delta]);
	}

	override function destroy():Void {
		ScriptHandler.call('destroy');

		closeSubState();
		camGame.setFilters([]);

		stage.destroy();
		Judgement.resetHits();

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		ScriptHandler.clear();

		self = null;
		super.destroy();

		PauseMenu.openCount = 0;
	}

	override function stepHit(step:Int) {
		ScriptHandler.call('stepHit', [step]);
		hud.stepHit(step);
		stage.stepHit(step);
	}

	override function beatHit(beat:Int) {
		ScriptHandler.call('beatHit', [beat]);
		stage.beatHit(beat);
		hud.beatHit(beat);

		characterBopper(beat);
	}

	override function measureHit(measure:Int) {
		ScriptHandler.call('measureHit', [measure]);
		stage.measureHit(measure);

		if (Settings.data.cameraZooms) {
			camGame.zoom += 0.03;
			camHUD.zoom += 0.015;
		}

		moveCamera(measure);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// input related
	///////////////////////////////////////////////////////////////////////////////////////////////
	function noteHit(strumline:Strumline, note:Note):Void {
		ScriptHandler.call('noteHit', [strumline, note]);

		if (note.player != playerID) {
			playCharacterAnim(strumline.character(), note, 'sing');
			if (song.meta.hasVocals && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;
			hud.noteHit(strumline, note, null);
			return;
		} else if (botplay) {
			playCharacterAnim(strumline.character(), note, 'sing');
			if (note.isSustain) return;

			final judge:Judgement = Judgement.min;
			health += judge.health * strumline.healthMult;
			combo++;
			judge.hits++;
			hud.noteHit(strumline, note, judge);
			return;
		}

		final judgement:Judgement = judgeHit(strumline, note);
		if (Settings.data.noteSplashSkin != 'None' && judgement.splashes && note.splashes)
			noteSplashes.members[note.lane].hit(strumline.members[note.lane]);
		
		if (note.type == 'Hey!' && strumline.character().animation.exists('cheer'))
			strumline.character().playAnim('cheer');
		else playCharacterAnim(strumline.character(), note, 'sing');

		hud.noteHit(strumline, note, judgement);
	}

	function sustainHit(strumline:Strumline, note:Note) {
		ScriptHandler.call('sustainHit', [strumline, note]);

		playCharacterAnim(strumline.character(), note, 'sing');
	}

	function judgeHit(strumline:Strumline, note:Note):Judgement {
		final judgeID:Int = Judgement.getIDFromTiming(note.rawHitTime);
		var judge:Judgement = Judgement.list[judgeID];

		note.judge = judge.name;

		if (Settings.data.gameplaySettings['onlySicks'] && judgeID != 0) die();
	
		if (!note.breakOnHit) {
			totalNotesPlayed += judge.accuracy;
			health += judge.health * strumline.healthMult;
			// pbot1-ish scoring system
			// cuz judgement based is boring :sob:
			score += Math.floor(500 - Math.abs(note.rawHitTime));
			judge.hits++;
			combo++;
		} else {
			score -= 20;
			health -= 6 * strumline.healthMult;
			combo = 0;
			comboBreaks++;
		}
	
		if (judge.breakCombo) {
			combo = 0;
			comboBreaks++;
		}
		
		totalNotesHit++;
		accuracy = updateAccuracy();

		if (song.meta.hasVocals) {
			if (Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;
			else Conductor.vocals.members[playerID].volume = 1;
		}
		return judge;
	}

	function noteMiss(strumline:Strumline, note:Note) {
		if (note.ignore) return;

		ScriptHandler.call('noteMiss', [strumline, note]);
		
		if (Settings.data.gameplaySettings['instakill'] || Settings.data.gameplaySettings['onlySicks']) die();

		comboBreaks++;
		combo = 0;
		score -= 20;
		health -= 6 * strumline.healthMult;

		accuracy = updateAccuracy();

		note.missed = true;
		for (piece in note.pieces)
			if (piece != null && piece.exists && piece.alive) piece.multAlpha = 0.25;

		if (song.meta.hasVocals) {
			if (Conductor.opponentVocals == null) Conductor.mainVocals.volume = 0;
			else Conductor.vocals.members[playerID].volume = 0;
		}

		playCharacterAnim(strumline.character(), note, 'miss');

		hud.noteMiss(strumline, note);
	}

	function ghostTap(strumline:Strumline) {
		ScriptHandler.call('ghostTap', [strumline]);
		score -= 20;
		health -= 6 * strumline.healthMult;

		accuracy = updateAccuracy();
		hud.ghostTap(strumline);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// gameplay functionality
	///////////////////////////////////////////////////////////////////////////////////////////////
	function updateAccuracy():Float 
		return (totalNotesHit <= 0 ? 0.0 : (totalNotesPlayed / (totalNotesHit + comboBreaks)));

	///////////////////////////////////////////////////////////////////////////////////////////////
	// chart/song related
	///////////////////////////////////////////////////////////////////////////////////////////////
	function loadSong():Void {
		// load chart
		try 
			song = Song.load(songID, Difficulty.format())
		catch (e:haxe.Exception) {
			error('The chart "$songID (${Difficulty.current})" failed to load: $e');
			song = Song.createDummyFile();
			song.meta = Meta.load(songID);
		}

		Conductor.timingPoints = song.meta.timingPoints;
		Conductor.bpm = Conductor.timingPoints[0].bpm;
		Conductor.offset = song.meta.offset;
		songName = song.meta.songName;
		stageName = song.meta.stage;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.onComplete = function() {
				if (!disqualified) {
					Scores.setPlay({
						songID: songID,
						difficulty: Difficulty.current,

						score: score,
						accuracy: accuracy,

						modifiers: Settings.data.gameplaySettings.copy()
					});

					if (storyMode) {
						storyScore += score;
						if (currentLevel == songList.length - 1) {
							Scores.setWeekPlay({
								weekID: weekData.fileName,
								difficulty: Difficulty.current,
								score: score,
								modifiers: Settings.data.gameplaySettings.copy()
							});
							weekData = null;
							storyScore = 0;
						}
					}
				}

				endSong();
				Scores.save();
			}
		} catch (e:Dynamic)
			error('Instrumental failed to load: $e');

		// load vocals
		try {
			if (song.meta.hasVocals) {
				final mainFile:Sound = Paths.audio('songs/$songID/Voices-Player', null, false) ?? Paths.audio('songs/$songID/Voices');
				final opponentFile:Sound = Paths.audio('songs/$songID/Voices-Opponent', null, false);

				Conductor.mainVocals = FlxG.sound.load(mainFile);
				if (opponentFile != null) Conductor.opponentVocals = FlxG.sound.load(opponentFile);
			}
		} catch (e:Dynamic)
			warn('Vocals failed to load: $e');

		playfield.loadNotes(song);
	}

	function noteSpawned(note:Note):Void
		ScriptHandler.call('noteSpawned', [note]);

	///////////////////////////////////////////////////////////////////////////////////////////////
	// events
	///////////////////////////////////////////////////////////////////////////////////////////////
	function eventTriggered(event:Event):Void {
		ScriptHandler.call('eventTriggered', [event]);
		stage.eventTriggered(event);

		switch event.name {
			case 'Change Character':
				final type:Int = Std.parseInt(event.args[0]);
				final character:Character = switch type {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				final name:String = event.args[1];
				if (character != null && character.name != name) {
					final newCharacter:Character = characterCache[name];
					if (newCharacter != null) return;
					newCharacter.alpha = 1;
					newCharacter.visible = character.visible;
					newCharacter.setPosition(character.x, character.y);
					character.alpha = 0;
					character.visible = false;

					if (type == 0) dad = newCharacter;
					else if (type == 1) gf = newCharacter;
					else if (type == 2) bf = newCharacter;
				}

			case 'Hey!':
				final character:Character = switch Std.parseInt(event.args[0]) {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character != null && character.animation.exists('cheer')) {
					character.playAnim('cheer', true);
					character.specialAnim = true;
				}

			case 'Play Animation':
				final animName:String = event.args[1];
				final character:Character = switch Std.parseInt(event.args[0]) {
					case 0: dad;
					case 1: gf;
					case 2: bf;

					default: null;
				}

				if (character != null && character.animation.exists(animName)) {
					character.playAnim(animName, true);
					character.specialAnim = true;
				}

			case 'Set GF Speed':
				gfSpeed = Math.floor(Math.max(Std.parseInt(event.args[0]), 1));

			case 'Play Sound':
				FlxG.sound.play(Paths.sound(event.args[0]), Std.parseFloat(event.args[1]));

			case 'Add Camera Zoom':
				if (Settings.data.cameraZooms && camGame.zoom < 1.35) {
					camGame.zoom += Std.parseFloat(event.args[0]);
					camHUD.zoom += Std.parseFloat(event.args[1]);
				}

			case 'Screen Shake':
				for (i => cam in [camGame, camHUD]) {
					final duration:Float = Std.parseFloat(event.args[0].split(',')[i]);
					final intensity:Float = Std.parseFloat(event.args[1].split(',')[i]);

					if (duration <= 0 || intensity <= 0) continue;
					cam.shake(intensity, duration);
				}

			case 'Change Scroll Speed':
				if (scrollType != 'constant') {
					final duration:Float = Std.parseFloat(event.args[1]);
					final value:Float = song.speed * _rawScrollSpeed * Math.max(Std.parseFloat(event.args[0]), 1);

					if (duration <= 0) scrollSpeed = value;
					else FlxTween.tween(this, {scrollSpeed: value}, duration / rate);
				}
		}

		hud.eventTriggered(event);
	}

	var eventList:Array<String> = [];
	function eventPushed(event:Event):Void {
		eventPushedUnique(event);
		if (eventList.contains(event.name)) return;

		ScriptHandler.call('eventPushed', [event]);
		eventList.push(event.name);
		stage.eventPushed(event);
	}

	function eventPushedUnique(event:Event):Void {
		ScriptHandler.call('eventPushedUnique', [event]);
		stage.eventPushedUnique(event);

		switch event.name {
			case 'Change Character':
				cacheCharacter(Std.parseInt(event.args[0]), event.args[1]);
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// regarding objects
	///////////////////////////////////////////////////////////////////////////////////////////////
	dynamic function updateCameraScale(delta:Float):Void {
		final scalingMult:Float = Math.exp(-delta * 6 * playfield.rate);
		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, scalingMult);
	}

	function moveCamera(?measure:Int = 0) {
        measure = Std.int(Math.max(0, measure));
        if (song.notes[measure] == null) return;

		final char:Character = (song.notes[measure].gfSection ? gf : (song.notes[measure].mustHitSection != true ? dad : bf));
		final name:String = (char == gf ? 'spectator' : (char == dad ? 'opponent' : 'player'));
		if (char == null) return;
		ScriptHandler.call('movedCamera', [name]);
		camFollow.setPosition(char.getMidpoint().x, char.getMidpoint().y);
		camFollow.x += char.cameraOffset.x;
		camFollow.y += char.cameraOffset.y;
    }

	function characterBopper(beat:Int):Void {
		for (char in [gf, bf, dad])
		{
			if (char == null) continue;
			if (beat % (char == gf ? Math.round(gfSpeed * char.danceInterval) : char.danceInterval) == 0)
				char.dance();
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// any other miscellaneous functions i need
	///////////////////////////////////////////////////////////////////////////////////////////////
	inline function playCharacterAnim(character:Character, note:Note, prefix:String) 
		character.playAnim('$prefix${Note.directions[note.lane].toUpperCase()}${note.animSuffix}');

	// have to make it a function instead because dce lol
	function loadVideo(path:String):FunkinVideo 
		return new FunkinVideo(Paths.video(path), true);

	function openPauseMenu() {
		persistentUpdate = false;
		Conductor.pause();
		paused = true;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

		final menu:PauseMenu = new PauseMenu(songName, Difficulty.current, 0);
		openSubState(menu);
		menu.camera = camOther;
	}

	function cacheCharacter(type:Int, name:String):Character {
		final character:Character = new Character(0, 0, name);
		character.alpha = 0.0001;
		characterCache.set(name, character);
		add(character);
		return character;
	}

	// you die
	dynamic function die() {
		persistentUpdate = camGame.visible = camHUD.visible = false;

		countdown.stop();

		final gameOverSubstate:GameOverSubstate = new GameOverSubstate(bf);
		gameOverSubstate.cameras = [camOther];
		openSubState(gameOverSubstate);
	}

	// forceLeave:Bool - forces you to leave to the main menu
	public function endSong(?forceLeave:Bool = false):Void {
		Conductor.stop();
		Conductor.vocals.destroy();
		canPause = false;
		// should automatically leave if you're not in story mode
		var exitToMenu:Bool = !storyMode;
		if (storyMode) 
			++currentLevel < songList.length ? MusicState.resetState() : exitToMenu = true;

		if (exitToMenu || forceLeave) {
			persistentUpdate = true;
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.play();
			Difficulty.reset();
			Mods.current = '';
			MusicState.switchState(storyMode ? new StoryMenuState() : new FreeplayState());
			songList.resize(0);
			storyMode = false;
			currentLevel = 0;
			disqualified = false;
		} else prevCamFollow = camFollow;

		Sys.println('');
	}
}