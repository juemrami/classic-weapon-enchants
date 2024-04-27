local TOC_NAME, 
  ---@class ClassicWeaponEnchants
  private = ...;

local tempEnchantItems = private.ItemImbues
local tempEnchantSpells = private.SpellImbues


local suggestedIcons = {
  ["ROGUE"] = 136242, -- Poison
  ["WARRIOR"] = 135251, -- Sharpening Stone
  ["SHAMAN"] = 135814, -- flametounge icon
  ["CASTER"] = 134711, -- Wizard Oil
}
local _, class = UnitClass("player")
local FALLBACK_ICON = suggestedIcons[class] or suggestedIcons["CASTER"]

-- todo: refactor this num buttons stuff.
-- this terminology only makes sense for horizontal layouts. (left/right)
-- note: for the "UP" and "DOWN", to make the make the button stack vertically, im setting the number of rows to an arbirtatrily high number (32) that a user will never realistically have this many. to trigger a 2nd column from being created. This is not ideal, and immediate improvement is just just pick the nearest 2^n number to the number of buttons required for the flyout.
local BUTTON_X_SPACING = 4
local BUTTON_Y_SPACING = 6
local dragMouseButton = "LeftButton"
local DEBUG = false
local ADDON_ID = "ClassicWeaponEnchants"
assert(ADDON_ID == TOC_NAME, "ADDON_ID does not match toc's addon name", {toc = TOC_NAME, lua = ADDON_ID})
local BASE_BUTTON_ID = ADDON_ID .. "Button"
local MAIN_BUTTON_SIZE = 35 -- square


--- helper functions
local playerHasOffhand = IsDualWielding

local function getItemLevel(itemID)
  return select(4, GetItemInfo(itemID)) or 0
end
local function areFramesOverlapping(frame1, frame2)
  local left1, bottom1, width1, height1 = frame1:GetRect()
  local left2, bottom2, width2, height2 = frame2:GetRect()
  return not (
    left1 + width1 < left2 
    or left2 + width2 < left1 
    or bottom1 + height1 < bottom2 
    or bottom2 + height2 < bottom1 
  )
end 

local debugHeader = AZERITE_ESSENCE_COLOR:WrapTextInColorCode("["..ADDON_ID.."]: ")
local print = function(...)
  if DEBUG 
  or (ClassicWeaponEnchantsDB and ClassicWeaponEnchantsDB.debug) then
    _G.print(debugHeader, ...)
  end
end
local hooks = {}
local Frame_OnNextEvent = function(frame, event, callback, ...)
  ---@cast frame Frame
  assert(C_EventUtils.IsEventValid(event), "Event is not valid.")
  local firstRegister = not frame:IsEventRegistered(event)
  if firstRegister then
    frame:RegisterEvent(event)
  end
  local callbackArgs = { ... }
  local _hooks = hooks[frame] or 0
  hooks[frame] = _hooks + 1
  frame:HookScript("OnEvent", function(self, _event, ...)
    if _event == event then
      if #callbackArgs > 0 then
        callback(table.unpack(callbackArgs), ...)
      else
        callback(...)
      end
      if firstRegister then
        frame:UnregisterEvent(event)
      end
    end
  end)
  print("Num hooks for ", frame:GetName() or "nil", " :", _hooks)
end
--- 

---@class Addon : Frame
local addon = CreateFrame("Frame", ADDON_ID, UIParent, "SecureHandlerBaseTemplate");


--[[
  Hover Icon Frame aka the Flyout "toggle".
  ]]
---@class FlyoutToggle : Frame
local FlyoutButton = CreateFrame("Frame", nil, addon, "SecureHandlerEnterLeaveTemplate, SecureHandlerDragTemplate, SecureHandlerMouseUpDownTemplate")
FlyoutButton.Icon = FlyoutButton:CreateTexture(nil, "BACKGROUND", nil)
FlyoutButton.Highlight = FlyoutButton:CreateTexture(nil, "BACKGROUND", nil, 2)
FlyoutButton.Border = FlyoutButton:CreateTexture(nil, "OVERLAY", nil, 1)
FlyoutButton.BorderShadow = FlyoutButton:CreateTexture(nil, "OVERLAY", nil, 1)
FlyoutButton.FlyoutArrow = FlyoutButton:CreateTexture(nil, "OVERLAY", nil, 2)


