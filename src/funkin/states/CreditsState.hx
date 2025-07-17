package funkin.states;

import funkin.objects.AttachedSprite;

class CreditsState extends FunkinState {
	var list:Array<CreditGroup> = [ // MODIFY THIS IF YOU WANT TO ADD CREDIT
		new CreditGroup('Psych Engine', [
			{
				name: 'Shadow Mario',
				description: 'Lead Developer/Programmer',
				link: 'https://ko-fi.com/shadowmario',
				colour: 0xFF444444
			},
			{
				name: 'Riveren',
				description: 'Lead Artist',
				link: 'https://x.com/riverennn',
				colour: 0xFF14967B
			},
			{
				name: 'BBPanzu',
				description: 'Ex-Programmer',
				link: 'https://x.com/bbsub3',
				colour: 0xFF3E813A
			},
			{
				name: 'Discord',
				description: 'Join the Discord!',
				link: 'https://discord.gg/2ka77eMXDv',
				colour: 0xFF5165F6
			}
		]),
		new CreditGroup('Custom Psych', [
			{
				name: 'Rudyrue',
				description: 'Lead Developer/Programmer',
				link: 'https://bsky.app/profile/rudyrue.bsky.social',
				colour: 0xFF75471F
			},
			{
				name: 'SrtHero278',
				description: 'Code Help',
				link: 'https://bsky.app/profile/srtpro278.bsky.social'
			}
		]),
		new CreditGroup('Contributors', [
			{
				name: 'Kamizeta',
				description: 'Creator of Pessy, Psych Engine\'s mascot.',
				link: 'https://www.instagram.com/cewweey/',
				colour: 0xFFD21C11
			},
			{
				name: 'Keoiki',
				description: 'Note splash animations, Latin alphabet',
				link: 'https://x.com/Keoiki_',
				colour: 0xFFD2D2D2
			},
			{
				name: 'sqirradotdev',
				description: 'Crash Handler',
				link: 'https://sqirra.dev/',
				colour: 0xFFE1843A
			},
			{
				name: 'EliteMasterEric',
				description: 'Early Runtime Shader Support',
				link: 'https://x.com/EliteMasterEric',
				colour: 0xFFFFBD40
			},
			{
				name: 'MAJigsaw77',
				description: '.mp4 Video Library (hxvlc)',
				link: 'https://x.com/MAJigsaw77',
				colour: 0xFF5F5F5F
			},
			{
				name: 'iFlicky',
				description: 'Composer of "Tea Time" and "PSync"',
				link: 'https://x.com/flicky_i',
				colour: 0xFF9E29CF
			},
			{
				name: 'MaybeMaru',
				description: 'Adobe Texture Atlas Support (flixel-animate)',
				link: 'https://linktr.ee/maybemaru'
			}
		]),
		new CreditGroup('Friday Night Funkin\'', [
			{
				name: 'ninjamuffin99',
				description: 'Co-Director/Programmer',
				link: 'https://x.com/ninja_muffin99',
				colour: 0xFFCF2D2D
			},
			{
				name: 'PhantomArcade',
				description: 'Director/Artist',
				link: 'https://x.com/PhantomArcade3K',
				colour: 0xFFFADC45
			},
			{
				name: 'evilsk8r',
				description: 'Character Designer/Artist',
				link: 'https://x.com/PhantomArcade3K',
				colour: 0xFF5ABD4B
			},
			{
				name: 'KawaiSprite',
				description: 'Composer',
				link: 'https://x.com/kawaisprite',
				colour: 0xFF378FC7
			}
		])
	];
	
	// used for curSelected
	// DO NOT MODIFY
	var people:Array<Person> = [];
	
	var categories:FlxTypedSpriteGroup<CreditGroup>;

	static var curSelected:Int = 0;
	var curCategoryNum:Int = 0;
	var curPerson(get, never):Person;
	function get_curPerson():Person return people[curSelected];

	var bg:FunkinSprite;
	var descBG:FunkinSprite;
	var descText:FlxText;

	override function create():Void {
		super.create();

		add(bg = new FunkinSprite(0, 0, Paths.image('menus/desatBG')));
		bg.alpha = 0.7;

		add(categories = new FlxTypedSpriteGroup<CreditGroup>());

		add(descBG = new FunkinSprite(0, 550));
		descBG.makeGraphic(1050, 150, FlxColour.BLACK);
		descBG.alpha = 0.7;
		descBG.screenCenter(X);

		add(descText = new FlxText(descBG.x, 0, descBG.width, '', 32));
		descText.font = Paths.font("vcr.ttf");
		descText.borderStyle = FlxTextBorderStyle.OUTLINE;
		descText.borderColor = FlxColor.BLACK;
		descText.borderSize = 2.4;
		descText.scrollFactor.set();
		descText.alignment = 'center';
		
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

	override function update(delta:Float):Void {
		super.update(delta);

		if (Controls.justPressed('back')) {
			FunkinState.switchState(new MainMenuState());
		}

		var downJustPressed:Bool = Controls.justPressed('ui_down');
		if (downJustPressed || Controls.justPressed('ui_up')) {
			changeSelection(downJustPressed ? 1 : -1);
		}

		if (Controls.justPressed('accept')) Util.openURL(curPerson.link);

		if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);
		
		var prevCat = curCategoryNum - 1;
		var yOff:Float = -25.;
		if (prevCat >= 0) {
			var cat = categories.members[prevCat];
			yOff = cat.child.spawnPos.y + cat.height + 25;
		}
		
		var yDesired:Float = (200. - yOff) - curPerson.child.spawnPos.y;
		categories.y = FlxMath.lerp(yDesired, categories.y, Math.exp(-delta * 9.6));
	}

	var intendedColour:FlxColour;
	function changeSelection(?dir:Int = 0) {
		FlxG.sound.play(Paths.sound('scroll'));
		curSelected = FlxMath.wrap(curSelected + dir, 0, people.length - 1);
		curCategoryNum = categories.members.indexOf(curPerson.parent);

		for (i => person in people) {
			person.alpha = curSelected == i ? 1 : 0.5;
		}

		descText.text = curPerson.description;
		descText.y = descBG.y + (descBG.height - descText.height) * 0.5;
		descBG.setGraphicSize(Std.int(descText.width + 20), Std.int(Math.max(descBG.height, descText.height)));

		var newColour:Int = curPerson.colour;
		if (newColour != intendedColour) {
			intendedColour = newColour;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColour);
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

@:structInit
class Person extends FlxSpriteGroup {
	public var child:Alphabet;
	public var icon:AttachedSprite;
	public var parent:CreditGroup;

	public var name:String;
	public var description:String;
	public var link:String;
	public var colour:FlxColour;
	
	public function new(name:String, description:String, ?link:String, ?colour:FlxColour) {
		super();

		this.name = name;
		this.description = description;
		this.link = link ?? '';
		this.colour = colour ?? 0xFF999999;

		add(child = new Alphabet(0, 0, name));

		var path:String = 'credits/${Util.format(name)}';
		if (!Paths.exists('images/$path.png')) path = 'credits/default';
		add(icon = new AttachedSprite(path));
		icon.sprTracker = child;
		icon.trackerOffset.set(child.width + 25, -35);
	}
}