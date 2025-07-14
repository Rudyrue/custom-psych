package funkin.huds;

import funkin.objects.Bar;
import funkin.objects.CharIcon;
import funkin.objects.JudgementSpr;
import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;
import funkin.objects.Note;
import funkin.objects.ComboNums;
import funkin.backend.Judgement;

class DefaultHUD extends HUD {
	var timeBar:Bar;
	var timeTxt:FlxText;
	var healthBar:Bar;
	var iconP1:CharIcon;
	var iconP2:CharIcon;
	var scoreTxt:FlxText;
	var botplayTxt:FlxText;
	var judgeCounter:FlxText;
	var judgeSpr:JudgementSpr;
	var comboNumbers:ComboNums;
	var songPercent:Float = 0;
	var iconSpacing:Float = 20;
	var botplayTxtSine:Float = 0;
	var grade:String;
	var clearType:String;
	var updateTime:Bool;

	var gradeSet:Array<Array<Dynamic>> = [
		["Perfect!!", 1],
		["Sick!", 0.9],
		["Great", 0.8],
		["Good", 0.7],
		["Nice", 0.69],
		["Meh", 0.6],
		["Bruh", 0.5],
		["Bad", 0.4],
		["Shit", 0.2],
		["You Suck!", 0],
		["WHAT THE FUCK", Math.NaN]
	];

	public function new(songName:String, ?difficulty:String) {
		super(songName, difficulty);
		this.name = 'Default';

		add(timeBar = new Bar(0, 0, 'timeBar', function() return songPercent, 0, 1));
		timeBar.setColors(0xFFFFFFFF, 0xFF000000);
		timeBar.screenCenter(X);

		timeBar.visible = Settings.data.timeBarType != 'Disabled';

		// doing it in here instead
		// doing it in playstate runs the risk of adding another hud
		// and it breaking because these colours don't fit with that hud

		// i hate doing this but if it stops it from breaking it's good enough for me :sob:
		setTimeBarColors(game.bf.healthColor, game.dad.healthColor);

		add(timeTxt = new FlxText(0, 0, timeBar.width, '$songName - 0:00', 16));
		timeTxt.font = Paths.font('vcr.ttf');
		timeTxt.alignment = 'center';
		timeTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		timeTxt.borderColor = FlxColor.BLACK;
		timeTxt.borderSize = 1.25;
		timeTxt.visible = Settings.data.timeBarType != 'Disabled';
		updateTime = Settings.data.timeBarType != 'Disabled';

		add(healthBar = new Bar(0, 0, 'healthBar', function() return game.health, 0, 100));
		healthBar.alpha = Settings.data.healthBarAlpha;
		setHealthColors(game.dad.healthColor, game.bf.healthColor);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;

		add(iconP1 = new CharIcon(game.bf.icon, true));
		iconP1.alpha = Settings.data.healthBarAlpha;

		add(iconP2 = new CharIcon(game.dad.icon));
		iconP2.alpha = Settings.data.healthBarAlpha;

		updateIconPositions();

		add(scoreTxt = new FlxText(0, 0, FlxG.width, '', 16));
		scoreTxt.font = Paths.font('vcr.ttf');
		scoreTxt.alignment = 'center';
		scoreTxt.alpha = Settings.data.scoreAlpha;
		scoreTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreTxt.borderColor = FlxColor.BLACK;
		scoreTxt.borderSize = 1.25;
		scoreTxt.screenCenter(X);

		add(judgeSpr = new JudgementSpr(Settings.data.judgePosition[0], Settings.data.judgePosition[1]));
		add(comboNumbers = new ComboNums(Settings.data.comboPosition[0], Settings.data.comboPosition[1]));

		add(judgeCounter = new FlxText(0, 0, 500, '', 20));
		judgeCounter.font = Paths.font('vcr.ttf');
		judgeCounter.borderStyle = FlxTextBorderStyle.OUTLINE;
		judgeCounter.borderColor = FlxColor.BLACK;
		judgeCounter.borderSize = 1.25;
		updateJudgeCounter();
		judgeCounter.screenCenter(Y);
		judgeCounter.visible = Settings.data.judgementCounter;

		add(botplayTxt = new FlxText(0, 0, FlxG.width - 800, 'BOTPLAY', 32));
		botplayTxt.font = Paths.font('vcr.ttf');
		botplayTxt.alignment = CENTER;
		botplayTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		botplayTxt.borderColor = FlxColor.BLACK;
		botplayTxt.borderSize = 1.25;
		botplayTxt.screenCenter(X);

		grade = updateGrade();
		clearType = updateClearType();
		updateScoreTxt();
	}

	function updateIconPositions():Void {
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconSpacing;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconSpacing * 2;
	}

	override function eventTriggered(event:Event) {
		switch event.name {
			case 'Change Character':
				var type:Int = Std.parseInt(event.args[0]);
				var name:String = Std.string(event.args[1]);

				if (type == 0) iconP2.change(name);
				else if (type == 2) iconP1.change(name);
		}
	}

	dynamic function updateJudgeCounter() {
		if (!Settings.data.judgementCounter) return;
		
		var sicks:Int = Judgement.list[0].hits;
		var goods:Int = Judgement.list[1].hits;
		var bads:Int = Judgement.list[2].hits;
		var shits:Int = Judgement.list[3].hits;

		judgeCounter.text = 'Sicks: $sicks\nGoods: $goods\nBads: $bads\nShits: $shits';
	}

