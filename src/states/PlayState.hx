package states;

import openfl.media.Sound;
import lime.ui.KeyCode;
import lime.app.Application;

import flixel.util.FlxSort;

import objects.*;
import stages.*;
import objects.Note.NoteData;
import objects.Strumline.StrumNote;

import backend.Judgement;

import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;

import substates.PauseMenu;
import substates.GameOverSubstate;

class PlayState extends MusicState {
	public static var self:PlayState;

	// chart stuff
	public static var song:Chart;
	public static var songID:String;

	public static var songList:Array<String> = [];
	public static var storyMode:Bool = false;
	public static var currentLevel:Int = 0;

	var songName:String;
	var stageName:String;
	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;

	var notes:FlxTypedSpriteGroup<Note>;
	var unspawnedNotes:Array<Note> = [];

	// gameplay logic stuff
	var scrollType:String;
	var scrollSpeed(default, set):Float = 1;
	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed;
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	public var botplay(default, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		// prevents players from just having botplay on the entire time
		// and then turning it off at the last note
		// and saving the play
		if (value) disqualified = true;

		if (playerStrums != null) playerStrums.player = !value;
		if (botplayTxt != null) botplayTxt.visible = value;
		return botplay = value;
	}

	var downscroll:Bool;
	var noFail:Bool;
	var canReset:Bool;

	@:unreflective
	var disqualified:Bool = false;

	var clearType:String;
	var grade:String;

	static var gradeSet:Array<Array<Dynamic>> = [
		["Perfect!!", 1],
		["Sick!", 0.9],
		["Great", 0.8],
		["Good", 0.7],
		["Nice", 0.69],
		["Meh", 0.6],
		["Bruh", 0.5],
		["Bad", 0.4],
		["Shit", 0.2],
		["You Suck!", 0]
	];

	var health(default, set):Float = 50;
	function set_health(value:Float):Float {
		value = FlxMath.bound(value, 0, 100);

		// update health bar
		health = value;
		healthBar.percent = FlxMath.remapToRange(FlxMath.bound(health, healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);

		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)

		return health = value;
	}

	var playbackRate(default, set):Float = 1;
	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		Conductor.rate = value;

