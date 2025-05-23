package backend;

import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	#if mobile
 	var _virtualpad:FlxVirtualPad;
 
 	public function addVirtualPad(?DPad:FlxDPadMode, ?Action:FlxActionMode) {
 		_virtualpad = new FlxVirtualPad(DPad, Action);
 		add(_virtualpad);
 	}
 
     public function addVPadCam() {
 		var virtualpadcam = new flixel.FlxCamera();
 		virtualpadcam.bgColor.alpha = 0;
 		FlxG.cameras.add(virtualpadcam, false);
 		_virtualpad.cameras = [virtualpadcam];
     }
 
 	public function removeVirtualPad() {
 		remove(_virtualpad);
 	}
 	public function closeSs() {
 		FlxTransitionableState.skipNextTransOut = true;
 		FlxG.resetState();
 	}
 	#end

	inline function get_controls():Controls
		return Controls.instance;

	public var allowMouseControlWithKeys = false;

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (allowMouseControlWithKeys)
		{
			var x:Float = 0.0;
			if (controls.UI_LEFT) x += -1;
			if (controls.UI_RIGHT) x += 1;
			var y:Float = 0.0;
			if (controls.UI_UP) y += -1;
			if (controls.UI_DOWN) y += 1;
	
			if (x != 0.0 || y != 0.0)
				moveCursor(x, y);
		}

		if (FlxG.mouse.justMoved) {
			FlxG.mouse.visible = true;
			MusicBeatState.mouseHideTimer = 5;
		}
		if (MusicBeatState.mouseHideTimer > 0) {
			MusicBeatState.mouseHideTimer -= elapsed;
			if (MusicBeatState.mouseHideTimer <= 0) {
				FlxG.mouse.visible = false;
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	function moveCursor(dirX:Float = 0, dirY:Float = 0)
	{
		var newX = FlxG.stage.mouseX + (1280 * dirX * FlxG.elapsed);
		var newY = FlxG.stage.mouseY + (1280 * dirY * FlxG.elapsed);
		#if desktop
		lime.app.Application.current.window.warpMouse(Std.int(newX), Std.int(newY));
		#end
	}
}
