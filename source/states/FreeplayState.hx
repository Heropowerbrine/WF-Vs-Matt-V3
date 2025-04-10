package states;

import objects.WiiCustomText;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;

class FreeplayState extends MusicBeatState
{
	public static var selectedPackName:String = "";
	public static var selectedPack:Array<String> = [];
	public static var selectedPorts:Array<String> = [];

	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	private static var selectedScroll:Int = 0;
	private static var selectedMax:Int = 0;
	var lerpSelected:Float = 0;

	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FlxSprite>;
	private var grpTexts:FlxTypedGroup<WiiCustomText>;
	private var grpPorts:FlxTypedGroup<FlxSprite>;
	private var grpStars:FlxTypedGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);
		Highscore.load();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Freeplay", null);
		#end

		for (i in 0...WeekData.weeksList.length) {

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			if(weekIsLocked(WeekData.weeksList[i]) || !selectedPack.join('|').contains(leWeek.weekName.toLowerCase().replace(' ', ''))) continue;

			

			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, leWeek.weekName.toLowerCase().replace(' ', ''), song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('freeplay/bg'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		grpPorts = new FlxTypedGroup<FlxSprite>();
		add(grpPorts);

		grpSongs = new FlxTypedGroup<FlxSprite>();
		add(grpSongs);

		grpTexts = new FlxTypedGroup<WiiCustomText>();
		add(grpTexts);

		grpStars = new FlxTypedGroup<FlxSprite>();
		add(grpStars);

		for (i in 0...songs.length)
		{
			var label:FlxSprite = new FlxSprite(40).loadGraphic(Paths.image('freeplay/labels/${songs[i].weekLabel}'));
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.ID = i;
			grpSongs.add(label);


			Mods.currentModDirectory = songs[i].folder;
			PlayState.storyWeek = songs[i].week;
			Difficulty.loadFromWeek();

			var fcLabel:FlxSprite = new FlxSprite(40).loadGraphic(Paths.image('freeplay/labels/FCbadge'));
			fcLabel.antialiasing = ClientPrefs.data.antialiasing;
			fcLabel.ID = i;
			fcLabel.visible = Highscore.getFullCombo(songs[i].songName, 0);
			grpStars.add(fcLabel);

			var songText = new WiiCustomText(170, 60, 0, songs[i].locked ? "???" : songs[i].songName, 1.5, 'wii');
			songText.color = 0xFF000000;
			songText.alignment = 'left';
			songText.noAA = false;
			songText.regenText(true);
			grpTexts.add(songText);

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.scale.set(0.7, 0.7);
			icon.updateHitbox();
			if (songs[i].locked || !Highscore.getCompletion(songs[i].songName)) {
				icon.visible = false;
			}
			if (songs[i].songCharacter.endsWith("nightmarematt")) {
				icon.offset.x += 15;
				icon.offset.y += 15;
			}

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		for (i in 0...selectedPorts.length) {
			var port = new FlxSprite().loadGraphic(Paths.image("freeplay/ports/"+selectedPorts[i]));
			port.x = FlxG.width - port.width; port.alpha = 0; port.antialiasing = true;
			grpPorts.add(port);
		}

		scoreText = new FlxText(FlxG.width * 0.7, (FlxG.height - (26+56))+5, 0, "", 24);
		scoreText.setFormat(Paths.font("contm.ttf"), 24, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, FlxG.height - (26+56)).makeGraphic(1, 56, 0xFF000000);
		scoreBG.alpha = 0.6;
		
		diffText = new FlxText(scoreText.x, scoreText.y + 26, 0, "", 24);
		diffText.font = scoreText.font;


		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("contm.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var topBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/modeBar'));
		topBar.antialiasing = ClientPrefs.data.antialiasing;
		add(topBar);
		topBar.screenCenter(X);

		var textShit = "bonusSongs";
		if (selectedPackName == "StoryMode") textShit = "storySongs";

		var title:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/'+textShit));
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);
		title.screenCenter(X);

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("contm.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);

		add(scoreBG);
		add(diffText);
		add(scoreText);
		
		player = new MusicPlayer(this);
		add(player);

		#if mobile
		addVirtualPad(FULL, A_B_C_X_Y_Z);
		#end
		
		changeSelection();
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		removeVirtualPad();
		addVirtualPad(FULL, A_B_C_X_Y_Z);
	}

	public function addSong(songName:String, weekNum:Int, weekName:String, songCharacter:String, color:Int)
	{
		var song = new SongMetadata(songName, weekNum, weekName, songCharacter, color);
		PlayState.storyWeek = weekNum;
		Difficulty.loadFromWeek();
		var doPush:Bool = true;
		switch(weekName) {
			case "wiik1":
				if (!Highscore.getWeekCompletion("1wiik1")) song.locked = true;
			case "wiik2":
				if (!Highscore.getWeekCompletion("2wiik2")) song.locked = true;
			case "wiikz":
				if (!Highscore.getWeekCompletion("3wiikZ")) song.locked = true;
			case "fridaynightfisticuffs":
				if (!Highscore.getWeekCompletion("4wiikFisticuffs")) song.locked = true;
			case "wiikwhitegloves":
				if (!Highscore.getWeekCompletion("5wiikWG")) song.locked = true;
			default:

				switch(songName.toLowerCase()) {
					case "3hot" | "fired up" | "mii funkin" | "revolution":
						if (!Highscore.getWeekCompletion("1wiik1")) song.locked = true;
					case "4hot" | "battlefield" | "swap!" | "motion control":
						if (!Highscore.getWeekCompletion("2wiik2")) song.locked = true;
					case "miisacre" | "lazulii" | "snacks":
						if (!Highscore.getWeekCompletion("3wiikZ")) song.locked = true;
					case "illusion" | "heavenfall" | "long awaited" | "god mode" | "broadcasting":
						if (!Highscore.getWeekCompletion("4wiikFisticuffs")) song.locked = true;
					case "foulplay":
						var unlocked = true;
						for (song in ["snacks", "long-awaited", "god-mode", "broadcasting", "lazulii", "illusion", "heavenfall"]) {
							if (!Highscore.getCompletion(song)) {
								unlocked = false;
							}
						}
						song.locked = !unlocked;
					case "destiny":
						if (!Highscore.getCompletion("destiny")) {
							song.locked = true;
						}
					case "funkin corner":
						if (!Highscore.getCompletion("funkin-corner")) {
							doPush = false;
						}
					default:
						//trace(songName);
				}
		}
		if (HealthNSafety.unlock) song.locked = false;

		if (Paths.formatToSongPath(songName) != "five-hot" && doPush) songs.push(song);
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	//var mouseUpdateTimer:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		/*if (mouseUpdateTimer > 0) {
			mouseUpdateTimer -= elapsed;
		} else if (FlxG.mouse.justMoved || FlxG.mouse.wheel != 0) {
			mouseUpdateTimer = 1;
		}*/


		var currentPort:String = "";
		var hidePort:Bool = false;
		if (songs[curSelected] != null) {
			currentPort = songs[curSelected].port;

			if (songs[curSelected].locked || !Highscore.getCompletion(songs[curSelected].songName)) hidePort = true;
		}
		for (i => port in grpPorts.members) {
			var selected = currentPort == selectedPorts[i];
			port.alpha = FlxMath.lerp(port.alpha, selected ? 1.0 : 0.0, (selected ? 5.0 : 12.0) * elapsed);

			if (selected) {
				port.color = (hidePort) ? FlxColor.fromRGBFloat(0, 0, 0, port.alpha) : FlxColor.fromRGBFloat(1, 1, 1, port.alpha);
			}
		}

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT #if mobile || _virtualpad.buttonZ.pressed #end) shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = 'Personal Best: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
			positionHighscore();
			
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;
					//mouseUpdateTimer = 0;
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
					//mouseUpdateTimer = 0;
				}
				if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
					//mouseUpdateTimer = 0;
				}
				if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end)
				{
					changeSelection(shiftMult);
					holdTime = 0;
					//mouseUpdateTimer = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP #if mobile || _virtualpad.buttonDown.pressed || _virtualpad.buttonUp.pressed #end)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * ((controls.UI_UP #if mobile || _virtualpad.buttonUp.pressed #end) ? -shiftMult : shiftMult));
				}

				/*if (mouseUpdateTimer > 0) {
					for (i => spr in grpSongs.members) {
						if (FlxG.mouse.overlaps(spr) && curSelected != i) {
							curSelected = i;
							var lastScroll = selectedScroll;
							changeSelection();
							selectedScroll = lastScroll;
							break;
						}
					}
				}

				if(FlxG.mouse.wheel != 0)
				{
					var lastScroll = selectedScroll;
					selectedScroll += -shiftMult * FlxG.mouse.wheel;
					if (selectedScroll < 0) selectedScroll = 0;
					if (selectedScroll > songs.length-4) selectedScroll = songs.length-4;
					//changeSelection(-shiftMult * FlxG.mouse.wheel, false);

					if (lastScroll != selectedScroll) {
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					}
				}*/
			}

			if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
				//mouseUpdateTimer = 0;
			}
			else if (controls.UI_RIGHT_P #if mobile || _virtualpad.buttonRight.justPressed #end)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
				//mouseUpdateTimer = 0;
			}

			/*if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.y >= scoreBG.y && FlxG.mouse.x >= FlxG.width-scoreBG.scale.x) {
					if (FlxG.mouse.x < FlxG.width - (scoreBG.scale.x*0.5)) {
						changeDiff(-1);
					} else {
						changeDiff(1);
					}
					_updateSongLastDifficulty();
				}
			}*/
		}

		if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.loopTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_START_TIME;
				FlxG.sound.music.endTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_END_TIME;
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new SongPackSelector());
			}
		}

		if(FlxG.keys.justPressed.CONTROL #if mobile || _virtualpad.buttonC.justPressed #end && !player.playingMusic)
		{
			persistentUpdate = false;
		        #if mobile
			removeVirtualPad();
			#end
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE #if mobile || _virtualpad.buttonY.justPressed #end && !songs[curSelected].locked)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					FlxG.sound.list.add(vocals);
					vocals.persist = true;
					vocals.looped = true;
				}
				else if (vocals != null)
				{
					vocals.stop();
					vocals.destroy();
					vocals = null;
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				if(vocals != null) //Sync vocals to Inst
				{
					vocals.play();
					vocals.volume = 0.8;
				}
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(player.paused);
			}
		}
		else if ((controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) && !player.playingMusic && !songs[curSelected].locked)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				super.update(elapsed);
				return;
			}
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET #if mobile || _virtualpad.buttonX.justPressed #end && !player.playingMusic && !songs[curSelected].locked)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
                        #if mobile
			removeVirtualPad();
			#end
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		lerpSelected = FlxMath.lerp(lerpSelected, selectedScroll-1, FlxMath.bound(elapsed * 9.6, 0, 1));

		for (label in grpSongs.members)
		{
			label.color = label.ID == curSelected?0xffACABF8:0xffffffff;
			if (songs[label.ID].locked) label.color = label.ID == curSelected?0xff595981:0xff838383;
			label.y = ((label.ID - lerpSelected) * 1.3 * 100);
			grpStars.members[label.ID].x = label.x;
			grpStars.members[label.ID].y = label.y;
			grpTexts.members[label.ID].y = (label.y + 12) + label.height/2 - grpTexts.members[label.ID].height/2;
			iconArray[label.ID].y = (label.y - 10) + label.height/2 - iconArray[label.ID].height/2;
			iconArray[label.ID].x = label.x;
		}

		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		grpStars.members[curSelected].visible = Highscore.getFullCombo(songs[curSelected].songName, curDifficulty);

		lastDifficultyName = Difficulty.getString(curDifficulty);

		//uppercase first letter of each word
		var diffDisplay:String = "";
		var splitWords = lastDifficultyName.split(" ");
		for (i => word in splitWords)
		{
			diffDisplay += word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
			if (i < splitWords.length-1)
				diffDisplay += " ";
		}
		
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + diffDisplay + ' >';
		else
			diffText.text = diffDisplay;

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		if (curSelected > selectedMax)
			selectedScroll = curSelected - 3;
		if (curSelected < selectedScroll) 
			selectedScroll = curSelected;
		selectedMax = selectedScroll + 3;

		// selector.y = (70 * curSelected) + 30;
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			FlxG.sound.music.loopTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_START_TIME;
			FlxG.sound.music.endTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_END_TIME;
		}
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var weekLabel:String = "";
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var port:String = "";
	public var locked:Bool = false;

	public function new(song:String, week:Int, weekName:String, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
		switch(weekName){
			case 'wiikwhitegloves': this.weekLabel = 'whitegloves';
			case 'fridaynightfisticuffs': this.weekLabel = 'fisticuffs';
			case 'wiikdlc': this.weekLabel = 'freeplay';
			default: this.weekLabel = weekName == '' ?'freeplay':weekName;
		}
		if (!Paths.fileExists("images/freeplay/labels/"+weekLabel+".png", IMAGE)) weekLabel = "freeplay";

		switch(weekName){
			case 'wiikwhitegloves': 
				port = 'wg';
			case 'fridaynightfisticuffs': 
				port = 'fisticuffs';
			case 'wiik1':
				port = "wiik1";
			case 'wiik2':
				port = "wiik2";
			case 'wiikz':
				port = "wiikz";
		}

		switch(Paths.formatToSongPath(song)) {
			case "basket-match": port = "hex";
			case "sussy-qussy": port = "impostor";
			case "battlefield": port = "battlefield";
			case "swap": port = "swap";
			case "mii-funkin": port = "miifunkin";
			case "fired-up": port = "fired-up";
			case "miisacre": port = "miisacre";
			case "paper-cut": port = "sketchy";
			case "lazulii": port = "lazulii";
			case "illusion": port = "illusion";
			case "heavenfall": port = "heavenfall";
			case "long-awaited": port = "long-awaited";
			case "revolution": port = "revol";
			case "3hot": port = "3hot";
			case "4hot": port = "4hot";
			case "snacks": port = "shaggy";
			case "motion-control": port = "eteled";
			case "destiny": port = "correrioptahsjdfklasdf";
			case "funkadelic" | "broadcasting": port = "nikku";
			case "foulplay": port = "foul";
			case "god-mode": port = "godmode";
			case "boxing-match-wg": port = "bmwg";
			case "funkin-corner": port = "corner";
		}
	}
}