function FlyoutButton:Init()
  self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  self:SetSize(MAIN_BUTTON_SIZE, MAIN_BUTTON_SIZE)

  -- Button Icon
  local iconSize = MAIN_BUTTON_SIZE - 2
  self.Icon:SetTexture(FALLBACK_ICON)
  self.Icon:SetTexCoord(0.01, 0.99, 0.01, 0.99)
  self.Icon:SetSize(iconSize, iconSize)
  self.Icon:SetPoint("CENTER")
  self.Icon:Show()

  --- Textures shown on mouseover and while the flyout is open.
  -- Highlight
  self.Highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
  self.Highlight:SetAllPoints(self.Icon, true)
  self.Highlight:SetBlendMode("ADD")
  self.Highlight:Hide()

  -- Border
  local borderSize = iconSize + 2
  self.Border:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  self.Border:SetTexCoord(0.01562500, 0.67187500, 0.39843750, 0.72656250)
  self.Border:SetSize(borderSize, borderSize)
  self.Border:SetPoint("CENTER", self.Icon)
  self.Border:Show()

  -- Border Shadow
  local shadowSize = borderSize + 6;
  self.BorderShadow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  self.BorderShadow:SetTexCoord(0.01562500, 0.76562500, 0.00781250, 0.38281250)
  self.BorderShadow:SetPoint("CENTER", self.Border)
  self.BorderShadow:SetSize(shadowSize, shadowSize)
  self.BorderShadow:Hide()

  -- Arrow texture to indicate flyout direction
  -- see "Interface\FrameXML\ActionButtonTemplate.xml"
  self.FlyoutArrow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
  self.FlyoutArrow:SetTexCoord(0.625, 0.984375, 0.7421875, 0.828125)
  self.FlyoutArrow:SetSize(MAIN_BUTTON_SIZE / (1.83), MAIN_BUTTON_SIZE / (3.82))
  self.FlyoutArrow:SetPoint("CENTER", self.Border, "TOP", 0, 2);
  self.FlyoutArrow:Show()
  SetClampedTextureRotation(self.FlyoutArrow, 0);

  --- Make Toggle draggable
  self:SetMovable(true);
  self:EnableMouse(true);
  self:RegisterForDrag(dragMouseButton);
  self:SetUserPlaced(true);
  local hideTooltipOnOverlap = function()
    if GameTooltip:IsShown() and areFramesOverlapping(FlyoutButton, GameTooltip) then
      C_Timer.After(0.25, GameTooltip_Hide)
    end
  end     
  self:SetScript("OnDragStart", function(self)
    self:StartMoving()
    self:SetScript("OnUpdate", hideTooltipOnOverlap)
  end);
  self:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetScript("OnUpdate", nil)
  end);

  -- fix to hide tooltip whenever toggle is overlapping it.
  self:SetClampedToScreen(true)

  -- self:SetFrameLevel(_G["MultiBarBottomLeftButton1"]:GetFrameLevel() + 1);
  return self

end
--- preserve og if ever using an actually button
local setEnabled = FlyoutButton.SetEnabled
function FlyoutButton:SetEnabled(enable)
  if setEnabled then
    setEnabled(self, enable)
  end
  if self.isEnabled == enable then return end
  if enable then
    if not InCombatLockdown() then
      -- FlyoutButton is secure. Need to call SetEnabled from-
      -- a secure scope to skip this check.
      self:Show()
    end
    self.FlyoutArrow:Show()
    self.Icon:SetDesaturated(false)
  else
    self.FlyoutArrow:Hide()
    self.Icon:SetDesaturated(true)
  end
  self.isEnabled = enable
end

function FlyoutButton:IsEnabled()
  return self.isEnabled
end

function FlyoutButton:LoadSavedVars()
  assert(ClassicWeaponEnchantsDB, "ClassicWeaponEnchantsDB not found. Ensure saved variables are loaded before calling this function.") 
  -- load saved position
  self:ClearAllPoints()
  local pos = ClassicWeaponEnchantsDB.ToggleOptions.position
  if pos.x == 0 and pos.y == 0 then
    self:SetPoint("CENTER", UIParent, "CENTER")
  else
    self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
  end
  -- add script to save position on move
  if not self.updateFuncHooked then 
    addon.FlyoutButton:HookScript("OnDragStop", function(self)
      -- local _, _, _, x, y = self:GetPoint()
      -- print(x,y)
      ---@cast self Frame
      local x, y = self:GetRect()
      ClassicWeaponEnchantsDB.ToggleOptions.position.x = x
      ClassicWeaponEnchantsDB.ToggleOptions.position.y = y
    end)
    self.updateFuncHooked = true
  end
  --- add secure scripts with any delay timer updates
  ---@diagnostic disable-next-line: undefined-field
  self:SetScripts()
  --- load preffered icon or use fallback
  self.Icon:SetTexture(ClassicWeaponEnchantsDB.ToggleOptions.icon or FALLBACK_ICON)
  self:SetShown(not ClassicWeaponEnchantsDB.ToggleOptions.hidden)

end

---@param shown boolean is flyout shown
local FlyoutButtonHoverTextures_SetActiveState = function(shown)
  local toggle = addon.FlyoutButton
  if shown then
    toggle.Highlight:Show()
    toggle.FlyoutArrow:SetRotation(math.pi)
    toggle.BorderShadow:Show()
  else
    toggle.Highlight:Hide()
    toggle.FlyoutArrow:SetRotation(0)
    toggle.BorderShadow:Hide()
  end
end
addon.FlyoutButton = FlyoutButton:Init()
--[[
  The Flyout frame itself.
]]
local LAYOUT_VERTICAL_PADDING = 12
local LAYOUT_HORIZONTAL_PADDING = 12
---@class FlyoutFrame : SecureResizeLayout
addon.FlyoutFrame = private.SecureResizeLayout:New(nil, addon)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  -- texture size for the edge and corner pieces of the frame
  edgeSize = 16, -- defaults to 39 if 0 or not set

  -- insets are the amount that center peice ie the bg is inset from the outer edge of the (frame)
  -- used to hide sharp bg edges under rounded corner textures
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
})

---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdropColor(0, 0, 0, 0.9)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.85)

