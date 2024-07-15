Crusader = AceAddonClass:new({
	name          		= Crusader_CONST.Title,
	description   		= Crusader_CONST.Desc,
	version       		= Crusader_CONST.Version,
	releaseDate   		= "",
	aceCompatible 		= 103,
	author        		= "Azgardian",
	email         		= "",
	website		     	= "http://www.wowace.com",
	category      		= "interface",
	db            		= AceDbClass:new("CrusaderDB"),
	cmd           		= AceChatCmdClass:new(Crusader_CONST.ChatCmd,Crusader_CONST.ChatOpt),
	
	----------------------------
	--			Module Loadup			--
	----------------------------
	
	
	Initialize = function(self)
		self.Compost = CompostLib:GetInstance("compost-1")
		self.Metrognome = Metrognome:GetInstance("1")
		self.Metrognome:Register("Crusader", self.Heartbeat, Crusader_CONST.UpdateInterval, self )
	end,
	
	Enable = function(self)
		if( UnitClass("player") == Crusader_CONST.Pattern.Paladin ) then
			self.spells = {}

			self.timers = {}
			self.timerstext = "" 
			self.lastupdate = 0
			self.currentspell = {}
			self.mounttype = 0
			self.hearthstone = {}

			self.bufftype = 0
			self.shieldtype = ""
			self.button = ""
			if( not self:GetOpt("firsttimedone") ) then
				self:SetOpt("timers", TRUE)
				self:SetOpt("firsttimedone", TRUE)
			end

			self:ScanSpells()
			

			self:SetupFrames()
			self.frames.main:Show()

			self:UpdateButtons()

			self:RegisterEvent("BAG_UPDATE")
			self:RegisterEvent("Crusader_BAG_UPDATE")

			self:RegisterEvent("SPELLS_CHANGED")
			self:RegisterEvent("LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED")

			self:RegisterEvent("SPELLCAST_START")
			self:RegisterEvent("SPELLCAST_FAILED")
			self:RegisterEvent("SPELLCAST_INTERRUPTED")
			--self:RegisterEvent("SPELLCAST_CHANNEL_START")
			-- self:RegisterEvent("SPELLCAST_CHANNEL_STOP")
			self:RegisterEvent("SPELLCAST_STOP")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")

			self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
			self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

			self:Hook("CastSpell", "OnCastSpell", Crusader )
			self:Hook("CastSpellByName", "OnCastSpellByName", Crusader )
			self:Hook("UseAction", "OnUseAction", Crusader )
			--slef:Hook("OnMouseUp")
			-- self:Hook("UseContainerItem", "OnUseContainerItem" )
		
			if( self:GetOpt("timers") ) then
				self.Metrognome:Start("Crusader")
				self.frames.timers:Show()
			else
				self.frames.timers:Hide()
			end
		end
	end,
	
	Disable = function(self)
		if( UnitClass("player") == Crusader_CONST.Pattern.Paladin ) then
			-- Stop the heartbeat and hide our main frame
			self.Metrognome:Stop("Crusader")
			self.frames.main:Hide()

			self.UnregisterAllEvents()

			self:Unhook("CastSpell")
			self:Unhook("CastSpellByName")
			self:Unhook("UseAction")
			-- self:Unhook("UseContainerItem")
		end
		
	end,

----------------------------
-- General               --
----------------------------


	GetGradient = function( self, perc )
		local gradient = "|CFF00FF00" -- BrightGreen
		
		if( perc < 10 ) then
			gradient = "|CFFFF0000" -- Red
		elseif( perc < 20 ) then
			gradient = "|CFFFF3300" -- RedOrange
		elseif( perc < 30 ) then
			gradient = "|CFFFF6600" -- DarkOrange
		elseif( perc < 40 ) then
			gradient = "|CFFFF9933" -- DirtyOrange
		elseif( perc < 50 ) then
			gradient = "|CFFFFCC00" -- DarkYellow
		elseif( perc < 60 ) then
			gradient = "|CFFFFFF66" -- LightYellow
		elseif( perc < 70 ) then
			gradient = "|CFFCCFF66" -- YellowGreen
		elseif( perc < 80 ) then
			gradient = "|CFF99FF66" -- LightGreen
		elseif( perc < 90 ) then
			gradient = "|CFF66FF66" -- LighterGreen
		end
		return gradient
	end,

	ScanHearth = function( self )
		local bag
		local itemLink
		self.Compost:Erase(self.hearthstone)
		--function UseContainerItemByName(search)
		--for bag = 0,4 do
		--	for slot = 1,GetContainerNumSlots(bag) do
		--		local item = GetContainerItemLink(bag,slot)
		--			if item and string.find(item,search) then
		--				UseContainerItem(bag,slot)
		--			end
		--	end
		--end
		--end

		for bag = 4, 0, -1 do
			local size = GetContainerNumSlots(bag)
			if (size > 0) then
				local slot
				for slot=1, size, 1 do
					if (GetContainerItemLink(bag,slot)) then
						itemLink = GetContainerItemLink(bag,slot)
						if( string.find( itemLink, "Hearthstone" )) then
							self.hearthstone[0] = bag
							self.hearthstone[1] = slot
						end
					end
				end
			end
		end
	end,

	ScanSpells = function( self )

		local spellName, spellRank, spellTotal, id, rank, maxrank, rankedSpell
		local spellLevel = {}

		self.spells.normal = {}
		self.spells.timed = {}
		self.spells.timedid = {}
		self.spells.timedname = {}
		self.spells.timeddisplay = {}
		self.spells.timedrank = {}

		for id = 1, 480 do
			rankedSpell = nil
			spellName, spellRank = GetSpellName(id, "spell")
			--self:SendChatMessage(string.format( self.timers[mindex][sindex]["duration"] ) )
			
			if (spellName) then
			
				if( spellRank and spellRank ~= "" ) then 
					spellTotal = spellName .. " " .. spellRank
				else 
					spellTotal = spellName
				end
				--self:SendChatMessage(string.format( spellname ) )
				if( Crusader_CONST.Spell[spellName] ) then
					self.spells.normal[Crusader_CONST.Spell[spellName]] = id
					
				end
				self:Msg("Spell: ##"..spellTotal.."##")
				if( Crusader_CONST.RankedSpell[spellTotal] ) then
					local thistag, thislevel
					thistag = Crusader_CONST.RankedSpell[spellTotal][1]
					thislevel = Crusader_CONST.RankedSpell[spellTotal][2]
					if( not spellLevel[thistag] or thislevel > spellLevel[thistag] ) then
						self.spells.normal[thistag] = id
						spellLevel[thistag] = thislevel
						if( thistag == "MOUNT" ) then
							self.mounttype = thislevel
						end
					end
				end

				if( Crusader_CONST.RankedSpell[spellName] ) then
					rankedSpell = spellName
				end
				if( Crusader_CONST.RankedSpell[spellTotal] ) then
					rankedSpell = spellTotal
				end

				if( rankedSpell ) then
					local thistag, thislevel, thisduration
					thistag = Crusader_CONST.RankedSpell[rankedSpell][1]
					thislevel = Crusader_CONST.RankedSpell[rankedSpell][2]
					
--						self:Msg ("Registered t:")
					if( not spellLevel[thistag] or thislevel > spellLevel[thistag] ) then
							self.spells.normal[thistag] = id
							spellLevel[thistag] = thislevel
							if( thistag == "MOUNT" ) then
								self.mounttype = thislevel
							end
						end
	
					end
				--self:Msg("Spell: ##"..spellNormal.."##")
				if( Crusader_CONST.TimedSpell[spellName] ) then
					maxrank = 0
					if (string.find(spellRank, Crusader_CONST.Pattern.Rank )) then
						for rank in string.gfind( spellRank, Crusader_CONST.Pattern.Rank ) do
							rank = tonumber(rank)
							if( rank > maxrank ) then
								maxrank = rank
							end
						end
					end					
					if( maxrank == 0 ) then
						maxrank = 1
					end
					if( not spellLevel[spellName] or maxrank > spellLevel[spellName] ) then
						self.spells.timedname[strlower(spellName)] = strlower(spellTotal)
					end
					self.spells.timedid[id] = strlower(spellTotal)
					self.spells.timed[strlower(spellTotal)] = Crusader_CONST.TimedSpell[spellName][maxrank]
					self.spells.timeddisplay[strlower(spellTotal)] = spellName
					self.spells.timedrank[id] = maxrank
					
				end
			end
		end
	end,	

	GetTargetInfo = function( self )

		local targetInfo = { }
	
		if( UnitExists("target") ) then
	
			targetInfo.Name = UnitName("target")
			targetInfo.Sex = UnitSex("target")
			targetInfo.Level = UnitLevel("target")
			if( targetInfo.Level == -1 ) then targetInfo.Level = "??" end

			targetInfo.Classification = UnitClassification("target")
			if( targetInfo.Classification == "worldboss" ) then
				targetInfo.Classification = "b+"
			elseif( targetInfo.Classification == "rareelite" ) then
				targetInfo.Classification = "r+"
			elseif( targetInfo.Classification == "elite" ) then
				targetInfo.Classification = "+"
			elseif( targetInfo.Classification == "rare" ) then
				targetInfo.Classification = "r"
			else 
				targetInfo.Classification = ""
			end

			targetInfo.IsPlayer = UnitIsPlayer("target")
			targetInfo.IsEnemy = UnitCanAttack("player", "target")
			targetInfo.Id = targetInfo.Name..targetInfo.Sex..targetInfo.Level
			targetInfo.Display = "["..targetInfo.Level..targetInfo.Classification.."] "..targetInfo.Name
		
			return targetInfo
		else
			return FALSE
		end
	
	end,

	RegisterSpellCast = function( self, spell )

		if( not self:GetOpt("timers") )	then return end

		if( self.currentspell.state and 
				self.currentspell.state == Crusader_CONST.State.Start ) then
			-- We do nothing. This happens when you cast a spell with a duration and
			-- after that cast another spell, which attempt to register with the timers.
			-- the state will be > 1 when SPELLCAST_START has fired we are casting atm.
			-- so ignore this cast.
			return
		end
	
		-- We reset the current spellcast whatever happens next.
		self.Compost:Erase( self.currentspell )

		-- Not a valid timed spell? don't do a thing
		if( not self.spells.timed[spell] ) then
			self.currentspell.state = Crusader_CONST.State.Cast
		    self.currentspell.target = "player"
		    self.currentspell.spell = spell
			self.currentspell.spelldisplay = self.spells.timeddisplay[spell]
			self.currentspell.duration = self.spells.timed[spell]
		
	    end

		-- If we don't have a target this spell is not worth monitoring for our purposes
		--local target = self:GetTargetInfo()
		local target = self
		if( not target ) then 
		-- Valid Spell, Valid target
		self.currentspell.state = Crusader_CONST.State.Cast
		self.currentspell.target = target
		self.currentspell.spell = spell
		self.currentspell.spelldisplay = self.spells.timeddisplay[spell]
		self.currentspell.duration = self.spells.timed[spell]

		else
		-- Valid Spell, Valid target
		self.currentspell.state = Crusader_CONST.State.Cast
		self.currentspell.target = target
		self.currentspell.spell = spell
		self.currentspell.spelldisplay = self.spells.timeddisplay[spell]
		self.currentspell.duration = self.spells.timed[spell]
		end
		 --self:Msg( "Registered t:"..self.currentspell.target.Display.." s: "..self.currentspell.spell.." d: "..self.currentspell.duration )
	end,

	ClearTimers = function( self )
		local i,j
		for i in pairs( self.timers ) do
			for j in pairs( self.timers[i] ) do
				if( j ~= "name" and j ~= "nr" ) then
					Timex:DeleteSchedule("Paladin Timers "..i..j)
				end
			end
		end
		self.Compost:Erase( self.timers )
	end,

	TimerDeleteSpell = function( self, mindex, sindex )
		if( self.timers[mindex] ) then
			if( self.timers[mindex][sindex] ) then
				self.timers[mindex][sindex]["duration"] = nil
				self.timers[mindex][sindex] = nil 
				self.timers[mindex]["nr"] = self.timers[mindex]["nr"] - 1
			end
			if( self.timers[mindex]["nr"] < 1 ) then
				self.timers[mindex]["name"] = nil
				self.timers[mindex]["nr"] = nil
				self.timers[mindex] = nil
			end
		end
	end,

	TimerAddSpell = function( self )
		local mindex = self.currentspell.target.Id
		local sindex = self.currentspell.spelldisplay
		if( self.timers[mindex] ) then
			if( self.timers[mindex][sindex] ) then
				-- self:Msg("AddSpell Updating "..mindex..sindex )
				self.currentspell.state = Crusader_CONST.State.Update
				self.currentspell.oldduration = Timex:ScheduleCheck("Paladin Timers "..mindex..sindex, TRUE)
				Timex:DeleteSchedule("Paladin Timers "..mindex..sindex )
				Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
				self.timers[mindex][sindex]["duration"] = self.currentspell.duration
			else
				-- self:Msg("AddSpell Newspell "..mindex..sindex )
				self.currentspell.state = Crusader_CONST.State.NewSpell
				self.timers[mindex][sindex] = {}
				self.timers[mindex][sindex]["duration"] = self.currentspell.duration
				self.timers[mindex]["nr"] = self.timers[mindex]["nr"] + 1
				Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
			end
		else
			-- self:Msg("AddSpell Newmonster&spell "..mindex..sindex )
			self.currentspell.state = Crusader_CONST.State.NewMonsterNewSpell
			self.timers[mindex] = {}
			self.timers[mindex]["nr"] = 0
			self.timers[mindex]["name"] = self.currentspell.spell
			self.timers[mindex][sindex] = {}
			self.timers[mindex][sindex]["duration"] = self.currentspell.duration
			self.timers[mindex]["nr"] = self.timers[mindex]["nr"] + 1
			Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
			
		end
	end,
	
	TimerAddBuff = function( self )
		local mindex = self.bufftype
		local sindex = self.currentspell.spelldisplay
		local spell_duration = self.currentspell.duration
		


        --self.currentspell.duration = 300
		if( self.timers[mindex] ) then
			if( self.timers[mindex][sindex] ) then
				-- self:Msg("AddSpell Updating "..mindex..sindex )
				self.currentspell.state = Crusader_CONST.State.Update
				self.currentspell.oldduration = Timex:ScheduleCheck("Paladin Timers "..mindex..sindex, TRUE)
				Timex:DeleteSchedule("Paladin Timers "..mindex..sindex )
				Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
				self.timers[mindex][sindex]["duration"] = self.currentspell.duration
			else
				-- self:Msg("AddSpell Newspell "..mindex..sindex )
				Timex:DeleteSchedule("Paladin Timers "..mindex..sindex )
				self.currentspell.state = Crusader_CONST.State.NewSpell	
				self.timers[mindex] = {}
				self.timers[mindex]["nr"] = 0
				self.timers[mindex]["name"] = sindex
				self.timers[mindex][sindex] = {}
				self.timers[mindex][sindex]["duration"] = self.currentspell.duration
				self.timers[mindex]["nr"] = self.timers[mindex]["nr"] + 1
				
				Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
				--self:SendChatMessage(string.format( self.timers[mindex][sindex]["duration"] ) )
			end
		else
			 self:Msg("AddSpell Newmonster&spell "..mindex..sindex )
			self.currentspell.state = Crusader_CONST.State.NewSpell
			self.timers[mindex] = {}
			self.timers[mindex]["nr"] = 0
			self.timers[mindex]["name"] = sindex
			self.timers[mindex][sindex] = {}
			self.timers[mindex][sindex]["duration"] = self.currentspell.duration
			self.timers[mindex]["nr"] = self.timers[mindex]["nr"] + 1
			Timex:AddSchedule("Paladin Timers "..mindex..sindex, self.currentspell.duration, nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
	        --self:SendChatMessage(string.format( self.currentspell.duration) )
		end 
		self.shieldtype = ""
	end,
	
	TimerRollback = function( self )
		local mindex = self.currentspell.target.Id
		local sindex = self.currentspell.spelldisplay
		local i
		if( not mindex or not sindex ) then return end
		if( self.currentspell.state == Crusader_CONST.State.NewMonsterNewSpell ) then
			if( self.timers[mindex] and self.timers[mindex][sindex] ) then
				self.timers[mindex][sindex]["duration"] = nil
				self.timers[mindex][sindex] = nil
				self.timers[mindex]["name"] = nil
				self.timers[mindex]["nr"] = nil
				self.timers[mindex] = nil
				Timex:DeleteSchedule( "Paladin Timers "..mindex..sindex )
			end
		elseif( self.currentspell.state == Crusader_CONST.State.NewSpell ) then
			if( self.timers[mindex] and self.timers[mindex][sindex] ) then
				self.timers[mindex][sindex]["duration"] = nil
				self.timers[mindex][sindex] = nil
				self.timers[mindex]["nr"] = self.timers[mindex]["nr"] - 1
				Timex:DeleteSchedule( "Paladin Timers "..mindex..sindex )
			end
		elseif( self.currentspell.state == Crusader_CONST.State.Update ) then
			Timex:DeleteSchedule( "Paladin Timers "..mindex..sindex )
			Timex:AddSchedule( "Paladin Timers "..mindex..sindex, (self.currentspell.duration - self.currentspell.oldduration), nil, nil, Crusader.TimerDeleteSpell, Crusader, mindex, sindex )
		end
	end,

	SendChatMessage = function( self, msg )
		if (GetNumRaidMembers() > 0) then
			SendChatMessage(msg, "RAID");
		elseif (GetNumPartyMembers() > 0) then
			SendChatMessage(msg, "PARTY");
		else
			SendChatMessage(msg, "SAY");
		end
	end,
	
	BuildTime = function( self, duration )
		local minute
		if( duration > 59 ) then
			minute = floor( duration / 60 )
			duration = duration - (minute *60)
		else
			minute = 0
		end
		if( minute < 10 ) then minute = "0"..minute end
		if( duration < 10 ) then duration  = "0"..duration end
		return minute..":"..duration	
	end,

	castblessingsonenter = function( self, spell_name,frame )
		GameTooltip:Hide()
        GameTooltip:SetOwner(frame, "TOP_RIGHT")
        GameTooltip:AddLine(spell_name)
        GameTooltip:Show()
	end,
	castblessingsonleave = function( self, spell_name,frame )
		GameTooltip:Hide()
	end,

	castfiretotemonenter = function( self, spell_name,frame )
		GameTooltip:Hide()
        GameTooltip:SetOwner(frame, "TOP_RIGHT")
        GameTooltip:AddLine(spell_name)
        GameTooltip:Show()
	end,
	castfiretotemonleave = function( self, spell_name,frame )
		GameTooltip:Hide()
	end,

	castweapononenter = function( self, spell_name,frame )
		GameTooltip:Hide()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(spell_name)
        GameTooltip:Show()
	end,
	castweapononleave = function( self, spell_name,frame )
		GameTooltip:Hide()
	end,

	castshieldonenter = function( self, spell_name,frame )
		GameTooltip:Hide()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(spell_name)
        GameTooltip:Show()
	end,
	castshieldonleave = function( self, spell_name,frame )
		GameTooltip:Hide()
	end,

	casthearthstoneonenter = function( self, spell_name,frame )
		GameTooltip:Hide()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(spell_name)
        GameTooltip:Show()
	end,
	casthearthstoneonleave = function( self, spell_name,frame )
		GameTooltip:Hide()
	end,

	Castblessing = function( self, spellid )
		local playername = UnitName("player");
		local old_target = UnitName("playertarget")
		
		TargetUnit("player")
		CastSpell( spellid, BOOKTYPE_SPELL )
		--CastSpellByName(spellname)
		if old_target == nil then 
			ClearTarget()
		else	
			TargetByName(old_target)
		end
		self.bufftype = 1
		
		self:TimerAddBuff(spellid)
		
		if( self:GetOpt("closeonclick") ) then
			self:BlessingClicked()
		end
		self:BlessingsClicked()
	end,
	
    	CastBOS = function( self, spellid )
		local playername = UnitName("player");
		local old_target = UnitName("playertarget")
		
		TargetUnit("player")
		CastSpell( spellid, BOOKTYPE_SPELL )
		--CastSpellByName(spellname)
		if old_target == nil then 
			ClearTarget()
		else	
			TargetByName(old_target)
		end
		self.bufftype = 1
		
		self:TimerAddBuff(spellid)
		
		--if( self:GetOpt("closeonclick") ) then
		--	self:BlessingClicked()
		--end
		--self:BlessingsClicked()
	end,
	
	
	Castseal = function( self, spellid )
		
		CastSpell( spellid, BOOKTYPE_SPELL )
		self.bufftype = 2
		self:TimerAddBuff(spellid)
		
		if( self:GetOpt("closeonclick") ) then
			self:SealClicked()
		end
		self:SealClicked()
	end,
	
	castairtotem = function( self, spellid )
		
		CastSpell( spellid, BOOKTYPE_SPELL )
		self.bufftype = 3
		self:TimerAddBuff(spellid)
		
		if( self:GetOpt("closeonclick") ) then
			self:AirTotemClicked()
		end
		self:AirTotemClicked()
	end,
	
	castwatertotem = function( self, spellid )
		
		CastSpell( spellid, BOOKTYPE_SPELL )
		self.bufftype = 4
		self:TimerAddBuff(spellid)

		if( self:GetOpt("closeonclick") ) then
			self:WaterTotemClicked()
		end
		self:WaterTotemClicked()
	end,
	
	castweapon = function( self, spellid, Spellbooktab )
		
		CastSpell( spellid, BOOKTYPE_SPELL )
		self.bufftype = 6
		self:TimerAddBuff(spellid)
		
		if( self:GetOpt("closeonclick") ) then
			self:WeaponBuffClicked()
		end
		self:WeaponBuffClicked()

	end,
	
	castshield = function( self, spellid, Spellbooktab )
		self.bufftype = 5
		if( self.spells.normal["LS"] ) then
			CastSpellByName( "Lightning Shield()" )
			self.shieldtype = "LS"
			self:TimerAddBuff(spellid)
		end
		if( self.spells.normal["WS"] ) then
			CastSpellByName( "Water Shield()" )
			self.shieldtype = "WS"
			self:TimerAddBuff(spellid)
		end
		if( self.spells.normal["ES"] ) then
			CastSpellByName( "Earth Shield()" )
			self.shieldtype = "ES"
			self:TimerAddBuff(spellid)
		end
					
		if( self:GetOpt("closeonclick") ) then
			self:ShieldBuffClicked()
		end
			self:ShieldBuffClicked()

	end,


	casthearthstone = function( self, spellid )
	    local name, stoneloc
	
		UseContainerItem(self.hearthstone[0],self.hearthstone[1])
		--if( self:GetOpt("closeonclick") ) then
		--	self:HearthClicked()
		--end
		--self:HearthClicked()

	end,

----------------------------
-- GUI Updating Functions --
----------------------------

	SetupFrames = function( self )
		local x, y, etx, ftx, wtx, atx, stx, btx
		
		self.frames = {}
		self.frames.main = CreateFrame( "Frame", nil, UIParent )
		self.frames.main.owner = self
		self.frames.main:Hide()
		self.frames.main:EnableMouse(true)
		self.frames.main:SetMovable(true)
		self.frames.main:SetWidth(1)
		self.frames.main:SetHeight(1)
		if( self:GetOpt("mainx") and self:GetOpt("mainy") ) then
			x = self:GetOpt("mainx")
			y = self:GetOpt("mainy")
			self.frames.main:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y )
		else
		self.frames.main:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 150, -150)
		end
		
		-- Graphical Shardcounter
		self.frames.shard = CreateFrame( "Button", nil, self.frames.main )
		self.frames.shard.owner = self
		self.frames.shard:SetWidth(80)
		self.frames.shard:SetHeight(80)
		self.frames.shard:SetPoint("CENTER", self.frames.main, "CENTER" )
		self.frames.shard:RegisterForDrag("LeftButton")
		self.frames.shard:SetScript("OnDragStart", function() this.owner.frames.main:StartMoving() end )
		self.frames.shard:SetScript("OnDragStop",
			function() 
				this.owner.frames.main:StopMovingOrSizing()
				local _,_,_,x,y = this.owner.frames.main:GetPoint("CENTER")
				this.owner:SetOpt("mainx", x)
				this.owner:SetOpt("mainy", y)
			end
		)		
		

		-- Text inside the counter		
		self.frames.shardtext = self.frames.shard:CreateFontString(nil, "OVERLAY")
		self.frames.shardtext.owner = self
		self.frames.shardtext:SetFontObject(GameFontNormalSmall)
		self.frames.shardtext:ClearAllPoints()
		self.frames.shardtext:SetTextColor(1, 1, 1, 1) 
		self.frames.shardtext:SetWidth(80)
		self.frames.shardtext:SetHeight(80)
		self.frames.shardtext:SetPoint("TOPLEFT", self.frames.shard, "TOPLEFT")
		self.frames.shardtext:SetJustifyH("CENTER")
		self.frames.shardtext:SetJustifyV("MIDDLE")

		self.frames.blessings = CreateFrame("Button", nil, self.frames.main )
		self.frames.blessings.owner = self
		
		self.frames.blessings:SetWidth(26)
		self.frames.blessings:SetHeight(26)
		self.frames.blessings:SetPoint("CENTER", self.frames.main, "CENTER", -19.3 , 46.19 )
		self.frames.blessings:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Ability_Paladin_BlessedHands" )
		self.frames.blessings:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		
		self.frames.blessings:SetScript("OnClick", function() this.owner:BlessingsClicked() end )
        self.frames.blessings:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessings",self.frames.blessings) end) 
		self.frames.blessings:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessings",self.frames.blessings) end) 
			
		 
		-- Blessings Menu 
		self.frames.blessingsmenu = CreateFrame("Frame", nil, self.frames.blessings )
		self.frames.blessingsmenu.owner = self
		self.frames.blessingsmenu:SetWidth(1)
		self.frames.blessingsmenu:SetHeight(1)
		self.frames.blessingsmenu:SetPoint("TOPRIGHT", self.frames.blessings, "TOPLEFT" )
		
		self.frames.blessingsmenu:Hide()
	
		local tmp_x
	    etx = 0
		-- Blessing of Might
		self.frames.bom = CreateFrame("Button", nil, self.frames.blessingsmenu )
		self.frames.bom.owner = self
		self.frames.bom:SetWidth(26)
		self.frames.bom:SetHeight(26)
		self.frames.bom:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_FistOfJustice")
		self.frames.bom:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.bom:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		self.frames.bom:SetScript("OnClick", function() this.owner:Castblessing(this.owner.spells.normal["BOM"]) end )
		self.frames.bom:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Might",self.frames.bom) end) 
		self.frames.bom:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Might",self.frames.bom) end) 
		
		tmp_x = etx
		
		-- Blessing of Wisdom
		if( self.spells.normal["BOW"] ) then  etx = tmp_x - 32 end
		self.frames.bow = CreateFrame("Button", nil, self.frames.blessingsmenu )
		self.frames.bow.owner = self
		self.frames.bow:SetWidth(26)
		self.frames.bow:SetHeight(26)
		self.frames.bow:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_SealOfWisdom")
		self.frames.bow:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.bow:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		self.frames.bow:SetScript("OnClick", function() this.owner:Castblessing( this.owner.spells.normal["BOW"] ) end )
		self.frames.bow:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Wisdom",self.frames.bow) end)
		self.frames.bow:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Wisdom",self.frames.bow) end)

		tmp_x = etx

		-- Blessing of Kings
        if( self.spells.normal["BOK"] ) then  etx = tmp_x - 32 end
		self.frames.bok = CreateFrame("Button", nil, self.frames.blessingsmenu )
		self.frames.bok.owner = self
		self.frames.bok:SetWidth(26)
		self.frames.bok:SetHeight(26)
		self.frames.bok:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Magic_Magearmor")
		self.frames.bok:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.bok:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		self.frames.bok:SetScript("OnClick", function() this.owner:Castblessing( this.owner.spells.normal["BOK"] ) end )
		self.frames.bok:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Kings",self.frames.bok) end)
		self.frames.bok:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Kings",self.frames.bok) end)

		tmp_x = etx

		-- Blessing of Freedom
        if( self.spells.normal["BOF"] ) then  etx = tmp_x - 32 end
		self.frames.bof = CreateFrame("Button", nil, self.frames.blessingsmenu )
		self.frames.bof.owner = self
		self.frames.bof:SetWidth(26)
		self.frames.bof:SetHeight(26)
		self.frames.bof:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_SealOfValor")
		self.frames.bof:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.bof:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		self.frames.bof:SetScript("OnClick", function() this.owner:Castblessing( this.owner.spells.normal["BOF"] ) end )	
		self.frames.bof:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Freedom",self.frames.bof) end)
		self.frames.bof:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Freedom",self.frames.bof) end)
       	tmp_x = etx
		
		-- Blessing of Protection
        if( self.spells.normal["BOP"] ) then  etx = tmp_x - 32 end
		self.frames.bop = CreateFrame("Button", nil, self.frames.blessingsmenu )
		self.frames.bop.owner = self
		self.frames.bop:SetWidth(26)
		self.frames.bop:SetHeight(26)
		self.frames.bop:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_SealOfProtection")
		self.frames.bop:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.bop:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		self.frames.bop:SetScript("OnClick", function() this.owner:Castblessing( this.owner.spells.normal["BOP"] ) end )	
		self.frames.bop:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Protection",self.frames.bop) end)
		self.frames.bop:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Protection",self.frames.bop) end)
       	tmp_x = etx
		
		-- Blessing of Light
        --if( self.spells.normal["BOL"] ) then  etx = tmp_x - 32 end
		--self.frames.bol = CreateFrame("Button", nil, self.frames.blessingsmenu )
		--self.frames.bol.owner = self
		--self.frames.bol:SetWidth(26)
		--self.frames.bol:SetHeight(26)
		--self.frames.bol:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_SealOfProtection")
		--self.frames.bol:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		--self.frames.bol:SetPoint("TOPRIGHT", self.frames.blessingsmenu, "TOPLEFT", etx, 6.5 )
		--self.frames.bol:SetScript("OnClick", function() this.owner:Castblessing( this.owner.spells.normal["BOL"] ) end )	
		--self.frames.bol:SetScript("OnEnter", function() this.owner:castblessingsonenter("Blessing of Light",self.frames.bol) end)
		--self.frames.bol:SetScript("OnLeave", function() this.owner:castblessingsonleave("Blessing of Light",self.frames.bol) end)
       	--tmp_x = etx


		-- Fire Totem button
		local tmp_x
	    ftx = 0
--[[
		self.frames.firetotem = CreateFrame("Button", nil, self.frames.main )
		self.frames.firetotem.owner = self
		self.frames.firetotem:SetWidth(38)
		self.frames.firetotem:SetHeight(38)
		self.frames.firetotem:SetPoint("CENTER", self.frames.main, "CENTER", -46.19, 19.13 )
		self.frames.firetotem:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Fire_Elemental_Totem" )
		self.frames.firetotem:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.firetotem:SetScript("OnClick", function() this.owner:FireTotemClicked() end )
		self.frames.firetotem:SetScript("OnEnter", function() this.owner:castfiretotemonenter("Fire Totems",self.frames.firetotem) end)
		self.frames.firetotem:SetScript("OnLeave", function() this.owner:castfiretotemonleave("Fire Totems",self.frames.firetotem) end)

		-- fire totem Menu 
		self.frames.firetotemmenu = CreateFrame("Frame", nil, self.frames.firetotem )
		self.frames.firetotemmenu.owner = self
		self.frames.firetotemmenu:SetWidth(1)
		self.frames.firetotemmenu:SetHeight(1)
		self.frames.firetotemmenu:SetPoint("TOPRIGHT", self.frames.firetotem, "TOPLEFT" )
		self.frames.firetotemmenu:Hide()
	
		-- searing
		self.frames.seat = CreateFrame("Button", nil, self.frames.firetotemmenu )
		self.frames.seat.owner = self
		self.frames.seat:SetWidth(38)
		self.frames.seat:SetHeight(38)
		self.frames.seat:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Fire_SearingTotem")
		self.frames.seat:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.seat:SetPoint("TOPRIGHT", self.frames.firetotemmenu, "TOPLEFT", ftx, 0 )
		self.frames.seat:SetScript("OnClick", function() this.owner:castfiretotem( this.owner.spells.normal["SEAT"] ) end )		
		self.frames.seat:SetScript("OnEnter", function() this.owner:castfiretotemonenter("Searing",self.frames.seat) end)
		self.frames.seat:SetScript("OnLeave", function() this.owner:castfiretotemonleave("Searing",self.frames.seat) end)
				
		
		-- snetry
		tmp_x = atx
		if( self.spells.normal["SENT"] ) then  atx = tmp_x - 32 end

		self.frames.sent = CreateFrame("Button", nil, self.frames.airtotemmenu )
		self.frames.sent.owner = self
		self.frames.sent:SetWidth(38)
		self.frames.sent:SetHeight(38)
		self.frames.sent:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Nature_RemoveCurse")
		self.frames.sent:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.sent:SetPoint("TOPRIGHT", self.frames.airtotemmenu, "TOPLEFT", atx, -6.5 )
		self.frames.sent:SetScript("OnClick", function() this.owner:castairtotem( this.owner.spells.normal["SENT"] ) end )	
        self.frames.sent:SetScript("OnEnter", function() this.owner:castairtotemonenter("Sentry",self.frames.sent) end)
		self.frames.sent:SetScript("OnLeave", function() this.owner:castairtotemonleave("Sentry",self.frames.sent) end)

		-- WWT
		tmp_x = atx
		if( self.spells.normal["WWT"] ) then  atx = tmp_x - 32 end
		
		self.frames.wwt = CreateFrame("Button", nil, self.frames.airtotemmenu )
		self.frames.wwt.owner = self
		self.frames.wwt:SetWidth(38)
		self.frames.wwt:SetHeight(38)
		self.frames.wwt:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Nature_EarthBind")
		self.frames.wwt:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.wwt:SetPoint("TOPRIGHT", self.frames.airtotemmenu, "TOPLEFT", atx, -6.5 )
		self.frames.wwt:SetScript("OnClick", function() this.owner:castairtotem( this.owner.spells.normal["WWT"] ) end )	
        self.frames.wwt:SetScript("OnEnter", function() this.owner:castairtotemonenter("Wind Wall",self.frames.wwt) end)
		self.frames.wwt:SetScript("OnLeave", function() this.owner:castairtotemonleave("Wind Wall",self.frames.wwt) end)

		-- Grace of Air
		tmp_x = atx
		if( self.spells.normal["GOAT"] ) then  atx = tmp_x - 32 end

		self.frames.goat = CreateFrame("Button", nil, self.frames.airtotemmenu )
		self.frames.goat.owner = self
		self.frames.goat:SetWidth(38)
		self.frames.goat:SetHeight(38)
		self.frames.goat:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Nature_InvisibilityTotem")
		self.frames.goat:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.goat:SetPoint("TOPRIGHT", self.frames.airtotemmenu, "TOPLEFT", atx, -6.5 )
		self.frames.goat:SetScript("OnClick", function() this.owner:castairtotem( this.owner.spells.normal["GOAT"] ) end )	
        self.frames.goat:SetScript("OnEnter", function() this.owner:castairtotemonenter("Grace of Air",self.frames.goat) end)
		self.frames.goat:SetScript("OnLeave", function() this.owner:castairtotemonleave("Grace of Air",self.frames.goat) end)
	
		
		-- Water Totem button
		self.frames.watertotem = CreateFrame("Button", nil, self.frames.main )
		self.frames.watertotem.owner = self
		self.frames.watertotem:SetWidth(38)
		self.frames.watertotem:SetHeight(38)
		self.frames.watertotem:SetPoint("CENTER", self.frames.main, "CENTER", -46.19, -19.3  )
		self.frames.watertotem:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\INV_Spear_04" )
		self.frames.watertotem:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.watertotem:SetScript("OnClick", function() this.owner:WaterTotemClicked() end )
		self.frames.watertotem:SetScript("OnEnter", function() this.owner:castwatertotemonenter("Water Totems",self.frames.firetotem) end)
		self.frames.watertotem:SetScript("OnLeave", function() this.owner:castwatertotemonleave("Water Totems",self.frames.firetotem) end)
		
		self.frames.watertotemb = CreateFrame("Button", nil, self.frames.main )
		self.frames.watertotemb.owner = self
		self.frames.watertotemb:SetWidth(38)
		self.frames.watertotemb:SetHeight(38)
		self.frames.watertotemb:SetPoint("CENTER", self.frames.main, "CENTER", -40, -9 )
		--self.frames.watertotemb:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\INV_Spear_04" )
		
		local tmp_x
	    wtx = 0

		-- Water totem menu
		self.frames.watertotemmenu = CreateFrame("Frame", nil, self.frames.watertotem )
		self.frames.watertotemmenu.owner = self
		self.frames.watertotemmenu:SetWidth(1)
		self.frames.watertotemmenu:SetHeight(1)
		self.frames.watertotemmenu:SetPoint("TOPRIGHT", self.frames.watertotem, "TOPLEFT" )
		self.frames.watertotemmenu:Hide()
	
		-- healing stream totem

		self.frames.hst = CreateFrame("Button", nil, self.frames.watertotemmenu )
		self.frames.hst.owner = self
		self.frames.hst:SetWidth(38)
		self.frames.hst:SetHeight(38)
		self.frames.hst:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\INV_Spear_04")
		self.frames.hst:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.hst:SetPoint("TOPRIGHT", self.frames.watertotemmenu, "TOPLEFT", wtx, 0 )
		self.frames.hst:SetScript("OnClick", function() this.owner:castwatertotem( this.owner.spells.normal["HST"] ) end)
        self.frames.hst:SetScript("OnEnter", function() this.owner:castwatertotemonenter("Healing Stream",self.frames.hst) end)
		self.frames.hst:SetScript("OnLeave", function() this.owner:castwatertotemonleave("Healing Stream",self.frames.hst) end)
--]]
		
		-- Mount button
		self.frames.mount = CreateFrame("Button", nil, self.frames.main )
		self.frames.mount.owner = self
		self.frames.mount:SetWidth(34)
		self.frames.mount:SetHeight(34)
		self.frames.mount:SetPoint("CENTER", self.frames.main, "CENTER", 24, -36 )
		self.frames.mount:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Ability_Mount_Charger" )
		self.frames.mount:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.mount:SetScript("OnClick", function() this.owner:MountClicked() end )

		-- Pots button
		--self.frames.armor = CreateFrame("Button", nil, self.frames.main )
		--self.frames.armor.owner = self
		--self.frames.armor:SetWidth(38)
		--self.frames.armor:SetHeight(38)
		--self.frames.armor:SetPoint("CENTER", self.frames.main, "CENTER", 0, 45 )
		--self.frames.armor:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\INV_Potion_50" )
		--self.frames.armor:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		--self.frames.armor:SetScript("OnClick", function() this.owner:ArmorClicked() end )

		self.frames.hearth = CreateFrame("Button", nil, self.frames.main )
		self.frames.hearth.owner = self
		self.frames.hearth:RegisterForClicks("LeftButtonUp","RightButtonUp")
		self.frames.hearth:SetWidth(38)
		self.frames.hearth:SetHeight(38)
		self.frames.hearth:SetPoint("CENTER", self.frames.main, "CENTER", 19.13, 46.19 )
		self.frames.hearth:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\INV_Misc_Rune_01" )
		self.frames.hearth:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.hearth:SetScript("OnClick", function() this.owner:casthearthstone( this.owner.spells.normal["HEARTSHTONE"] ) end )
		self.frames.hearth:SetScript("OnEnter", function() this.owner:casthearthstoneonenter("Hearthstone",self.frames.hearth) end)
		self.frames.hearth:SetScript("OnLeave", function() this.owner:casthearthstoneonleave("Hearthstone",self.frames.hearth) end)

		
		-- Weapon Buffs button
		self.frames.weaponbuff = CreateFrame("Button", nil, self.frames.main )
		self.frames.weaponbuff.owner = self
		self.frames.weaponbuff:SetWidth(26)
		self.frames.weaponbuff:SetHeight(26)
		self.frames.weaponbuff:SetPoint("CENTER", self.frames.main, "CENTER", 46.19, 19.13)
		self.frames.weaponbuff:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Ability_Paladin_HammeroftheRighteous" )
		self.frames.weaponbuff:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.weaponbuff:SetScript("OnClick", function() this.owner:WeaponBuffClicked() end )
		self.frames.weaponbuff:SetScript("OnEnter", function() this.owner:castweapononenter("Weapon Seals",self.frames.weaponbuff) end)
		self.frames.weaponbuff:SetScript("OnLeave", function() this.owner:castweapononleave("Weapon Seals",self.frames.weaponbuff) end)

		-- Weapon Buff menu
		self.frames.weaponbuffmenu = CreateFrame("Frame", nil, self.frames.weaponbuff )
		self.frames.weaponbuffmenu.owner = self
		self.frames.weaponbuffmenu:SetWidth(1)
		self.frames.weaponbuffmenu:SetHeight(1)
		self.frames.weaponbuffmenu:SetPoint("TOPRIGHT", self.frames.weaponbuff, "TOPRIGHT" )
		self.frames.weaponbuffmenu:Hide()

		self.frames.sor = CreateFrame("Button", nil, self.frames.weaponbuffmenu )
		self.frames.sor.owner = self
		self.frames.sor:SetWidth(26)
		self.frames.sor:SetHeight(26)
		self.frames.sor:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Ability_ThunderBolt")
		self.frames.sor:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.sor:SetPoint("TOPRIGHT", self.frames.weaponbuffmenu, "TOPRIGHT", 32, 0 )
		self.frames.sor:SetScript("OnClick", function() this.owner:castweapon( this.owner.spells.normal["SOR"] ) end )		
        self.frames.sor:SetScript("OnEnter", function() this.owner:castweapononenter("Seal of Righteousness",self.frames.sor) end)
		self.frames.sor:SetScript("OnLeave", function() this.owner:castweapononleave("Seal of Righteousness",self.frames.sor) end)
		
		self.frames.sotc = CreateFrame("Button", nil, self.frames.weaponbuffmenu )
		self.frames.sotc.owner = self
		self.frames.sotc:SetWidth(26)
		self.frames.sotc:SetHeight(26)
		self.frames.sotc:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_HolySmite")
		self.frames.sotc:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.sotc:SetPoint("TOPRIGHT", self.frames.weaponbuffmenu, "TOPRIGHT", 64, 0 )
		self.frames.sotc:SetScript("OnClick", function() this.owner:castweapon( this.owner.spells.normal["SOTC"] ) end )		
		self.frames.sotc:SetScript("OnEnter", function() this.owner:castweapononenter("Seal of the Crusader",self.frames.sotc) end)
		self.frames.sotc:SetScript("OnLeave", function() this.owner:castweapononleave("Seal of the Crusader",self.frames.sotc) end)
		
		self.frames.sol = CreateFrame("Button", nil, self.frames.weaponbuffmenu )
		self.frames.sol.owner = self
		self.frames.sol:SetWidth(26)
		self.frames.sol:SetHeight(26)
		self.frames.sol:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_HealingAura")
		self.frames.sol:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.sol:SetPoint("TOPRIGHT", self.frames.weaponbuffmenu, "TOPRIGHT", 96, 0 )
		self.frames.sol:SetScript("OnClick", function() this.owner:castweapon( this.owner.spells.normal["SOL"] ) end )		
		self.frames.sol:SetScript("OnEnter", function() this.owner:castweapononenter("Seal of Light",self.frames.sol) end)
		self.frames.sol:SetScript("OnLeave", function() this.owner:castweapononleave("Seal of Light",self.frames.sol) end)
		
		self.frames.sow = CreateFrame("Button", nil, self.frames.weaponbuffmenu )
		self.frames.sow.owner = self
		self.frames.sow:SetWidth(26)
		self.frames.sow:SetHeight(26)
		self.frames.sow:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Holy_RighteousnessAura")
		self.frames.sow:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.sow:SetPoint("TOPRIGHT", self.frames.weaponbuffmenu, "TOPRIGHT", 128, 0 )
		self.frames.sow:SetScript("OnClick", function() this.owner:castweapon( this.owner.spells.normal["SOW"] ) end )		
		self.frames.sow:SetScript("OnEnter", function() this.owner:castweapononenter("Seal of Wisdom",self.frames.sow) end)
		self.frames.sow:SetScript("OnLeave", function() this.owner:castweapononleave("Seal of Wisdom",self.frames.sow) end)
		
		-- Shield Buffs button
		self.frames.shieldbuff = CreateFrame("Button", nil, self.frames.main )
		self.frames.shieldbuff.owner = self
		self.frames.shieldbuff:SetWidth(38)
		self.frames.shieldbuff:SetHeight(38)
		self.frames.shieldbuff:SetPoint("CENTER", self.frames.main, "CENTER", 46.19, -19.13 )
		self.frames.shieldbuff:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Nature_LightningShield" )
		self.frames.shieldbuff:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.shieldbuff:SetScript("OnClick", function() this.owner:CastBOS( this.owner.spells.normal["BOS"] ) end )
		self.frames.shieldbuff:SetScript("OnEnter", function() this.owner:castshieldonenter("Blessing of Sanctuary",self.frames.shieldbuff) end)
		--self.frames.shieldbuff:SetScript("OnLeave", function() this.owner:castshieldonleave("Shields",self.frames.shieldbuff) end)

		-- Shield Buff menu
		self.frames.shieldbuffmenu = CreateFrame("Frame", nil, self.frames.shieldbuff )
		self.frames.shieldbuffmenu.owner = self
		self.frames.shieldbuffmenu:SetWidth(1)
		self.frames.shieldbuffmenu:SetHeight(1)
		self.frames.shieldbuffmenu:SetPoint("TOPRIGHT", self.frames.shieldbuff, "TOPRIGHT" )
		self.frames.shieldbuffmenu:Hide()
		stx = 32

		self.frames.ls = CreateFrame("Button", nil, self.frames.shieldbuffmenu )
		self.frames.ls.owner = self
		self.frames.ls:SetWidth(38)
		self.frames.ls:SetHeight(38)
		self.frames.ls:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Spell_Nature_LightningShield")
		self.frames.ls:SetHighlightTexture( "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight" )
		self.frames.ls:SetPoint("TOPRIGHT", self.frames.shieldbuffmenu, "TOPRIGHT", stx, 0 )
		self.frames.ls:SetScript("OnClick", function() this.owner:castshield( this.owner.spells.normal["LS"] ) end )		
		self.frames.ls:SetScript("OnEnter", function() this.owner:castshieldonenter("Lighting",self.frames.shieldbuff) end)
		self.frames.ls:SetScript("OnLeave", function() this.owner:castshieldonleave("Lighting",self.frames.shieldbuff) end)

		-- Spelltimers
		self.frames.timers = CreateFrame("Button", nil, self.frames.main )
		self.frames.timers.owner = self
		self.frames.timers:SetMovable(true)
		self.frames.timers:EnableMouse(true)
		self.frames.timers:SetWidth(150)
		self.frames.timers:SetHeight(25)
		self.frames.timers:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = false, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 5, right =5, top = 5, bottom = 5 }})


		self.frames.timers:SetBackdropColor( 0.7, 0, 0.7, 1 )
		self.frames.timers:SetBackdropBorderColor( 1, 1, 1, 1)
		if( self:GetOpt("timerx") and self:GetOpt("timery") ) then
			x = self:GetOpt("timerx")
			y = self:GetOpt("timery")
			self.frames.timers:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y )
		else
			self.frames.timers:SetPoint("TOPLEFT", self.frames.main, "BOTTOM", 60, 40)
		end
		self.frames.timers:RegisterForDrag("LeftButton")
		self.frames.timers:SetScript("OnDragStart", function() this:StartMoving() end )
		self.frames.timers:SetScript("OnDragStop", 
			function() 
				this:StopMovingOrSizing()
				local _,_,_,x,y = this:GetPoint("TOPLEFT")
				this.owner:SetOpt("timerx", x)
				this.owner:SetOpt("timery", y)
			end
		)
		
		self.frames.timersheader = self.frames.timers:CreateFontString(nil, "OVERLAY")
		self.frames.timersheader.owner = self
		self.frames.timersheader:SetFontObject(GameFontNormalSmall)
		self.frames.timersheader:ClearAllPoints()
		self.frames.timersheader:SetTextColor(1, 1,1, 1)
		self.frames.timersheader:SetPoint("CENTER", self.frames.timers, "CENTER", 0, 1 )
		self.frames.timersheader:SetJustifyH("CENTER")
		self.frames.timersheader:SetJustifyV("MIDDLE")
		self.frames.timersheader:SetText( Crusader_CONST.Timerheader )

		
		self.frames.timerstext = self.frames.timers:CreateFontString(nil, "OVERLAY")
		self.frames.timerstext.owner = self
		self.frames.timerstext:SetFontObject(GameFontNormalSmall)
		self.frames.timerstext:ClearAllPoints()
		self.frames.timerstext:SetTextColor(0.8, 0.8, 1, 1)
		self.frames.timerstext:SetPoint("TOPLEFT", self.frames.timers, "TOPLEFT", 10, -6 )
		self.frames.timerstext:SetJustifyH("LEFT")
		self.frames.timerstext:SetJustifyV("MIDDLE")
		self.frames.timerstext:SetWidth(200)
		self.frames.timerstext:SetText( "" )

		self:UpdateFrameLocks()
	end,

	UpdateShardCount = function( self )
		mana_perc = math.floor((UnitMana('player') * 16 / UnitManaMax('player')) + 0.5);
		mana_string = (math.floor((UnitMana('player') * 100 / UnitManaMax('player')) + 0.5))..'%\n'..UnitMana('player');
		self.shardcount = mana_string
		if( mana_perc >= 16 ) then
		    self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard16") 
		elseif ( mana_perc < 16 ) and ( mana_perc >= 15 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard15") 
		elseif ( mana_perc < 15 ) and ( mana_perc >= 14 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard14") 
		elseif ( mana_perc < 14 ) and ( mana_perc >= 13 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard13") 
		elseif ( mana_perc < 13 ) and ( mana_perc >= 12 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard12") 
		elseif ( mana_perc < 12 ) and ( mana_perc >= 11 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard11") 
		elseif ( mana_perc < 11 ) and ( mana_perc >= 10 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard10") 
		elseif ( mana_perc < 10 ) and ( mana_perc >= 9 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard9") 
		elseif ( mana_perc < 9 ) and ( mana_perc >= 8 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard8") 
		elseif ( mana_perc < 8 ) and ( mana_perc >= 7 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard7") 
		elseif ( mana_perc < 7 ) and ( mana_perc >= 6 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard6") 
		elseif ( mana_perc < 6 ) and ( mana_perc >= 5 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard5") 
		elseif ( mana_perc < 5 ) and ( mana_perc >= 4 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard4") 
		elseif ( mana_perc < 4 ) and ( mana_perc >= 3 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard3") 
		elseif ( mana_perc < 3 ) and ( mana_perc >= 2 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard2") 
		elseif ( mana_perc < 2 ) and ( mana_perc >= 1 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard1") 
		elseif ( mana_perc < 1 ) and ( mana_perc >= 0 ) then
			self.frames.shard:SetNormalTexture( "Interface\\AddOns\\Crusader\\Images\\Solid\\Shards\\Shard0") 
		end
		
		self.frames.shardtext:SetText(""..self.shardcount )		
	end,

	UpdateOtherButtons = function( self ) 
	
	if( not self.spells.normal["BOM"]) then
			self.frames.bom:Hide()
		else
			self.frames.bom:Show()
	end
	if( not self.spells.normal["BOW"] ) then
			self.frames.bow:Hide()
		else
			self.frames.bow:Show()
	end
	if( not self.spells.normal["BOK"] ) then
			self.frames.bok:Hide()
		else
			self.frames.bok:Show()
	end
	if( not self.spells.normal["BOF"] ) then
		self.frames.bof:Hide()
	else
		self.frames.bof:Show()
	end
	--if( not self.spells.normal["BOL"] ) then
	--	self.frames.bol:Hide()
	--else
	--	self.frames.bol:Show()
	--end
	if( not self.spells.normal["BOP"] ) then
		self.frames.bop:Hide()
	else
		self.frames.bop:Show()
	end
	
	if( not self.spells.normal["SOR"] ) then
			self.frames.sor:Hide()
		else
			self.frames.sor:Show()
	end
	
	-- flame tongue weaponbuff
	if( not self.spells.normal["SOTC"] ) then
			self.frames.sotc:Hide()
		else
			self.frames.sotc:Show()
	end
	-- frost brand
	if( not self.spells.normal["SOL"] ) then
			self.frames.sol:Hide()
		else
			self.frames.sol:Show()
	end
	-- wind fury we
	if( not self.spells.normal["SOW"] ) then
			self.frames.sow:Hide()
		else
			self.frames.sow:Show()
	end
	-- posion
	
	-- lighting shield
	if( not self.spells.normal["LS"] ) then
			self.frames.ls:Hide()
		else
			self.frames.ls:Show()
	end



	end,

	UpdateTimers = function( self )
		local mindex, sindex, duration, text, tleft, gradient
		
		self.timerstext = ""
		
		for mindex in pairs(self.timers) do
			if( self.timers[mindex]["name"] ) then
				self.timerstext = self.timerstext .. "\n\n".."|cffffffff"..self.timers[mindex]["name"].."|r"
				for sindex in pairs(self.timers[mindex]) do
					if( sindex ~= "name" and sindex ~= "nr" ) then
						duration = Timex:ScheduleCheck("Paladin Timers "..mindex..sindex, TRUE)
						--duration = 30
						if( duration ) then
							-- tleft = floor(self.timers[mindex][sindex]["duration"] - duration)
							tleft = floor( duration )
							text = self:BuildTime(tleft)
							gradient = self:GetGradient( floor((tleft/self.timers[mindex][sindex]["duration"])*100) )
							self.timerstext = self.timerstext .. "   "..gradient.." "..text.."|r"
						else
							self.timerstext = self.timerstext .. "\n  "..sindex.." no timer "
						end
					end
				end
			end
		end
		
		self.frames.timerstext:SetText(self.timerstext)
	end,

	UpdateButtons = function( self )
		--self:UpdateShardCount()
		--self:UpdateHealthstone()
		--self:UpdateSoulstone()
		--self:UpdateFirestone()
		--self:UpdateSpellstone()

		self:UpdateOtherButtons()
	end,

	UpdateFrameLocks = function( self )
		if( self:GetOpt("lock") ) then
			self.frames.timers:SetMovable(false)
			self.frames.timers:SetBackdrop(nil)
			self.frames.timers:SetBackdropColor(0,0,0,0)
			self.frames.timers:SetBackdropBorderColor(0,0,0,0)
			self.frames.main:SetMovable(false)
			self.frames.timers:RegisterForDrag()
			self.frames.shard:RegisterForDrag()
		else
			self.frames.timers:SetMovable(true)
			self.frames.timers:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	                                            tile = false, tileSize = 16, edgeSize = 16, 
	                                            insets = { left = 5, right =5, top = 5, bottom = 5 }})
			--self.frames.timers:SetBackdropColor( 0.00,0.44,0.87, 1 )
			self.frames.timers:SetBackdropColor( 0.98,0.37,0.96, .72 )
			self.frames.timers:SetBackdropBorderColor( 1, 1, 1, 1)
			self.frames.main:SetMovable(true)
			self.frames.timers:RegisterForDrag("LeftButton")
			self.frames.shard:RegisterForDrag("LeftButton")
		end
	end,
----------------------------
-- ButtonClicks           --
----------------------------

	HealthstoneClicked = function( self )
		if( self.healthstone[0] ~= nil ) then
			if( UnitExists("target") and UnitIsPlayer("target") and not UnitIsEnemy("target", "player") and UnitName("target") ~= UnitName("player") ) then
				if( not UnitCanCooperate("player", "target")) then
					self:Msg( Crusader_CONST.Message.Busy )
				elseif (not CheckInteractDistance("target",2)) then
					self:Msg( Crusader_CONST.Message.TooFarAway )
				else
					PickupContainerItem( self.healthstone[0], self.healthstone[1] )
					if ( CursorHasItem() ) then
						DropItemOnUnit("target")
						Timex:AddSchedule("Crusader Healthstone Trade", 3, nil, nil, "AcceptTrade", "" )
					end
				end
			elseif( (UnitHealth("player") < UnitHealthMax("player")) and GetContainerItemCooldown(self.healthstone[0],self.healthstone[1]) == 0) then
				UseContainerItem( self.healthstone[0], self.healthstone[1] )
			end
		else
			CastSpell( self.spells.normal["HEALTHSTONE"], BOOKTYPE_SPELL )
		end
	end,



	BlessingsClicked = function( self )
	    --if not ( self.spells.normal["BOS"] ) then
		  if ( self.frames.blessingsmenu.opened ) then
			  self.frames.blessingsmenu:Hide()
			  self.frames.blessingsmenu.opened = FALSE
		  else
			  self.frames.blessingsmenu:Show()
			  self.frames.blessingsmenu.opened = TRUE
		  end
		--end
	end,

    ETOnEnter = function(self)
        GameTooltip:Hide()
        GameTooltip:SetOwner(self.frames.blessingsmenu, "ANCHOR_RIGHT")
        --GameTooltip:AddLine("|cFFFFFFFF" .. self.frames.earthtotemmenu.tooltipTitle)
        GameTooltip:AddLine("Blessings")
        GameTooltip:Show()
    end,
	
	ETOnExit = function(self)
        GameTooltip:Hide() 
    end,

	FireTotemClicked = function( self )
	    --if( self.spells.normal["EARTH"] ) then
		--	CastSpell( self.spells.normal["EARTH"], BOOKTYPE_SPELL )
		--end
		if( self.frames.firetotemmenu.opened ) then
			self.frames.firetotemmenu:Hide()
			self.frames.firetotemmenu.opened = FALSE
		else
			self.frames.firetotemmenu:Show()
			self.frames.firetotemmenu.opened = TRUE
		end
	end,

	AirTotemClicked = function( self )
	    --if( self.spells.normal["EARTH"] ) then
		--	CastSpell( self.spells.normal["EARTH"], BOOKTYPE_SPELL )
		--end
		if( self.frames.airtotemmenu.opened ) then
			self.frames.airtotemmenu:Hide()
			self.frames.airtotemmenu.opened = FALSE
		else
			self.frames.airtotemmenu:Show()
			self.frames.airtotemmenu.opened = TRUE
		end
	end,

	WaterTotemClicked = function( self )
	    --if( self.spells.normal["EARTH"] ) then
		--	CastSpell( self.spells.normal["EARTH"], BOOKTYPE_SPELL )
		--end
		if( self.frames.watertotemmenu.opened ) then
			self.frames.watertotemmenu:Hide()
			self.frames.watertotemmenu.opened = FALSE
		else
			self.frames.watertotemmenu:Show()
			self.frames.watertotemmenu.opened = TRUE
		end
	end,
	
	WeaponBuffClicked = function( self )
	    --if( self.spells.normal["EARTH"] ) then
		--	CastSpell( self.spells.normal["EARTH"], BOOKTYPE_SPELL )
		--end
		if( self.frames.weaponbuffmenu.opened ) then
			self.frames.weaponbuffmenu:Hide()
			self.frames.weaponbuffmenu.opened = FALSE
		else
			self.frames.weaponbuffmenu:Show()
			self.frames.weaponbuffmenu.opened = TRUE
		end
	end,
	
	ShieldBuffClicked = function( self )
		if( self.frames.shieldbuffmenu.opened ) then
			self.frames.shieldbuffmenu:Hide()
			self.frames.shieldbuffmenu.opened = FALSE
		else
			self.frames.shieldbuffmenu:Show()
			self.frames.shieldbuffmenu.opened = TRUE
		end
	end,
	
	MountClicked = function( self )
		if( self.spells.normal["MOUNT"] ) then
			CastSpell( self.spells.normal["MOUNT"], BOOKTYPE_SPELL )
		end
	end,
	
	HearthClicked = function( self, LeftButton )
		
	if( self.frames.hearthbuffmenu.opened ) then
			self.frames.hearthbuffmenu:Hide()
			self.frames.hearthbuffmenu.opened = FALSE
		else
			self.frames.hearthbuffmenu:Show()
			self.frames.hearthbuffmenu.opened = TRUE
		end
	    
	end,
	
			
----------------------------
-- WoW Event Handlers     --
----------------------------

	BAG_UPDATE = function( self )		
		local bag = arg1
		Timex:AddSchedule("Crusader Bag Update", 0.5, nil, nil, "Crusader_BAG_UPDATE", Crusader )
	end,

	SPELLS_CHANGED = function( self )
		self:ScanSpells()
		self:UpdateButtons()
	end,

	SPELLCAST_START = function( self )
		-- self:Msg("SPELLCAST_START: "..arg1 )
		if( self.currentspell.state ) then
			if( self.currentspell.state == Crusader_CONST.State.Cast ) then
				self.currentspell.state = Crusader_CONST.State.Start
				-- we have started casting
			else
				-- I want nothing do do with this cast
				self.Compost:Erase(self.currentspell)
			end
		end
		self.soulstonestate = nil
		if( arg1 == Crusader_CONST.Pattern.SoulstoneResurrection ) then
			if( UnitName("target") ) then
				self.soulstonetimer = 1
				self.soulstonetarget = "["..UnitLevel("target").."] "..UnitName("target")
				self.soulstonename = UnitName("target")
				self:SendChatMessage(string.format( Crusader_CONST.Message.PreSoulstone, UnitName("target") ) )
				
			end
		elseif( arg1 == Crusader_CONST.Pattern.RitualOfSummoning ) then
			if( UnitName("target") ) then
				self:SendChatMessage(string.format( Crusader_CONST.Message.PreSummon, UnitName("target") ) )
				self.presummoncount = self.shardcount
				self.summoning = true
				self.summonvictim = UnitName("target")
			end
		end
	end,

	SPELLCAST_FAILED = function( self )
		-- self:Msg("SPELLCAST_FAILED" )
		if( self.currentspell.state ) then
			self.currentspell.state = Crusader_CONST.State.Failed
		end
	end,

	SPELLCAST_STOP = function( self )
		-- self:Msg("SPELLCAST_STOP" )
		if( self.currentspell.state and self.currentspell.state < Crusader_CONST.State.Stop ) then
			self.currentspell.state = Crusader_CONST.State.Stop
			self:TimerAddSpell()
		end
		if( self.soulstonetimer and self.soulstonetimer == 1 ) then
			self.soulstonetimer = 2
			self.soulstonestate = 1
			Timex:AddSchedule("Crusader Soulstone Timer", 1800, nil, nil, Crusader.DeleteSoulstoneTimer, Crusader )
			self:SendChatMessage(string.format( Crusader_CONST.Message.Soulstone, self.soulstonename ) )		
		end
	end,

	SPELLCAST_INTERRUPTED = function( self )
		-- self:Msg("SPELLCAST_INTERRUPTED" )
		if( self.currentspell.state and self.currentspell.state > Crusader_CONST.State.Stop ) then
			self:TimerRollback()
		end
		if( self.soulstonetimer and self.soulstonestate ) then
			self.soulstonetimer = nil
			self.soulstonestate = nil
			Timex:DeleteSchedule("Crusader Soulstone Timer")
			self:SendChatMessage( Crusader_CONST.Message.SoulstoneAborted )
		end
	end,

	SPELLCAST_CHANNEL_START = function( self )
		-- self:Msg("SPELLCAST_CHANNEL_START: "..arg1)
		if( self.currentspell.state ) then
			if( self.currentspell.state == Crusader_CONST.State.Cast ) then
				self.currentspell.state = Crusader_CONST.State.Start
				-- we have started casting
			end
		end
	end,

	SPELLCAST_CHANNEL_STOP = function( self )
		-- self:Msg("SPELLCAST_CHANNEL_STOP")
		if( self.summoning ) then
			self:ScanStones()
			if( self.shardcount >= self.summoncount ) then
				-- failed summoning
				self:SendChatMessage( string.format( Crusader_CONST.Message.FailedSummon, self.summonvictim) )
			end
			self.summoning = nil
		end
	end,

	PLAYER_REGEN_ENABLED = function( self )
		self:ClearTimers()
	end,

	CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS = function( self )
		if( self:GetOpt("shadowtrancesound") and string.find( arg1, Crusader_CONST.Pattern.ShadowTrance ) ) then
			PlaySoundFile("Interface\\AddOns\\Crusader\\Sounds\\ShadowTrance.mp3")
		end
	end,

	CHAT_MSG_SPELL_SELF_DAMAGE = function( self )
		if( self.currentspell.state and self.currentspell.state > Crusader_CONST.State.Stop ) then
			if( string.find( arg1, Crusader_CONST.Pattern.Resisted ) or 
				string.find( arg1, Crusader_CONST.Pattern.Immune ) ) then
				self:TimerRollback()
			end
		end		
	end,

----------------------------
-- My Event Handlers      --
----------------------------

	Crusader_BAG_UPDATE = function( self )
		self:ScanHearth()
		--self:UpdateShardCount()
		--self:UpdateHealthstone()
		--self:UpdateSoulstone()
		--self:UpdateSpellstone()
		--self:UpdateFirestone()
	end,


	Heartbeat = function( self)
		self:UpdateTimers()
		self:UpdateShardCount()
		self:ScanHearth()
	end,

----------------------------
-- My Hooks               --
----------------------------
	
	OnCastSpell = function( self, spellid, spellbooktab )
		-- self:Msg( "OnCastSpell: "..spellid..", "..spellbooktab)

		self:CallHook("CastSpell", spellid, spellbooktab )

		if( self.spells.timedid[spellid] ) then
			self:RegisterSpellCast( self.spells.timedid[spellid] )
		end

	end,

	OnCastSpellByName = function( self, spellname )
		-- self:Msg("OnCastSpellByName: "..spellname )

		self:CallHook("CastSpellByName", spellname )

		if( self.spells.timed[strlower(spellname)] ) then
			self:RegisterSpellCast( strlower(spellname) )
		elseif( self.spells.timedname[strlower(spellname)] ) then
			self:RegisterSpellCast( self.spells.timedname[strlower(spellname)] )
		end

	end,

	OnUseAction = function( self, actionid, a2, a3)
		-- self:Msg("OnUseAction: "..actionid )

		self:CallHook("UseAction", actionid, a2, a3 )

		CrusaderTooltip:SetAction(actionid)

		local lefttext = CrusaderTooltipTextLeft1:GetText()
		local righttext = CrusaderTooltipTextRight1:GetText()

		if( lefttext ) then

			if( righttext ) then
				righttext = lefttext.." "..righttext
			else
				righttext = lefttext
			end
			
			lefttext = strlower( lefttext )
			righttext = strlower( righttext )

			if( self.spells.timed[lefttext] ) then
				self:RegisterSpellCast( lefttext )
			elseif( self.spells.timed[righttext] ) then
				self:RegisterSpellCast( righttext ) 
			end
		end


	end,

	-- Not using this for now
	OnUseContainerItem = function( self, index, slot )
		self:Msg("OnUseContainerItem: "..index..", "..slot )
		return self:CallHook("UseContainerItem", index, slot )
	end,

----------------------------
-- Chat       	          --
----------------------------

	chatReset = function( self )
		self.frames.main:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 150, -150)
		self.frames.timers:SetPoint("TOPLEFT", self.frames.main, "BOTTOM", 60, 40)
	end,

	chatFelDom = function( self, modifier ) 
		if( modifier == "ctrl" ) then
			self:SetOpt("feldommodifier", "ctrl")
		elseif( modifier == "alt" ) then
			self:SetOpt("feldommodifier", "alt") 
		elseif( modifier == "shift" ) then
			self:SetOpt("feldommodifier", "shift") 
		elseif( modifier == "none" ) then
			self:SetOpt("feldommodifier", nil )
		else
			self:Msg( Crusader_CONST.Chat.FelDomValid )
		end
		if( self:GetOpt("feldommodifier") ) then
			self:Msg( Crusader_CONST.Chat.FelDomModifier .. self:GetOpt("feldommodifier") )
		else
			self:Msg( Crusader_CONST.Chat.FelDomModifier .. "none" )
		end
	end,


	chatCloseClick = function( self )
		self:TogOpt("closeonclick")
		self:Msg(Crusader_CONST.Chat.CloseOnClick, ACEG_MAP_ONOFF[self:GetOpt("closeonclick") or 0])		
	end,


	chatShadowTranceSound = function( self )
		self:TogOpt("shadowtrancesound")
		self:Msg(Crusader_CONST.Chat.ShadowTranceSound, ACEG_MAP_ONOFF[self:GetOpt("shadowtrancesound") or 0])
	end,
	
	chatSoulstoneSound = function( self )
		self:TogOpt("soulstonesound")
		self:Msg(Crusader_CONST.Chat.SoulstoneSound, ACEG_MAP_ONOFF[self:GetOpt("soulstonesound") or 0])
	end,

	chatTimers = function( self )
		self:TogOpt("timers")
		self:Msg(Crusader_CONST.Chat.Timers, ACEG_MAP_ONOFF[self:GetOpt("timers") or 0])
		if( self:GetOpt("timers") ) then
			self.Metrognome:Start("Crusaderr")
			self.frames.timers:Show()
		else
			self.Metrognome:Stop("Crusaderr")
			self.frames.timers:Hide()
		end
	end,


	chatLock = function( self )
		self:TogOpt("lock")
		self:Msg(Crusader_CONST.Chat.Lock, ACEG_MAP_ONOFF[self:GetOpt("lock") or 0])
		self:UpdateFrameLocks()
	end,

	chatTexture = function( self, texture )
		if( texture == "default" ) then
			self:SetOpt("texture", nil)
		elseif( texture == "blue" ) then
			self:SetOpt("texture", "Blue")
		elseif( texture == "orange" ) then
			self:SetOpt("texture", "Orange")
		elseif( texture == "rose" ) then
			self:SetOpt("texture", "Rose")
		elseif( texture == "turquoise" ) then
			self:SetOpt("texture", "Turquoise")
		elseif( texture == "violet" ) then
			self:SetOpt("texture", "Violet")
		elseif( texture == "x" ) then
			self:SetOpt("texture", "X")
		else
			self:Msg( Crusader_CONST.Chat.TextureValid )
		end
		if( self:GetOpt("texture") ) then
			self:Msg( Crusader_CONST.Chat.Texture .. self:GetOpt("texture") )
		else
			self:Msg( Crusader_CONST.Chat.Texture .. "default" )
		end
		--self:UpdateShardCount()
	end,




	Report = function( self )
		if( self:GetOpt("texture") ) then
			self:Msg( Crusader_CONST.Chat.Texture .. self:GetOpt("texture") )
		else
			self:Msg( Crusader_CONST.Chat.Texture .. "default" )
		end
		if( self:GetOpt("feldommodifier") ) then
			self:Msg( Crusader_CONST.Chat.FelDomModifier .. self:GetOpt("feldommodifier") )
		else
			self:Msg( Crusader_CONST.Chat.FelDomModifier .. "none" )
		end
		self:Msg(Crusader_CONST.Chat.CloseOnClick, ACEG_MAP_ONOFF[self:GetOpt("closeonclick") or 0])
		self:Msg(Crusader_CONST.Chat.SoulstoneSound, ACEG_MAP_ONOFF[self:GetOpt("soulstonesound") or 0])
		self:Msg(Crusader_CONST.Chat.ShadowTranceSound, ACEG_MAP_ONOFF[self:GetOpt("shadowtrancesound") or 0])
		self:Msg(Crusader_CONST.Chat.Lock, ACEG_MAP_ONOFF[self:GetOpt("lock") or 0])
	end,

	-- Command Reporting Closures

	GetOpt = function(self, path, var)
		if (not var) then var = path; path = nil; end
		local profilePath = path and {self.profilePath, path} or self.profilePath;
	   
		return self.db:get(profilePath, var)
	end,
	
	SetOpt = function(self, path, var, val)
		if (not val) then val = var; var = path; path = nil; end
		local profilePath = path and {self.profilePath, path} or self.profilePath;
	
		return self.db:set(profilePath, var, val)
	end,
	
	TogOpt = function(self, path, var)
		if (not var) then var = path; path = nil; end
		local profilePath = path and {self.profilePath, path} or self.profilePath;
	
		return self.db:toggle(profilePath, var)
	end,

	Msg = function(self, ...)
	   self.cmd:result(Crusader_MSG_COLOR, unpack(arg))
	end,
	
	Result = function(self, text, val, map)
	   if( map ) then val = map[val or 0] or val end
	   self.cmd:result(Crusader_MSG_COLOR, text, " ", ACEG_TEXT_NOW_SET_TO, " ",
		       format(Crusader_DISPLAY_OPTION, val or ACE_CMD_REPORT_NO_VAL)
		       )
	end,

	
	TogMsg = function(self, var, text)
	   local val = self:TogOpt(var)
	   self:Result(text, val, ACEG_MAP_ONOFF)
	   return val
	end,
	
	Error = function(self, ...)
	   local text = "";
	   for i=1,getn(arg) do
	      text = text .. arg[i]
	   end
	   error(Crusader_MSG_COLOR .. text, 2)
	end,
	
	
})

----------------------------------
--			Load this bitch up!			--
----------------------------------
Crusader:RegisterForLoad()

