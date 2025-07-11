package funkin.states;

import funkin.objects.AttachedSprite;
import funkin.objects.CreditsSchema;

class CreditsState extends FunkinState
{
	final defaultCredits:Array<CreditsPageSchema> = [
		/**
		```haxe
		{
			name: "My Team",
			users: [
				// all fields are optional, except name.
				// NOTE: leaving any of these unset will either not display them or use a fallback value (antialiasing sets itself automatically depending on if the icon ends in -pixel for example)
				{name: "Me", icon: "myself", role: "stuff", url: "https://example.com", color: 0xFF00FFFF, pronouns: "they/them", antialiasing: true},
				{name: "My Mom", icon: "mom", role: "hi mom", url: "https://youtu.be/rgSNmapyrHw?si=IES4WH-bYbYUY5Ly", color: 0xFFFF0000, pronouns: "she/her", antialiasing: true}
			],
			icon: "superCoolHeaderIcon"
		},
		```
		**/
		{
			name: "Psych Engine Team",
			users: [
				{name: "Shadow Mario", icon: "shadowmario", role: "Main Programmer, Head Developer", url: "https://ko-fi.com/shadowmario", pronouns: "he/him", color: 0xFF444444},
				{name: "Riveren", icon: "riveren", role: "Main Artist and Animator", url: "https://twitter.com/riverennn", pronouns: "any", color: 0xFF14967B},
				{name: "Join the Psych Ward!", icon: "discord", role: "Official Discord Server", url: "https://discord.gg/2ka77eMXDv", pronouns: "it's a discord server.", color: 0xFF5165F6},
			],
		},
		{
			name: "Psych Engine Contributors",
			users: [
				{name: "bb-panzu", icon: "bb", role: "Former Programmer", url: "https://twitter.com/bbpnz213", pronouns: "he/him", color: 0xFF3E813A},
				{name: "IamMorwen", icon: "crowplexus", role: "HScript Iris, Input System V3, and Other PRs", url: "https://bsky.app/profile/crowplexus.bsky.social", pronouns: "any", color: 0xFFCFCFCF},
				{name: "Kamizeta", icon: "kamizeta", role: "Creator of Pessy, Psych Engine's mascot", url: "https://www.instagram.com/cewweey/", pronouns: "para/béns", color: 0xFFD21C11},
				{name: "MaxNeton", icon: "maxneton", role: "Loading Screen Easter Egg Artist/Animator", url: "https://bsky.app/profile/maxneton.bsky.social", color: 0xFF3C2E4E},
				{name: "Keoiki", icon: "keoiki", role: "Note Splash Animations, Additional Characters for Alphabet", url: "https://twitter.com/Keoiki_", color: 0xFFD2D2D2},
				{name: "sqirra-rng", icon: "sqirra", role: "Crash Handler, Original code for the Chart Editor's Waveform", url: "https://twitter.com/sqirradotdev", pronouns: "she/her", color: 0xFFE1843A},
				{name: "EliteMasterEric", icon: "mastereric", role: "Runtime Shaders support and Other PRs", url: "https://twitter.com/EliteMasterEric", color: 0xFFFFBD40},
				{name: "MAJigsaw77", icon: "majigsaw", role: ".MP4 Video Loader Library (hxvlc)", url: "https://twitter.com/MAJigsaw77", color: 0xFF5F5F5F},
				{name: "iFlicky", icon: "flicky", role: "Composer of Psync and Tea Time, Sound Effects", url: "https:twitter.com/flicky_i", color: 0xFF9E29CF},
				{name: "KadeDev", icon: "kade", role: "Fixed some issues on Chart Editor and Other PRs", url: "https://twitter.com/kade0912", color: 0xFF64A250},
				{name: "superpowers04", icon: "superpowers04", role: "LUA JIT Fork", url: "https://twitter.com/superpowers04", pronouns: "she/her", color: 0xFFB957ED},
				{name: "CheemsAndFriends", icon: "cheems", role: "Creator of FlxAnimate", url: "https://twitter.com/CheemsnFriendos", color: 0xFFE1E1E1},
			]
		},
		{
			name: "Funkin' Crew",
			users: [
				{name: "ninjamuffin99", icon: "ninjamuffin99", role: "Programmer of Friday Night Funkin'", url: "https://twitter.com/ninja_muffin99", color: 0xFFCF2D2D},
				{name: "PhantomArcade", icon: "phantomarcade", role: "Animator of Friday Night Funkin'", url: "https://twitter.com/PhantomArcade3K", color: 0xFFFADC45},
				{name: "evilsk8r", icon: "evilsk8r", role: "Artist of Friday Night Funkin'", url: "https://twitter.com/evilsk8r", color: 0xFF5ABD4B},
				{name: "kawaisprite", icon: "kawaisprite", role: "Composer of Friday Night Funkin'", url: "https://twitter.com/kawaisprite", color: 0xFF378FC7},
			]
		}
	];