local flyoutConfigs = {
  ["UP"] = {
    point = "BOTTOM",
    relativePoint = "TOP",
    x = 0,
    y = BUTTON_Y_SPACING - 1,
  },
  ["DOWN"] = {
    point = "TOP",
    relativePoint = "BOTTOM",
    x = 0,
    y = -BUTTON_Y_SPACING,
  },
  ["LEFT"] = {
    point = "RIGHT",
    relativePoint = "LEFT",
    x = -BUTTON_X_SPACING + 1,
    y = 0,
  },
  ["RIGHT"] = {
    point = "LEFT",
    relativePoint = "RIGHT",
    x = BUTTON_X_SPACING,
    y = 0,
  }
}
function addon.FlyoutFrame:UpdateDirection()
  --- todo refactor
  -- if this is called before button info is available then assume a state with 32 buttons.
  local numButtons = addon.GetNumButtons and addon:GetNumButtons() or 32
  local wasShown = addon.FlyoutFrame:IsVisible()
  local direction = ClassicWeaponEnchantsDB and ClassicWeaponEnchantsDB.FlyoutOptions.direction or "UP"
  local NUM_LINES = ClassicWeaponEnchantsDB and ClassicWeaponEnchantsDB.FlyoutOptions.numLines or 1
  local config = flyoutConfigs[direction]
  addon.FlyoutFrame:Hide()
  addon.FlyoutFrame:ClearAllPoints()
  addon.FlyoutFrame:SetPoint(
    config.point, addon.FlyoutButton, config.relativePoint, config.x, config.y
  )
  local arrowOfffset = 2
  if (direction == "LEFT") then
    SetClampedTextureRotation(addon.FlyoutButton.FlyoutArrow, 270);
    addon.FlyoutButton.FlyoutArrow:SetPoint("CENTER", addon.FlyoutButton.Border, "LEFT", -arrowOfffset, 0);
  elseif (direction == "RIGHT") then
    SetClampedTextureRotation(addon.FlyoutButton.FlyoutArrow, 90);
    addon.FlyoutButton.FlyoutArrow:SetPoint("CENTER", addon.FlyoutButton.Border, "RIGHT", arrowOfffset, 0);
  elseif (direction == "DOWN") then
    SetClampedTextureRotation(addon.FlyoutButton.FlyoutArrow, 180);
    addon.FlyoutButton.FlyoutArrow:SetPoint("CENTER", addon.FlyoutButton.Border, "BOTTOM", 0, -arrowOfffset);
  else -- UP
    SetClampedTextureRotation(addon.FlyoutButton.FlyoutArrow, 0);
    addon.FlyoutButton.FlyoutArrow:SetPoint("CENTER", addon.FlyoutButton.Border, "TOP", 0, arrowOfffset);
  end
  -- note: when using LEFT/RIGHT using NUM_BUTTONS is required to determine the number of children to use per row. When using UP/DOWN the number of children per row is always the numLines. ie numLines always control number of columns in the resulting layout. (no matter the orientation) 
  local childrenPerRow
  if direction == "UP" or direction == "DOWN" then
    childrenPerRow = NUM_LINES
  else
    childrenPerRow = math.ceil(numButtons / NUM_LINES)
  end
  addon.FlyoutFrame:SetChildrenLayout(childrenPerRow, BUTTON_X_SPACING, BUTTON_Y_SPACING, LAYOUT_HORIZONTAL_PADDING, LAYOUT_VERTICAL_PADDING)
  ---@diagnostic disable-next-line: inject-field
  addon.FlyoutFrame.widthPadding = LAYOUT_HORIZONTAL_PADDING
  ---@diagnostic disable-next-line: undefined-field
  addon.FlyoutFrame:SetHeightPadding(LAYOUT_VERTICAL_PADDING)

  if wasShown then
    addon.FlyoutFrame:Show()
  end
end

addon.FlyoutFrame:UpdateDirection()
addon.FlyoutFrame:SetClampedToScreen(true)
addon.FlyoutFrame:Hide()


local flyoutFrameDebugCache = {}
---@param key string
function addon.FlyoutFrame:BenchMarkStart(key)
  local _debugstart = debugprofilestop()
  local cache = flyoutFrameDebugCache[key] or {};
  cache.start = _debugstart
  flyoutFrameDebugCache[key] = cache
end
---@param key string
function addon.FlyoutFrame:BenchMarkStop(key)
  local _debugend = debugprofilestop()
  local cache = flyoutFrameDebugCache[key];
  if not cache then print("No cache for key: ", key) return end
  cache.stop = _debugend
  cache.elapsed = cache.stop - cache.start
  cache.samples = (cache.samples or 0) + 1
  cache.avg = cache.avg and (cache.avg + cache.elapsed) / 2 or cache.elapsed
  flyoutFrameDebugCache[key] = cache
end
function addon.FlyoutFrame:BenchMarkPrint(key)
  local cache = flyoutFrameDebugCache[key];
  if not cache then print("No cache for key: ", key) return end
  print(("%s took: %.4fms | avg: %.4fms | samples: %i"):format(key, cache.elapsed, cache.avg, cache.samples))
end
-----
-- FLYOUT ACTION BUTTONS
-----
addon.hidden = CreateFrame("Frame", nil, addon, "SecureHandlerBaseTemplate")
addon.hidden:Hide()

-- called once when a new button is added to the pool.
local buttonInitializer = function(button)
  ---@class FlyoutEnchantButton : Button
  ---@field icon Texture
  local button = button
  local size = button:GetSize()
  local scale = (MAIN_BUTTON_SIZE * 0.8) / size -- scale to NxN via "N/size"
  button:SetScale(scale)
  button:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
  button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
  button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")
  button:SetScript("OnLeave", GameTooltip_Hide);
  -- local nativeHide = self.Hide
  -- self.hideAnim = self:CreateAnimationGroup()
  -- local fade = self.hideAnim:CreateAnimation("Alpha")
  -- fade:SetFromAlpha(1)
  -- fade:SetToAlpha(0)
  -- fade:SetDuration(0.25)
  -- self.hideAnim:HookScript("OnFinished", function()
  --   if not InCombatLockdown() then
  --     nativeHide(self)
  --   end
  -- end)

  -- hack to get `SetItemButtonCount` to include count == 1
  button.used = false
  button.isBag = true
end

-- called when a button is released back into the pool, or initially added (after the initializer)
local buttonReseter = function(pool, button)
  ---@type FlyoutEnchantButton
  button:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]]);
  button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]]);
  button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD");
  (button.icon --[[@as Texture]]):SetDesaturated(false);
  button:SetParent(addon.FlyoutFrame)
  button:SetScript("OnEnter", nil)
  if not button:IsShown() then
    if not InCombatLockdown() then 
      button:Show() 
    else
      Frame_OnNextEvent(button,
        "PLAYER_REGEN_ENABLED", function()
          button:Show()
        end
      )
    end
  end
