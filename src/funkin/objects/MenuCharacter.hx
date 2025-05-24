package funkin.objects;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var offset:Array<Float>;
	var idle:String;
	var confirm:String;
	var ?flipX:Bool;
	var ?antialiasing:Bool;
}

class MenuCharacter extends FlxSprite {
	public var name(default, set):String;
	var _file:MenuCharacterFile;
	public var hasConfirmAnimation:Bool = false;
	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(?x:Float, ?y:Float, ?name:String = 'bf') {
		super(x, y);
		this.name = name;
	}

	function set_name(?value:String = 'bf'):String {
		if (name == value) return value;

		if (value.length == 0) {
			visible = false;
			return name = value;
		}

		visible = true;

		scale.set(1, 1);
		updateHitbox();
		
		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		var filePath:String = '$value.json';
		var path:String = 'images/story/characters';
		if (!FileSystem.exists(Paths.get('$path/$filePath'))) {
			filePath = '$DEFAULT_CHARACTER.json'; // If a character couldn't be found, change him to BF just to prevent a crash
			color = FlxColor.BLACK;
			alpha = 0.6;
		}

		try {
			_file = Json5.parse(Paths.getFileContent('$path/$filePath'));
		} catch(e:Dynamic) {
			trace('Error loading menu character file of "$value": $e');
		}

		frames = Paths.sparrowAtlas('story/characters/${_file.image}');
		animation.addByPrefix('idle', _file.idle, 24);

		var confirmAnim:String = _file.confirm;
		if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != _file.idle) {
			animation.addByPrefix('confirm', confirmAnim, 24, false);
			if (animation.getByName('confirm') != null) // check for invalid animation
				hasConfirmAnimation = true;
		}
		flipX = _file.flipX;

		if (_file.scale != 1) {
			scale.set(_file.scale, _file.scale);
			updateHitbox();
		}
		offset.set(_file.offset[0], _file.offset[1]);
		animation.play('idle');

		antialiasing = _file.antialiasing != false && Settings.data.antialiasing;

		return name = value;
	}
}
