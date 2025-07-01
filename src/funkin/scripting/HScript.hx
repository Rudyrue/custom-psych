package funkin.scripting;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import haxe.ValueException;

class HScript extends Iris {
	public var active:Bool = true;

	public function new(dir:String) {
		super(File.getContent(dir), {name: dir, autoRun: false, autoPreset: true});
		this.parser.resumeErrors = true;
		set('closeFile', close);


		set('Settings', Settings);
		set('FlxG', FlxG);
		set('Controls', Controls);
		set('Util', Util);
		set('Paths', Paths);
		set('ScriptHandler', ScriptHandler);
		set('PlayState', PlayState);
		set('FlxSprite', FlxSprite);
		set('game', PlayState.self);

		set('addBehindObject', function(obj:FlxBasic, target:FlxBasic):FlxBasic {
			return PlayState.self.insert(PlayState.self.members.indexOf(target), obj);
		});
	}
	
	override function call(func:String, ?args:Array<Dynamic>):IrisCall {
		var defaultCall:IrisCall = {funName: func, signature: null, returnValue: null};

		if (!active || !exists(func)) return defaultCall;

		try {
			var signature:Dynamic = interp.variables.get(func);
			var ret = Reflect.callMethod(null, signature, args ?? []);
			return {funName: func, signature: signature, returnValue: ret};
		} catch(e:IrisError) {
			Iris.error(Printer.errorToString(e, false), interp.posInfos());
			return defaultCall;
		} catch (e:ValueException) {
			Iris.error('$e', interp.posInfos());
			return defaultCall;
		}

		return defaultCall;
	}

	public function close():Void {
		destroy();
		active = false;
	}
}
#else
class HScript {
	public var active:Bool = true;

	public function new(_) {}
	public function call(_, ?_):Dynamic return null;
	public function set(_, _):Dynamic return null;
	public function get(_):Dynamic return null;
	public function close():Void {}
}
#end