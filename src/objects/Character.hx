package objects;

typedef CharacterFile = {
	var antialiasing:Bool;
	var flipX:Bool;
	var icon:String;
	var scale:Float;
	var singDuration:Float;
	var healthColor:FlxColor;
	var sheets:String;
	var cameraOffset:Array<Float>;
	var danceInterval:Int;

	var animations:Array<CharacterAnim>;
}

typedef CharacterAnim = {
	var name:String;
	var id:String;
	var indices:Array<Int>;
	var framerate:Int;
	var looped:Bool;
	var offsets:Array<Float>;
}

class Character extends FunkinSprite {
	public static inline var default_name:String = 'bf';
	public var name:String = default_name;
	public var singDuration:Float = 4;
	public var danceInterval:Int = 2;
	public var healthColor:FlxColor = 0xFFA1A1A1;
	public var sheets:Array<String> = [];
	public var icon:String = '';
	public var cameraOffset:FlxPoint = FlxPoint.get(0, 0);
	public var dancer:Bool = false;
	public var autoIdle:Bool = true;

	public var file:CharacterFile;

	public function new(?x:Float, ?y:Float, ?name:String, ?player:Bool = true) {
		name ??= default_name;
		super(x, y);

		var path:String = Paths.get('characters/$name.json');
		if (!FileSystem.exists(path)) {
			trace('character path "$path" doesn\'t exist');
			name = default_name;
		}
		path = Paths.get('characters/$name.json');

		file = getFile(path);

		this.name = name;
		this.singDuration = file.singDuration;
		this.healthColor = file.healthColor;
		this.sheets = file.sheets.split(',');
		this.icon = file.icon;
		this.danceInterval = file.danceInterval;
		this.cameraOffset.set(file.cameraOffset[0], file.cameraOffset[1]);
		flipX = file.flipX;
		antialiasing = Settings.data.antialiasing && file.antialiasing;

		frames = Paths.multiAtlas(this.sheets);

		for (anim in file.animations) {
			if (anim.indices.length == 0) {
				animation.addByPrefix(anim.name, anim.id, anim.framerate, anim.looped);
			} else {
				animation.addByIndices(anim.name, anim.id, anim.indices, '', anim.framerate, anim.looped);
			}

			offsetMap.set(anim.name, anim.offsets);
		}

		scale.set(file.scale, file.scale);
		updateHitbox();

		if (animation.exists('danceLeft') || animation.exists('danceRight')) {
			danceList = ['danceLeft', 'danceRight'];
			dancer = true;
		}

		dance(true);
	}

	public var dancing(get, never):Bool;
	function get_dancing():Bool {
		return animation.curAnim != null && danceList.contains(animation.curAnim.name);
	}

	var _singTimer:Float = 0.0;
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!autoIdle || dancing) return;

		_singTimer -= elapsed * (singDuration * (Conductor.stepCrotchet * 0.25));
		if (_singTimer <= 0.0) dance(true);
	}

	var animIndex:Int = 0;
	var danceList:Array<String> = ['idle'];
	public function dance(?forced:Bool = false) {
		// support for gf/spooky kids characters
		if (dancer && !forced) forced = dancing;

		if (!forced && (animation.curAnim == null || !animation.curAnim.finished)) return;

		playAnim(danceList[animIndex]);
		animIndex = FlxMath.wrap(animIndex + 1, 0, danceList.length - 1);
	}

	override function playAnim(name:String, ?forced:Bool = true) {
		super.playAnim(name, forced);
		if (name.startsWith('sing') || name.startsWith('miss')) {
			_singTimer = singDuration * (Conductor.stepCrotchet * 0.15);
		}
	}

	public static function createDummyFile():CharacterFile {
		return {
			antialiasing: true,
			flipX: false,
			icon: 'face',
			scale: 1,
			singDuration: 4,
			healthColor: 0xFFA1A1A1,
			danceInterval: 2,
			sheets: 'characters/bf',
			cameraOffset: [0, 0],

			animations: [
				{
					name: 'name',
					id: 'id',
					indices: [],
					framerate: 24,
					looped: false,
					offsets: [0, 0]
				}
			],
		}
	}

	static function getFile(path:String):CharacterFile {
		var file:CharacterFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}
}