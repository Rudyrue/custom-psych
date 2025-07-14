package funkin.states;

import funkin.objects.AttachedSprite;

class CreditsState extends FunkinState {
	// used for curSelected
	// DO NOT MODIFY
	var people:Array<Person> = [];

	// MODIFY THIS INSTEAD
	// IF YOU WANT TO ADD CREDIT
	var categories:Array<CreditGroup> = [
		new CreditGroup('group 1', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help')
		]),

		new CreditGroup('group 2', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help')
		]),

		new CreditGroup('group 3', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help')
		]),
	];

	var curSelected:Int = 0;

	override function create():Void {
		super.create();

		var yPos:Float = 100;
		for (i => category in categories) {
			add(category);
			category.y = category.child.spawnPos.y = yPos;
			category.child.targetY = i;
			yPos += category.height + 25;

			for (person in category.people.members) people.push(person);
		}

		changeSelection();
	}

	var lerpSelected:Float = 0.0;
	override function update(delta:Float):Void {
		super.update(delta);

		if (Controls.justPressed('back')) {
			FunkinState.switchState(new MainMenuState());
		}

		var downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? 1 : -1);
		}

		var lerpVal:Float = Math.exp(-delta * 9.6);

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-delta * 9.6));
		for (i => category in categories) {
			category.y = ((i * lerpSelected) + category.height) / category.length;
		}
	}

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, people.length - 1);

		for (i => person in people) {
			person.alpha = curSelected == i ? 1 : 0.5;
		}
	}
}

class CreditGroup extends FlxSpriteGroup {
	public var child:Alphabet;
	var name:String;
	public var people:FlxTypedSpriteGroup<Person>;
	public function new(name:String, list:Array<Person>) {
		super();

		this.name = name;
		add(child = new Alphabet(0, 0, name));
		child.fieldWidth = FlxG.width;
		child.alignment = 'center';

		add(people = new FlxTypedSpriteGroup<Person>());

		var yPos:Float = child.height + 25;
		for (person in list) {
			people.add(person);
			person.screenCenter(X);
			person.y = yPos;
			yPos += person.height;
		}
	}
}

class Person extends FlxSpriteGroup {
	public var child:Alphabet;
	public var icon:AttachedSprite;

	var name:String;
	var description:String;
	var role:String;
	
	public function new(name:String, description:String, role:String) {
		super();

		this.name = name;
		this.description = description;
		this.role = role;

		add(child = new Alphabet(0, 0, name));

		//add(icon = new AttachedSprite('credits/${Util.format(name)}'));
		add(icon = new AttachedSprite('icons/face'));
		icon.sprTracker = child;
		icon.trackerOffset.set(child.width + 25, -25);
	}
}