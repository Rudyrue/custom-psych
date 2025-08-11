package funkin.states;

import flixel.graphics.FlxGraphic;
import funkin.objects.Bar;

class AwardsState extends FunkinState {
	var grpAwards:FlxTypedSpriteGroup<FunkinSprite>;
	var nameTxt:FlxText;
	var descText:FlxText;
	var progressTxt:FlxText;
	var progressBar:Bar;
	var list:Array<String> = [];

	var camFollow:FlxObject;
	var MAX_PER_ROW:Int = 4;
	var curSelected:Int = 0;
	override function create():Void {
		super.create();

		for (award in Awards.list) {
			if (award.hidden && !Awards.isUnlocked(award.id)) continue;
			list.push(award.id);
		}

		var bg = new FunkinSprite(0, 0, Paths.image('menus/blueBG'));
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		grpAwards = new FlxTypedSpriteGroup<FunkinSprite>();
		grpAwards.scrollFactor.x = 0;
		add(camFollow = new FlxObject(0, 0, 1, 1));

		for (id in list) {
			var graphic:FlxGraphic = null;
			var path:String = 'awards/$id';
			var antialiasing:Bool = true;
			if (Awards.isUnlocked(id)) {
				if (Paths.exists('images/$path-pixel.png')) {
					graphic = Paths.image('$path-pixel');
					antialiasing = false;
				} else graphic = Paths.image(path);
			} else graphic = Paths.image('awards/locked');

			var spr = new FunkinSprite(0, Math.floor(grpAwards.members.length / MAX_PER_ROW) * 180, graphic);
			spr.scrollFactor.x = 0;
			spr.screenCenter(X);
			spr.x += 180 * ((grpAwards.members.length % MAX_PER_ROW) - MAX_PER_ROW / 2) + spr.width / 2 + 15;
			spr.antialiasing = antialiasing;
			spr.ID = grpAwards.members.length;
			grpAwards.add(spr);
		}

		var awardBox = new FunkinSprite(0, -30).makeGraphic(1, 1, FlxColor.BLACK);
		awardBox.scale.set(grpAwards.width + 60, grpAwards.height + 60);
		awardBox.updateHitbox();
		awardBox.alpha = 0.6;
		awardBox.scrollFactor.x = 0;
		awardBox.screenCenter(X);
		add(awardBox);
		add(grpAwards);

		var box = new FunkinSprite(0, 570).makeGraphic(1, 1, FlxColor.BLACK);
		box.scale.set(FlxG.width, FlxG.height - box.y);
		box.updateHitbox();
		box.alpha = 0.6;
		box.scrollFactor.set();
		add(box);

		add(nameTxt = new FlxText(50, box.y + 10, FlxG.width - 100, ''));
		nameTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameTxt.scrollFactor.set();

		add(descText = new FlxText(50, nameTxt.y + 38, FlxG.width - 100, ''));
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();

		add(progressBar = new Bar(0, descText.y + 52));
		progressBar.screenCenter(X);
		progressBar.scrollFactor.set();
		progressBar.active = false;
		
		add(progressTxt = new FlxText(50, progressBar.y - 6, FlxG.width - 100, '0 / 0'));
		progressTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressTxt.scrollFactor.set();
		progressTxt.borderSize = 2;

		changeSelection();
		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.camera.scroll.y = -FlxG.height;
	}

	function changeSelection() {
		var award = Awards.get(list[curSelected]);
		nameTxt.text = Awards.isUnlocked(award.id) ? award.name : '???';
		descText.text = award.description;
		progressBar.visible = award.maxScore > 0;
		progressTxt.visible = award.maxScore > 0;

		if (progressTxt.visible) {
			var currentProgress:Float = Util.truncateFloat(Awards.getScore(list[curSelected]), award.decimals);
			var maxProgress:Float = Util.truncateFloat(award.maxScore, award.decimals);
			progressTxt.text = '$currentProgress / $maxProgress';
		}

		var maxRows = Math.floor(grpAwards.members.length / MAX_PER_ROW);
		if (maxRows > 0) {
			var camY:Float = FlxG.height / 2 + (Math.floor(curSelected / MAX_PER_ROW) / maxRows) * Math.max(0, grpAwards.height - FlxG.height / 2 - 50) - 100;
			camFollow.setPosition(0, camY);
		} else camFollow.setPosition(0, grpAwards.members[curSelected].getGraphicMidpoint().y - 100);

		grpAwards.forEach(function(spr:FunkinSprite) {
			spr.alpha = 0.6;
			if (spr.ID == curSelected) spr.alpha = 1;
		});
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (Controls.justPressed('back')) {
			FunkinState.switchState(new MainMenuState());
		}

		var add:Int = 0;
		if (Controls.justPressed('ui_left')) add = -1;
		else if (Controls.justPressed('ui_right')) add = 1;

		if (add != 0) {
			var oldRow:Int = Math.floor(curSelected / MAX_PER_ROW);
			var rowSize:Int = Std.int(Math.min(MAX_PER_ROW, grpAwards.length - oldRow * MAX_PER_ROW));
				
			curSelected += add;
			var curRow:Int = Math.floor(curSelected / MAX_PER_ROW);
			if (curSelected >= grpAwards.length) curRow++;

			if (curRow != oldRow) {
				if (curRow < oldRow) curSelected += rowSize;
				else curSelected = curSelected -= rowSize;
			}
			changeSelection();
		}

		if (grpAwards.length > MAX_PER_ROW) {
			var add:Int = 0;
			if (Controls.justPressed('ui_up')) add = -1;
			else if (Controls.justPressed('ui_down')) add = 1;

			if (add != 0) {
				var diff:Int = curSelected - (Math.floor(curSelected / MAX_PER_ROW) * MAX_PER_ROW);
				curSelected += add * MAX_PER_ROW;
				if (curSelected < 0) {
					curSelected += Math.ceil(grpAwards.length / MAX_PER_ROW) * MAX_PER_ROW;
					if (curSelected >= grpAwards.length) curSelected -= MAX_PER_ROW;
				}

				if (curSelected >= grpAwards.length) curSelected = diff;
				changeSelection();
			}
		}
	}
}