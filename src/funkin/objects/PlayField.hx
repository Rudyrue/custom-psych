package funkin.objects;

import funkin.backend.Song.Chart;
import funkin.objects.Note;
import funkin.objects.Strumline.Receptor;
import lime.app.Application;
import lime.ui.KeyCode;

class PlayField extends flixel.group.FlxSpriteGroup {
	public var downscroll:Bool = false;
	public var botplay(default, set):Bool = false;
	public var scrollSpeed(default, set):Float = 1.0;
	public var playerID(default, set):Int;
	public var rate(default, set):Float = 1.0;
	public var modifiers:Bool = false;

	public var unspawnedNotes:Array<Note> = [];
	public var notePassedIndex:Int = 0;
	public var noteSpawnIndex:Int = 0;
	public var noteSpawnDelay:Float = 1500;

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	public dynamic function noteHit(strumline:Strumline, note:Note):Void {}
	public dynamic function sustainHit(strumline:Strumline, note:Note):Void {}
	public dynamic function noteMiss(strumline:Strumline, note:Note):Void {}
	public dynamic function ghostTap(strumline:Strumline):Void {}
	public dynamic function noteSpawned(note:Note):Void {}

	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	var notes:FlxTypedSpriteGroup<Note>;
	
	function set_playerID(value:Int):Int {
		if (playerID == value) return value;
		if (value >= strumlines.length) return playerID;

		for (i => line in strumlines.members) {
			line.ai = (value == i) ? botplay : true;
		}

		return playerID = value;
	}
	public var currentPlayer(get, never):Strumline;
	function get_currentPlayer():Strumline {
		if (playerID >= strumlines.length) {
			return strumlines.members[strumlines.length - 1];
		}

		return strumlines.members[playerID];
	}

	public var leftSide(get, never):Strumline;
	function get_leftSide():Strumline {
		return strumlines.members[0];
	}

	public var rightSide(get, never):Strumline;
	function get_rightSide():Strumline {
		return strumlines.members[1];
	}

	function set_botplay(value:Bool):Bool {
		return botplay = currentPlayer.ai = value;
	}

	function set_scrollSpeed(value:Float):Float {
		var ratio:Float = value / scrollSpeed;
		if (ratio != 1) {
			for (note in unspawnedNotes) {
				note.resizeByRatio(ratio);
			}
		}

		return scrollSpeed = value;
	}

	function set_rate(value:Float):Float {
		#if FLX_PITCH
		Conductor.rate = value;
		FlxG.animationTimeScale = value;

		var ratio:Float = rate / value;
		if (ratio != 1) {
			for (note in unspawnedNotes) note.resizeByRatio(ratio);
		}

		rate = value;
		#else
		rate = 1.0; // ensuring -Crow
		#end

		return rate;
	}

