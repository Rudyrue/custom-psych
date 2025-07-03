package funkin.objects;

import flixel.math.FlxPoint;

class AttachedText extends Alphabet {
	public var sprTracker:FlxSprite;
	public var trackerOffset:FlxPoint = FlxPoint.get();
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;

	public function new(text:String = "", ?type:AlphabetGlyphType = NORMAL, ?scale:Float = 1) {
		super(0, 0, text, type);

		this.updateScale(scale, scale);
		this.isMenuItem = false;
	}

	override function update(elapsed:Float) {
		if (sprTracker == null) {
			super.update(elapsed);
			return;
		}

		setPosition(sprTracker.x + trackerOffset.x, sprTracker.y + trackerOffset.y);
		if (copyVisible) visible = sprTracker.visible;
		if (copyAlpha) alpha = sprTracker.alpha;

		super.update(elapsed);
	}
}