	var displayCredits:Array<CreditsPageSchema> = [];

	// [0] = Selected Page | [1] = Selected User
	var selections:Array<Int> = [0, 0];
	var selectLength:Array<Int> = [0, 0];

	var grpOptions:FlxTypedSpriteGroup<Alphabet>;
	var grpHeaderIcons:FlxSpriteGroup;
	var intendedColor:FlxColor;
	var headerText:FlxText;
	var bg:FlxSprite;

	var currentPage:CreditsPageSchema = null;
	var currentUser:CreditSchema = null;

	override function create()
	{
		super.create(); // make sure the transition works

		// push mod credits in *this exact line* so they show up before the default ones
		for (v in defaultCredits) displayCredits.push(v); // push default credits.

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Looking at the Credits", "In the Menus");
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menus/desatBG'));
		bg.antialiasing = Settings.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// ——— TOP BAR ——— //

		headerText = new FlxText(0, 0, FlxG.width, displayCredits[selections[0]].name);
		headerText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, CENTER);
		headerText.antialiasing = Settings.data.antialiasing;
		headerText.textField.backgroundColor = 0xAA000000;
		headerText.textField.background = true;
		add(headerText);

		// ——— OPTIONS ——— //

		add(grpHeaderIcons = new FlxSpriteGroup());
		add(grpOptions = new FlxTypedSpriteGroup());

		for (i in 0...3) {
			var alpha:Alphabet = new Alphabet(0, 0, "", NORMAL, CENTER, 0.8);
			alpha.antialiasing = Settings.data.antialiasing;
			alpha.isMenuItem = true;
			alpha.changeX = false;
			alpha.screenCenter(X);
			alpha.kill();
			grpOptions.add(alpha);
		}
		
		createHeaderOptions();
		createUserOptions();
		resetPageVariables();
		changeBGColor();

		// ——— BOTTOM BAR (BRIEF) ——— //