		var ratio:Float = playbackRate / value; //funny word huh
		if (ratio != 1) {
			for (note in unspawnedNotes) note.resizeByRatio(ratio);
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	var judgeData:Array<Judgement> = Judgement.list;

	var defaultCamZoom:Float = 1.05;

	var songPercent:Float = 0.0;
	var songLength:Float;

	var botplayTxtSine:Float = 0.0;

	var cameraSpeed:Float = 1;

	var combo:Int = 0;
	var comboBreaks:Int = 0;
	var score:Int = 0;
	var accuracy:Float = 0.0;

	var totalNotesPlayed:Float = 0.0;
	var totalNotesHit:Int = 0;

	public var paused:Bool = false;
	var updateTime:Bool = false;

	var ghostNoteDetection:Bool = true;

	// objects
	var stage:Stage;

	public var bf:Character;
	public var dad:Character;
	public var gf:Character;

	var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	var opponentStrums:Strumline;
	var playerStrums:Strumline;

	var hud:FlxSpriteGroup;

	var scoreTxt:FlxText;
	var botplayTxt:FlxText;

	var timeBar:Bar;
	var timeTxt:FlxText;

	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;

	var judgeCounter:FlxText;

	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;

	var countdown:Countdown;

	// cameras
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var camOther:FlxCamera;

	// whatever variables i also need lmao
	final iconSpacing:Float = 20;
	var gfSpeed:Int = 1;

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	override function create() {
		Language.reloadPhrases();

		super.create();
		self = this;

		Conductor.stop();

		if (storyMode) songID = songList[currentLevel];

		// precache the pause menu music
		// to prevent the pause menu freezing on first pause
		PauseMenu.musicPath = Settings.data.pauseMusic;
		Paths.music(PauseMenu.musicPath);

		// set up gameplay settings
		botplay = Settings.data.gameplaySettings['botplay'];
		playbackRate = Settings.data.gameplaySettings['playbackRate'];
		noFail = Settings.data.gameplaySettings['noFail'];
		canReset = Settings.data.canReset;
		downscroll = Settings.data.downscroll;

		clearType = updateClearType();
		grade = updateGrade();

		ScriptHandler.loadFromDir('scripts');

		loadSong();
		ScriptHandler.loadFromDir('songs/$songID');

		scrollSpeed = switch (Settings.data.gameplaySettings['scrollType']) {
			case 'Constant': Settings.data.gameplaySettings['scrollSpeed'];
			case 'Multiplied': song.speed * Settings.data.gameplaySettings['scrollSpeed'];
			default: song.speed;
		}

		// set up cameras
		FlxG.cameras.reset(camGame = new FlxCamera());

		camFollow = new FlxObject();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCamera();

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alphaFloat = 1 - (Settings.data.gameVisibility / 100);

		// to prevent more lag when you can't even see the game camera
		if (Settings.data.gameVisibility <= 0) {
			camGame.visible = false;
			camHUD.bgColor.alphaFloat = 0;
		}

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		// set up strumlines and the note group
		final strumlineYPos:Float = downscroll ? FlxG.height - 150 : 50;
		add(playerStrums = new Strumline(950, strumlineYPos, !botplay));
		add(opponentStrums = new Strumline(320, strumlineYPos));

		playerStrums.cameras = [camHUD];
		opponentStrums.cameras = [camHUD];

		add(notes = new FlxTypedSpriteGroup<Note>());
		notes.cameras = [camHUD];

		if (Settings.data.centeredNotes) {
			playerStrums.screenCenter(X);
			opponentStrums.alpha = 0;
		}

		if (!Settings.data.opponentNotes) opponentStrums.alpha = 0;

		if (Settings.data.gameplaySettings['blind']) {
			notes.alpha = 0;
			opponentStrums.alpha = 0;
			playerStrums.alpha = 0;

			// just to make sure some note types don't work around alpha stuff
			notes.visible = false;
			opponentStrums.visible = false;
			playerStrums.visible = false;
		}

		stage = switch stageName {
			case 'stage': new StageWeek1();
			case _: new Stage(stageName);
/*			
			case 'spooky': new Spooky();
			case 'philly': new Philly();
			case 'limo': new Limo();
			case 'mall': new Mall();
			case 'mallEvil': new MallEvil();
			case 'school': new School();
			case 'schoolEvil': new SchoolEvil();
			case 'tank': new Tank();
			case 'phillyStreets': new PhillyStreets();
			case 'phillyBlazin': new PhillyBlazin();
			*/
		}
		ScriptHandler.loadFile('stages/$stageName.lua');
		ScriptHandler.loadFile('stages/$stageName.hx');

		cameraSpeed = stage.cameraSpeed;
		camGame.zoom = defaultCamZoom = stage.zoom;

		// characters
		add(gf = new Character(stage.spectator.x, stage.spectator.y, song.gfVersion, false));
		gf.visible = stage.isSpectatorVisible;

		// fix for the camera starting off in the stratosphere
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraOffset.x;
		camFollow.y += gf.cameraOffset.y;

		camGame.follow(camFollow, LOCKON, 0);
		camGame.snapToTarget();

		add(dad = new Character(stage.opponent.x, stage.opponent.y, song.player2, false));
		add(bf = new Character(stage.player.x, stage.player.y, song.player1));

		stage.create();

		// set up hud elements
		add(hud = new FlxSpriteGroup());
		hud.cameras = [camHUD];

		loadHUD();

		hud.add(countdown = new Countdown());
		countdown.screenCenter();
		countdown.onStart = function() {
			Conductor.playing = true;
			ScriptHandler.call('countdownStarted');
		}
		countdown.onFinish = function() {
			Conductor.play();
			updateTime = true;
			ScriptHandler.call('onSongStart');
		}

		// set up any other stuff we might need
		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);

		Conductor.rawTime -= (Conductor.crotchet * 5) + Conductor.songOffset;
		countdown.start();

		FlxG.mouse.visible = false;

		DiscordClient.changePresence('$songName - ${Difficulty.current}', storyMode ? 'Story Mode' : 'Freeplay', dad.icon, true);

		ScriptHandler.call('create');
	}

