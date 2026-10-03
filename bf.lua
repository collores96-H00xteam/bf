--[[
    BIN'S QUEST — v40
    + Читает прогресс квеста из UI (4/8)
    + Считает убийства по реальному прогрессу
    + Высота 18
]]

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local StarterGui          = game:GetService("StarterGui")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    FlySpeed    = 200,
    SafeHeight  = 18,
    MobScale    = 4,
    HitboxSize  = 320,
    FlyFree     = false,
}
local FLY_ARRIVE    = 4
local KILL_TIMEOUT  = 20
local CLICK_DELAY   = 1.2
local RESPAWN_WAIT  = 3
local EQUIP_TIMEOUT = 15

local COLORS = {
    bg = Color3.fromRGB(18, 16, 28),
    bgPanel = Color3.fromRGB(28, 24, 44),
    bgPanelHover = Color3.fromRGB(40, 34, 60),
    bgTitle = Color3.fromRGB(48, 24, 92),
    bgAccent = Color3.fromRGB(70, 45, 140),
    bgAccentHover = Color3.fromRGB(95, 65, 175),
    bgStart = Color3.fromRGB(40, 140, 70),
    bgStartHover = Color3.fromRGB(55, 175, 90),
    bgStop = Color3.fromRGB(170, 45, 45),
    bgStopHover = Color3.fromRGB(210, 60, 60),
    bgSelect = Color3.fromRGB(60, 90, 60),
    stroke = Color3.fromRGB(130, 90, 210),
    strokeSoft = Color3.fromRGB(70, 55, 110),
    text = Color3.fromRGB(230, 225, 255),
    textDim = Color3.fromRGB(150, 140, 190),
    textGreen = Color3.fromRGB(140, 220, 140),
    textAccent = Color3.fromRGB(210, 190, 255),
}

local BOSS_KEYWORDS = {"boss", "king", "elite", "chief", "ruler", "lord"}
local EXCLUDE_KEYWORDS = {
    "quest", "giver", "npc", "dialog",
    "adventurer", "trader", "shop", "citizen", "villager",
    "sailor", "barmaid", "guide", "trainer", "teacher",
    "vendor", "merchant", "dealer", "seller", "buyer",
    "guard", "blacksmith", "smith", "chef", "cook", "bartender",
}

local QUESTS = {
    {id = "pirate", title = "🏴‍☠️  Пиратский остров", sections = {
        {name = "⚔️  Бандиты", tpPos = Vector3.new(1055, 15, 1555),
         clicks = {{1044, 547}, {1044, 547}, {1033, 476}}, mobName = "bandit", killTarget = 5}
    }},
    {id = "jungle", title = "🌴  Джунгли", sections = {
        {name = "🐒  Обычные Монки", tpPos = Vector3.new(-1683, 50, 175),
         clicks = {{1054, 401}, {1054, 401}, {1071, 484}}, mobName = "monkey", killTarget = 6},
        {name = "🦍  Гориллы", tpPos = Vector3.new(-1683, 50, 175),
         clicks = {{1054, 401}, {1052, 477}, {1071, 484}}, mobName = "gorilla", killTarget = 8, noBoss = true},
    }},
    {id = "village", title = "🏘️  Пиратская деревня", sections = {
        {name = "🏴‍☠️  Пираты", tpPos = Vector3.new(-1151, 17, 3860),
         clicks = {{1146, 403}, {1146, 403}, {1056, 474}}, mobName = "pirate", killTarget = 8},
        {name = "💢  Грубияны", tpPos = Vector3.new(-1151, 17, 3860),
         clicks = {{1091, 479}, {1091, 479}, {1056, 474}}, mobName = "brute", killTarget = 8},
    }},
}

local TP_LOCATIONS = {
    {name = "🏴‍☠️  Пиратский остров",  pos = Vector3.new(1108, 15, 1448)},
    {name = "🏙️  Средний город",     pos = Vector3.new(-654, 5, 1578)},
    {name = "🌴  Джунгли",           pos = Vector3.new(-1683, 50, 175)},
    {name = "🏘️  Пиратская деревня", pos = Vector3.new(-1265, 27, 4086)},
}

local State = {
    Running = false, Killed = 0, DebugText = "загрузка",
    ActiveSection = nil,
    SelectedQuest = nil, SelectedSection = nil,
    Flying = false, NoclipActive = false,
    ModifiedMobs = {},
    ModifiedHitboxes = {},
    WeaponName = "нет",
    FlyActive = false,
    WasDead = false,
    QuestProgress = 0,     -- считываемый из UI
    QuestRequired = 0,     -- требуемое число из UI
}

