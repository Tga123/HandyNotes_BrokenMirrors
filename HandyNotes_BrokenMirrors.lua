HNBM = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_BrokenMirrors", "AceEvent-3.0") -- register addon in Ace3 API
local HN = LibStub("AceAddon-3.0"):GetAddon("HandyNotes") -- get original HandyNotes for use it API
local CompletedQuests = {} -- empty table for list completed quests
local CompletedGroup = 0 -- id group of quests, 0 is empty group

local defaults = { -- default settings of addon
    profile = {
        icon_scale = 1.3,
        icon_alpha = 1.0,
		found = false,
    },
}

HNBM.db = LibStub("AceDB-3.0"):New("HandyNotes_BrokenMirrorsDB", defaults, true) -- AceDB-3.0 API, register "SavedVariables" variable from addon table of contents file (.toc) as AceDB managed database, and set "defaults" variable as default values of database

HNBM.icons = {} -- empty table for icons
for i = 1, 4 do -- prepare icons to use with HandyNotes, 4 of default map POI icons
	local left, right, top, bottom = GetPOITextureCoords(111+i)
	HNBM.icons[i] = {
		icon = [[Interface\Minimap\POIIcons]],
		tCoordLeft = left,
		tCoordRight = right,
		tCoordTop = top,
		tCoordBottom = bottom,
		r = 1, g = 0, b = 0,
	}
end

local options = { -- table with addon settings interface, use Ace3 API
    type = "group",
    name = "BrokenMirrors",
    desc = "BrokenMirrors",
    get = function(info) return HNBM.db.profile[info[#info]] end,
    set = function(info, v)
        HNBM.db.profile[info[#info]] = v
        HNBM:SendMessage("HandyNotes_NotifyUpdate", "BrokenMirrors")
    end,
    args = {
        desc = {
            name = "These settings control the look and feel of the icon.",
            type = "description",
            order = 0,
        },
        icon_scale = {
            type = "range",
            name = "Icon Scale",
            desc = "The scale of the icons",
            min = 0.25, max = 2, step = 0.01,
            order = 20,
        },
        icon_alpha = {
            type = "range",
            name = "Icon Alpha",
            desc = "The alpha transparency of the icons",
            min = 0, max = 1, step = 0.01,
            order = 30,
        },
        found = {
            type = "toggle",
            name = "Show ",
            desc = "Show waypoints for repaired mirrors?",
        },
    },
}

local points = { -- table with pin coordinates (in HandyNotes format) and metadata

	--[coordinates] = { group=id, label="text", note="text", quest=id,},

	[29493726] = { group=1, label="Broken mirror (Group №1)", note="Room with Cooking Pot", quest=61818},
	[27152163] = { group=1, label="Broken mirror (Group №1)", note="Room with Elite Spider", quest=61826},
	[40417334] = { group=1, label="Broken mirror (Group №1)", note="Inside House with Sleeping Wildlife", quest=61822},

	[39095218] = { group=2, label="Broken mirror (Group №2)", note="Room on Ground Floor", quest=61819},
	[58806780] = { group=2, label="Broken mirror (Group №2)", note="Inside House with Stonevigil, on top floor", quest=61823},
	[70974363] = { group=2, label="Broken mirror (Group №2)", note="Room with Disciples", quest=61827},

	[72604365] = { group=3, label="Broken mirror (Group №3)", note="Inside Crypt with Disciples", quest=61817},
	[40307716] = { group=3, label="Broken mirror (Group №3)", note="Inside House with Wildlife", quest=61821},
	[77176543] = { group=3, label="Broken mirror (Group №3)", note="Inside House with several Elite Mobs", quest=61825},

	[29602589] = { group=4, label="Broken mirror (Group №4)", note="Room with Elite Soulbinder", quest=61824},
	[20755426] = { group=4, label="Broken mirror (Group №4)", note="Inside Villa at Entrance", quest=59236},
	[55123567] = { group=4, label="Broken mirror (Group №4)", note="Inside Crypt with Nobles", quest=61820},
}

local function QuestAndGroup() -- detect completed quests, fill "CompletedQuests" table with quest ids ([id] = true), and put quest group id in "CompletedGroup"
	for _,v in pairs(points) do
		if C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
			CompletedQuests[v.quest] = true
			CompletedGroup = v.group
		end
	end
end

do -- "do .. end" container, HandyNotes authors recommend to do that
	local function HNBM_iterator(nodes, precoord) -- iterator function required by HandyNotes API, detect which pins must be shown, require table with coordinates and table index, HandyNotes send here 2 and 3 args returned by "GetNodes2"
		if not nodes then return end
		local coord, value = next(nodes, precoord)
		while coord do
			if value and HNBM.db.profile.found or CompletedGroup == 0 or (CompletedGroup == value.group and not CompletedQuests[value.quest]) then
				return coord, nil, HNBM.icons[value.group], HNBM.db.profile.icon_scale, HNBM.db.profile.icon_alpha
			end
			coord, value = next(nodes, coord)
		end
	end

	function HNBM:GetNodes2(uiMapId, minimap) -- function required by HandyNotes API, detect which iterator be handle pins, HandyNotes send here zone map id and map type (bool, true if minimap)
		if uiMapId ~= 1525 then
			return HNBM_iterator, nil, nil
		end
		return HNBM_iterator, points, nil
	end

	function HNBM:OnEnter(uiMapId, coord) -- function required by HandyNotes API, it called when mouse enters on pin, used to produce tooltip, HandyNotes send here zone map id and coordinates of pin (in HandyNotes format)
		local tooltip = GameTooltip
		if ( self:GetCenter() > UIParent:GetCenter() ) then
			tooltip:SetOwner(self, "ANCHOR_LEFT")
		else
			tooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		tooltip:SetText(points[coord].label)
		tooltip:AddLine(points[coord].note, 1, 1, 1, true)
		if CompletedGroup == 0 or not HNBM.db.profile.found then
			tooltip:AddLine("Repair one of mirrors to hide improper pins", 0.5, 0.5, 0.5, true)
		end
		tooltip:Show()
	end

	function HNBM:OnLeave(mapID, coord) -- function required by HandyNotes API, it called when mouse leaves pin, used to hide tooltip, HandyNotes send here zone map id and coordinates of pin (in HandyNotes format)
		local tooltip = GameTooltip
		tooltip:Hide()
	end

	function HNBM:OnClick(button, down, uiMapID, coord) -- function required by HandyNotes API, it called when mouse click on pin, used to produce standard WoW waypoint, HandyNotes send here which button be pressed, up/down state, zone map id, and coordinates of pin (in HandyNotes format)
		C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(uiMapID,HN:getXY(coord)))
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)
	end
end

function HNBM:Refresh() -- refreshing pins. For example, when conditions changed
	QuestAndGroup()
	HNBM:SendMessage("HandyNotes_NotifyUpdate", "BrokenMirrors")
end

function HNBM:OnEnable() -- Ace3 API function, calling when addon enabled, after "OnInitialize"
	HNBM:Refresh()
end

function HNBM:OnInitialize()  -- Ace3 API function, calling when addon Initialized, on loading screen, before game can send to addons player information (quests states, map coordinates)
    HN:RegisterPluginDB("BrokenMirrors", HNBM, options) -- register addon as plugin for HandyNotes, and define "options" table as addon settings interface
	HNBM:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST", "Refresh") -- AceEvent-3.0 API, registering "Refresh" function on "RECEIVED_ACHIEVEMENT_LIST" event, it fires after repairing mirror
end