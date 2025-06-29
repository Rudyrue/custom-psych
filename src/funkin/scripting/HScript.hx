package funkin.scripting;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;

class HScript extends Iris implements IScript {
	public var active:Bool = true;
	public var disposed:Bool = false;

	public function new(dir:String) {
		super(File.getContent(dir), {name: dir, autoRun: false, autoPreset: true});

		set('closeFile', function() {
			close();
			if (ScriptHandler.list.contains(this)) ScriptHandler.list.remove(this);
		});


		set('Settings', Settings);
		set('FlxG', FlxG);
		set('Controls', Controls);
		set('Util', Util);
		set('Paths', Paths);
		set('ScriptHandler', ScriptHandler);
		set('PlayState', PlayState);
		set('FlxSprite', FlxSprite);
		set('game', PlayState.self);

		set('addBehindObject', function(obj:FlxBasic, target:FlxBasic):FlxBasic
			return PlayState.self.insert(PlayState.self.members.indexOf(target), obj));
	}
	
	override function call(func:String, ?args:Array<Dynamic>):IrisCall {
		if (disposed || !active || !interp.variables.exists(func))
			return {funName: func, signature: null, returnValue: null};
		return super.call(func, args ?? []);
	}

	public function close():Void {
		destroy();
		disposed = true;
		active = false;
	}
}
#else
class HScript {
	public var active:Bool = true;
	public var disposed:Bool = false;

	public function new(_) {}
	public function call(_, ?_):Dynamic return null;
	public function set(_, _):Dynamic return null;
	public function get(_):Dynamic return null;
	public function close():Void {}
}
#end