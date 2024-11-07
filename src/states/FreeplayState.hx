package states;

import backend.WeekData;
import backend.Song;

import objects.HealthIcon;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

import flixel.text.FlxText;

class FreeplayState extends MusicState {
	var songList:Array<Track> = [];
	var difficultyList:Array<Array<String>> = [];

	static var curSelected:Int = 0;

	static var curDifficulty:Int;
	static var curDiffName:String = Difficulty.current;
	static var curDiffs:Array<String> = Difficulty.list;

	var grpSongs:FlxTypedSpriteGroup<Alphabet>;
	var grpIcons:FlxTypedSpriteGroup<HealthIcon>;

	var bg:FlxSprite;
	var intendedColour:Int;

	var intendedAccuracy:Float;
	var lerpAccuracy:Float;

	var lerpScore:Int;
	var intendedScore:Int = 0;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;

	var difficultyText:FlxText;

	var bottomBG:FlxSprite;
	var bottomText:FlxText;

	override function create() {
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reload();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (week in WeekData.list) {
			for (song in week.songs) {
				songList.push(song);

				var diffs:Array<String> = song.difficulties;
				if (song.difficulties == null || song.difficulties.length == 0) diffs = Difficulty.loadFromWeek(week);
				difficultyList.push(diffs);
			}
		}

		add(bg = new FlxSprite().loadGraphic(Paths.image('menus/desatBG')));
		bg.antialiasing = Settings.data.antialiasing;
		bg.screenCenter();
		bg.color = intendedColour = songList[curSelected].color;

		add(grpSongs = new FlxTypedSpriteGroup<Alphabet>());
		add(grpIcons = new FlxTypedSpriteGroup<HealthIcon>());

		for (index => song in songList) {
			final alphabet:Alphabet = grpSongs.add(new Alphabet(90, 320, song.id));
			alphabet.visible = alphabet.active = false;
			alphabet.targetY = index;
			alphabet.scaleX = Math.min(1, 980 / alphabet.width);
			alphabet.snapToPosition();

			var icon:HealthIcon = new HealthIcon(song.icon);
			icon.visible = icon.active = false;
			grpIcons.add(icon);
		}

		scoreText = new FlxText(FlxG.width - 384, 5, 0, '', 32);
		scoreText.font = Paths.font('vcr.ttf');
		scoreText.alignment = 'right';

		add(scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000));
		scoreBG.alpha = 0.6;

		add(scoreText);

		add(difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, '', 24));
		difficultyText.font = scoreText.font;

		add(bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000));
		bottomBG.alpha = 0.6;

		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.", 16);
		bottomText.font = Paths.font("vcr.ttf");
		bottomText.alignment = 'center';
		bottomText.scrollFactor.set();
		add(bottomText);

		changeSelection();
		updateTexts();
		super.create();
	}

	var holdTime:Float;
	override function update(elapsed:Float) {
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpAccuracy = FlxMath.lerp(intendedAccuracy, lerpAccuracy, Math.exp(-elapsed * 12));
		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01) lerpAccuracy = intendedAccuracy;

		var accuracy:Array<String> = '${Util.truncateFloat(lerpAccuracy, 2)}'.split('.');
		if (accuracy.length < 2) accuracy.push(''); // No decimals, add an empty space
		while (accuracy[1].length < 2) accuracy[1] += '0'; // Less than 2 decimals in it, add decimals then
		accuracy.join('.');

		scoreText.text = 'PERSONAL BEST: $lerpScore ($accuracy%)';

		positionStats();

		songControls(elapsed);
		difficultyControls();
		updateTexts(elapsed);
		super.update(elapsed);

		if (Controls.justPressed('back')) MusicState.switchState(new MainMenuState());
	}

	function songControls(elapsed:Float) {
		if (songList.length == 1) return;

		if (FlxG.keys.justPressed.HOME) {
			curSelected = 0;
			changeSelection();
			holdTime = 0;	
		} else if (FlxG.keys.justPressed.END) {
			curSelected = songList.length - 1;
			changeSelection();
			holdTime = 0;	
		}

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? shiftMult : -shiftMult);
			holdTime = 0;
		}

		final downPressed:Bool = Controls.pressed('ui_down');
		if (downPressed || Controls.pressed('ui_up')) {
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				changeSelection((checkNewHold - checkLastHold) * (downPressed ? shiftMult : -shiftMult));
		}

		if (FlxG.mouse.wheel != 0) changeSelection(-shiftMult * FlxG.mouse.wheel, 0.2);
	}

	function difficultyControls() {
		if (curDiffs.length == 1) return;

		final leftPressed:Bool = Controls.justPressed('ui_left');
		if (leftPressed || Controls.justPressed('ui_right')) changeDifficulty(leftPressed ? -1 : 1);
	}

	function positionStats() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x * 0.5);
		difficultyText.x = Std.int(scoreBG.x + (scoreBG.width * 0.5));
		difficultyText.x -= difficultyText.width * 0.5;
	}

	function changeSelection(?change:Int = 0, ?volume:Float = 0.4) {
		curSelected = FlxMath.wrap(curSelected + change, 0, songList.length - 1);
		if (volume > 0.0) FlxG.sound.play(Paths.sound('scroll'), volume);

		for (num => item in grpSongs.members) {
			item.alpha = num == curSelected ? 1 : 0.6;
			grpIcons.members[num].alpha = num == curSelected ? 1 : 0.6;
		}

		var newColour:Int = songList[curSelected].color;
		if (newColour != intendedColour) {
			intendedColour = newColour;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColour);
		}

		curDiffs = difficultyList[curSelected];

		curDifficulty = curDiffs.indexOf(curDiffName);
		if (curDifficulty == -1) curDifficulty = 0;
		changeDifficulty();
	}

	function changeDifficulty(?change:Int = 0) {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDiffs.length - 1);

		curDiffName = curDiffs[curDifficulty];
		var displayDiff:String = curDiffName.toUpperCase();
		difficultyText.text = curDiffs.length == 1 ? displayDiff : '< $displayDiff >';

		intendedScore = FlxG.random.int(0, 500000);
		intendedAccuracy = FlxG.random.float(0, 100);

		positionStats();
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	var lerpSelected:Float = 0.0;
	public function updateTexts(elapsed:Float = 0.0) {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles) {
			var text:Alphabet = grpSongs.members[i];

			text.visible = text.active = false;
			grpIcons.members[i].visible = false;
		}
		_lastVisibles.resize(0);

		var min:Int = Math.round(FlxMath.bound(lerpSelected - _drawDistance, 0, songList.length));
		var max:Int = Math.round(FlxMath.bound(lerpSelected + _drawDistance, 0, songList.length));
		for (i in min...max) {
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;

			var icon:HealthIcon = grpIcons.members[i];
			icon.visible = true;
			icon.setPosition(item.x + (item.width + (icon.width * 0.05)), item.y - (item.height * 0.5));
			_lastVisibles.push(i);
		}
	}	
}