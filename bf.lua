--[[
    BIN'S QUEST — v18
    Красивый UI + выбор секции + toggle меню правым кликом
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

--// НАСТРОЙКИ
local FLY_SPEED    = 200
local FLY_ARRIVE   = 6
local KILL_TIMEOUT = 6
local CLICK_DELAY  = 1.2

--// ЦВЕТА
local COLORS = {
    bg         = Color3.fromRGB(18, 16, 28),
    bgPanel    = Color3.fromRGB(28, 24, 44),
    bgPanelHover = Color3.fromRGB(40, 34, 60),
    bgTitle    = Color3.fromRGB(48, 24, 92),
    bgAccent   = Color3.fromRGB(70, 45, 140),
    bgAccentHover = Color3.fromRGB(95, 65, 175),
    bgStart    = Color3.fromRGB(40, 140, 70),
    bgStartHover = Color3.fromRGB(55, 175, 90),
    bgStop     = Color3.fromRGB(170, 45, 45),
    bgStopHover = Color3.fromRGB(210, 60, 60),
    bgSelect   = Color3.fromRGB(60, 90, 60),
    stroke     = Color3.fromRGB(130, 90, 210),
    strokeSoft = Color3.fromRGB(70, 55, 110),
    text       = Color3.fromRGB(230, 225, 255),
    textDim    = Color3.fromRGB(150, 140, 190),
    textGreen  = Color3.fromRGB(140, 220, 140),
    textAccent = Color3.fromRGB(210, 190, 255),
}

--// ДАННЫЕ КВЕСТОВ
local QUESTS = {
    {
        id = "pirate",
        title = "🏴‍☠️  Пиратский остров",
        sections = {
            {
                name = "⚔️  Бандиты",
                tpPos = Vector3.new(1055, 15, 1555),
                clicks = {{1044, 547}, {1044, 547}, {1033, 476}},
                mobName = "bandit",
                killTarget = 5,
            }
        }
    },
    {
        id = "jungle",
        title = "🌴  Джунгли",
        sections = {
            {
                name = "🐒  Обычные Монки",
                tpPos = Vector3.new(-1683, 50, 175),
                clicks = {{1054, 401}, {1054, 401}, {1071, 484}},
                mobName = "monkey",
                killTarget = 6,
            },
        }
    }
}

--// TP ТОЧКИ
local TP_LOCATIONS = {
    {name = "🏴‍☠️  Пиратский остров", pos = Vector3.new(1108, 15, 1448)},
    {name = "🏙️  Средний город",    pos = Vector3.new(-654, 5, 1578)},
    {name = "🌴  Джунгли",          pos = Vector3.new(-1683, 50, 175)},
}

local State = {
    Running = false, Killed = 0, DebugText = "загрузка",
    ActiveSection = nil,
    SelectedQuest = nil,
    SelectedSection = nil,
    FlyTarget = nil, Flying = false,
    NoclipActive = false,
}
local UI = {}

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

--// ============================================================
-- NOCLIP
-- ============================================================
local NoclipConn = nil

local function EnableNoclip()
    if NoclipConn then return end
    State.NoclipActive = true
    NoclipConn = RunService.Stepped:Connect(function()
        if not State.NoclipActive then return end
        local char = LP.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    Log("ноуклип ВКЛ")
end

local function DisableNoclip()
    State.NoclipActive = false
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    end
    local char = LP.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    Log("ноуклип ВЫКЛ")
end

--// ============================================================
-- ФИЗИКА
-- ============================================================
local function ClearFly()
    local r = GetRoot()
    if not r then return end
    for _, c in ipairs(r:GetChildren()) do
        if c:IsA("BodyVelocity") or c:IsA("BodyGyro") then c:Destroy() end
    end
end

local function RestoreBody()
    local hum = GetHum()
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
    end)
    pcall(function() hum.WalkSpeed = 16 end)
    pcall(function() hum.JumpPower = 50 end)
    pcall(function() hum.PlatformStand = false end)
    pcall(function() hum.AutoRotate = true end)
    Log("тело восстановлено")
end

--// ============================================================
-- ПОЛЁТ
-- ============================================================
local function FlyTo(targetPos)
    local r = GetRoot()
    if not r then return false end

    ClearFly()
    State.FlyTarget = targetPos
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
        local dist = diff.Magnitude
        if dist < FLY_ARRIVE then break end
        local dir = diff.Unit
        bv.Velocity = dir * FLY_SPEED
        bg.CFrame = CFrame.new(cur, cur + dir)
        RunService.Heartbeat:Wait()
    end

    if bv.Parent then bv:Destroy() end
    if bg.Parent then bg:Destroy() end

    State.Flying = false
    State.FlyTarget = nil

    if r.Parent then
        r.CFrame = CFrame.new(targetPos)
        r.Velocity = Vector3.zero
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end

    RestoreBody()
    task.wait(0.1)
    DisableNoclip()
    return true
end

local function StopFly()
    State.Flying = false
    ClearFly()
    RestoreBody()
    DisableNoclip()
end

--// ============================================================
-- МОБЫ
-- ============================================================
local function FindMob(mobName)
    local r = GetRoot(); if not r then return nil end
    local pos = r.Position
    local mobLower = string.lower(mobName)
    local near, shortest = nil, math.huge
    local totalFound = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            local nr = obj:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and nr then
                local n = string.lower(obj.Name)
                if string.find(n, mobLower, 1, true) and not string.find(n, "quest", 1, true) then
                    totalFound = totalFound + 1
                    local d = (nr.Position - pos).Magnitude
                    if d < shortest then shortest = d; near = obj end
                end
            end
        end
    end
    if totalFound > 0 then Log("мобов ("..mobLower.."): "..totalFound)
    else Log("нет мобов: "..mobLower) end
    return near
end

local function AttackMob(mob)
    if not mob then return end
    local mr = mob:FindFirstChild("HumanoidRootPart")
    if not mr then return end
    pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, mr.Position) end)
    local vp = Camera.ViewportSize
    ClickAt(vp.X/2, vp.Y/2)
    local ch = LP.Character
    if ch then
        local tool = ch:FindFirstChildOfClass("Tool")
        if tool then pcall(function() tool:Activate() end) end
    end