--// ============================================================
-- ЧТЕНИЕ ПРОГРЕССА КВЕСТА ИЗ UI
-- Ищет TextLabel с текстом "X/Y" в PlayerGui
-- ============================================================
local function ReadQuestProgress()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil, nil end
    -- Ищем TextLabel с паттерном "число/число"
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            local t = obj.Text or ""
            -- Проверяем паттерн "4/8" или "4 / 8"
            local cur, req = string.match(t, "^(%d+)%s*/%s*(%d+)$")
            if cur and req then
                local c = tonumber(cur)
                local r = tonumber(req)
                if c and r and r > 0 and r <= 100 then
                    return c, r
                end
            end
            -- Также иногда текст разделён на два лейбла "4" и "/8"
            -- но это редкий случай, пока пропускаем
        end
    end
    return nil, nil
end

local function GetRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function Alive() local h = GetHum(); return h and h.Health > 0 end
local function Log(t) State.DebugText = t; print("[BIN] "..t) end

local function ClickAt(x, y)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function ScaleMobUp(mob)
    if not mob then return end
    for _, d in ipairs(State.ModifiedMobs) do
        if d.model == mob then return end
    end
    local originalScale = 1
    pcall(function() originalScale = mob:GetScale() end)
    local ok = pcall(function() mob:ScaleTo(Config.MobScale) end)
    if ok then
        table.insert(State.ModifiedMobs, {model = mob, originalScale = originalScale})
    end
end

local function RestoreAllMobs()
    for _, d in ipairs(State.ModifiedMobs) do
        if d.model and d.model.Parent then
            pcall(function() d.model:ScaleTo(d.originalScale) end)
        end
    end
    State.ModifiedMobs = {}
end

local function ExpandHitbox(mob)
    if not mob then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, d in ipairs(State.ModifiedHitboxes) do
        if d.model == mob and d.part and d.part.Parent then return end
    end
    table.insert(State.ModifiedHitboxes, {
        model = mob, part = hrp,
        origSize = hrp.Size, origCanCollide = hrp.CanCollide,
        origTransparency = hrp.Transparency,
    })
    local s = Config.HitboxSize
    pcall(function() hrp.Size = Vector3.new(s, s, s) end)
    pcall(function() hrp.CanCollide = false end)
    pcall(function() hrp.Transparency = 1 end)
end

local function RestoreAllHitboxes()
    for _, d in ipairs(State.ModifiedHitboxes) do
        if d.part and d.part.Parent then
            pcall(function() d.part.Size = d.origSize end)
            pcall(function() d.part.CanCollide = d.origCanCollide end)
            pcall(function() d.part.Transparency = d.origTransparency end)
        end
    end
    State.ModifiedHitboxes = {}
end

local function EquipWeapon()
    local ch = LP.Character
    if not ch then return end
    local current = ch:FindFirstChildOfClass("Tool")
    if current then
        local n = string.lower(current.Name)
        if not string.find(n, "fist", 1, true)
           and not string.find(n, "hand", 1, true) then
            State.WeaponName = current.Name
            return
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then State.WeaponName = "нет бэкпака"; return end
    local bestTool = nil
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local n = string.lower(tool.Name)
            if not string.find(n, "fist", 1, true)
               and not string.find(n, "bomb", 1, true)
               and not string.find(n, "potion", 1, true)
               and not string.find(n, "food", 1, true) then
                bestTool = tool
                break
            end
        end
    end
    if bestTool then
        local hum = GetHum()
        if hum then
            pcall(function() hum:EquipTool(bestTool) end)
            task.wait(0.1)
            local checkTool = ch:FindFirstChildOfClass("Tool")
            if checkTool and checkTool.Name == bestTool.Name then
                State.WeaponName = bestTool.Name
                return
            end
        end
        pcall(function() bestTool.Parent = ch end)
        task.wait(0.1)
        local checkTool2 = ch:FindFirstChildOfClass("Tool")
        if checkTool2 then
            State.WeaponName = checkTool2.Name
            return
        end
        State.WeaponName = "не удалось"
    else
        State.WeaponName = "кулак"
    end
end

LP.CharacterAdded:Connect(function(char)
    Log("респавн, ожидание "..RESPAWN_WAIT.."с")
    task.wait(RESPAWN_WAIT)
    State.ModifiedMobs = {}
    State.ModifiedHitboxes = {}
    local startWait = tick()
    while tick() - startWait < EQUIP_TIMEOUT do
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local toolCount = 0
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then toolCount = toolCount + 1 end
            end
            if toolCount > 0 then
                Log("бэкпак готов: "..toolCount.." tools")
                break
            end
        end
        task.wait(0.5)
    end
    for attempt = 1, 5 do
        EquipWeapon()
        task.wait(0.3)
        local ch2 = LP.Character
        if ch2 and ch2:FindFirstChildOfClass("Tool") then
            Log("оружие в руке: "..ch2:FindFirstChildOfClass("Tool").Name)
            break
        end
    end
end)

