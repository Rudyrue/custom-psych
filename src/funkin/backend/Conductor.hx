package funkin.backend;

import flixel.sound.FlxSoundGroup;
import haxe.Timer;

@:structInit
class TimingPoint {
	public var time:Float = 0;
	public var offsettedTime(get, never):Float;
	function get_offsettedTime():Float return time + Conductor.offset;

	public var bpm:Float = 120;
	public var beatsPerMeasure:Int = 4;

	public function toString():String {
		return 'Time: $time | Tempo: $bpm | Beats per measure: $beatsPerMeasure';
	}
}

class Conductor extends flixel.FlxBasic {
    public static var playing:Bool = false;
    public static var length:Float = 0.0;

    public static var bpm(default, set):Float = 120.0;
    public static var crotchet:Float = (60 / bpm) * 1000;
    public static var stepCrotchet:Float = crotchet * 0.25;

	public static var beatsPerMeasure(default, set):Int = 4;
    
    public static var offset:Float = 0.0;

    public static var rate(default, set):Float = 1.0;
    public static var volume(default, set):Float = 1.0;

    public static var visualTime:Float = 0.0;
    public static var rawTime:Float = 0.0;
    public static var timingPoints(default, set):Array<TimingPoint> = [];
    static function set_timingPoints(value:Array<TimingPoint>):Array<TimingPoint> {
		if (value == null || value.length == 0) {
			timingPoints.resize(1);
			timingPoints[0] = {};
			return timingPoints;
		}

        var lastPoint:TimingPoint = {
			bpm: 0,
			beatsPerMeasure: 0
		};

        // so that the end-user doesn't have to specify a bpm/numerator every time they add a new point for smth else
        for (point in value) {
            if (point.bpm <= 0) point.bpm = lastPoint.bpm;
            if (point.beatsPerMeasure <= 0) point.beatsPerMeasure = lastPoint.beatsPerMeasure;
            lastPoint = point;
        }
        timingPoints.resize(0);
        timingPoints = value.copy();

        timingPoints.sort((a, b) -> return Std.int(a.time - b.time));

        return value;
    }

    public static var inst(default, set):FlxSound;
    
    @:isVar public static var mainVocals(get, set):FlxSound;
    @:isVar public static var opponentVocals(get, set):FlxSound;
    public static var vocals:FlxSoundGroup;

	static var _metronomeSound:FlxSound;
	public static var metronome:Bool = false;

    public static final vocalResyncDiff:Float = 5;

    public static var step:Int = 0;
    public static var beat:Int = 0;
    public static var measure:Int = 0;
    static var _fStep:Float;
    static var _fBeat:Float;
    static var _fMeasure:Float;

    static var _prevStep:Int = -1;
    static var _prevBeat:Int = -1;
    static var _prevMeasure:Int = -1;

    public static dynamic function onStep(value:Int):Void {}
    public static dynamic function onBeat(value:Int):Void {}
    public static dynamic function onMeasure(value:Int):Void {}

    public function new() {
        super();
        vocals = new FlxSoundGroup(2);
        visible = false;
        reset();
    }

    public static function reset() {
        playing = false;
		@:bypassAccessor
		rawTime = 0.0;
		visualTime = 0.0;
        _time = 0.0;
        _fStep = step = 0;
        _fBeat = beat = 0;
        _fMeasure = measure = 0;

		timingPoints = null;
		beatsPerMeasure = 4;
		bpm = 120;

        offset = 0.0;
    }

    override function update(elapsed:Float) {
        if (!playing) return;

        _prevStep = step;
        _prevBeat = beat;
        _prevMeasure = measure;

        syncTime(elapsed);
        syncVocals();
        syncBeats();
    }

	/* for the people that can't read comments (me)
		if (!playing) return;
		
		deltaTime *= 1000;
		if (inst == null || !inst.playing) {
			_time += deltaTime * rate;
			@:bypassAccessor
			rawTime = _time + offset;
			visualTime = rawTime;
			return;
		}
		
		@:privateAccess
		deltaTime = FlxG.game._elapsedMS;

		if (inst.time == _lastTime) _resyncTimer += deltaTime;
		else _resyncTimer = 0;

		_lastTime = inst.time;
		
		_time = inst.time;
		@:bypassAccessor
		rawTime = _time + offset;

		visualTime = rawTime + _resyncTimer;
	*/

	// used for countdown
	public static var _time:Float = 0.0;
	
    static var _lastTime:Float = 0.0;
    static var _resyncTimer:Float = 0.0;
	static var _lastTimestamp:Float = 0.0;
	
