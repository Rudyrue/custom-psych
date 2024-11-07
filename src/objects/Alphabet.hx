package objects;

import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
import flixel.util.FlxAxes;
import flixel.FlxObject;

// swordcube's alphabet but heavily modified to work with psych
// since i had alignment issues getting it to work the other way around (psych alphabet working with swordcube's code
class Alphabet extends FlxTypedSpriteGroup<AlphabetLine> {
    public var type(default, set):AlphabetGlyphType;

    public var alignment(default, set):AlphabetAlignment;

    public var text(default, set):String;

	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var scaleX(default, set):Float = 1.0;
	public var scaleY(default, set):Float = 1.0;

	public var letters(get, never):Array<AlphabetGlyph>;
	function get_letters():Array<AlphabetGlyph> {
		return [for (line in members) {
			for (glyph in line) glyph;
		}];
	}

    public var targetY:Int = 0;

    public var isMenuItem:Bool = false;

    public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
	public var spawnPos:FlxPoint = FlxPoint.get();

	public static function loadData(?request:String) {
		var path:String = '$request.json';
		if (!FileSystem.exists(path)) path = Paths.get('data/alphabet.json');

		AlphabetGlyph.allGlyphs = new Map<String, Glyph>();
		try {
			var data:Dynamic = Json.parse(File.getContent(path));

			if (data.allowed != null && data.allowed.length > 0) {
				for (i in 0...data.allowed.length) {
					var glyph:String = data.allowed.charAt(i);
					if (glyph == ' ') continue;
					
					// default values for the letters that don't have offsets
					AlphabetGlyph.allGlyphs.set(glyph.toLowerCase(), {
						anim: glyph.toLowerCase(),
						offsets: [0.0, 0.0], 
						offsetsBold: [0.0, 0.0]
					});
				}
			}

			if (data.characters != null) {
				for (char in Reflect.fields(data.characters)) {
					var glyphData = Reflect.field(data.characters, char);
					var glyph:String = char.toLowerCase().substr(0, 1);

					if (AlphabetGlyph.allGlyphs.exists(glyph)) {
						AlphabetGlyph.allGlyphs.set(glyph, {
							anim: glyphData.animation ?? glyph, 
							offsets: glyphData.normal ?? [0.0, 0.0], 
							offsetsBold: glyphData.bold ?? [0.0, 0.0]
						});
					}
				}
			}
			
			trace('Reloaded members successfully ($path)!');
		} catch(e:Dynamic) trace('Error on loading alphabet data: $e');

		if (!AlphabetGlyph.allGlyphs.exists('?')) {
			AlphabetGlyph.allGlyphs.set('?', {
				anim: 'question',
				offsets: [0.0, 0.0], 
				offsetsBold: [0.0, 0.0]
			});
		}
	}

    public function new(x:Float = 0, y:Float = 0, text:String = "", ?type:AlphabetGlyphType = BOLD, ?alignment:AlphabetAlignment = LEFT, ?size:Float = 1.0) {
        super(x, y);
		this.spawnPos.set(x, y);

        @:bypassAccessor this.type = type;
        this.text = text;
		this.alignment = alignment;
    }

    override function update(elapsed:Float) {
        if (!isMenuItem) {
			super.update(elapsed);
			return;
		}

        if (changeX) x = Util.ilerp(x, (targetY * distancePerItem.x) + spawnPos.x, 0.16);
        if (changeY) y = Util.ilerp(y, (targetY * 1.3 * distancePerItem.y) + spawnPos.y, 0.16);
    }

	public function snapToPosition() {
		if (!isMenuItem) return;

		if (changeX) x = (targetY * distancePerItem.x) + spawnPos.x;
		if (changeY) y = (targetY * 1.3 * distancePerItem.y) + spawnPos.y;
	}

    // --------------- //
    // [ Private API ] //
    // --------------- //

	static final Y_PER_ROW:Float = 60;

    @:noCompletion
    function updateText(newText:String, ?force:Bool = false) {
        if (text == newText && !force) return; // what's the point of regenerating

        for (glyph in members) glyph.destroy();
        clear();

        final glyphPos:FlxPoint = FlxPoint.get();
        var rows:Int = 0;

        var line:AlphabetLine = new AlphabetLine();

        for (i in 0...newText.length) {
            final char:String = newText.charAt(i);
            if (char == "\n") {
                glyphPos.x = 0;
                glyphPos.y = ++rows * Y_PER_ROW;
                add(line);
                line = new AlphabetLine();
                continue;
            }

            final spaceChar:Bool = (char == " ");
            if (spaceChar) {
                glyphPos.x += 28;
                continue;
            }

            if (!AlphabetGlyph.allGlyphs.exists(char.toLowerCase())) continue;

            final glyph:AlphabetGlyph = new AlphabetGlyph(glyphPos.x, glyphPos.y, char, type);
            glyph.row = rows;
            glyph.color = color;
            glyph.spawnPos.copyFrom(glyphPos);
            line.add(glyph);

            glyphPos.x += glyph.width;
        }

        if (members.indexOf(line) == -1) add(line);
        
        glyphPos.put();
    }

