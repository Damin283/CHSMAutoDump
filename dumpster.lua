--[[
    Dumpster Utility Pro
    Version: 1.4.0

    UPDATE LOG
    v1.4.0
    - 쓰레기통별 경유 좌표 + 실제 위치 분리
    - 2번 쓰레기통 진입/복귀 경로 분리
    - 경로 순차 이동 + 도착 확인/재시도 유지
    - 쓰레기통 대기 시간 4.7초 (2번 기준), 나머지 기본 4.5초
    - NPC 대기 4초 유지

    v1.3.3
    - 쓰레기통 수거 대기 시간 4.5초로 변경
    - NPC 대기 시간 4초로 변경
    - 목적지 도착 확인 및 이동 재시도 처리
    - 이동 관련 안정성 개선

    v1.3.2
    - UI 종료 및 재실행 안정성 개선

    v1.3.1
    - 자잘한 버그 수정 및 안정성 개선
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local LIBRARY_URL =
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"

-- 설정
local npcWaitTime = 4
local defaultDumpsterWaitTime = 4.5
local dumpster2WaitTime = 4.7

local arrivalTolerance = 5
local arrivalTimeout = 3
local maxMoveAttempts = 3

-- 상태
local enabled = false
local closed = false
local running = false
local currentIndex = 0
local cycleCount = 0

--[[
    각 쓰레기통 정의
    waypoints = 진입 경로 (마지막이 실제 쓰레기통)
    returnWaypoints = 복귀 경로 (있으면 사용, 없으면 진입 역순에서 마지막 제외)
    waitTime = 이 쓰레기통에서 대기할 시간
]]
local dumpsters = {
    -- 1번
    {
        name = "1번",
        waypoints = {
            Vector3.new(59.3844, 726.2589, -553.9585), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
    -- 2번 (진입 + 전용 복귀)
    {
        name = "2번",
        waypoints = {
            Vector3.new(-49.812450134277344, 726.3965454101562, -548.9459838867188),
            Vector3.new(-60.85980224609375, 726.3966064453125, -775.8695678710938),
            Vector3.new(-128.3144073486328, 726.6795654296875, -762.6356201171875),
            Vector3.new(-127.90377044677734, 726.6796264648438, -623.9077758789062), -- 실제
        },
        returnWaypoints = {
            Vector3.new(-127.90377044677734, 726.6796264648438, -623.9077758789062),
            Vector3.new(-128.3144073486328, 726.6795654296875, -762.6356201171875),
            Vector3.new(-60.85980224609375, 726.3966064453125, -775.8695678710938),
        },
        waitTime = dumpster2WaitTime,
    },
    -- 3번
    {
        name = "3번",
        waypoints = {
            Vector3.new(359.06683349609375, 709.7947998046875, -772.297607421875), -- 경유
            Vector3.new(342.5182189941406, 710.3426513671875, -900.2728271484375), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
    -- 4번
    {
        name = "4번",
        waypoints = {
            Vector3.new(747.9673461914062, 710.4390258789062, -889.592041015625), -- 경유
            Vector3.new(917.7178955078125, 709.6536865234375, -760.108154296875), -- 경유
            Vector3.new(1090.612060546875, 710.4390258789062, -815.144287109375), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
    -- 5번
    {
        name = "5번",
        waypoints = {
            Vector3.new(1073.725830078125, 719.2354736328125, -712.980224609375), -- 경유
            Vector3.new(1044.5260009765625, 710.4390258789062, -610.3722534179688), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
    -- 6번
    {
        name = "6번",
        waypoints = {
            Vector3.new(1109.643310546875, 709.6878662109375, -366.28631591796875), -- 경유
            Vector3.new(1036.7313232421875, 711.1288452148438, -136.04592895507812), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
    -- 7번
    {
        name = "7번",
        waypoints = {
            Vector3.new(1144.709716796875, 709.6878662109375, 5.922271184921265), -- 경유
            Vector3.new(1149.110107421875, 709.6878662109375, 207.83314514160156), -- 경유
            Vector3.new(749.5130615234375, 710.841796875, 206.46275329589844), -- 경유
            Vector3.new(750.3395385742188, 710.841796875, 345.1310119628906), -- 실제
        },
        waitTime = defaultDumpsterWaitTime,
    },
}

-- NPC 좌표
local npcPosition = Vector3.new(
    91.52301025390625,
    726.2588850097656,
    -625.6691284179688
)

-- 라이브러리 로드
local loadOK, Library = pcall(function()
    return loadstring(game:HttpGet(LIBRARY_URL))()
end)

if not loadOK or type(Library) ~= "table" then
    warn("[Dumpster] LinoriaLib 로드 실패:", Library)
    return
end

-- UI
local Window = Library:CreateWindow({
    Title = "Dumpster Utility Pro | v1.4.0",
    Center = true,
    AutoShow = true,
})

local MainTab = Window:AddTab("Main")
local LogTab = Window:AddTab("업데이트 로그")

local Controls = MainTab:AddLeftGroupbox("자동 순회")
local Progress = MainTab:AddRightGroupbox("진행 상황")
local Logs = LogTab:AddLeftGroupbox("변경 이력")

local statusLabel = Progress:AddLabel("대기 중")

local function setStatus(message)
    print("[Dumpster v1.4.0]", message)

    if not closed then
        pcall(function()
            statusLabel:SetText(message)
        end)
    end
end

-- 업데이트 로그
Logs:AddLabel("v1.4.0 — 쓰레기통별 경유 경로 + 2번 복귀 경로")
Logs:AddLabel("2번 대기 4.7초 / 나머지 4.5초 / NPC 4초")
Logs:AddLabel("경로 순차 이동 + 도착 확인/재시도 유지")
Logs:AddLabel(" ")
Logs:AddLabel("v1.3.3 — 이동 확인 및 재시도 개선")
Logs:AddLabel("쓰레기통 대기 4.5초 / NPC 대기 4초")
Logs:AddLabel("이동 관련 안정성 개선")
Logs:AddLabel(" ")
Logs:AddLabel("v1.3.2 — UI 종료 및 재실행 안정성 개선")
Logs:AddLabel("v1.3.1 — 자잘한 버그 수정")
Logs:AddLabel("v1.3.0 — 반복 순회 기능 추가")

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 단일 좌표 이동 (도착 확인 + 재시도)
local function moveToPosition(position)
    if not enabled or closed then
        return false
    end

    for attempt = 1, maxMoveAttempts do
        if not enabled or closed then
            return false
        end

        local root = getRoot()

        if not root then
            setStatus("캐릭터를 찾을 수 없음")
            return false
        end

        root.CFrame = CFrame.new(position)

        local deadline = os.clock() + arrivalTimeout

        repeat
            if not enabled or closed then
                return false
            end

            root = getRoot()

            if not root then
                break
            end

            local distance = (root.Position - position).Magnitude

            if distance <= arrivalTolerance then
                return true
            end

            task.wait(0.1)
        until os.clock() >= deadline

        if attempt < maxMoveAttempts then
            setStatus(("이동 확인 실패 — 재시도 %d/%d"):format(
                attempt,
                maxMoveAttempts
            ))
            task.wait(0.25)
        end
    end

    setStatus("목적지 도착 실패 — 순회를 중지합니다")
    return false
end

-- 경로(여러 경유점) 순차 이동
local function moveAlongPath(waypoints, label)
    if not waypoints or #waypoints == 0 then
        return false
    end

    for i, pos in ipairs(waypoints) do
        if not enabled or closed then
            return false
        end

        setStatus(("%s — 경유 %d/%d"):format(label, i, #waypoints))

        if not moveToPosition(pos) then
            return false
        end
    end

    return true
end

local function waitCancelable(seconds)
    local deadline = os.clock() + seconds

    while os.clock() < deadline do
        if not enabled or closed then
            return false
        end

        task.wait(0.05)
    end

    return enabled and not closed
end

local function runCycle()
    if running or closed then
        return
    end

    running = true

    while enabled and not closed do
        -- NPC로 이동
        setStatus("NPC 위치로 이동 중")

        if not moveToPosition(npcPosition) then
            break
        end

        setStatus(("NPC 대기 — %.1f초"):format(npcWaitTime))

        if not waitCancelable(npcWaitTime) then
            break
        end

        -- 쓰레기통 순회
        local interrupted = false

        for index, dumpster in ipairs(dumpsters) do
            if not enabled or closed then
                interrupted = true
                break
            end

            currentIndex = index

            -- 진입 경로
            if not moveAlongPath(dumpster.waypoints, dumpster.name .. " 진입") then
                interrupted = true
                break
            end

            local waitTime = dumpster.waitTime or defaultDumpsterWaitTime

            setStatus(("%s — %.1f초 대기"):format(dumpster.name, waitTime))

            if not waitCancelable(waitTime) then
                interrupted = true
                break
            end

            -- 2번만 전용 복귀 경로
            if dumpster.returnWaypoints then
                if not moveAlongPath(dumpster.returnWaypoints, dumpster.name .. " 복귀") then
                    interrupted = true
                    break
                end
            end
        end

        if interrupted or not enabled or closed then
            break
        end

        -- NPC로 복귀
        setStatus("NPC 위치로 복귀 중")

        if not moveToPosition(npcPosition) then
            break
        end

        cycleCount += 1
        currentIndex = 0

        setStatus(("순회 %d회 완료 — NPC에서 %.1f초 대기"):format(
            cycleCount,
            npcWaitTime
        ))

        if not waitCancelable(npcWaitTime) then
            break
        end
    end

    running = false

    if not closed then
        if enabled then
            enabled = false
            setStatus("이동 실패 — 자동 순회를 중지했습니다")
        else
            setStatus(("일시 중지 — 순회 %d회, 쓰레기통 %d"):format(
                cycleCount,
                currentIndex
            ))
        end
    end
end

Controls:AddToggle("AutoRoute", {
    Text = "자동 순회 ON / OFF",
    Default = false,

    Callback = function(value)
        if closed then
            return
        end

        enabled = value

        if enabled and not running then
            task.spawn(runCycle)
        elseif not enabled then
            setStatus("일시 중지 — ON으로 재개")
        end
    end,
})

Controls:AddButton({
    Text = "진행 상황 확인",
    Func = function()
        setStatus(("완료 %d회 / 현재 쓰레기통 %d/%d"):format(
            cycleCount,
            currentIndex,
            #dumpsters
        ))
    end,
})

Controls:AddButton({
    Text = "진행 상황 초기화",
    Func = function()
        if closed then
            return
        end

        enabled = false
        currentIndex = 0
        cycleCount = 0

        setStatus("초기화 완료 — ON을 눌러 시작")
    end,
})

Controls:AddButton({
    Text = "NPC로 이동",
    Func = function()
        if closed then
            return
        end

        if enabled then
            setStatus("먼저 자동 순회를 OFF 해주세요")
            return
        end

        local root = getRoot()

        if not root then
            setStatus("캐릭터를 찾을 수 없음")
            return
        end

        root.CFrame = CFrame.new(npcPosition)
        setStatus("NPC 위치로 이동 요청 완료")
    end,
})

Controls:AddButton({
    Text = "UI 닫기",
    Func = function()
        if closed then
            return
        end

        enabled = false
        closed = true

        pcall(function()
            Library:Unload()
        end)
    end,
})

Library:Notify("Dumpster Utility Pro v1.4.0 로드 완료", 4)
setStatus("대기 중 — ON을 눌러 시작")
