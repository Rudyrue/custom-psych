class InitState extends flixel.FlxState {
	override function create() {
		Controls.load();
		Scores.load();

		#if AWARDS_ALLOWED
		Awards.load();
		#end
		
		#if MODS_ALLOWED
		Mods.reload();
		#end
		Meta.cacheFiles();

		#if TRANSLATIONS_ALLOWED
		Language.reloadPhrases();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.plugins.add(new Conductor());
		FlxG.plugins.add(new Debug());

		FlxG.fullscreen = Settings.data.fullscreen;
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 10;
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = FlxG.mouse.useSystemCursor = true;

		if (Settings.data.flashingLights && !FlxG.save.data.seenFlashWarning) {
			FlxG.switchState(new FlashingState());
			return;
		}
		
		FlxG.switchState(Type.createInstance(Main.initState, []));
	}
}