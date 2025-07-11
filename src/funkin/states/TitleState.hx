package funkin.states;

import flixel.graphics.frames.FlxFrame;

typedef TitleData = {
	var gfPos:Array<Float>;
	var logoPos:Array<Float>;
	var textPos:Array<Float>;
	
	var bpm:Float;

	var ?animation:String;
	var ?dance_left:Array<Int>;
	var ?dance_right:Array<Int>;
	var ?idle:Bool;
	var ?background:String;
}

class TitleState extends FunkinState {
	override public function create():Void {
		// forces a null object ref
		// for testing crashing
		// thumbs up emoji
		//var fuck:FlxSprite = null;
		//fuck.visible = true;

		FunkinState.skipNextTransIn = FunkinState.skipNextTransOut = true;

		Paths.clearStoredMemory();
		super.create();
		persistentUpdate = true;

		FlxG.mouse.visible = false;
		startIntro();
	}

	var logo:FlxSprite;
	var gf:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	var alphabet:Alphabet;
	var introGroup:FlxSpriteGroup;
	var ngSpr:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	public static var seenIntro:Bool = false;

	function startIntro() {
		loadJsonData();
		curWacky = FlxG.random.getObject(getIntroTexts());

		add(introGroup = new FlxSpriteGroup());
		introGroup.visible = false;

		logo = new FlxSprite(logoPosition.x, logoPosition.y);
		logo.frames = Paths.sparrowAtlas('menus/title/logo');
		logo.antialiasing = Settings.data.antialiasing;
		logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logo.animation.play('bump');
		logo.updateHitbox();

		gf = new FlxSprite(gfPosition.x, gfPosition.y);
		gf.frames = Paths.sparrowAtlas('menus/title/gfTitle');
		gf.antialiasing = Settings.data.antialiasing;
		if (!useIdle) 	{
			gf.animation.addByIndices('danceLeft', animationName, danceLeftFrames, '', 24, false);
			gf.animation.addByIndices('danceRight', animationName, danceRightFrames, '', 24, false);
			gf.animation.play('danceRight');
		} else {
			gf.animation.addByPrefix('idle', animationName, 24, false);
			gf.animation.play('idle');
		}

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.sparrowAtlas('menus/title/pressEnter');
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (newTitle = animFrames.length > 0) {
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', Settings.data.flashingLights ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		} else {
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();

		ngSpr = new FlxSprite(0, FlxG.height - 346).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Math.floor(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = Settings.data.antialiasing;

		add(alphabet = new Alphabet(0, 200, '', BOLD, CENTER));
		alphabet.fieldWidth = FlxG.width;
		//alphabet.screenCenter(X);

		introGroup.add(gf);
		introGroup.add(logo); //FNF Logo
		introGroup.add(titleText); //"Press Enter to Begin" text
		add(ngSpr);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence();
		#end

		Conductor.bpm = bpm;
		Conductor.playing = true;
		if (seenIntro) {
			skipIntro();

			// so that you doesn't have to restart the game every time
			Meta.cacheFiles(true);
			return;
		}

		Conductor.inst = FlxG.sound.load(Paths.music('freakyMenu'), 0, true);
		Conductor.play();
		Conductor.inst.fadeIn(4, 0, 0.7);
	}

	var animationName:String = 'gfDance';

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	
	var useIdle:Bool = false;
	var bpm:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];	

	function loadJsonData() {
		if (!Paths.exists('data/titleData.json')) {
			warn('No Title JSON detected, using default values.');
			return;
		}

		var titleRaw:String = Paths.getFileContent('data/titleData.json');
		if (titleRaw == null || titleRaw.length == 0) return;

		try {
			var data:TitleData = cast Json5.parse(titleRaw);
			gfPosition.set(data.gfPos[0], data.gfPos[1]);
			logoPosition.set(data.logoPos[0], data.logoPos[1]);
			enterPosition.set(data.textPos[0], data.textPos[1]);
			bpm = data.bpm;
					
			if (data?.animation.length > 0) animationName = data.animation;
			if (data?.dance_left.length > 0) danceLeftFrames = data.dance_left;
			if (data?.dance_right.length > 0) danceRightFrames = data.dance_right;
			useIdle = data.idle;
	
			if (data.background != null && data.background.trim().length > 0) {
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(data.background));
				bg.antialiasing = Settings.data.antialiasing;
				add(bg);
			}
		} catch(e:haxe.Exception) warn('Title JSON might be broken, ignoring issue...\n${e.details()}');
	}

	function getIntroTexts():Array<Array<String>> 
		return [for (i in File.getContent(Paths.text('introText.txt')).split('\n')) i.split('--')];
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	function updateTitleText(elapsed:Float) {
		if (!newTitle || !seenIntro || skipped) return;

		titleTimer += FlxMath.bound(elapsed, 0, 1);
		if (titleTimer > 2) titleTimer -= 2;

		var timer:Float = titleTimer;
		if (timer >= 1) timer = -timer + 2;
				
		timer = FlxEase.quadInOut(timer);
				
		titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
		titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
	}

	var skipped:Bool = false;
	var transitionTmr:FlxTimer;
	override function update(elapsed:Float) {
		updateTitleText(elapsed);

		if (Controls.justPressed('accept') || FlxG.mouse.justPressed) {
			if (!seenIntro) skipIntro();
			else if (skipped) {
				if (transitionTmr != null) {
					transitionTmr.cancel();
					transitionTmr = null;
				}

				FunkinState.switchState(new MainMenuState());
			} else {
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				titleText.animation.play('press');

				FlxG.camera.flash(Settings.data.flashingLights ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirm'), 0.7);
				skipped = true;
				transitionTmr = new FlxTimer().start(1.5, function(_) {
					FunkinState.switchState(new MainMenuState());
				});
			}
		}

		super.update(elapsed);
	}

	var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	override function beatHit(beat:Int) {
		super.beatHit(beat);

		logo.animation.play('bump', true);

		danceLeft = !danceLeft;
		if (!useIdle) gf.animation.play((danceLeft ? 'danceRight' : 'danceLeft'));
		else if (curBeat % 2 == 0) gf.animation.play('idle');

		if (seenIntro) return;

		sickBeats++;
		switch (sickBeats) {
			case 1:
				alphabet.y += 40;
				alphabet.text += 'Psych Engine by';
			case 3:
				alphabet.text += '\nShadow Mario\nRiveren';
			case 4:
				alphabet.text = '';
			case 5:
				alphabet.y -= 40;
				alphabet.text += 'Not associated\nwith';
			case 7:
				alphabet.text += '\nNewgrounds';
				ngSpr.visible = true;
			case 8:
				alphabet.text = '';
				ngSpr.visible = false;
			case 9:
				alphabet.text += curWacky[0];
			case 11:
				alphabet.text += '\n${curWacky[1]}';
			case 12:
				alphabet.text = '';
			case 13:
				alphabet.text += 'Friday';
			case 14:
				alphabet.text += '\nNight';
			case 15:
				alphabet.text += '\nFunkin';
			case 16:
				skipIntro();
		}
	}

	function skipIntro():Void {
		remove(ngSpr);
		remove(alphabet);
		introGroup.visible = true;
		FlxG.camera.flash(FlxColor.WHITE, 2);
		seenIntro = true;
	}
}
