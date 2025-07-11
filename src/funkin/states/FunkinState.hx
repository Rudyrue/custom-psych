package funkin.states;

import flixel.FlxState;

class FunkinState extends FlxState {
	var curStep:Int = 0;
	var curBeat:Int = 0;
	var curMeasure:Int = 0;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	override function create() {
		Conductor.reset();
		Paths.clearUnusedMemory();

		if (!skipNextTransOut && Settings.data.transitions) openSubState(new Transition(0.5, true));
		skipNextTransOut = false;

		Conductor.onStep = stepHit;
		Conductor.onBeat = beatHit;
		Conductor.onMeasure = measureHit;
	}

	public static function switchState(nextState:FlxState = null) {
		nextState ??= FlxG.state;
		if (nextState == FlxG.state) {
			resetState();
			return;
		}

		if (!Settings.data.transitions || skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		skipNextTransIn = false;
	}

	public static function resetState() {
		if (!Settings.data.transitions || skipNextTransIn) FlxG.resetState();
		else startTransition();
		skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(?nextState:FlxState) {
		if (nextState == null) nextState = FlxG.state;

		FlxG.state.openSubState(new Transition(0.5, false));
		Transition.finishCallback = function() {
			if (nextState == FlxG.state) FlxG.resetState();
			else FlxG.switchState(nextState);
		}
	}

	public static function getState():FunkinState {
		return cast(FlxG.state, FunkinState);
	}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}
}
