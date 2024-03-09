local _, addon = ...
local ADDON_ID = "ClassicWeaponEnchants"
---@class SecureResizeLayout : Frame
local SecureResizeLayout = {}
function SecureResizeLayout:New(name, parent)
    ---@class SecureResizeLayout : Frame
    local frame = CreateFrame("Frame", name, parent, "SecureHandlerShowHideTemplate, BackdropTemplate, SecureHandlerBaseTemplate")
    frame.ignoreInLayout = {}
    assert(frame.Show, "Show is not defined")
    function frame:_DebugLine(edge, frameName)
        local line = _G[frameName.."Line"]
        or _G[frameName]:CreateLine(frameName.."Line")
        ---@cast line Line
        line:SetColorTexture(1, 0, 0, 1)
        line:SetDrawLayer("OVERLAY", 1)
        if edge == "LEFT" then
            line:SetStartPoint("TOPLEFT", frameName)
            line:SetEndPoint("BOTTOMLEFT", frameName)
        elseif edge == "RIGHT" then
            line:SetStartPoint("TOPRIGHT", frameName)
            line:SetEndPoint("BOTTOMRIGHT", frameName)
        elseif edge == "TOP" then
            line:SetStartPoint("TOPLEFT", frameName)
            line:SetEndPoint("TOPRIGHT", frameName)
        elseif edge == "BOTTOM" then
            line:SetStartPoint("BOTTOMLEFT", frameName)
            line:SetEndPoint("BOTTOMRIGHT", frameName)
        end
        line:SetThickness(2)
        line:Show()
    end
    function frame:DebugLine(name, x1, y1, x2, y2)
        local line = _G[name] or self:CreateLine(name)
        ---@cast line Line
        line:SetColorTexture(1, 0, 0, 1)
        line:SetDrawLayer("OVERLAY", 1)
        line:SetStartPoint("BOTTOMLEFT", UIParent, x1 , y1)
        line:SetEndPoint("BOTTOMLEFT", UIParent, x2, y2)
        line:SetThickness(2)
        line:Show()
    end
    function frame:MarkButton(button, number)
       ---@cast button Button
        local id  = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        id:SetText(number)
        id:SetPoint("CENTER", button)
        id:SetTextColor(1, 0, 0, 1)
    end
    local SetSecureResizeScript = function()
        local uiScale = frame:GetEffectiveScale()
        assert(uiScale == UIParent:GetScale(), "uiScale is not UIParent:GetScale()")
        local widthPadding = frame.widthPadding * uiScale
        local heightPadding = frame.heightPadding * uiScale
        local script = ([=[
        -- self == layout
        -- steps in determining size:
        
        -- get all children.
        local children = newtable();
        self:GetChildList(children);
        
        local layoutScale = self:GetEffectiveScale();
        -- get all rects of valid children
        local child_rects = newtable();
        for i, child in ipairs(children) do
            local childScale = child:GetEffectiveScale();
            local rect = newtable(); ---@type table
            local left, bottom, width, height = child:GetRect();
            if (left and bottom) 
            and (width > 0 and height > 0 )
            and child:IsShown()
            and child:IsObjectType("Button")
            then 
                -- if child has a valid rect, track it
                local uiScale = childScale / layoutScale
                left = left * uiScale
                bottom = bottom * uiScale
                width = width * uiScale
                height = height * uiScale
                
                rect.left = left
                rect.right = left + width
                rect.top = bottom + height
                rect.bottom = bottom
                tinsert(child_rects, rect)
            end
        end
        
        -- determine Top Left and Bottom Right based on childrects
        local minLeft, maxRight, maxTop, minBot
        for i, rect in ipairs(child_rects) do
            -- print(rect.name, rect.left, rect.right, rect.top, rect.bottom)
            if (not minLeft) or (rect.left < minLeft) then
                minLeft = rect.left
            end
            if (not maxRight) or (rect.right > maxRight) then
                maxRight = rect.right
            end
            if (not maxTop) or (rect.top > maxTop) then
                maxTop = rect.top
            end
            if (not minBot) or (rect.bottom < minBot) then
                minBot = rect.bottom
            end
        end
        if not (minLeft and maxRight and maxTop and minBot) then
            print("No children for flyout being shown. Not ReHiding")
            self:Hide() -- no children, hide flyout 
            return;
        end

        -- set size of frame to bounding rect + padding
        local width = (maxRight - minLeft) + (%.4f*2)
        local height = (maxTop - minBot) + (%.4f*2)
        
        self:SetWidth(width)
        self:SetHeight(height)
        ]=]):format(widthPadding, heightPadding)
        frame.resizeFrameScript = script
        script = frame.layoutChildrenScript .. script
        frame:SetAttribute("_onshow", script)
    end
    function frame:ForceResize()
        self:ExecuteAttribute("_onshow")
    end
    ---@param childrenPerRow number
    ---@param horizontalSpacing number
    ---@param verticalSpacing number
    ---@param horizontalPadding number?
    ---@param verticalPadding number?
    function frame:SetChildrenLayout(childrenPerRow, horizontalSpacing, verticalSpacing, horizontalPadding, verticalPadding)
        local script = ([=[
        local flyout = self
        local children = flyout:GetChildList(newtable());
        local col = 1
        local row = 1
        local maxRowElements = %i --[[MAX_ROW_BUTTONS]]
        local horizontalSpacing = %.2f --[[BUTTON_X_SPACING]]
        local verticalSpacing = %.2f --[[BUTTON_Y_SPACING]]
        local horizontalPadding = %.2f --[[LAYOUT_HORIZONTAL_PADDING]]
        local verticalPadding = %.2f --[[LAYOUT_VERTICAL_PADDING]]
        local buttonIdx = 0;
        local shownButtons = newtable();
        for _, child in ipairs(children) do
            if child:IsObjectType("Button") 
            and child:IsShown()
            then
                -- print(buttonIdx)
                buttonIdx = buttonIdx + 1
                shownButtons[buttonIdx] = child
                child:SetID(buttonIdx)
                child:ClearAllPoints()
                if col == 1 then
                    -- usually anchor to first of previous row
                    local relativeTo = shownButtons[buttonIdx - maxRowElements]
                    local relativePoint = "TOPLEFT"
                    local xOffset = 0
                    local yOffset = verticalSpacing
                    
                    -- but for first of initial row only anchor to flyout 
                    if row == 1 then
                        relativeTo = flyout
                        relativePoint = "BOTTOMLEFT"
                        xOffset =  horizontalPadding
                        yOffset =  verticalPadding
                    end

                    child:SetPoint("BOTTOMLEFT", relativeTo, relativePoint, xOffset, yOffset)
                else
                    -- anchor to button directly to left button if not initial row button
                    child:SetPoint("LEFT", shownButtons[buttonIdx - 1], "RIGHT", horizontalSpacing, 0)
                end
                
                col = col + 1
                if col > maxRowElements then
                    col = 1
                    row = row + 1
                end
            end
        end;
        ]=]):format(childrenPerRow, horizontalSpacing or 2, verticalSpacing or 2, self.widthPadding or horizontalPadding, self.heightPadding or verticalPadding)
        print("script made")
        self.layoutChildrenScript = script
    end
    function frame:SetFrameRef(name, frame)
        SecureHandlerSetFrameRef(frame, name, frame)
    end
    function frame:SetHeightPadding(px)
        self.heightPadding = px
        SetSecureResizeScript();
    end
    function frame:SetWidthPadding(px)
        self.widthPadding = px
        SetSecureResizeScript();
    end
    function frame:MarkIgnoreInLayout(button)
        self.ignoreInLayout[button] = true
        button:SetParent(_G[ADDON_ID])
        button:SetAllPoints(_G[ADDON_ID].FlyoutButton)
        -- button:SetFrameLevel(_G[ADDON_ID].FlyoutButton:GetFrameLevel() - 2)
    end
    -- migration support from resizelayouttemplate
    function frame:MarkDirty()
        self:ForceResize()
    end
    function frame:SecureExecute(script)
        return SecureHandlerExecute(self, script)
    end
    return frame
