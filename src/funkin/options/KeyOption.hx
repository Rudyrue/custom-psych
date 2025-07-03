package funkin.options;

import flixel.input.keyboard.FlxKey;
import funkin.backend.InputFormatter;
import funkin.options.BaseOption;

class KeyOption extends BaseOption<Array<FlxKey>, Int> {
    public var curKey:Int = 0;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	**/
	public function new(name:String, ?description:String, ?preference:String)
    {
        super(name, description, preference);
        this.hasMovement = true;
        this.hasEnter = true;
        this.enter = _enter;
        this.change = _change;
        this.getText = _getText;
    }

    override function getValues() {
		defaultValue = Controls.default_binds[attachedPref];
		value = Controls.binds[attachedPref];
    }

    private function _getText():String {
        return (curKey == value.length) ? "New Key" : InputFormatter.getKeyName(value[curKey]);
    }

    private function _change(next:Int):Void
    {
        curKey = (curKey + next + (value.length + 1)) % (value.length + 1);
    }

    private function _enter():Void
    {
        FlxG.state.persistentUpdate = false;
        FlxG.state.openSubState(new RebindSubState(this));
    }
}

class RebindSubState extends FlxSubState {
    var bg:FlxSprite;
    var key:KeyOption;

    public function new(key:KeyOption) {
        super();
        this.key = key;
    }
    
    override function create() {
        super.create();

        final newKey = key.curKey == key.value.length;

        add(bg = new FlxSprite().makeGraphic(1, 1, 0x80000000));
        bg.scale.set(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0;

        var title = new Alphabet(0, 220, 'Rebinding ${key.name} (${newKey ? "NEW" : "#" + (key.curKey + 1)})');
        title.screenCenter(X);
        add(title);

        var infoTxt = "Press Any Key\nESCAPE to cancel";
        if (!newKey)
            infoTxt += "\nDELETE to remove";
        var info = new Alphabet(0, 360, infoTxt, NORMAL, CENTER);
        info.screenCenter(X);
        for (line in info.members) {
            for (char in line.members)
                char.setColorTransform(1, 1, 1, char.alpha, 255, 255, 255, 0);
        }
        add(info);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        bg.alpha = FlxMath.lerp(bg.alpha, 1, elapsed * 10);

        final pressed = FlxG.keys.firstJustPressed();
        switch (pressed) {
            case FlxKey.ESCAPE:
                close();
            case FlxKey.DELETE:
                if (key.curKey == key.value.length) return;
                key.value.splice(key.curKey, 1);
                close();
            default:
                if (pressed == FlxKey.NONE) return;

                if (key.curKey == key.value.length)
                    key.value.push(pressed);
                else
                    key.value[key.curKey] = pressed;
                FlxG.sound.play(Paths.sound('confirm'));

                close();
        }
    }
}