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
    print("[korean_alert_on_focus] windowFocused: appName=" .. tostring(appName) .. ", window=" .. tostring(window))
    local app = window and window:application()
    if isExcludedApp(app) then
        print("[korean_alert_on_focus] excluded app, skipping")
        return
    end
    local currentSource = hs.keycodes.currentSourceID()
    print("[korean_alert_on_focus] inputSource=" .. tostring(currentSource))
    if currentSource ~= inputEnglish then
        print("[korean_alert_on_focus] Korean detected, showing alert")
        hs.alert.show("🇰🇷", koreanAlertStyle, 1)
    else
        print("[korean_alert_on_focus] English detected, showing alert")
        hs.alert.show("🇺🇸", koreanAlertStyle, 1)
    end
end)
print("[korean_alert_on_focus] windowFilter subscribed")
