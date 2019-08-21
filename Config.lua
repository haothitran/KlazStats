local addon, ns = ...
local C = {}
ns.C = C

--------------------------------------------------------------------------------
-- // CORE / CONFIG
--------------------------------------------------------------------------------

C.NumberAddOns = 40                 -- number of addons to show in stats tooltip
C.Clock24 = true                    -- show time in 24 hour format

C.Font = {
  ["Family"] = STANDARD_TEXT_FONT,  -- font family
  ["Size"] = 12,                    -- font size
  ["Style"] = "OUTLINE",            -- font outline
  ["Align"] = "CENTER",             -- text justification
}

C.Size = {
  ["Width"] = 240,                  -- frame width
  ["Height"] = 24,                  -- frame height
}

C.Position = {
  ["Point"] = "CENTER",              -- attachment point to parent
	["RelativeTo"] = "UIParent",       -- parent frame
	["RelativePoint"] = "CENTER",      -- parent attachment point
	["XOffset"] = 0,                   -- horizontal offset from parent point
	["YOffset"] = 0,                   -- vertical offset from parent point
}
