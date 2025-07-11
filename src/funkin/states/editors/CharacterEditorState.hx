package funkin.states.editors;

import funkin.objects.Character;
import funkin.objects.CharIcon;
import funkin.objects.Bar;
import funkin.backend.ui.*;
import openfl.net.FileReference;
import openfl.events.Event;
import flixel.graphics.FlxGraphic;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import openfl.events.IOErrorEvent;

class CharacterEditorState extends FunkinState implements PsychUIEventHandler.PsychUIEvent {
	var _characterFile:CharacterFile = Character.createDummyFile();
	var name:String = 'bf';
	var character:Character;
	var ghost:FunkinSprite;
	var camHUD:FlxCamera;
	
	var characterUIBox:PsychUIBox;
	var mainUIBox:PsychUIBox;

	var healthBar:Bar;
	var icon:CharIcon;
	var animsTxt:FlxText;
	var curAnim:Int = 0;
	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);
	var cameraFollowPointer:FlxSprite;

	var anims(get, never):Array<CharacterAnim>;
	function get_anims():Array<CharacterAnim> return _characterFile.animations;

	override function create():Void {
		super.create();

        Conductor.stop();
		FlxG.autoPause = false;
        FlxG.sound.playMusic(Paths.music('artisticExpression'), 1, true);
		FlxG.camera.bgColor = 0xFF4C4C4C;

		camHUD = FlxG.cameras.add(new FlxCamera(), false);
		camHUD.bgColor.alpha = 0;
		
		add(ghost = new FunkinSprite());
		ghost.visible = false;
		ghost.alpha = ghostAlpha;

		add(new FlxSprite().loadGraphic(Paths.image('silhouette')));



		add(healthBar = new Bar(30, FlxG.height - 75));
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		add(icon = new CharIcon('face'));
		icon.y = FlxG.height - 150;
		icon.camera = camHUD;

		add(animsTxt = new FlxText(10, Settings.data.fpsCounter ? 64 : 16, 400, ''));
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.camera = camHUD;

		reloadCharacter();
		makeUI();

		add(cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross)));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		updateCameraPointer(true);
	}

    override function update(delta:Float):Void {
        super.update(delta);

		if (PsychUIInputText.focusOn != null) {
			Controls.toggleVolumeKeys(false);
			return;
		}
		Controls.toggleVolumeKeys(true);

        if (Controls.justPressed('back')) {
            FunkinState.switchState(new MainMenuState());
        }

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT) {
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		if (FlxG.keys.pressed.A) FlxG.camera.scroll.x -= delta * 500;
		if (FlxG.keys.pressed.S) FlxG.camera.scroll.y += delta * 500;
		if (FlxG.keys.pressed.D) FlxG.camera.scroll.x += delta * 500;
		if (FlxG.keys.pressed.W) FlxG.camera.scroll.y -= delta * 500;

		if (FlxG.keys.justPressed.R) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += delta * FlxG.camera.zoom;
			if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		} else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= delta * FlxG.camera.zoom;
			if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		var changedAnim:Bool = false;
		if (anims.length > 1) {
	    	if (FlxG.keys.justPressed.UP && (changedAnim = true)) curAnim--;
			else if (FlxG.keys.justPressed.DOWN && (changedAnim = true)) curAnim++;

			if (changedAnim) {
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].name, true);
				updateText();
			}
		}

		var anim:CharacterAnim = anims[curAnim];
		var changedOffset:Bool = false;
		var moveKeysP:Array<Bool> = [FlxG.keys.justPressed.J, FlxG.keys.justPressed.L, FlxG.keys.justPressed.I, FlxG.keys.justPressed.K];
		if (moveKeysP.contains(true)) {
			anim.offsets[0] += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			anim.offsets[1] += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
			character.setOffset(anim.name, anim.offsets);
			updateText();

			// ????????
			// character.x /= _characterFile.scale;
			// character.y /= _characterFile.scale;
		}

		if (character.animation.curAnim != null) {
			if (FlxG.keys.justPressed.SPACE || changedOffset) 
				character.playAnim(character.animation.curAnim.name, true);
		}
    }

    override function destroy():Void {
        FlxG.sound.music.stop();
		Conductor.play();
		FlxG.autoPause = Settings.data.autoPause;
        super.destroy();
		FlxG.camera.bgColor = 0xFF000000;
    }

	public function UIEvent(id:String, sender:Dynamic) {
		switch id {
			case PsychUIInputText.CHANGE_EVENT:
				if (sender == healthColourInputText) {
					_characterFile.healthColor = Std.parseInt(healthColourInputText.text);
					healthBar.rightBar.color = Std.parseInt(healthColourInputText.text);
				}

				if (sender == iconInputText) {
					_characterFile.icon = iconInputText.text;
					icon.change(iconInputText.text);
				}

			case PsychUINumericStepper.CHANGE_EVENT:
				if (sender == scaleStepper) {
					_characterFile.scale = scaleStepper.value;
					character.scale.set(scaleStepper.value, scaleStepper.value);
					character.updateHitbox();
				}

				if (sender == singDurationStepper) {
					_characterFile.singDuration = singDurationStepper.value;
					character.singDuration = singDurationStepper.value;
				}

				if (sender == danceIntervalStepper) {
					_characterFile.danceInterval = Math.floor(danceIntervalStepper.value);
				}

				if (sender == positionOffsetXStepper) {
					_characterFile.offset[0] = positionOffsetXStepper.value;
					character.offset.x = positionOffsetXStepper.value * _characterFile.scale;
				}

				if (sender == positionOffsetYStepper) {
					_characterFile.offset[1] = positionOffsetYStepper.value;
					character.offset.y = positionOffsetYStepper.value * _characterFile.scale;
				}

				if (sender == cameraOffsetXStepper) {
					_characterFile.cameraOffset[0] = cameraOffsetXStepper.value;
					updateCameraPointer();
				}

				if (sender == cameraOffsetYStepper) {
					_characterFile.cameraOffset[1] = cameraOffsetYStepper.value;
					updateCameraPointer();
				}

			case _:
		}
	}

	function reloadCharacter() {
		if (character != null) {
			remove(character);
			character.destroy();
		}

		add(character = new Character(0, 0, name));
		character.inEditor = true;

		_characterFile = character.file;
		healthBar.rightBar.color = _characterFile.healthColor;
		icon.change(_characterFile.icon);
		reloadAnimList();
	}

	function makeUI():Void {
		add(characterUIBox = new PsychUIBox((FlxG.width - 275) - 100, 155, 350, 310, ['Character', 'Animations']));
		characterUIBox.scrollFactor.set();
		characterUIBox.cameras = [camHUD];
		characterUIBox.canMinimize = false;

		add(mainUIBox = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']));
		mainUIBox.scrollFactor.set();
		mainUIBox.cameras = [camHUD];
		mainUIBox.canMinimize = false;

		addCharacterTab();
		addAnimationTab();
		addGhostUI();
		addSettingsUI();
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI():Void {
		var tabMenu:FlxSpriteGroup = mainUIBox.getTab('Ghost').menu;

		// Make Ghost
		tabMenu.add(new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim:CharacterAnim = anims[curAnim];

			ghost.antialiasing = _characterFile.antialiasing;
			ghost.flipX = _characterFile.flipX;
			ghost.alpha = ghostAlpha;

			ghost.setPosition(character.x, character.y);
			ghost.scale.set(_characterFile.scale, _characterFile.scale);
			ghost.loadGraphicFromSprite(character);
			ghost.visible = true;

			ghost.updateHitbox();
			ghost.offset.copyFrom(character.offset);

			if (character.animation.curAnim == null) return;

			ghost.frameOffset.set(anim.offsets[0], anim.offsets[1]);
			ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
			ghost.animation.pause();
		}));

		// Highlight Ghost
		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(125, 15, "Highlight Ghost", 100);
		tabMenu.add(highlightGhost);
		highlightGhost.onClick = function() {
			var value:Int = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
		}

		// Alpha Slider
		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, 40, function(v:Float) {
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';
		tabMenu.add(ghostAlphaSlider);
	}

	var charListDropDown:PsychUIDropDownMenu;
	function addSettingsUI():Void {
		var tabMenu:FlxSpriteGroup = mainUIBox.getTab('Settings').menu;

		// Reload Character
		var reloadCharButton:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function() {
			reloadCharacter();
			reloadCharacterOptions();
		});
		tabMenu.add(reloadCharButton);

		// Template Character
		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function() {
			_characterFile = Character.createDummyFile();
			reloadCharacterImage();
			reloadCharacterOptions();
			reloadAnimList();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;
		tabMenu.add(templateCharacter);

		// Character List
		charListDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String) {
			if (intended == null || intended.length == 0) return;
			
			if (Paths.exists('characters/$intended.json')) {
				name = intended;
				reloadCharacter();
				reloadCharacterOptions();
				updateText();
			} else {
				FlxG.sound.play(Paths.sound('cancel'));
			}
		});
		tabMenu.add(new FlxText(charListDropDown.x, charListDropDown.y - 14, 80, 'Character:'));
		tabMenu.add(charListDropDown);
		reloadCharacterDropDown();		
	}

	var imageInputText:PsychUIInputText;
	var iconInputText:PsychUIInputText;
	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var healthColourInputText:PsychUIInputText;
	var flipXCheckBox:PsychUICheckBox;
	var antialiasingCheckBox:PsychUICheckBox;
	var positionOffsetXStepper:PsychUINumericStepper;
	var positionOffsetYStepper:PsychUINumericStepper;
	var cameraOffsetXStepper:PsychUINumericStepper;
	var cameraOffsetYStepper:PsychUINumericStepper;
	var danceIntervalStepper:PsychUINumericStepper;
	function addCharacterTab():Void {
		var tabMenu:FlxSpriteGroup = characterUIBox.getTab('Character').menu;

		// Sheet(s)
		tabMenu.add(imageInputText = new PsychUIInputText(15, 30, 200, _characterFile.sheets, 8));
		tabMenu.add(new FlxText(imageInputText.x, imageInputText.y - 14, 100, 'Sheet(s):'));

		// Reload Image
		var reloadImage:PsychUIButton = new PsychUIButton(225, 27, "Reload Image", function() {
			_characterFile.sheets = imageInputText.text;
			reloadCharacterImage();
		});
		tabMenu.add(reloadImage);

		// Position Offset
		tabMenu.add(positionOffsetXStepper = new PsychUINumericStepper(15, 230, 5, _characterFile.offset[0], -5000, 5000, 0));
		tabMenu.add(new FlxText(positionOffsetXStepper.x, positionOffsetXStepper.y - 14, 100, 'Position Offset (X):'));

		tabMenu.add(positionOffsetYStepper = new PsychUINumericStepper(15, 265, 5, _characterFile.offset[1], -5000, 5000, 0));
		tabMenu.add(new FlxText(positionOffsetYStepper.x, positionOffsetYStepper.y - 14, 100, 'Position Offset (Y):'));

		// Camera Offset
		tabMenu.add(cameraOffsetXStepper = new PsychUINumericStepper(125, 230, 5, _characterFile.cameraOffset[0], -5000, 5000, 0));
		tabMenu.add(new FlxText(cameraOffsetXStepper.x, cameraOffsetXStepper.y - 14, 100, 'Camera Offset (X):'));

		tabMenu.add(cameraOffsetYStepper = new PsychUINumericStepper(125, 265, 5, _characterFile.cameraOffset[1], -5000, 5000, 0));
		tabMenu.add(new FlxText(cameraOffsetYStepper.x, cameraOffsetYStepper.y - 14, 100, 'Camera Offset (Y):'));

		// Dance Interval
		tabMenu.add(danceIntervalStepper = new PsychUINumericStepper(125, 180, 1, _characterFile.danceInterval, 0, 8, 0));
		tabMenu.add(new FlxText(danceIntervalStepper.x, danceIntervalStepper.y - 14, 100, 'Dance Interval:'));

		// Icon
		tabMenu.add(iconInputText = new PsychUIInputText(15, 66, 75, icon.name, 8));
		tabMenu.add(new FlxText(iconInputText.x, iconInputText.y - 14, 100, 'Icon Name:'));

		// Get Icon Colour
		tabMenu.add(new PsychUIButton(225, 57, "Get Icon Colour", function() {
			var newColor:FlxColor = Util.dominantColor(icon);
			healthColourInputText.text = newColor.toHexString();
			healthBar.rightBar.color = newColor;
		}));

		// Sing Duration
		tabMenu.add(singDurationStepper = new PsychUINumericStepper(15, 104, 0.1, _characterFile.singDuration, 0, 999, 1));
		tabMenu.add(new FlxText(singDurationStepper.x, singDurationStepper.y - 14, 120, 'Sing Duration:'));

		// Scale
		tabMenu.add(scaleStepper = new PsychUINumericStepper(15, 141, 0.1, _characterFile.scale, 0.05, 10, 2));
		tabMenu.add(new FlxText(scaleStepper.x, scaleStepper.y - 14, 100, 'Scale:'));

		// Health Colour
		tabMenu.add(healthColourInputText = new PsychUIInputText(15, 180, 75, _characterFile.healthColor.toHexString(), 8));
		healthColourInputText.maxLength = 10;
		tabMenu.add(new FlxText(healthColourInputText.x, healthColourInputText.y - 14, 100, 'Health Colour:'));

		// Flip X
		tabMenu.add(flipXCheckBox = new PsychUICheckBox(95, 104, 'Flip X', 50));
		flipXCheckBox.checked = _characterFile.flipX;
		flipXCheckBox.onClick = function() {
			_characterFile.flipX = flipXCheckBox.checked;
			character.flipX = flipXCheckBox.checked;
		}

		// Antialiasing
		tabMenu.add(antialiasingCheckBox = new PsychUICheckBox(95, 144, 'Antialiasing', 80));
		antialiasingCheckBox.checked = _characterFile.antialiasing;
		antialiasingCheckBox.onClick = function() {
			_characterFile.antialiasing = antialiasingCheckBox.checked;
			character.antialiasing = antialiasingCheckBox.checked;
		}

		// Save Character
		tabMenu.add(new PsychUIButton(225, 184, 'Save', save));
	}

	var animationListDropDown:PsychUIDropDownMenu;
	var animationNameInputText:PsychUIInputText;
	var animationIDInputText:PsychUIInputText;
	var animationFramerateStepper:PsychUINumericStepper;
	var animationIndicesInputText:PsychUIInputText;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationTab():Void {
		var tabMenu:FlxSpriteGroup = characterUIBox.getTab('Animations').menu;

		// Animation Name
		tabMenu.add(animationNameInputText = new PsychUIInputText(15, 85, 80, '', 8));
		tabMenu.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 14, 100, 'Name:'));

		// Animation ID
		tabMenu.add(animationIDInputText = new PsychUIInputText(15, 123, 150, '', 8));
		tabMenu.add(new FlxText(animationIDInputText.x, animationIDInputText.y - 14, 150, 'ID:'));

		// Animation Framerate
		tabMenu.add(animationFramerateStepper = new PsychUINumericStepper(185, 85, 1, 24, 0, 240, 0));
		tabMenu.add(new FlxText(animationFramerateStepper.x, animationFramerateStepper.y - 14, 100, 'Framerate:'));

		// Animation Indices
		tabMenu.add(animationIndicesInputText = new PsychUIInputText(15, 165, 250, '', 8));
		tabMenu.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 14, 170, 'Indices (optional):'));

		// Animation Loop
		tabMenu.add(animationLoopCheckBox = new PsychUICheckBox(185, 119, 'Looped', 100));

		// Add/Update Animation
		tabMenu.add(new PsychUIButton(70, 210, 'Add/Update', function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if (indicesText.length > 0) {
				// assume that they have something like `min-max`
				if (indicesText.contains('-')) {
					var fuck:Array<String> = indicesText.split('-');
					var min:Int = Std.parseInt(fuck[0]);
					var max:Int = Std.parseInt(fuck[1]) + 1;
					if (Math.isNaN(min)) min = 0; // in case the user didn't put it as a number

					// if the max number wasn't a number then don't do anything
					// because we don't know how long to run the loop for
					if (!Math.isNaN(max)) for (i in min...max) indices.push(i);
				} else {
					// use normal indices instead
					for (i in animationIndicesInputText.text.split(',')) indices.push(Std.parseInt(i));
				}
			}

			var lastOffsets:Array<Float> = [0, 0];
			for (anim in anims) {
				if (animationNameInputText.text != anim.name) continue;

				lastOffsets = anim.offsets;
				if (character.animation.exists(animationNameInputText.text)) {
					character.animation.remove(animationNameInputText.text);
				}
				anims.remove(anim);
			}

			var addedAnim:CharacterAnim = {
				offsets: lastOffsets,
				looped: animationLoopCheckBox.checked,
				framerate: Math.round(animationFramerateStepper.value),
				name: animationNameInputText.text,
				indices: indices,
				id: animationIDInputText.text
			};
			addAnimation(addedAnim.name, addedAnim.id, addedAnim.framerate, addedAnim.looped, addedAnim.indices);
			anims.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, anims.indexOf(addedAnim)));
			updateText();
			character.playAnim(addedAnim.name, true);
			trace('Added/Updated animation: ' + animationNameInputText.text);
		}));

		// Remove Animation
		tabMenu.add(new PsychUIButton(180, 210, 'Remove', function() {
			for (anim in anims) {
				if (animationNameInputText.text != anim.name) continue;

				var resetAnim:Bool = false;
				if (character.animation.curAnim != null && anim.name == character.animation.curAnim.name) resetAnim = true;
				if (character.offsetMap.exists(anim.name)) {
					character.animation.remove(anim.name);
					character.offsetMap.remove(anim.name);
					anims.remove(anim);
				}

				if (resetAnim && anims.length > 0) {
					curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
					character.playAnim(anims[curAnim].name, true);
					updateText();
				}
				reloadAnimList();
				trace('Removed animation: ' + animationNameInputText.text);
				break;
			}
		}));

		// Animation List
		tabMenu.add(animationListDropDown = new PsychUIDropDownMenu(15, 30, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:CharacterAnim = anims[selectedAnimation];
			animationNameInputText.text = anim.name;
			animationIDInputText.text = anim.id;
			animationLoopCheckBox.checked = anim.looped;
			animationFramerateStepper.value = anim.framerate;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		}));
		tabMenu.add(new FlxText(animationListDropDown.x, animationListDropDown.y - 14, 100, 'Animations:'));
		reloadAnimList();
	}

	// extra utility stuff
	function reloadCharacterImage() {
		var lastAnim:String = character.animation.curAnim != null ? character.animation.curAnim.name : '';
		var oldAnims:Array<CharacterAnim> = _characterFile.animations.copy();
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		var sheets:Array<String> = _characterFile.sheets.split(',');
		if (Paths.exists('images/${sheets[0]}/Animation.json')) character.frames = Paths.animateAtlas(sheets[0]);
		else character.frames = Paths.multiAtlas(sheets);

		for (anim in oldAnims) {
			var animName:String = anim.name;
			var animID:String = anim.id;
			var animFps:Int = anim.framerate;
			var animLoop:Bool = anim.looped;
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animName, animID, animFps, animLoop, animIndices);
		}

		if (oldAnims.length > 0) {
			if (lastAnim.length != 0) character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function addAnimation(name:String, id:String, fps:Float, loop:Bool, ?indices:Array<Int>) {
		indices ??= [];

		if (character.isAnimate) {
			if (indices.length > 0) character.anim.addBySymbolIndices(name, id, indices, fps, loop);
			else character.anim.addBySymbol(name, id, fps, loop);
		} else {
			if (indices.length > 0) character.animation.addByIndices(name, id, indices, "", fps, loop);
			else character.animation.addByPrefix(name, id, fps, loop);
		}

		if (!character.animation.exists(name)) character.setOffset(name, [0.0, 0.0]);
	}

	function reloadCharacterOptions() {
		imageInputText.text = _characterFile.sheets;
		iconInputText.text = _characterFile.icon;
		healthColourInputText.text = _characterFile.healthColor.toHexString();
		singDurationStepper.value = _characterFile.singDuration;
		scaleStepper.value = _characterFile.scale;
		flipXCheckBox.checked = _characterFile.flipX;
		antialiasingCheckBox.checked = _characterFile.antialiasing;
		positionOffsetXStepper.value = _characterFile.offset[0];
		positionOffsetYStepper.value = _characterFile.offset[1];
		cameraOffsetXStepper.value = _characterFile.cameraOffset[0];
		cameraOffsetYStepper.value = _characterFile.cameraOffset[1];
		danceIntervalStepper.value = _characterFile.danceInterval;

		// because sometimes some stuff won't update properly
		icon.change(iconInputText.text);
		character.scale.set(scaleStepper.value, scaleStepper.value);
		character.updateHitbox();
		character.flipX = flipXCheckBox.checked;
		character.antialiasing = antialiasingCheckBox.checked;
		character.offset.set(positionOffsetXStepper.value * scaleStepper.value, positionOffsetYStepper.value * scaleStepper.value);
		healthBar.rightBar.color = _characterFile.healthColor;

		updateCameraPointer();
	}

	function updateCameraPointer(?snap:Bool = false) {
		var xPos:Float = character.getMidpoint().x + _characterFile.cameraOffset[0];
		var yPos:Float = character.getMidpoint().y + _characterFile.cameraOffset[1];
		cameraFollowPointer.setPosition(xPos, yPos);

		if (snap) {
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width / 2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height / 2;
		}
	}

	function updateText() {
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (num => anim in _characterFile.animations) {
			if (num > 0) intendText += '\n';

			if (num != curAnim) {
				intendText += '${anim.name}: [${anim.offsets[0]}, ${anim.offsets[1]}]';
				continue;
			}

			var n:Int = intendText.length;
			intendText += '${anim.name}: [${anim.offsets[0]}, ${anim.offsets[1]}]';
			animsTxt.addFormat(selectedFormat, n, intendText.length);
		}
		animsTxt.text = intendText;
	}

	function reloadAnimList() {
		if (_characterFile.animations.length == 0) {
		} else character.playAnim(_characterFile.animations[0].name, true);

		curAnim = 0;

		updateText();
		reloadAnimationDropDown();
	}

	function reloadAnimationDropDown() {
		if (animationListDropDown == null) return;

		var animList:Array<String> = [for (anim in _characterFile.animations) anim.name];
		if (animList.length == 0) animList.push('NO ANIMATIONS'); //Prevents crash

		animationListDropDown.list = animList;
	}

	function reloadCharacterDropDown() {
		var characterList:Array<String> = [];
		final directories:Array<String> = ['assets'];
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (i => path in directories) {
			if (!FileSystem.exists(path) || !FileSystem.exists('$path/characters')) continue;
			for (file in FileSystem.readDirectory('$path/characters')) {
				if (FileSystem.isDirectory(file)) continue;
				characterList.push(file.replace('.json', ''));
			}
		}

		if (characterList.length < 1) characterList.push('');
		charListDropDown.list = characterList;
		charListDropDown.selectedLabel = name;
	}

	// saving
	var _fileToSave:FileReference;
	function save() {
		if (_fileToSave != null) return;

		var data:String = Json5.stringify(_characterFile, null, '\t');
		if (data.length == 0) return;

		_fileToSave = new FileReference();
		_fileToSave.addEventListener(Event.SELECT, onSaveComplete);
		_fileToSave.addEventListener(Event.CANCEL, onSaveCancel);
		_fileToSave.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_fileToSave.save(data, '$name.json');
	}

	function onSaveComplete(_):Void {
		if (_fileToSave == null) return;
		
		_fileToSave.removeEventListener(Event.COMPLETE, onSaveComplete);
		_fileToSave.removeEventListener(Event.CANCEL, onSaveCancel);
		_fileToSave.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_fileToSave = null;
	}

	function onSaveCancel(_):Void {
		if (_fileToSave == null) return;
		_fileToSave.removeEventListener(Event.COMPLETE, onSaveComplete);
		_fileToSave.removeEventListener(Event.CANCEL, onSaveCancel);
		_fileToSave.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_fileToSave = null;
	}

	function onSaveError(_):Void {
		if (_fileToSave == null) return;

		_fileToSave.removeEventListener(Event.COMPLETE, onSaveComplete);
		_fileToSave.removeEventListener(Event.CANCEL, onSaveCancel);
		_fileToSave.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_fileToSave = null;
	}
}