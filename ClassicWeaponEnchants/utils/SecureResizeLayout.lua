local _, addon = ...
local ADDON_ID = "ClassicWeaponEnchants"
local SecureResizeLayout = {}
function SecureResizeLayout:New(name, parent)
    ---@class SecureResizeLayout : Frame
    local frame = CreateFrame("Frame", name, parent, "SecureHandlerShowHideTemplate, BackdropTemplate")
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
        local usedButtons = 0;
        for i, child in ipairs(children) do
            ---@cast child Frame
            local childScale = child:GetEffectiveScale();
            local rect = newtable(); ---@type table
            local left, bottom, width, height = child:GetRect();
            if (left and bottom) 
            and (width > 0 and height > 0 )
            and child:IsShown()
            and child:IsObjectType("Button")
            then 
                usedButtons = usedButtons + 1;
                print("Button ID: ", child:GetID() )
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
                rect.name = child:GetName()
                tinsert(child_rects, rect)
            end
        end
        -- print ("used buttons", usedButtons)
        
        -- determine Top Left and Bottom Right based on childrects
        local minLeft, maxRight, maxTop, minBot
        local lName, rName, tName, bName
        for i, rect in ipairs(child_rects) do
            -- print(rect.name, rect.left, rect.right, rect.top, rect.bottom)
            if (not minLeft) or (rect.left < minLeft) then
                minLeft = rect.left
                lName = rect.name
            end
            if (not maxRight) or (rect.right > maxRight) then
                maxRight = rect.right
                rName = rect.name
            end
            if (not maxTop) or (rect.top > maxTop) then
                maxTop = rect.top
                tName = rect.name
            end
            if (not minBot) or (rect.bottom < minBot) then
                minBot = rect.bottom
                bName = rect.name
            end
        end
        if not (minLeft and maxRight and maxTop and minBot) then
            -- print("no child size data")
            self:Hide() -- no children, hide flyout 
            return;
        end
        -- -- left edge
        -- self:CallMethod("DebugLine", "left", minLeft, minBot, minLeft, maxTop)
        -- -- right edge
        -- self:CallMethod("DebugLine", "right", maxRight, minBot, maxRight, maxTop)
        -- -- top edge
        -- self:CallMethod("DebugLine", "top", minLeft, maxTop, maxRight, maxTop)
        -- -- bottom edge
        -- self:CallMethod("DebugLine", "bottom", minLeft, minBot, maxRight, minBot)
        -- set size of frame to bounding rect + padding
        local width = (maxRight - minLeft) + (%.4f*2)
        local height = (maxTop - minBot) + (%.4f*2)
        
        self:SetWidth(width)
        self:SetHeight(height)
        ]=]):format(widthPadding, heightPadding)
        frame:SetAttribute("_onshow", script)
    end
    -- assert(not SecureResizeLayout.OnShow, "OnShow already exists")
    -- SecureResizeLayout.OnShow = function(self)
    --     print("OnShow")
    --     self:Execute([=[self:RunAttribute("_onshow")]=])
    -- end
    function frame:ForceResize()
        self:ExecuteAttribute("_onshow")
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
    function frame:MarkDirty()
        -- not needed 
    end
    return frame
end


local newtable = function() return {} end
---@param self Frame
local function fun(self)
        -- self == layout
        -- steps in determining size:
        
        -- get all children.
        local children = newtable();
        self:GetChildList(children);
        
        local layoutScale = self:GetEffectiveScale();
        -- get all rects of valid children
        local child_rects = newtable();
        local usedButtons = 0;
        for i, child in ipairs(children) do
            ---@cast child Frame
            local childScale = child:GetEffectiveScale();
            local rect = newtable(); ---@type table
            local left, bottom, width, height = child:GetRect();
            if (left and bottom) 
            and (width > 0 and height > 0 )
            and child:IsShown()
            and child:IsObjectType("Button")
            then 
                usedButtons = usedButtons + 1;
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
                rect.name = child:GetName()
                tinsert(child_rects, rect)
            end
        end
        print ("used buttons", usedButtons)
        
        -- determine Top Left and Bottom Right based on childrects
        local minLeft, maxRight, maxTop, minBot
        local lName, rName, tName, bName
        for i, rect in ipairs(child_rects) do
            -- print(rect.name, rect.left, rect.right, rect.top, rect.bottom)
            if (not minLeft) or (rect.left < minLeft) then
                minLeft = rect.left
                lName = rect.name
            end
            if (not maxRight) or (rect.right > maxRight) then
                maxRight = rect.right
                rName = rect.name
            end
            if (not maxTop) or (rect.top > maxTop) then
                maxTop = rect.top
                tName = rect.name
            end
            if (not minBot) or (rect.bottom < minBot) then
                minBot = rect.bottom
                bName = rect.name
            end
        end
        if not (minLeft and maxRight and maxTop and minBot) then
            print("no child size data")
            self:Hide() -- no children, hide flyout 
            return;
        end
        -- -- left edge
        -- self:CallMethod("DebugLine", "left", minLeft, minBot, minLeft, maxTop)
        -- -- right edge
        -- self:CallMethod("DebugLine", "right", maxRight, minBot, maxRight, maxTop)
        -- -- top edge
        -- self:CallMethod("DebugLine", "top", minLeft, maxTop, maxRight, maxTop)
        -- -- bottom edge
        -- self:CallMethod("DebugLine", "bottom", minLeft, minBot, maxRight, minBot)
        -- set size of frame to bounding rect + padding

        -- local width = (maxRight - minLeft) + (%.4f*2)
        -- local height = (maxTop - minBot) + (%.4f*2)
        
        -- when the number of children is 1, looks pretieer centered 
        -- self:SetPoint("BOTTOM", self:GetFrameRef("RelativeAnchorFrame"), "BOTTOM", 0, %i)
        
        self:SetWidth(width)
        self:SetHeight(height)
end

-- 144.21641540527 76.10814666748 new
-- 145.47296142578 77.364837646484 old


addon.SecureResizeLayout = SecureResizeLayout