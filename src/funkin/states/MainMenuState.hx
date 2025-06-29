package funkin.states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import funkin.options.OptionsState;

class MainMenuState extends MusicState {
	public static var curSelected:Int = 0;
	public static var mouseControls:Bool = true;

	var optionGrp:FlxTypedSpriteGroup<FunkinSprite>;
	var camFollow:FlxObject;

	final options:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if AWARDS_ALLOWED 'awards', #end
		'credits',
		'options'
	];

	override function create() {
		super.create();

		persistentUpdate = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence();
		#end

		add(camFollow = new FlxObject(FlxG.width * 0.5, 0, 1, 1));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/yellowBG'));
		bg.antialiasing = Settings.data.antialiasing;
		bg.scrollFactor.set(0, Math.max(0.25 - (0.05 * (options.length - 4)), 0.1));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		add(optionGrp = new FlxTypedSpriteGroup<FunkinSprite>());

		// meth :broken_heart:
		var itemScrollY:Float = options.length < 6 ? 0 : (options.length - 4) * 0.135;
		var offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
		for (i => option in options) {
			var item:FunkinSprite = createItem(option, 0, (i * 140) + offset);
			optionGrp.add(item);

			item.scrollFactor.set(0, itemScrollY);
			item.updateHitbox();
			item.screenCenter(X);
		}

		changeSelection();

		final versions:FlxText = new FlxText(4, 683, 0, 'Psych Engine v${Main.psychEngineVersion}\nFriday Night Funkin\' v${Main.baseGameVersion}', 16);
		versions.font = Paths.font('vcr.ttf');
		versions.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versions.scrollFactor.set();
		add(versions);

		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.mouse.visible = true;
	}

	var actionPressed:Bool = false;
	override function update(elapsed:Float) {
		if (actionPressed) {
			super.update(elapsed);
			return;
		}

		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) changeSelection(downJustPressed ? 1 : -1);

		if (mouseControls && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)) {
			for (index => option in optionGrp.members) {
				if (!FlxG.mouse.overlaps(option) || curSelected == index) continue;

				changeSelection(index, true);
				break;
			}
		}

		if (Controls.justPressed('accept') || (mouseControls && FlxG.mouse.overlaps(optionGrp.members[curSelected]) && FlxG.mouse.justPressed)) {
			actionPressed = true;
			FlxG.sound.play(Paths.sound('confirm'));

			for (i => option in optionGrp.members) {
				if (i == curSelected) continue;

				FlxTween.tween(option, {alpha: 0}, 0.4, {
					ease: FlxEase.quadOut,
					onComplete: function(_) option.kill()
				});
			}

			FlxFlicker.flicker(optionGrp.members[curSelected], 1, 0.06, false, false, function(_) {
				switch (options[curSelected]) {
					case 'story_mode':
						MusicState.switchState(new StoryMenuState());
						
					case 'freeplay':
						MusicState.switchState(new FreeplayState());

					/*#if MODS_ALLOWED
					case 'mods':
						MusicState.switchState(new ModsMenuState());
					#end*/

					#if AWARDS_ALLOWED
					case 'awards':
						MusicState.switchState(new AchievementsMenuState());
					#end

					case 'credits':
						MusicState.switchState(new CreditsState());

					case 'options':
						if (!FlxG.keys.pressed.SHIFT)
							MusicState.switchState(new OptionsState());
						else
							MusicState.switchState(new funkin.options.NewOptionsMenu());
						funkin.substates.PauseMenu.wentToOptions = false;

					default:
						optionGrp.members[curSelected].alpha = 0.0;
						optionGrp.members[curSelected].visible = true;
						for (i => option in optionGrp.members) {
							if (!option.alive) option.revive();
							FlxTween.tween(option, {alpha: 1.0}, 0.2 * (i + 1), {ease: FlxEase.quadIn, startDelay: 0.5});
						}
						actionPressed = false;
						warn('"${options[curSelected]}" not implemented.');
				}
			});
		}

		if (Controls.justPressed('back')) {
			MusicState.switchState(new TitleState());
			actionPressed = true;
		}

		if (FlxG.keys.justPressed.SEVEN) MusicState.switchState(new funkin.states.editors.CharacterEditorState());

		super.update(elapsed);
	}

	function createItem(option:String, x:Float, y:Float):FunkinSprite {
		final item:FunkinSprite = new FunkinSprite(x, y);
		item.scrollFactor.set();
		item.frames = Paths.sparrowAtlas('menus/main/$option');
		item.animation.addByPrefix('idle', '$option idle', 24, true);
		item.animation.addByPrefix('selected', '$option selected', 24, true);
		item.playAnim('idle');
		return item;
	}

	function changeSelection(?dir:Int = 0, ?usingMouse:Bool = false) {
		final lastItem:FunkinSprite = optionGrp.members[curSelected];
		curSelected = usingMouse ? dir : FlxMath.wrap(curSelected + dir, 0, optionGrp.length - 1);
		final curItem:FunkinSprite = optionGrp.members[curSelected];

		lastItem.playAnim('idle');
		lastItem.updateHitbox();
		lastItem.screenCenter(X);

		curItem.playAnim('selected');
		curItem.centerOffsets();
		curItem.screenCenter(X);

		FlxG.sound.play(Paths.sound('scroll'));
		camFollow.y = curItem.getGraphicMidpoint().y - (optionGrp.length > 4 ? optionGrp.length * 8 : 0);
	}
}
