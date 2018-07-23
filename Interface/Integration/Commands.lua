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

local SLASH_XRP = L.SLASH_XRP or "/xrp"
local INFO = STAT_FORMAT:format("|cff99b3e6%s") .. "|r %s"
-- Also used in ui/options.xml.
XRP_VERSION = INFO:format(GAME_VERSION_LABEL, AddOn.version)
local XRP_HEADER = ("|cffffd100<|r|cffabd473%s|r|cffffd100>:|r %%s"):format(GetAddOnMetadata(FOLDER_NAME, "Title"))

local xrpCmds = {}

xrpCmds.about = function(args)
	print(XRP_HEADER:format(""))
	print(XRP_VERSION)
	for line in L.GPL_SHORT:gmatch("[^\n]+") do
		print(line)
	end
end

xrpCmds.archive = function(args)
	XRPArchive:Toggle(1)
end

xrpCmds.currently = function(args)
	if args == L.ARG_CURRENTLY_NIL then
		xrp.current.CU = nil
		local CU = xrp.current.CU
		if CU then
			print(XRP_HEADER:format(L.SET_CURRENTLY_PROFILE:format(CU)))
		else
			print(XRP_HEADER:format(L.SET_CURRENTLY_BLANK_PROFILE))
		end
	elseif type(args) == "string" then
		xrp.current.CU = args
		print(XRP_HEADER:format(L.SET_CURRENTLY:format(args)))
	else
		xrp.current.CU = ""
		print(XRP_HEADER:format(L.SET_CURRENTLY_BLANK))
	end
end

xrpCmds.edit = function(args)
	XRPEditor:Edit(args)
end

xrpCmds.export = function(args)
	local name = xrp.FullName(args:match("^[^%s]+"))
	if not name then return end
	name = name:gsub("^%l", string.upper)
	XRPExport:Export(xrp.ShortName(name), tostring(xrp.characters.noRequest.byName[name].fields))
end

