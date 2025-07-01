package funkin.scripting;

class ScriptHandler {
	public static var list:Array<HScript> = [];

	public static function loadFromDir(dir:String, ?subFolders:Bool = false):Void {
		if (!Paths.exists(dir)) return;

		final directories:Array<String> = ['assets'];
		final originalLength:Int = directories.length;
		for (mod in Mods.getActive()) directories.push('mods/${mod.id}');

		for (i => directory in directories) {
			if (!FileSystem.exists(directory) || !FileSystem.exists('$directory/$dir')) continue;
			
			for (file in FileSystem.readDirectory('$directory/$dir') ?? []) {
				final absPath:String = '$directory/$dir/$file';

				if (FileSystem.isDirectory(absPath) && subFolders) {
					loadFromDir(absPath, subFolders);
					continue;
				}

				loadFile(absPath);
			}
		}
	}

	public static function loadFile(dir:String):HScript {
		dir = Util.addFileExtension(dir, 'hx');

		if (!FileSystem.exists(dir) || !dir.endsWith('hx')) return null;
		var script:HScript = new HScript(dir);

		list.push(script);
		script.execute();

		return script;
	}

	public static function call(func:String, ?args:Array<Dynamic>):Void {
		for (script in list) {
			if (script == null || !script.active) continue;
			script.call(func, args);
		}
	}

	public static function set(variable:String, value:Dynamic):Void {
		for (script in list) {
			if (script == null || !script.active) continue;
			script.set(variable, value);
		}
	}

	public static function clear() {
		while (list.length > 0) list.pop().destroy();
	}
}