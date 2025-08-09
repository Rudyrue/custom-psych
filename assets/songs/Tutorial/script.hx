import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.backend.Conductor;

function create() {
	game.dad.setPosition(game.gf.x, game.gf.y);
	game.gf.visible = false;
}

game.camZooming = false;

function movedCamera(name:String) {
	var zoomTo:Float = name == 'opponent' ? 1.3 : 1;
	if (game.camGame.zoom == zoomTo) return;
	FlxTween.tween(game.camGame, {zoom: zoomTo}, (Conductor.stepCrotchet * 4 * 0.001), {ease: FlxEase.elasticInOut});
}