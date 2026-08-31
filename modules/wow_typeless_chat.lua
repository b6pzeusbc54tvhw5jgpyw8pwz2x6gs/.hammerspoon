-- WoW + Typeless 음성 채팅 매크로
--
-- Typeless가 게임 화면 위 고정 위치에 띄워주는 복사 버튼을 클릭해
-- 음성 인식 텍스트를 복사한 뒤, WoW 채팅창에 엔터 → Cmd+V → 엔터로 전송한다.
--
-- 단축키: Cmd+Shift+A
--
-- 동작 방식:
--   1. 현재 마우스 위치 저장
--   2. Typeless 복사 버튼 좌표 클릭
--   3. 클립보드 changeCount가 바뀔 때까지 대기 (복사 완료 확인, 최대 1.5초)
--   4. 마우스 원위치 복구, WoW 재활성화(클릭으로 포커스를 잃었을 경우 대비)
--   5. return → Cmd+V → return 순서로 키 입력
--
-- Typeless 오버레이는 보통 포커스를 뺏지 않으므로 4번의 activate는 안전망이다.

local M = {}

-- ★ Typeless 복사 버튼의 실제 좌표로 수정할 것 (절대 좌표)
M.buttonPos = { x = 1922, y = 1988 }


-- 키 입력 간 간격(초). 게임 프레임(60fps=16ms)보다 약간만 길면 충분
local KEY_INTERVAL = 0.017
-- keydown-keyup 간격(마이크로초). hs.eventtap.keyStroke 기본값 200ms는 너무 느림
local KEY_PRESS_US = 8000
-- 클립보드 복사 대기 타임아웃(초)
local COPY_TIMEOUT = 2.5
-- 커서 이동 후 오버레이가 hover를 인지할 때까지 대기(초)
local HOVER_DELAY = 0.2

-- GC 방지를 위해 장수명 객체는 모듈 변수에 저장
local waitTimer = nil
local seqTimers = {}

local function sendChatSequence()
    seqTimers = {}
    hs.eventtap.keyStroke({}, "return", KEY_PRESS_US)
    seqTimers[1] = hs.timer.doAfter(KEY_INTERVAL, function()
        hs.eventtap.keyStroke({ "cmd" }, "v", KEY_PRESS_US)
        seqTimers[2] = hs.timer.doAfter(KEY_INTERVAL, function()
            hs.eventtap.keyStroke({}, "return", KEY_PRESS_US)
        end)
    end)
end

local function runMacro()
    local frontApp = hs.application.frontmostApplication()
    local originalMousePos = hs.mouse.absolutePosition()
    local beforeCount = hs.pasteboard.changeCount()

    -- Typeless 복사 버튼 클릭
    -- 주의: 커서 순간이동 직후 바로 클릭하면 오버레이가 hover를 인지하기 전이라
    -- 클릭이 밑의 WoW 레이어로 통과할 수 있다. 사람 클릭처럼
    -- 이동(mouseMoved) → hover 대기 → mouseDown → mouseUp 순서로 진행한다.
    local evt = hs.eventtap.event
    hs.mouse.absolutePosition(M.buttonPos)
    evt.newMouseEvent(evt.types.mouseMoved, M.buttonPos):post()
    seqTimers.down = hs.timer.doAfter(HOVER_DELAY, function()
        evt.newMouseEvent(evt.types.leftMouseDown, M.buttonPos):post()
        seqTimers.up = hs.timer.doAfter(0.08, function()
            evt.newMouseEvent(evt.types.leftMouseUp, M.buttonPos):post()
        end)
    end)

    local function restore()
        hs.mouse.absolutePosition(originalMousePos)
        if frontApp and not frontApp:isFrontmost() then
            frontApp:activate()
        end
    end

    -- 복사 완료(클립보드 변경)까지 대기 후 키 시퀀스 실행
    if waitTimer then waitTimer:stop() end
    waitTimer = hs.timer.waitUntil(
        function() return hs.pasteboard.changeCount() ~= beforeCount end,
        function()
            restore()
            -- activate 직후 바로 키를 보내면 씹힐 수 있어 한 틱 쉬어감
            seqTimers.kick = hs.timer.doAfter(0.02, sendChatSequence)
        end,
        0.05 -- 폴링 주기
    )
    -- 타임아웃: 클립보드가 안 바뀌면 중단하고 알림
    seqTimers.timeout = hs.timer.doAfter(COPY_TIMEOUT, function()
        if waitTimer and waitTimer:running() then
            waitTimer:stop()
            restore()
            hs.alert.show("Typeless 복사 실패 (클립보드 변경 없음)")
        end
    end)
end

M.hotkey = hs.hotkey.bind({ "cmd", "shift" }, "a", runMacro)

print("[wow_typeless_chat] module loaded (button: " .. M.buttonPos.x .. "," .. M.buttonPos.y .. ")")

return M
