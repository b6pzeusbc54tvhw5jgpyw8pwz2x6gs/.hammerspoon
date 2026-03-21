-- Hyper+0 으로 현재 입력 소스 국기를 보여주는 모듈

local inputEnglish = "com.apple.keylayout.ABC"
local hyper = {"cmd", "alt", "ctrl", "shift"}

local flagAlertStyle = {
    textSize = 120,
    strokeColor = { alpha = 0 },
    fillColor = { alpha = 0 },
}

hs.hotkey.bind(hyper, "0", function()
    local currentSource = hs.keycodes.currentSourceID()
    if currentSource ~= inputEnglish then
        hs.alert.show("🇰🇷", flagAlertStyle, 1)
    else
        hs.alert.show("🇺🇸", flagAlertStyle, 1)
    end
end)