end

local function KillOneMob(mobName)
    local mob = FindMob(mobName)
    if not mob then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    Log("убиваю: "..mob.Name.." HP:"..math.floor(hum.Health))

    local mr = mob:FindFirstChild("HumanoidRootPart")
    if mr then FlyTo(mr.Position + Vector3.new(0, 0, 3)) end

    local start = tick()
    local attackTick = 0
    while tick() - start < KILL_TIMEOUT do
        if not mob.Parent or hum.Health <= 0 then Log("✅ убит"); return true end
        local r = GetRoot()
        mr = mob:FindFirstChild("HumanoidRootPart")
        if r and mr then
            r.CFrame = CFrame.new(mr.Position + Vector3.new(0, 0, 3), mr.Position)
            r.Velocity = Vector3.zero
            if tick() - attackTick > 0.15 then AttackMob(mob); attackTick = tick() end
        end
        task.wait(0.05)
    end
    Log("⏱ таймаут")
    return false
end

--// ============================================================
-- СТАРТ / СТОП
-- ============================================================
local function StopCycle()
    if State.Running then
        State.Running = false
        State.ActiveSection = nil
        StopFly()
        if UI.startBtn then
            UI.startBtn.Text = "▶  СТАРТ"
            UI.startBtn.BackgroundColor3 = COLORS.bgStart
        end
        Log("цикл остановлен")
    end
end