local function IsInteractiveNPC(model)
    if not model then return false end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local objText = string.lower(d.ObjectText or "")
            local actText = string.lower(d.ActionText or "")
            if actText ~= "" or objText ~= "" then return true end
        end
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BillboardGui") then
            for _, sub in ipairs(d:GetDescendants()) do
                if sub:IsA("TextLabel") then
                    local t = string.lower(sub.Text or "")
                    if string.find(t, "quest", 1, true) or
                       string.find(t, "interact", 1, true) or
                       string.find(t, "talk", 1, true) or
                       string.find(t, "shop", 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local flyBV, flyBG = nil, nil
local flyInput = {W = false, A = false, S = false, D = false, Space = false, Shift = false}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then flyInput.W = true end
    if input.KeyCode == Enum.KeyCode.A then flyInput.A = true end
    if input.KeyCode == Enum.KeyCode.S then flyInput.S = true end
    if input.KeyCode == Enum.KeyCode.D then flyInput.D = true end
    if input.KeyCode == Enum.KeyCode.Space then flyInput.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyInput.Shift = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then flyInput.W = false end
    if input.KeyCode == Enum.KeyCode.A then flyInput.A = false end
    if input.KeyCode == Enum.KeyCode.S then flyInput.S = false end
    if input.KeyCode == Enum.KeyCode.D then flyInput.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyInput.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then flyInput.Shift = false end
end)

local function StartFreeFly()
    local r = GetRoot()
    if not r then return end
    if State.FlyActive then return end
    State.FlyActive = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "BinFreeFly"
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.P = 50000
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = r
    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "BinFreeGyro"
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 50000
    flyBG.CFrame = r.CFrame
    flyBG.Parent = r
end

local function StopFreeFly()
    State.FlyActive = false
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
end

RunService.Heartbeat:Connect(function()
    if not State.FlyActive then return end
    local r = GetRoot()
    if not r then return end
    if not flyBV or not flyBV.Parent then StartFreeFly(); return end
    local spd = Config.FlySpeed / 2
    local move = Vector3.zero
    local cam = Camera.CFrame
    local forward = cam.LookVector
    local right = cam.RightVector
    if flyInput.W then move = move + forward end
    if flyInput.S then move = move - forward end
    if flyInput.D then move = move + right end
    if flyInput.A then move = move - right end
    if flyInput.Space then move = move + Vector3.new(0, 1, 0) end
    if flyInput.Shift then move = move - Vector3.new(0, 1, 0) end
    if move.Magnitude > 0 then flyBV.Velocity = move.Unit * spd
    else flyBV.Velocity = Vector3.zero end
    flyBG.CFrame = CFrame.new(r.Position, r.Position + cam.LookVector)
end)

local NoclipConn = nil
local function EnableNoclip()
    if NoclipConn then return end
    NoclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
end
local function DisableNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

local function ClearFly()
    local r = GetRoot()
    if not r then return end
    for _, c in ipairs(r:GetChildren()) do
        if c.Name == "BinFly" or c.Name == "BinGyro" or c.Name == "BinHoldV" or c.Name == "BinHoldG" then
            c:Destroy()
        end
    end
end

local function RestoreBody()
    local hum = GetHum()
    if not hum then return end
    pcall(function() hum.WalkSpeed = 16 end)
    pcall(function() hum.JumpPower = 50 end)
    pcall(function() hum.PlatformStand = false end)
    pcall(function() hum.AutoRotate = true end)
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
    end)
end

local function FlyTo(targetPos)
    local r = GetRoot()
    if not r then return false end
    ClearFly()
    State.Flying = true
    EnableNoclip()
    local hum = GetHum()
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end)
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BinFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.P = 50000
    bv.Velocity = Vector3.zero
    bv.Parent = r
    local bg = Instance.new("BodyGyro")
    bg.Name = "BinGyro"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 50000
    bg.CFrame = r.CFrame
    bg.Parent = r
    local start = tick()
    while tick() - start < 60 do
        if not State.Flying then break end
        if not r.Parent then break end
        local cur = r.Position
        local diff = targetPos - cur
        if diff.Magnitude < FLY_ARRIVE then break end
        local dir = diff.Unit
        bv.Velocity = dir * Config.FlySpeed
        bg.CFrame = CFrame.new(cur, cur + dir)
        RunService.Heartbeat:Wait()
    end
    if bv.Parent then bv:Destroy() end
    if bg.Parent then bg:Destroy() end
    State.Flying = false
    if r.Parent then
        r.CFrame = CFrame.new(targetPos)
        r.Velocity = Vector3.zero
    end
    task.wait(0.05)
    DisableNoclip()
    RestoreBody()
    return true
end

local function StopFly()
    State.Flying = false
    ClearFly()
    RestoreBody()
    DisableNoclip()
end

