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

-- These fields are not searched in a full-text search.
local FILTER_IGNORE = { CO = true, FC = true, FR = true, GC = true, GF = true, GR = true, GS = true, GU = true, IC = true, VA = true, VP = true }

local RACE_FACTION = {
	Human = "Alliance",
	Dwarf = "Alliance",
	Gnome = "Alliance",
	NightElf = "Alliance",
	Draenei = "Alliance",
	Worgen = "Alliance",
	Orc = "Horde",
	Tauren = "Horde",
	Troll = "Horde",
	Scourge = "Horde",
	BloodElf = "Horde",
	Goblin = "Horde",
	Pandaren = nil, -- Can't tell faction.
}

local unitCache = {}
_xrp.unitCache = unitCache

local nameMap, requestMap = setmetatable({}, _xrp.weakKeyMeta), setmetatable({}, _xrp.weakKeyMeta)

local characterMeta
do
	local characterFunctions = {
		DropCache = function(self)
			_xrp.DropCache(nameMap[self])
		end,
		ForceRefresh = function(self)
			_xrp.ForceRefresh(nameMap[self])
		end,
	}
	local fieldsMeta = {
		__index = function(self, field)
			if not field:find("^%u%u$") then
				return nil
			end
			local name = nameMap[self]
			if name == _xrp.playerWithRealm then
				return xrp.current[field]
			elseif unitCache[name] and unitCache[name][field] then
				return unitCache[name][field]
			elseif requestMap[self] then
				_xrp.QueueRequest(name, field)
			end
			if xrpCache[name] and xrpCache[name].fields[field] then
				return xrpCache[name].fields[field]
			end
			return nil
		end,
		__newindex = _xrp.DoNothing,
		__tostring = function(self)
			local name = nameMap[self]
			if not xrpCache[name] then return "" end
			local shortName, realm = name:match("^([^%-]+)%-([^%-]+)$")
			realm = xrp.RealmDisplayName(realm)
			return _xrp.ExportText(_xrp.L.NAME_REALM:format(shortName, realm), name == _xrp.playerWithRealm and xrp.current or xrpCache[name].fields)
		end,
		__metatable = false,
	}

	characterMeta = {
		__index = function(self, component)
			local name = nameMap[self]
			if component == "fields" then
				local fields = setmetatable({}, fieldsMeta)
				nameMap[fields] = name
				requestMap[fields] = requestMap[self]
				rawset(self, "fields", fields)
				return fields
			elseif characterFunctions[component] then
				return characterFunctions[component]
			elseif component == "own" and name == _xrp.playerWithRealm then
				return true
			elseif component == "noRequest" then
				return not requestMap[self]
			elseif component == "canRefresh" then
				if xrpCache[name] and xrpCache[name].own then
					return false
				end
				return not requestMap[self] or _xrp.CanRefresh(name)
			elseif not xrpCache[name] then
				return nil
			elseif component == "notes" then
				return xrpAccountSaved.notes[name]
			elseif component == "bookmark" then
				return xrpAccountSaved.bookmarks[name]
			elseif component == "hide" then
				return xrpAccountSaved.hidden[name]
			elseif component == "own" then
				return xrpCache[name].own
			elseif component == "date" then
				return xrpCache[name].lastReceive
			end
		end,
		__newindex = function(self, component, value)
			local name = nameMap[self]
			if not xrpCache[name] then return end
			if component == "notes" then
				xrpAccountSaved.notes[name] = value
			elseif component == "bookmark" then
				if value and not xrpAccountSaved.bookmarks[name] then
					xrpAccountSaved.bookmarks[name] = time()
				elseif not value and xrpAccountSaved.bookmarks[name] then
					xrpAccountSaved.bookmarks[name] = nil
				end
			elseif component == "hide" then
				if value and not xrpAccountSaved.hidden[name] then
					xrpAccountSaved.hidden[name] = true
				elseif not value and xrpAccountSaved.hidden[name] then
					xrpAccountSaved.hidden[name] = nil
				end
			end
		end,
		__tostring = function(self)
			return nameMap[self]
		end,
		__metatable = false,
	}
end

local function SortString(sortType, name, cache)
	if sortType == "date" then
		return ("%d\30%s"):format(cache.lastReceive, name)
	elseif sortType == "NA" then
		return ("%s\30%s"):format((xrp.Strip(cache.fields.NA) or name):lower(), name)
	elseif sortType == "realm" then
		return ("%s\30%s"):format(name:match("%-([^%-]+)$"), name)
	end
	return ("%s\30%s"):format(name:lower(), name)
end

local function SortAsc(a, b)
	return a > b
end

local requestTables = setmetatable({}, _xrp.weakMeta)
local noRequestTables = setmetatable({}, _xrp.weakMeta)

