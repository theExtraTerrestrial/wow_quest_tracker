local WST = WrathStoryTracker

local checkboxes = {}
local headers = {}

WST.ui = {}

function WST.ui:Init()    
    local QUESTS_BY_ZONE = WrathStoryTracker_QUESTS_BY_ZONE or {}
    local ZONE_ORDER = WrathStoryTracker_ZONE_ORDER or {}
	
	local function IsQuestCompletedAPI(questID)
		if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
			return C_QuestLog.IsQuestFlaggedCompleted(questID)
		end
		return false
    end
	
	local function SaveProgress()
        for zone, cbList in pairs(checkboxes) do
            WrathStoryTrackerDB.completed[zone] = WrathStoryTrackerDB.completed[zone] or {}
            for i, cb in ipairs(cbList) do
                WrathStoryTrackerDB.completed[zone][i] = cb:GetChecked()
            end
        end
    end

    local function LoadProgress()
        for zone, quests in pairs(QUESTS_BY_ZONE) do
            checkboxes[zone] = checkboxes[zone] or {}
            WrathStoryTrackerDB.completed[zone] = WrathStoryTrackerDB.completed[zone] or {}
            for i, quest in ipairs(quests) do
                local cb = checkboxes[zone][i]
                if cb then
                    if IsQuestCompletedAPI(quest.id) then
                        cb:SetChecked(true)
                        cb:Disable()
                        WrathStoryTrackerDB.completed[zone][i] = true
                    elseif WrathStoryTrackerDB.completed[zone][i] ~= nil then
                        cb:SetChecked(WrathStoryTrackerDB.completed[zone][i])
                        cb:Enable()
                    else
                        cb:SetChecked(false)
                        cb:Enable()
                        WrathStoryTrackerDB.completed[zone][i] = false
                    end
                end
            end
        end
    end

    -- Main Frame
    local frame = CreateFrame("Frame", "WrathStoryTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 350)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Wrath Story Tracker")
    frame:SetAlpha(WrathStoryTrackerDB.opacity)

    -- Tabs
    local tabs = {}
    local function SelectTab(idx)
        for i, tab in ipairs(tabs) do
            if i == idx then
                PanelTemplates_SelectTab(tab)
                tab.content:Show()
            else
                PanelTemplates_DeselectTab(tab)
                tab.content:Hide()
            end
        end
        WrathStoryTrackerDB.tab = idx
    end

    -- Story Tab
    tabs[1] = CreateFrame("Button", "WrathStoryTrackerTab1", frame, "PanelTabButtonTemplate")
    tabs[1]:SetID(1)
    tabs[1]:SetText("Story")
    tabs[1]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 8, 2)
    tabs[1]:SetScript("OnClick", function(self) SelectTab(1) end)
    PanelTemplates_TabResize(tabs[1], 0)
    tabs[1].content = CreateFrame("Frame", nil, frame)
    tabs[1].content:SetAllPoints()
    tabs[1].content:Show()

    -- Settings Tab
    tabs[2] = CreateFrame("Button", "WrathStoryTrackerTab2", frame, "PanelTabButtonTemplate")
    tabs[2]:SetID(2)
    tabs[2]:SetText("Settings")
    tabs[2]:SetPoint("LEFT", tabs[1], "RIGHT", 4, 0)
    tabs[2]:SetScript("OnClick", function(self) SelectTab(2) end)
    PanelTemplates_TabResize(tabs[2], 0)
    tabs[2].content = CreateFrame("Frame", nil, frame)
    tabs[2].content:SetAllPoints()
    tabs[2].content:Hide()

    -- Opacity Slider in Settings tab
    local slider = CreateFrame("Slider", "WrathStoryTrackerOpacitySlider", tabs[2].content, "OptionsSliderTemplate")
    slider:SetWidth(150)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", 20, -60)
    slider:SetMinMaxValues(0.2, 1)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(WrathStoryTrackerDB.opacity)
    slider.textLow = _G[slider:GetName().."Low"]
    slider.textHigh = _G[slider:GetName().."High"]
    slider.text = _G[slider:GetName().."Text"]
    slider.textLow:SetText("20%")
    slider.textHigh:SetText("100%")
    slider.text:SetText("Opacity")
    slider:SetScript("OnValueChanged", function(self, value)
        WrathStoryTrackerDB.opacity = value
        frame:SetAlpha(value)
    end)

    -- Sync Button for Settings Tab (moved from Story Tab)
    local syncButton = CreateFrame("Button", nil, tabs[2].content, "UIPanelButtonTemplate")
    syncButton:SetSize(130, 24)
    syncButton:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -30)
    syncButton:SetText("Sync with API")
    syncButton:SetScript("OnClick", function()
        for _, zone in ipairs(ZONE_ORDER) do
            local quests = QUESTS_BY_ZONE[zone]
            if quests then
                checkboxes[zone] = checkboxes[zone] or {}
                WrathStoryTrackerDB.completed[zone] = WrathStoryTrackerDB.completed[zone] or {}
                for i, quest in ipairs(quests) do
                    local cb = checkboxes[zone][i]
                    if cb then
                        if IsQuestCompletedAPI(quest.id) then
                            cb:SetChecked(true)
                            cb:Disable()
                            WrathStoryTrackerDB.completed[zone][i] = true
                        else
                            cb:SetChecked(WrathStoryTrackerDB.completed[zone][i] or false)
                            cb:Enable()
                        end
                    end
                end
            end
        end
        print("Wrath Story Tracker: Synced quest completion with API.")
        SaveProgress()
    end)
	
	local function DumpTableError(tbl, name)
		name = name or "Table"
		if type(tbl) ~= "table" then
			error(name .. ": (not a table)")
		end
		local lines = {name .. " = {"}
		for k, v in pairs(tbl) do
			table.insert(lines, "  [" .. tostring(k) .. "] = " .. tostring(v))
			
		end
		table.insert(lines, "}")
		error(table.concat(lines, "\n"))
	end
	
	local dumpErrorButton = CreateFrame("Button", nil, tabs[2].content, "UIPanelButtonTemplate")
	dumpErrorButton:SetSize(180, 24)
	dumpErrorButton:SetPoint("TOPLEFT", syncButton, "BOTTOMLEFT", 0, -48)
	dumpErrorButton:SetText("Dump Collapsed (Error)")
	dumpErrorButton:SetScript("OnClick", function()
		DumpTableError(WrathStoryTrackerDB, "WrathStoryTrackerDB")
	end)
	

    -- Story Tab Functionality
    local HEADER_HEIGHT, CHECKBOX_HEIGHT = 28, 26
    local COLLAPSED_ICON = "Interface\\Buttons\\UI-PlusButton-UP"
    local EXPANDED_ICON = "Interface\\Buttons\\UI-MinusButton-UP"

    local scrollFrame = CreateFrame("ScrollFrame", nil, tabs[1].content, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabs[1].content, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", tabs[1].content, "BOTTOMRIGHT", -28, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    -- Top spacer for padding below title bar
    if not content.topSpacer then
        content.topSpacer = content:CreateTexture(nil, "BACKGROUND")
        content.topSpacer:SetColorTexture(0,0,0,0)
        content.topSpacer:SetPoint("TOPLEFT")
        content.topSpacer:SetPoint("TOPRIGHT")
        content.topSpacer:SetHeight(28)
    end


    local function ToggleZone(zone)        
        WrathStoryTrackerDB.collapsed[zone] = not WrathStoryTrackerDB.collapsed[zone]				
        frame:BuildCheckboxes()
        SaveProgress()
    end

    local function CreateDivider(parent, yOffset)
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.5, 0.5, 0.5, 1)
        line:SetHeight(1)
        line:SetPoint("LEFT", 6, 0)
        line:SetPoint("RIGHT", -6, 0)
        line:SetPoint("TOP", 0, yOffset)
        return line
    end

    function frame:BuildCheckboxes()		
        for _, cbList in pairs(checkboxes) do
            for _, cb in ipairs(cbList) do cb:Hide() end
        end
		for k in pairs(checkboxes) do checkboxes[k] = nil end
		for _, header in pairs(headers) do header:Hide() end
        for k in pairs(headers) do headers[k] = nil end
        if content.divider then content.divider:Hide(); content.divider = nil end
        if content.hiddenTitle then content.hiddenTitle:Hide(); content.hiddenTitle = nil end
        

        local yOffset = -28
        for _, zone in ipairs(ZONE_ORDER) do
            local isCollapsed = WrathStoryTrackerDB.collapsed[zone]
            if not isCollapsed then
                local quests = QUESTS_BY_ZONE[zone]
                if quests then
                    local header = headers[zone]					
                    if not header then
                        header = CreateFrame("Button", nil, content)
                        header:SetSize(340, HEADER_HEIGHT)
                        header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                        header.text:SetPoint("LEFT", 32, 0)
                        header.icon = header:CreateTexture(nil, "ARTWORK")
                        header.icon:SetSize(18, 18)
                        header.icon:SetPoint("LEFT", 8, 0)
                        header:SetNormalFontObject(GameFontNormalLarge)
                        header:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")						
                        header:SetScript("OnClick", function() ToggleZone(zone) end)
                        headers[zone] = header
                    end
                    header:SetPoint("TOPLEFT", 10, yOffset)
                    header.text:SetText(zone)
                    header.icon:SetTexture(EXPANDED_ICON)
                    header:Show()
                    yOffset = yOffset - HEADER_HEIGHT

                    checkboxes[zone] = checkboxes[zone] or {}

                    for i, quest in ipairs(quests) do
                        local cb = checkboxes[zone][i]
                        if not cb then
                            cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
                            cb.text:SetText(quest.name)
                            cb:SetScript("OnClick", function(self)
                                if self:GetChecked() and IsQuestCompletedAPI(quest.id) then
                                    self:SetChecked(true)
                                    self:Disable()
                                elseif IsQuestCompletedAPI(quest.id) then
                                    self:SetChecked(true)
                                    self:Disable()
                                else
                                    self:Enable()
                                end
                                SaveProgress()
                            end)
                            checkboxes[zone][i] = cb
                        end
                        cb:SetPoint("TOPLEFT", 32, yOffset)
                        if IsQuestCompletedAPI(quest.id) then
                            cb:SetChecked(true)
                            cb:Disable()
                        else
                            WrathStoryTrackerDB.completed[zone] = WrathStoryTrackerDB.completed[zone] or {}
                            cb:SetChecked(WrathStoryTrackerDB.completed[zone][i] or false)
                            cb:Enable()
                        end
                        cb:Show()
                        yOffset = yOffset - CHECKBOX_HEIGHT
                    end
                end
            end
        end

        local numCollapsed = 0
        for _, zone in ipairs(ZONE_ORDER) do
            if WrathStoryTrackerDB.collapsed[zone] then numCollapsed = numCollapsed + 1 end
        end
        if numCollapsed > 0 then
            yOffset = yOffset - 8
            content.divider = CreateDivider(content, yOffset)
            content.divider:Show()
            yOffset = yOffset - 22

            content.hiddenTitle = content.hiddenTitle or content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            content.hiddenTitle:SetPoint("TOPLEFT", 16, yOffset)
            content.hiddenTitle:SetText("Hidden")
            content.hiddenTitle:Show()
            yOffset = yOffset - HEADER_HEIGHT

            for _, zone in ipairs(ZONE_ORDER) do
                if WrathStoryTrackerDB.collapsed[zone] then
                    local header = headers[zone]
                    if not header then
                        header = CreateFrame("Button", nil, content)
                        header:SetSize(340, HEADER_HEIGHT)
                        header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                        header.text:SetPoint("LEFT", 32, 0)
                        header.icon = header:CreateTexture(nil, "ARTWORK")
                        header.icon:SetSize(18, 18)
                        header.icon:SetPoint("LEFT", 8, 0)
                        header:SetNormalFontObject(GameFontNormalLarge)
                        header:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
                        header:SetScript("OnClick", function() ToggleZone(zone) end)
                        headers[zone] = header
                    end
                    header:SetPoint("TOPLEFT", 10, yOffset)
                    header.text:SetText(zone)
                    header.icon:SetTexture(COLLAPSED_ICON)
                    header:Show()
                    yOffset = yOffset - HEADER_HEIGHT
                end
            end
        end

        content:SetHeight(math.abs(yOffset) + 20)		
    end

    frame:RegisterEvent("QUEST_TURNED_IN")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            self:BuildCheckboxes()
            LoadProgress()
            frame:SetAlpha(WrathStoryTrackerDB.opacity or 1)
        elseif event == "QUEST_TURNED_IN" then
            local questID = ...
            for _, zone in ipairs(ZONE_ORDER) do
                local quests = QUESTS_BY_ZONE[zone]
                if quests then
                    for i, quest in ipairs(quests) do
                        if questID == quest.id then
                            local cb = checkboxes[zone][i]
                            if cb then
                                cb:SetChecked(true)
                                cb:Disable()
                                WrathStoryTrackerDB.completed[zone][i] = true
                                SaveProgress()
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Tabs wiring
    PanelTemplates_SetNumTabs(frame, #tabs)
    PanelTemplates_UpdateTabs(frame)
    SelectTab(WrathStoryTrackerDB.tab or 1)

    frame:HookScript("OnShow", function(self)
        SelectTab(WrathStoryTrackerDB.tab or 1)
        slider:SetValue(WrathStoryTrackerDB.opacity or 1)
        self:SetAlpha(WrathStoryTrackerDB.opacity or 1)
    end)

    -- Slash command
    SLASH_WRATHSTORYTRACKER1 = "/wst"
    SlashCmdList["WRATHSTORYTRACKER"] = function()
        if frame:IsShown() then frame:Hide() else frame:Show() end
    end

    -- Make frame accessible for other modules if needed
    WST.ui.frame = frame
end