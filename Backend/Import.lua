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

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

local hasMRP, hasTRP3 = (GetAddOnEnableState(AddOn.player, "MyRolePlay") == 2), (GetAddOnEnableState(AddOn.player, "totalRP3") == 2)
if not (hasMRP or hasTRP3) then return end

local MRP_NO_IMPORT = { TT = true, VA = true, VP = true, GC = true, GF = true, GR = true, GS = true, GU = true }

StaticPopupDialogs["XRP_IMPORT_RELOAD"] = {
	text = L"Available profiles have been imported and may be found in the editor's profile list. You should reload your UI now.",
	button1 = RELOADUI,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	enterClicksFirstButton = false,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	cancels = "XRP_MSP_DISABLE",
}

-- This is easy. Using a very similar storage format (i.e., MSP fields).
local function ImportMyRolePlay()
	if not mrpSaved then
		return 0
	end
	local imported = 0
	local importedList = {}
	for profileName, oldProfile in pairs(mrpSaved.Profiles) do
		local profile = xrp.profiles:Add("MRP-" .. profileName)
		if profile then
			importedList[#importedList + 1] = tostring(profile)
			for field, value in pairs(oldProfile) do
				if not MRP_NO_IMPORT[field] and field:find("^%u%u$") then
					if field == "FC" then
						if not tonumber(value) and value ~= "" then
							value = "2"
						elseif value == "0" then
							value = ""
						end
					elseif field == "FR" and tonumber(value) then
						value = xrp.L.VALUES.FR[value] or ""
					end
					profile.fields[field] = value ~= "" and value or nil
				end
			end
			imported = imported + 1
		end
	end
	for i, name in ipairs(importedList) do
		if name ~= "MRP-Default" then
			xrp.profiles[name].parent = "MRP-Default"
		end
	end
	return imported
end

-- They really like intricate data structures.
local function ImportTotalRP3()
	if not TRP3_Profiles or not TRP3_Characters then
		return 0
	end
	local oldProfile = TRP3_Profiles[TRP3_Characters[AddOn.playerWithRealm].profileID]
	if not oldProfile then
		return 0
	end
	local profile = xrp.profiles:Add("TRP3-" .. oldProfile.profileName)
	if not profile then
		return 0
	end

	local NA = {}
	NA[#NA + 1] = oldProfile.player.characteristics.TI
	NA[#NA + 1] = oldProfile.player.characteristics.FN or AddOn.player
	NA[#NA + 1] = oldProfile.player.characteristics.LN
	profile.fields.NA = table.concat(NA, " ")
	profile.fields.NT = oldProfile.player.characteristics.FT
	profile.fields.AG = oldProfile.player.characteristics.AG
	profile.fields.RA = oldProfile.player.characteristics.RA
	profile.fields.RC = oldProfile.player.characteristics.CL
	profile.fields.AW = oldProfile.player.characteristics.WE
	profile.fields.AH = oldProfile.player.characteristics.HE
	profile.fields.HH = oldProfile.player.characteristics.RE
	profile.fields.HB = oldProfile.player.characteristics.BP
	profile.fields.AE = oldProfile.player.characteristics.EC
	if oldProfile.player.characteristics.MI then
		local NI, NH, MO = {}, {}, {}
		for i, custom in ipairs(oldProfile.player.characteristics.MI) do
			if custom.NA == L.TRP3_NICKNAME then
				NI[#NI + 1] = custom.VA
			elseif custom.NA == L.TRP3_HOUSE_NAME then
				NH[#NH + 1] = custom.VA
			elseif custom.NA == L.TRP3_MOTTO then
				MO[#MO + 1] = custom.VA
			end
		end
		profile.fields.NI = table.concat(NI, " | ")
		profile.fields.NH = table.concat(NH, " | ")
		profile.fields.MO = table.concat(MO, " | ")
	end
	local CU = {}
	CU[#CU + 1] = oldProfile.player.character.CU
	if oldProfile.player.character.CO then
		CU[#CU + 1] = L.OOC_TEXT:format(oldProfile.player.character.CO)
	end
	profile.fields.CU = table.concat(CU, " ")
	profile.fields.FC = tostring(oldProfile.player.character.RP)
	if oldProfile.player.about.TE == 1 then
		profile.fields.DE = oldProfile.player.about["T1"].TX
	elseif oldProfile.player.about.TE == 2 then
		local DE = {}
		for i, block in ipairs(oldProfile.player.about["T2"]) do
			DE[#DE + 1] = block.TX
		end
		profile.fields.DE = table.concat(DE, "\n\n")
	elseif oldProfile.player.about.TE == 3 then
		local HI = {}
		profile.fields.DE = oldProfile.player.about["T3"].PH.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].PS.TX
		HI[#HI + 1] = oldProfile.player.about["T3"].HI.TX
		profile.fields.HI = table.concat(HI, "\n\n")
	end
	return 1
end

AddOn.HookGameEvent("PLAYER_LOGIN", function(event)
	local imported = false
	if hasMRP and select(2, IsAddOnLoaded("MyRolePlay")) then
		local count = ImportMyRolePlay()
		if count > 0 then
			DisableAddOn("MyRolePlay", AddOn.player)
			imported = true
		end
	end
	if hasTRP3 and select(2, IsAddOnLoaded("totalRP3")) then
		local count = ImportTotalRP3()
		if count > 0 then
			DisableAddOn("totalRP3", AddOn.player)
			imported = true
		end
	end
	if imported then
		StaticPopup_Show("XRP_IMPORT_RELOAD")
	end
end)