xrp.characters = {
	byName = setmetatable({}, {
		__index = function(self, name)
			name = xrp.FullName(name)
			if not name then
				return nil
			elseif not requestTables[name] then
				local character = setmetatable({}, characterMeta)
				nameMap[character] = name
				requestMap[character] = true
				requestTables[name] = character
			end
			return requestTables[name]
		end,
		__newindex = _xrp.DoNothing,
		__metatable = false,
	}),
	byUnit = setmetatable({}, {
		__index = function (self, unit)
			local name = xrp.UnitFullName(unit)
			if not name then
				return nil
			elseif not unitCache[name] then
				local GU = UnitGUID(unit)
				local class, GC, race, GR, GS = GetPlayerInfoByGUID(GU)
				local reliable = (RACE_FACTION[GR] or (GetZonePVPInfo() ~= "combat" and (not UnitInBattleground("player") or IsRatedMap())) or not UnitIsVisible(unit)) and true or nil
				unitCache[name] = {
					GC = GC,
					GF = RACE_FACTION[GR] or UnitFactionGroup(unit),
					GR = GR,
					GS = tostring(GS),
					GU = GU,
					reliable = reliable,
				}
				if xrpCache[name] and name ~= _xrp.playerWithRealm then
					-- We DO want to overwrite these, to account for race,
					-- faction, or sex changes.
					for field, contents in pairs(unitCache[name]) do
						-- Ugh, mercenary mode bugs workaround for Pandaren.
						if field ~= "GF" or reliable then
							xrpCache[name].fields[field] = contents
						end
					end
				end
			elseif not unitCache[name].GF or not unitCache[name].reliable then
				local reliable = (GetZonePVPInfo() ~= "combat" and (not UnitInBattleground("player") or IsRatedMap()) or not UnitIsVisible(unit)) and true or nil
				-- GUID won't always get faction. Plus more ugly mercenary mode
				-- Pandaren workarounds above.
				unitCache[name].GF = UnitFactionGroup(unit)
				unitCache[name].reliable = reliable
				if reliable and xrpCache[name] and name ~= _xrp.playerWithRealm then
					xrpCache[name].fields.GF = unitCache[name].GF
				end
			end
			if not requestTables[name] then
				local character = setmetatable({}, characterMeta)
				nameMap[character] = name
				requestMap[character] = true
				requestTables[name] = character
			end
			return requestTables[name]
		end,
		__newindex = _xrp.DoNothing,
		__metatable = false,
	}),
	byGUID = setmetatable({}, {
		__index = function (self, GU)
			-- This will return nil if the GUID hasn't been seen by the client
			-- yet in the session.
			local success, class, GC, race, GR, GS, name, realm = pcall(GetPlayerInfoByGUID, GU)
			name = xrp.FullName(name, realm)
			if not success or not name then
				return nil
			elseif not unitCache[name] then
				unitCache[name] = {
					GC = GC,
					GF = RACE_FACTION[GR],
					GR = GR,
					GS = tostring(GS),
					GU = GU,
				}
				if xrpCache[name] and name ~= _xrp.playerWithRealm then
					for field, contents in pairs(unitCache[name]) do
						-- We DO want to overwrite these, to account for race,
						-- faction, or sex changes.
						xrpCache[name].fields[field] = contents
					end
				end
			end
			if not requestTables[name] then
				local character = setmetatable({}, characterMeta)
				nameMap[character] = name
				requestMap[character] = true
				requestTables[name] = character
			end
			return requestTables[name]
		end,
		__newindex = _xrp.DoNothing,
		__metatable = false,
	}),
	List = function(self, filter)
		if not filter then
			filter = {}
		end
		local results, totalCount = {}, 0
		local before = filter.maxAge and (time() - filter.maxAge)
		local bookmarks, notes, hidden = xrpAccountSaved.bookmarks, xrpAccountSaved.notes, xrpAccountSaved.hidden
		for name, cache in pairs(xrpCache) do
			totalCount = totalCount + 1
			local toAdd = true
			if filter.bookmark and not bookmarks[name] then
				toAdd = false
			elseif filter.notes and not notes[name] then
				toAdd = false
			elseif not filter.showHidden and hidden[name] then
				toAdd = false
			elseif filter.own and not cache.own then
				toAdd = false
			elseif filter.faction and filter.faction[cache.fields.GF or "UNKNOWN"] then
				toAdd = false
			elseif filter.class and filter.class[cache.fields.GC or "UNKNOWN"] then
				toAdd = false
			elseif filter.race and filter.race[cache.fields.GR or "UNKNOWN"] then
				toAdd = false
			elseif before and cache.lastReceive < before then
				toAdd = false
			elseif not filter.fullText and filter.text then
				local searchText = filter.text:lower()
				local nameText = name:match(FULL_PLAYER_NAME:format("(.+)", ".+")):lower()
				if not nameText:find(searchText, nil, true) then
					toAdd = false
				end
			elseif filter.text then
				local found = false
				local searchText = filter.text:lower()
				for field, contents in pairs(cache.fields) do
					if not FILTER_IGNORE[field] and contents:lower():find(searchText, nil, true) then
						found = true
						break
					end
				end
				if not found then
					toAdd = false
				end
			end
			if toAdd then
				results[#results + 1] = SortString(filter.sortType, name, cache)
			end
		end
		local sortAscending = filter.sortReverse
		if filter.sortType == "date" then -- Default to newest first for date.
			sortAscending = not sortAscending
		end
		if sortAscending then
			table.sort(results, SortAsc)
		else
			table.sort(results)
		end
		for i, result in ipairs(results) do
			results[i] = result:match("^.-\30(.+)$")
		end
		results.totalCount = totalCount
		return results
	end,
	noRequest = {
		byName = setmetatable({}, {
			__index = function(self, name)
				name = xrp.FullName(name)
				if not name then
					return nil
				elseif not noRequestTables[name] then
					local character = setmetatable({}, characterMeta)
					nameMap[character] = name
					noRequestTables[name] = character
				end
				return noRequestTables[name]
			end,
			__newindex = _xrp.DoNothing,
			__metatable = false,
		}),
	},
}