end
--- This function should "Disable" the button from the UI. The idea is that when called in combat it gray out a button and then once combat ends and we can perform secure actions, the button is actually hidden so that its not used by the resize layout. 
local disableButton = function(button)
  ---@cast button FlyoutEnchantButton
  button:ClearNormalTexture()  
  button:ClearPushedTexture()
  button:ClearHighlightTexture()
  button.icon:SetDesaturated(true)
  SetItemButtonCount(button, 0)
  button:SetScript("OnEnter", nil)
end

local ButtonPool = CreateFramePool("Button", addon.FlyoutFrame, "SecureActionButtonTemplate, ItemButtonTemplate", buttonReseter, false, buttonInitializer)
-- Reimple creationFunc to use a frame name
local createdCount = 0
local creationFunc = function(pool)
  createdCount = createdCount + 1
  local frame = CreateFrame(pool.frameType, "$parentActionItemButton"..createdCount, pool.parent, pool.frameTemplate)
  buttonInitializer(frame)
  return frame
end
ButtonPool.creationFunc = creationFunc

-- Reimpl aquire to always call resetter.
local aquireButton = ButtonPool.Acquire
function ButtonPool:Acquire()
  local button = aquireButton(self)
  buttonReseter(self, button)
  return button
end
-- Reimpl release to not call resetter on Release.
local releaseButton = ButtonPool.Release
function ButtonPool:Release(button)
  local ressterFunc = self.resetterFunc
  self.resetterFunc = nil
  releaseButton(self, button)
  disableButton(button)
  if ressterFunc then
    self.resetterFunc = ressterFunc
  end
end

-- function used after frame is hidden to abandon any children buttons that are not active in the pool. The resize layout will only reize based on its current children
-- call it after flyout is hidden so that the children remain hidden.
function ButtonPool:SetParentForInactiveButtons(parent)
  for _, button in self:EnumerateInactive() do
    ---@cast button FlyoutEnchantButton
    button:SetParent(parent)
  end
end

function ButtonPool:SetActive(button)
  if not self:IsActive(button) then
    -- iterate inactive for a button match.
    -- update self
      -- .(inactiveObjects, activeObjects, numActiveObjects)
    -- inactive should retain sequntial key indexes ie array.
    local inactive = {}
    for _, inactiveButton in ipairs(self.inactiveObjects) do
      if button == inactiveButton then
        tinsert(self.activeObjects, inactiveButton)
        self.numActiveObjects = self.numActiveObjects + 1
      else
        tinsert(inactive, inactiveButton)
      end
    end
    self.inactiveObjects = inactive
  end
  return false
end

local SetButtonAttributes = function(self, attributes)
  for attribute, value in pairs(attributes) do
    self:SetAttribute(attribute, value)
  end
end
local SetButtonQuality = function(self, quality)
  if quality then
    if quality >= LE_ITEM_QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] then
      self.IconBorder:Show()
      self.IconBorder:SetVertexColor(
        BAG_ITEM_QUALITY_COLORS[quality].r,
        BAG_ITEM_QUALITY_COLORS[quality].g,
        BAG_ITEM_QUALITY_COLORS[quality].b
      )
    else
      self.IconBorder:Hide()
    end
  else
    self.IconBorder:Hide()
  end
end

--- lookup for recently used buttons by spell ID to not have to modify attributes. This should be added into our button pool mixin imo. and on-aquire pass a spellID to prioritize reusing an inactive button that had the same spellID when it was last active.
local buttonBySpellID = {}