	function loadHUD():Void {
		if (hud == null) return;
		hud.clear();

		hud.add(timeBar = new Bar(0, downscroll ? FlxG.height - 30 : 15, 'timeBar', function() return songPercent, 0, 1));
		timeBar.setColors(0xFFFFFFFF, 0xFF000000);
		timeBar.screenCenter(X);

		// to make it fancy
		// if you want it the generic psych way
		// (black and white)
		// then just take this long ass line out
		FlxGradient.overlayGradientOnFlxSprite(timeBar.leftBar, Std.int(timeBar.leftBar.width), Std.int(timeBar.leftBar.height), [bf.healthColor, dad.healthColor], 0, 0, 1, 180);

		hud.add(timeTxt = new FlxText(0, 0, timeBar.width, '$songName - 0:00', 16));
		timeTxt.font = Paths.font('vcr.ttf');
		timeTxt.alignment = CENTER;
		timeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeTxt.borderColor = FlxColor.BLACK;
		timeTxt.borderSize = 1.25;
		timeTxt.setPosition(timeBar.getMidpoint().x - (timeTxt.width * 0.5), timeBar.getMidpoint().y - (timeTxt.height * 0.5));

		updateTime = Settings.data.timeBarType != 'Disabled';
		timeBar.visible = Settings.data.timeBarType != 'Disabled';
		timeTxt.visible = Settings.data.timeBarType != 'Disabled';

		hud.add(healthBar = new Bar(0, downscroll ? 55 : 640, 'healthBar', function() return health, 0, 100));
		healthBar.alpha = Settings.data.healthBarAlpha;
		healthBar.setColors(dad.healthColor, bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;

		hud.add(iconP1 = new CharIcon(bf.icon, true));
		iconP1.alpha = Settings.data.healthBarAlpha;
		iconP1.y = healthBar.y - (iconP1.height * 0.5);

		hud.add(iconP2 = new CharIcon(dad.icon));
		iconP2.alpha = Settings.data.healthBarAlpha;
		iconP2.y = healthBar.y - (iconP2.height * 0.5);

		updateIconPositions();

		hud.add(scoreTxt = new FlxText(0, downscroll ? 21 : FlxG.height - 39, FlxG.width, '', 16));
		scoreTxt.font = Paths.font('vcr.ttf');
		scoreTxt.alignment = CENTER;
		scoreTxt.alpha = Settings.data.scoreAlpha;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		scoreTxt.screenCenter(X);
		updateScoreTxt();

		hud.add(judgeSpr = new JudgementSpr(Settings.data.judgePosition[0], Settings.data.judgePosition[1]));
		hud.add(comboNumbers = new ComboNums(Settings.data.comboPosition[0], Settings.data.comboPosition[1]));

		hud.add(botplayTxt = new FlxText(0, downscroll ? FlxG.height - 115 : 85, FlxG.width - 800, 'BOTPLAY', 32));
		botplayTxt.font = Paths.font('vcr.ttf');
		botplayTxt.alignment = CENTER;
		botplayTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		botplayTxt.borderColor = FlxColor.BLACK;
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = botplay;
		botplayTxt.screenCenter(X);

		hud.add(judgeCounter = new FlxText(5, 0, 500, '', 20));
		judgeCounter.font = Paths.font('vcr.ttf');
		judgeCounter.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounter.borderColor = FlxColor.BLACK;
		judgeCounter.borderSize = 1.25;
		updateJudgeCounter();
		judgeCounter.screenCenter(Y);
		judgeCounter.visible = Settings.data.judgementCounter;
	}

	function loadSong():Void {
		// load chart
		try {
			song = Song.load('songs/$songID/${Difficulty.format()}.json');
		} catch (e:haxe.Exception) {
			Sys.println('The chart "$songID (${Difficulty.current})" failed to load: $e');
			song = Song.createDummyFile();
		}

		Conductor.setBPMChanges(song);
		Conductor.bpm = song.bpm;
		Conductor.songOffset = song.offset;
		songName = song.song;
		stageName = song.stage;

		// load inst
		try {
			Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
			Conductor.inst.onComplete = function() {
				if (!disqualified) {
					Scores.set({
						songID: songID,
						difficulty: Difficulty.current,

						score: score,
						accuracy: accuracy,

						playbackRate: Settings.data.gameplaySettings['playbackRate'],
						noFail: Settings.data.gameplaySettings['noFail'],
						randomizedNotes: Settings.data.gameplaySettings['randomizedNotes'],
						mirroredNotes: Settings.data.gameplaySettings['mirroredNotes'],
						sustains: Settings.data.gameplaySettings['sustains']
					});
				}

				endSong();
				Scores.save();
			}
		} catch (e:Dynamic) {
			Sys.println('Instrumental failed to load: $e');
		}

		songLength = Conductor.inst.length;

		// load vocals
		try {
			if (song.needsVoices) {
				var mainFile:Sound = Paths.audio('songs/$songID/Voices-Player', null, false);
				var opponentFile:Sound = Paths.audio('songs/$songID/Voices-Opponent', null, false);

				if (mainFile == null) mainFile = Paths.audio('songs/$songID/Voices');

				Conductor.mainVocals = FlxG.sound.load(mainFile);
				if (opponentFile != null) Conductor.opponentVocals = FlxG.sound.load(opponentFile);
			}
		} catch (e:Dynamic) {
			Sys.println('Vocals failed to load: $e');
		}

		loadNotes(songID);
	}

	function loadNotes(id:String) {
		var parsedNotes:Array<NoteData> = Song.parse(song);

		for (note in unspawnedNotes) {
			note.destroy();
			note = null;
		}
		unspawnedNotes.resize(0);

		var oldNote:Note = null;

		var randomizedLanes:Array<Int> = [for (i in 0...Strumline.keyCount) i];
		// randomizedLanes.push(FlxG.random.int(0, Strumline.keyCount - 1, randomizedLanes));
		if (Settings.data.gameplaySettings['randomizedNotes']) FlxG.random.shuffle(randomizedLanes);
		for (i => note in parsedNotes) {
			// thanks shubs /s
			if (note.lane < 0) continue;

			// dumbest way of doing it but whatever lmao
			if (Settings.data.gameplaySettings['mirroredNotes']) {
				if (note.lane == 0) note.lane = 3;
				else if (note.lane == 3) note.lane = 0;
				else if (note.lane == 1) note.lane = 2;
				else note.lane = 1;
			}

			// stepmania shuffle
			// instead of randomizing every note's lane individually
			// because chords were buggy asf lmao
			note.lane = randomizedLanes[note.lane];
			if (!Settings.data.gameplaySettings['sustains']) note.length = 0;

			var daBPM:Float = Conductor.getBPMChangeFromMS(note.time).bpm;

			if (i != 0 && ghostNoteDetection) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnedNotes) {
					if (evilNote.isSustain) continue;

					var matches:Bool = (note.lane == evilNote.lane && note.player == evilNote.player);
					if (!matches || Math.abs(note.time - evilNote.rawTime) > 2.0) continue;

					evilNote.destroy();
					unspawnedNotes.remove(evilNote);
				}
			}

			var swagNote:Note = new Note(note);
			unspawnedNotes.push(swagNote);

			var curStepCrotchet:Float = (60 / daBPM) * 1000 * 0.25;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrotchet);
			if (roundSus < 0) {
				oldNote = swagNote;
				continue;
			}