local function FindMob(mobName, noBoss)
    local r = GetRoot(); if not r then return nil end
    local pos = r.Position
    local mobLower = string.lower(mobName)
    local near, shortest = nil, math.huge
    local totalFound, skipped = 0, 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local nr = obj:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and nr then
                local n = string.lower(obj.Name)
                if string.find(n, mobLower, 1, true) then
                    local isExcluded = false
                    for _, kw in ipairs(EXCLUDE_KEYWORDS) do
                        if string.find(n, kw, 1, true) then isExcluded = true; break end
                    end
                    if not isExcluded then
                        if IsInteractiveNPC(obj) then isExcluded = true end
                    end
                    if not isExcluded and noBoss then
                        for _, kw in ipairs(BOSS_KEYWORDS) do
                            if string.find(n, kw, 1, true) then isExcluded = true; break end
                        end
                    end
                    if isExcluded then skipped = skipped + 1
                    else
                        totalFound = totalFound + 1
                        local d = (nr.Position - pos).Magnitude
                        if d < shortest then shortest = d; near = obj end
                    end
                end
            end
        end
    end
    if totalFound > 0 then Log("мобов: "..totalFound..(skipped > 0 and (" (пропуск:"..skipped..")") or ""))
    else Log("нет мобов: "..mobLower) end
    return near
end

local function AttackMob(mob)
    if not mob then return end
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position) end)
    local vp = Camera.ViewportSize
    ClickAt(vp.X/2, vp.Y/2)
    local ch = LP.Character
    if ch then
        local tool = ch:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
            task.wait(0.02)
            pcall(function() tool:Activate() end)
        end
    end
end

local function KillOneMob(section)
    local mob = FindMob(section.mobName, section.noBoss)
    if not mob then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    Log("убиваю: "..mob.Name.." HP:"..math.floor(hum.Health))

    EquipWeapon()
    ScaleMobUp(mob)
    task.wait(0.3)
    ExpandHitbox(mob)
    task.wait(0.1)

    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return false end
    FlyTo(mr.Position + Vector3.new(0, Config.SafeHeight, 0))

    local r = GetRoot()
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BinHoldV"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = 50000
    bv.Velocity = Vector3.zero
    bv.Parent = r
    local bg = Instance.new("BodyGyro")
    bg.Name = "BinHoldG"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 50000
    bg.Parent = r
    local start = tick()
    local attackTick = 0
    while tick() - start < KILL_TIMEOUT do
        if not Alive() then
            if bv and bv.Parent then bv:Destroy() end
            if bg and bg.Parent then bg:Destroy() end
            Log("умер во время боя")
            return false
        end
        if not mob.Parent or hum.Health <= 0 then
            Log("✅ убит")
            if bv and bv.Parent then bv:Destroy() end
            if bg and bg.Parent then bg:Destroy() end
            return true
        end
        mr = mob:FindFirstChild("HumanoidRootPart")
        if mr and r and r.Parent then
            local target = mr.Position + Vector3.new(0, Config.SafeHeight, 0)
            local diff = target - r.Position
            bv.Velocity = diff * 15
            bg.CFrame = CFrame.new(r.Position, mr.Position)
            if tick() - attackTick > 0.1 then
                AttackMob(mob)
                attackTick = tick()
            end
        end
        task.wait(0.03)
    end
    Log("⏱ таймаут")
    if bv and bv.Parent then bv:Destroy() end
    if bg and bg.Parent then bg:Destroy() end
    return false
end

local function StopCycle()
    if State.Running then
        State.Running = false
        State.ActiveSection = nil
        StopFly()
        RestoreAllMobs()
        RestoreAllHitboxes()
        if UI.startBtn then
            UI.startBtn.Text = "▶   СТАРТ"
            UI.startBtn.BackgroundColor3 = COLORS.bgStart
        end
    end
end

