local addon, ns = ...
local C = ns.C

--------------------------------------------------------------------------------
-- // STATS
--------------------------------------------------------------------------------

local loader = CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent', function(self, addon)
  if addon ~= KlazStats then
    local function initDB(db, defaults)
      if type(db) ~= 'table' then db = {} end
      if type(defaults) ~= 'table' then return db end
      for k, v in pairs(defaults) do
        if type(v) == 'table' then
          db[k] = initDB(db[k], v)
        elseif type(v) ~= type(db[k]) then
          db[k] = v
        end
      end
    return db
  end

    KlazStatsDB = initDB(KlazStatsDB, C.Position)
    C.UserPlaced = KlazStatsDB
    self:UnregisterEvent('ADDON_LOADED')
  end
end)

--------------------------------------------------------------------------------
-- // ANCHOR FRAME
--------------------------------------------------------------------------------

local anchor = CreateFrame('Frame', 'KlazStatsAnchor', UIParent)
anchor:SetSize(C.Size.Width, C.Size.Height)
if not anchor.SetBackdrop then Mixin(anchor, BackdropTemplateMixin) end
anchor:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background"})
anchor:SetFrameStrata('HIGH')
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:EnableMouse(true)
anchor:SetUserPlaced(true)
anchor:RegisterForDrag('LeftButton')
anchor:RegisterEvent('PLAYER_LOGIN')
anchor:Hide()

anchor.text = anchor:CreateFontString(nil, 'OVERLAY')
anchor.text:SetAllPoints(anchor)
anchor.text:SetFont(C.Font.Family, C.Font.Size, C.Font.Style)
anchor.text:SetShadowOffset(0, 0)
anchor.text:SetText('KlazStatsAnchor')

anchor:SetScript('OnEvent', function(self, event, arg1)
  if event == 'PLAYER_LOGIN' then
    self:ClearAllPoints()
    self:SetPoint(
    C.UserPlaced.Point,
    C.UserPlaced.RelativeTo,
    C.UserPlaced.RelativePoint,
    C.UserPlaced.XOffset,
    C.UserPlaced.YOffset)
  end
end)

anchor:SetScript('OnDragStart', function(self)
  self:StartMoving()
end)

anchor:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)

  point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1)
    if relativeTo then
      relativeTo = relativeTo:GetName();
    else
      relativeTo = self:GetParent():GetName();
    end

  C.UserPlaced.Point = point
  C.UserPlaced.RelativeTo = relativeTo
  C.UserPlaced.RelativePoint = relativePoint
  C.UserPlaced.XOffset = xOffset
  C.UserPlaced.YOffset = yOffset
end)

--------------------------------------------------------------------------------
-- // STATS FRAME
--------------------------------------------------------------------------------

local class = RAID_CLASS_COLORS[select(2, UnitClass('player'))]

local stats = CreateFrame('Frame', 'KlazStats', UIParent)
stats:SetAllPoints(anchor)
stats:SetSize(C.Size.Width, C.Size.Height)

stats.text = stats:CreateFontString(nil, 'BACKGROUND')
stats.text:SetPoint(C.Font.Align, stats)
stats.text:SetJustifyH(C.Font.Align)
stats.text:SetFont(C.Font.Family, C.Font.Size, C.Font.Style)
stats.text:SetTextColor(class.r, class.g, class.b)

--------------------------------------------------------------------------------
-- // CALCULATE MEMORY
--------------------------------------------------------------------------------

local function memFormat(number)
  if number > 1024 then
    return string.format('%.2f mb', (number / 1024))
  else
    return string.format('%.1f kb', floor(number))
  end
end

local function compareMemory(a, b)
  return a.memory > b.memory
end

--------------------------------------------------------------------------------
-- // STATS TEXT
--------------------------------------------------------------------------------

local function getFPS()
  return '|cffffffff'..floor(GetFramerate())..'|r fps'
end

local function getLatencyRaw()
  return select(3, GetNetStats())
end

local function getLatency()
  return '|cffffffff'..getLatencyRaw()..'|r ms'
end

local function getLatencyWorldRaw()
  return select(4, GetNetStats())
end

local function getLatencyWorld()
  return '|cffffffff'..getLatencyWorldRaw()..'|r ms'
end

local function getTime()
  local t
  if C.Clock24 == true then
    t = date('%H:%M')
    return '|cffffffff'..t..'|r '
  else
    t = date('|cffffffff%I:%M|r %p')
    return t
  end
end

