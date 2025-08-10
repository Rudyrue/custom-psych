package funkin.objects;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame;

class FunkinSprite extends animate.FlxAnimate {
	public var offsetMap:Map<String, Array<Float>> = [];
	public var frameOffset:FlxPoint = FlxPoint.get();

	public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset) {
		super(x, y, graphic);
		moves = false;
		active = false;
	}

	// knew this was gonna get to me eventually lol
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):FunkinSprite {
		super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
		return this;
	}

	override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):FunkinSprite	{
		super.makeGraphic(width, height, color, unique, key);
		return this;
	}

	override function set_antialiasing(v:Bool):Bool {
		if (!Settings.data.antialiasing) return antialiasing = false;
		return antialiasing = v;
	}

	public function setOffset(name:String, offsets:Array<Float>) offsetMap.set(name, offsets);

	public function playAnim(name:String, ?forced:Bool = true) {
		if (!animation.exists(name)) return;

		final offsetsForAnim:Array<Float> = offsetMap[name] ?? [0, 0];

		animation.play(name, forced);
		active = animation.curAnim != null ? animation.curAnim.frames.length > 1 : false;
		frameOffset.set(offsetsForAnim[0], offsetsForAnim[1]);
	}

	override function drawComplex(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.translate(-frameOffset.x, -frameOffset.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}
}