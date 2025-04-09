// 
package states;

import flixel.input.keyboard.FlxKey;
import backend.Song;
import flixel.addons.transition.FlxTransitionableState;
import backend.WeekData;
import backend.Highscore;

class HealthNSafety extends MusicBeatState
{
	public static var leftState:Bool = false;
	public static var canLeave:Bool = false;

	var enterAlpha:Float = 0;

	var warnText:FlxSprite;
	var pressText:FlxSprite;

	var blackScreen:FlxSprite;

	public static var unlock:Bool = false;
	
	override function create()
	{
		warnText = new FlxSprite().loadGraphic(Paths.image('warning/warning'));
		warnText.screenCenter();
		warnText.antialiasing = ClientPrefs.data.antialiasing;

		pressText = new FlxSprite().loadGraphic(Paths.image('warning/enter'));
		pressText.screenCenter();
		pressText.antialiasing = ClientPrefs.data.antialiasing;

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);

		new FlxTimer().start(5, function(tmr:FlxTimer) {
			canLeave = true;
		});

		FlxTween.tween(blackScreen, {alpha: 0}, 1);

		add(pressText);
		add(warnText);
		add(blackScreen);

		WeekData.reloadWeekFiles(true);

	}

	var unlockInputs:Array<FlxKey> = [UP, UP, DOWN, DOWN, LEFT, RIGHT, LEFT, RIGHT, B, A, ENTER];
	var lastInputs:Array<FlxKey> = [];

	override function update(elapsed:Float)
	{
		var justTouched:Bool = false;
 
 		#if mobile
                 for (touch in FlxG.touches.list)
 	                if (touch.justPressed)
 		                justTouched = true;
 		#end
			
		if(canLeave) enterAlpha += elapsed;
		pressText.alpha = (Math.sin((enterAlpha-0.6)/0.5)/1.9) + 0.46;

		var enter = FlxG.keys.justPressed.ENTER;

		var key = FlxG.keys.firstJustPressed();
		if (key != -1) {
			if (key == unlockInputs[lastInputs.length]) {
				lastInputs.push(key);

				if (lastInputs.length == unlockInputs.length) unlock = true;
			} else {
				lastInputs = [];
			}
		}

		if(!leftState) {
			if (enter || justTouched) {
				leftState = true;
				canLeave = true;
				FlxTransitionableState.skipNextTransIn = true;

				FlxG.sound.play(Paths.sound('enterClick'));
				FlxTween.tween(blackScreen, {alpha: 1}, 2, {
					onComplete: function (twn:FlxTween) {
						if (!loadWeek("captcha")) {
							LoadingState.loadAndSwitchState(new MainMenuState());
						}
					}
				});
				
			}
		}
		super.update(elapsed);
	}

	function loadWeek(name:String)
	{
		if (HealthNSafety.unlock) return false;

		var leWeek = WeekData.weeksLoaded[name];
		trace(WeekData.weeksLoaded);
		if (leWeek == null) return false;

		WeekData.setDirectoryFromWeek(leWeek);
		PlayState.storyWeek = WeekData.weeksList.indexOf(name);
		Difficulty.loadFromWeek();

		var intendedScore = Highscore.getWeekScore(leWeek.fileName, 0);
		if (intendedScore != 0) return false; //already completed week

		var songArray:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			songArray.push(leWeek.songs[i][0]);
		}

		PlayState.storyPlaylist = songArray;
		PlayState.isStoryMode = true;
		PlayState.storySongNum = 0;

		var diffic = Difficulty.getFilePath(0);
		if(diffic == null) diffic = '';
		PlayState.storyDifficulty = 0;

		ClientPrefs.data.gameplaySettings.set("botplay", false);
		ClientPrefs.data.gameplaySettings.set("practice", false);

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
		PlayState.campaignScore = 0;
		PlayState.campaignMisses = 0;
		LoadingState.loadAndSwitchState(new options.FirstTimeOptionsState());
		return true;
	}
}
