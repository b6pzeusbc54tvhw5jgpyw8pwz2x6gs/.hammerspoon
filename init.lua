require('modules.inputsource_aurora')
require('modules.korean_alert_on_focus')
require('modules.switch_inputsource_to_ABC_when_enter_vim_normal_mode')
require('modules.window_count_alert')
require('modules.switch_to_abc_on_iterm2')
require('modules.show_inputsource_flag')
require('modules.hyper_key_overlay')

-- World of Warcraft 모듈 로드
local wow = require("modules.worldofwarcraft")
wow.start()

-- hs.hotkey.bind({"cmd"}, "k", function()
--     local currentPos = hs.mouse.getAbsolutePosition()
--     local newPos = {x = currentPos.x, y = currentPos.y + 64}
--     hs.mouse.setAbsolutePosition(newPos)
--     hs.eventtap.leftClick(newPos)
-- end)

-- hs.hotkey.bind({"cmd"}, "i", function()
--     local currentPos = hs.mouse.getAbsolutePosition()
--     local newPos = {x = currentPos.x, y = currentPos.y - 64}
--     hs.mouse.setAbsolutePosition(newPos)
--     hs.eventtap.leftClick(newPos)
-- end)
