local module = {}

-- World of Warcraft Bundle ID
local WOW_BUNDLE_ID = "com.blizzard.worldofwarcraft"

-- Karabiner Elements CLI 경로
local KARABINER_CLI = "\"/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli\""

-- Karabiner Elements 프로필 UUID
local WOW_PROFILE_UUID = "wow"
local DEFAULT_PROFILE_UUID = "Default profile"

-- 현재 활성화된 프로필 저장
local currentProfile = nil

-- 프로필 전환 함수
local function switchKarabinerProfile(profileUUID)
    -- 같은 프로필이면 전환하지 않음
    if currentProfile == profileUUID then
        return
    end
    
    local cmd = string.format('%s --select-profile "%s"', KARABINER_CLI, profileUUID)
    hs.execute(cmd)
    print("Karabiner profile switched to " .. profileUUID)
    currentProfile = profileUUID
end

-- WoW 활성화/비활성화에 따른 설정 변경 함수
local function handleWoWActivation(isWoWActive)
    if isWoWActive then
        -- WoW가 활성화될 때
        switchKarabinerProfile(WOW_PROFILE_UUID)
    else
        -- WoW가 비활성화될 때
        switchKarabinerProfile(DEFAULT_PROFILE_UUID)
    end
end

-- 앱 감시자 설정
local appWatcher = hs.application.watcher.new(function(name, event, app)
    if event == hs.application.watcher.activated then
        if app and app:bundleID() == WOW_BUNDLE_ID then
            handleWoWActivation(true)
        else
            handleWoWActivation(false)
        end
    end
end)

-- 모듈 초기화 함수
function module.start()
    appWatcher:start()
end

-- 모듈 중지 함수
function module.stop()
    appWatcher:stop()
    currentProfile = nil  -- 프로필 캐시 초기화
end

return module
