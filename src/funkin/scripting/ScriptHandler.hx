package funkin.scripting;

interface IScript {
	public var active:Bool;
	public var disposed:Bool;
	
	public function call(name:String, ?args:Array<Dynamic>):Dynamic;
	public function set(name:String, value:Dynamic, ?overrideSet:Bool):Dynamic;
	public function get(name:String):Dynamic;
	public function close():Void;
}

class ScriptHandler {
	public static var list:Array<IScript> = [];

	public static function loadFromDir(dir:String, ?subFolders:Bool = false):Void {
		if (!Paths.exists(dir)) return;
		
		for (file in FileSystem.readDirectory(Paths.get(dir))) {
			final absPath:String = '$dir/$file';
			if (FileSystem.isDirectory(absPath) && subFolders) {
				loadFromDir(absPath, subFolders);
				continue;
			}

			loadFile(absPath);
		}
	}

	public static function loadFile(dir:String):IScript {
		dir = Paths.get(dir);
		if (!FileSystem.exists(dir)) return null;

		switch haxe.io.Path.extension(dir) {
/*			case "lua":
				var script:LuaScript = new LuaScript(dir);

				list.push(script);
				script.execute();

				return script;*/

			case "hx": 
				final script:HScript = new HScript(dir);
				list.push(script);
				script.execute();
				return script;

			case _: return null;
		}
	}

	public static function call(func:String, ?args:Array<Dynamic>):Void {
		args ??= [];
		for (i in 0...list.length) {
			final script:IScript = list[i];
			if (script.disposed) {
				if (list.contains(script)) list.remove(script);
				continue;
			}
			script.call(func, args);
		}
	}

	public static function set(variable:String, value:Dynamic):Void {
		for (i in 0...list.length) {
			final script:IScript = list[i];
			if (script.disposed) {
				if (list.contains(script)) list.remove(script);
				continue;
			}
			script.set(variable, value);
		}
	}

	public static function clear()
		while (list.length > 0) list.pop().close();
}