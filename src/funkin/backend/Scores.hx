package funkin.backend;

import flixel.util.FlxSave;

@:structInit
class PlayData {
	// song data
	public var songID:String;
	public var difficulty:String;

	// play data
	public var score:Int;
	public var accuracy:Float;

	// modifiers
	public var modifiers:Map<String, Dynamic>;
}

@:structInit
class WeekPlayData {
	public var weekID:String;
	public var difficulty:String;
	public var score:Int;
	public var modifiers:Map<String, Dynamic>;
}

class Scores {
	public static var list:Array<PlayData> = [];
	public static var weekList:Array<WeekPlayData> = [];

	public static final changeableModifiers:Array<String> = ['playbackRate', 'noFail', 'randomizedNotes', 'mirroredNotes', 'sustains', 'opponentMode', 'blind', 'mines'];

	static var _save:FlxSave;

	public static function load():Void {
		_save = new FlxSave();
		_save.bind('scores', Util.getSavePath());

		if (_save.data.list != null) list = _save.data.list.copy();
		if (_save.data.weekList != null) weekList = _save.data.weekList.copy();
	}

	public static function save():Void {
		_save.data.list = list.copy();
		_save.data.weekList = weekList.copy();
		_save.flush();
	}

	public static function getWeekPlay(weekID:String, ?difficulty:String):WeekPlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<WeekPlayData> = filterWeekPlays(weekList, weekID, difficulty);
		if (plays.length == 0) {
			return {
				weekID: weekID,
				difficulty: difficulty,
				score: 0,

				modifiers: Settings.default_data.gameplayModifiers.copy()
			}
		}

		return plays[0];
	}

	public static function setWeekPlay(data:WeekPlayData):Void {
		var filteredList:Array<WeekPlayData> = filterWeekPlays(weekList, data.weekID, data.difficulty);

		info('current modifiers for "${data.weekID} - ${data.difficulty}":');
		for (key => value in data.modifiers) Sys.println('$key: $value');
		Sys.println('');

		if (filteredList.length == 0) {
			weekList.push(data);
			return;
		}

		var oldPlay:WeekPlayData = weekList[weekList.indexOf(filteredList[0])];
		if (oldPlay.score < data.score) oldPlay.score = data.score;
	}

	public static function filterWeekPlays(plays:Array<WeekPlayData>, weekID:String, difficulty:String):Array<WeekPlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers;

		return plays.filter(function(play:WeekPlayData) {
			for (m in changeableModifiers) {
				if (!modifiers.exists(m)) return false;
				if (play.modifiers[m] != modifiers[m]) return false;
			}

			return play.weekID == weekID && play.difficulty == difficulty;
		});
	}

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public static function getPlay(songID:String, ?difficulty:String):PlayData {
		difficulty ??= Difficulty.current;

		var plays:Array<PlayData> = filterPlays(list, songID, difficulty);
		if (plays.length == 0) {
			return {
				songID: songID,
				difficulty: difficulty,
				score: 0,
				accuracy: 0.0,

				modifiers: Settings.default_data.gameplayModifiers.copy()
			}
		}

		return plays[0];
	}

	public static function setPlay(data:PlayData):Void {
		var filteredList:Array<PlayData> = filterPlays(list, data.songID, data.difficulty);

		info('current modifiers for "${data.songID} - ${data.difficulty}":');
		for (key => value in data.modifiers) Sys.println('$key: $value');
		Sys.println('');

		if (filteredList.length == 0) {
			list.push(data);
			return;
		}

		var oldPlay:PlayData = list[list.indexOf(filteredList[0])];

		if (oldPlay.accuracy < data.accuracy) {
			oldPlay.accuracy = data.accuracy;
		}

		if (oldPlay.score < data.score) {
			oldPlay.score = data.score;
		}
	}

	public static function filterPlays(plays:Array<PlayData>, songID:String, difficulty:String):Array<PlayData> {
		var modifiers:Map<String, Dynamic> = Settings.data.gameplayModifiers;

		return plays.filter(function(play:PlayData) {
			for (m in changeableModifiers) {
				if (!modifiers.exists(m)) return false;
				if (play.modifiers[m] != modifiers[m]) return false;
			}

			return play.songID == songID && play.difficulty == difficulty;
		});
	}
}