	public function new(strumlines:Array<Strumline>, ?playerID:Int = 0) {
		super();

		add(this.strumlines = new FlxTypedSpriteGroup<Strumline>());
		for (line in strumlines) this.strumlines.add(line);
		this.playerID = playerID;

		add(notes = new FlxTypedSpriteGroup<Note>());
		notes.active = false;

		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);
	}

	override function destroy():Void {
		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);

		super.destroy();
	}

	override function update(delta:Float):Void {
		super.update(delta);

		spawnNotes();

		var nextNote:Note = unspawnedNotes[notePassedIndex];
		if (nextNote != null && nextNote.rawTime - Conductor.rawTime <= 0) {
			if (!nextNote.ignore && !nextNote.isSustain && nextNote.player == playerID && Settings.data.assistClaps) {
				FlxG.sound.play(Paths.sound('hitsound'));
			}
			notePassedIndex++;
		}
	
		for (note in notes.members) {
			if (note == null) continue;

			note.update(delta);

			var strum:Receptor = strumlines.members[note.player].members[note.lane];
			note.followStrum(strum, downscroll, scrollSpeed);

			if (note.player == playerID) {
				if (botplay) botplayInputs(strum, note);
				else if (note.isSustain) sustainInputs(strum, note);
			} else botplayInputs(strum, note);

			if (!botplay && note.player == playerID && !note.missed && !note.isSustain && note.tooLate) {
				noteMiss(strum.parent, note);
			}

			if (note.time < Conductor.rawTime - 300) {
				notes.remove(note);
				note.destroy();
			}
		}
	}

	dynamic function spawnNotes() {
		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteToSpawn:Note = unspawnedNotes[noteSpawnIndex];
			if (noteToSpawn.rawHitTime > noteSpawnDelay) break;

			noteSpawned(noteToSpawn);

			notes.add(noteToSpawn);
			noteToSpawn.spawned = true;
			noteSpawnIndex++;
		}
	}

	dynamic function botplayInputs(strum:Receptor, note:Note):Void {
		if (!note.canHit || note.ignore || note.breakOnHit || note.time > Conductor.rawTime) return;
		
		// sustain input
		if (note.isSustain) {
			note.clipToStrum(strum, downscroll);
			if (note.wasHit) return;

			strum.playAnim('notePressed');
			note.wasHit = true;
			sustainHit(strum.parent, note);
			return;
		}

		if (Settings.data.pressAnimOnTap) strum.playAnim('notePressed');

		// normal notes
		note.wasHit = true;
		noteHit(strum.parent, note);
		note.destroy();
		notes.remove(note);
	}

	dynamic function sustainInputs(strum:Receptor, note:Note) {
		var parent:Note = note.parent;

		if (!parent.wasHit || !parent.canHit || parent.missed) return;

		var playerHeld:Bool = keysHeld[note.lane] || parent.coyoteTimer > 0;
		var tooLate:Bool = parent.wasHit ? note.time < Conductor.rawTime : parent.tooLate;

		if (note.wasHit)
			parent.coyoteTimer = keysHeld[note.lane] ? 0.25 : parent.coyoteTimer - FlxG.elapsed;

		if (!playerHeld) {
			if (tooLate && !note.wasHit) {
				noteMiss(strum.parent, parent);
				parent.missed = true;
			}

			return;
		}

		strum.queueStatic = !keysHeld[note.lane];
		note.clipToStrum(strum, downscroll);

		if (note.time <= Conductor.rawTime && !note.wasHit) note.wasHit = true;
		else return;
		
		parent.coyoteTimer = 0.25;
		
		strum.playAnim('notePressed');
		sustainHit(strum.parent, note);
	}

	public function loadNotes(chart:Chart) {
		var parsedNotes:Array<NoteData> = Song.parse(chart);

		for (note in unspawnedNotes) {
			note.destroy();
			note = null;
		}
		unspawnedNotes.resize(0);

		var oldNote:Note = null;

		var lanes:Array<Int> = [for (i in 0...Strumline.keyCount) i];
		if (Settings.data.gameplaySettings['mirroredNotes'] && modifiers) {
			// dumb way of doing `for (i in 4...0) {}` but whatever
			var i:Int = Strumline.keyCount;
			lanes = [
				while (i > 0) {
					i--;
					i;
				}
			];
		}

		if (Settings.data.gameplaySettings['randomizedNotes'] && modifiers) FlxG.random.shuffle(lanes);
		for (i => note in parsedNotes) {
			// thanks shubs /s
			if (note.lane < 0) continue;
			
			if (modifiers && !Settings.data.gameplaySettings['mines'] && note.type == 'Hurt Note') {
				continue;
			}

			// fixes a crash when loading a chart with only one strumline in the playfield
			note.player = Std.int(Math.min(note.player, strumlines.length - 1));

			// stepmania shuffle
			// instead of randomizing every note's lane individually
			// because chords were buggy asf lmao
			note.lane = lanes[note.lane];
			if (!Settings.data.gameplaySettings['sustains'] && modifiers) note.length = 0;

			var daBPM:Float = Conductor.getPointFromTime(note.time).bpm;

			if (i != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnedNotes) {
					if (evilNote.isSustain) continue;

					var matches:Bool = (note.lane == evilNote.lane && note.player == evilNote.player);
					if (!matches || Math.abs(note.time - evilNote.rawTime) > 2.0) continue;

					evilNote.destroy();
					unspawnedNotes.remove(evilNote);
					for (piece in evilNote.pieces) {
						piece.destroy();
						unspawnedNotes.remove(piece);
					}
					evilNote.pieces.resize(0);
				}
			}

			var swagNote:Note = new Note(note);
			unspawnedNotes.push(swagNote);

			var curStepCrotchet:Float = (60 / daBPM) * 1000 * 0.25;
			final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrotchet);
			if (roundSus < 0) {
				oldNote = swagNote;
				continue;
			}

			for (susNote in 0...roundSus) {
				oldNote = unspawnedNotes[unspawnedNotes.length - 1];

				var sustainNote:Note = new Note({
					time: note.time + (curStepCrotchet * susNote),
					lane: note.lane,
					length: note.length,
					type: note.type,
					player: note.player,
					altAnim: note.altAnim
				}, true, oldNote);
				sustainNote.parent = swagNote;
				sustainNote.correctionOffset.y = downscroll ? 0 : swagNote.height * 0.5;
				unspawnedNotes.push(sustainNote);
				swagNote.pieces.push(sustainNote);

				if (!oldNote.isSustain) continue;

				//oldNote.scale.y *= 44 / oldNote.frameHeight;
				oldNote.scale.y /= rate;
				oldNote.resizeByRatio(curStepCrotchet / Conductor.stepCrotchet);
			}

			oldNote = swagNote; 
		}

		// forces sustains to be behind notes
		// if you want them to be in front just use this code instead lol

		//unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));
		unspawnedNotes.sort((a, b) -> {
			if (a.time == b.time) return a.isSustain ? -1 : Std.int(a.time - b.time);
			return Std.int(a.time - b.time);
		});
		oldNote = null;
	}

	public var keysHeld:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];
	inline function input(key:KeyCode, _):Void {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1 || keysHeld[dir] || FlxG.state.subState != null) return;
		keysHeld[dir] = true;

		var closestDistance:Float = Math.POSITIVE_INFINITY;
		var noteToHit:Note = null;
		for (note in notes.members) {
			if (note == null) continue;
			if (note.player != playerID || !note.hittable || note.lane != dir || note.isSustain) continue;
			
			var distance:Float = Math.abs(note.rawHitTime);
			if (distance < closestDistance) closestDistance = distance;
			else continue;

			noteToHit = note;
		}

		if (noteToHit == null) {
			currentPlayer.members[dir].playAnim('pressed');
			if (Settings.data.ghostTapping) return;
			ghostTap(currentPlayer);
			return;
		} 

		if (Settings.data.pressAnimOnTap) currentPlayer.members[dir].playAnim('notePressed');
		noteHit(currentPlayer, noteToHit);
		noteToHit.wasHit = true;
		noteToHit.destroy();
		notes.remove(noteToHit);
		noteToHit = null;
	}

	inline function release(key:KeyCode, _):Void {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(key));
		if (dir == -1) return;
		
		keysHeld[dir] = false;
		currentPlayer.members[dir].playAnim('default');
	}
}