package options;

import objects.WiiCustomText;

class FirstTimeOptionsState extends MusicBeatState
{
	public static var menuBG:FlxSprite;

    var curIndex:Int = 0;
    var substateNeedsOpening = true;
	function loadOptionSubstate() {
		switch(curIndex) {
            case 0:
                var substate = new WiiOptionSelectSubstate("Controls", ["WASD / Arrow Keys", "DFJK", "Custom"], "WASD / Arrow Keys", function(optionName)
                {
                    switch(optionName) {
                        case "WASD / Arrow Keys":
                            ClientPrefs.keyBinds.set("note_up", [W, UP]);
                            ClientPrefs.keyBinds.set("note_left", [A, LEFT]);
                            ClientPrefs.keyBinds.set("note_down", [S, DOWN]);
                            ClientPrefs.keyBinds.set("note_right", [D, RIGHT]);
                            curIndex++;
                            substateNeedsOpening = true;
                        case "DFJK":
                            ClientPrefs.keyBinds.set("note_up", [J, UP]);
                            ClientPrefs.keyBinds.set("note_left", [D, LEFT]);
                            ClientPrefs.keyBinds.set("note_down", [F, DOWN]);
                            ClientPrefs.keyBinds.set("note_right", [K, RIGHT]);
                            curIndex++;
                            substateNeedsOpening = true;
                        case "Custom":
                            openSubState(new ControlsSubState()); 
                            curIndex++;
                            substateNeedsOpening = true;
                    }
                });
                substate.canCancel = false;
                @:privateAccess
                substate.backButton.x = 10000; //fuck off
	        var warningText = new WiiCustomText(60, 500, FlxG.width, "These controls only work if you have connected a keyboard, if you are using the mobile controls just ignore this and continue", 1, "wii");
                    warningText.scrollFactor.set();
                    warningText.width = warningText.fieldWidth;
                    warningText.screenCenter(X);
                    warningText.alpha = 0; FlxTween.tween(warningText, {alpha: 1}, 0.5);
                    substate.add(warningText);
                    substate.bgs.push(warningText);
                openSubState(substate); 
			case 1:
                var substate = new WiiOptionSelectSubstate("Downscroll", ["On", "Off"], ClientPrefs.data.downScroll ? "On" : "Off", function(optionName)
                {
                    ClientPrefs.data.downScroll = optionName == "On";
                    curIndex++;
                    substateNeedsOpening = true;
                }, function() {
                    curIndex--;
                    substateNeedsOpening = true;
                });
                @:privateAccess {
                    substate.backButton.text.text = "Back";
                    substate.backButton.text.width = substate.backButton.text.fieldWidth;
                }

                openSubState(substate);
            case 2:
                var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
                if(!noteSkins.contains(ClientPrefs.data.noteSkin))
                    ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

                noteSkins.insert(0, ClientPrefs.defaultData.noteSkin);

                var substate = new WiiOptionSelectSubstate("Note Skins", noteSkins, ClientPrefs.data.noteSkin, function(optionName)
                {
                    ClientPrefs.data.noteSkin = optionName;
                    curIndex++;
                    substateNeedsOpening = true;
                }, function() {
                    curIndex--;
                    substateNeedsOpening = true;
                });
                @:privateAccess {
                    substate.backButton.text.text = "Back";
                    substate.backButton.text.width = substate.backButton.text.fieldWidth;
                }
                openSubState(substate);
            case 3:
                var substate = new WiiOptionSelectSubstate("Ghost Tapping", ["On", "Off"], ClientPrefs.data.ghostTapping ? "On" : "Off", function(optionName)
                    {
                        ClientPrefs.data.ghostTapping = optionName == "On";
                        curIndex++;
                        substateNeedsOpening = true;
                    }, function() {
                        curIndex--;
                        substateNeedsOpening = true;
                    });
                    @:privateAccess {
                        substate.backButton.text.text = "Back";
                        substate.backButton.text.width = substate.backButton.text.fieldWidth;
                    }
                    openSubState(substate);
            case 4:
                var substate = new WiiOptionSelectSubstate("Flashing Lights", ["On", "Off"], ClientPrefs.data.flashing ? "On" : "Off", function(optionName)
                {
                    ClientPrefs.data.flashing = optionName == "On";
                    curIndex++;
                    substateNeedsOpening = true;
                }, function() {
                    curIndex--;
                    substateNeedsOpening = true;
                });
                @:privateAccess {
                    substate.backButton.text.text = "Back";
                    substate.backButton.text.width = substate.backButton.text.fieldWidth;
                }
                openSubState(substate);
            case 5:
                var substate = new WiiOptionSelectSubstate("Shaders / Modcharts", ["On", "Off"], ClientPrefs.data.shaders ? "On" : "Off", function(optionName)
                {
                    ClientPrefs.data.shaders = optionName == "On";
                    curIndex++;
                    substateNeedsOpening = true;
                }, function() {
                    curIndex--;
                    substateNeedsOpening = true;
                });
                @:privateAccess {
                    @:privateAccess {
                        substate.backButton.text.text = "Back";
                        substate.backButton.text.width = substate.backButton.text.fieldWidth;
                    }

                    var warningText = new WiiCustomText(60, 400, FlxG.width, "Recommended to disable if sensitive to flashing lights! (or if your phone sucks)", 1, "wii");
                    warningText.scrollFactor.set();
                    warningText.width = warningText.fieldWidth;
                    warningText.screenCenter(X);
                    warningText.alpha = 0; FlxTween.tween(warningText, {alpha: 1}, 0.5);
                    substate.add(warningText);
                    substate.bgs.push(warningText);
                }
               
                openSubState(substate);
	    case 6:
                var substate = new WiiOptionSelectSubstate("Hide Hitbox Hints", ["On", "Off"], ClientPrefs.data.hideHitboxHints ? "On" : "Off", function(optionName)
                {
                    ClientPrefs.data.hideHitboxHints = optionName == "On";
                    curIndex++;
                    substateNeedsOpening = true;
                }, function() {
                    curIndex--;
                    substateNeedsOpening = true;
                });
                @:privateAccess {
                    @:privateAccess {
                        substate.backButton.text.text = "Back";
                        substate.backButton.text.width = substate.backButton.text.fieldWidth;
                    }

                    var warningText = new WiiCustomText(60, 400, FlxG.width, "If checked, makes the hitbox hints invisible.", 1, "wii");
                    warningText.scrollFactor.set();
                    warningText.width = warningText.fieldWidth;
                    warningText.screenCenter(X);
                    warningText.alpha = 0; FlxTween.tween(warningText, {alpha: 1}, 0.5);
                    substate.add(warningText);
                    substate.bgs.push(warningText);
		}
                openSubState(substate);
            default:
                exit();
		}
	}

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		for (i in ['optionsBG', 'optionsBorder', 'optionsVERSION'])
		{
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('wiimenu/options/'+i));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.updateHitbox();
			bg.screenCenter();
			add(bg);
			bg.alpha = 0; FlxTween.tween(bg, {alpha: 1}, 1.0);
		}

		var titleText = new WiiCustomText(60, 50, 0, "Wii Funkin' Options", 2, 'wii');
		titleText.alignment = 'left';
		titleText.color = 0xFF000000;
		titleText.regenText(true);
		titleText.scrollFactor.set();
		titleText.alpha = 0; FlxTween.tween(titleText, {alpha: 1}, 0.5);
		add(titleText);

		FlxG.mouse.visible = true;
		allowMouseControlWithKeys = true;

		//changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

        if (substateNeedsOpening) {
            loadOptionSubstate();
            substateNeedsOpening = false;
        }
	}

    function exit() {
        ClientPrefs.saveSettings();
        LoadingState.loadAndSwitchState(new PlayState());
    }

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
