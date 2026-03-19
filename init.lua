require('modules.inputsource_aurora')
require('modules.switch_inputsource_to_ABC_when_enter_vim_normal_mode')
require('modules.window_count_alert')

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
