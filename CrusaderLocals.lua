BINDING_HEADER_Crusader = "Crusader"
-- This statement will load any translation that is present or default to English.
if( not ace:LoadTranslation("Crusader") ) then

	Crusader_MSG_COLOR		= "|cffcceebb";
	Crusader_DISPLAY_OPTION	= "[|cfff5f530%s|cff0099CC]";

	Crusader_CONST = {

		Title   		= "Crusader",
		Version 		= "0.1",
		Desc    		= "Crusader a Paladin Helper",
		Timerheader		= "Paladin Timers",
		UpdateInterval		= 0.2,
	
		ChatCmd		= {"/crusader"},
		
		ChatOpt 		= {
			{	
				option	= "reset",
				desc	= "Reset the window positions.",
				method	= "chatReset",
			},
			{
				option 	= "lock",
				desc	= "Toggle locking of the frames",
				method  = "chatLock",
			},
			{
				option  = "timers",
				desc    = "Toggle to turn on/off the timers",
				method  = "chatTimers",
			},

		},
		
		Chat            	= {
			Lock = "Frame lock is now: ",
			Timers = "Timers are now: ",
		},
		
		Message			= {
			TooFarAway 	= "They are too far away.",
			Busy		= "They are busy.",
			PreSummon	= "Going to summon %s, please click the portal.",
			PreSoulstone	= "Placing my soulstone on %s.",
			Soulstone	= "%s has been soulstoned.",
			SoulstoneAborted = "Soustone Aborted! It's not placed.",
			FailedSummon	= "Summoning %s failed!",
		},
		

		Pattern = {
			Hearthstone = "Hearthstone",
			Healthstone = "Healthstone",
			Paladin = "Paladin",
			Rank = "Rank (.+)",
			Resisted = "^Your [%a%s%p]+ was resisted by [%a%s%p]+%.",
			Immune = "^Your [%a%s%p]+ failed%. [%a%s%p]+ is immune%.$",
		},

		State = {
			Reset = 0,
			Cast = 1,
			Start = 2,
			Stop = 3,
			NewMonsterNewSpell = 4,
			NewSpell = 5,
			Update = 6,
			Failed = 7
			
		},

		Spell = {	
			["Blessing of Kings"] = "BOK",
			["Blessing of Freedom"] = "BOF",
			["Seal of Reckoning"] = "SORK",

			["Hearthstone"] = "HEARTHSTONE",

		},

		RankedSpell = {
			["Summon Warhorse"] = { "MOUNT", 1 },
			["Summon Charger"] = { "MOUNT", 2 },
			-- Blessings
			["Blessing of Might Rank 1"] = { "BOM", 1,},
			["Blessing of Might Rank 2"] = { "BOM", 2 },
			["Blessing of Might Rank 3"] = { "BOM", 3 },
			["Blessing of Might Rank 4"] = { "BOM", 4 },
			["Blessing of Might Rank 5"] = { "BOM", 5 },
			["Blessing of Might Rank 6"] = { "BOM", 6 },
			["Blessing of Might Rank 7"] = { "BOM", 7 },
			["Blessing of Wisdom Rank 1"] = { "BOW", 1 },
			["Blessing of Wisdom Rank 2"] = { "BOW", 2 },
			["Blessing of Wisdom Rank 3"] = { "BOW", 3 },
			["Blessing of Wisdom Rank 4"] = { "BOW", 4 },
			["Blessing of Wisdom Rank 5"] = { "BOW", 5 },
			["Blessing of Wisdom Rank 6"] = { "BOW", 6 },
			["Blessing of Light Rank 1"] = { "BOL", 1 },
			["Blessing of Light Rank 2"] = { "BOL", 2 },
			["Blessing of Light Rank 3"] = { "BOL", 3 },
			["Blessing of Protection Rank 1"] = {"BOP", 1},
			["Blessing of Protection Rank 2"] = {"BOP", 1},
			["Blessing of Protection Rank 3"] = {"BOP", 1},
			["Blessing of Sanctuary Rank 1"] = {"BOS", 1},
			["Blessing of Sanctuary Rank 2"] = {"BOS", 2},
			["Blessing of Sanctuary Rank 3"] = {"BOS", 3},
			["Blessing of Sanctuary Rank 4"] = {"BOS", 4},

			-- Seals
			["Seal of Righteousness Rank 1"] = {"SOR", 1},
			["Seal of Righteousness Rank 2"] = {"SOR", 2},
			["Seal of Righteousness Rank 3"] = {"SOR", 3},
			["Seal of Righteousness Rank 4"] = {"SOR", 4},
			["Seal of Righteousness Rank 5"] = {"SOR", 5},
			["Seal of Righteousness Rank 6"] = {"SOR", 6},
			["Seal of Righteousness Rank 7"] = {"SOR", 7},
			["Seal of Righteousness Rank 8"] = {"SOR", 8},
			["Seal of the Crusader Rank 1"] = {"SOTC", 1},
			["Seal of the Crusader Rank 2"] = {"SOTC", 2},
			["Seal of the Crusader Rank 3"] = {"SOTC", 3},
			["Seal of the Crusader Rank 4"] = {"SOTC", 4},
			["Seal of the Crusader Rank 5"] = {"SOTC", 5},
			["Seal of the Crusader Rank 6"] = {"SOTC", 6},
			["Seal of the Crusader Rank 7"] = {"SOTC", 7},
			["Seal of Light Rank 1"] = {"SOL", 1},
			["Seal of Light Rank 2"] = {"SOL", 2},
			["Seal of Light Rank 3"] = {"SOL", 3},
			["Seal of Light Rank 4"] = {"SOL", 4},
			["Seal of Light Rank 5"] = {"SOL", 5},
			["Seal of Light Rank 6"] = {"SOL", 6},
			["Seal of Light Rank 7"] = {"SOL", 7},
			["Seal of Wisdom Rank 1"] = {"SOW", 1},
			["Seal of Wisdom Rank 2"] = {"SOW", 2},
			["Seal of Wisdom Rank 3"] = {"SOW", 3},
			["Seal of Wisdom Rank 4"] = {"SOW", 4},
			["Seal of Wisdom Rank 5"] = {"SOW", 5},
			["Seal of Wisdom Rank 6"] = {"SOW", 6},
			["Seal of Wisdom Rank 7"] = {"SOW", 7},
			["Seal of the Command Rank 1"] = {"SOC", 1},
			["Seal of the Command Rank 2"] = {"SOC", 2},
			["Seal of the Command Rank 3"] = {"SOC", 3},
			["Seal of the Command Rank 4"] = {"SOC", 4},
			["Seal of the Command Rank 5"] = {"SOC", 5},
			
		},
		TimedSpell = {
			--weapon buffs
			["Blessing of Kings"] = { 300, 300, 300, 300, 300 },
			["Blessing of Might"] = { 300, 300, 300, 300, 300, 300 },
			["Blessing of Wisdom"] = { 300, 300, 300, 300, 300, 300 },
			["Blessing of Freedom"] = { 10 },
			["Blessing of Protection"] = { 6 },
			["Blessing of Sanctuary"] = { 300, 300, 300, 300, 300, 300 },
			
			["Seal of Righteousness"] = { 30,30,30,30,30,30,30,30 },
			["Seal of the Crusader"] = { 30,30,30,30,30,30,30,30 },
			["Seal of Light"] = { 30,30,30,30,30,30,30,30 },
			["Seal of Wisdom"] = { 30,30,30,30,30,30,30,30 },
			["Seal of Command"] = { 30,30,30,30,30,30,30,30 },
			["Seal of Reckoning"] = { 30,30,30,30,30,30,30,30 },
			-- Shields
		},
	}

	ace:RegisterGlobals({
		version	= 1.01,
	
		ACEG_TEXT_NOW_SET_TO = "now set to",
		ACEG_TEXT_DEFAULT	 = "default",
	
		ACEG_DISPLAY_OPTION  = "[|cfff5f530%s|r]",
	
		ACEG_MAP_ONOFF		 = {[0]="|cffff5050Off|r",[1]="|cff00ff00On|r"},
		ACEG_MAP_ENABLED	 = {[0]="|cffff5050Disabled|r",[1]="|cff00ff00Enabled|r"},
	})
end