local USAGE = XRP_HEADER:format(("|cff9482c9%s|r %%s"):format(STAT_FORMAT:format(L.USAGE)))
local ARG = (" - |cfffff569%s|r %%s"):format(STAT_FORMAT:format("%s"))
local NO_ARGS = SLASH_XRP .. " %s"
local HAS_ARGS = SLASH_XRP .. " %s %s"
xrpCmds.help = function(args)
	if args == "about" or args and args == L.CMD_ABOUT then
		print(USAGE:format(NO_ARGS:format(L.CMD_ABOUT)))
		print(L.ABOUT_HELP)
	elseif args == "archive" or args and args == L.CMD_ARCHIVE then
		print(USAGE:format(NO_ARGS:format(L.CMD_ARCHIVE)))
		print(L.ARCHIVE_HELP)
	elseif args == "currently" or args and args == L.CMD_CURRENTLY then
		print(USAGE:format(HAS_ARGS:format(L.CMD_CURRENTLY, L.CURRENTLY_ARGS)))
		print(ARG:format(L.CURRENTLY_ARG1, L.CURRENTLY_ARG1_HELP))
		print(ARG:format(L.CURRENTLY_ARG2, L.CURRENTLY_ARG2_HELP))
		print(ARG:format(L.ARG_CURRENTLY_NIL, L.CURRENTLY_ARG3_HELP))
	elseif args == "edit" or args and args == L.CMD_EDIT then
		print(USAGE:format(HAS_ARGS:format(L.CMD_EDIT, L.EDIT_ARGS)))
		print(ARG:format(L.EDIT_ARG1, L.EDIT_ARG1_HELP))
		print(ARG:format(L.EDIT_ARG2, L.EDIT_ARG2_HELP))
	elseif args == "export" or args and args == L.CMD_EXPORT then
		print(USAGE:format(HAS_ARGS:format(L.CMD_EXPORT, L.EXPORT_ARG1)))
		print(ARG:format(L.EXPORT_ARG1, L.EXPORT_ARG1_HELP))
	elseif args == "profile" or args and args == L.CMD_PROFILE then
		print(USAGE:format(HAS_ARGS:format(L.CMD_PROFILE, L.PROFILE_ARGS)))
		print(ARG:format(L.ARG_PROFILE_LIST, L.PROFILE_ARG1_HELP))
		print(ARG:format(L.PROFILE_ARG2, L.PROFILE_ARG2_HELP))
	elseif args == "status" or args and args == L.CMD_STATUS then
		print(USAGE:format(HAS_ARGS:format(L.CMD_STATUS, L.STATUS_ARGS)))
		print(ARG:format(L.ARG_STATUS_NIL, L.STATUS_ARG1_HELP))
		print(ARG:format(L.ARG_STATUS_IC, L.STATUS_ARG2_HELP))
		print(ARG:format(L.ARG_STATUS_OOC, L.STATUS_ARG3_HELP))
		print(ARG:format(L.ARG_STATUS_LFC, L.STATUS_ARG4_HELP))
		print(ARG:format(L.ARG_STATUS_ST, L.STATUS_ARG5_HELP))
	elseif args == "toggle" or args and args == L.CMD_TOGGLE then
		print(USAGE:format(NO_ARGS:format(L.CMD_TOGGLE)))
		print(L.TOGGLE_HELP)
	elseif args == "view" or args and args == L.CMD_VIEW then
		print(USAGE:format(HAS_ARGS:format(L.CMD_VIEW, L.VIEW_ARGS)))
		print(ARG:format(L.VIEW_ARG1, L.VIEW_ARG1_HELP))
		print(ARG:format(L.VIEW_ARG2, L.VIEW_ARG2_HELP))
		print(ARG:format(L.VIEW_ARG3, L.VIEW_ARG3_HELP))
	else
		print(USAGE:format(HAS_ARGS:format(L.COMMANDS, L.ARGUMENTS)))
		print(L.COMMANDS_HELP)
		print(ARG:format(L.CMD_ABOUT, L.ABOUT_HELP))
		print(ARG:format(L.CMD_ARCHIVE, L.ARCHIVE_HELP))
		print(ARG:format(L.CMD_CURRENTLY, L.CURRENTLY_HELP))
		print(ARG:format(L.CMD_EDIT, L.EDIT_HELP))
		print(ARG:format(L.CMD_EXPORT, L.EXPORT_HELP))
		print(ARG:format(L.CMD_HELP, L.HELP_HELP))
		print(ARG:format(L.CMD_PROFILE, L.PROFILE_HELP))
		print(ARG:format(L.CMD_STATUS, L.STATUS_HELP))
		print(ARG:format(L.CMD_TOGGLE, L.TOGGLE_HELP))
		print(ARG:format(L.CMD_VIEW, L.VIEW_HELP))
	end
end

xrpCmds.profile = function(args)
	if args == "list" or args == L.ARG_PROFILE_LIST then
		print(XRP_HEADER:format(STAT_FORMAT:format(L.PROFILES)))
		for i, profile in ipairs(xrp.profiles:List()) do
			print(profile)
		end
	elseif type(args) == "string" then
		if xrp.profiles[args] and xrp.profiles[args]:Activate() then
			print(XRP_HEADER:format(L.SET_PROFILE:format(args)))
		else
			print(XRP_HEADER:format(L.SET_PROFILE_FAIL:format(args)))
		end
	else
		xrpCmds.help("profile")
	end
end

