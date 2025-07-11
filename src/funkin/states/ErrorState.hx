package funkin.states;

class ErrorState extends FunkinState {
	public dynamic function acceptCallback():Void {}
	public dynamic function backCallback():Void {}
	public var errorMsg:String;

	public function new(error:String, accept:Void->Void = null, back:Void->Void = null) {
		this.errorMsg = error;
		this.acceptCallback = accept;
		this.backCallback = back;

		super();
	}

	public var errorSine:Float = 0;
	public var errorText:FlxText;
	override function create() {
		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.GRAY;
		bg.antialiasing = Settings.data.antialiasing;
		add(bg);
		bg.screenCenter();

		errorText = new FlxText(0, 0, FlxG.width - 300, errorMsg, 32);
		errorText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errorText.scrollFactor.set();
		errorText.borderSize = 2;
		errorText.screenCenter();
		add(errorText);
		super.create();
	}

	override function update(elapsed:Float) {
		errorSine += 180 * elapsed;
		errorText.alpha = 1 - Math.sin((Math.PI * errorSine) / 180);

		if (Controls.justPressed('accept')) acceptCallback();
		else if (Controls.justPressed('back')) backCallback();

		super.update(elapsed);
	}
}