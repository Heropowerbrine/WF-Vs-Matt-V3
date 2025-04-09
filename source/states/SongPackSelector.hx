package states;

import objects.WiiCustomText;
import backend.Song;

class SongPackSelector extends MusicBeatState
{

	var covers:FlxTypedGroup<FlxSprite>;
	var packs:Array<String> = ["StoryMode", "Bonus", "DLC"];
	var wiikPacks:Array<Dynamic> = [
		["wiik1", "wiik2", "wiikz", "wiikwhitegloves", "fridaynightfisticuffs"],
		["wiikbonus", "stupidalts", "shaggystuff", "shaggyremixes"],
		['']
	];
	var wiikPackPortraits:Array<Dynamic> = [
		["wiik1", "wiik2", "wiikz", /*"whitegloves",*/ "fisticuffs", "impostor", 'sketchy', "nikku", "wg", "bmwg", "hex"],
		["godmode", "foul", "nikku","swap", "miifunkin", "battlefield", "fired-up", "miisacre", "lazulii", "illusion", "heavenfall", "long-awaited", "revol", "corner", "3hot", "4hot", "shaggy", "correrioptahsjdfklasdf", "eteled"],
		[]
	];

	override function create()
	{
		FlxG.mouse.visible = true;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/bg'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		var question:WiiCustomText = new WiiCustomText(0, 60, FlxG.width, "Which songs would you like to play?", 2, "wii");
		question.width = question.fieldWidth;
		question.screenCenter(X);
		add(question);

		covers = new FlxTypedGroup<FlxSprite>();
		add(covers);

		for (pack in packs)
		{
			var cover = new FlxSprite().loadGraphic(Paths.image('freeplay/covers/$pack'));
			cover.scale.set(0.5, 0.5);
			cover.updateHitbox();
			cover.screenCenter();
			cover.x += 350 * (covers.length - 1);
			cover.antialiasing = ClientPrefs.data.antialiasing;
			cover.ID = covers.length;
			covers.add(cover);

		}

		var branding:WiiCustomText = new WiiCustomText(0, 620, FlxG.width, "2025 Matt Team", 1, "wii"); //damm the copyright char isnt in the font
		branding.width = branding.fieldWidth;
		branding.screenCenter(X);
		add(branding);

		allowMouseControlWithKeys = true;

		super.create();
	}
	var t:Int = 0;
	var leavingState = false;
	override function update(elapsed:Float)
	{	
		if (!leavingState)
		{
			if (controls.BACK || FlxG.android.justReleased.BACK)
			{
				leavingState = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			for (cover in covers.members)
			{
				if (cover.ID != 2) //NO DLC FOR YOU
				{
					//this doesnt work with gpu sprites
					//var overlap = cover.pixelsOverlapPoint(FlxG.mouse.getPositionInCameraView(), 0xFF);
					var overlap = FlxG.mouse.overlaps(cover);
					cover.scale.y = cover.scale.x = FlxMath.lerp(cover.scale.x, overlap?0.52:0.5, 15*elapsed);
					if ((FlxG.mouse.justPressed || controls.ACCEPT) && overlap){
						leavingState = true;
						FreeplayState.selectedPackName = packs[cover.ID];
						FreeplayState.selectedPack = wiikPacks[cover.ID];
						FreeplayState.selectedPorts = wiikPackPortraits[cover.ID];
						MusicBeatState.switchState(new FreeplayState());
					}
				} else {
					var overlap = FlxG.mouse.overlaps(cover);
					if ((FlxG.mouse.justPressed || controls.ACCEPT) && overlap){
						t++;
						if (t >= 15) {
							backend.Difficulty.resetList();
							PlayState.SONG = Song.loadFromJson('funkin-corner-hard', 'funkin-corner');
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = 2;
							LoadingState.loadAndSwitchState(new PlayState());
						}
					}
				}
			}
		}
		super.update(elapsed);
	}
}
