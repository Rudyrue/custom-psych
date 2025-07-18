package funkin.objects;

import flixel.graphics.FlxGraphic;

class Countdown extends FunkinSprite {
	public dynamic function onStart():Void {}
	public dynamic function onTick(tick:Int):Void {
		switch (tick) {
			case 4: 
				if (!silent) FlxG.sound.play(Paths.sound('intro3'));
				animation.frameIndex = 0;
			case 3: 
				if (!silent) FlxG.sound.play(Paths.sound('intro2'));
				animation.frameIndex = 1;
			case 2: 
				if (!silent) FlxG.sound.play(Paths.sound('intro1'));
				animation.frameIndex = 2;
			case 1: 
				if (!silent) FlxG.sound.play(Paths.sound('introGo'));
				animation.frameIndex = 3;
		}
	}
	public dynamic function onFinish():Void {}

	public var ticks:Int = 4;
	public var finished:Bool = true;
	public var silent:Bool = false;

	public function new(?x:Float, ?y:Float) {
		super(x, y);
		final graphic:FlxGraphic = Paths.image('countdown');
		loadGraphic(graphic, true, graphic.width, Std.int(graphic.height * (1 / ticks)));

		animation.frameIndex = -1; // ????

		alpha = 0;
		active = false;
		curTick = ticks;
		_lastBeat = ticks + 1;
	}

	public function start():Void {
		finished = false;
		active = true;
		_time = (Conductor.crotchet * -(ticks + 1));

/*		// give the game time to start it correctly on positive offsets
		var extraTime:Float = Math.floor((Conductor.offset * -1) / Conductor.crotchet);
		if (extraTime > 0) _time -= Conductor.crotchet * extraTime;
*/
		onStart();
	}

	var _lastBeat:Int = 0;
	var _time:Float;
	var curTick:Int;
	override function update(elapsed:Float):Void {
		alpha -= elapsed / (Conductor.crotchet * 0.001);
		if (finished) return;

		_time += (elapsed * 1000) * Conductor.rate;

		var possibleBeat:Int = Math.floor((_time + Conductor.offset) / Conductor.crotchet) * -1;
		if (possibleBeat != _lastBeat && curTick >= 1) {
			beat(curTick--);
			_lastBeat = possibleBeat;
		}

		if (_time >= 0) {
			finished = true;
			active = false;
			onFinish();
		}
	}

	public function beat(curTick:Int) {
		if (curTick > ticks) return;

		onTick(curTick);
		alpha = 1;
	}

	public function stop():Void {
		active = false;
	}
}