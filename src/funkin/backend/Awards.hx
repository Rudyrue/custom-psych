package funkin.backend;

import flixel.util.FlxSave;
import funkin.objects.AwardPopup;

class Awards {
	public static var list:Array<Award> = [
		{
			name: 'Freaky on a Friday Night', id: 'friday_play', hidden: true,
			description: 'Play on a Friday... Night.'
		},
		{
			name: 'She Calls Me Daddy Too', id: 'week1_fc',
			description: 'Beat Week 1 on Hard with no misses.'
		},
		{
			name: 'No More Tricks', id: 'week2_fc',
			description: 'Beat Week 2 on Hard with no misses.'
		},
		{
			name: 'Call me The Hitman', id: 'week3_fc',
			description: 'Beat Week 3 on Hard with no misses.'
		},
		{
			name: 'Lady Killer', id: 'week4_fc',
			description: 'Beat Week 4 on Hard with no misses.'
		},
		{
			name: 'Missless Christmas', id: 'week5_fc',
			description: 'Beat Week 5 on Hard with no misses.'
		},
		{
			name: 'Highscore!!', id: 'week6_fc',
			description: 'Beat Week 6 on Hard with no misses.'
		},
		{
			name: 'God Effing Damn It!', id: 'week7_fc',
			description: 'Beat Week 7 on Hard with no misses.'
		},
		{
			name: 'Just a Friendly Sparring', id: 'weekend1_fc',
			description: 'Beat Weekend 1 on Hard with no misses.'
		},
		{
			name: 'What a Funkin\' Disaster!', id: 'ur_bad',
			description: 'Finish a song with an accuracy lower than 20%.'
		},
		{
			name: 'Perfectionist', id: 'ur_good',
			description: 'Finish a song with 100% accuracy.'
		},
		{
			name: 'Roadkill Enthusiast', id: 'roadkill_enthusiast',
			description: 'Watch the Henchmen die 50 times.',
			maxScore: 50
		},
		{
			name: 'Oversinging Much...?', id: 'oversinging',
			description: 'Sing for 10 seconds without returning back to idle.'
		},
		{
			name: 'Hyperactive', id: 'hype',
			description: 'Finish a song without going back to idle.'
		},
		{
			name: 'Just the Two of Us', id: 'two_keys',
			description: 'Finish a song pressing only two keys.'
		},
		{
			name: 'Toaster Gamer', id: 'toastie',
			description: 'Have you tried to run the game on a toaster?'
		},
		/*{
			name: 'Debugger', id: 'debugger', hidden: true,
			description: 'Beat the song "Test" from the chart editor.'
		},*/
	];

	@:unreflective
	static var _unlocked:Array<String> = [];
	static var _scores:Map<String, Float> = [];

	static var _save:FlxSave;

	public static function load() {
		if (_save == null) {
			_save = new FlxSave();
			_save.bind('awards', Util.getSavePath());
		}

		if (_save.data.list != null) {
			_unlocked.resize(0);
			_unlocked = _save.data.list.copy();
		}

		if (_save.data.scores != null) {
			_scores = _save.data.scores.copy();
		}
	}

	public static function save() {
		_save.data.list = _unlocked;
		_save.data.scores = _scores;
		_save.flush();
	}

	public static function reset(?saveToDisk:Bool = false) {
		_unlocked.resize(0);
		_scores = [];
		if (saveToDisk) save();
	}

	public static function isUnlocked(id:String):Bool {
		if (!exists(id)) return false;
		return _unlocked.contains(id);
	}

	public static function unlock(id:String, ?autoPopup:Bool = true) {
		if (isUnlocked(id)) return;

		_unlocked.push(id);
		FlxG.sound.play(Paths.sound('confirm'), 0.5);
		if (autoPopup) startPopup(id);

		save();
	}

	public static function getScore(id:String):Float {
		if (!_scores.exists(id)) return 0;
		return _scores[id];
	}

	public static function addScore(id:String, value:Float) {
		var award:Award = get(id);
		if (award == null || award.maxScore <= 0) return;

		setScore(id, _scores[id] + value);
	}

	public static function setScore(id:String, value:Float) {
		var award:Award = get(id);
		if (award == null || award.maxScore <= 0 || value > award.maxScore) return;

		_scores.set(id, value);
		if (value >= award.maxScore) unlock(id);
	}

	@:allow(funkin.objects.AwardPopup)
	static var _popups:Array<AwardPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups():Bool return _popups.length > 0;
	public static function startPopup(id:String) {
		for (popup in _popups) {
			if (popup == null) continue;
			popup.intendedY += 150;
		}

		_popups.push(new AwardPopup(id));
	}

	public static function exists(id:String):Bool {
		for (award in list) {
			if (award.id == id) return true;
		}

		return false;
	}

	public static function get(id:String):Award {
		for (award in list) {
			if (award.id != id) continue;
			return award;
		}

		return null;
	}
}

@:structInit
class Award {
	public var name:String = 'Unknown';
	public var description:String = 'No description given.';
	public var id:String = '';
	public var icon:String = 'default';
	public var hidden:Bool = false;

	public var maxScore:Float = 0;
	public var decimals:Int = 0;
}