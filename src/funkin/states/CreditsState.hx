package funkin.states;

import funkin.objects.AttachedSprite;

class CreditsState extends FunkinState {
	var list:Array<CreditGroup> = [ // MODIFY THIS IF YOU WANT TO ADD CREDIT
		new CreditGroup('group 1', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help'),
			new Person('person 4', 'they maybe did things', 'moral help'),
			new Person('person 5', 'they maybe did things', 'moral help'),
			new Person('person 6', 'they maybe did things', 'moral help'),
			new Person('person 7', 'they maybe did things', 'moral help'),
			new Person('person 8', 'they maybe did things', 'moral help'),
			new Person('person 9', 'they maybe did things', 'moral help'),
			new Person('person 10', 'they maybe did things', 'moral help')
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
		
		new CreditGroup('group 4', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help')
		]),
		
		new CreditGroup('group 5', [
			new Person('person 1', 'they did things', 'programmer'),
			new Person('person 2', 'they also did things', 'artist'),
			new Person('person 3', 'they maybe did things', 'moral help')
		])
	];
	
	// used for curSelected
	// DO NOT MODIFY
	var people:Array<Person> = [];
	
	var categories:FlxTypedSpriteGroup<CreditGroup>;

	var curSelected:Int = 0;
	var curCategoryNum:Int = 0;
	var curPerson(get, never):Person;
	function get_curPerson():Person return people[curSelected];

	override function create():Void {
		super.create();
		
		categories = new FlxTypedSpriteGroup<CreditGroup>();
		add(categories);
		
		var yPos:Float = 0.;
		for (i => credit in list) {
			categories.add(credit);
			
			credit.y = credit.child.spawnPos.y = yPos;
			credit.child.targetY = i;
			yPos += credit.height + 25;
			
			for (person in credit.people.members) people.push(person);
		}

		changeSelection();
	}

	var lerpCategory:Float = 0.;
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
		
		var curCategory = curPerson.parent;
		var prevCat = curCategoryNum - 1;
		var yOff:Float = -25.;
		if (prevCat >= 0) {
			var cat = categories.members[prevCat];
			yOff = cat.child.spawnPos.y + cat.height + 25;
		}
		
		var yDesired:Float = (200. - yOff) - curPerson.child.spawnPos.y;
		categories.y = FlxMath.lerp(yDesired, categories.y, Math.exp(-delta * 9.6));
	}

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, people.length - 1);
		curCategoryNum = categories.members.indexOf(curPerson.parent);

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
			person.y = person.child.spawnPos.y = yPos;
			yPos += person.height;

			person.parent = this;
		}
	}
}

class Person extends FlxSpriteGroup {
	public var child:Alphabet;
	public var icon:AttachedSprite;
	public var parent:CreditGroup;

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