		final footerText:FlxText = new FlxText(0, 0, FlxG.width, "Left/Right ~ Switch Pages | Up/Down ~ Select User Enter ~ Redirect to the user's page.");
		footerText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, CENTER);
		footerText.y = (FlxG.height - footerText.height);
		footerText.antialiasing = Settings.data.antialiasing;
		footerText.textField.backgroundColor = 0xAA000000;
		footerText.textField.background = true;
		add(footerText);

		FlxTween.tween(footerText, {y: footerText.y + 50}, 1.0, {
			onComplete: (tween:FlxTween) -> footerText.kill(),
			ease: FlxEase.bounceOut,
			startDelay: 3.0,
		});
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		updateTexts(elapsed);
		for (idx => letter in grpOptions.members) {
			if (lerpSelected == selections[1]) letter.x = FlxMath.lerp(letter.x, 100 + 20, 0.3);
			else if (lerpSelected == selections[1] - 1) letter.x = FlxMath.lerp(letter.x, 50 + 20, 0.3);
			else if (lerpSelected == selections[1] + 1) letter.x = FlxMath.lerp(letter.x, 20, 0.3);
		}
		moveControls();
		if (Controls.justPressed('accept') && currentUser.url != null) Util.openURL(currentUser.url);
		if (Controls.justPressed('back')) FunkinState.switchState(new MainMenuState());
	}

	function createHeaderOptions():Void {
		// this should generate the icons and whatnot.
		selectLength[0] = displayCredits.length - 1;
		changeSelection(0, 0);
	}

	function createUserOptions():Void {
		for (i in 0...grpOptions.members.length)
			grpOptions.members[i].kill();
		
		for (idx => user in displayCredits[selections[0]].users) {
			final bet:Alphabet = grpOptions.recycle(Alphabet);
			bet.alpha = selections[1] == idx ? 1.0 : 0.6;
			bet.targetY = idx;
			bet.type = NORMAL; // just making sure.
			bet.alignment = CENTER;
			bet.text = user.name;
			bet.screenCenter(X);
			bet.snapToPosition();
		}

		selectLength[1] = displayCredits[selections[0]].users.length - 1;
		changeSelection(0, 1);

		for (i in 0...(selectLength[1] + 1)) {
			var item:Alphabet = grpOptions.members[i];
			if (item == null) continue;

			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;
		}
	}

	/**
	 * Changes the current selection of the specified cursor.
	 *
	 * 0 = Header / Page Selection.
	 *
	 * 1 = User Selction.
	 */
	function changeSelection(next:Int = 0, type: Int = 0):Void {
		var previous:Int = selections[type];
		selections[type] = FlxMath.wrap(previous + next, 0, selectLength[type]);
		var current:Int = selections[type];
		if (current != previous) {
			FlxG.sound.play(Paths.sound('scroll'));
			resetPageVariables();
			switch type {
				case 0:
					createUserOptions();
					headerText.text = currentPage.name;
					changeBGColor();
				case 1:
					final item:Alphabet = grpOptions.members[current];
					item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
					item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;
					final prev:Alphabet = grpOptions.members[previous];
					if (prev != null) prev.alpha = 0.6;
					if (item != null) item.alpha = 1.0;
					changeBGColor();
			}
		}
	}

	function resetPageVariables():Void {
		currentPage = displayCredits[selections[0]];
		currentUser = currentPage.users[selections[1]];
	}

	function changeBGColor(force:Bool = false):Void {
		var nextColor = currentUser.color;
		if (nextColor != intendedColor || force) {
			intendedColor = nextColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}
	}

	function moveControls():Void {
		if (selectLength[0] > 1) { // Pages
			final leftPressed:Bool = Controls.justPressed('ui_left');
			if (leftPressed || Controls.justPressed('ui_right')) changeSelection(leftPressed ? -1 : 1, 0);
		}
		if (selectLength[1] > 1) { // Users
			final upPressed:Bool = Controls.justPressed('ui_up');
			if (upPressed || Controls.justPressed('ui_down')) changeSelection(upPressed ? -1 : 1, 1);
		}
	}

	var _drawDistance:Int = 5;
	var _lastVisibles:Array<Int> = [];
	var lerpSelected:Float = 0.0;

	public function updateTexts(elapsed:Float = 0.0) {
		lerpSelected = FlxMath.lerp(selections[1], lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles) {
			var text = grpOptions.members[i];
			if (text == null) continue; // need to do this since regens can happen during this function.
			text.visible = text.active = false;
			//grpIcons.members[i].visible = false;
		}
		_lastVisibles.resize(0);

		var min:Int = Math.round(FlxMath.bound(lerpSelected - _drawDistance, 0, selectLength[1] + 1));
		var max:Int = Math.round(FlxMath.bound(lerpSelected + _drawDistance, 0, selectLength[1] + 1));
		for (i in min...max) {
			var item:Alphabet = grpOptions.members[i];
			if (item == null) continue;
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.spawnPos.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.spawnPos.y;
			/*
			var icon:CharIcon = grpIcons.members[i];
			icon.visible = true;
			icon.setPosition(item.x + (item.width + (icon.width * 0.05)), item.y - (item.height * 0.5));
			*/
			_lastVisibles.push(i);
		}
	}
}