local SLOTS = {}
for _, slot in pairs({
  'Head',
  'Shoulder',
  'Chest',
  'Waist',
  'Legs',
  'Feet',
  'Wrist',
  'Hands',
  'MainHand',
  'SecondaryHand'
}) do
  SLOTS[slot] = GetInventorySlotInfo(slot..'Slot')
end

local function durPercent(perc)
  perc = perc > 1 and 1 or perc < 0 and 0 or perc
  local seg, relperc = math.modf(perc*2)
  local r1, g1, b1, r2, g2, b2 = select(seg*3+1,1,0,0,1,1,0,1,1,1,0,0,0)
  local r, g, b = r1+(r2-r1)*relperc, g1+(g2-g1)*relperc, b1+(b2-b1)*relperc
  return format('|cff%02x%02x%02x', r*255, g*255, b*255), r, g, b
end

local function getDurability()
  local l = 1
  for slot, id in pairs(SLOTS) do
    local d, md = GetInventoryItemDurability(id)
    if d and md and md ~= 0 then
      l = math.min(d/md, l)
    end
  end
  return format('%s%d|r dur', durPercent(l), l*100)
end

--------------------------------------------------------------------------------
-- // CLICK GARBAGE COLLECTION
--------------------------------------------------------------------------------

stats:SetScript('OnMouseDown', function()
  UpdateAddOnMemoryUsage()
  local before = gcinfo()
  collectgarbage()
  UpdateAddOnMemoryUsage()
  local after = gcinfo()
  print('|cff1994ffCleaned:|r '..memFormat(before-after))
end)

--------------------------------------------------------------------------------
-- // TOOLTIP
--------------------------------------------------------------------------------

stats:SetScript('OnEnter', function(self)
  if IsModifierKeyDown() then return end
  if not InCombatLockdown() then
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:SetPoint('TOP', self, 'BOTTOM', 0, -12)

    local addons, total, nr, name = {}, 0, 0
    local blizz = collectgarbage('count')
    local entry, memory
    UpdateAddOnMemoryUsage()

    GameTooltip:AddLine('Stats', .098, .58, 1)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine(TRACK_QUEST_TOP_SORTING..' '..C.NumberAddOns..' '..ADDONS, class.r, class.g, class.b)

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
      if nr < C.NumberAddOns then
        GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, 1, 1, 1)
        nr = nr+1
      end
    end

    GameTooltip:AddLine(' ')
    GameTooltip:AddDoubleLine(TOTAL, memFormat(total), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine(NETWORK_LABEL, class.r, class.g, class.b)
    GameTooltip:AddDoubleLine(HOME, getLatencyRaw()..' ms', 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(WORLD, getLatencyWorldRaw()..' ms', 1, 1, 1, 1, 1, 1)

    GameTooltip:Show()
  end
end)

stats:SetScript('OnLeave', function()
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
    stats.text:SetText(getFPS()..'    '..getLatency()..'    '..getDurability()..'    '..getTime())
  end
end

stats:RegisterEvent('PLAYER_LOGIN')
stats:RegisterEvent('PLAYER_ENTERING_WORLD')
stats:RegisterEvent('UPDATE_INVENTORY_DURABILITY')
stats:SetScript('OnEvent', function(self, event)
  if event == 'PLAYER_LOGIN' then
    self:SetScript('OnUpdate', updateStats)
  end
end)

--------------------------------------------------------------------------------
-- // SLASH COMMAND
--------------------------------------------------------------------------------

SlashCmdList.KLAZSTATS = function (msg, editbox)
  if string.lower(msg) == 'reset' then
    KlazStatsDB = C.Position
    ReloadUI()
  elseif string.lower(msg) == 'unlock' then
    if not anchor:IsShown() then
      anchor:Show()
      print('|cff1994ffKlazStats|r |cff00ff00Unlocked.|r')
    end
  elseif string.lower(msg) == 'lock' then
    anchor:Hide()
    print('|cff1994ffKlazStats|r |cffff0000Locked.|r')
  else
    print('------------------------------------------')
    print('|cff1994ffKlazStats commands:|r')
    print('------------------------------------------')
    print('|cff1994ff/klazstats unlock|r Unlocks frame to be moved.')
    print('|cff1994ff/klazstats lock|r Locks frame in position.')
    print('|cff1994ff/klazstats reset|r Resets frame to default position.')
  end
end
SLASH_KLAZSTATS1 = '/klazstats'
SLASH_KLAZSTATS2 = '/kstats'
