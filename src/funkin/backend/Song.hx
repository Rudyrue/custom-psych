package funkin.backend;

import funkin.objects.Note;
import funkin.backend.Meta;
import funkin.objects.Strumline;

import moonchart.formats.OsuMania;
import moonchart.formats.StepMania;
import moonchart.formats.StepManiaShark;
import moonchart.formats.BasicFormat.BasicNoteType;

// just to make sure chart parsing doesn't kill itself
typedef JsonChart = {
	var notes:Array<Section>;
	var ?events:Array<Dynamic>;
	var speed:Float;
}

typedef Chart = {
	var notes:Array<Section>;
	var events:Array<Dynamic>;
	var speed:Float;
	var ?meta:MetaFile;
}

typedef Section = {
	var sectionNotes:Array<Dynamic>;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var altAnim:Bool;
}

class FNFChart extends moonchart.formats.fnf.legacy.FNFLegacy {
 	public function new() {
    	super();

    	this.indexedTypes = false;
    	this.bakedOffset = false;
    	this.offsetHolds = false;

    	noteTypeResolver.register("Hurt Note", BasicNoteType.MINE);
  	}
}

class Song {
	public static function createDummyFile():Chart {
		return {
			notes: [{
				sectionNotes: [],
				mustHitSection: false,
				gfSection: false,
				altAnim: false
			}],
			events: [],
			speed: 1.0,
		}
	}

	public static function loadFromPath(path:String):Chart {
		var file:Chart = createDummyFile();

		path = Paths.get(path);
		if (!FileSystem.exists(path)) return file;

		var rawChart:JsonChart = switch haxe.io.Path.extension(path) {
			case 'json':
				cast Json.parse(File.getContent(path)).song;

			case 'sm':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new StepMania().fromFile(path)).data.song;

			case 'ssc':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new StepManiaShark().fromFile(path)).data.song;

			case 'osu':
				var fnf:FNFChart = new FNFChart();
				cast fnf.fromFormat(new OsuMania().fromFile(path)).data.song;

			default: null;
		}

		for (property in Reflect.fields(rawChart)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(rawChart, property));
		}

		return file;
	}

	public static function load(song:String, diff:String):Chart {
		var file:Chart = loadFromPath('songs/$song/${getFile(song, diff)}');
		file.meta = Meta.load(song);

		return file;
	}

	public static function parse(chart:Chart):Array<NoteData> {
		final notes:Array<NoteData> = [];
		if (chart == null) return notes;

		for (section in chart.notes) {
			for (note in section.sectionNotes) {
				notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % Strumline.keyCount),
					length: note[2],
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
					altAnim: section.altAnim,
					player: note[1] > (Strumline.keyCount - 1) != section.mustHitSection ? 1 : 0,
				});
			}
		}

		notes.sort((a, b) -> Std.int(a.time - b.time));
		return notes;
	}

	static var formats:Array<String> = ['json', 'sm', 'osu'];
	public static function getFile(song:String, diff:String) {
		diff = Difficulty.format(diff);
		var file:String = '$diff.${formats[0]}';
		var path:String = Paths.get('songs/$song');

		if (!FileSystem.exists(path)) return file;

		var files:Array<String> = FileSystem.readDirectory(path);
		for (format in formats) {
			if (files.contains('$diff.$format')) { // shouldnt this be endsWith? or use haxe.io.Path.withoutDirectory
				file = '$diff.$format';
				break;
			}
		}

		return file;
	}
}