local function StartSelected()
    if not State.SelectedSection then Log("не выбрана секция"); return end
    StopCycle()
    task.wait(0.1)
    local s = State.SelectedSection
    State.ActiveSection = s
    State.Running = true
    State.Killed = 0
    State.QuestProgress = 0
    State.QuestRequired = s.killTarget
    if UI.startBtn then
        UI.startBtn.Text = "⏹   СТОП"
        UI.startBtn.BackgroundColor3 = COLORS.bgStop
    end
    task.spawn(function()
        while State.Running and State.ActiveSection == s do
            if not Alive() then
                if not State.WasDead then
                    State.WasDead = true
                    Log("умер, жду респавн...")
                end
                task.wait(1)
                local timeout = 0
                while not Alive() and timeout < 60 do
                    task.wait(1)
                    timeout = timeout + 1
                end
                task.wait(RESPAWN_WAIT)
                State.ModifiedMobs = {}
                State.ModifiedHitboxes = {}
                EquipWeapon()
                State.WasDead = false
                Log("ожил, оружие: "..State.WeaponName)
            end

            -- Читаем прогресс из UI перед действиями
            local cur, req = ReadQuestProgress()
            if cur then
                State.QuestProgress = cur
                if req then State.QuestRequired = req end
                Log("UI: "..cur.."/"..State.QuestRequired)
                -- Если квест уже выполнен — берём новый
                if cur >= State.QuestRequired and State.QuestRequired > 0 then
                    Log("квест выполнен! беру заново")
                    FlyTo(s.tpPos)
                    task.wait(0.3)
                    for i, clk in ipairs(s.clicks) do
                        if not State.Running then break end
                        ClickAt(clk[1], clk[2])
                        if i < #s.clicks then task.wait(CLICK_DELAY) end
                    end
                    task.wait(1)
                    State.Killed = 0
                end
            end

            Log("полёт к квестодателю")
            FlyTo(s.tpPos)
            task.wait(0.3)
            for i, clk in ipairs(s.clicks) do
                if not State.Running then break end
                if not Alive() then break end
                Log("клик "..i.."/"..#s.clicks)
                ClickAt(clk[1], clk[2])
                if i < #s.clicks then task.wait(CLICK_DELAY) end
            end
            task.wait(1)

            State.Killed = 0
            -- Используем UI прогресс как счётчик, а не свой счётчик
            while State.Running and State.ActiveSection == s do
                if not Alive() then break end

                -- Читаем текущий прогресс из UI
                local uiCur, uiReq = ReadQuestProgress()
                if uiCur then
                    State.QuestProgress = uiCur
                    if uiReq then State.QuestRequired = uiReq end
                    State.Killed = uiCur
                    if uiCur >= State.QuestRequired and State.QuestRequired > 0 then
                        Log("✅ квест выполнен ("..uiCur.."/"..State.QuestRequired..")")
                        break
                    end
                end

                Log("прогресс "..State.QuestProgress.."/"..State.QuestRequired.." ("..State.WeaponName..")")
                if KillOneMob(s) then
                    -- После убийства подождём немного чтобы UI обновился
                    task.wait(0.8)
                else
                    Log("жду моба...")
                    task.wait(1)
                end
                task.wait(0.3)
            end
            task.wait(0.5)
        end
    end)
end

local function CreateUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BinQuest"; gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 440)
    main.Position = UDim2.new(0.5, -180, 0.5, -220)
    main.BackgroundColor3 = COLORS.bg
    main.BorderSizePixel = 0; main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    local mst = Instance.new("UIStroke", main)
    mst.Color = COLORS.stroke; mst.Thickness = 2; mst.Transparency = 0.2

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = COLORS.bgTitle
    titleBar.BorderSizePixel = 0; titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, 14); tb.Position = UDim2.new(0, 0, 1, -14)
    tb.BackgroundColor3 = COLORS.bgTitle; tb.BorderSizePixel = 0; tb.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0); title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡  БИН — АВТО КВЕСТ v40"
    title.TextColor3 = COLORS.textAccent
    title.Font = Enum.Font.GothamBold; title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28); close.Position = UDim2.new(1, -36, 0, 7)
    close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    close.Text = "✕"; close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Font = Enum.Font.GothamBold; close.TextSize = 14
    close.AutoButtonColor = false; close.Parent = titleBar
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function()
        StopFreeFly(); StopCycle(); gui:Destroy()
    end)

    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, -20, 0, 32)
    tabsFrame.Position = UDim2.new(0, 10, 0, 50)
    tabsFrame.BackgroundColor3 = COLORS.bgPanel
    tabsFrame.BorderSizePixel = 0; tabsFrame.Parent = main
    Instance.new("UICorner", tabsFrame).CornerRadius = UDim.new(0, 8)

    local function MakeTab(text, order, total)
        local tab = Instance.new("TextButton")
        local w = 1 / total
        tab.Size = UDim2.new(w, -2, 1, 0)
        tab.Position = UDim2.new((order - 1) * w + 0.005, 0, 0, 0)
        tab.BackgroundColor3 = Color3.fromRGB(0,0,0)
        tab.BackgroundTransparency = 1
        tab.Text = text
        tab.TextColor3 = COLORS.textDim
        tab.Font = Enum.Font.GothamBold; tab.TextSize = 12
        tab.AutoButtonColor = false; tab.Parent = tabsFrame
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)
        return tab
    end

    local tabQuest = MakeTab("⚔️ КВЕСТ", 1, 3)
    local tabTP    = MakeTab("🌍 ТП", 2, 3)
    local tabCfg   = MakeTab("⚙️ НАСТР", 3, 3)
    tabQuest.BackgroundColor3 = COLORS.bgAccent
    tabQuest.BackgroundTransparency = 0
    tabQuest.TextColor3 = COLORS.text

    local function SetTabActive(active, inactives)
        TweenService:Create(active, TweenInfo.new(0.15), {BackgroundColor3=COLORS.bgAccent, BackgroundTransparency=0, TextColor3=COLORS.text}):Play()
        for _, inac in ipairs(inactives) do
            TweenService:Create(inac, TweenInfo.new(0.15), {BackgroundTransparency=1, TextColor3=COLORS.textDim}):Play()
        end
    end

    local questPage = Instance.new("Frame")
    questPage.Size = UDim2.new(1, -20, 1, -160)
    questPage.Position = UDim2.new(0, 10, 0, 90)
    questPage.BackgroundTransparency = 1; questPage.Parent = main
    local ql = Instance.new("UIListLayout", questPage); ql.Padding = UDim.new(0, 8)

    local questsContainer = Instance.new("Frame")
    questsContainer.Size = UDim2.new(1, 0, 0, 190)
    questsContainer.BackgroundTransparency = 1
    questsContainer.LayoutOrder = 1; questsContainer.Parent = questPage
    local qcl = Instance.new("UIListLayout", questsContainer); qcl.Padding = UDim.new(0, 8)

    local questButtons = {}
    local function UpdateQuestButtons()
        for id, btn in pairs(questButtons) do
            if State.SelectedQuest and State.SelectedQuest.id == id then
                btn.BackgroundColor3 = COLORS.bgSelect
                btn.TextColor3 = Color3.fromRGB(200, 255, 200)
            else
                btn.BackgroundColor3 = COLORS.bgPanel
                btn.TextColor3 = COLORS.text
            end
        end
    end

    for qi, quest in ipairs(QUESTS) do
        local qBtn = Instance.new("TextButton")
        qBtn.Size = UDim2.new(1, 0, 0, 52)
        qBtn.BackgroundColor3 = COLORS.bgPanel
        qBtn.Text = "▶   " .. quest.title
        qBtn.TextColor3 = COLORS.text
        qBtn.Font = Enum.Font.GothamBold; qBtn.TextSize = 14
        qBtn.LayoutOrder = qi; qBtn.AutoButtonColor = false
        qBtn.Parent = questsContainer
        Instance.new("UICorner", qBtn).CornerRadius = UDim.new(0, 10)
        questButtons[quest.id] = qBtn

        qBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if UI.openMenuFor == quest.id then
                    if UI.CloseMenu then UI.CloseMenu() end
                    return
                end
                if UI.CloseMenu then UI.CloseMenu() end
                UI.openMenuFor = quest.id

                local menuH = #quest.sections * 38 + 12
                local menu = Instance.new("Frame")
                menu.Size = UDim2.new(0, 240, 0, menuH)
                menu.Position = UDim2.new(0, qBtn.AbsolutePosition.X + 60, 0, qBtn.AbsolutePosition.Y + 30)
                menu.BackgroundColor3 = COLORS.bgPanel
                menu.BorderSizePixel = 0; menu.ZIndex = 10
                menu.Parent = gui
                Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)
                local ms = Instance.new("UIStroke", menu)
                ms.Color = COLORS.stroke; ms.Thickness = 1.5

                local mh = Instance.new("TextLabel")
                mh.Size = UDim2.new(1, 0, 0, 20); mh.BackgroundTransparency = 1
                mh.Text = "секции:"; mh.TextColor3 = COLORS.textDim
                mh.Font = Enum.Font.Gotham; mh.TextSize = 11
                mh.ZIndex = 11; mh.Parent = menu

                local ml = Instance.new("UIListLayout", menu)
                ml.Padding = UDim.new(0, 4)
                ml.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ml.VerticalAlignment = Enum.VerticalAlignment.Bottom

                for si, section in ipairs(quest.sections) do
                    local sBtn = Instance.new("TextButton")
                    sBtn.Size = UDim2.new(0.94, 0, 0, 32)
                    sBtn.BackgroundColor3 = COLORS.bgAccent
                    sBtn.Text = section.name
                    sBtn.TextColor3 = COLORS.text
                    sBtn.Font = Enum.Font.GothamBold; sBtn.TextSize = 13
                    sBtn.AutoButtonColor = false; sBtn.LayoutOrder = si
                    sBtn.ZIndex = 11; sBtn.Parent = menu
                    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 8)
                    if State.SelectedSection == section then
                        sBtn.BackgroundColor3 = COLORS.bgSelect
                    end
                    sBtn.MouseButton1Click:Connect(function()
                        State.SelectedSection = section
                        State.SelectedQuest = quest
                        UpdateQuestButtons()
                        for _, ch in ipairs(menu:GetDescendants()) do
                            if ch:IsA("TextButton") then
                                ch.BackgroundColor3 = (ch == sBtn) and COLORS.bgSelect or COLORS.bgAccent
                            end
                        end
                        Log("выбрано: "..section.name)
                    end)
                end

                UI.CloseMenu = function()
                    if menu and menu.Parent then menu:Destroy() end
                    UI.CloseMenu = nil; UI.openMenuFor = nil
                end
            end
        end)
    end

    local actionContainer = Instance.new("Frame")
    actionContainer.Size = UDim2.new(1, 0, 0, 60)
    actionContainer.BackgroundTransparency = 1
    actionContainer.LayoutOrder = 2; actionContainer.Parent = questPage

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1, 0, 0, 55)
    startBtn.BackgroundColor3 = COLORS.bgStart
    startBtn.Text = "▶   СТАРТ"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold; startBtn.TextSize = 17
    startBtn.AutoButtonColor = false; startBtn.Parent = actionContainer
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)
    startBtn.MouseButton1Click:Connect(function()
        if State.Running then StopCycle() else StartSelected() end
    end)
    UI.startBtn = startBtn

    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(1, 0, 0, 60)
    infoContainer.BackgroundTransparency = 1
    infoContainer.LayoutOrder = 3; infoContainer.Parent = questPage

    local statusBox = Instance.new("Frame")
    statusBox.Size = UDim2.new(1, 0, 0, 26)
    statusBox.BackgroundColor3 = COLORS.bgPanel
    statusBox.BorderSizePixel = 0; statusBox.Parent = infoContainer
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 1, 0); status.Position = UDim2.new(0, 8, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "Статус: готов"; status.TextColor3 = COLORS.textDim
    status.Font = Enum.Font.GothamBold; status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = statusBox

    local debugBox = Instance.new("Frame")
    debugBox.Size = UDim2.new(1, 0, 0, 26)
    debugBox.Position = UDim2.new(0, 0, 0, 32)
    debugBox.BackgroundColor3 = Color3.fromRGB(14, 22, 18)
    debugBox.BorderSizePixel = 0; debugBox.Parent = infoContainer
    Instance.new("UICorner", debugBox).CornerRadius = UDim.new(0, 8)
    local debug = Instance.new("TextLabel")
    debug.Size = UDim2.new(1, -16, 1, 0); debug.Position = UDim2.new(0, 8, 0, 0)
    debug.BackgroundTransparency = 1
    debug.Text = "отладка: ..."; debug.TextColor3 = COLORS.textGreen
    debug.Font = Enum.Font.Code; debug.TextSize = 11
    debug.TextXAlignment = Enum.TextXAlignment.Left
    debug.Parent = debugBox

    local tpPage = Instance.new("Frame")
    tpPage.Size = UDim2.new(1, -20, 1, -160)
    tpPage.Position = UDim2.new(0, 10, 0, 90)
    tpPage.BackgroundTransparency = 1; tpPage.Visible = false; tpPage.Parent = main
    local tpl = Instance.new("UIListLayout", tpPage); tpl.Padding = UDim.new(0, 8)

    for i, loc in ipairs(TP_LOCATIONS) do
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(1, 0, 0, 48)
        tpBtn.BackgroundColor3 = Color3.fromRGB(40, 55, 95)
        tpBtn.Text = "➤   " .. loc.name
        tpBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
        tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 14
        tpBtn.LayoutOrder = i; tpBtn.AutoButtonColor = false
        tpBtn.Parent = tpPage
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 10)
        local pos = loc.pos
        tpBtn.MouseButton1Click:Connect(function()
            StopCycle(); task.wait(0.05)
            task.spawn(function() FlyTo(pos) end)
        end)
    end

    local cfgPage = Instance.new("Frame")
    cfgPage.Size = UDim2.new(1, -20, 1, -160)
    cfgPage.Position = UDim2.new(0, 10, 0, 90)
    cfgPage.BackgroundTransparency = 1; cfgPage.Visible = false; cfgPage.Parent = main

    local cfgl = Instance.new("UIListLayout", cfgPage)
    cfgl.Padding = UDim.new(0, 8)
    cfgl.SortOrder = Enum.SortOrder.LayoutOrder

    local flyRow = Instance.new("Frame")
    flyRow.Size = UDim2.new(1, 0, 0, 48)
    flyRow.BackgroundColor3 = COLORS.bgPanel
    flyRow.BorderSizePixel = 0
    flyRow.LayoutOrder = 1
    flyRow.Parent = cfgPage
    Instance.new("UICorner", flyRow).CornerRadius = UDim.new(0, 10)

    local flyLbl = Instance.new("TextLabel")
    flyLbl.Size = UDim2.new(0.6, 0, 1, 0); flyLbl.Position = UDim2.new(0, 12, 0, 0)
    flyLbl.BackgroundTransparency = 1
    flyLbl.Text = "✈️  Свободный полёт"
    flyLbl.TextColor3 = COLORS.text
    flyLbl.Font = Enum.Font.GothamBold; flyLbl.TextSize = 14
    flyLbl.TextXAlignment = Enum.TextXAlignment.Left
    flyLbl.Parent = flyRow

    local flyHint = Instance.new("TextLabel")
    flyHint.Size = UDim2.new(1, -24, 0, 14); flyHint.Position = UDim2.new(0, 12, 1, 2)
    flyHint.BackgroundTransparency = 1
    flyHint.Text = "WASD + Space/Shift"
    flyHint.TextColor3 = COLORS.textDim
    flyHint.Font = Enum.Font.Gotham; flyHint.TextSize = 10
    flyHint.TextXAlignment = Enum.TextXAlignment.Left
    flyHint.Parent = flyRow

    local flyToggle = Instance.new("TextButton")
    flyToggle.Size = UDim2.new(0, 70, 0, 32); flyToggle.Position = UDim2.new(1, -82, 0, 8)
    flyToggle.BackgroundColor3 = COLORS.bgStop
    flyToggle.Text = "ВЫКЛ"
    flyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyToggle.Font = Enum.Font.GothamBold; flyToggle.TextSize = 12
    flyToggle.AutoButtonColor = false; flyToggle.Parent = flyRow
    Instance.new("UICorner", flyToggle).CornerRadius = UDim.new(0, 8)
    flyToggle.MouseButton1Click:Connect(function()
        if State.FlyActive then
            StopFreeFly()
            flyToggle.Text = "ВЫКЛ"
            flyToggle.BackgroundColor3 = COLORS.bgStop
        else
            StartFreeFly()
            flyToggle.Text = "ВКЛ"
            flyToggle.BackgroundColor3 = COLORS.bgStart
        end
    end)

    local function MakeSlider(label, order, key, min, max, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = COLORS.bgPanel
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = cfgPage
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 0, 20); lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COLORS.text
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.3, 0, 0, 20); val.Position = UDim2.new(0.7, -12, 0, 6)
        val.BackgroundTransparency = 1
        val.Text = tostring(Config[key])
        val.TextColor3 = COLORS.textAccent
        val.Font = Enum.Font.GothamBold; val.TextSize = 13
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 8); bar.Position = UDim2.new(0, 12, 0, 36)
        bar.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
        bar.BorderSizePixel = 0; bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((Config[key]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = COLORS.bgAccent
        fill.BorderSizePixel = 0; fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
        btn.Text = ""; btn.Parent = bar

        local dragging = false

        local function updateFromX(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = min + rel * (max - min)
            v = math.floor(v / step + 0.5) * step
            Config[key] = v
            val.Text = tostring(v)
            fill.Size = UDim2.new((v - min)/(max - min), 0, 1, 0)
        end

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return val
    end

    MakeSlider("⚡ Скорость полёта", 2, "FlySpeed", 50, 500, 10)
    MakeSlider("📏 Высота над мобом", 3, "SafeHeight", 3, 40, 1)
    MakeSlider("🐘 Размер моба (x)", 4, "MobScale", 1, 6, 0.5)
    MakeSlider("📦 Размер хитбокса", 5, "HitboxSize", 40, 500, 20)

    local infoCfg = Instance.new("TextLabel")
    infoCfg.Size = UDim2.new(1, 0, 0, 70)
    infoCfg.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
    infoCfg.LayoutOrder = 6
    infoCfg.Text = "Скорость — скорость полёта\nВысота — на сколько над мобом\nРазмер моба — реальное увеличение NPC\nХитбокс — размер HRP моба"
    infoCfg.TextColor3 = COLORS.textDim
    infoCfg.Font = Enum.Font.Gotham; infoCfg.TextSize = 11
    infoCfg.TextXAlignment = Enum.TextXAlignment.Left
    infoCfg.TextYAlignment = Enum.TextYAlignment.Center
    infoCfg.Parent = cfgPage
    Instance.new("UICorner", infoCfg).CornerRadius = UDim.new(0, 8)

    local function SelectTab(n)
        questPage.Visible = (n == 1)
        tpPage.Visible = (n == 2)
        cfgPage.Visible = (n == 3)
        if n == 1 then SetTabActive(tabQuest, {tabTP, tabCfg})
        elseif n == 2 then SetTabActive(tabTP, {tabQuest, tabCfg})
        else SetTabActive(tabCfg, {tabQuest, tabTP}) end
    end
    tabQuest.MouseButton1Click:Connect(function() SelectTab(1) end)
    tabTP.MouseButton1Click:Connect(function() SelectTab(2) end)
    tabCfg.MouseButton1Click:Connect(function() SelectTab(3) end)

    task.spawn(function()
        while gui.Parent do
            if State.Running and State.ActiveSection then
                status.Text = "⚔️  "..State.ActiveSection.name.." — "..State.QuestProgress.."/"..State.QuestRequired
                status.TextColor3 = Color3.fromRGB(180, 255, 180)
            elseif State.FlyActive then
                status.Text = "✈️ Свободный полёт активен"
                status.TextColor3 = Color3.fromRGB(150, 200, 255)
            elseif State.SelectedSection then
                status.Text = "✓ Выбрано: "..State.SelectedSection.name
                status.TextColor3 = COLORS.textAccent
            else
                status.Text = "Статус: выбери секцию"
                status.TextColor3 = COLORS.textDim
            end
            debug.Text = "отладка: "..State.DebugText
            task.wait(0.3)
        end
    end)

    local dragging, ds, sp
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; ds = i.Position; sp = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

CreateUI()
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ БИН v40",
        Text = "Читает прогресс из квеста (4/8)",
        Duration = 4,
    })
end)
