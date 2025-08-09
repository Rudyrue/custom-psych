package funkin.stages;

import flixel.graphics.frames.FlxFramesCollection;

class StageWeek1 extends Stage {
	public function new() {
		super('stage');
	}

	override function create():Void {
		final assets:FlxFramesCollection = sparrowAtlas('assets');

		var bg:FlxSprite = new FlxSprite(-600, -200);
		bg.frames = assets;
		bg.animation.addByPrefix('FUCK', 'stageback', 0, false);
		bg.animation.play('FUCK');
		addBehindObject(bg, PlayState.self.gf);

		var front:FlxSprite = new FlxSprite(-650, 600);
		front.frames = assets;
		front.animation.addByPrefix('FUCK', 'stagefront', 0, false);
		front.animation.play('FUCK');
		addBehindObject(front, PlayState.self.gf);

		if (Settings.data.reducedQuality) return;

		var leftLight:FlxSprite = new FlxSprite(-125, -100);
		leftLight.frames = assets;
		leftLight.animation.addByPrefix('FUCK', 'stage_light', 0, false);
		leftLight.animation.play('FUCK');
		leftLight.scrollFactor.set(0.9, 0.9);
		add(leftLight);

		var rightLight:FlxSprite = new FlxSprite(1225, -100,);
		rightLight.frames = assets;
		rightLight.animation.addByPrefix('FUCK', 'stage_light', 0, false);
		rightLight.animation.play('FUCK');
		rightLight.scrollFactor.set(0.9, 0.9);
		rightLight.flipX = true;
		add(rightLight);

		var curtains:FlxSprite = new FlxSprite(-500, -300);
		curtains.frames = assets;
		curtains.animation.addByPrefix('FUCK', 'stagecurtains', 0, false);
		curtains.animation.play('FUCK');
		curtains.scrollFactor.set(1.3, 1.3);
		add(curtains);
	}
}