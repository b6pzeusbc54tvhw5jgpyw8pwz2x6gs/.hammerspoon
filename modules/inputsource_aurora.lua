-- 한글일때 화면 상단 하단에 녹색 띠를 보여주는 모듈.

local boxes = {}
-- 자신이 사용하고 있는 English 인풋 소스 이름을 넣어준다
local inputEnglish = "com.apple.keylayout.ABC"
local box_height = 23
local box_alpha = 0.65
local GREEN = hs.drawing.color.osx_green

-- 입력소스 표시를 제외할 앱 bundleID 목록
local excludedBundleIDs = {
    "com.blizzard.worldofwarcraft",
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

-- 입력소스 변경 이벤트에 이벤트 리스너를 달아준다
hs.keycodes.inputSourceChanged(function()
    removeGreenBars()
    if hs.keycodes.currentSourceID() ~= inputEnglish then
        showGreenBars()
    end
end)

function showGreenBars()
    -- 제외 앱이면 그리지 않음
    local frontmostApp = hs.application.frontmostApplication()
    if isExcludedApp(frontmostApp) then return end

    reset_boxes()
    hs.fnutils.each(hs.screen.allScreens(), function(scr)
        local frame = scr:fullFrame()

        local box = newBox()
        draw_rectangle(box, frame.x, frame.y, frame.w, box_height, GREEN)
        table.insert(boxes, box)

        -- 화면 아래쪽에도 보여준다
        local box2 = newBox()
        draw_rectangle(box2, frame.x, frame.y + frame.h - 20, frame.w, box_height, GREEN)
        table.insert(boxes, box2)
    end)
end

function removeGreenBars()
    hs.fnutils.each(boxes, function(box)
        if box ~= nil then
            box:delete()
        end
    end)
    reset_boxes()
end

function newBox()
    return hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
end

function reset_boxes()
    boxes = {}
end

function draw_rectangle(target_draw, x, y, width, height, fill_color)
  target_draw:setSize(hs.geometry.rect(x, y, width, height))
  target_draw:setTopLeft(hs.geometry.point(x, y))

  target_draw:setFillColor(fill_color)
  target_draw:setFill(true)
  target_draw:setAlpha(box_alpha)
  target_draw:setLevel(hs.drawing.windowLevels.overlay)
  target_draw:setStroke(false)
  target_draw:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  target_draw:show()
end
