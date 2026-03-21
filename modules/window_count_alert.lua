local M = {}

local rules = {
    { app = "Google Chrome", limit = 7 },
    { app = "iTerm2",        limit = 6 },
}

local alerted = {}

local function checkWindows()
    for _, rule in ipairs(rules) do
        local app = hs.application.get(rule.app)
        local count = app and #app:allWindows() or 0
        if count >= rule.limit and not alerted[rule.app] then
            hs.alert.show("⚠ " .. rule.app .. " 창이 " .. count .. "개입니다. 정리하세요!", 3)
            alerted[rule.app] = true
        elseif count < rule.limit then
            alerted[rule.app] = false
        end
    end
end

local wf = hs.window.filter.new():setDefaultFilter()
M.watcher = wf:subscribe(
    hs.window.filter.windowFocused,
    checkWindows
)

return M
