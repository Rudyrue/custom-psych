package funkin.backend;

@:structInit
class MetaFile {
	public var songName:String = 'Unknown';
	public var composer:String = 'Unknown';
	public var charter:Map<String, String> = [];
	public var timingPoints:Array<Conductor.TimingPoint> = [];
	public var offset:Float = 0.0;
	public var hasVocals:Bool = true;

	public var player:String = 'bf';
	public var spectator:String = 'gf';
	public var enemy:String = 'bf-opponent';
	public var stage:String = 'stage';
}

typedef MetaTimingPoint = {
	var time:Float;
	var ?bpm:Float;
	var ?beatsPerMeasure:Int;
}

class Meta {
	static var _cache:Map<String, MetaFile> = [];
	public static function cacheFiles(?force:Bool = false):Void {
		if (force) _cache.clear();

		final directories:Array<String> = ['assets'];
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (path in directories) {
			if (!FileSystem.exists('$path/songs')) continue;

			for (songFolder in FileSystem.readDirectory('$path/songs')) {
				final path = '$path/songs/$songFolder/meta.json';
				if (!FileSystem.exists(path)) continue;

				_cache.set(songFolder, load(songFolder, path));
			}
		}
	}

	public static function load(song:String, ?fullPath:String):MetaFile {
		if (_cache.exists(song)) return _cache[song];
		
		var path:String = fullPath != null ? fullPath : Paths.get('songs/$song/meta.json');
		var file:MetaFile = {};

		// still keeping this check here
		// in case the file isn't in the cache
		// but the user wants to parse it anyways
		if (!FileSystem.exists(path)) return file;
		var data:Dynamic = Json5.parse(File.getContent(path));

		for (property in Reflect.fields(data)) {
			// ??????? ok i guess no `Reflect.hasField()` for you
			if (!Reflect.fields(file).contains(property)) continue;
			if (property == 'charter' || property == 'timingPoints') continue;
			
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		for (diff in Reflect.fields(data.charter)) file.charter.set(diff, Reflect.field(data.charter, diff));

		// have to do it this way
		// otherwise haxe shits itself and starts printing insane numbers
		// and that's no good /ref
		var timingPoints:Array<MetaTimingPoint> = data.timingPoints;
		if (timingPoints == null) file.timingPoints.push({});
		else {
			for (point in timingPoints) {
				file.timingPoints.push({
					time: point.time,
					bpm: point.bpm,
					beatsPerMeasure: point.beatsPerMeasure
				});
			}
		}

		// in case this file wasn't cached
		// we cache it so that it doesn't have to keep re-parsing over and over
		_cache.set(song, file);
		return file;
	}
}