    public function updateAlignment(align:AlphabetAlignment) {
        final totalWidth:Float = width;
        for (line in members) {
            line.x = switch (align) {
                case LEFT: x;
                case CENTER: x + ((x - totalWidth) * 0.5);
                case RIGHT: x + (x - totalWidth);
            }
        }
    }

	@:noCompletion
	function set_scaleX(value:Float):Float {
		updateScale(value, scaleY);
		return value;
	}

	@:noCompletion
	function set_scaleY(value:Float):Float {
		updateScale(scaleX, value);
		return value;
	}

    public function updateScale(?_x:Float, ?_y:Float) {
		_x ??= scaleX;
		_y ??= scaleY;

		@:bypassAccessor scaleX = _x;
		@:bypassAccessor scaleY = _y;

        for (line in members) {
            for (glyph in line) {
                glyph.scale.set(_x, _y);
                glyph.updateHitbox();
                glyph.setPosition(line.x + (glyph.spawnPos.x * _x), line.y + (glyph.spawnPos.y * _y));
            }
        }

        updateAlignment(alignment);
    }

    @:noCompletion
    inline function set_type(newType:AlphabetGlyphType):AlphabetGlyphType {
        type = newType;
        updateText(text, true);
        updateScale(scaleX, scaleY);
        return newType;
    }

    @:noCompletion
    function set_text(newText:String):String {
        newText = newText.replace('\\n', '\n');
        updateText(newText);
        updateScale(scaleX, scaleY);
        return text = newText;
    }

    @:noCompletion
    inline function set_alignment(newAlign:AlphabetAlignment):AlphabetAlignment {
        alignment = newAlign;
        updateScale(scaleX, scaleY);
        return newAlign;
    }

    @:noCompletion
    override function set_color(value:Int) {
        for(line in members)
            line.color = value;
        return super.set_color(value);
    }

    override function destroy() {
        distancePerItem.put();
        super.destroy();
    }
	
}

class AlphabetLine extends FlxTypedSpriteGroup<AlphabetGlyph> {
    @:noCompletion
    override function set_color(value:Int) {
        for(letter in members)
            letter.color = value;

        return super.set_color(value);
    }
}

enum abstract AlphabetAlignment(String) from String to String {
    var LEFT = "left";
    var CENTER = "center";
    var RIGHT = "right";
}

typedef Glyph = {
	var anim:Null<String>;
	var offsets:Array<Float>;
	var offsetsBold:Array<Float>;
}

class AlphabetGlyph extends FunkinSprite {
	public var image(default, set):String;
	public static var allGlyphs:Map<String, Glyph>;

	public var type(default, set):AlphabetGlyphType;
	public var char(default, set):String;

	public var row:Int = 0;
	public var spawnPos:FlxPoint = FlxPoint.get();
	public var letterOffset:Array<Float> = [0, 0];
	public var curGlyph:Glyph = null;

	public var parent:Alphabet;

	public function new(x:Float = 0, y:Float = 0, char:String = "", ?type:AlphabetGlyphType = BOLD) {
		super(x, y);
		image = 'alphabet';
		@:bypassAccessor this.type = type;
		this.char = char;
	}

	@:noCompletion
	inline function set_type(newType:String):String {
		set_char(char);
		return type = newType;
	}

	@:noCompletion
	function set_image(value:String):String {
		if (frames == null) {
			frames = Paths.sparrowAtlas(image = value);
			return value;
		}

		var lastAnim:String = null;
		if (animation != null) lastAnim = animation.name;

		frames = Paths.sparrowAtlas(image = value);
		
		if (lastAnim != null) {
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);
			updateHitbox();
		}

		return value;
	}

	@:noCompletion
	inline function set_char(newChar:String):String {
		frames = Paths.sparrowAtlas(image);

		var converted:String = newChar.toLowerCase();
		final isLowerCase:Bool = converted == newChar;
		var suffix:String;

		curGlyph = allGlyphs[allGlyphs.exists(converted) ? converted : '?'];

		if (type == NORMAL) {
			if (Util.isLetter(converted)) suffix = isLowerCase ? 'lowercase' : 'uppercase';
			else suffix = 'normal';
		} else suffix = 'bold';

		converted = '${curGlyph.anim} $suffix';
		
		animation.addByPrefix(converted, converted, 24);
		animation.play(converted);

		updateHitbox();

		return char = newChar;
	}

	override function destroy() {
		spawnPos.put();
		super.destroy();
	}

	public function updateLetterOffset() {
		if (animation.curAnim == null) return;

		var add:Float = 110;
		if (animation.curAnim.name.endsWith('bold')) {
			if (curGlyph.offsetsBold != null) letterOffset = curGlyph.offsetsBold;
			add = 70;
		} else if (curGlyph.offsets != null) letterOffset = curGlyph.offsets;

		add *= scale.y;
		offset.x += letterOffset[0] * scale.x;
		offset.y += letterOffset[1] * scale.y - (add - height);
	}

	override function updateHitbox() {
		super.updateHitbox();
		updateLetterOffset();
	}
}

enum abstract AlphabetGlyphType(String) from String to String {
	var BOLD = "bold";
	var NORMAL = "normal";
}