--------------------------------------------------------------------------------
-- // STATS
--------------------------------------------------------------------------------

local position = {"BOTTOM", UIParent, 0, 14}
local font = STANDARD_TEXT_FONT		-- font family
local fontSize = 12               -- font size
local fontStyle = "OUTLINE"		    -- font style
local textAlign = "CENTER"        -- text justification
local numberAddOns = 40           -- number of addons to show in memory tooltip
local clock24 = true              -- show time in 24 hour format
local class = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

--------------------------------------------------------------------------------
-- // STATS FRAME
--------------------------------------------------------------------------------

local KlazStats = CreateFrame("Frame", "KlazStats", UIParent)
KlazStats:SetPoint(unpack(position))
KlazStats:SetWidth(300)
KlazStats:SetHeight(fontSize)
KlazStats:EnableMouse(true)

KlazStats.text = KlazStats:CreateFontString(nil, "BACKGROUND")
KlazStats.text:SetPoint(textAlign, KlazStats)
KlazStats.text:SetJustifyH(textAlign)
KlazStats.text:SetFont(font, fontSize, fontStyle)
KlazStats.text:SetTextColor(class.r, class.g, class.b)

--------------------------------------------------------------------------------
-- // CALCULATE MEMORY
--------------------------------------------------------------------------------

local function memFormat(number)
	if number > 1024 then
		return string.format("%.2f mb", (number / 1024))
	else
		return string.format("%.1f kb", floor(number))
	end
end

local function compareMemory(a, b)
	return a.memory > b.memory
end

--------------------------------------------------------------------------------
-- // FORMAT STATS TEXT
--------------------------------------------------------------------------------

local function getFPS()
	return "|cffffffff"..floor(GetFramerate()).."|r fps"
end

local function getLatencyRaw()
	return select(3, GetNetStats())
end

local function getLatency()
	return "|cffffffff"..getLatencyRaw().."|r ms"
end

local function getLatencyWorldRaw()
	return select(4, GetNetStats())
end

local function getLatencyWorld()
	return "|cffffffff"..getLatencyWorldRaw().."|r ms"
end

local function getTime()
	local t
  if clock24 then
    t = date("%H:%M")
    return "|cffffffff"..t.."|r "
  else
    t = date("|cffffffff%I:%M|r %p")
    return t
  end

end

local SLOTS = {}
for _, slot in pairs({
  "Head",
  "Shoulder",
  "Chest",
  "Waist",
  "Legs",
  "Feet",
  "Wrist",
  "Hands",
  "MainHand",
  "SecondaryHand"
}) do
  SLOTS[slot] = GetInventorySlotInfo(slot.."Slot")
end

local function durPercent(perc)
	perc = perc > 1 and 1 or perc < 0 and 0 or perc
	local seg, relperc = math.modf(perc*2)
	local r1, g1, b1, r2, g2, b2 = select(seg*3+1,1,0,0,1,1,0,1,1,1,0,0,0)
	local r, g, b = r1+(r2-r1)*relperc, g1+(g2-g1)*relperc, b1+(b2-b1)*relperc
	return format("|cff%02x%02x%02x", r*255, g*255, b*255), r, g, b
end

local function getDurability()
	local l = 1
	for slot, id in pairs(SLOTS) do
		local d, md = GetInventoryItemDurability(id)
		if d and md and md ~= 0 then
			l = math.min(d/md, l)
		end
	end
  return format("%s%d|r dur", durPercent(l), l*100)
end

--------------------------------------------------------------------------------
-- // CLICK GARBAGE COLLECTION
--------------------------------------------------------------------------------

KlazStats:SetScript("OnMouseDown", function()
  UpdateAddOnMemoryUsage()
	local before = gcinfo()
	collectgarbage()
	UpdateAddOnMemoryUsage()
	local after = gcinfo()
	print("|cff1994ffCleaned:|r "..memFormat(before-after))
end)

--------------------------------------------------------------------------------
-- // HOVER TOOLTIP
--------------------------------------------------------------------------------

KlazStats:SetScript("OnEnter", function(self)
  if not InCombatLockdown() then
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 12)

    local addons, total, nr, name = {}, 0, 0
    local blizz = collectgarbage("count")
    local entry, memory
    UpdateAddOnMemoryUsage()

    GameTooltip:AddLine("Stats", .098, .58, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(TRACK_QUEST_TOP_SORTING.." "..numberAddOns.." "..ADDONS, class.r, class.g, class.b)

    for i = 1, GetNumAddOns(), 1 do
      if GetAddOnMemoryUsage(i) > 0 then
        memory = GetAddOnMemoryUsage(i)
        entry = {name = GetAddOnInfo(i), memory = memory}
        table.insert(addons, entry)
        total = total + memory
      end
    end

    table.sort(addons, compareMemory)

    for _, entry in pairs(addons) do
      if nr < numberAddOns then
        GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, 1, 1, 1)
        nr = nr+1
      end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(TOTAL, memFormat(total), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(NETWORK_LABEL, class.r, class.g, class.b)
    GameTooltip:AddDoubleLine(HOME, getLatencyRaw().." ms", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(WORLD, getLatencyWorldRaw().." ms", 1, 1, 1, 1, 1, 1)

    GameTooltip:Show()
  end
end)

KlazStats:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

--------------------------------------------------------------------------------
-- // UPDATE STATS TEXT
--------------------------------------------------------------------------------

local lastUpdate = 0
local function updateStats(self,elapsed)
	lastUpdate = lastUpdate + elapsed

	if lastUpdate > 1 then
		lastUpdate = 0
		KlazStats.text:SetText(getFPS().."    "..getLatency().."    "..getDurability().."    "..getTime())
	end
end

KlazStats:RegisterEvent("PLAYER_LOGIN")
KlazStats:RegisterEvent("PLAYER_ENTERING_WORLD")
KlazStats:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
KlazStats:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:SetScript("OnUpdate", updateStats)
	end
end)
