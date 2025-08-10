package funkin.objects;

import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.graphics.FlxGraphic;
import openfl.Lib;

class AwardPopup extends openfl.display.Sprite {
	public var intendedY:Float = 0;
	var lastScale:Float = 1;
	var nameTxt:TextField;
	var descTxt:TextField;
	public function new(id:String) {
		super();

		graphics.beginFill(FlxColor.BLACK);
		graphics.drawRoundRect(0, 0, 420, 130, 16, 16);

		var graphic:FlxGraphic = null;
		var path:String = 'awards/$id';
		var antialiasing:Bool = Settings.data.antialiasing;
		if (Paths.exists('images/$path-pixel.png')) {
			graphic = Paths.image('$path-pixel');
			antialiasing = false;
		} else graphic = Paths.image(path);

		if (graphic == null) graphic = Paths.image('unknownMod');

		var sizeX:Float = 100;
		var sizeY:Float = 100;

		var imgX:Float = 15;
		var imgY:Float = 15;
		var image = graphic.bitmap;
		graphics.beginBitmapFill(image, new Matrix(sizeX / image.width, 0, 0, sizeY / image.height, imgX, imgY), false, antialiasing);
		graphics.drawRect(imgX, imgY, sizeX + 10, sizeY + 10);

		var textX = sizeX + imgX + 15;
		var textY = imgY + 20;

        addChild(nameTxt = new TextField());
        nameTxt.autoSize = LEFT;
		nameTxt.x = textX;
		nameTxt.y = textY;
        nameTxt.wordWrap = nameTxt.mouseEnabled = nameTxt.selectable = false;
        nameTxt.defaultTextFormat = new TextFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFF, JUSTIFY);

	    addChild(descTxt = new TextField());
        descTxt.autoSize = LEFT;
		descTxt.x = textX;
		descTxt.y = textY + 30;
        descTxt.wordWrap = descTxt.mouseEnabled = descTxt.selectable = false;
        descTxt.defaultTextFormat = new TextFormat(Paths.font('vcr.ttf'), 16, 0xFFFFFFF, JUSTIFY);

		var award = Awards.get(id);
		nameTxt.text = award.name;
		descTxt.text = award.description;
		graphics.endFill();

		FlxG.game.addChild(this);

		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, update);

		lastScale = (FlxG.stage.stageHeight / FlxG.height);
		this.x = 20 * lastScale;
		this.y = -130 * lastScale;
		this.scaleX = lastScale;
		this.scaleY = lastScale;
		intendedY = 20;
	}

	public function destroy() {
		Awards._popups.remove(this);

		if (FlxG.game.contains(this)) {
			FlxG.game.removeChild(this);
		}
		FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		removeEventListener(Event.ENTER_FRAME, update);
	}

	var lerpTime:Float = 0;
	var countedTime:Float = 0;
	var timePassed:Float = -1;

	function update(e:Event) {
		if (timePassed < 0)  {
			timePassed = Lib.getTimer();
			return;
		}

		var time = Lib.getTimer();
		var elapsed:Float = (time - timePassed) * 0.001;
		timePassed = time;

		if (elapsed >= 0.5) return; //most likely passed through a loading

		countedTime += elapsed;
		if (countedTime < 3) {
			lerpTime = Math.min(1, lerpTime + elapsed);
			y = ((FlxEase.elasticOut(lerpTime) * (intendedY + 130)) - 130) * lastScale;
		} else {
			y -= FlxG.height * 2 * elapsed * lastScale;
			if (y <= -130 * lastScale) destroy();
		}
	}

	private function onResize(e:Event) {
		var mult = (FlxG.stage.stageHeight / FlxG.height);
		scaleX = mult;
		scaleY = mult;

		x = (mult / lastScale) * x;
		y = (mult / lastScale) * y;
		lastScale = mult;
	}
}