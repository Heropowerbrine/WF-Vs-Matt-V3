package cutscenes;

import objects.WiiCustomText;
import flixel.addons.text.FlxTypeText;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';

	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;

	var actualText:WiiCustomText;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		/*bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);*/

		box = new FlxSprite(-20, 340);
		
		var hasDialog = true;
		switch (PlayState.SONG.song.toLowerCase())
		{
			default:

				//864
				//hasDialog = false;
				
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog)
			return;

		box.loadGraphic(Paths.image("wiidialogue/dialoguebox"));
		box.updateHitbox();
		box.screenCenter(X);
		add(box);
		
		portraitLeft = new FlxSprite(box.x + (864*box.scale.x), box.y);
		portraitLeft.loadGraphic(Paths.image("wiidialogue/dialogueMatt"));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(box.x + (864*box.scale.x), box.y);
		portraitRight.loadGraphic(Paths.image("wiidialogue/dialogueBF"));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		add(portraitRight);
		portraitRight.visible = false;
		
		handSelect = new FlxSprite(1042, 590).loadGraphic(Paths.image('pointer'));
		//handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.visible = false;
		//add(handSelect);

		swagDialogue = new DialogueTypeText(box.x + 64, box.y + 120, 1024, "", 48);
		swagDialogue.color = 0xFF000000;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('text'), 1.0),
		];
		add(swagDialogue);
		swagDialogue.visible = false;

		actualText = new WiiCustomText(box.x + 64, box.y + 120, 1200, "", 2, 'wii');
		actualText.color = 0xFF000000;
		actualText.alignment = 'left';
		add(actualText);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	override function update(elapsed:Float)
	{
		dialogueOpened = true;
		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		var justTouched:Bool = false;
 		for (touch in FlxG.touches.list)
 			if (touch.justPressed)
 				justTouched = true;
 
 		if(Controls.instance.ACCEPT || justTouched)
		{
			if (dialogueEnded)
			{
				if (dialogueList[1] == null && dialogueList[0] != null)
				{
					if (!isEnding)
					{
						isEnding = true;
						FlxG.sound.play(Paths.sound('wiiSelect'), 0.8);	

						if (PlayState.SONG.song.toLowerCase() == 'senpai' || PlayState.SONG.song.toLowerCase() == 'thorns')
							FlxG.sound.music.fadeOut(1.5, 0);

						FlxTween.tween(box, {alpha: 0}, 1);
						FlxTween.tween(portraitLeft, {alpha: 0}, 1);
						FlxTween.tween(portraitRight, {alpha: 0}, 1);
						FlxTween.tween(swagDialogue, {alpha: 0}, 1);
						FlxTween.tween(actualText, {alpha: 0}, 1);
						FlxTween.tween(handSelect, {alpha: 0}, 1);

						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							finishThing();
							kill();
						});
					}
				}
				else
				{
					dialogueList.remove(dialogueList[0]);
					startDialogue();
					FlxG.sound.play(Paths.sound('wiiSelect'), 0.8);
				}
			}
			else if (dialogueStarted)
			{
				FlxG.sound.play(Paths.sound('wiiSelect'), 0.8);
				swagDialogue.skip();
				
				if(skipDialogueThing != null) {
					skipDialogueThing();
				}
			}
		}
		
		super.update(elapsed);

		actualText.text = swagDialogue.text;
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();
		// var theDialog:Alphabet = new Alphabet(0, 70, dialogueList[0], false, true);
		// dialogue = theDialog;
		// add(theDialog);

		// swagDialogue.text = ;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);
		swagDialogue.completeCallback = function() {
			handSelect.visible = true;
			dialogueEnded = true;
		};

		handSelect.visible = false;
		dialogueEnded = false;
		switch (curCharacter)
		{
			case 'dad':
				portraitRight.visible = false;
				portraitLeft.visible = true;
			case 'bf':
				portraitLeft.visible = false;
				portraitRight.visible = true;
		}
		if(nextDialogueThing != null) {
			nextDialogueThing();
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}


class DialogueTypeText extends FlxTypeText {
	override public function update(elapsed:Float):Void
	{
		// If the skip key was pressed, complete the animation.
		#if FLX_KEYBOARD
		if (skipKeys != null && skipKeys.length > 0 && FlxG.keys.anyJustPressed(skipKeys))
		{
			skip();
		}
		#end

		if (_waiting && !paused)
		{
			_waitTimer -= elapsed;

			if (_waitTimer <= 0)
			{
				_waiting = false;
				_erasing = true;
			}
		}

		// So long as we should be animating, increment the timer by time elapsed.
		if (!_waiting && !paused)
		{
			if (_length < _finalText.length && _typing)
			{
				_timer += elapsed;
			}

			if (_length > 0 && _erasing)
			{
				_timer += elapsed;
			}
		}

		// If the timer value is higher than the rate at which we should be changing letters, increase or decrease desired string length.

		if (_typing || _erasing)
		{
			if (_typing && _timer >= delay)
			{
				_length += Std.int(_timer / delay);
				if (_length > _finalText.length)
					_length = _finalText.length;
			}

			if (_erasing && _timer >= eraseDelay)
			{
				_length -= Std.int(_timer / eraseDelay);
				if (_length < 0)
					_length = 0;
			}

			if ((_typing && _timer >= delay) || (_erasing && _timer >= eraseDelay))
			{
				if (_typingVariation)
				{
					if (_typing)
					{
						_timer = FlxG.random.float(-delay * _typeVarPercent / 2, delay * _typeVarPercent / 2);
					}
					else
					{
						_timer = FlxG.random.float(-eraseDelay * _typeVarPercent / 2, eraseDelay * _typeVarPercent / 2);
					}
				}
				else
				{
					_timer %= delay;
				}

				if (sounds != null && !useDefaultSound)
				{
					
				}
				else if (useDefaultSound)
				{
					_sound.play(!finishSounds);
				}
			}
		}

		// Update the helper string with what could potentially be the new text.
		FlxTypeText.helperString = prefix + _finalText.substr(0, _length);

		// Append the cursor if needed.
		if (showCursor)
		{
			_cursorTimer += elapsed;

			// Prevent word wrapping because of cursor
			var isBreakLine = (prefix + _finalText).charAt(FlxTypeText.helperString.length) == "\n";

			if (_cursorTimer > cursorBlinkSpeed / 2 && !isBreakLine)
			{
				FlxTypeText.helperString += cursorCharacter.charAt(0);
			}

			if (_cursorTimer > cursorBlinkSpeed)
			{
				_cursorTimer = 0;
			}
		}

		// If the text changed, update it.
		if (FlxTypeText.helperString != text)
		{
			text = FlxTypeText.helperString;

			if (text.charAt(text.length-1) != " ") {
				for (sound in sounds)
				{
					if (sound.playing) sound.stop();
				}
				sounds[text.length%sounds.length].play(true);
			}

			// If we're done typing, call the onComplete() function
			if (_length >= _finalText.length && _typing && !_waiting && !_erasing)
			{
				onComplete();
			}

			// If we're done erasing, call the onErased() function
			if (_length == 0 && _erasing && !_typing && !_waiting)
			{
				onErased();
			}
		}

		//super.update(elapsed);
	}
}
