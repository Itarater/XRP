--[[
	Copyright / © 2014-2018 Justin Snelgrove

	This file is part of XRP.

	XRP is free software: you can redistribute it and/or modify it under the
	terms of the GNU General Public License as published by	the Free
	Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	XRP is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along
	with XRP. If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER_NAME, AddOn = ...
local L = AddOn.GetText

XRPTargetCard_Mixin = {}

function XRPTargetCard_Mixin:TargetOnLoad()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function XRPTargetCard_Mixin:TargetOnEvent(event)
	if event == "PLAYER_TARGET_CHANGED" then
		local exists = UnitExists("target")
		if exists and AddOn.Settings.cardsTargetShowOnChanged or not exists and AddOn.Settings.cardsTargetHideOnLost then
			self:SetUnit("target")
		end
	end
end