	function updateIconScales(delta:Float):Void {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-delta * 9 * Conductor.rate));
		iconP1.scale.set(mult, mult);
		iconP1.centerOrigin();

		mult = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-delta * 9 * Conductor.rate));
		iconP2.scale.set(mult, mult);
		iconP2.centerOrigin();
	}

	override function setTimeBarColors(a:FlxColor, ?b:FlxColor) {
		super.setTimeBarColors(a, b);
		FlxGradient.overlayGradientOnFlxSprite(timeBar.leftBar, Std.int(timeBar.leftBar.width), Std.int(timeBar.leftBar.height), [a, b], 0, 0, 1, 180);
	}

	override function setHealthColors(a:FlxColor, ?b:FlxColor) {
		super.setHealthColors(a, b);
		healthBar.setColors(a, b);
	}

	override function healthChange(value:Float) {
		healthBar.percent = FlxMath.remapToRange(FlxMath.bound(value, healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		iconP1.animation.curAnim.curFrame = healthBar.percent < 20 ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = healthBar.percent > 80 ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		updateTimeBar();
		updateIconScales(elapsed);
		updateIconPositions();

		if (botplayTxt.visible) {
			botplayTxtSine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplayTxtSine) / 180);
		}
	}

	override function beatHit(beat:Int):Void {
		iconP1.scale.set(1.2, 1.2);
		iconP1.updateHitbox();

		iconP2.scale.set(1.2, 1.2);
		iconP2.updateHitbox();
	}

	override function noteHit(_, note:Note, judgement:Judgement):Void {
		if (playerID != note.player) return;

		if (!note.breakOnHit) {
			if (!Settings.data.hideTightestJudge || Judgement.list.indexOf(judgement) > 0) {
				judgeSpr.display(note.rawHitTime);
			}
			comboNumbers.display(game.combo);
		}

		grade = updateGrade();
		clearType = updateClearType();
		updateScoreTxt();
		updateJudgeCounter();
	}

	override function noteMiss(_, _) {
		grade = updateGrade();
		clearType = updateClearType();
		updateScoreTxt();
	}

	override function ghostTap(_) {
		grade = updateGrade();
		clearType = updateClearType();
		updateScoreTxt();
	}

	dynamic function updateScoreTxt():Void {
		var textToShow:String = 'Score: ${game.score}';

		if (!Settings.data.gameplayModifiers['onlySicks']) {
			if (!Settings.data.gameplayModifiers['instakill']) 
				textToShow += ' | Combo Breaks: ${game.comboBreaks}';

			textToShow += ' | Accuracy: ${Util.truncateFloat(game.accuracy, 2)}%';
			textToShow += ' [$clearType | $grade]';
		}

		scoreTxt.text = textToShow;
	}

	var _lastSeconds:Int = -1;
	dynamic function updateTimeBar() {
		if (paused || !updateTime) return;

		var curTime:Float = Math.max(0, Conductor.rawTime);

		songPercent = (curTime / Conductor.length);

		var songCalc:Float = (Conductor.length - curTime);
		if (Settings.data.timeBarType == 'Time Elapsed') songCalc = curTime;

		var seconds:Int = Math.floor((songCalc / Conductor.rate) * 0.001);
		if (seconds < 0) seconds = 0;

		if (seconds == _lastSeconds) return;

		var textToShow:String = '$songName';
		if (Conductor.rate != 1) textToShow += ' (${Conductor.rate}x)';
		if (Settings.data.timeBarType != 'Song Name') textToShow += ' - ${FlxStringUtil.formatTime(seconds, false)}';

		timeTxt.text = textToShow;
		_lastSeconds = seconds;
	}

	override function set_downscroll(v:Bool):Bool {
		timeBar.y = v ? FlxG.height - 30 : 15;
		timeTxt.setPosition(timeBar.getMidpoint().x - (timeTxt.width * 0.5), timeBar.getMidpoint().y - (timeTxt.height * 0.5));
		healthBar.y = v ? 55 : 640;
		iconP1.y = healthBar.y - (iconP1.height * 0.5);
		iconP2.y = healthBar.y - (iconP2.height * 0.5);
		scoreTxt.y = v ? 21 : FlxG.height - 39;
		botplayTxt.y = v ? FlxG.height - 115 : 85;

		return super.set_downscroll(v);
	}

	override function set_playerID(v:Int):Int {
		judgeCounter.alignment = v == 0 ? 'right' : 'left';
		judgeCounter.x = v == 0 ? (FlxG.width - judgeCounter.width) - 5 : 5;

		return super.set_playerID(v);
	}

	override function set_botplay(v:Bool):Bool {
		botplayTxt.visible = v;

		return super.set_botplay(v);
	}

	dynamic function updateClearType():String {
		var sicks:Int = Judgement.list[0].hits;
		var goods:Int = Judgement.list[1].hits;
		var bads:Int = Judgement.list[2].hits;
		var shits:Int = Judgement.list[3].hits;

		var type:String = 'N/A';

		if (game.comboBreaks == 0) {
			if (bads > 0 || shits > 0) type = 'FC';
			else if (goods > 0) {
				if (goods == 1) type = 'BF';
				else if (goods <= 9) type = 'SDG';
				else if (goods >= 10) type = 'GFC';
			} else if (sicks > 0) type = 'PFC';
		} else {
			if (game.comboBreaks == 1) type = 'MF';
			else if (game.comboBreaks <= 9) type = 'SDCB';
			else type = 'Clear';
		}

		return type;
	}

	// from troll engine
	// lol luhmao
	dynamic function updateGrade():String {
		var type:String = '?';
		if (game.totalNotesHit == 0) return type;
		
		final roundedAccuracy:Float = game.accuracy * 0.01;

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
}