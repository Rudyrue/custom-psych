package funkin.objects;

import funkin.objects.Strumline;

class NoteSplash extends FunkinSprite {
	public var skin(default, set):String;
	public var lane:Int = 0;
	public var listOfAnims:Int = 2;
	function set_skin(value:String):String {
		reload(value);
		return skin = value;
	}

	public function new(lane:Int, ?skin:String) {
		super();
		this.lane = lane;
		reload(skin);

		animation.finishCallback = function(_) {
			visible = false;
		}
	}

	public function reload(?path:String) {
		if (path.length == 0) {
			path = 'noteSplashes/${Util.format(Settings.data.noteSplashSkin)}';
		}

		if (!Paths.exists('images/$path.png')) path = Settings.default_data.noteSplashSkin;

		frames = Paths.sparrowAtlas(path);

		var colour:String = Note.colours[lane];
		for (i in 1...listOfAnims + 1) {
			//if (!frames.frames.contains('note splash $colour $i')) continue; FUCK
			animation.addByPrefix('hit$i', 'note splash $colour $i', 24, false);
		}

		animation.play('hit1');
	
		scale.set(0.7, 0.7);
		updateHitbox();
		offset.set(10, 10);

		visible = false;
	}

	public function hit(strum:Receptor) {
		visible = true;
		playAnim('hit${FlxG.random.int(1, listOfAnims)}');
		updateHitbox();
		setPosition(strum.x + (strum.width - width) * 0.5, strum.y + (strum.height - height) * 0.5);

		animation.curAnim.frameRate = FlxG.random.int(22, 26);
	}
}