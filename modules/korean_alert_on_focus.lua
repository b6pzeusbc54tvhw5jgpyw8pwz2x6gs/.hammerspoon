-- 창 포커스가 바뀔 때 한글 입력 상태이면 가운데 알림을 보여주는 모듈.

local inputEnglish = "com.apple.keylayout.ABC"

-- 알림을 제외할 앱 bundleID 목록
local excludedBundleIDs = {
    "com.blizzard.worldofwarcraft",
    "com.googlecode.iterm2",
}

local function isExcludedApp(appObj)
    if not appObj then return false end
    local bundleID = appObj:bundleID()
    for _, id in ipairs(excludedBundleIDs) do
        if bundleID == id then
            return true
        end
    end
    return false
end

local koreanAlertStyle = {
    textSize = 120,
    strokeColor = { alpha = 0 },
    fillColor = { alpha = 0 },
}

local wf = hs.window.filter.new():setDefaultFilter()
wf:subscribe(hs.window.filter.windowFocused, function(window, appName, event)
    local app = window and window:application()
    if isExcludedApp(app) then return end
    local currentSource = hs.keycodes.currentSourceID()
    if currentSource ~= inputEnglish then
        hs.alert.show("🇰🇷", koreanAlertStyle, 1)
    else
        hs.alert.show("🇺🇸", koreanAlertStyle, 1)
    end
end)
