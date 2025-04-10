package states;

import objects.WiiCustomText;
import flixel.system.FlxAssets.FlxShader;
import backend.Highscore;
import options.WiiOption;
import backend.WeekData;
import flixel.math.FlxRect;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import backend.Song;
import backend.Controls;
import backend.MusicBeatSubstate;
#if desktop
import lime.app.Application;
#end

class StarChecker {
	public static function checkStar1() {
		return Highscore.getWeekCompletion("1wiik1") && Highscore.getWeekCompletion("2wiik2");
	}
	public static function checkStar2() {
		return Highscore.getWeekCompletion("3wiikZ");
	}
	public static function checkStar3() {
		return Highscore.getWeekCompletion("4wiikFisticuffs");
	}
	public static function checkStar4() {

		//trace(Highscore.songScores);
		//trace(Highscore.weekScores);

		for (song in ["3hot", "4hot", "foulplay", "revolution", "swap", "mii-funkin", "snacks", "long-awaited", "fired-up", "battlefield", "motion-control", "destiny", "god-mode", "miisacre", "broadcasting", "lazulii", "illusion", "heavenfall"]) {
			if (!Highscore.getCompletion(song)) {
				return false;
			}
		}
		
		return true;
	}
	public static function checkStar5() {
		return Highscore.getWeekCompletion("5wiikWG");
	}

	public static function getUnlockedArray() {
		return [checkStar1(), checkStar2(), checkStar5(), checkStar4(), checkStar3()];
	}
}

class StaticOverlayShader extends FlxShader {
	@:glFragmentSource('
		#pragma header

		uniform float iTime;

		//https://www.shadertoy.com/view/3d3fR7
		//best noise func i could find
		float noise(vec2 pos, float evolve) {
    
			// Loop the evolution (over a very long period of time).
			float e = fract((evolve*0.01));
			
			// Coordinates
			float cx  = pos.x*e;
			float cy  = pos.y*e;
			
			// Generate a "random" black or white value
			return fract(23.0*fract(2.0/fract(fract(cx*2.4/cy*23.0+pow(abs(cy/22.4),3.3))*fract(cx*evolve/pow(abs(cy),0.050)))));
		}

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec2 pixel = openfl_TextureCoordv * openfl_TextureSize;
			float n = noise( vec2(floor(pixel.x)+10.0, floor(pixel.y)+10.0), iTime + 30.0);
			gl_FragColor = mix(color, vec4(n, n, n, color.a)*color.a, 0.2);
		}')
	public function new()
	{
		super();
	}
}

class MainMenuState extends MusicBeatState
{
	public static final MAIN_MENU_MUSIC_LOOP_START_TIME:Float = 167185;
	public static final MAIN_MENU_MUSIC_LOOP_END_TIME:Float = 297670;
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	public static var instance:MainMenuState = null;
	private static var firstLoad:Bool = true;

	public var menuItems:FlxTypedGroup<MainMenuOption>;
	public var menuTexts:FlxTypedGroup<FlxSprite>;

	var optionsGrid:Array<Dynamic> = [
		["wiik1", "wiik2", "wiikz", "fisticuffs"],
		["whitegloves", "freeplay", "credits", ""],
		["", "", "", ""]
	];

	var optionsText:Array<Dynamic> = [
		["Wiik 1", "Wiik 2", "Wiik Z", "Fisticuffs"],
		["White Gloves", "Freeplay", "Credits", ""],
		["", "", "", ""]
	];

	var xPos = [99, 373, 646, 919]; //stupid shit cuz its slightly off
	var yPos = [60, 212, 365];

	public var camFollow:FlxObject;
	public var whiteFades:Array<FlxSprite> = [];

	var staticShaders:Array<StaticOverlayShader> = [];
	var iTime:Float = 0;

	var bg:FlxSprite;
	var bgITime:Float = 0;

	var messages:MainMenuOption;
	var messageCount:MainMenuOption;
	var meesageNotif:LetterNotif;
	public function reloadMessagesButton() {

		if (messages != null) {
			messages.enabled = false;
			menuItems.remove(messages, true);
			MainMenuState.instance.menuTexts.remove(messages.hoverBG);
			MainMenuState.instance.menuTexts.remove(messages.hoverText);
			messages.destroy();
		}
		if (messageCount != null) {
			messages.enabled = false;
			menuItems.remove(messageCount, true);
			messageCount.destroy();
		}

		if (meesageNotif != null) {
			meesageNotif.visible = false;
			remove(meesageNotif);
			meesageNotif.destroy();
		}

		var unreadLetters = WiiMessageBoardSubstate.getUnreadLetters();

		messages = new MainMenuOption(1088, 536, false);
		messages.loadGraphic(Paths.image(unreadLetters.length == 0 ? 'wiimenu/menu_messages' : 'wiimenu/menu_messagesNew'));
		messages.antialiasing = ClientPrefs.data.antialiasing;
		messages.name = "messages";
		messages.scale.set(0.9, 0.9);
		messages.onClick = function()
		{
			persistentUpdate = false;
			openSubState(new WiiMessageBoardSubstate());
		}
		messages.setupHoverText("Messages", -80, -60, 200);
		menuItems.add(messages);

		if (unreadLetters.length > 0) {
			messageCount = new MainMenuOption(1088, 536, false);
			messageCount.loadGraphic(Paths.image('wiimenu/messages/messages'+unreadLetters.length));
			messageCount.antialiasing = ClientPrefs.data.antialiasing;
			messageCount.name = "messageCount";
			messageCount.scale.set(0.9, 0.9);
			messageCount.playsMouseHoverSound = false;
			menuItems.add(messageCount);
		}

		meesageNotif = new LetterNotif(messages);
		meesageNotif.visible = unreadLetters.length > 0;
		add(meesageNotif);
	}

