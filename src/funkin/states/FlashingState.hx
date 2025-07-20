package funkin.states;

import flixel.effects.FlxFlicker;

class FlashingState extends flixel.FlxState {
	var warnText:FlxText;
	var pressedKey:Bool = false;
	override function create() {
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (pressedKey) return;

		var backJustPressed:Bool = Controls.justPressed('back');
		if (backJustPressed || Controls.justPressed('accept')) {
			pressedKey = true;
			FlxG.save.data.seenFlashWarning = true;
			if (backJustPressed) {
				FlxG.sound.play(Paths.sound('cancel'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (_) {
						FunkinState.switchState(new TitleState());
					}
				});

				return;
			}

			Settings.data.flashingLights = false;
			Settings.save();
			FlxG.sound.play(Paths.sound('confirm'));
			FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(_) {
				FunkinState.switchState(new TitleState());
			});	
		}
	}
}