-- This function should handle securely/insecurely updating the flyout buttons.
local FlyoutFrame_UpdateButtons = function(self)
  addon.FlyoutFrame:BenchMarkStart("FlyoutFrame_UpdateButtons")
  ---@cast self FlyoutFrame
  local buttonInfo = addon:GetButtonInfo()
  -- mark all buttons as unused to be consumed by the pool.
  for _, button in pairs(buttonBySpellID) do
    button.used = false
  end
  -- generate flyout buttons
  -- iterate found button **info** to determine how many buttons we need and check if we can reuse any previously shown buttons.
  for _, info in ipairs(buttonInfo) do
    
    -- use itemID as a backup key but all buttons should have a spellID since items have an associated spell
    ---@type FlyoutEnchantButton
    local button = buttonBySpellID[info.spellID or info.itemID]
    if button then
      buttonReseter(nil, button)
      ButtonPool:SetActive(button)
    end
    if not button then
      button = ButtonPool:Acquire()
      buttonBySpellID[info.spellID or info.itemID] = button
    end
    button.used = true

    -- These should all be safe to call in combat.
    button:SetParent(self)
    ---@diagnostic disable-next-line: undefined-global
    SetItemButtonTexture(button, info.icon)
    if info.itemID then
      ---@diagnostic disable-next-line: undefined-global
      SetItemButtonCount(button, GetItemCount(info.itemID, false, true))
      SetButtonQuality(button, select(3, GetItemInfo(info.itemID)))
    end

    -- set button attributes, if the button was properly re-used then the attributes shouldnt need to be updated.
    if InCombatLockdown() then
      -- i think this branch will get hit whenever a new poison is created while in combat and a new button for it is required. That new button will not have any attributes set.(or the wrong ones)
      -- one way to hit this branch is to reload game while in combat.
      
      assert(
        button:GetAttribute("type1") == info.attributes.type1,
        "Exisiting Button reused but attributes are different",
        info.attributes,
        button:GetAttribute("type1"),
        info
      )
      -- in this case we cant set attributes so it will not be functional.

    elseif not InCombatLockdown() then
      SetButtonAttributes(button, info.attributes)
      -- add tooltip to reflect attributes
      button.setSpellID = info.spellID
      button:HookScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        -- use ItemSpell if enchant comes from item, else use spellID
        local spell = info.itemID
            and select(2, GetItemSpell(info.itemID))
            or info.spellID
        local ohExists = playerHasOffhand()
        local leftClickText = (ohExists and info.itemID)
        and "<Left-click to apply to main-hand>"
        or "<Left-click to apply to weapon>";
        local rightClickText = (ohExists and info.itemID)
        and "<Right-click to apply to off-hand>"
        or nil;
        GameTooltip:SetSpellByID(spell)
        GameTooltip:AddLine(leftClickText)
        GameTooltip:AddLine(rightClickText)
        GameTooltip:Show()
      end)
    end
    -- set tooltip to match attributes
    button:HookScript("OnEnter", function(button)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      -- use ItemSpell if enchant comes from item, else use spellID
      local isItem = info.itemID
      local ohExists = playerHasOffhand()
      if button:GetAttribute("type1") 
      and button.setSpellID == info.spellID 
      then
        local leftClickText = (ohExists and isItem)
        and "<Left-click to apply to main-hand>"
        or "<Left-click to apply to weapon>";
        local rightClickText = (ohExists and isItem)
        and "<Right-click to apply to off-hand>"
        or nil;
        GameTooltip:SetSpellByID(info.spellID)
        GameTooltip:AddLine(leftClickText)
        GameTooltip:AddLine(rightClickText)
        GameTooltip:Show()
      end
    end)
  end
  -- "disable" unused buttons
  for spellID, button in pairs(buttonBySpellID) do
    if not button.used then
      print("releasing button for : ", GetSpellLink(spellID))
      ButtonPool:Release(button)
      
      -- buttonBySpellID[spellID] = nil
      -- if i dont nil here then a button can be reused first by checking if a button with the same spellID was recently used.
      -- this however will not update the internal active/inactive tables of the pool so that should be done explicilty until the pool is reimplemented.
    end
  end
  -- this needs to be cleaned up. 
  if #buttonInfo > 0 then
    self:MarkDirty()
    if not InCombatLockdown() then
      ---@diagnostic disable-next-line: undefined-field
      self:Execute(self.layoutChildrenScript)
      ---@diagnostic disable-next-line: undefined-field
      self:Execute(self.resizeFrameScript)
    end
  end
  addon.FlyoutFrame:BenchMarkStop("FlyoutFrame_UpdateButtons")
  addon.FlyoutFrame:BenchMarkPrint("FlyoutFrame_UpdateButtons")
end
--- note that OnShow is only called when the frame was previously hidden.
addon.FlyoutFrame:HookScript("OnAttributeChanged",
  function(self, attribute, isHidden)
    if attribute ~= "statehidden" then return end
    FlyoutButtonHoverTextures_SetActiveState(not isHidden)
    if isHidden then -- OnHide
      GameTooltip_Hide()
      -- this will keep inactive buttons hidden when the flyout is hidden.
      -- they will remaing hidden untill 
      ButtonPool:SetParentForInactiveButtons(addon.hidden)
    else -- OnShow
      self:BenchMarkStop("Show Flyout")
      self:BenchMarkPrint("Show Flyout")
    end
  end
)

local cachedTargetBagItems = {}
local cachedTargetSpells = {}

--- refreshes `self.cachedButtonInfo` with the current enchant items and known spells.
---@param skipBags? boolean skips bags when refreshing button info.
function addon:RefreshButtonInfo(skipBags)
  addon.FlyoutFrame:BenchMarkStart("RefreshButtonInfo")
  local foundIDs = {}
  ---@type {[integer]: {bag: integer, slot: integer, info: ContainerItemInfo}}
  local itemInfo = {}
  ---@type {attributes: table<string,any>, icon: integer, count: integer?, itemID: integer?, spellID: number}[]
  local buttonInfo = {}
  local targetBagItems = {}
  for bag = 0, (skipBags and 0 or 4) do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info
          and info.itemID
          and tempEnchantItems[info.itemID]
      then
        if not itemInfo[info.itemID] then
          itemInfo[info.itemID] = {
            bag = bag,
            slot = slot,
            info = info
          }
          tinsert(foundIDs, info.itemID)
        else
          -- for multiple stacks of the same item
          -- only make a button for the one with the lowest amount of stacks + charges
          local prevItem = itemInfo[info.itemID]
          if info.stackCount < prevItem.info.stackCount then
            itemInfo[info.itemID] = {
              bag = bag,
              slot = slot,
              info = info
            }
          end
        end
        -- targetBagItems[bag] = targetBagItems[bag] or {}
        -- targetBagItems[bag][slot] = info.itemID
      end
    end
  end
  local targetSpells = {}
  for spellID, _ in pairs(tempEnchantSpells) do
    if IsSpellKnownOrOverridesKnown(spellID) then
      tinsert(foundIDs, spellID)
      -- targetSpells[spellID] = true
    end
  end

  -- -- check for bag updates
  -- local isUpdate = false
  -- for newBag, newSlot in pairs(targetBagItems) do
  --   if not cachedTargetBagItems[newBag] then
  --     isUpdate = true
  --     break
  --   end
  --   for slot, itemID in pairs(newSlot) do
  --     if not cachedTargetBagItems[newBag][slot] then
  --       isUpdate = true
  --       break
  --     elseif cachedTargetBagItems[newBag][slot] ~= itemID then
  --       isUpdate = true
  --       break
  --     end
  --   end
  -- end
  -- -- check for spell updates
  -- for spellID, _ in pairs(targetSpells) do
  --   if not cachedTargetSpells[spellID] then
  --     isUpdate = true
  --     break
  --   end
  -- end
  -- if not isUpdate then
  --   local _debugend = debugprofilestop()
  --   print(("RefreshButtonInfo took: %.4fms | no changes detected"):format(_debugend - _debugstart))
  --   return self.cachedButtonInfo
  -- end
  -- cachedTargetBagItems = targetBagItems
  -- cachedTargetSpells = targetSpells
  sort(foundIDs, function(a, b)
    return getItemLevel(a) < getItemLevel(b)
  end)
  local getItemMacroText = function(bag, slot, weapSlot)
    return ("/use %s %s\n/use %s\n/click StaticPopup1Button1")
        :format(bag, slot, weapSlot)
  end
  for i = 1, #foundIDs do
    local foundID = foundIDs[i]
    local item = itemInfo[foundID]
    if item then -- isItem
      -- https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate
      local attributes = {
        type1 = "macro",
        type2 = "macro",
        macrotext1 = getItemMacroText(item.bag, item.slot, 16),
        macrotext2 = getItemMacroText(item.bag, item.slot, 17),
        -- macrotext2 = playerHasOffhand()
        --   and getMacroText(item.bag, item.slot, 17)
        --   or nil,
      }
      tinsert(buttonInfo, {
        macrotext1 = getItemMacroText(item.bag, item.slot, 16),
        macrotext2 = getItemMacroText(item.bag, item.slot, 17),
        attributes = attributes,
        icon = item.info.iconFileID,
        itemID = foundID,
        -- could either use the hardcoded spellID or the spellID from the api
        -- spellID = tempEnchantItems[foundID].spell,
        spellID = select(2, GetItemSpell(foundID)),
        count = item.info.stackCount
      })
    else -- isSpell
      local spellName = GetSpellInfo(foundID)
      local attributes = {
        type1 = "macro",
        macrotext1 = spellName and ("/cast %s"):format(spellName)
      }
      tinsert(buttonInfo, {
        attributes = attributes,
        spellID = foundID,
        icon = GetSpellTexture(foundID)
      })
    end
  end
  self.cachedButtonInfo = buttonInfo
  addon.FlyoutFrame:BenchMarkStop("RefreshButtonInfo")
  return self.cachedButtonInfo
