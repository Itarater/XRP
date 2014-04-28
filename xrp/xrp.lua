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

xrp = CreateFrame("Frame", "xrp", UIParent)

xrp.version = GetAddOnMetadata("xrp", "Version")
xrp.versionstring = format("%s/%s", GetAddOnMetadata("xrp", "Title"), xrp.version)

local default_settings = { __index = {
	height = "ft",
	weight = "lb",
	minimap = 225,
}}

local default_defaults = { __index = function(default_defaults, field)
	return true
end}

local function checksavedvars()
	if type(xrp_settings) ~= "table" then
		xrp_settings = {
			height = "ft",
			weight = "lb",
			minimap = 225,
		}
	end
	if type(xrp_settings.defaults) ~= "table" then
		xrp_settings.defaults = {}
	end

	if type(xrp_profiles) ~= "table" then
		xrp_profiles = {}
	end
	if type(xrp_profiles.Default) ~= "table" then
		xrp_profiles.Default = {}
	end
	if type(xrp_profiles.Default.NA) ~= "string" then
		xrp_profiles.Default.NA = xrp.toon.name
	end

	if type(xrp_defaults) ~= "table" then
		xrp_defaults = {}
	end

	if type(xrp_selectedprofile) ~= "string" or type(xrp_profiles[xrp_selectedprofile]) ~= "table" then
		xrp_selectedprofile = "Default"
	end

	if type(xrp_cache) ~= "table" then
		xrp_cache = {}
	end
	if not xrp_cache[xrp.toon.withrealm] then
		xrp_cache[xrp.toon.withrealm] = {
			fields = {},
			versions = {},
		}
	end

	if type(xrp_versions) ~= "table" then
		xrp_versions = {}
	end
end

local addons = {
	"GHI",
	"Tongues",
}

-- Remove before final.
local function beta3convert()
	local uiname, uititle, uinotes, uienabled, uiloadable, uireason = GetAddOnInfo("xrpui")
	if uienabled and not xrp_settings.beta3convert then
		xrp_settings.beta3convert = true
		StaticPopupDialogs["XRP_RELOAD_NOW"] = {
			text = "You need to reload your UI. (Also you should remove all the xrpui_ folders from your Interface\\Addons folder.)",
			button1 = "Please Reload!",
			button2 = "Reload, I guess.",
			OnAccept = function()
				ReloadUI()
			end,
			OnCancel = function()
				ReloadUI()
			end,
			timeout = 0,
			hideOnEscape = false,
		}
		DisableAddOn("xrpui")
		StaticPopup_Show("XRP_RELOAD_NOW")
	end
end

local function init_OnEvent(xrp, event, addon)
	if event == "ADDON_LOADED" and addon == "xrp" then
		local fullversion = xrp.versionstring
		for _, addon in pairs(addons) do
			local name, title, notes, enabled, loadable, reason = GetAddOnInfo(addon)
			if enabled or loadable then
				fullversion = format("%s;%s/%s", fullversion, name, GetAddOnMetadata(name, "Version"))
			end
		end

		xrp.toon = {}
		-- DO NOT use xrp:UnitNameWithRealm() here as it will fail on first
		-- load after login (UnitIsPlayer("player") fails).
		xrp.toon.withrealm = format("%s-%s", UnitName("player"), GetRealmName():gsub("%s+", ""))
		xrp.toon.name = xrp:NameWithoutRealm(xrp.toon.withrealm)
		-- NOTE: UnitGUID("player") doesn't work until PLAYER_LOGIN, so is set
		-- during that event (below).
		xrp.toon.fields = { -- NONE of these are localized.
			GC = (select(2, UnitClass("player"))),
			GF = (UnitFactionGroup("player")),
			GR = (select(2, UnitRace("player"))),
			GS = tostring(UnitSex("player")),
			VA = fullversion,
			VP = tostring(xrp.msp.protocol),
		}

		checksavedvars()
		setmetatable(xrp_settings, default_settings)
		setmetatable(xrp_settings.defaults, default_defaults)

		xrp:UnregisterEvent("ADDON_LOADED")
		xrp:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		beta3convert()
		-- UnitGUID("player") doesn't work before first PLAYER_LOGIN.
		xrp.toon.fields.GU = UnitGUID("player")
		xrp.profiles(xrp_selectedprofile)
		xrp:UnregisterEvent("PLAYER_LOGIN")
	end
end
xrp:SetScript("OnEvent", init_OnEvent)
xrp:RegisterEvent("ADDON_LOADED")