xrpCmds.status = function(args)
	if args == "nil" or args == L.ARG_STATUS_NIL then
		xrp.current.FC = nil
		local FC = xrp.current.FC
		print(XRP_HEADER:format(L.SET_STATUS_PROFILE:format(xrp.L.VALUES.FC[FC] or FC or NONE)))
	elseif args == "ooc" or args == L.ARG_STATUS_OOC then
		xrp.current.FC = "1"
		print(XRP_HEADER:format(L.SET_STATUS:format(xrp.L.VALUES.FC["1"])))
	elseif args == "ic" or args == L.ARG_STATUS_IC then
		xrp.current.FC = "2"
		print(XRP_HEADER:format(L.SET_STATUS:format(xrp.L.VALUES.FC["2"])))
	elseif args == "lfc" or args == L.ARG_STATUS_LFC then
		xrp.current.FC = "3"
		print(XRP_HEADER:format(L.SET_STATUS:format(xrp.L.VALUES.FC["3"])))
	elseif args == "st" or args == L.ARG_STATUS_ST then
		xrp.current.FC = "4"
		print(XRP_HEADER:format(L.SET_STATUS:format(xrp.L.VALUES.FC["4"])))
	else
		xrpCmds.help("status")
	end
end

xrpCmds.toggle = function(args)
	xrp.Status()
	local FC = xrp.current.FC
	print(XRP_HEADER:format(L.SET_STATUS:format(xrp.L.VALUES.FC[FC] or FC or NONE)))
end

xrpCmds.view = function(args)
	if not args and UnitIsPlayer("target") then
		args = "target"
	elseif not args and UnitIsPlayer("mouseover") then
		args = "mouseover"
	end
	XRPViewer:View(args)
end

-- Some aliases to match MRP's chat commands.
xrpCmds.version = xrpCmds.about
xrpCmds.c = xrpCmds.currently
xrpCmds.cu = xrpCmds.currently
xrpCmds.cur = xrpCmds.currently
xrpCmds.ooc = function() xrpCmds.status("ooc") end
xrpCmds.ic = function() xrpCmds.status("ic") end
xrpCmds.lfc = function() xrpCmds.status("lfc") end
xrpCmds.contact = xrpCmds.lfc
xrpCmds.st = function() xrpCmds.status("st") end
xrpCmds.storyteller = xrpCmds.st
xrpCmds.browse = xrpCmds.view
xrpCmds.browser = xrpCmds.view
xrpCmds.show = xrpCmds.view

-- Localized aliases.
if L.CMD_ABOUT ~= "about" then
	xrpCmds[L.CMD_ABOUT] = xrpCmds.about
end
if L.CMD_ARCHIVE ~= "archive" then
	xrpCmds[L.CMD_ARCHIVE] = xrpCmds.archive
end
if L.CMD_CURRENTLY ~= "currently" then
	xrpCmds[L.CMD_CURRENTLY] = xrpCmds.currently
end
if L.CMD_EDIT ~= "edit" then
	xrpCmds[L.CMD_EDIT] = xrpCmds.edit
end
if L.CMD_EXPORT ~= "export" then
	xrpCmds[L.CMD_EXPORT] = xrpCmds.export
end
if L.CMD_HELP ~= "help" then
	xrpCmds[L.CMD_HELP] = xrpCmds.help
end
if L.CMD_PROFILE ~= "profile" then
	xrpCmds[L.CMD_PROFILE] = xrpCmds.profile
end
if L.CMD_STATUS ~= "status" then
	xrpCmds[L.CMD_STATUS] = xrpCmds.status
end
if L.CMD_TOGGLE ~= "toggle" then
	xrpCmds[L.CMD_TOGGLE] = xrpCmds.toggle
end
if L.CMD_VIEW ~= "view" then
	xrpCmds[L.CMD_VIEW] = xrpCmds.view
end

SLASH_XRP1 = "/xrp"
if SLASH_XRP ~= "/xrp" then
	SLASH_XRP2 = SLASH_XRP
end

SlashCmdList["XRP"] = function(input, editBox)
	local command, args = input:match("^([^%s]+)%s*(.*)$")
	command = command and command:lower()
	if command and xrpCmds[command] then
		xrpCmds[command](args ~= "" and args)
	else
		xrpCmds["help"](args ~= "" and args)
	end
end