    public static dynamic function syncTime(deltaTime:Float):Void {
		if (!playing) return;
		
		deltaTime *= 1000;
		if (inst == null || !inst.playing) {
			_time += deltaTime * rate;
			rawTime = _time + Math.max(0, offset);
			visualTime = rawTime;
			return;
		}

		// because fuck it :fire:
		@:privateAccess
		deltaTime = FlxG.game._elapsedMS;

		// if the sound time was unchanged from the last frame
		// increase by the delta time from the last frame
		// to prevent the notes looking jittery/unsmooth
		// see https://github.com/stepmania/stepmania/blob/5_1-new/src/GameState.cpp#L1253
		if (inst.time == _lastTime) _resyncTimer += deltaTime;

		// else just use the raw time
		else _resyncTimer = 0;

		_lastTime = inst.time;

		// we seperate time into 2 values because of modcharting capabilities
		// makes it easier to fuck with scroll velocities and such

		// USE THIS FOR JUDGEMENT MATH, **NOT FOR VISUAL POSITION**
		rawTime = inst.time + offset;

		// USE THIS FOR VISUAL POSITION, **NOT FOR JUDGEMENT MATH (ie note.rawHitTime)**
		visualTime = rawTime + _resyncTimer;
    }

    public static dynamic function syncVocals() {
        if (!playing || inst == null || !inst.playing) return;

        final instTime:Float = inst.time;

        for (vocal in vocals.members) {
            if (vocal == null || !vocal.playing || vocal.length < instTime) continue;

            final vocalDT:Float = Math.abs(vocal.time - instTime);
            if (vocalDT <= vocalResyncDiff) continue;
            vocal.time = instTime;
        }
    }

    public static dynamic function syncBeats() {
        var point:TimingPoint = getPointFromTime(rawTime);
        if (point.bpm != bpm) bpm = point.bpm;

		// beatsPerMeasure
		if (point.beatsPerMeasure != beatsPerMeasure) beatsPerMeasure = point.beatsPerMeasure;

        _fBeat = getBeatFromTime(rawTime) + ((rawTime - point.time) / crotchet);
        _fMeasure = _fBeat / beatsPerMeasure;
		_fStep = _fBeat * 4;

        var nextStep:Int = Math.floor(_fStep);
        var nextBeat:Int = Math.floor(_fBeat);
        var nextMeasure:Int = Math.floor(_fMeasure);

        if (step != nextStep) onStep(step = nextStep);
        if (beat != nextBeat) {
			if (metronome) FlxG.sound.play(Paths.sound('metronome'));
			onBeat(beat = nextBeat);
		}
        if (measure != nextMeasure) onMeasure(measure = nextMeasure);
    }

    public static function stop() {
        playing = false;
        inst.stop();
        vocals.stop();
    }

    public static function play() {
        playing = true;
        inst.play();
        vocals.play();
    }

    public static function pause() {
        playing = false;
        inst.pause();
        vocals.pause();
    }

    public static function resume() {
        playing = true;
        inst.resume();
        vocals.resume();
    }

    static function set_bpm(value:Float):Float {
        crotchet = calculateCrotchet(value);
        stepCrotchet = crotchet * 0.25;

		if (timingPoints.length == 1) {
			timingPoints[0].bpm = value;
		}

        return bpm = value;
    }

	static function set_beatsPerMeasure(value:Int):Int {
		if (timingPoints.length == 1) {
			timingPoints[0].beatsPerMeasure = value;
		}

		return beatsPerMeasure = value;
	}

    static function set_inst(value:FlxSound):FlxSound {
        if (inst != null) {
            inst.stop();
            inst.destroy();
            FlxG.sound.list.remove(inst);
            if (value == null) return inst = null;
        }

        value.persist = true;
        value.pitch = rate;
        length = value.length;
        return inst = value;
    }

    static function get_mainVocals():FlxSound {
        return vocals.members[1];
    }

    static function get_opponentVocals():FlxSound {
        return vocals.members[0];
    }

    static function set_mainVocals(value:FlxSound):FlxSound {
        value.pitch = rate;
        return vocals.members[1] = value;
    }

    static function set_opponentVocals(value:FlxSound):FlxSound {
        value.pitch = rate;
        return vocals.members[0] = value;
    }

    static function set_rate(value:Float):Float {
        #if FLX_PITCH
        return inst.pitch = vocals.pitch = rate = value;
        #else
        return 1.0;
        #end
    }

    static function set_volume(value:Float):Float {
        return inst.volume = value = vocals.volume = volume = value;
    }

    // helper functions that im just gonna
    // throw at the bottom of here lmao
    inline public static function calculateCrotchet(bpm:Float) {
        return (60 / bpm) * 1000;
    }

    public static function getBeatFromTime(timeAt:Float):Float {
		var beatFromTime:Float = 0;
		
		if (timingPoints.length <= 1) return beatFromTime;

        var curBPM:Float = timingPoints[0].bpm;
		var lastPointTime:Float = offset;

        for (point in timingPoints) {
			if (timeAt >= point.offsettedTime) {
				beatFromTime += (point.offsettedTime - lastPointTime) / calculateCrotchet(curBPM);
				lastPointTime = point.offsettedTime;

				curBPM = point.bpm;
			} else break;
        }

        return beatFromTime;
    }

	public static function getPointFromTime(timeAt:Float):TimingPoint {
		var lastPoint:TimingPoint = {};
		if (timingPoints.length == 0) return lastPoint;
		lastPoint = timingPoints[0];
		
		// to prevent running a for loop just for one object
		if (timingPoints.length == 1) return lastPoint;
		
		for (i => point in timingPoints) {
			if (timeAt >= point.offsettedTime) lastPoint = point;
			else break;
		}
		
		return lastPoint;
	}
}