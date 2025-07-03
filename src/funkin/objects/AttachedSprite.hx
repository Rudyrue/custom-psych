package funkin.objects;

import flixel.math.FlxPoint;

class AttachedSprite extends FlxSprite {
	public var sprTracker:FlxSprite;
	public var trackerOffset:FlxPoint = FlxPoint.get();
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null, ?anim:String = null, ?parentFolder:String = null, ?loop:Bool = false) {
		super();
		if(anim != null) {
			frames = Paths.sparrowAtlas(file, parentFolder);
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		} else if(file != null) {
			loadGraphic(Paths.image(file, parentFolder));
		}
		antialiasing = Settings.data.antialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + trackerOffset.x, sprTracker.y + trackerOffset.y);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;

			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if (copyVisible) 
				visible = sprTracker.visible;
		}
	}
}
