package funkin.objects;

class Strumline extends FlxTypedSpriteGroup<Receptor> {
	public static final keyCount:Int = 4;
	public static var size:Float = Settings.data.strumlineSize;
	public var healthMult:Float = 1;
	public var skin(default, set):String;
	public dynamic function character():Character return null;
	
	public static inline var default_skin:String = 'noteSkins/funkin';
	function set_skin(value:String):String {
		skin = value;
		regenerate();
		return value;
	}
	public var ai:Bool;

	public function new(?x:Float, ?y:Float, ?player:Bool = false, ?skin:String) {
		this.moves = false;
		this.ai = !player;
		super(x, y);
		this.skin = skin ?? Settings.data.noteSkin;

		// center the strumline on the x position we gave it
		// instead of basing the x position on the left side of the x axis
		this.x = x - (width * 0.5);
	}

	public function regenerate() {
		// just in case there's anything stored
		while (members.length != 0) members.pop().destroy();

		var strum:Receptor = null;
		for (i in 0...keyCount) {
			add(strum = new Receptor(this, i));
			strum.scale.set(size, size);
			strum.updateHitbox();
			strum.x += strum.width * i;
		}
	}
}

class Receptor extends FunkinSprite {
	public var queueStatic:Bool = false;
	public var parent:Strumline;
	public var holdTime:Float = 0.0;
	public function new(parent:Strumline, lane:Int) {
		super();

		this.parent = parent;

		animation.finishCallback = _ -> {
			if (holdTime > 0) return;
			
			active = false;

			if (!(parent.ai || queueStatic) || animation.curAnim.name != 'notePressed') return;
			playAnim('default');
		}

		// modding by length will cause different behaviour here
		// purple, blue, green, red, if it goes beyond that, it loops back, purple blue green red, and so on.
		final anim:String = Note.directions[lane % Note.directions.length];
		final formattedSkin:String = parent.skin.trim().toLowerCase().replace(' ', '-');
		frames = Paths.sparrowAtlas('noteSkins/$formattedSkin');
		animation.addByPrefix('default', 'arrow${anim.toUpperCase()}', 24);
		animation.addByPrefix('pressed', '$anim press', 48, false);
		animation.addByPrefix('notePressed', '$anim confirm', 48, false);

		playAnim('default');
	}
	
	override function update(e:Float) {
		if (holdTime > 0) {
			holdTime -= e;
			
			if (holdTime <= 0) playAnim('default');
		}
		super.update(e);
	}

	override function playAnim(name:String, ?forced:Bool = true) {
		super.playAnim(name, forced);
		centerOffsets();
		centerOrigin();
	}
}