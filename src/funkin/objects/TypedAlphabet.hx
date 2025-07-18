package funkin.objects;

class TypedAlphabet extends Alphabet {
	public dynamic function onFinish() {}
	public var finishedText:Bool = false;
	public var delay:Float = 0.05;
	public var sound:String = 'dialogue';
	public var volume:Float = 1;

	public function new(x:Float, y:Float, text:String = "", ?delay:Float = 0.05, ?type:AlphabetGlyphType = NORMAL) {
		super(x, y, text, type);
		this.delay = delay;
	}

	override function set_text(newText:String) {
		super.set_text(newText);

		resetDialogue();
		return newText;
	}

	var _curLetter:Int = -1;
	var _timeToUpdate:Float = 0;
	override function update(elapsed:Float) {
		if (finishedText) {
			super.update(elapsed);
			return;
		}

		var playedSound:Bool = false;
		_timeToUpdate += elapsed;
		while (_timeToUpdate >= delay) {
			showCharacterUpTo(_curLetter + 1);
			if (!playedSound && sound.length != 0 && (delay > 0.025 || _curLetter % 2 == 0)) {
				FlxG.sound.play(Paths.sound(sound), volume);
			}
			playedSound = true;

			_curLetter++;
			if (_curLetter >= members.length - 1) {
				finishedText = true;
				onFinish();
				_timeToUpdate = 0;
				break;
			}
			_timeToUpdate = 0;
		}

		super.update(elapsed);
	}

	public function showCharacterUpTo(upTo:Int) {
		var start:Int = _curLetter;
		if (start < 0) start = 0;

		for (i in start...(upTo + 1)) {
			if (members[i] != null) members[i].visible = true;
		}
	}

	public function resetDialogue() {
		_curLetter = -1;
		finishedText = false;
		_timeToUpdate = 0;
		for (letter in members) letter.visible = false;
	}

	public function finishText() {
		if (finishedText) return;

		showCharacterUpTo(members.length - 1);
		if (sound.length != 0) FlxG.sound.play(Paths.sound(sound), volume);
		finishedText = true;
		
		onFinish();
		_timeToUpdate = 0;
	}
}