end


local newtable = function() end
---@param self Frame
local function resizeFrame(self)
        --    -- self == layout
        -- -- steps in determining size:
        
        -- -- get all children.
        -- local children = newtable();
        -- self:GetChildList(children);
        
        -- local layoutScale = self:GetEffectiveScale();
        -- -- get all rects of valid children
        -- local child_rects = newtable();
        -- local usedButtons = 0;
        -- for i, child in ipairs(children) do
        --     ---@cast child Frame
        --     local childScale = child:GetEffectiveScale();
        --     local rect = newtable(); ---@type table
        --     local left, bottom, width, height = child:GetRect();
        --     if (left and bottom) 
        --     and (width > 0 and height > 0 )
        --     and child:IsShown()
        --     and child:IsObjectType("Button")
        --     then 
        --         usedButtons = usedButtons + 1;
        --         -- print("Button ID: ", child:GetID() )
        --         -- if child has a valid rect, track it
        --         local uiScale = childScale / layoutScale
        --         left = left * uiScale
        --         bottom = bottom * uiScale
        --         width = width * uiScale
        --         height = height * uiScale
                
        --         rect.left = left
        --         rect.right = left + width
        --         rect.top = bottom + height
        --         rect.bottom = bottom
        --         rect.name = child:GetName()
        --         tinsert(child_rects, rect)
        --     end
        -- end
        -- -- print ("used buttons", usedButtons)
        
        -- -- determine Top Left and Bottom Right based on childrects
        -- local minLeft, maxRight, maxTop, minBot
        -- local lName, rName, tName, bName
        -- for i, rect in ipairs(child_rects) do
        --     -- print(rect.name, rect.left, rect.right, rect.top, rect.bottom)
        --     if (not minLeft) or (rect.left < minLeft) then
        --         minLeft = rect.left
        --         lName = rect.name
        --     end
        --     if (not maxRight) or (rect.right > maxRight) then
        --         maxRight = rect.right
        --         rName = rect.name
        --     end
        --     if (not maxTop) or (rect.top > maxTop) then
        --         maxTop = rect.top
        --         tName = rect.name
        --     end
        --     if (not minBot) or (rect.bottom < minBot) then
        --         minBot = rect.bottom
        --         bName = rect.name
        --     end
        -- end
        -- if not (minLeft and maxRight and maxTop and minBot) then
        --     -- print("no child size data")
        --     self:Hide() -- no children, hide flyout 
        --     return;
        -- end
        -- -- -- left edge
        -- -- self:CallMethod("DebugLine", "left", minLeft, minBot, minLeft, maxTop)
        -- -- -- right edge
        -- -- self:CallMethod("DebugLine", "right", maxRight, minBot, maxRight, maxTop)
        -- -- -- top edge
        -- -- self:CallMethod("DebugLine", "top", minLeft, maxTop, maxRight, maxTop)
        -- -- -- bottom edge
        -- -- self:CallMethod("DebugLine", "bottom", minLeft, minBot, maxRight, minBot)
        -- -- set size of frame to bounding rect + padding
        -- local width = (maxRight - minLeft) + (%.4f*2)
        -- local height = (maxTop - minBot) + (%.4f*2)
        
        -- self:SetWidth(width)
        -- self:SetHeight(height)