local function StartSelected()
    if not State.SelectedSection then
        Log("не выбрана секция")
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "⚠️ БИН",
                Text = "Сначала выбери секцию (правый клик по квесту)",
                Duration = 3,
            })
        end)
        return
    end
    StopCycle()
    task.wait(0.1)
    local s = State.SelectedSection
    State.ActiveSection = s
    State.Running = true
    State.Killed = 0
    if UI.startBtn then
        UI.startBtn.Text = "⏹  СТОП"
        UI.startBtn.BackgroundColor3 = COLORS.bgStop
    end
    Log("запуск: "..s.name)
    task.spawn(function()
        while State.Running and State.ActiveSection == s do
            if not Alive() then task.wait(1); continue end

            Log("полёт к квестодателю")
            FlyTo(s.tpPos)
            task.wait(0.3)

            for i, clk in ipairs(s.clicks) do
                if not State.Running or State.ActiveSection ~= s then break end
                Log("клик "..i.."/"..#s.clicks)
                ClickAt(clk[1], clk[2])
                if i < #s.clicks then task.wait(CLICK_DELAY) end
            end
            task.wait(0.8)

            State.Killed = 0
            while State.Killed < s.killTarget and State.Running and State.ActiveSection == s do
                Log("убиваю "..(State.Killed+1).."/"..s.killTarget)
                if KillOneMob(s.mobName) then
                    State.Killed = State.Killed + 1
                else
                    Log("жду моба...")
                    task.wait(1)
                end
                task.wait(0.3)
            end

            if State.ActiveSection == s then
                Log("✅ цикл завершён, повтор")
            end
            task.wait(0.5)
        end
    end)
end

--// ============================================================
-- ИНТЕРФЕЙС
-- ============================================================
local function CreateUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BinQuest"
    gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    -- ГЛАВНОЕ ОКНО
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 440)
    main.Position = UDim2.new(0.5, -180, 0.5, -220)
    main.BackgroundColor3 = COLORS.bg
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = COLORS.stroke
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.2

    -- ТЕНЬ
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = -1
    shadow.Parent = main

    -- ЗАГОЛОВОК
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = COLORS.bgTitle
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

    -- Обрезка нижней части скругления у заголовка
    local titleBottom = Instance.new("Frame")
    titleBottom.Size = UDim2.new(1, 0, 0, 14)
    titleBottom.Position = UDim2.new(0, 0, 1, -14)
    titleBottom.BackgroundColor3 = COLORS.bgTitle
    titleBottom.BorderSizePixel = 0
    titleBottom.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡  БИН — АВТО КВЕСТ"
    title.TextColor3 = COLORS.textAccent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Кнопка закрытия
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -36, 0, 7)
    close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.AutoButtonColor = false
    close.Parent = titleBar
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseEnter:Connect(function()
        TweenService:Create(close, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(230, 80, 80)}):Play()
    end)
    close.MouseLeave:Connect(function()
        TweenService:Create(close, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 60, 60)}):Play()
    end)
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- ВКЛАДКИ
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, -20, 0, 32)
    tabsFrame.Position = UDim2.new(0, 10, 0, 50)
    tabsFrame.BackgroundColor3 = COLORS.bgPanel
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = main
    Instance.new("UICorner", tabsFrame).CornerRadius = UDim.new(0, 8)

    local function MakeTab(text, order, isFirst)
        local tab = Instance.new("TextButton")
        tab.Size = UDim2.new(0.5, isFirst and -3 or -3, 1, 0)
        tab.Position = isFirst and UDim2.new(0, 3, 0, 0) or UDim2.new(0.5, 0, 0, 0)
        tab.BackgroundColor3 = isFirst and COLORS.bgAccent or Color3.fromRGB(0, 0, 0)
        tab.BackgroundTransparency = isFirst and 0 or 1
        tab.Text = text
        tab.TextColor3 = isFirst and COLORS.text or COLORS.textDim
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 13
        tab.AutoButtonColor = false
        tab.LayoutOrder = order
        tab.Parent = tabsFrame
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)
        return tab
    end

    local tabQuest = MakeTab("⚔️  КВЕСТ", 1, true)
    local tabTP = MakeTab("🌍  ТЕЛЕПОРТ", 2, false)

    local function SetTabActive(active, inactive)
        TweenService:Create(active, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.bgAccent,
            BackgroundTransparency = 0,
            TextColor3 = COLORS.text,
        }):Play()
        TweenService:Create(inactive, TweenInfo.new(0.15), {
            BackgroundTransparency = 1,
            TextColor3 = COLORS.textDim,
        }):Play()
    end

    -- КОНТЕНТ КВЕСТ
    local questPage = Instance.new("Frame")
    questPage.Size = UDim2.new(1, -20, 1, -160)
    questPage.Position = UDim2.new(0, 10, 0, 90)
    questPage.BackgroundTransparency = 1
    questPage.Parent = main

    local qLayout = Instance.new("UIListLayout", questPage)
    qLayout.Padding = UDim.new(0, 8)
    qLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Контейнер для кнопок квестов
    local questsContainer = Instance.new("Frame")
    questsContainer.Size = UDim2.new(1, 0, 0, 130)
    questsContainer.BackgroundTransparency = 1
    questsContainer.LayoutOrder = 1
    questsContainer.Parent = questPage

    local qcLayout = Instance.new("UIListLayout", questsContainer)
    qcLayout.Padding = UDim.new(0, 8)
    qcLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
        qBtn.Size = UDim2.new(1, 0, 0, 55)
        qBtn.BackgroundColor3 = COLORS.bgPanel
        qBtn.Text = "▶   " .. quest.title
        qBtn.TextColor3 = COLORS.text
        qBtn.Font = Enum.Font.GothamBold
        qBtn.TextSize = 15
        qBtn.LayoutOrder = qi
        qBtn.AutoButtonColor = false
        qBtn.Parent = questsContainer
        Instance.new("UICorner", qBtn).CornerRadius = UDim.new(0, 10)

        local qStroke = Instance.new("UIStroke", qBtn)
        qStroke.Color = COLORS.strokeSoft
        qStroke.Thickness = 1

        qBtn.MouseEnter:Connect(function()
            if not (State.SelectedQuest and State.SelectedQuest.id == quest.id) then
                TweenService:Create(qBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgPanelHover}):Play()
            end
        end)
        qBtn.MouseLeave:Connect(function()
            UpdateQuestButtons()
        end)

        questButtons[quest.id] = qBtn

        -- ПРАВЫЙ КЛИК — toggle меню секций
        qBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                -- Если меню уже открыто для этого квеста — закрываем
                if UI.openMenuFor == quest.id then
                    if UI.CloseMenu then UI.CloseMenu() end
                    return
                end

                -- Закрываем предыдущее если есть
                if UI.CloseMenu then UI.CloseMenu() end

                -- Открываем новое
                UI.openMenuFor = quest.id

                local sectionsCount = #quest.sections
                local menuH = sectionsCount * 38 + 12

                local menu = Instance.new("Frame")
                menu.Size = UDim2.new(0, 240, 0, menuH)
                menu.Position = UDim2.new(0, qBtn.AbsolutePosition.X + 60, 0, qBtn.AbsolutePosition.Y + 30)
                menu.BackgroundColor3 = COLORS.bgPanel
                menu.BorderSizePixel = 0
                menu.ZIndex = 10
                menu.Parent = gui
                Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 10)

                local mShadow = Instance.new("ImageLabel")
                mShadow.Size = UDim2.new(1, 20, 1, 20)
                mShadow.Position = UDim2.new(0, -10, 0, -10)
                mShadow.BackgroundTransparency = 1
                mShadow.Image = "rbxassetid://5028857084"
                mShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
                mShadow.ImageTransparency = 0.4
                mShadow.ZIndex = 9
                mShadow.Parent = menu

                local mStroke = Instance.new("UIStroke", menu)
                mStroke.Color = COLORS.stroke
                mStroke.Thickness = 1.5

                local mHeader = Instance.new("TextLabel")
                mHeader.Size = UDim2.new(1, 0, 0, 20)
                mHeader.BackgroundTransparency = 1
                mHeader.Text = "секции:"
                mHeader.TextColor3 = COLORS.textDim
                mHeader.Font = Enum.Font.Gotham
                mHeader.TextSize = 11
                mHeader.ZIndex = 11
                mHeader.Parent = menu

                local mLayout = Instance.new("UIListLayout", menu)
                mLayout.Padding = UDim.new(0, 4)
                mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                mLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
                mLayout.SortOrder = Enum.SortOrder.LayoutOrder

                for si, section in ipairs(quest.sections) do
                    local sBtn = Instance.new("TextButton")
                    sBtn.Size = UDim2.new(0.94, 0, 0, 32)
                    sBtn.BackgroundColor3 = COLORS.bgAccent
                    sBtn.Text = section.name
                    sBtn.TextColor3 = COLORS.text
                    sBtn.Font = Enum.Font.GothamBold
                    sBtn.TextSize = 13
                    sBtn.AutoButtonColor = false
                    sBtn.LayoutOrder = si
                    sBtn.ZIndex = 11
                    sBtn.Parent = menu
                    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 8)

                    -- Подсветка если эта секция выбрана
                    if State.SelectedSection == section then
                        sBtn.BackgroundColor3 = COLORS.bgSelect
                    end

                    sBtn.MouseEnter:Connect(function()
                        if State.SelectedSection ~= section then
                            TweenService:Create(sBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgAccentHover}):Play()
                        end
                    end)
                    sBtn.MouseLeave:Connect(function()
                        if State.SelectedSection ~= section then
                            TweenService:Create(sBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgAccent}):Play()
                        end
                    end)

                    -- Левый клик = ВЫБОР секции (не запуск!)
                    sBtn.MouseButton1Click:Connect(function()
                        State.SelectedSection = section
                        State.SelectedQuest = quest
                        UpdateQuestButtons()
                        -- Обновляем подсветку в меню
                        for _, child in ipairs(menu:GetDescendants()) do
                            if child:IsA("TextButton") then
                                if child == sBtn then
                                    child.BackgroundColor3 = COLORS.bgSelect
                                else
                                    child.BackgroundColor3 = COLORS.bgAccent
                                end
                            end
                        end
                        Log("выбрано: "..section.name)
                        pcall(function()
                            StarterGui:SetCore("SendNotification", {
                                Title = "✓ Выбрано",
                                Text = section.name,
                                Duration = 1.5,
                            })
                        end)
                    end)
                end

                -- Функция закрытия
                UI.CloseMenu = function()
                    if menu and menu.Parent then
                        TweenService:Create(menu, TweenInfo.new(0.15), {
                            BackgroundTransparency = 1,
                        }):Play()
                        for _, d in ipairs(menu:GetDescendants()) do
                            if d:IsA("TextButton") or d:IsA("TextLabel") then
                                pcall(function()
                                    TweenService:Create(d, TweenInfo.new(0.15), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                                end)
                            end
                        end
                        task.wait(0.18)
                        menu:Destroy()
                    end
                    UI.CloseMenu = nil
                    UI.openMenuFor = nil
                end
            end
        end)
    end

    -- Второй контейнер для кнопки СТАРТ
    local actionContainer = Instance.new("Frame")
    actionContainer.Size = UDim2.new(1, 0, 0, 60)
    actionContainer.BackgroundTransparency = 1
    actionContainer.LayoutOrder = 2
    actionContainer.Parent = questPage

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1, 0, 0, 55)
    startBtn.BackgroundColor3 = COLORS.bgStart
    startBtn.Text = "▶   СТАРТ"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 17
    startBtn.AutoButtonColor = false
    startBtn.Parent = actionContainer
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

    local sStroke = Instance.new("UIStroke", startBtn)
    sStroke.Color = Color3.fromRGB(90, 200, 130)
    sStroke.Thickness = 1.5
    sStroke.Transparency = 0.3

    startBtn.MouseEnter:Connect(function()
        if State.Running then
            TweenService:Create(startBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgStopHover}):Play()
        else
            TweenService:Create(startBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgStartHover}):Play()
        end
    end)
    startBtn.MouseLeave:Connect(function()
        if State.Running then
            TweenService:Create(startBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgStop}):Play()
        else
            TweenService:Create(startBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.bgStart}):Play()
        end
    end)

    startBtn.MouseButton1Click:Connect(function()
        if State.Running then
            StopCycle()
        else
            StartSelected()
        end
    end)

    UI.startBtn = startBtn

    -- СТАТУС И ОТЛАДКА
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(1, 0, 0, 60)
    infoContainer.BackgroundTransparency = 1
    infoContainer.LayoutOrder = 3
    infoContainer.Parent = questPage

    local statusBox = Instance.new("Frame")
    statusBox.Size = UDim2.new(1, 0, 0, 26)
    statusBox.Position = UDim2.new(0, 0, 0, 0)
    statusBox.BackgroundColor3 = COLORS.bgPanel
    statusBox.BorderSizePixel = 0
    statusBox.Parent = infoContainer
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 1, 0)
    status.Position = UDim2.new(0, 8, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "Статус: готов"
    status.TextColor3 = COLORS.textDim
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = statusBox

    local debugBox = Instance.new("Frame")
    debugBox.Size = UDim2.new(1, 0, 0, 26)
    debugBox.Position = UDim2.new(0, 0, 0, 32)
    debugBox.BackgroundColor3 = Color3.fromRGB(14, 22, 18)
    debugBox.BorderSizePixel = 0
    debugBox.Parent = infoContainer
    Instance.new("UICorner", debugBox).CornerRadius = UDim.new(0, 8)

    local debug = Instance.new("TextLabel")
    debug.Size = UDim2.new(1, -16, 1, 0)
    debug.Position = UDim2.new(0, 8, 0, 0)
    debug.BackgroundTransparency = 1
    debug.Text = "отладка: ..."
    debug.TextColor3 = COLORS.textGreen
    debug.Font = Enum.Font.Code
    debug.TextSize = 11
    debug.TextXAlignment = Enum.TextXAlignment.Left
    debug.Parent = debugBox

    -- КОНТЕНТ ТЕЛЕПОРТ
    local tpPage = Instance.new("Frame")
    tpPage.Size = UDim2.new(1, -20, 1, -160)
    tpPage.Position = UDim2.new(0, 10, 0, 90)
    tpPage.BackgroundTransparency = 1
    tpPage.Visible = false
    tpPage.Parent = main
    local tpLayout = Instance.new("UIListLayout", tpPage)
    tpLayout.Padding = UDim.new(0, 8)
    tpLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, loc in ipairs(TP_LOCATIONS) do
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(1, 0, 0, 52)
        tpBtn.BackgroundColor3 = Color3.fromRGB(40, 55, 95)
        tpBtn.Text = "➤   " .. loc.name
        tpBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 14
        tpBtn.LayoutOrder = i
        tpBtn.AutoButtonColor = false
        tpBtn.Parent = tpPage
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 10)

        local tStroke = Instance.new("UIStroke", tpBtn)
        tStroke.Color = Color3.fromRGB(80, 110, 180)
        tStroke.Thickness = 1

        tpBtn.MouseEnter:Connect(function()
            TweenService:Create(tpBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 75, 130)}):Play()
        end)
        tpBtn.MouseLeave:Connect(function()
            TweenService:Create(tpBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 55, 95)}):Play()
        end)

        local pos = loc.pos
        tpBtn.MouseButton1Click:Connect(function()
            StopCycle()
            task.wait(0.05)
            task.spawn(function()
                FlyTo(pos)
                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "⚡ Телепорт",
                        Text = loc.name,
                        Duration = 2,
                    })
                end)
            end)
        end)
    end

    -- Переключение вкладок
    local function SelectTab(n)
        if n == 1 then
            questPage.Visible = true; tpPage.Visible = false
            SetTabActive(tabQuest, tabTP)
        else
            questPage.Visible = false; tpPage.Visible = true
            SetTabActive(tabTP, tabQuest)
        end
    end
    tabQuest.MouseButton1Click:Connect(function() SelectTab(1) end)
    tabTP.MouseButton1Click:Connect(function() SelectTab(2) end)

    -- Обновление статуса
    task.spawn(function()
        while gui.Parent do
            if State.Running and State.ActiveSection then
                status.Text = "⚔️  "..State.ActiveSection.name.." — убито: "..State.Killed.."/"..State.ActiveSection.killTarget
                status.TextColor3 = Color3.fromRGB(180, 255, 180)
            elseif State.SelectedSection then
                status.Text = "✓ Выбрано: "..State.SelectedSection.name
                status.TextColor3 = COLORS.textAccent
            else
                status.Text = "Статус: выбери секцию (правый клик)"
                status.TextColor3 = COLORS.textDim
            end
            debug.Text = "отладка: "..State.DebugText
            task.wait(0.3)
        end
    end)

    -- Перетаскивание
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
        Title = "⚡ БИН — АВТО КВЕСТ v18",
        Text = "Правый клик по квесту = выбор секции",
        Duration = 4,
    })
end)
