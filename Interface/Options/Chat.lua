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

local FOLDER, _xrp = ...

local channelsList = {}

local function Channels_Checked(self)
	return channelsList[self.arg1].value
end
local function Channels_OnClick(self, channel, arg2, checked)
	channelsList[channel].value = checked
	_xrp.settings.chatType[channel] = checked or nil
end

local function ChannelsTable(...)
	local list, i = {}, 2
	while select(i, ...) do
		list[i * 0.5] = select(i, ...)
		i = i + 2
	end
	return list
end

local function AddChannel(channel, menuList)
	local setting = _xrp.settings.chatType[channel] or false
	local oldSetting = setting
	if not channelsList[channel] then
		channelsList[channel] = { value = setting, oldValue = oldSetting }
	end
	menuList[#menuList + 1] = { text = channel:match("^CHANNEL_(.+)"):lower():gsub("^%l", string.upper), arg1 = channel, isNotRadio = true, checked = Channels_Checked, func = Channels_OnClick, keepShownOnClick = true, }
end

XRPOptionsChatChannels_Mixin = {
	CustomRefresh = function(self)
		table.wipe(self.baseMenuList)
		local seenChannels = {}
		for i, name in ipairs(ChannelsTable(GetChannelList())) do
			local channel = "CHANNEL_" .. name:upper()
			AddChannel(channel, self.baseMenuList, channelsList)
			seenChannels[channel] = true
		end
		for channel, setting in pairs(_xrp.settings.chatType) do
			if not seenChannels[channel] and channel:find("^CHANNEL_") then
				AddChannel(channel, self.baseMenuList, channelsList)
				seenChannels[channel] = true
			end
		end
	end,
	CustomOkay = function(self)
		for channel, control in pairs(channelsList) do
			control.oldValue = control.value
		end
	end,
	CustomDefault = function(self)
		for channel, control in pairs(channelsList) do
			_xrp.settings.chatType[channel] = nil
			control.value = nil
		end
	end,
	CustomCancel = function(self)
		for channel, control in pairs(channelsList) do
			_xrp.settings.chatType[channel] = control.oldValue
			control.value = control.oldValue
		end
	end,
	baseMenuList = {},
}