end
local function orderChildren(self)
    -- local flyout = self
    -- local children = newtable();
    -- flyout:GetChildList(children);
    -- local col = 1
    -- local row = 1
    -- local maxRowElements = %i --[[MAX_ROW_BUTTONS]]
    -- local horizontalSpacing = %.2f --[[BUTTON_X_SPACING]]
    -- local verticalSpacing = %.2f --[[BUTTON_Y_SPACING]]
    -- local horizontalPadding = %.2f --[[LAYOUT_HORIZONTAL_PADDING]]
    -- local verticalPadding = %.2f --[[LAYOUT_VERTICAL_PADDING]]
    -- local buttonIdx = 0;
    -- local shownButtons = newtable();
    -- for _, child in ipairs(children) do
    --     if child:IsObjectType("Button") 
    --     and child:IsShown()
    --     then
    --         -- print(buttonIdx)
    --         buttonIdx = buttonIdx + 1
    --         shownButtons[buttonIdx] = child
    --         child:SetID(buttonIdx)
    --         child:ClearAllPoints()
    --         if col == 1 then
    --             -- usually anchor to first of previous row
    --             local relativeTo = shownButtons[buttonIdx - maxRowElements]
    --             if relativeTo then 
    --                 local left, bottom, width, height = relativeTo:GetRect();
    --                 local scale = relativeTo:GetEffectiveScale() / flyout:GetEffectiveScale()
    --                 left = left * scale
    --                 bottom = bottom * scale
    --                 width = width * scale
    --                 height = height * scale
    --                 local x1, y1, x2, y2 = left, bottom+height, left+width, bottom+height;
    --                 print("first col button: ", child:GetID())
    --                 print("relativeTo to: ", relativeTo:GetID())
    --                 self:CallMethod("DebugLine", "top", x1, y1, x2, y2)
    --             end;
    --             local relativePoint = "TOPLEFT"
    --             local xOffset = 0
    --             local yOffset = verticalSpacing
                
    --             -- but for first of initial row only anchor to flyout 
    --             if row == 1 then
    --                 relativeTo = flyout
    --                 relativePoint = "BOTTOMLEFT"
    --                 xOffset =  horizontalPadding
    --                 yOffset =  verticalPadding
    --             end                    
    --             child:SetPoint("BOTTOMLEFT", relativeTo, relativePoint, xOffset, yOffset)
    --             local left, bottom, width, height = child:GetRect();
    --             local scale = child:GetEffectiveScale() / flyout:GetEffectiveScale()
    --             left = left * scale
    --             bottom = bottom * scale
    --             width = width * scale
    --             height = height * scale
    --             -- left edge
    --             local x1, y1, x2, y2 = left, bottom, left, bottom+height;
    --             self:CallMethod("DebugLine", "left-edge", x1, y1, x2, y2)
    --             -- bottom edge
    --             local x1, y1, x2, y2 = left, bottom, left+width, bottom;
    --             self:CallMethod("DebugLine", "bottom-edge", x1, y1, x2, y2)
    --         else
    --             -- anchor to button directly to left button if not initial row button
    --             child:SetPoint("LEFT", shownButtons[buttonIdx - 1], "RIGHT", horizontalSpacing, 0)
    --         end
            
    --         col = col + 1
    --         if col > maxRowElements then
    --             col = 1
    --             row = row + 1
    --         end
    --     end
    -- end;
end
-- 144.21641540527 76.10814666748 new
-- 145.47296142578 77.364837646484 old


addon.SecureResizeLayout = SecureResizeLayout