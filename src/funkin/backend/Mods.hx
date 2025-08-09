package funkin.backend;

@:structInit
class ModData {
	public var name:String = '';
	public var id:String = '';
	public var description:String = '';
	public var global:Bool = false;
	public var enabled:Bool = false;
}

typedef PackFile = {
	var name:String;
	var description:String;
	var restart:Bool;
	var global:Bool;
	var color:FlxColor;
}

class Mods {
	public static var list:Array<ModData> = [];
	public static var current:String = '';

	public static function getActive(?type:String):Array<ModData> {
		return [for (mod in list) {
			if (!mod.enabled) continue;

			switch (type.toLowerCase()) {
				case 'global': if (!mod.global) continue;
				case 'local': if (mod.global) continue;
				case _: 
			}
			mod;
		}];
	}

	public static function loadTop() {
		current = '';
		
		var list:Array<ModData> = getActive();
		if (list == null || list.length == 0) return;

		current = list[0].id;
	}

	public static function add(modID:String):ModData {
		#if MODS_ALLOWED
		var file:PackFile = getFile('mods/$modID/pack.json');
		var mod:ModData = {
			name: file.name,
			id: modID,
			description: file.description,
			global: file.global,
			enabled: false
		};

		list.push(mod);
		return mod;
		#else
		return {};
		#end
	}

	public static function reload():Void {
		#if MODS_ALLOWED
		list.resize(0);

		if (!FileSystem.exists('modsList.txt')) {
			var lines:Array<String> = FileSystem.readDirectory('mods');
			for (i in 0...lines.length) {
				if (!FileSystem.isDirectory('mods/${lines[i]}')) continue;
				lines[i] = '${lines[i]}|0';
			}

			File.saveContent('modsList.txt', lines.join('\n'));
		}

		for (i in [for (line in File.getContent('modsList.txt').split('\n')) line.split('|')]) {
			var mod:ModData = add(i[0]);
			mod.enabled = i[1].trim() == '1';
		}

		loadTop();
		#end
	}

	public static function createDummyFile():PackFile {
		return {
			name: '',
			description: '',
			restart: false,
			global: false,
			color: 0xFF000000
		}
	}

	public static function getFile(path:String):PackFile {
		var file:PackFile = createDummyFile();
		if (!FileSystem.exists(path)) return file;
		
		var data = Json5.parse(File.getContent(path));
		for (property in Reflect.fields(data)) {
			if (!Reflect.hasField(file, property)) continue;
			Reflect.setField(file, property, Reflect.field(data, property));
		}

		return file;
	}
}