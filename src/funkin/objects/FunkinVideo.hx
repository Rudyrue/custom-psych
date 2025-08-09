package funkin.objects;

import flixel.addons.display.FlxPieDial;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;

class FunkinVideo extends FlxSpriteGroup {
	public dynamic function onFinish():Void {}
	public dynamic function onSkip():Void {}

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var video:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	private var name:String;

	public var waiting:Bool = false;

	public function new(name:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Bool = false) {
		super();

		this.name = name;
		scrollFactor.set();

		waiting = isWaiting;
		if (!waiting) {
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		video = new FlxVideoSprite();
		video.antialiasing = Settings.data.antialiasing;
		add(video);
		if (canSkip) this.canSkip = true;

		// callbacks
		if (!shouldLoop) video.bitmap.onEndReached.add(finishVideo);

		video.bitmap.onFormatSetup.add(function() {
			video.setGraphicSize(FlxG.width);
			video.updateHitbox();
			video.screenCenter();
		});

		video.load(name, shouldLoop ? ['input-repeat=65545'] : null);
	}

	override function destroy() {
		if (!exists)
			return;

		trace('Video destroyed');
		if (cover != null) {
			remove(cover);
			cover.destroy();
		}
		
		onFinish = function() {};
		onSkip = function() {};

		if (FlxG.state != null) {
			if (FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if (FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}
		super.destroy();
	}

	function finishVideo() {
		if (!exists) return;
		onFinish();
		destroy();
	}

	override function update(elapsed:Float) {
		if (!canSkip) super.update(elapsed); return;

		var holdingMath:Float = 0;
		if (Controls.pressed('accept')) {
			holdingMath = Math.min(_timeToSkip, holdingTime + elapsed);
		} else if (holdingTime > 0) {
			holdingMath = FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1));
		}
		holdingTime = Math.max(0, holdingMath);

		updateSkipAlpha();

		if (holdingTime >= _timeToSkip) {
			onSkip();
			onFinish = function() {}
			video.bitmap.onEndReached.dispatch();
			trace('Skipped video');
			return;
		}

		super.update(elapsed);
	}

	function set_canSkip(value:Bool):Bool {
		if (value) {
			if (skipSprite == null) {
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
				skipSprite.x = FlxG.width - (skipSprite.width + 80);
				skipSprite.y = FlxG.height - (skipSprite.height + 72);
				skipSprite.amount = 0;
				add(skipSprite);
			}
		} else if (skipSprite != null) {
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}

		return canSkip = value;
	}

	function updateSkipAlpha() {
		if (skipSprite == null) return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}

	public function play() video?.play();
	public function resume() video?.resume();
	public function pause() video?.pause();
}
#else 
class FunkinVideo extends FlxSpriteGroup {
	public dynamic function onFinish():Void {}
	public dynamic function onSkip():Void {}

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var video:Dynamic;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip:Bool = false;

	private var name:String;

	public var waiting:Bool = false;

	public function new(name:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Bool = false) {
		super();

		this.name = name;
		scrollFactor.set();
	}
	
	public function play() {}
	public function resume() {}
	public function pause() {}
}
#end