-- hs.window.filter 내부 WebKit XPC 프로세스로 인한 에러 가드
--
-- 증상 (Hammerspoon 1.1.0):
--   LuaSkin: Unable to fetch NSRunningApplication for pid: NNNNN
--   hs.timer callback error: .../hs/uielement.lua:134: attempt to index a nil value
--
-- 원인:
--   hs.application.runningApplications()에 WebKit XPC 프로세스
--   (com.apple.WebKit.WebContent, 이름 "<앱이름> Web Content" / "Web Content Process")가
--   kind=0으로 포함된다. window_filter.lua의 startAppWatcher는 이를 GUI 앱으로 보고
--   focusedWindow()를 MAX_RETRIES(5)회 재시도한 뒤 force=true로 watcher를 만드는데,
--   이 프로세스는 pid로 NSRunningApplication을 얻을 수 없어 watcher:element()가 nil이 되고
--   watcherMT.start 안의 self:element():isApplication() 호출이 터진다.
--
-- 해결:
--   1) hs.window.filter.isGuiApp을 감싸 WebKit 헬퍼 프로세스 이름을 non-GUI로 판정
--      → startAppWatcher가 newWatcher 전에 빠져나가므로 LuaSkin 로그도 발생하지 않음
--   2) 안전망으로 hs.uielement.watcher:start에서 element를 얻을 수 없으면 시작을 건너뜀
--
-- init.lua에서 window.filter를 사용하는 모듈보다 먼저 require 해야 한다.

require("hs.uielement") -- watcherMT.start 정의를 먼저 로드한 뒤 덮어쓴다
local windowfilter = hs.window.filter

-- 1) WebKit XPC 헬퍼 프로세스 이름 패턴
local HELPER_PATTERNS = {
  "Web Content$",          -- "Safari Web Content", "Bambu Studio Web Content", ...
  "^Web Content Process$",
  "^Networking Process$",
  "^GPU Process$",
}

local origIsGuiApp = windowfilter.isGuiApp
windowfilter.isGuiApp = function(appname)
  if appname then
    for _, pat in ipairs(HELPER_PATTERNS) do
      if appname:find(pat) then return false end
    end
  end
  return origIsGuiApp(appname)
end

-- 2) 안전망: element를 얻을 수 없는 watcher는 시작하지 않음
local watcherMT = hs.getObjectMetatable("hs.uielement.watcher")
local origStart = watcherMT.start

function watcherMT.start(self, events)
  local ok, element = pcall(self.element, self)
  if not ok or not element then
    return self
  end
  return origStart(self, events)
end

local M = {}
return M
