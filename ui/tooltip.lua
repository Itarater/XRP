--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local addonName, _xrp = ...

local currentUnit = {
	lines = {},
}

local Tooltip, replace, rendering

local GTTL, GTTR = "GameTooltipTextLeft%d", "GameTooltipTextRight%d"

local RenderTooltip
do
	local TruncateLine
	do
		local SINGLE, DOUBLE = "%s", "%s\n%s"
		local SINGLE_TRUNC, DOUBLE_TRUNC = SINGLE .. CONTINUED, DOUBLE .. CONTINUED
		function TruncateLine(text, length, offset, double)
			if not text then return end
			if not offset then offset = 0 end
			text = text:gsub("\n+", " ")
			local textLen = strlenutf8(text)
			local line1, line2 = text
			local isTruncated = false
			if textLen > length - offset then
				local nextText = text:match("(.-) ")
				if nextText and strlenutf8(nextText) <= length - offset then
					local position = #nextText
					local nextPos = text:find(" ", position + 1, true)
					while nextPos and strlenutf8(nextText) <= length - offset do
						position = nextPos
						nextPos = text:find(" ", nextPos + 1, true)
						nextText = nextPos and text:sub(1, nextPos - 1) or nil
					end
					line1 = text:sub(1, position - 1)
					if double ~= false then
						local lineLen, linePos = strlenutf8(line1), position + 1
						if textLen - lineLen > lineLen + offset then
							nextPos = text:find(" ", linePos, true)
							nextText = nextPos and text:sub(linePos, nextPos - 1) or nil
							while nextPos and strlenutf8(nextText) <= lineLen + offset - 3 do
								position = nextPos
								nextPos = text:find(" ", nextPos + 1, true)
								nextText = nextPos and text:sub(linePos, nextPos - 1) or nil
							end
							if position > linePos then
								line2 = text:sub(linePos, position - 1)
							end
							isTruncated = true
						else
							line2 = text:sub(linePos)
						end
					else
						isTruncated = true
					end
				else
					local chars = {}
					for char in text:gmatch("[\1-\127\192-\255][\128-\191]*") do
						chars[#chars + 1] = char
					end
					local line1t = {}
					for i = 1, length - offset do
						line1t[i] = chars[i]
					end
					line1 = table.concat(line1t)
					if double ~= false then
						local line2t = {}
						for i = #line1t + 1, #line1t * 2 + offset - 3 do
							line2t[#line2t + 1] = chars[i]
						end
						line2 = table.concat(line2t)
						if #chars > #line1t + #line2t then
							isTruncated = true
						end
					else
						isTruncated = true
					end
				end
			end
			return (line2 and (isTruncated and DOUBLE_TRUNC or DOUBLE) or isTruncated and SINGLE_TRUNC or SINGLE):format(line1, line2)
		end
	end

	local ParseVersion
	do
		local PROFILE_ADDONS = {
			["XRP"] = "XRP",
			["MYROLEPLAY"] = "MRP",
			["TOTALRP2"] = "TRP2",
			["TOTALRP3"] = "TRP3",
			["GNOMTEC_BADGE"] = "GTEC",
			["FLAGRSP"] = "RSP",
		}
		local EXTRA_ADDONS = {
			["GHI"] = "GHI",
			["TONGUES"] = "T",
		}
		function ParseVersion(VA)
			if not VA then return end
			local short, hasProfile = {}
			for addon in VA:upper():gmatch("([^/;]+)/[^/;]+") do
				if PROFILE_ADDONS[addon] and not hasProfile then
					short[#short + 1] = PROFILE_ADDONS[addon]
					hasProfile = true
				elseif EXTRA_ADDONS[addon]then
					short[#short + 1] = EXTRA_ADDONS[addon]
				end
			end
			if not hasProfile then
				-- They must have some sort of addon, just not a known one.
				table.insert(short, 1, "RP")
			end
			return table.concat(short, PLAYER_LIST_DELIMITER)
		end
	end

	local oldLines, lineNum = 0, 0
	local function RenderLine(left, right, lR, lG, lB, rR, rG, rB)
		if not left and not right then return end
		rendering = true
		lineNum = lineNum + 1
		-- First case: If there's already a line to replace. This only happens
		-- if using the GameTooltip, as XRPTooltip is cleared before rendering
		-- starts.
		if lineNum <= oldLines then
			local LeftLine = _G[GTTL:format(lineNum)]
			local RightLine = _G[GTTR:format(lineNum)]
			-- Can't have an empty left text line ever -- if a line exists, it
			-- needs to have a space at minimum to not muck up line spacing.
			LeftLine:SetText(left or " ")
			LeftLine:SetTextColor(lR or 1, lG or 0.82, lB or 0)
			LeftLine:Show()
			if right then
				RightLine:SetText(right)
				RightLine:SetTextColor(rR or 1, rG or 0.82, rB or 0)
				RightLine:Show()
			else
				RightLine:Hide()
			end
		else -- Second case: If there are no more lines to replace.
			if right then
				Tooltip:AddDoubleLine(left or " ", right, lR or 1, lG or 0.82, lB or 0, rR or 1, rG or 0.82, rB or 0)
			elseif left then
				Tooltip:AddLine(left, lR or 1, lG or 0.82, lB or 0)
			end
		end
		rendering = nil
	end

	local COLORS = {
		OOC = { r = 0.6, g = 0.4, b = 0.3 },
		IC = { r = 0.4, g = 0.7, b = 0.5 },
		Alliance = { r = 0.53, g = 0.56, b = 1 },
		Horde = { r = 1, g = 0.39, b = 0.41 },
		Neutral = { r = 1, g = 0.86, b = 0.36 },
	}
	local REACTION = "FACTION_STANDING_LABEL%d"
	local NI_LENGTH = strlenutf8(xrp.L.FIELDS.NI) + strlenutf8(STAT_FORMAT) + strlenutf8(_xrp.L.NICKNAME) - 2
	local CU_LENGTH = strlenutf8(xrp.L.FIELDS.CU) + strlenutf8(STAT_FORMAT) - 1
	function RenderTooltip()
		oldLines = Tooltip:NumLines()
		lineNum = 0
		local showProfile = not (currentUnit.noProfile or currentUnit.character.hide)
		local fields = currentUnit.character.fields

		if currentUnit.type == "player" then
			if not replace then
				XRPTooltip:ClearLines()
				XRPTooltip:SetOwner(GameTooltip, "ANCHOR_TOPRIGHT")
				if currentUnit.character.hide then
					RenderLine(_xrp.L.HIDDEN, nil, 0.5, 0.5, 0.5)
					XRPTooltip:Show()
					return
				elseif (not showProfile or not fields.VA) then
					XRPTooltip:Hide()
					return
				end
			end
			RenderLine(currentUnit.nameFormat:format(showProfile and TruncateLine(xrp.Strip(fields.NA), 65, 0, false) or xrp.ShortName(tostring(currentUnit.character))), currentUnit.icons)
			if replace and currentUnit.reaction then
				RenderLine(GetText(REACTION:format(currentUnit.reaction), currentUnit.gender), nil, 1, 1, 1)
			end
			if showProfile then
				local NI = fields.NI
				RenderLine(NI and ("|cff6070a0%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.NI), _xrp.L.NICKNAME:format(TruncateLine(xrp.Strip(NI), 70, NI_LENGTH, false))) or nil, nil, 0.6, 0.7, 0.9)
				RenderLine(TruncateLine(xrp.Strip(fields.NT), 70), nil, 0.8, 0.8, 0.8)
			end
			if _xrp.settings.tooltip.extraSpace then
				RenderLine(" ")
			end
			if replace then
				RenderLine(currentUnit.guild, nil, 1, 1, 1)
				local color = COLORS[currentUnit.faction]
				RenderLine(currentUnit.titleRealm, currentUnit.character.hide and _xrp.L.HIDDEN or showProfile and ParseVersion(fields.VA), color.r, color.g, color.b, 0.5, 0.5, 0.5)
				if _xrp.settings.tooltip.extraSpace then
					RenderLine(" ")
				end
			end
			if showProfile then
				local CU = fields.CU
				RenderLine(CU and ("|cffa08050%s|r %s"):format(STAT_FORMAT:format(xrp.L.FIELDS.CU), TruncateLine(xrp.Strip(CU), 70, CU_LENGTH)) or nil, nil, 0.9, 0.7, 0.6)
			end
			RenderLine(currentUnit.info:format(showProfile and not _xrp.settings.tooltip.noRace and TruncateLine(xrp.Strip(fields.RA), 40, 0, false) or xrp.L.VALUES.GR[fields.GR] or UNKNOWN, showProfile and not _xrp.settings.tooltip.noClass and TruncateLine(xrp.Strip(fields.RC), 40, 0, false) or xrp.L.VALUES.GC[fields.GS] and xrp.L.VALUES.GC[fields.GS][fields.GC] or xrp.L.VALUES.GC["1"][fields.GC] or UNKNOWN, 40, 0, false), not replace and ParseVersion(fields.VA), 1, 1, 1, 0.5, 0.5, 0.5)
			if showProfile then
				local FR, FC = fields.FR, fields.FC
				if FR and FR ~= "0" or FC and FC ~= "0" then
					local color = COLORS[FC == "1" and "OOC" or "IC"]
					RenderLine((not FR or FR == "0") and " " or xrp.L.VALUES.FR[FR] or TruncateLine(xrp.Strip(FR), 35, 0, false), FC and FC ~= "0" and (xrp.L.VALUES.FC[FC] or TruncateLine(xrp.Strip(FC), 35, 0, false)) or nil, color.r, color.g, color.b, color.r, color.g, color.b)
				end
			end
			if replace then
				RenderLine(currentUnit.location, nil, 1, 1, 1)
			end
		elseif currentUnit.type == "pet" then
			RenderLine(currentUnit.nameFormat, currentUnit.icons)
			if currentUnit.reaction then
				RenderLine(GetText(REACTION:format(currentUnit.reaction), currentUnit.gender), nil, 1, 1, 1)
			end
			local color = COLORS[currentUnit.faction]
			RenderLine(currentUnit.titleRealm:format(showProfile and TruncateLine(xrp.Strip(fields.NA), 60, 0, false) or xrp.ShortName(tostring(currentUnit.character))), nil, color.r, color.g, color.b)
			RenderLine(currentUnit.info, nil, 1, 1, 1)
		end

		if replace then
			for i, line in ipairs(currentUnit.lines) do
				if line.double then
					RenderLine(unpack(line))
				else
					RenderLine(line[1], nil, unpack(line, 2))
				end
			end
			-- In rare cases (test case: target without RP addon, is PvP
			-- flagged) there will be some leftover lines at the end of the
			-- tooltip. This hides them, if they exist.
			while lineNum < oldLines do
				lineNum = lineNum + 1
				_G[GTTL:format(lineNum)]:Hide()
				_G[GTTR:format(lineNum)]:Hide()
			end
		end

		Tooltip:Show()
	end
end

local SetUnit, active
do
	local COLORS = {
		friendly = "00991a",
		neutral = "e6b300",
		hostile = "cc4d38",
	}
	local PVP_ICON = "|TInterface\\TargetingFrame\\UI-PVP-%s:18:18:4:0:8:8:0:5:0:5|t"
	local FLAG_OFFLINE = CHAT_FLAG_AFK:gsub(AFK, PLAYER_OFFLINE)
	function SetUnit(unit)
		currentUnit.type = UnitIsPlayer(unit) and "player" or replace and (UnitIsOtherPlayersPet(unit) or UnitIsUnit("playerpet", unit)) and "pet" or nil
		if not currentUnit.type then return end

		local defaultLines = 3
		local playerFaction = xrp.current.fields.GF
		local attackMe = UnitCanAttack(unit, "player")
		local meAttack = UnitCanAttack("player", unit)
		if currentUnit.type == "player" then
			currentUnit.character = xrp.characters.byUnit[unit]

			currentUnit.faction = currentUnit.character.fields.GF or "Neutral"

			local connected = UnitIsConnected(unit)
			local color = COLORS[(currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (currentUnit.faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			local watchIcon = _xrp.settings.tooltip.watching and UnitIsUnit("player", unit .. "target") and "|TInterface\\LFGFrame\\BattlenetWorking0:28:28:10:0|t" or nil
			local class, classID = UnitClassBase(unit)

			if replace then
				local colorblind = GetCVar("colorblindMode") == "1"
				-- Can only ever be one of AFK, DND, or offline.
				local isAFK = connected and UnitIsAFK(unit)
				local isDND = connected and not isAFK and UnitIsDND(unit)
				currentUnit.nameFormat = ("|cff%s%%s|r%s"):format(color, not connected and (" |cff888888%s|r"):format(FLAG_OFFLINE) or isAFK and (" |cff99994d%s|r"):format(CHAT_FLAG_AFK) or isDND and (" |cff994d4d%s|r"):format(CHAT_FLAG_DND) or "")

				local ffa = UnitIsPVPFreeForAll(unit)
				local pvpIcon = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction) or nil
				currentUnit.icons = watchIcon and pvpIcon and watchIcon .. pvpIcon or watchIcon or pvpIcon

				local guildName, guildRank, guildIndex = GetGuildInfo(unit)
				currentUnit.guild = guildName and (_xrp.settings.tooltip.guildRank and (_xrp.settings.tooltip.guildIndex and _xrp.L.GUILD_RANK_INDEX or _xrp.L.GUILD_RANK) or _xrp.L.GUILD):format(_xrp.settings.tooltip.guildRank and guildRank or guildName, _xrp.settings.tooltip.guildIndex and guildIndex + 1 or guildName, guildName) or nil

				local realm = tostring(currentUnit.character):match("%-([^%-]+)$")
				if realm == _xrp.realm then
					realm = nil
				end
				local name = UnitPVPName(unit) or xrp.ShortName(tostring(currentUnit.character))
				currentUnit.titleRealm = (colorblind and _xrp.L.ASIDE or "%s"):format(realm and _xrp.L.NAME_REALM:format(name, xrp.RealmDisplayName(realm)) or name, colorblind and xrp.L.VALUES.GF[currentUnit.faction] or nil)

				currentUnit.reaction = colorblind and UnitReaction("player", unit) or nil
				currentUnit.gender = colorblind and UnitSex(unit) or nil

				local level = UnitLevel(unit)
				level = level > 0 and tostring(level) or _xrp.L.LETHAL_LEVEL
				currentUnit.info = (TOOLTIP_UNIT_LEVEL_RACE_CLASS_TYPE):format(level, "%s", ("|c%s%%s|r"):format(RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff"), colorblind and xrp.L.VALUES.GC["1"][classID] or PLAYER)

				local location = connected and not UnitIsVisible(unit) and GameTooltipTextLeft3:GetText() or nil
				currentUnit.location = location and ("|cffffeeaa%s|r %s"):format(ZONE_COLON, location) or nil

				if pvpIcon then
					defaultLines = defaultLines + 1
				end
				if guildName then
					defaultLines = defaultLines + 1
				end
				if colorblind then
					defaultLines = defaultLines + 1
				end
			else
				currentUnit.nameFormat = ("|cff%s%%s|r"):format(color)
				currentUnit.icons = watchIcon
				currentUnit.info = ("%%s |c%s%%s|r"):format(RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff")
			end
		elseif currentUnit.type == "pet" then
			local colorblind = GetCVar("colorblindMode") == "1"
			currentUnit.faction = UnitFactionGroup(unit) or UnitIsUnit(unit, "playerpet") and playerFaction or "Neutral"

			local name = UnitName(unit)
			local color = COLORS[(currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or attackMe and meAttack) and "hostile" or (currentUnit.faction == "Neutral" or meAttack or attackMe) and "neutral" or "friendly"]
			currentUnit.nameFormat = ("|cff%s%s|r"):format(color, name)

			local ffa = UnitIsPVPFreeForAll(unit)
			currentUnit.icons = (UnitIsPVP(unit) or ffa) and PVP_ICON:format((ffa or currentUnit.faction == "Neutral") and "FFA" or currentUnit.faction) or nil

			local ownership = _G[GTTL:format(colorblind and 3 or 2)]:GetText()
			local owner, petType = ownership:match(UNITNAME_TITLE_PET:format("(.+)")), UNITNAME_TITLE_PET
			if not owner then
				owner, petType = ownership:match(UNITNAME_TITLE_MINION:format("(.+)")), UNITNAME_TITLE_MINION
			end

			if not owner then return end
			currentUnit.character = xrp.characters.byName[owner]

			local realm = owner:match("%-([^%-]+)$")
			currentUnit.titleRealm = (colorblind and _xrp.L.ASIDE or "%s"):format(realm and _xrp.L.NAME_REALM:format(petType, xrp.RealmDisplayName(realm)) or petType, colorblind and xrp.L.VALUES.GF[currentUnit.faction] or nil)

			currentUnit.reaction = colorblind and UnitReaction("player", unit) or nil
			currentUnit.gender = colorblind and UnitSex(unit) or nil

			local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			if race == _xrp.L.PET_GHOUL or race == _xrp.L.PET_WATER_ELEMENTAL or race == _xrp.L.PET_MT_WATER_ELEMENTAL then
				race = UnitCreatureType(unit)
			elseif not race then
				race = UNKNOWN
			end
			-- Mages, death knights, and warlocks have minions, hunters have 
			-- pets. Mages and death knights only have one pet family each.
			local classID = petType == UNITNAME_TITLE_MINION and (race == _xrp.L.PET_ELEMENTAL and "MAGE" or race == _xrp.L.PET_UNDEAD and "DEATHKNIGHT" or "WARLOCK") or petType == UNITNAME_TITLE_PET and "HUNTER"
			local level = UnitLevel(unit)
			level = level > 0 and tostring(level) or _xrp.L.LETHAL_LEVEL
			currentUnit.info = TOOLTIP_UNIT_LEVEL_CLASS_TYPE:format(level, ("|c%s%s|r"):format(RAID_CLASS_COLORS[classID] and RAID_CLASS_COLORS[classID].colorStr or "ffffffff", race), colorblind and ("%s %s"):format(xrp.L.VALUES.GC["1"][classID], PET) or PET)

			if currentUnit.icons then
				defaultLines = defaultLines + 1
			end
			if colorblind then
				defaultLines = defaultLines + 1
			end
		end
		currentUnit.noProfile = _xrp.settings.tooltip.noOpFaction and currentUnit.faction ~= playerFaction and currentUnit.faction ~= "Neutral" or _xrp.settings.tooltip.noHostile and attackMe and meAttack

		if replace then
			table.wipe(currentUnit.lines)
			local currentLines = GameTooltip:NumLines()
			if defaultLines < currentLines then
				for i = defaultLines + 1, currentLines do
					local LeftLine = _G[GTTL:format(i)]
					local RightLine = _G[GTTR:format(i)]
					if RightLine:IsVisible() then
						currentUnit.lines[#currentUnit.lines + 1] = { double = true, LeftLine:GetText(), RightLine:GetText(), LeftLine:GetTextColor(), RightLine:GetTextColor() }
					else
						currentUnit.lines[#currentUnit.lines + 1] = { LeftLine:GetText(), LeftLine:GetTextColor() }
					end
				end
			end
		end

		active = true
		RenderTooltip()
	end
end

local function Tooltip_RECEIVE(event, name)
	if not active or name ~= tostring(currentUnit.character) then return end
	local tooltip, unit = GameTooltip:GetUnit()
	if tooltip then
		RenderTooltip()
		-- If the mouse has already left the unit, the tooltip will get stuck
		-- visible. This bounces it back into visibility if it's partly faded
		-- out, but it'll just fade again.
		if replace and not GameTooltip:IsUnit("mouseover") then
			Tooltip:FadeOut()
		end
	end
end

local enabled
local function GameTooltip_AddLine_Hook(self, ...)
	if enabled and replace and active and not rendering then
		currentUnit.lines[#currentUnit.lines + 1] = { ... }
	end
end

local function GameTooltip_AddDoubleLine_Hook(self, ...)
	if enabled and replace and active and not rendering then
		currentUnit.lines[#currentUnit.lines + 1] = { double = true, ... }
	end
end

local function GameTooltip_OnTooltipCleared_Hook(self)
	active = nil
	if not replace then
		Tooltip:Hide()
	end
end

local function NoUnit()
	-- GameTooltip:GetUnit() will sometimes return nil, especially when custom
	-- unit frames call GameTooltip:SetUnit() with something 'odd' like
	-- targettarget. By the next frame draw, the tooltip will correctly be able
	-- to identify such units (usually as mouseover).
	local tooltip, unit = GameTooltip:GetUnit()
	if not unit then return end
	SetUnit(unit)
end

local function GameTooltip_OnTooltipSetUnit_Hook(self)
	if not enabled then return end
	local tooltip, unit = self:GetUnit()
	if not unit then
		_xrp.NextFrame(NoUnit)
	else
		SetUnit(unit)
	end
end

_xrp.settingsToggles.tooltip = {
	enabled = function(setting)
		if setting then
			if enabled == nil then
				GameTooltip:HookScript("OnTooltipSetUnit", GameTooltip_OnTooltipSetUnit_Hook)
				GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared_Hook)
			end
			xrp.HookEvent("RECEIVE", Tooltip_RECEIVE)
			enabled = true
			_xrp.settingsToggles.tooltip.replace(_xrp.settings.tooltip.replace)
		elseif enabled ~= nil then
			enabled = false
			xrp.UnhookEvent("RECEIVE", Tooltip_RECEIVE)
		end
	end,
	replace = function(setting)
		if not enabled then return end
		if setting then
			if replace == nil then
				hooksecurefunc(GameTooltip, "AddLine", GameTooltip_AddLine_Hook)
				hooksecurefunc(GameTooltip, "AddDoubleLine", GameTooltip_AddDoubleLine_Hook)
			end
			Tooltip = GameTooltip
			replace = true
		else
			if not XRPTooltip then
				CreateFrame("GameTooltip", "XRPTooltip", GameTooltip, "GameTooltipTemplate")
			end
			Tooltip = XRPTooltip
			if replace ~= nil then
				replace = false
			end
		end
	end,
}
