local WST = WrathStoryTracker
WST.minimap = {}

function WST.minimap:Init()
    local frame = WST.ui.frame

    local minimapButton = CreateFrame("Button", "WrathStoryTrackerMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    minimapButton:SetMovable(true)
    minimapButton:SetUserPlaced(true)

    minimapButton:SetNormalTexture("Interface\\AddOns\\WrathStoryTracker\\icon.tga")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-Background")

    minimapButton:SetScript("OnClick", function()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end)

    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("Wrath Story Tracker")
        GameTooltip:AddLine("Click to toggle window.", 1, 1, 1)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end