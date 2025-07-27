package funkin.backend;

@:structInit
class Judgement {
	public static var list:Array<Judgement> = [
		{name: 'sick', timing: Settings.data.sickHitWindow, accuracy: 100, health: 2.5, splashes: true},
		{name: 'good', timing: Settings.data.goodHitWindow, accuracy: 85, health: 1},
		{name: 'bad', timing: Settings.data.badHitWindow, accuracy: 60, health: -2.5},
		{name: 'shit', timing: Settings.data.shitHitWindow, accuracy: 40, health: -4}
	];

	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];

	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];

	public var name:String;
	public var timing:Float;
	public var accuracy:Float = 0.0;
	public var health:Float = 0.0;
	public var breakCombo:Bool = false;
	public var splashes:Bool = false;

	public var hits:Int = 0;

	public static function getIDFromTiming(noteDev:Float):Int {
		var value:Int = list.length - 1;

		for (i in 0...list.length) {
			if (Math.abs(noteDev) > list[i].timing) continue;
			value = i;
			break;
		}

		return value;
	}

	public static function getFromTiming(noteDev:Float):Judgement {
		var judge:Judgement = max;

		for (possibleJudge in list) {
			if (Math.abs(noteDev) > possibleJudge.timing) continue;
			judge = possibleJudge;
			break;
		}

		return judge;
	}
	
	inline public static function resetHits():Void {
		for (judge in list) judge.hits = 0;
	}

	public function toString():String {
		return 'Judgement | Name: "$name" | Timing: $timing';
	}
}