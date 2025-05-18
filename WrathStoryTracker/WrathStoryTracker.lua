WrathStoryTracker = WrathStoryTracker or {}
WrathStoryTrackerDB = WrathStoryTrackerDB or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "WrathStoryTracker" then
        if WrathStoryTracker.ui and WrathStoryTracker.ui.Init then
            WrathStoryTracker.ui:Init()
        end
        if WrathStoryTracker.minimap and WrathStoryTracker.minimap.Init then
            WrathStoryTracker.minimap:Init()
        end
    end
end)