			for (susNote in 0...roundSus) {
				oldNote = unspawnedNotes[unspawnedNotes.length - 1];

				var sustainNote:Note = new Note({
					time: note.time + (curStepCrotchet * susNote),
					lane: note.lane,
					length: note.length,
					type: note.type,
					player: note.player
				}, true, oldNote);
				sustainNote.parent = swagNote;
				sustainNote.correctionOffset.y = downscroll ? 0 : swagNote.height * 0.5;
				unspawnedNotes.push(sustainNote);
				swagNote.pieces.push(sustainNote);

				if (!oldNote.isSustain) continue;

				oldNote.scale.y *= 44 / oldNote.frameHeight;
				oldNote.scale.y /= playbackRate;
				oldNote.resizeByRatio(curStepCrotchet / Conductor.stepCrotchet);
			}

			oldNote = swagNote;
		}

		// forces sustains to be behind notes
		// if you want them to be in front just use this code instead lol

		//unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		unspawnedNotes.sort((a, b) -> {
			if (a.time == b.time) return a.isSustain ? -1 : Std.int(a.time - b.time);
			return Std.int(a.time - b.time);
		});
		oldNote = null;
	}

	var canPause:Bool = true;
	override function update(elapsed:Float):Void {
		ScriptHandler.call('update', [elapsed]);
		super.update(elapsed);

		if ((Controls.justPressed('reset') && canReset) || (health <= 0 && !noFail)) die();

		spawnNotes();
		updateNotes();
		updateCameraScale(elapsed);
		updateIconScales(elapsed);
		updateIconPositions();
		updateTimeBar();

		stage.update(elapsed);

		if (FlxG.keys.justPressed.F8) botplay = !botplay;

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}

		if (Controls.justPressed('pause') && canPause) openPauseMenu();

		camGame.followLerp = paused ? 0 : (0.04 * cameraSpeed * playbackRate);

		ScriptHandler.call('updatePost', [elapsed]);
	}

	var _lastSeconds:Int = -1;
	dynamic function updateTimeBar() {
		if (paused || !updateTime) return;

		var curTime:Float = Math.max(0, Conductor.rawTime);
		songPercent = (curTime / songLength);

		var songCalc:Float = (songLength - curTime);
		if (Settings.data.timeBarType == 'Time Elapsed') songCalc = curTime;

		var seconds:Int = Math.floor((songCalc / playbackRate) * 0.001);
		if (seconds < 0) seconds = 0;

		if (seconds == _lastSeconds) return;

		var textToShow:String = '$songName';
		if (playbackRate != 1) textToShow += ' (${playbackRate}x)';
		if (Settings.data.timeBarType != 'Song Name') textToShow += ' - ${FlxStringUtil.formatTime(seconds, false)}';

		timeTxt.text = textToShow;
		_lastSeconds = seconds;
	}

	dynamic function spawnNotes() {
		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteToSpawn:Note = unspawnedNotes[noteSpawnIndex];
			if (noteToSpawn.rawHitTime > noteSpawnDelay) break;

			ScriptHandler.call('noteSpawned', [noteToSpawn]);

			notes.add(noteToSpawn);
			noteToSpawn.spawned = true;
			noteSpawnIndex++;
		}
	}

	dynamic function updateNotes() {
		for (note in notes.members) {
			if (note == null || !note.alive) continue;

			final strum:StrumNote = (note.player ? playerStrums : opponentStrums).members[note.lane];
			note.followStrum(strum, scrollSpeed);

			if (note.player) {
				if (botplay) checkNoteHitWithAI(strum, note);
				else if (note.isSustain) sustainInputs(strum, note);
			} else checkNoteHitWithAI(strum, note);

			if (!botplay && note.player && !note.missed && !note.isSustain && note.tooLate) {
				noteMiss(note);
			}

			if (note.time < Conductor.rawTime - 300) {
				notes.remove(note);
				note.destroy();
			}
		}
	}

	dynamic function updateCameraScale(elapsed:Float):Void {
		if (!Settings.data.cameraZooms) return;

		final scalingMult:Float = Math.exp(-elapsed * 6 * playbackRate);
		camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, scalingMult);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, scalingMult);
	}

	dynamic function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	dynamic function updateIconScales(elapsed:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	public function endSong():Void {
		ScriptHandler.call('endSong');

		Conductor.stop();
		Conductor.vocals.destroy();
		canPause = false;
		// should automatically leave if you're not in story mode
		var exitToMenu:Bool = !storyMode;
		if (storyMode) {
			++currentLevel < songList.length ? MusicState.resetState() : exitToMenu = true;
		}

		if (exitToMenu) {
			persistentUpdate = true;
			Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0.7, true);
			Conductor.play();
			Difficulty.reset();
			Mods.current = '';
			MusicState.switchState(storyMode ? new StoryMenuState() : new FreeplayState());
			songList = [];
			storyMode = false;
			currentLevel = 0;
		} else prevCamFollow = camFollow;
	}

	// you die
	function die() {
		persistentUpdate = false;
		camGame.visible = false;
		camHUD.visible = false;

		countdown.stop();

		var gameOverSubstate:GameOverSubstate = new GameOverSubstate(bf);
		gameOverSubstate.cameras = [camOther];
		openSubState(gameOverSubstate);
	}

	// ai note hitting
	dynamic function checkNoteHitWithAI(strum:StrumNote, note:Note):Void {
		if (!note.canHit || note.ignore || note.breakOnHit || note.time > Conductor.rawTime) return;

		final noteFunc = note.player ? noteHit : opponentNoteHit;

		// sustain input
		if (note.isSustain) {
			note.clipToStrum(strum);
			if (note.wasHit) return;

			note.wasHit = true;
			strum.playAnim('notePressed');
			noteFunc(note);
			return;
		}

		// normal notes
		note.wasHit = true;
		noteFunc(note);
		note.destroy();
		notes.remove(note);
	}

	dynamic function opponentNoteHit(note:Note) {
		ScriptHandler.call('opponentNoteHit', [note]);
		if (song.needsVoices && Conductor.opponentVocals == null) Conductor.mainVocals.volume = 1;

		opponentStrums.members[note.lane].playAnim('notePressed');
		dad.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
	}

	// note hitting specific to the player
	dynamic function sustainInputs(strum:StrumNote, note:Note) {
		var parent:Note = note.parent;

		if (!parent.canHit || parent.missed) return;

		var heldKey:Bool = keysHeld[parent.lane];
		var tooLate:Bool = (parent.wasHit ? note.time < (Conductor.rawTime / Conductor.rate) : parent.tooLate);
		var isTail:Bool = note.animation.curAnim.name == 'holdend';

		if (!heldKey) {
			if (tooLate && !note.wasHit) {
				// ignore tails completely
				if (isTail && parent.wasHit) {
					note.destroy();
					trace('why does this not destroy the tail ???? i don\'t miss it but it doesn\'t get destroyed');
					notes.remove(note);
					return;
				}

				noteMiss(parent);
				parent.missed = true;
			}

			return;
		}

		note.clipToStrum(strum);

		if (note.time <= (Conductor.rawTime / Conductor.rate) && !note.wasHit) note.wasHit = true;
		else return;
		
		strum.playAnim('notePressed');
		bf.playAnim('sing${Note.directions[parent.lane].toUpperCase()}');
	}

	dynamic function noteHit(note:Note) {
		ScriptHandler.call('noteHit', [note]);

		final strum:StrumNote = playerStrums.members[note.lane];

		note.wasHit = true;

		if (botplay) {
			strum.playAnim('notePressed');
			bf.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
			if (note.isSustain) return;

			final judge:Judgement = Judgement.min;

			health += judge.health;
			judgeSpr.display(0);
			judge.hits++;
			comboNumbers.display(++combo);
			updateJudgeCounter();
			
			return;
		}

		final adjustedHitTime:Float = note.rawHitTime / playbackRate;
		var judge:Judgement = Judgement.getFromTiming(adjustedHitTime);

		if (Settings.data.gameplaySettings['onlySicks'] && judge.name != 'sick') die();
	
		if (!note.breakOnHit) {
			totalNotesPlayed += judge.accuracy;
			health += judge.health;
			// pbot1-ish scoring system
			// cuz judgement based is boring :sob:
			score += Math.floor(500 - Math.abs(adjustedHitTime));
			judge.hits++;
			combo++;
		} else {
			score -= 20;
			health -= 6;
			combo = 0;
			comboBreaks++;
		}
	
		if (judge.breakCombo) {
			combo = 0;
			comboBreaks++;
		}
		
		totalNotesHit++;
		accuracy = updateAccuracy();
		grade = updateGrade();
		clearType = updateClearType();

		strum.playAnim('notePressed');
		bf.playAnim('sing${Note.directions[note.lane].toUpperCase()}');
		updateScoreTxt();
		updateJudgeCounter();
		if (song.needsVoices) Conductor.mainVocals.volume = 1;

		if (!note.breakOnHit) {
			judgeSpr.display(adjustedHitTime);
			comboNumbers.display(combo);
		}

		judge = null;
	}

	dynamic function noteMiss(note:Note) {
		if (note.ignore) return;

		if (Settings.data.gameplaySettings['instakill'] || Settings.data.gameplaySettings['onlySicks']) die();

		comboBreaks++;
		combo = 0;
		score -= 20;
		health -= 6;

		accuracy = updateAccuracy();
		grade = updateGrade();
		clearType = updateClearType();

		ScriptHandler.call('noteMiss', [note]);

		note.missed = true;
		for (piece in note.pieces) {
			if (piece == null || !piece.exists || !piece.alive) continue;
			piece.multAlpha = 0.25;
		}

		if (song.needsVoices) Conductor.mainVocals.volume = 0;
		bf.playAnim('miss${Note.directions[note.lane].toUpperCase()}');

		updateScoreTxt();
	}

	override function beatHit(beat:Int) {
		ScriptHandler.call('beatHit', [beat]);

		countdown.beat(beat);

		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();

		characterBopper(beat);
	}

	function characterBopper(beat:Int):Void {
		if (beat % Math.round(gfSpeed * gf.danceInterval) == 0)
			gf.dance();
		if (beat % bf.danceInterval == 0)
			bf.dance();
		if (beat % dad.danceInterval == 0)
			dad.dance();
	}

	dynamic function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;
		
		var sicks:Int = judgeData[0].hits;
		var goods:Int = judgeData[1].hits;
		var bads:Int = judgeData[2].hits;
		var shits:Int = judgeData[3].hits;

		judgeCounter.text = 'Sicks: $sicks\nGoods: $goods\nBads: $bads\nShits: $shits';
	}

	override function stepHit(step:Int) {
		ScriptHandler.call('stepHit', [step]);
	}

	override function measureHit(measure:Int) {
		ScriptHandler.call('measureHit', [measure]);

		if (Settings.data.cameraZooms) {
			camGame.zoom += 0.03;
			camHUD.zoom += 0.015;
		}

		moveCamera(measure);
	}

	public function moveCamera(?measure:Int = 0) {
		measure = Math.floor(Math.max(0, measure));
		if (song.notes[measure] == null) return;

		if (gf != null && song.notes[measure].gfSection) {
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraOffset.x;
			camFollow.y += gf.cameraOffset.y;
			return;
		}

		var isOpponent:Bool = song.notes[measure].mustHitSection != true;
		if (isOpponent) {
			if (dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x, dad.getMidpoint().y);
			camFollow.x += dad.cameraOffset.x;
			camFollow.y += dad.cameraOffset.y;
			return;
		}
		
		if (bf == null) return;
		camFollow.setPosition(bf.getMidpoint().x, bf.getMidpoint().y);
		camFollow.x -= bf.cameraOffset.x;
		camFollow.y += bf.cameraOffset.y;
	}

	function openPauseMenu() {
		persistentUpdate = false;
		Conductor.pause();
		paused = true;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);

		var menu:PauseMenu = new PauseMenu(songName, Difficulty.current, 0);
		openSubState(menu);
		menu.camera = camOther;
	}

	// in case someone wants to make their own accuracy calc
	dynamic function updateAccuracy():Float {
		return totalNotesPlayed / (totalNotesHit + comboBreaks);
	}

	dynamic function updateClearType():String {
		var sicks:Int = judgeData[0].hits;
		var goods:Int = judgeData[1].hits;
		var bads:Int = judgeData[2].hits;
		var shits:Int = judgeData[3].hits;

		var type:String = 'N/A';

		if (comboBreaks == 0) {
			if (bads > 0 || shits > 0) type = 'FC';
			else if (goods > 0) {
				if (goods == 1) type = 'BF';
				else if (goods <= 9) type = 'SDG';
				else if (goods >= 10) type = 'GFC';
			} else if (sicks > 0) type = 'PFC';
		} else {
			if (comboBreaks == 1) type = 'MF';
			else if (comboBreaks <= 9) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	// from troll engine
	// lol luhmao
	dynamic function updateGrade():String {
		var type:String = '?';
		if (totalNotesHit == 0) return type;
		
		final roundedAccuracy:Float = accuracy * 0.01;

		if (roundedAccuracy >= 1) return gradeSet[0][0]; // Uses first string
		else {
			for (curGrade in gradeSet) {
				if (roundedAccuracy <= curGrade[1]) continue;
				type = curGrade[0];
				break;
			}
		}
		
		return type;
	}

	dynamic function updateScoreTxt():Void {
		var textToShow:String = '';
		textToShow += 'Score: $score';

		if (!Settings.data.gameplaySettings['onlySicks']) {
			if (!Settings.data.gameplaySettings['instakill']) 
				textToShow += ' | Combo Breaks: $comboBreaks';

			textToShow += ' | Accuracy: ${Util.truncateFloat(accuracy, 2)}%';
			textToShow += ' [$clearType | $grade]';
		}

		scoreTxt.text = textToShow;
	}

	var keysHeld:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];
	inline function keyPressed(key:KeyCode, _):Void {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || keysHeld[dir] || paused) return;
		keysHeld[dir] = true;

		final sortedNotes:Array<Note> = notes.members.filter(function(note:Note):Bool {
			if (note == null) return false;
			return note.hittable && note.lane == dir && note.player && !note.isSustain;
		});

		if (sortedNotes.length == 0) {
			playerStrums.members[dir].playAnim('pressed');
			ScriptHandler.call('ghostTap', [dir]);
			if (Settings.data.ghostTapping) return;
			score -= 20;
			health -= 6;

			accuracy = updateAccuracy();
			grade = updateGrade();
			updateScoreTxt();
			return;
		} 

		sortedNotes.sort((a, b) -> Std.int(a.time - b.time));
		var note:Note = sortedNotes[0];
		noteHit(note);
		note.destroy();
		notes.remove(note);
		note = null;
	}

	inline function keyReleased(key:KeyCode, _):Void {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1) return;
		keysHeld[dir] = false;
		playerStrums.members[dir].playAnim('default');
	}

	override function destroy() {
		ScriptHandler.call('destroy');
		closeSubState();
		camGame.setFilters([]);

		Application.current.window.onKeyDown.remove(keyPressed);
		Application.current.window.onKeyUp.remove(keyReleased);

		stage.destroy();
		Judgement.resetHits();

		Conductor.rate = 1;
		FlxG.animationTimeScale = 1;

		ScriptHandler.clear();

		self = null;
		super.destroy();

		PauseMenu.openCount = 0;
	}
}