end

-- debug hook
hooksecurefunc(addon, "RefreshButtonInfo", function(self, skipBags)
  -- average time taken for RefreshButtonInfo
  addon.FlyoutFrame:BenchMarkPrint("RefreshButtonInfo")
end)


local numButtons = 0
function addon:GetButtonInfo()
  if self.refreshButtonCache or not self.cachedButtonInfo then
    self:RefreshButtonInfo()
    self.refreshButtonCache = false
  end
  local newSize = #self.cachedButtonInfo
  if numButtons ~= newSize then
    numButtons = newSize

    if InCombatLockdown() then
      Frame_OnNextEvent(addon, "PLAYER_REGEN_ENABLED", function()
        addon.FlyoutFrame:UpdateDirection();
      end)
    else 
      addon.FlyoutFrame:UpdateDirection();
    end
  end
  return self.cachedButtonInfo
end
function addon:GetNumButtons()
  return numButtons
end

--[[
  Setting up Secure Auto Hide for the flyout.
  allows in combat support
]]
local flyoutHandle = "FlyoutFrame"
local toggleHandle = "FlyoutButton"
---@diagnostic disable-next-line: undefined-field
addon.FlyoutButton:SetFrameRef(flyoutHandle, addon.FlyoutFrame)
---@diagnostic disable-next-line: undefined-field
addon.FlyoutButton:SetFrameRef(toggleHandle, addon.FlyoutButton)
local ShowFlyoutAndSetAutoHide = function(delay) 
  return ([=[
    local flyout = self:GetFrameRef("%s");
    if not flyout:IsShown() then 
      flyout:CallMethod("BenchMarkStart", "Show Flyout")
      local isFlyoutEmpty = true;
      local children = flyout:GetChildList(newtable());
      for i, child in ipairs(children) do
        if child:IsShown() and child:IsObjectType("Button") then
          isFlyoutEmpty = false;
          break;
        end
      end
      if not isFlyoutEmpty then
        flyout:Show();
      end
    end
    local toggle = self:GetFrameRef("%s");
    flyout:RegisterAutoHide(%.2f);
    flyout:AddToAutoHide(toggle);
  ]=]):format(flyoutHandle, toggleHandle, delay)
end

-- This feature is only active when flyout has nothing to show.
-- intending on adding a explicit show/hide feature for all other times.
local HideFlyoutButtonOnShiftRightClick = ([=[
  local flyout = self:GetFrameRef("%s");
  local children = flyout:GetChildList(newtable());
  local isFlyoutEmpty = true;
  for i, child in ipairs(children) do
    if child:IsShown() and child:IsObjectType("Button") then
      isFlyoutEmpty = false;
      break;
    end
  end
  if isFlyoutEmpty then
    if IsShiftKeyDown() and button == "RightButton"
    then
      self:Hide();
    end
  end
]=]):format(flyoutHandle)

---@diagnostic disable-next-line: inject-field
function addon.FlyoutButton:SetScripts()
  local hideDelay = ClassicWeaponEnchantsDB and ClassicWeaponEnchantsDB.FlyoutOptions.hideDelay or 0.5
  addon.FlyoutButton:SetAttribute("_onenter", ShowFlyoutAndSetAutoHide(hideDelay))
  addon.FlyoutButton:SetAttribute("_onreceivedrag", ShowFlyoutAndSetAutoHide(hideDelay))
  addon.FlyoutButton:SetAttribute("_onmouseup", HideFlyoutButtonOnShiftRightClick)