	override function create()
	{
		instance = this;
		
		FlxG.mouse.visible = true;
		
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end



		//trace();

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('wiimenu/bg'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(FlxG.width);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		/*var staticChannels:FlxSprite = new FlxSprite(0, 0);
		staticChannels.frames = Paths.getSparrowAtlas('wiimenu/Static Channels/staticchannels');
		staticChannels.antialiasing = ClientPrefs.data.antialiasing;
		staticChannels.animation.addByPrefix("static", "static", 24);
		staticChannels.animation.play("static");
		staticChannels.updateHitbox();
		staticChannels.screenCenter();
		add(staticChannels);*/

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		camFollow.screenCenter();

		menuItems = new FlxTypedGroup<MainMenuOption>();
		add(menuItems);
		
		menuTexts = new FlxTypedGroup<FlxSprite>();
		
		PlayState.storyWeek = 0;
		Difficulty.loadFromWeek();

		//seperate sprites will make things easier
		for (i in 0...4)
		{
			for (j in 0...3)
			{
				var outline = new FlxSprite(xPos[i], yPos[j]).loadGraphic(Paths.image('wiimenu/outline'));
				outline.antialiasing = ClientPrefs.data.antialiasing;
				add(outline);

				if (optionsGrid[j][i] != null && optionsGrid[j][i] != "")
				{
					var locked = false;
					switch(optionsGrid[j][i]) {
						case "wiik2" | "freeplay":
							if (!Highscore.getWeekCompletion("1wiik1")) locked = true;
						case "wiikz":
							if (!Highscore.getWeekCompletion("2wiik2")) locked = true;
						case "fisticuffs":
							if (!Highscore.getWeekCompletion("3wiikZ")) locked = true;
						case "whitegloves":
							if (StarChecker.checkStar1() && StarChecker.checkStar2() && StarChecker.checkStar3() && StarChecker.checkStar4()) {
							} else {
								locked = true;
							}
					}
					if (HealthNSafety.unlock) locked = false;
					var option = new MainMenuOption(outline.x, outline.y);
					option.enabled = !locked;
					option.loadGraphic(Paths.image('wiimenu/menu_' + (locked ? "locked" : optionsGrid[j][i])));
					option.antialiasing = ClientPrefs.data.antialiasing;
					option.name = optionsGrid[j][i];
					option.onClick = function()
					{
						persistentUpdate = false;
						openSubState(new WiiChannelSubstate(option));
					}
					menuItems.add(option);
					add(option.outlineFade);
					option.outlineFade.x = option.x + (option.width*0.5) - (option.outlineFade.width*0.5);
					option.outlineFade.y = option.y + (option.height*0.5) - (option.outlineFade.height*0.5);

					if (locked) {
						var shader = new StaticOverlayShader();
						option.shader = shader;
						staticShaders.push(shader);
					}

					option.setupHoverText(optionsText[j][i], 10, 155, 260);
				} else {
					var option = new MainMenuOption(outline.x, outline.y);
					option.loadGraphic(Paths.image('wiimenu/menu_null'));
					option.antialiasing = ClientPrefs.data.antialiasing;
					var shader = new StaticOverlayShader();
					option.shader = shader;
					staticShaders.push(shader);
					add(option);
				}
			}
		}

		var settings = new MainMenuOption(40, 536, false);
		settings.loadGraphic(Paths.image('wiimenu/menu_options'));
		settings.antialiasing = ClientPrefs.data.antialiasing;
		settings.name = "options";
		settings.scale.set(0.9, 0.9);
		settings.onClick = function()
		{
			MusicBeatState.switchState(new OptionsState());
			OptionsState.onPlayState = false;
			if (PlayState.SONG != null)
			{
				PlayState.SONG.arrowSkin = null;
				PlayState.SONG.splashSkin = null;
				PlayState.stageUI = 'normal';
			}
		}
		settings.setupHoverText("Settings", 25, -60, 200);
		menuItems.add(settings);

		reloadMessagesButton();

		var starsUnlocked = StarChecker.getUnlockedArray();
		var starOffsetX:Array<Float> = [2,79,168,276,364];
		var starOffsetY:Array<Float> = [39,25,2,24,40];
		var starInfos:Array<String> = [
			"Unlocked after beating Wiik 1 and 2",
			"Unlocked after beating Wiik Z",
			"Unlocked after beating White Gloves Wiik",
			"Unlocked after beating all Freeplay Songs",
			"Unlocked after beating Fisticuffs Wiik"
		];
		var starHoverOffsets:Array<Float> = [-250, -200, -300, -300, -250];
		for (i in 0...starsUnlocked.length) {
			var star = new MainMenuOption(415 + starOffsetX[i], 544 + starOffsetY[i], false);
			star.antialiasing = ClientPrefs.data.antialiasing;
			star.name = "star"+i;
			star.loadGraphic(Paths.image("wiimenu/star"+i));
			star.color = starsUnlocked[i] ? 0xFFFFFFFF : 0xFF2F2F2F;
			star.unselectedScale = 1.0;
			star.selectedScale = 1.1;
			menuItems.add(star);
			star.setupHoverText(starInfos[i], starHoverOffsets[i], -60, 0);
		}

		add(menuTexts);

		#if ACHIEVEMENTS_ALLOWED

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();

		if(FlxG.sound.music == null) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.loopTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_START_TIME;
			FlxG.sound.music.endTime = states.MainMenuState.MAIN_MENU_MUSIC_LOOP_END_TIME;
		}

		FlxG.camera.minScrollX = 0;
		FlxG.camera.minScrollY = 0;
		FlxG.camera.maxScrollX = FlxG.camera.width;
		FlxG.camera.maxScrollY = FlxG.camera.height;

		for (i in 0...4)
		{
			var bg = new FlxSprite();
			bg.makeGraphic(1,1,0xFFFFFFFF);
			bg.setGraphicSize(1280,720);
			bg.updateHitbox();
			bg.alpha = 0;
			add(bg);
			whiteFades.push(bg);
		}

		//FlxG.camera.follow(camFollow, null, 9);
		//FlxG.camera.deadzone = new FlxRect(0, 0, 1280, 720);

		allowMouseControlWithKeys = true;

		if (firstLoad) {
			firstLoad = false;
			FlxG.camera.flash(FlxColor.BLACK, 1);
		}

		if (Highscore.getWeekCompletion("3wiikZ")) {
			if (FlxG.save.data.seenBreakPopup == null || !FlxG.save.data.seenBreakPopup) {
				FlxG.save.data.seenBreakPopup = true;
				FlxG.save.flush();

				persistentUpdate = false;
				openSubState(new BreakPopupSubstate());
			}
		}

		//persistentUpdate = false;
		//openSubState(new TextTest());
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{


		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		iTime += elapsed;
		for (i in 0...staticShaders.length) {
			var time = Math.floor(iTime * 24) % 24;
			staticShaders[i].iTime.value = [time + i];
		}
		bgITime += elapsed * FlxG.random.float(0.5, 1.5);
		bg.alpha = 0.75 + (Math.cos(bgITime*2)*0.25);

		if (!selectedSomethin)
		{
			if (controls.BACK)
			{
				//selectedSomethin = true;
				//FlxG.sound.play(Paths.sound('cancelMenu'));
				//MusicBeatState.switchState(new TitleState());
			}

			itemsUpdate();

			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function itemsUpdate()
	{
		for (item in menuItems.members)
		{
			if (item.enabled && FlxG.mouse.overlaps(item))
			{
				if (!item.selected)
				{
					if (item.playsMouseHoverSound) FlxG.sound.play(Paths.sound('wiiOptionHover'));
					item.selected = true;
				}
			}
			else
			{
				item.selected = false;
			}
		}
	}
}

class WiiUIBox extends FlxSprite {
	var left:FlxSprite;
	var center:FlxSprite;
	var right:FlxSprite;
	public function new() {
		super();

		left = new FlxSprite(); center = new FlxSprite(); right = new FlxSprite();
		left.frames = center.frames = right.frames = Paths.getSparrowAtlas("wiimenu/wiiUISlice");
		left.animation.addByPrefix("left", "left"); left.animation.play("left");
		center.animation.addByPrefix("center", "center"); center.animation.play("center");
		right.animation.addByPrefix("right", "right"); right.animation.play("right");
	}
	override public function draw() {
		left.scale.x = right.scale.x = scale.y;
		left.scale.y = center.scale.y = right.scale.y = scale.y;
		left.updateHitbox(); center.updateHitbox(); right.updateHitbox();
		left.y = center.y = right.y = y;
		left.alpha = center.alpha = right.alpha = alpha;

		left.x = x;
		center.x = x + left.width;
		right.x = (x + width) - right.width;

		center.scale.x = right.x - center.x;
		center.updateHitbox();

		left.draw(); center.draw(); right.draw();
	}
	override public function destroy() {
		left.destroy(); center.destroy(); right.destroy();
		super.destroy();
	}
}

private class MainMenuOption extends FlxSprite
{
	public var name:String = "";
	public var onClick:Void->Void;
	public var enabled:Bool = true;
	public var selected:Bool = false;

	public var xIndex:Int = -1;
	public var yIndex:Int = -1;

	public var outlineFade:FlxSprite = null;

	public var hoverBG:FlxSprite = null;
	public var hoverText:WiiCustomText = null;

	private var hasOutline:Bool = false;

	public var hoverTime:Float = 0;
	public var playedHoverSound:Bool = false;

	public var playsMouseHoverSound:Bool = true;

	public function new(X:Float, Y:Float, ?hasOutline:Bool = true)
	{
		super(X, Y, null);
		this.hasOutline = hasOutline;

		if (hasOutline) //box menu option
		{
			outlineFade = new FlxSprite(X, Y);
			outlineFade.loadGraphic(Paths.image("wiimenu/outlineBlue"));
			outlineFade.alpha = 0;
			outlineFade.updateHitbox();
		}
	}

	public function setupHoverText(text:String, xoffset:Float, yoffset:Float, fieldWidth:Float = 0) {
		hoverBG = new WiiUIBox();
		hoverBG.loadGraphic(Paths.image("wiimenu/wiiUISlice"));
		//hoverBG.scale.y = 0.5;
		hoverText = new WiiCustomText(x + xoffset, y + yoffset, fieldWidth, text, 1.5, "wii");
		hoverText.alignment = 'left';
		hoverText.color = 0xFF858585;
		hoverText.regenText(true);

		hoverBG.setGraphicSize(hoverText.width + 50, hoverText.height + 20);
		hoverBG.updateHitbox();

		hoverBG.x = hoverText.x + (hoverText.width/2) - (hoverBG.width/2);
		hoverBG.y = hoverText.y + (hoverText.height/2) - (hoverBG.height/2);
		hoverBG.y -= 5;

		MainMenuState.instance.menuTexts.add(hoverBG);
		MainMenuState.instance.menuTexts.add(hoverText);

		hoverBG.alpha = 0;
		hoverText.alpha = 0;
	}

	public var selectedScale = 1.0;
	public var unselectedScale = 0.9;

	override public function update(elapsed:Float)
	{
		if (selected)
		{
			if (hasOutline)
			{
				outlineFade.scale.x = 1;
				outlineFade.alpha = FlxMath.lerp(outlineFade.alpha, 1, 10*elapsed);	
			}
			else
			{
				scale.y = scale.x = FlxMath.lerp(scale.x, selectedScale, 15*elapsed);
			}
	
			if (FlxG.mouse.justPressed || Controls.instance.ACCEPT) {
				if (onClick != null) onClick();

				hoverTime = 0;
				playedHoverSound = false;
				if (hoverBG != null) {
					hoverBG.alpha = hoverText.alpha = 0;
				}
			}

			hoverTime += elapsed;
			if (hoverTime > 0.5 && hoverBG != null) {
				hoverBG.alpha = hoverText.alpha = FlxMath.lerp(hoverBG.alpha, 1.0, 15*elapsed);
				if (!playedHoverSound) {

					FlxG.sound.play(Paths.sound("wiiHover"));
					playedHoverSound = true;
				}
			}
		}
		else
		{
			hoverTime = 0;
			playedHoverSound = false;
			if (hoverBG != null) {
				hoverBG.alpha = hoverText.alpha = 0;
			}

			if (hasOutline)
			{
				outlineFade.alpha = FlxMath.lerp(outlineFade.alpha, 0, 6*elapsed);	
				outlineFade.scale.x = FlxMath.lerp(outlineFade.scale.x, 0.85, 3*elapsed);	
			}
			else
			{
				scale.y = scale.x = FlxMath.lerp(scale.x, unselectedScale, 15*elapsed);
			}
		}
	}
}

private class WiiChannelSubstate extends MusicBeatSubstate
{
	var option:MainMenuOption;

	var bg:FlxSprite;
	var channelBG:FlxSprite;

	var menuOption:WiiOption;
	var startOption:WiiOption;

	var objects:Array<FlxSprite> = [];
	var canExit:Bool = false;

	override public function new(option:MainMenuOption)
	{
		super();
		this.option = option;
	}

	var targetZoom = 4.0;

	override public function create()
	{
		super.create();

		

		//bgs
		bg = new FlxSprite();
		bg.loadGraphic(Paths.image("wiimenu/channels/" + option.name));
		bg.setGraphicSize(FlxG.width, 0);
		bg.scale.x /= targetZoom;
		bg.scale.y /= targetZoom;
		bg.updateHitbox();
		bg.x = option.x + (option.width*0.5) - (bg.width*0.5);
		bg.y = option.y + (option.height*0.5) - (bg.height*0.5);
		bg.y -= 25;
		bg.antialiasing = ClientPrefs.data.antialiasing;

		add(bg);
		bg.alpha = 0;

		channelBG = new FlxSprite().loadGraphic(Paths.image("wiimenu/channels/channelBorder"));
		channelBG.setGraphicSize(FlxG.width);
		channelBG.scale.x /= targetZoom;
		channelBG.scale.y /= targetZoom;
		channelBG.updateHitbox();
		channelBG.antialiasing = ClientPrefs.data.antialiasing;

		channelBG.x = option.x + (option.width*0.5) - (channelBG.width*0.5);
		channelBG.y = option.y + (option.height*0.5) - (channelBG.height*0.5);

		add(channelBG);
		channelBG.alpha = 0;

		//wii option buttons
		//need to be scaled and shit asdhiads
		menuOption = new WiiOption(0, option.y + (490/targetZoom), "Menu", "channelButton");
		menuOption.scale.x /= targetZoom;
		menuOption.scale.y /= targetZoom;
		menuOption.updateHitbox();
		menuOption.text.size /= targetZoom;
		menuOption.text.fieldWidth = menuOption.width;
		menuOption.text.regenText(true);
		menuOption.text.width = menuOption.text.fieldWidth;
		menuOption.selectedSpr.scale.x /= targetZoom;
		menuOption.selectedSpr.scale.y /= targetZoom;
		menuOption.selectedSpr.updateHitbox();

		menuOption.x = option.x + (option.width*0.5) - (menuOption.width*0.5);
		menuOption.x -= 240/targetZoom;
		add(menuOption);
		menuOption.alpha = 0;

		startOption = new WiiOption(0, option.y + (490/targetZoom), "Start", "channelButton");
		startOption.scale.x /= targetZoom;
		startOption.scale.y /= targetZoom;
		startOption.updateHitbox();
		startOption.text.size /= targetZoom;
		startOption.text.fieldWidth = startOption.width;
		startOption.text.regenText(true);
		startOption.text.width = startOption.text.fieldWidth;
		startOption.selectedSpr.scale.x /= targetZoom;
		startOption.selectedSpr.scale.y /= targetZoom;
		startOption.selectedSpr.updateHitbox();

		startOption.x = option.x + (option.width*0.5) - (startOption.width*0.5);
		startOption.x += 240/targetZoom;
		add(startOption);
		startOption.alpha = 0;

		new FlxTimer().start(0.25, function(tmr)
		{			
			FlxG.sound.play(Paths.sound('channelEnter'));

			var ease = FlxEase.linear;

			FlxTween.tween(FlxG.camera, {zoom: targetZoom}, 0.5, {ease:FlxEase.linear});
			FlxTween.tween(FlxG.camera.scroll, {x: option.x + (option.width*0.5) - (FlxG.camera.width * 0.5), y: option.y + (option.height*0.5) - (FlxG.camera.height * 0.5)}, 0.5, {ease:FlxEase.quartOut});

			//fade on each side to prevent weird fade overlaps
			var whiteFades = MainMenuState.instance.whiteFades;
			whiteFades[0].y = channelBG.y - whiteFades[0].height;
			whiteFades[1].y = channelBG.y + channelBG.height;
			whiteFades[2].y = channelBG.y;
			whiteFades[3].y = channelBG.y;

			whiteFades[2].x = channelBG.x - whiteFades[2].width;
			whiteFades[3].x = channelBG.x + channelBG.width;
			whiteFades[2].scale.y = whiteFades[3].scale.y = channelBG.height;
			whiteFades[2].updateHitbox(); whiteFades[3].updateHitbox();

			for (fade in whiteFades) {
				FlxTween.tween(fade, {alpha: 1}, 0.35, {ease:ease});
			}

			FlxTween.tween(channelBG, {alpha: 1}, 0.35, {ease:ease});
			FlxTween.tween(menuOption, {alpha: 1}, 0.35, {ease:ease});
			FlxTween.tween(startOption, {alpha: 1}, 0.35, {ease:ease});
			FlxTween.tween(bg, {alpha: 1}, 0.35);
		});

		new FlxTimer().start(0.75, function(tmr)
		{
			//FlxTween.tween(bg, {alpha: 1}, 0.35);
		});

		FlxG.sound.music.fadeOut(1, 0);

		var startTime:Float = 1;
		switch(option.name) {
			case "wiik1" | "wiik2":
				bg.scale *= 1.25;
			case "whitegloves":
				bg.scale *= 1.25;
				bgYOffset += 15;

				bg.colorTransform.redOffset = bg.colorTransform.blueOffset = bg.colorTransform.greenOffset = 255;

			case "wiikz":
				bg.scale *= 1.25;
				new FlxTimer().start(0.25, function(tmr)
				{
					var blackBG = new FlxSprite();
					blackBG.makeGraphic(1,1,0xFF000000);
					blackBG.setGraphicSize(FlxG.width, FlxG.height);
					blackBG.scale.x /= targetZoom;
					blackBG.scale.y /= targetZoom;
					blackBG.updateHitbox();
					blackBG.x = option.x + (option.width*0.5) - (blackBG.width*0.5);
					blackBG.y = option.y + (option.height*0.5) - (blackBG.height*0.5);
					blackBG.antialiasing = ClientPrefs.data.antialiasing;
					objects.push(blackBG);
					insert(members.indexOf(bg)+1, blackBG);
				});
			case "fisticuffs":
				bgYOffset += 25;
			case "freeplay":
				//bg.scale *= 0.75;
				bgYOffset += 24;

				var freeplayText = setupSprite("wiimenu/channels/freeplay/FREEPLAY");
				add(freeplayText);
				freeplayText.y -= 55;

				var wfText = setupSprite("wiimenu/channels/freeplay/wf");
				add(wfText);
				wfText.x += 110;
				wfText.y -= 72;

				var text = setupSprite("wiimenu/channels/freeplay/text");
				add(text);
				text.y += 32;

				var possiblePhotos = ["Wiik 1", "Wiik 2", "3Hot", "Wiik Z", "Fisticuffs", "Revolution", "Mii Funkin"];
				var photos:Array<String> = [];
				for (i in 0...5) {
					var index = FlxG.random.int(0, possiblePhotos.length-1);
					photos.push(possiblePhotos[index]);
					possiblePhotos.remove(possiblePhotos[index]);
				}

				var photo0 = setupSprite("wiimenu/channels/freeplay/" + photos[0]);
				photo0.angle = 4;
				photo0.x -= 120;
				photo0.y -= 8;
				
				var photo1 = setupSprite("wiimenu/channels/freeplay/" + photos[1]);
				photo1.angle = -6;
				photo1.x -= 60;
				photo1.y -= 8;

				var photo2 = setupSprite("wiimenu/channels/freeplay/" + photos[2]);
				photo2.angle = 8;
				photo2.y -= 8;

				var photo3 = setupSprite("wiimenu/channels/freeplay/" + photos[3]);
				photo3.angle = 3;
				photo3.x += 60;
				photo3.y -= 8;

				var photo4 = setupSprite("wiimenu/channels/freeplay/" + photos[4]);
				photo4.angle = -8;
				photo4.x += 120;
				photo4.y -= 8;

				//add(photo0);
				add(photo1);
				//add(photo3);
				add(photo2);
				//add(photo4);

				insert(members.indexOf(bg)+1, photo4);
				insert(members.indexOf(bg)+1, photo3);
				insert(members.indexOf(bg)+1, photo0);

				for (item in [freeplayText, wfText, photo0, photo1, photo2, photo3, photo4, text]) {
					item.alpha = 0;
				}

				new FlxTimer().start(startTime, function(tmr) {
					for (item in [freeplayText, wfText, photo0, photo1, photo2, photo3, photo4, text]) {
						FlxTween.tween(item, {alpha: 1}, 1, {ease:FlxEase.expoOut});
					}
				});


				//4
				//-6
				//8
				//3
				//-8
		}

		new FlxTimer().start(startTime, function(tmr)
		{
			//this shit is painful but probably the easier option
			switch(option.name) {
				case "wiik1":
					new FlxTimer().start(0.15, function(tmr) {
						FlxG.sound.play(Paths.sound('channels/' + option.name));
					});
					FlxTween.tween(bg.scale, {x: bg.scale.x / 1.25}, 1, {ease:FlxEase.cubeOut});
					FlxTween.tween(bg.scale, {y: bg.scale.y / 1.25}, 1, {ease:FlxEase.cubeOut});

					var wiikspr = setupSprite("wiimenu/channels/Wiik");
					var wiiknum = setupSprite("wiimenu/channels/1");

					wiikspr.x += 15;
					wiikspr.y -= 25;
					wiiknum.x += 15;
					wiiknum.y -= 25;
					wiiknum.alpha = 0;

					insert(members.indexOf(bg)+1, wiikspr);
					insert(members.indexOf(bg)+1, wiiknum);

					wiikspr.x -= 320;
					FlxTween.tween(wiikspr, {x: wiikspr.x + 320}, 0.45, {ease:FlxEase.cubeOut});
					new FlxTimer().start(0.45, function(tmr)
					{
						wiiknum.alpha = 1;
						wiiknum.x -= 35;
						FlxTween.tween(wiiknum, {x: wiiknum.x + 35}, 0.5, {ease:FlxEase.cubeOut});
						new FlxTimer().start(0.5, function(tmr)
						{
							canExit = true;
						});
					});

				case "wiik2":
					new FlxTimer().start(0.15, function(tmr) {
						FlxG.sound.play(Paths.sound('channels/' + option.name));
					});
					FlxTween.tween(bg.scale, {x: bg.scale.x / 1.25}, 1, {ease:FlxEase.cubeOut});
					FlxTween.tween(bg.scale, {y: bg.scale.y / 1.25}, 1, {ease:FlxEase.cubeOut});

					var wiikspr = setupSprite("wiimenu/channels/wiik_2");
					var wiiknum = setupSprite("wiimenu/channels/2");

					wiikspr.x += 10;
					wiikspr.y -= 20;
					wiiknum.x += 10;
					wiiknum.y -= 20;

					add(wiiknum);
					add(wiikspr);

					wiikspr.alpha = wiiknum.alpha = 0;

					wiikspr.scale *= 1.25;
					FlxTween.tween(wiikspr.scale, {x: wiikspr.scale.x / 1.25}, 0.5, {ease:FlxEase.cubeOut});
					FlxTween.tween(wiikspr.scale, {y: wiikspr.scale.y / 1.25}, 0.5, {ease:FlxEase.cubeOut});
					FlxTween.tween(wiikspr, {alpha: 1}, 0.5, {ease:FlxEase.cubeOut});
					new FlxTimer().start(0.45, function(tmr)
					{
						wiiknum.scale *= 1.25;
						FlxTween.tween(wiiknum.scale, {x: wiiknum.scale.x / 1.25}, 0.5, {ease:FlxEase.cubeOut});
						FlxTween.tween(wiiknum.scale, {y: wiiknum.scale.y / 1.25}, 0.5, {ease:FlxEase.cubeOut});
						FlxTween.tween(wiiknum, {alpha: 1}, 0.5, {ease:FlxEase.cubeOut});
						new FlxTimer().start(0.5, function(tmr)
						{
							canExit = true;
						});
					});

				case "wiikz":

					new FlxTimer().start(0.6, function(tmr) {
						FlxG.sound.play(Paths.sound('channels/' + option.name));
					});
					FlxTween.tween(bg.scale, {x: bg.scale.x / 1.25}, 1.2, {ease:FlxEase.cubeOut});
					FlxTween.tween(bg.scale, {y: bg.scale.y / 1.25}, 1.2, {ease:FlxEase.cubeOut});

					var wiikspr = setupSprite("wiimenu/channels/Wiik_Z");
					var wiiknum = setupSprite("wiimenu/channels/Z");

					wiikspr.x += -3;
					wiikspr.y -= 21;
					wiiknum.x += 10;
					wiiknum.y -= 25;

					//add(wiiknum);
					//add(wiikspr);

					insert(members.indexOf(bg)+2, wiikspr);
					insert(members.indexOf(bg)+2, wiiknum);
					wiikspr.alpha = wiiknum.alpha = 0;

					var whiteBG = new FlxSprite();
					whiteBG.makeGraphic(1,1,0xFFFFFFFF);
					whiteBG.setGraphicSize(FlxG.width, FlxG.height);
					whiteBG.scale.x /= targetZoom;
					whiteBG.scale.y /= targetZoom;
					whiteBG.updateHitbox();
					whiteBG.x = option.x + (option.width*0.5) - (whiteBG.width*0.5);
					whiteBG.y = option.y + (option.height*0.5) - (whiteBG.height*0.5);
					whiteBG.antialiasing = ClientPrefs.data.antialiasing;
					objects.push(whiteBG);
					insert(members.indexOf(bg)+3, whiteBG);
					whiteBG.alpha = 0;

					wiiknum.scale *= 3;
					FlxTween.tween(wiiknum.scale, {x: wiiknum.scale.x / 3}, 0.6, {ease:FlxEase.cubeIn});
					FlxTween.tween(wiiknum.scale, {y: wiiknum.scale.y / 3}, 0.6, {ease:FlxEase.cubeIn});
					FlxTween.tween(wiiknum, {alpha: 1}, 0.6, {ease:FlxEase.cubeOut});
					wiiknum.x -= 50;
					FlxTween.tween(wiiknum, {x: wiiknum.x + 50}, 0.6, {ease:FlxEase.cubeIn});
					
					FlxTween.tween(whiteBG, {alpha: 1}, 0.6, {ease:FlxEase.expoIn});
					new FlxTimer().start(0.6, function(tmr)
					{
						objects[0].alpha = 0; //hide black bg
						FlxTween.tween(whiteBG, {alpha: 0}, 0.6, {ease:FlxEase.expoOut});
					});
					new FlxTimer().start(1.2, function(tmr)
					{
						FlxTween.tween(wiikspr, {alpha: 1}, 0.8, {ease:FlxEase.linear});
						new FlxTimer().start(0.8, function(tmr)
						{
							canExit = true;
						});
					});

				case "fisticuffs":

					

					var render = setupSprite("wiimenu/channels/Fisticuffs_Matt_Render");
					insert(members.indexOf(bg)+1, render);
					//render.x += 80;
					render.y -= 10;

					var logo = setupSprite("wiimenu/channels/fisticuffs_logo");
					insert(members.indexOf(bg)+1, logo);
					//logo.x -= 60;
					logo.y -= 20;

					render.x -= 200;
					logo.x += 200;
					FlxTween.tween(render, {x: render.x + 230}, 0.25, {ease:FlxEase.linear});
					FlxTween.tween(logo, {x: logo.x - 230}, 0.25, {ease:FlxEase.linear});

					render.colorTransform.redMultiplier = render.colorTransform.greenMultiplier = render.colorTransform.blueMultiplier = 0;
					new FlxTimer().start(0.25, function(tmr) {
						FlxG.sound.play(Paths.sound('channels/' + option.name));
						FlxTween.tween(render, {x: render.x + 50}, 1, {ease:FlxEase.cubeOut});
						FlxTween.tween(logo, {x: logo.x - 30}, 1, {ease:FlxEase.cubeOut});

						render.colorTransform.redOffset = render.colorTransform.greenOffset = render.colorTransform.blueOffset = 255;
						render.colorTransform.redMultiplier = render.colorTransform.greenMultiplier = render.colorTransform.blueMultiplier = 1;
						FlxTween.tween(render.colorTransform, {redOffset: 0, greenOffset: 0, blueOffset: 0}, 1, {ease:FlxEase.cubeOut});

						new FlxTimer().start(1, function(tmr)
						{
							canExit = true;
						});
					});


				case "whitegloves":

					

					var logo = setupSprite("wiimenu/channels/wg");
					logo.scale *= 0.8;
					logo.updateHitbox();
					logo.x = option.x + (option.width*0.5) - (logo.width*0.5);
					logo.y = option.y + (option.height*0.5) - (logo.height*0.5);
					logo.y -= 12;
					insert(members.indexOf(bg)+1, logo);

					logo.scale *= 0.5;
					logo.alpha = 0;
					FlxTween.tween(logo.scale, {x: logo.scale.x / 0.5, y: logo.scale.y / 0.5}, 1, {ease:FlxEase.cubeOut});
					FlxTween.tween(logo, {alpha: 1}, 1, {ease:FlxEase.cubeOut});
					/*
					logo.colorTransform.redMultiplier = logo.colorTransform.greenMultiplier = logo.colorTransform.blueMultiplier = 0;

					logo.y -= 100;
					FlxTween.tween(logo, {y: logo.y + 100}, 0.25, {ease:FlxEase.backOut});

					new FlxTimer().start(0.25, function(tmr) {
						FlxG.sound.play(Paths.sound('channels/' + option.name));

						logo.colorTransform.redOffset = logo.colorTransform.greenOffset = logo.colorTransform.blueOffset = 255;
						logo.colorTransform.redMultiplier = logo.colorTransform.greenMultiplier = logo.colorTransform.blueMultiplier = 1;
						FlxTween.tween(logo.colorTransform, {redOffset: 0, greenOffset: 0, blueOffset: 0}, 1, {ease:FlxEase.cubeOut});
						new FlxTimer().start(1, function(tmr)
						{
							canExit = true;
						});
					});

					*/

					FlxTween.tween(bg.colorTransform, {redOffset: 0, greenOffset: 0, blueOffset: 0}, 1, {ease:FlxEase.expoOut});

					FlxG.sound.play(Paths.sound('channels/' + option.name));

					FlxTween.tween(bg.scale, {x: bg.scale.x / 1.25}, 1.25, {ease:FlxEase.cubeOut});
					FlxTween.tween(bg.scale, {y: bg.scale.y / 1.25}, 1.25, {ease:FlxEase.cubeOut});
					FlxTween.tween(this, {bgYOffset: 0}, 1.25, {ease:FlxEase.cubeOut});

					new FlxTimer().start(1.25, function(tmr)
					{
						canExit = true;
					});

				case "freeplay":

					FlxG.sound.play(Paths.sound('channels/' + option.name));
					new FlxTimer().start(1, function(tmr)
					{
						canExit = true;
					});

				case "credits":

					var logo = setupSprite("wiimenu/channels/creditsLogo");
					logo.y -= 55;
					add(logo);
					logo.alpha = 0;

					var miiTop = setupSprite("wiimenu/channels/creditsMiisBack");
					miiTop.y += 5+7;
					var miiFade = setupSprite("wiimenu/channels/creditsWhiteFade");
					miiFade.y += 5+7;
					var miiBottom = setupSprite("wiimenu/channels/creditsMiisFront");
					miiBottom.y += 20+7;

					insert(members.indexOf(bg)+1, miiBottom);
					insert(members.indexOf(bg)+1, miiFade);
					insert(members.indexOf(bg)+1, miiTop);


					miiTop.y += 50;
					FlxTween.tween(miiTop, {y: miiTop.y - 50}, 0.5, {ease:FlxEase.backOut});

					miiBottom.y += 50;
					new FlxTimer().start(0.25, function(tmr) {
						
						FlxTween.tween(miiBottom, {y: miiBottom.y - 50}, 0.5, {ease:FlxEase.backOut});
					});


					
					new FlxTimer().start(0.5, function(tmr)
					{
						FlxG.sound.play(Paths.sound('channels/' + option.name));
						logo.y += 5;
						FlxTween.tween(logo, {alpha: 1}, 0.5, {ease:FlxEase.cubeOut});
						FlxTween.tween(logo, {y: logo.y - 5}, 0.5, {ease:FlxEase.backOut});

						new FlxTimer().start(0.5, function(tmr) {
							canExit = true;
						});
					});
					
				default:
					FlxG.sound.play(Paths.sound('channels/' + option.name));
					canExit = true;
			}
		});

		allowMouseControlWithKeys = true;
	}

	function setupSprite(graphicPath:String) {
		var spr = new FlxSprite();
		spr.loadGraphic(Paths.image(graphicPath));
		spr.scale.x /= targetZoom;
		spr.scale.y /= targetZoom;
		spr.updateHitbox();
		spr.x = option.x + (option.width*0.5) - (spr.width*0.5);
		spr.y = option.y + (option.height*0.5) - (spr.height*0.5);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		objects.push(spr);
		return spr;
	}

	var exiting:Bool = false;

	function updateClipRect(spr:FlxSprite) {
		if (spr.clipRect == null) {
			spr.clipRect = new FlxRect();
		}
		var rect = spr.clipRect;

		var w = Math.max( ((spr.x + spr.width) - (channelBG.x + channelBG.width)) / spr.scale.x, 0);
		var h = Math.max( ((spr.y + spr.height) - (channelBG.y + channelBG.height)) / spr.scale.y, 0);

		rect.x = Math.max( (channelBG.x - spr.x) / spr.scale.x, 0);
		rect.y = Math.max( (channelBG.y - spr.y) / spr.scale.y, 0);
		rect.width = spr.frameWidth - rect.x - w;
		rect.height = spr.frameHeight - rect.y - h;
		spr.clipRect = rect;
	}

	var bgYOffset:Float = 0;

	override public function update(elapsed:Float)
	{
		//FlxG.camera.scroll.x = option.x + (option.width*0.5) - (FlxG.camera.width * 0.5);
		//FlxG.camera.scroll.y = option.y + (option.height*0.5) - (FlxG.camera.height * 0.5);

		super.update(elapsed);

		bg.updateHitbox();
		bg.x = option.x + (option.width*0.5) - (bg.width*0.5);
		bg.y = option.y + (option.height*0.5) - (bg.height*0.5);
		bg.y -= 25;
		bg.y += bgYOffset;
		updateClipRect(bg);

		if (exiting)
			return;

		if (controls.BACK)
		{
			exit();
			return;
		}

		for (item in [menuOption, startOption])
		{
			if (FlxG.mouse.overlaps(item) && item.visible)
			{
				if (!item.selected)
				{
					FlxG.sound.play(Paths.sound('wiiOptionHover'));
					item.selected = true;
				}

				if(controls.ACCEPT || FlxG.mouse.justPressed)
				{
					if (item == startOption)
					{
						FlxG.sound.play(Paths.sound('channelStart'));
						exiting = true;
						new FlxTimer().start(0.25, function(tmr)
						{
							FlxG.camera.fade(0xFF000000, 0.5);
							new FlxTimer().start(0.5, function(tmr)
							{
								selectOption();
							});
						});
					}
					else if (item == menuOption)
					{
						exit();
					}
				}
			}
			else
			{
				item.selected = false;
			}
		}
	}

	function exit()
	{
		if (!canExit) return;
		if (exiting) return;
		exiting = true;
		FlxG.sound.music.fadeIn(1);
		FlxG.sound.play(Paths.sound('wiiBack'));

		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.5, {ease:FlxEase.linear, onComplete:function(twn)
		{
			MainMenuState.instance.persistentUpdate = true;
			close();
		}});

		FlxTween.tween(FlxG.camera.scroll, {x: 0, y: 0}, 0.5, {ease:FlxEase.quartIn});

		
		for (fade in MainMenuState.instance.whiteFades) {
			FlxTween.tween(fade, {alpha: 0}, 0.5, {ease:FlxEase.linear});
		}
		//FlxTween.tween(MainMenuState.instance.blackBG, {alpha: 0}, 0.5, {ease:FlxEase.linear});
		FlxTween.tween(channelBG, {alpha: 0}, 0.35, {ease:FlxEase.linear});
		for (obj in objects) {
			FlxTween.tween(obj, {alpha: 0}, 0.35, {ease:FlxEase.linear});
		}
		FlxTween.tween(bg, {alpha: 0}, 0.35, {ease:FlxEase.linear});
		FlxTween.tween(menuOption, {alpha: 0}, 0.35, {ease:FlxEase.linear});
		FlxTween.tween(startOption, {alpha: 0}, 0.35, {ease:FlxEase.linear});
	}

	function selectOption()
	{
		exiting = true;
		persistentUpdate = false;
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		switch(option.name)
		{
			case 'wiik1':
				loadWeek("1wiik1");
			case 'wiik2':
				loadWeek("2wiik2");
			case 'wiikz':
				loadWeek("3wiikZ");
			case 'fisticuffs':
				loadWeek("4wiikFisticuffs");
			case 'whitegloves':
				loadWeek("5wiikWG");
			case 'freeplay':
				MusicBeatState.switchState(new SongPackSelector());
			case 'credits':
				MusicBeatState.switchState(new MiiCreditsState());
		}
	}

	function loadWeek(name:String)
	{
		ClientPrefs.data.gameplaySettings.set("botplay", false);
		ClientPrefs.data.gameplaySettings.set("practice", false);

		var leWeek = WeekData.weeksLoaded[name];
		trace(WeekData.weeksLoaded);
		if (leWeek == null) return;

		WeekData.setDirectoryFromWeek(leWeek);
		PlayState.storyWeek = WeekData.weeksList.indexOf(name);
		Difficulty.loadFromWeek();

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

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
		PlayState.campaignScore = 0;
		PlayState.campaignMisses = 0;
		LoadingState.loadAndSwitchState(new PlayState());
	}
}



private class WiiMessageBoardSubstate extends MusicBeatSubstate {

	/*
	static final messageTitles = [
		"wiik1" => '',
		"wiik2" => '',
		"wiikz" => '',
		"fisticuffs" => '',
		"letterbomb" => ''
	];

	static final messageData = [
		"wiik1" => 'New songs have appeared in the Freeplay channel.\nNow Available: "Fired Up", "Mii Funkin",\n"Revolution", "3hot".',
		"wiik2" => 'New songs have appeared in the Freeplay channel.\nNow Available: "4hot", "Swap!", "Battlefield",\n"Motion Control".',
		"wiikz" => 'New songs have appeared in the Freeplay channel.\nNow Available: "Miisacre", "Lazulii", "Snacks".',
		"fisticuffs" => 'New songs have appeared in the Freeplay channel.\nNow Available: "Illusion", "Heavenfall",\n"Long Awaited", "God Mode", "Broadcasting".',
		"letterbomb" => ""
	];
	*/
	
	static final letterPositions = [
		"wiik1" => [-250, -200],
		"wiik2" => [250, 170],
		"wiikz" => [-300, 150],
		"fisticuffs" => [350, -150],
		"letterbomb" => [0, 0]
	];

	var messageBG:FlxSprite;
	var letters:Array<MainMenuOption> = [];
	var letterNotifs:Array<LetterNotif> = [];
	var canSelect:Bool = true;

	var backButton:substates.WiiPauseSubState.PauseOption; //too laxzyalkqjwehrflkjqwherlkjahsdflkjashdf
	var messageBox:FlxSprite;
	var messageText:WiiCustomText;
	var messageTitleText:FlxText;

	override public function new()
	{
		super();
	}

	var textX:Float = 40;
	var textY:Float = 254;

	override public function create()
	{
		super.create();

		FlxG.camera.maxScrollY = null;
		FlxTween.tween(FlxG.camera.scroll, {y: FlxG.height}, 0.25, {ease:FlxEase.smoothStepInOut});
		allowMouseControlWithKeys = true;

		var bg = new FlxSprite(0, FlxG.height).loadGraphic(Paths.image('wiimenu/messages/messageboardBG'));
		add(bg);

		var letterList:Array<String> = [];
		if (Highscore.getWeekCompletion("1wiik1")) letterList.push("wiik1");
		if (Highscore.getWeekCompletion("2wiik2")) letterList.push("wiik2");
		if (Highscore.getWeekCompletion("3wiikZ")) letterList.push("wiikz");
		if (Highscore.getWeekCompletion("4wiikFisticuffs")) letterList.push("fisticuffs");
		if (Highscore.getCompletion("foulplay") && !Highscore.getCompletion("destiny")) letterList.push("letterbomb");

		var unread = getUnreadLetters();

		for (i in 0...letterList.length) {
			var letter = new MainMenuOption(0, 0, false);
			letter.name = letterList[i];
			letter.antialiasing = ClientPrefs.data.antialiasing;
			letter.loadGraphic(Paths.image('wiimenu/messages/' + (letter.name == "letterbomb" ? 'letterBombfuckyougithub' : 'letter')));
			letter.screenCenter(); letter.y += FlxG.height;
			letter.x += letterPositions.get(letterList[i])[0];
			letter.y += letterPositions.get(letterList[i])[1];
			letter.onClick = function() {
				selectLetter(letter);
			}
			add(letter);
			letters.push(letter);

			var notif = new LetterNotif(letter);
			letterNotifs.push(notif);
			notif.visible = unread.contains(letterList[i]);
			add(notif);
		}

		var exitButton = new MainMenuOption(1088, 536 + FlxG.height, false);
		exitButton.loadGraphic(Paths.image('wiimenu/menu_back'));
		exitButton.antialiasing = ClientPrefs.data.antialiasing;
		exitButton.name = "exit";
		exitButton.scale.set(0.9, 0.9);
		exitButton.onClick = function()
		{
			exitButton.enabled = false;
			exitButton.selected = false;
			exit();
		}
		//exitButton.setupHoverText("Go Back", -80, -60, 200);
		add(exitButton);
		letters.push(exitButton); //not actually letter but yea who cares




		messageBG = new FlxSprite();
		messageBG.makeGraphic(1,1,0x80808080);
		messageBG.setGraphicSize(FlxG.width, FlxG.height); messageBG.updateHitbox();
		messageBG.screenCenter(); messageBG.y += FlxG.height;
		add(messageBG);
		messageBG.alpha = 0;

		messageBox = new FlxSprite(0, 750);
		messageBox.antialiasing = ClientPrefs.data.antialiasing;
		//messageBox.loadGraphic(Paths.image('wiimenu/messages/letterMessageBox'));
		//messageBox.screenCenter(X);
		add(messageBox);
		messageBox.alpha = 0;


		backButton = new substates.WiiPauseSubState.PauseOption(25, 600 + FlxG.height);
		backButton.antialiasing = ClientPrefs.data.antialiasing;
		backButton.loadGraphic(Paths.image('wiimenu/messages/messageBack'));
		backButton.clickSprite = new FlxSprite().loadGraphic(Paths.image("wiimenu/messages/messageBackClicked"));
		backButton.doScaleOnHover = false;
		add(backButton);
		backButton.alpha = 0;

		backButton.onClick = function() {
			unselectLetter();
			backButton.selected = false;
		}

		new FlxTimer().start(function(tmr) {canExit = true;});
	}


	var exiting:Bool = false;
	var canExit:Bool = false;

	override public function update(elapsed:Float)
	{

		super.update(elapsed);

		if (exiting)
			return;

		if (controls.BACK && canExit)
		{
			for (item in letters) item.selected = false;
			if (!canSelect) {
				unselectLetter();
				return;
			}
			exit();
			return;
		}

		if (canSelect) {
			backButton.selected = false;
			for (item in letters)
			{
				if (FlxG.mouse.overlaps(item) && item.enabled)
				{
					if (!item.selected)
					{
						FlxG.sound.play(Paths.sound('wiiOptionHover'));
						item.selected = true;
					}
				}
				else
				{
					item.selected = false;
				}
			}
		} else {
			for (item in [backButton])
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!item.selected)
					{
						FlxG.sound.play(Paths.sound('wiiOptionHover'));
						item.selected = true;
					}
				}
				else
				{
					item.selected = false;
				}
			}
		}
	}

	var currentLetter:MainMenuOption;

	function selectLetter(letter:MainMenuOption) {

		readLetter(letter.name);
		
		if (letter.name == 'letterbomb') {
			for (item in letters) item.selected = false;
			exiting = true;
			FlxG.sound.music.volume = 0;
			var bg = new FlxSprite(0, FlxG.height).makeGraphic(1,1,0xFF000000);
			bg.setGraphicSize(FlxG.width,FlxG.height);
			bg.updateHitbox();
			add(bg);

			Main.fpsVar.visible = false;

			var text = new FlxText(20, FlxG.height + 10, 0, 
				'savezelda (tueidj@tueidj.net)
				
				Copyright 2008,2009 Segher Boessenkool
				Copyright 2008 Haxx Enterprises
				Copyright 2008 Hector Martin ("marcan")
				Copyright 2003,2004 Felix Domke

				This code is licensed to you under the terms of the
				GNU GPL, version 2; see the file COPYING

				Font and graphics by Freddy Leitner

				Cleaning up enviroment...'
			);
			text.setFormat(Paths.font("vcr.ttf"), 20);
			add(text);

			new FlxTimer().start(0.05, function(tmr) {
				text.text = text.text + " OK.";
				new FlxTimer().start(1, function(tmr) {
					text.text = text.text + "\nSD card detected\nOpening boot.elf\nreading 2153056 bytes...";

					new FlxTimer().start(3, function(tmr) {
						text.text = text.text + "\n\nError reading boot.elf\nPlease reset console and try again.";
						FlxG.save.data.corrupted = true;
						FlxG.save.flush();
					});
				});
			});

			canSelect = false;

			return;
		}

		canSelect = false;
		for (l in letters) l.selected = false;
		currentLetter = letter;
		FlxTween.tween(messageBG, {alpha: 1}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(messageBox, {alpha: 1}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(backButton, {alpha: 1}, 0.25, {ease:FlxEase.linear});
		

		messageBox.loadGraphic(Paths.image('wiimenu/messages/' + letter.name));
		messageBox.setGraphicSize(0, 660);
		messageBox.screenCenter(X);

		letterNotifs[letters.indexOf(letter)].visible = false;

		//messageBox.scale.set(1.0, 1.0);
		messageBox.updateHitbox();
		messageBox.screenCenter(X);
		var screenCenterX = messageBox.x;
		messageBox.x = letter.x;
		messageBox.y = letter.y;
		messageBox.scale *= 0.3;
		messageBox.updateHitbox();

		function updateShit() {
			messageBox.updateHitbox();
		}

		FlxTween.tween(messageBox, {x: screenCenterX, y: 750}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(messageBox.scale, {x: messageBox.scale.x / 0.3, y: messageBox.scale.y / 0.3}, 0.25, {ease:FlxEase.linear, onUpdate:function(twn) {updateShit();}, onComplete: function(twn) {updateShit();}});
		FlxG.sound.play(Paths.sound("letterOpen"));

		canExit = false;
		new FlxTimer().start(function(tmr) {canExit = true;});
	}
	function unselectLetter() {
		canSelect = true;
		for (l in letters) l.selected = true;
		FlxTween.tween(messageBG, {alpha: 0}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(messageBox, {alpha: 0}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(backButton, {alpha: 0}, 0.25, {ease:FlxEase.linear});

		function updateShit() {
			messageBox.updateHitbox();
		}

		FlxTween.tween(messageBox, {x: currentLetter.x, y: currentLetter.y}, 0.25, {ease:FlxEase.linear});
		FlxTween.tween(messageBox.scale, {x: messageBox.scale.x * 0.3, y: messageBox.scale.y * 0.3}, 0.25, {ease:FlxEase.linear, onUpdate:function(twn) {updateShit();}, onComplete: function(twn) {updateShit();}});
		FlxG.sound.play(Paths.sound("letterClose"));

		canExit = false;
		new FlxTimer().start(function(tmr) {canExit = true;});
	}

	function exit()
	{
		if (exiting) return;
		exiting = true;

		FlxTween.tween(FlxG.camera.scroll, {y: 0}, 0.25, {ease:FlxEase.smoothStepInOut, onComplete:function(twn)
		{
			FlxG.camera.maxScrollY = FlxG.camera.height;
			MainMenuState.instance.reloadMessagesButton();
			MainMenuState.instance.persistentUpdate = true;
			close();
		}});
	}

	public static function getUnreadLetters() {
		var letterList:Array<String> = [];
		if (Highscore.getWeekCompletion("1wiik1")) letterList.push("wiik1");
		if (Highscore.getWeekCompletion("2wiik2")) letterList.push("wiik2");
		if (Highscore.getWeekCompletion("3wiikZ")) letterList.push("wiikz");
		if (Highscore.getWeekCompletion("4wiikFisticuffs")) letterList.push("fisticuffs");
		if (Highscore.getCompletion("foulplay") && !Highscore.getCompletion("destiny")) letterList.push("letterbomb");

		var readLetters:Array<String> = FlxG.save.data.lettersRead != null ? FlxG.save.data.lettersRead : [];
		var unread:Array<String> = [];
		for (l in letterList) {
			if (!readLetters.contains(l)) unread.push(l);
		}

		return unread;
	}
	private static function readLetter(name:String) {
		var readLetters:Array<String> = FlxG.save.data.lettersRead != null ? FlxG.save.data.lettersRead : [];
		if (!readLetters.contains(name)) readLetters.push(name);

		FlxG.save.data.lettersRead = readLetters;
		FlxG.save.flush();
	}
}

class BreakPopupSubstate extends MusicBeatSubstate {

	var popup:FlxSprite;
	var background:FlxSprite;
	override public function new() {
		super();

		background = new FlxSprite().makeGraphic(1,1,0xFF000000);
		background.setGraphicSize(FlxG.width, FlxG.height); background.updateHitbox();
		background.screenCenter();
		add(background);

		popup = new FlxSprite().loadGraphic(Paths.image("wiimenu/breakpopup"));
		popup.screenCenter();
		popup.antialiasing = ClientPrefs.data.antialiasing;
		add(popup);

		background.alpha = 0;
		popup.alpha = 0;
		popup.y += 20;

		FlxTween.tween(popup, {alpha: 1, y: popup.y - 20}, 0.5, {ease:FlxEase.quartOut});
		FlxTween.tween(background, {alpha: 0.4}, 0.5, {ease:FlxEase.quartOut});
	}

	var exitTimer:Float = 0.5;

	override public function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}
		var justTouched:Bool = false;
 		for (touch in FlxG.touches.list)
 			if (touch.justPressed)
 				justTouched = true;
		super.update(elapsed);

		if (exitTimer > 0) {
			exitTimer -= elapsed;
		} else {
			if (controls.ACCEPT || justTouched) {
				MainMenuState.instance.persistentUpdate = true;
				close();
			}
		}
	}
}

class LetterNotif extends FlxObject {
	final FLASH_TIME = 0.5;
	var flashers:Array<FlxSprite> = [];
	var flashElapsed:Float = 0.5;
	var flashIdx:Int = 0;

	var target:FlxSprite;

	override public function new(target:FlxSprite) {
		super(0,0);
		this.target = target;
		var spr1 = new FlxSprite().loadGraphic(Paths.image("wiimenu/messages/letterNew1"));
		var spr2 = new FlxSprite().loadGraphic(Paths.image("wiimenu/messages/letterNew2"));
		flashers.push(spr1);
		flashers.push(spr2);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		flashElapsed -= elapsed;
		if (flashElapsed < FLASH_TIME) {
			flashElapsed += FLASH_TIME;

			flashIdx++;
			if (flashIdx > flashers.length-1) flashIdx = 0;
		}
	}
	override public function draw() {
		if (visible) {
			var spr = flashers[flashIdx];
			spr.x = (target.x + (target.width/2)) - (spr.width/2);
			spr.y = (target.y + (target.height/2)) - ((target.frameHeight*target.scale.y*0.5)); //auto adjust to scale
			spr.y -= (spr.height/2);
			spr.draw();
		}
	}

	override public function destroy() {
		for (i in flashers) i.destroy();
		flashers = [];
		super.destroy();
	}
}

//really should have split these up but eh i dont feel like doing it




class TextTest extends MusicBeatSubstate {

	var text:WiiCustomText;
	var background:FlxSprite;
	override public function new() {
		super();

		background = new FlxSprite().makeGraphic(1,1,0xFF717171);
		background.setGraphicSize(FlxG.width, FlxG.height); background.updateHitbox();
		background.screenCenter();
		add(background);

		text = new WiiCustomText(0, 100, FlxG.width, "A.,/\\;'#()[]A0123456789A!$%&*+-\nabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", 1, "messages");
		add(text);


	}

	override public function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}
		super.update(elapsed);

		if (FlxG.keys.justPressed.F5) {
			text.applyFont(text.font, true);
			@:privateAccess
			text.regenText(true);
		}
	}
}
