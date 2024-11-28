package objects;

import flixel.graphics.FlxGraphic;


class CharIcon extends FunkinSprite {
	public var name:String;
	public var player(default, set):Bool;

	var iconOffsets:Array<Float> = [0, 0];

	public function new(name:String, ?player:Bool = false, ?allowGPU:Bool = true) {
		super(x, y);
		change(name);
		this.player = player;
	}

	function change(value:String, ?allowGPU:Bool = true):String {
		if (!Paths.exists('images/icons/$value.png')) value = 'face';
		var graphic = Paths.image('icons/$value', allowGPU);
		var size:Float = Math.round(graphic.width / graphic.height);

		loadGraphic(Paths.image('icons/$value'), true, 150, 150);
		animation.add(value, [for (i in 0...frames.frames.length) i], 0, false);
		animation.play(value);

		iconOffsets = [(width - 150) / size, (height - 150) / size];
		updateHitbox();

		return this.name = value;
	}

	function set_player(value:Bool):Bool {
		flipX = value;
		return player = value;
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox():Void {
		super.updateHitbox();
		if (!autoAdjustOffset) return;
		offset.set(iconOffsets[0], iconOffsets[1]);
	}
}