end
addon.FlyoutButton:HookScript("OnEnter", function(self)
  -- self:RefreshButtonInfo()
  GameTooltip:SetOwner(self, "ANCHOR_NONE")
  if self:IsEnabled() then
    -- GameawwTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 3, 0)
    -- GameTooltip:SetText("Left-click an enchant to apply to main-hand.\nRight-click to apply to off-hand.")
    FlyoutButtonHoverTextures_SetActiveState(true)
  else
    assert(HideFlyoutButtonOnShiftRightClick, "HideFlyoutButtonOnShiftRightClick script should be defined")
    GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 3)
    GameTooltip:SetText("No enchants available.\n<Shift Right Click to Hide Icon>")
  end
end);
addon.FlyoutButton:HookScript("OnLeave", function(self)
  GameTooltip_Hide()
end)
local BUTTON_UPDATE_EVENTS = {
  BAG_UPDATE_DELAYED = true,
  PLAYER_ENTERING_WORLD = true,
  SPELLS_CHANGED = true,
  PLAYER_REGEN_DISABLED = false,
  PLAYER_REGEN_ENABLED = false
}
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("SPELLS_CHANGED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("ADDON_LOADED")
local debounceTimeout = 0.5 -- seconds
local debounceTimer; ---@type cbObject?
local debounce = function(event, callback, timeout)
  if debounceTimer and not debounceTimer:IsCancelled() then
    debounceTimer:Cancel()
    -- print("debounced, canceling previous timer.")
  end
  -- print("update for ", event, " in", timeout, "seconwwds")
  debounceTimer = C_Timer.NewTimer(timeout, callback)
end
function addon:CancelUpdateTimer()
  if debounceTimer and not debounceTimer:IsCancelled() then
    debounceTimer:Cancel()
  end
end
-- this function can be delayed by a debounce timer. or called immediately if the flyout is shown.
local refreshAndUpdateButtons = function()
  local buttons = addon:RefreshButtonInfo()
  assert(buttons, "button info should be defaulted to an empty table")

  -- optimistically update toggle UI based on button info that will be used to update the flyout.
  local enableFlyoutToggle = #buttons > 0 or addon.FlyoutFrame:IsVisible()
  if enableFlyoutToggle ~= addon.FlyoutButton:IsEnabled() then
    addon.FlyoutButton:SetEnabled(enableFlyoutToggle)
  end
  -- this ui state should be verified after the flyout is actually shown in the onattributechanged hook in the case where no buttons are able to be show but button info exists.

  -- the bug is happening because we are trying to SetAttribute here which requires us to not be in combat.

  -- these attributes should be set on game load and then only updated when the flyout is hidden and out of combat.
  -- self.FlyoutButton:SetAttribute("_onenter", ShowFlyoutAndSetAutoHide)
  -- self.FlyoutButton:SetAttribute("_onreceivedrag", ShowFlyoutAndSetAutoHide)
  -- self.FlyoutButton:SetAttribute("_onmouseup", nil)

  -- edge cases for re-hiding the flyout when it doesnt have children should be handled in the secure code for the flyout maybe.

  -- additionally any incombat checks should be handled deeper in the called functions i think. OnEvent should just be routing the events to the correct functions. keep logic/scope concise here.
  -- flyout can now be shown/hidden in combat, only thing we cant do is update attributes, so instead of reflowing buttons when one goes unused durring combat we should just pseudo hide it (0 alpha/desaturate, deregister mouse, etc) untill combat ends at which point we can update the button attributes and propperly remove the button from the layout.
  FlyoutFrame_UpdateButtons(addon.FlyoutFrame)
end
-- call this once on load incase player is in combat.
refreshAndUpdateButtons()

---@class ClassicWeaponEnchantsDB
local defaultOptionsDB = {
  debug = false, 
  ToggleOptions = {
    ---@type {x: number, y: number}
    position = {x = 0, y = 0},
    ---@type "hover"|"toggle
    mode = "hover",
    ---@type integer?
    icon = nil, -- fallback
    hidden = false,
  },
  FlyoutOptions = {
    ---@type "UP"|"DOWN"|"LEFT"|"RIGHT"
    direction = "UP",
    ---@type integer
    numLines = 1,
    ---@type number
    hideDelay = 0.5,
  }
}
local setupSavedVariables = function()
  local nilExceptions = {
    ["icon"] = true, -- nilable to allow for fallback to suggestedIcons
  }
  local function validateTable(old, current, keepMissing)
    -- add any missing keys and assert types for old table.
    for key, default in pairs(current) do
      if old[key] == nil
      or type(old[key]) ~= type(default)
      then
        local reason = old[key] == nil 
          and "Missing Key."
          or ("Missmatched Types. old: %s | new: %s"):format(type(old[key]), type(default))
        print("DB Key: ", key, ", sets to default: ", default, " Reason: ", reason)
        old[key] = default
      elseif type(default) == "table" then
        validateTable(old[key], default)
      end
    end
    if keepMissing then
      return old
    end
    -- remove any keys that are not in the new table
    for key, _ in pairs(old) do
      if not nilExceptions[key]
        and current[key] == nil
      then
        print("Removing deprecated DB key: ", key)
        old[key] = nil
      elseif type(current[key]) == "table" then
        validateTable(old[key], current[key])
      end
    end
    return old
  end
  local savedVars = ClassicWeaponEnchantsDB or defaultOptionsDB
  -- validate saved variables w/ default options table
  if savedVars ~= defaultOptionsDB then
    savedVars = validateTable(savedVars, defaultOptionsDB, true)
  end
  ---@cast savedVars ClassicWeaponEnchantsDB
  
  -- update global refrence to match validated vars
  ClassicWeaponEnchantsDB = savedVars
  return ClassicWeaponEnchantsDB
end

addon:HookScript("OnEvent", function(self, event, ...)
  if BUTTON_UPDATE_EVENTS[event] then
    -- only debounce when the flyout is hidden.
    if not addon.FlyoutFrame:IsVisible() then
      debounce(event, refreshAndUpdateButtons, debounceTimeout)
    else -- if its open we want to see any changes immediately.
      refreshAndUpdateButtons()
    end
    if event == "PLAYER_ENTERING_WORLD" then
      setupSavedVariables()
      addon.FlyoutButton:LoadSavedVars()
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    print("in combat")
    addon.FlyoutFrame:ForceResize()
  elseif event == "PLAYER_REGEN_ENABLED" then
    print("out of combat")
  elseif event == "ADDON_LOADED" 
    and  ADDON_ID == ...
  then
    setupSavedVariables()
    addon.FlyoutButton:LoadSavedVars()
    DEBUG = ClassicWeaponEnchantsDB.debug
  end
end)

-- create slash commands for flyout direction
local WhenSafe = function(callback, ...)
  if InCombatLockdown() then
    Frame_OnNextEvent(addon, "PLAYER_REGEN_ENABLED", callback, ...)
  else
    callback(...)
  end
end
local slashCmdID = ADDON_ID:upper()
_G["SLASH_"..slashCmdID..1] = "/cwe"
local parseCommand = function(line)
  assert(ClassicWeaponEnchantsDB, "ClassicWeaponEnchantsDB not found")
  local cmd, arg1, arg2 = strsplit(' ', line or "", 3);
	if (cmd == "dir" or cmd == "direction" ) then
		arg1 = arg1:upper()
    if arg1 == "UP" or arg1 == "DOWN" or arg1 == "LEFT" or arg1 == "RIGHT" then
      ClassicWeaponEnchantsDB.FlyoutOptions.direction = arg1
      WhenSafe(function()
        addon.FlyoutFrame:UpdateDirection()
        DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Flyout's direction set to: "..arg1)
      end)
    else
      DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Usage: /cwe direction {up|down|left|right}")
    end
  elseif cmd == "reset" then
    ---@diagnostic disable-next-line: inject-field
    ClassicWeaponEnchantsDB.ToggleOptions = defaultOptionsDB.ToggleOptions
    ---@diagnostic disable-next-line: inject-field
    ClassicWeaponEnchantsDB.FlyoutOptions = defaultOptionsDB.FlyoutOptions
    WhenSafe(function() 
      addon.FlyoutButton:LoadSavedVars()
      addon.FlyoutFrame:UpdateDirection()
      DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."All settings reset to default!")
    end)
  elseif cmd == "show" then
    ClassicWeaponEnchantsDB.ToggleOptions.hidden = false
    WhenSafe(addon.FlyoutButton.LoadSavedVars, addon.FlyoutButton)
  elseif cmd == "hide" then
    ClassicWeaponEnchantsDB.ToggleOptions.hidden = true
    WhenSafe(addon.FlyoutButton.LoadSavedVars, addon.FlyoutButton)
  elseif cmd == "debug" then
    -- todo, dont print anything before saved vars are loaded.
    DEBUG = not DEBUG
    ---@diagnostic disable-next-line: inject-field
    ClassicWeaponEnchantsDB.debug = DEBUG
    DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Debug mode set to: "..tostring(DEBUG))
  elseif cmd == "lines" then
    local numLines = tonumber(arg1)
    if numLines then
      ClassicWeaponEnchantsDB.FlyoutOptions.numLines = numLines
      WhenSafe(function()
        addon.FlyoutFrame:UpdateDirection()
        DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Flyout lines set to: "..numLines)
      end)
    else
      DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Usage: /cwe lines {number}")
    end
  elseif cmd == "delay" then
    local delay = tonumber(arg1) or 0
    delay = Clamp(delay, .20, 5)
    if delay then
      ClassicWeaponEnchantsDB.FlyoutOptions.hideDelay = delay
      WhenSafe(function()
        addon.FlyoutButton:SetScripts()
        DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Flyout's auto-hide delay set to: "..("%.02f sec"):format(delay))
      end)
    else
      DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Usage: `/cwe delay {number}` (numbers between .25 and 5)")
    end
  elseif cmd == "icon" then
    local presets = {
      [0] = FALLBACK_ICON,
      [1] = 136242, -- Poison
      [2] = 134711, -- Wizard Oil
      [3] = 135251, -- Sharpening Stone
      [4] = 135814, -- flametounge icon
    }
    local icon = tonumber(arg1) or GetFileIDFromPath(arg1)
    if icon and presets[icon] then
      icon = presets[icon]
    end
    local inIconIDRange = function(n)
      -- https://wago.tools/db2/TextureFileData?build=1.15.1.53623&sort[FileDataID]=asc
      return n >= 117000 and n <= 5583000
    end
    if icon and inIconIDRange(icon) then
      if icon == FALLBACK_ICON then
        -- hack, 
        -- since FlyoutButton.LoadSavedVars will set the icon to the fallback if the db value is nil.
        -- This allows the `0` option icon to remain dynamic based on the class.
        ClassicWeaponEnchantsDB.ToggleOptions.icon = nil
      else
        ClassicWeaponEnchantsDB.ToggleOptions.icon = icon
      end
      WhenSafe(function()
        addon.FlyoutButton:LoadSavedVars()
        DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Flyout's icon set to:  "..arg1.." "..CreateSimpleTextureMarkup(icon, 16, 16))
      end)
    else
      DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Usage: `/cwe icon {iconID}` or `/cwe icon {iconFilePath}`")
    end
  else
		DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Usage: /cwe {command} {arg}")
    DEFAULT_CHAT_FRAME:AddMessage(debugHeader.."Commands: dir|direction, reset, show, hide")
		return;
	end
end
SlashCmdList[slashCmdID] = parseCommand