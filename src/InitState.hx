class InitState extends flixel.FlxState {
	override function create() {
		#if AWARDS_ALLOWED 
		Awards.load();
		#end
		Controls.load();
		Scores.load();
		
		Mods.reload();
		Meta.cacheFiles();

		Language.reloadPhrases();

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.plugins.add(new Conductor());

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = FlxG.mouse.useSystemCursor = true;

		if (Settings.data.flashingLights) {
			FlxG.switchState(new FlashingState());
			return;
		}
		
		FlxG.switchState(Type.createInstance(Main.initState, []));
	}
}