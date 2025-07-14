package funkin.substates;

import funkin.objects.CheckboxThingie;

class GameplayModifiersMenu extends FlxSubState {
	var list:Array<GameplayModifier> = [
		{
			var mod = new NumberModifier('Playback Rate', 'How fast the game will go.', 'playbackRate');
			mod.changeBy = 0.05;
			mod.min = 0.5;
			mod.max = 3;
			mod.formatText = function() mod.child.text = '${mod.name}: ${mod.value}x';
			mod.formatText();
			mod;
		},
		new BoolModifier('Instakill on Miss', 'You die the moment you miss a note.', 'instakill'),
		new BoolModifier('Perfect', 'Can only hit "Sick!!"\'s or higher.', 'onlySicks'),
		new BoolModifier('No Fail', 'Prevents you from dying.', 'noFail'),
		new BoolModifier('Botplay', 'The game will play for you.\n(press F8 to enable mid-song)', 'botplay'),
		new BoolModifier('Sustains', 'Holds will appear in the song.', 'sustains'),
		new BoolModifier('Mines', 'Mines will appear in the song that you have to prevent hitting.', 'mines'),
		new BoolModifier('Blind', 'How much of the song do you remember?', 'blind'),
		new BoolModifier('Mirror', 'Swaps the note lanes around.', 'mirroredNotes'),
		new BoolModifier('Shuffle', 'Randomizes the lanes of the notes.', 'randomizedNotes'),
		new BoolModifier('Play As Opponent', 'Play the opponent side instead.', 'opponentMode')
	];

	var optionGrp:FlxTypedSpriteGroup<GameplayModifier>;
	var curSelected:Int = 0;
	var curModifier(get, never):GameplayModifier;
	function get_curModifier():GameplayModifier return list[curSelected];

	var descBG:FunkinSprite;
	var descText:FlxText;

	override function create():Void {
		super.create();

		var bg:FunkinSprite = new FunkinSprite();
		bg.makeGraphic(1, 1, FlxColour.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.5;
		add(bg);

		add(optionGrp = new FlxTypedSpriteGroup<GameplayModifier>());
		for (i => modifier in list) {
			optionGrp.add(modifier);
			modifier.child.targetY = i;
		}

		add(descBG = new FunkinSprite(0, 550));
		descBG.makeGraphic(1050, 150, FlxColour.GRAY);
		descBG.alpha = 0.7;
		descBG.screenCenter(X);

		add(descText = new FlxText(descBG.x, 0, descBG.width, '', 32));
		descText.font = Paths.font("vcr.ttf");
		descText.borderStyle = FlxTextBorderStyle.OUTLINE;
		descText.borderColor = FlxColor.BLACK;
		descText.borderSize = 2.4;
		descText.scrollFactor.set();
		descText.alignment = 'center';

		changeSelection();
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (Controls.justPressed('back')) close();


		final downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? 1 : -1);
		}

		if (Controls.justPressed('accept') && curModifier is BoolModifier) {
			curModifier.action(!curModifier.value);
		}

		var leftJustPressed:Bool = Controls.justPressed('ui_left');
		if (leftJustPressed || Controls.justPressed('ui_right')) {
			if (curModifier is NumberModifier) {
				var newValue:Float = curModifier.value;
				if (leftJustPressed) newValue -= cast(curModifier, NumberModifier).changeBy;
				else newValue += cast(curModifier, NumberModifier).changeBy;
				curModifier.action(newValue);
			}
		}
	}

	function changeSelection(?dir:Int = 0) {
		FlxG.sound.play(Paths.sound('scroll'));
		curSelected = FlxMath.wrap(curSelected + dir, 0, list.length - 1);

		for (i => modifier in list) {
			modifier.alpha = i == curSelected ? 1 : 0.5;
			modifier.child.targetY = i - curSelected;
		}

		descText.text = curModifier.description;
		descText.y = descBG.y + (descBG.height - descText.height) * 0.5;
		descBG.setGraphicSize(Std.int(descText.width + 20), Std.int(Math.max(descBG.height, descText.height)));
	}
}

class GameplayModifier extends FlxSpriteGroup {
	public var child:Alphabet;

	public var name:String;
	public var description:String;
	public var variable:String;
	public var value:Dynamic;

	public function new(name:String, description:String, variable:String) {
		super();

		this.name = name;
		this.description = description;
		this.variable = variable;
		value = Settings.data.gameplayModifiers[variable];

		add(child = new Alphabet(90, 320, name));
		child.isMenuItem = true;
	}

	public dynamic function action(changedValue:Dynamic) value = changedValue;
	public dynamic function formatText() child.text = '$name: $value';
}

class BoolModifier extends GameplayModifier {
	public var checkbox:CheckboxThingie;
	public function new(name:String, description:String, variable:String) {
		super(name, description, variable);

		add(checkbox = new CheckboxThingie());
		checkbox.sprTracker = child;
		checkbox.trackerOffset.x = child.width + 25;
		checkbox.trackerOffset.y = 15;

		this.action = function(changedValue:Bool) {
			value = checkbox.value = changedValue;
		}
	}
}

class NumberModifier extends GameplayModifier {
	public var min:Float = 0;
	public var max:Float = 1;
	public var changeBy:Float = 0.25;
	public var decimals:Int = 2;
	public function new(name:String, description:String, variable:String) {
		super(name, description, variable);

		this.action = function(changedValue:Float) {
			value = FlxMath.roundDecimal(FlxMath.bound(changedValue, min, max), decimals);
			formatText();
		}

		formatText();
	}
}