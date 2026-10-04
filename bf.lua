--[[
    BIN'S QUEST — v58
    • ESP: async scan, index, reuse (без стуттеринга)
    • Ники мобов + HP
    • Все квесты + Небесные земли
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
    SafeHeight  = 12,
    MobScale    = 6,
    HitboxSize  = 60,
    -- ESP
    ESPEnabled  = false,
    ESPMobs     = true,
    ESPBosses   = true,
    ESPPlayers  = false,
    ESPNames    = true,
    ESPDistance = 500,
    ESPColor    = Color3.fromRGB(180, 60, 60),
    ESPBossColor= Color3.fromRGB(255, 100, 40),
    ESPPlayerColor = Color3.fromRGB(80, 150, 255),
}
local FLY_ARRIVE    = 4
local KILL_TIMEOUT  = 20
local CLICK_DELAY   = 1.2
local RESPAWN_WAIT  = 3
local EQUIP_TIMEOUT = 15

local COLORS = {
    bg         = Color3.fromRGB(8, 8, 10),
    bgPanel    = Color3.fromRGB(16, 16, 20),
    bgPanelHi  = Color3.fromRGB(24, 24, 30),
    bgTitle    = Color3.fromRGB(12, 12, 16),
    bgAccent   = Color3.fromRGB(36, 36, 44),
    bgStart    = Color3.fromRGB(35, 90, 55),
    bgStop     = Color3.fromRGB(140, 45, 45),
    bgSelect   = Color3.fromRGB(45, 75, 50),
    stroke     = Color3.fromRGB(30, 30, 38),
    text       = Color3.fromRGB(230, 230, 235),
    textDim    = Color3.fromRGB(120, 120, 135),
    textAccent = Color3.fromRGB(190, 190, 210),
    textGreen  = Color3.fromRGB(130, 200, 130),
}

local BOSS_KEYWORDS = {"boss", "king", "elite", "chief", "ruler", "lord"}
local EXCLUDE_KEYWORDS = {
    "quest", "giver", "npc", "dialog",
    "adventurer", "trader", "shop", "citizen", "villager",
    "sailor", "barmaid", "guide", "trainer", "teacher",
    "vendor", "merchant", "dealer", "seller", "buyer",
    "guard", "blacksmith", "smith", "bartender",
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
        {name = "👨‍🍳  Chef", tpPos = Vector3.new(-1151, 17, 3860),
         clicks = {{1146, 403}, {1090, 552}, {1056, 474}}, mobName = "chef", killTarget = 1},
    }},
    {id = "skylands", title = "☁️  Небесные земли", sections = {
        {name = "☁️  Небесный бандит", tpPos = Vector3.new(-5402, 411, -696),
         clicks = {{1075, 483}, {1075, 483}, {1056, 474}}, mobName = "Sky Bandit", killTarget = 5},
    }},
}

local TP_LOCATIONS = {
    {name = "🏴‍☠️  Пиратский остров",  pos = Vector3.new(1108, 15, 1448)},
    {name = "🏙️  Средний город",     pos = Vector3.new(-654, 5, 1578)},
    {name = "🌴  Джунгли",           pos = Vector3.new(-1683, 50, 175)},
    {name = "🏘️  Пиратская деревня", pos = Vector3.new(-1265, 27, 4086)},
    {name = "⚓  Морской начинающий", pos = Vector3.new(-2565, 6, 2065)},
    {name = "❄️  Ледяная деревня",   pos = Vector3.new(1453, 78, -1279)},
    {name = "⛲  Город Фонтанов",    pos = Vector3.new(5205, 76, 4073)},
    {name = "🌋  Магмовая деревня",  pos = Vector3.new(-5328, 18, 8482)},
    {name = "☁️  Небесный остров",   pos = Vector3.new(-5402, 411, -696)},
}

local State = {
    Running = false, Killed = 0, DebugText = "загрузка",
    ActiveSection = nil,
    SelectedQuest = nil, SelectedSection = nil,
    Flying = false,
    ModifiedMobs = {},
    ModifiedHitboxes = {},
    WeaponName = "нет",
    FlyActive = false,
    WasDead = false,
    UICurrent = 0,
    UIRequired = 0,
    UIFound = false,
    ESPHighlights = {},
    ESPIndex = {},
    ESPLastScan = 0,
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

local function IsFullyVisible(obj)
    local p = obj
    while p and p ~= game do
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("LayerCollector") then break end
        p = p.Parent
    end
    return true
end

local function ReadQuestProgress()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil, nil end
    local best = nil
    local bestCur = -1
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "BinQuest" and gui:IsA("ScreenGui") then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") and IsFullyVisible(obj) then
                    local t = obj.Text or ""
                    t = string.gsub(t, "^%s+", "")
                    t = string.gsub(t, "%s+$", "")
                    local cur, req = string.match(t, "^(%d+)%s*/%s*(%d+)$")
                    if cur and req then
                        local c = tonumber(cur)
                        local r = tonumber(req)
                        if c and r and r >= 2 and r <= 30 and c <= r then
                            if c > bestCur then
                                bestCur = c
                                best = {cur = c, req = r}
                            end
                        end
                    end
                end
            end
        end
    end
    if best then return best.cur, best.req end
    return nil, nil
end

local function RefreshUI()
    local c, r = ReadQuestProgress()
    if c and r then
        State.UICurrent = c
        State.UIRequired = r
        State.UIFound = true
        return true
    end
    State.UIFound = false
    return false
end

--// ============================================================
-- ESP СИСТЕМА (async + reuse)
-- ============================================================
local function IsBoss(model)
    local n = string.lower(model.Name)
    for _, kw in ipairs(BOSS_KEYWORDS) do
        if string.find(n, kw, 1, true) then return true end
    end
    return false
end

local function IsMob(model)
    if not model or not model.Parent then return false end
    if model == LP.Character then return false end
    if not model:IsA("Model") then return false end
    local h = model:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    local n = string.lower(model.Name)
    for _, kw in ipairs(EXCLUDE_KEYWORDS) do
        if string.find(n, kw, 1, true) then return false end
    end
    return true
end

local function ClearESP()
    for _, data in ipairs(State.ESPHighlights) do
        if data.hl and data.hl.Parent then data.hl:Destroy() end
        if data.bg and data.bg.Parent then data.bg:Destroy() end
    end
    State.ESPHighlights = {}
    State.ESPIndex = {}
end

local function CreateNameTag(model, color)
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BinNameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 120, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = Config.ESPDistance
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = model.Name
    nameLabel.TextColor3 = color
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = billboard

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 0, 14)
    hpLabel.Position = UDim2.new(0, 0, 0, 16)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP"
    hpLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    hpLabel.Font = Enum.Font.Code
    hpLabel.TextSize = 11
    hpLabel.TextStrokeTransparency = 0
    hpLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hpLabel.Parent = billboard

    return {billboard = billboard, nameLabel = nameLabel, hpLabel = hpLabel, model = model}
end

local function AddESP(model, color)
    if State.ESPIndex[model] and State.ESPIndex[model].hl and State.ESPIndex[model].hl.Parent then
        return State.ESPIndex[model]
    end

    local hl = Instance.new("Highlight")
    hl.Name = "BinESP"
    hl.Adornee = model
    hl.FillColor = color
    hl.FillTransparency = 0.75
    hl.OutlineColor = color
    hl.OutlineTransparency = 0.2
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model

    local nametag = nil
    if Config.ESPNames then
        nametag = CreateNameTag(model, color)
    end

    local data = {
        model = model,
        hl = hl,
        bg = nametag and nametag.billboard or nil,
        nameLabel = nametag and nametag.nameLabel or nil,
        hpLabel = nametag and nametag.hpLabel or nil,
    }
    table.insert(State.ESPHighlights, data)
    State.ESPIndex[model] = data
    return data
end

local function RemoveESP(model)
    local data = State.ESPIndex[model]
    if not data then return end
    if data.hl and data.hl.Parent then data.hl:Destroy() end
    if data.bg and data.bg.Parent then data.bg:Destroy() end
    State.ESPIndex[model] = nil
    for i, d in ipairs(State.ESPHighlights) do
        if d == data then
            table.remove(State.ESPHighlights, i)
            break
        end
    end
end

local function ScanWorkspaceLight()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local myPos = myRoot.Position
    local found = {}

    local function checkModel(obj)
        if not obj:IsA("Model") then return end
        local h = obj:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return end
        local nr = obj:FindFirstChild("HumanoidRootPart")
        if not nr then return end
        local d = (nr.Position - myPos).Magnitude
        if d > Config.ESPDistance then return end
        found[obj] = d
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            checkModel(obj)
        elseif obj:IsA("Folder") then
            for _, sub in ipairs(obj:GetChildren()) do
                if sub:IsA("Model") then checkModel(sub) end
            end
        end
    end

    return found
end

local espBusy = false

local function UpdateESP()
    if not Config.ESPEnabled then
        if #State.ESPHighlights > 0 then ClearESP() end
        return
    end

    -- HP обновляем каждый кадр (только текст, дёшево)
    for _, data in ipairs(State.ESPHighlights) do
        if data.model and data.model.Parent and data.hpLabel then
            local h = data.model:FindFirstChildOfClass("Humanoid")
            if h then
                data.hpLabel.Text = math.floor(h.Health).."/"..math.floor(h.MaxHealth)
            end
        end
    end

    if tick() - State.ESPLastScan < 3 then return end
    if espBusy then return end
    State.ESPLastScan = tick()
    espBusy = true

    task.spawn(function()
        local found = ScanWorkspaceLight()

        local toRemove = {}
        for _, data in ipairs(State.ESPHighlights) do
            local m = data.model
            if not m or not m.Parent then
                table.insert(toRemove, m)
            else
                local h = m:FindFirstChildOfClass("Humanoid")
                if not h or h.Health <= 0 then
                    table.insert(toRemove, m)
                elseif not found[m] then
                    table.insert(toRemove, m)
                end
            end
        end
        for _, m in ipairs(toRemove) do
            if m then RemoveESP(m) end
        end

        for model, _ in pairs(found) do
            if not State.ESPIndex[model] then
                local isPlayer = Players:GetPlayerFromCharacter(model)
                local isBossModel = IsBoss(model)
                local color = nil

                if isPlayer and Config.ESPPlayers and model ~= LP.Character then
                    color = Config.ESPPlayerColor
                elseif not isPlayer and IsMob(model) then
                    if isBossModel and Config.ESPBosses then
                        color = Config.ESPBossColor
                    elseif not isBossModel and Config.ESPMobs then
                        color = Config.ESPColor
                    end
                end

                if color then
                    AddESP(model, color)
                end
            end
        end

        espBusy = false
    end)
end

RunService.Heartbeat:Connect(UpdateESP)

--// ============================================================
-- Основной функционал
-- ============================================================
local function ScaleMobUp(mob)
    if not mob then return end
    for _, d in ipairs(State.ModifiedMobs) do
        if d.model == mob then return end
    end
    local orig = 1
    pcall(function() orig = mob:GetScale() end)
    if pcall(function() mob:ScaleTo(Config.MobScale) end) then
        table.insert(State.ModifiedMobs, {model = mob, originalScale = orig})
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
        if not string.find(n, "fist", 1, true) and not string.find(n, "hand", 1, true) then
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
            local ct = ch:FindFirstChildOfClass("Tool")
            if ct and ct.Name == bestTool.Name then
                State.WeaponName = bestTool.Name
                return
            end
        end
        pcall(function() bestTool.Parent = ch end)
        task.wait(0.1)
        local ct2 = ch:FindFirstChildOfClass("Tool")
        if ct2 then
            State.WeaponName = ct2.Name
            return
        end
    else
        State.WeaponName = "кулак"
    end
end

LP.CharacterAdded:Connect(function(char)
    task.wait(RESPAWN_WAIT)
    State.ModifiedMobs = {}
    State.ModifiedHitboxes = {}
    local startWait = tick()
    while tick() - startWait < EQUIP_TIMEOUT do
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local c = 0
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then c = c + 1 end
            end
            if c > 0 then break end
        end
        task.wait(0.5)
    end
    for _ = 1, 5 do
        EquipWeapon()
        task.wait(0.3)
        local ch2 = LP.Character
        if ch2 and ch2:FindFirstChildOfClass("Tool") then break end
    end
end)

local function IsInteractiveNPC(model)
    if not model then return false end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            if (d.ObjectText or "") ~= "" or (d.ActionText or "") ~= "" then return true end
        end
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BillboardGui") then
            for _, sub in ipairs(d:GetDescendants()) do
                if sub:IsA("TextLabel") then
                    local t = string.lower(sub.Text or "")
                    if string.find(t, "quest", 1, true) or string.find(t, "interact", 1, true)
                       or string.find(t, "talk", 1, true) or string.find(t, "shop", 1, true) then
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
    if not r or State.FlyActive then return end
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
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
end
local function DisableNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
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
        if not State.Flying or not r.Parent then break end
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
                    if not isExcluded and IsInteractiveNPC(obj) then isExcluded = true end
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
            UI.startBtn.Text = "СТАРТ"
            UI.startBtn.BackgroundColor3 = COLORS.bgStart
        end
    end
end

local function TakeQuestAtNPC(s)
    Log("полёт к квестодателю")
    FlyTo(s.tpPos)
    task.wait(0.3)
    for i, clk in ipairs(s.clicks) do
        if not State.Running then return false end
        if not Alive() then return false end
        Log("клик "..i.."/"..#s.clicks)
        ClickAt(clk[1], clk[2])
        if i < #s.clicks then task.wait(CLICK_DELAY) end
    end
    task.wait(1.5)
    return true
end

local function StartSelected()
    if not State.SelectedSection then Log("не выбрана секция"); return end
    StopCycle()
    task.wait(0.1)
    local s = State.SelectedSection
    State.ActiveSection = s
    State.Running = true
    State.Killed = 0
    State.UICurrent = 0
    State.UIRequired = 0
    State.UIFound = false
    if UI.startBtn then
        UI.startBtn.Text = "СТОП"
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

            if not TakeQuestAtNPC(s) then
                task.wait(1); continue
            end

            State.UICurrent = 0
            State.UIRequired = 0
            State.UIFound = false

            Log("ждём UI на "..s.killTarget.."...")
            local t0 = tick()
            local uiOK = false
            while tick() - t0 < 20 do
                if not State.Running then break end
                RefreshUI()
                if State.UIFound and State.UIRequired == s.killTarget then
                    uiOK = true
                    Log("UI готов: "..State.UICurrent.."/"..State.UIRequired)
                    break
                end
                task.wait(0.4)
            end

            if not uiOK then
                Log("⚠️ UI не подтверждён — fallback")
                State.Killed = 0
            else
                State.Killed = State.UICurrent
            end

            local lastKilled = State.Killed
            local stuckCount = 0
            local loopStart = tick()

            while State.Running and State.ActiveSection == s do
                if not Alive() then break end
                if tick() - loopStart > 300 then
                    Log("⏱ лимит, выходим")
                    break
                end

                RefreshUI()

                if State.UIFound and State.UIRequired == s.killTarget then
                    if State.UICurrent >= State.UIRequired then
                        Log("✅ UI: "..State.UICurrent.."/"..State.UIRequired)
                        break
                    end
                else
                    if State.Killed >= s.killTarget then
                        Log("✅ свой: "..State.Killed.."/"..s.killTarget)
                        break
                    end
                end

                if State.UICurrent == lastKilled and State.Killed == lastKilled then
                    stuckCount = stuckCount + 1
                    if stuckCount > 40 then
                        Log("⚠️ застревание — выходим")
                        break
                    end
                else
                    stuckCount = 0
                    lastKilled = math.max(State.UICurrent, State.Killed)
                end

                local uiInfo = State.UIFound and (State.UICurrent.."/"..State.UIRequired) or "нет"
                Log("убиваю | UI: "..uiInfo.." | свой: "..State.Killed)

                if KillOneMob(s) then
                    State.Killed = State.Killed + 1
                    task.wait(1.2)
                    RefreshUI()
                    if State.UIFound and State.UICurrent > State.Killed then
                        State.Killed = State.UICurrent
                    end
                else
                    Log("жду моба...")
                    task.wait(1)
                end
                task.wait(0.3)
            end
            task.wait(1)
        end
    end)
end

--// ============================================================
-- UI
-- ============================================================
local function CreateUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BinQuest"
    gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 340, 0, 480)
    main.Position = UDim2.new(0.5, -170, 0.5, -240)
    main.BackgroundColor3 = COLORS.bg
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = COLORS.stroke
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.3

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = COLORS.bgTitle
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 20)
    local tbCut = Instance.new("Frame")
    tbCut.Size = UDim2.new(1, 0, 0, 16)
    tbCut.Position = UDim2.new(0, 0, 1, -16)
    tbCut.BackgroundColor3 = COLORS.bgTitle
    tbCut.BorderSizePixel = 0
    tbCut.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -55, 1, 0)
    title.Position = UDim2.new(0, 18, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BIN QUEST"
    title.TextColor3 = COLORS.textAccent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Active = true
    title.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -34, 0, 9)
    close.BackgroundColor3 = Color3.fromRGB(50, 25, 25)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(180, 130, 130)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.AutoButtonColor = false
    close.Parent = titleBar
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function()
        StopFreeFly(); StopCycle(); ClearESP(); gui:Destroy()
    end)

    local tabsFrame = Instance.new("Frame")
    tabsFrame.Size = UDim2.new(1, -24, 0, 36)
    tabsFrame.Position = UDim2.new(0, 12, 0, 54)
    tabsFrame.BackgroundColor3 = COLORS.bgPanel
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Active = true
    tabsFrame.Parent = main
    Instance.new("UICorner", tabsFrame).CornerRadius = UDim.new(0, 12)

    local function MakeTab(text, order, total)
        local tab = Instance.new("TextButton")
        local w = 1 / total
        tab.Size = UDim2.new(w, -4, 1, -4)
        tab.Position = UDim2.new((order - 1) * w + 0.012, 0, 0, 2)
        tab.BackgroundColor3 = Color3.fromRGB(0,0,0)
        tab.BackgroundTransparency = 1
        tab.Text = text
        tab.TextColor3 = COLORS.textDim
        tab.Font = Enum.Font.GothamBold
        tab.TextSize = 10
        tab.AutoButtonColor = false
        tab.Parent = tabsFrame
        Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 9)
        return tab
    end

    local tabQuest = MakeTab("КВЕСТ", 1, 4)
    local tabTP    = MakeTab("ТП", 2, 4)
    local tabESP   = MakeTab("ESP", 3, 4)
    local tabCfg   = MakeTab("НАСТР", 4, 4)
    tabQuest.BackgroundColor3 = COLORS.bgAccent
    tabQuest.BackgroundTransparency = 0
    tabQuest.TextColor3 = COLORS.text

    local function SetTabActive(active, inactives)
        TweenService:Create(active, TweenInfo.new(0.15), {BackgroundColor3=COLORS.bgAccent, BackgroundTransparency=0, TextColor3=COLORS.text}):Play()
        for _, inac in ipairs(inactives) do
            TweenService:Create(inac, TweenInfo.new(0.15), {BackgroundTransparency=1, TextColor3=COLORS.textDim}):Play()
        end
    end

    -- КВЕСТ
    local questPage = Instance.new("Frame")
    questPage.Size = UDim2.new(1, -24, 1, -175)
    questPage.Position = UDim2.new(0, 12, 0, 100)
    questPage.BackgroundTransparency = 1
    questPage.Parent = main

    local questScroll = Instance.new("ScrollingFrame")
    questScroll.Size = UDim2.new(1, 0, 1, -110)
    questScroll.BackgroundTransparency = 1
    questScroll.BorderSizePixel = 0
    questScroll.ScrollBarThickness = 3
    questScroll.ScrollBarImageColor3 = COLORS.bgAccent
    questScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    questScroll.Parent = questPage
    local ql = Instance.new("UIListLayout", questScroll)
    ql.Padding = UDim.new(0, 6)
    ql.SortOrder = Enum.SortOrder.LayoutOrder

    local questButtons = {}
    local function UpdateQuestButtons()
        for id, btn in pairs(questButtons) do
            if State.SelectedQuest and State.SelectedQuest.id == id then
                btn.BackgroundColor3 = COLORS.bgSelect
                btn.TextColor3 = Color3.fromRGB(200, 230, 200)
            else
                btn.BackgroundColor3 = COLORS.bgPanel
                btn.TextColor3 = COLORS.text
            end
        end
    end

    for qi, quest in ipairs(QUESTS) do
        local qBtn = Instance.new("TextButton")
        qBtn.Size = UDim2.new(1, -6, 0, 50)
        qBtn.BackgroundColor3 = COLORS.bgPanel
        qBtn.Text = quest.title
        qBtn.TextColor3 = COLORS.text
        qBtn.Font = Enum.Font.GothamBold
        qBtn.TextSize = 12
        qBtn.LayoutOrder = qi
        qBtn.AutoButtonColor = false
        qBtn.Parent = questScroll
        Instance.new("UICorner", qBtn).CornerRadius = UDim.new(0, 14)
        local qStroke = Instance.new("UIStroke", qBtn)
        qStroke.Color = COLORS.stroke
        qStroke.Thickness = 1
        qStroke.Transparency = 0.5
        questButtons[quest.id] = qBtn

        qBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if UI.openMenuFor == quest.id then
                    if UI.CloseMenu then UI.CloseMenu() end
                    return
                end
                if UI.CloseMenu then UI.CloseMenu() end
                UI.openMenuFor = quest.id

                local menuH = #quest.sections * 38 + 16
                local menu = Instance.new("Frame")
                menu.Size = UDim2.new(0, 230, 0, menuH)
                menu.Position = UDim2.new(0, qBtn.AbsolutePosition.X + 55, 0, qBtn.AbsolutePosition.Y + 25)
                menu.BackgroundColor3 = COLORS.bgPanel
                menu.BorderSizePixel = 0
                menu.ZIndex = 10
                menu.Parent = gui
                Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 14)
                local ms = Instance.new("UIStroke", menu)
                ms.Color = COLORS.stroke
                ms.Thickness = 1
                ms.Transparency = 0.3

                local mh = Instance.new("TextLabel")
                mh.Size = UDim2.new(1, 0, 0, 22)
                mh.BackgroundTransparency = 1
                mh.Text = "СЕКЦИИ"
                mh.TextColor3 = COLORS.textDim
                mh.Font = Enum.Font.GothamBold
                mh.TextSize = 10
                mh.ZIndex = 11
                mh.Parent = menu

                local ml = Instance.new("UIListLayout", menu)
                ml.Padding = UDim.new(0, 5)
                ml.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ml.VerticalAlignment = Enum.VerticalAlignment.Bottom

                for si, section in ipairs(quest.sections) do
                    local sBtn = Instance.new("TextButton")
                    sBtn.Size = UDim2.new(0.92, 0, 0, 32)
                    sBtn.BackgroundColor3 = COLORS.bgAccent
                    sBtn.Text = section.name
                    sBtn.TextColor3 = COLORS.text
                    sBtn.Font = Enum.Font.GothamBold
                    sBtn.TextSize = 12
                    sBtn.AutoButtonColor = false
                    sBtn.LayoutOrder = si
                    sBtn.ZIndex = 11
                    sBtn.Parent = menu
                    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 10)
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
                    UI.CloseMenu = nil
                    UI.openMenuFor = nil
                end
            end
        end)
    end

    local actionFrame = Instance.new("Frame")
    actionFrame.Size = UDim2.new(1, 0, 0, 100)
    actionFrame.Position = UDim2.new(0, 0, 1, -108)
    actionFrame.BackgroundTransparency = 1
    actionFrame.Parent = questPage

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1, 0, 0, 44)
    startBtn.Position = UDim2.new(0, 0, 0, 0)
    startBtn.BackgroundColor3 = COLORS.bgStart
    startBtn.Text = "СТАРТ"
    startBtn.TextColor3 = Color3.fromRGB(230, 255, 230)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 14
    startBtn.AutoButtonColor = false
    startBtn.Parent = actionFrame
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 14)
    local sStroke = Instance.new("UIStroke", startBtn)
    sStroke.Color = Color3.fromRGB(60, 130, 80)
    sStroke.Thickness = 1
    sStroke.Transparency = 0.5
    startBtn.MouseButton1Click:Connect(function()
        if State.Running then StopCycle() else StartSelected() end
    end)
    UI.startBtn = startBtn

    local statusBox = Instance.new("Frame")
    statusBox.Size = UDim2.new(1, 0, 0, 22)
    statusBox.Position = UDim2.new(0, 0, 0, 50)
    statusBox.BackgroundColor3 = COLORS.bgPanel
    statusBox.BorderSizePixel = 0
    statusBox.Parent = actionFrame
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -12, 1, 0)
    status.Position = UDim2.new(0, 8, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "ожидание"
    status.TextColor3 = COLORS.textDim
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = statusBox

    local debugBox = Instance.new("Frame")
    debugBox.Size = UDim2.new(1, 0, 0, 22)
    debugBox.Position = UDim2.new(0, 0, 0, 76)
    debugBox.BackgroundColor3 = Color3.fromRGB(6, 10, 8)
    debugBox.BorderSizePixel = 0
    debugBox.Parent = actionFrame
    Instance.new("UICorner", debugBox).CornerRadius = UDim.new(0, 8)

    local debug = Instance.new("TextLabel")
    debug.Size = UDim2.new(1, -12, 1, 0)
    debug.Position = UDim2.new(0, 8, 0, 0)
    debug.BackgroundTransparency = 1
    debug.Text = "отладка..."
    debug.TextColor3 = COLORS.textGreen
    debug.Font = Enum.Font.Code
    debug.TextSize = 9
    debug.TextXAlignment = Enum.TextXAlignment.Left
    debug.Parent = debugBox

    -- ТП
    local tpPage = Instance.new("Frame")
    tpPage.Size = UDim2.new(1, -24, 1, -175)
    tpPage.Position = UDim2.new(0, 12, 0, 100)
    tpPage.BackgroundTransparency = 1
    tpPage.Visible = false
    tpPage.Parent = main

    local tpScroll = Instance.new("ScrollingFrame")
    tpScroll.Size = UDim2.new(1, 0, 1, 0)
    tpScroll.BackgroundTransparency = 1
    tpScroll.BorderSizePixel = 0
    tpScroll.ScrollBarThickness = 3
    tpScroll.ScrollBarImageColor3 = COLORS.bgAccent
    tpScroll.CanvasSize = UDim2.new(0, 0, 0, #TP_LOCATIONS * 54)
    tpScroll.Parent = tpPage

    local tpl = Instance.new("UIListLayout", tpScroll)
    tpl.Padding = UDim.new(0, 6)
    tpl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, loc in ipairs(TP_LOCATIONS) do
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(1, -6, 0, 46)
        tpBtn.BackgroundColor3 = COLORS.bgPanel
        tpBtn.Text = loc.name
        tpBtn.TextColor3 = COLORS.text
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 12
        tpBtn.LayoutOrder = i
        tpBtn.AutoButtonColor = false
        tpBtn.Parent = tpScroll
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 14)
        local tStroke = Instance.new("UIStroke", tpBtn)
        tStroke.Color = COLORS.stroke
        tStroke.Thickness = 1
        tStroke.Transparency = 0.5

        local pos = loc.pos
        tpBtn.MouseButton1Click:Connect(function()
            StopCycle()
            task.wait(0.05)
            task.spawn(function() FlyTo(pos) end)
        end)
    end

    -- ESP
    local espPage = Instance.new("Frame")
    espPage.Size = UDim2.new(1, -24, 1, -175)
    espPage.Position = UDim2.new(0, 12, 0, 100)
    espPage.BackgroundTransparency = 1
    espPage.Visible = false
    espPage.Parent = main

    local espScroll = Instance.new("ScrollingFrame")
    espScroll.Size = UDim2.new(1, 0, 1, 0)
    espScroll.BackgroundTransparency = 1
    espScroll.BorderSizePixel = 0
    espScroll.ScrollBarThickness = 3
    espScroll.ScrollBarImageColor3 = COLORS.bgAccent
    espScroll.CanvasSize = UDim2.new(0, 0, 0, 500)
    espScroll.Parent = espPage

    local el = Instance.new("UIListLayout", espScroll)
    el.Padding = UDim.new(0, 8)
    el.SortOrder = Enum.SortOrder.LayoutOrder

    local function MakeToggleRow(label, order, key, onText, offText)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 50)
        row.BackgroundColor3 = COLORS.bgPanel
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = espScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
        local rs = Instance.new("UIStroke", row)
        rs.Color = COLORS.stroke
        rs.Thickness = 1
        rs.Transparency = 0.5

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COLORS.text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local tgl = Instance.new("TextButton")
        tgl.Size = UDim2.new(0, 64, 0, 30)
        tgl.Position = UDim2.new(1, -76, 0, 10)
        tgl.BackgroundColor3 = Config[key] and COLORS.bgStart or Color3.fromRGB(45, 30, 30)
        tgl.Text = Config[key] and onText or offText
        tgl.TextColor3 = Config[key] and Color3.fromRGB(230, 255, 230) or Color3.fromRGB(180, 140, 140)
        tgl.Font = Enum.Font.GothamBold
        tgl.TextSize = 11
        tgl.AutoButtonColor = false
        tgl.Parent = row
        Instance.new("UICorner", tgl).CornerRadius = UDim.new(0, 10)
        tgl.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            if Config[key] then
                tgl.BackgroundColor3 = COLORS.bgStart
                tgl.Text = onText
                tgl.TextColor3 = Color3.fromRGB(230, 255, 230)
            else
                tgl.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
                tgl.Text = offText
                tgl.TextColor3 = Color3.fromRGB(180, 140, 140)
            end
            if not Config.ESPEnabled then ClearESP() end
        end)
        return tgl
    end

    MakeToggleRow("ESP включён", 1, "ESPEnabled", "ВКЛ", "ВЫКЛ")
    MakeToggleRow("Мобы", 2, "ESPMobs", "ВКЛ", "ВЫКЛ")
    MakeToggleRow("Боссы", 3, "ESPBosses", "ВКЛ", "ВЫКЛ")
    MakeToggleRow("Игроки", 4, "ESPPlayers", "ВКЛ", "ВЫКЛ")
    MakeToggleRow("Ники мобов", 5, "ESPNames", "ВКЛ", "ВЫКЛ")

    local espDistRow = Instance.new("Frame")
    espDistRow.Size = UDim2.new(1, -6, 0, 58)
    espDistRow.BackgroundColor3 = COLORS.bgPanel
    espDistRow.BorderSizePixel = 0
    espDistRow.LayoutOrder = 6
    espDistRow.Parent = espScroll
    Instance.new("UICorner", espDistRow).CornerRadius = UDim.new(0, 14)
    local eds = Instance.new("UIStroke", espDistRow)
    eds.Color = COLORS.stroke
    eds.Thickness = 1
    eds.Transparency = 0.5

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(0.7, 0, 0, 20)
    distLbl.Position = UDim2.new(0, 14, 0, 7)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "Дистанция"
    distLbl.TextColor3 = COLORS.text
    distLbl.Font = Enum.Font.GothamBold
    distLbl.TextSize = 12
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = espDistRow

    local distVal = Instance.new("TextLabel")
    distVal.Size = UDim2.new(0.3, 0, 0, 20)
    distVal.Position = UDim2.new(0.7, -14, 0, 7)
    distVal.BackgroundTransparency = 1
    distVal.Text = tostring(Config.ESPDistance)
    distVal.TextColor3 = COLORS.textAccent
    distVal.Font = Enum.Font.GothamBold
    distVal.TextSize = 12
    distVal.TextXAlignment = Enum.TextXAlignment.Right
    distVal.Parent = espDistRow

    local distBar = Instance.new("Frame")
    distBar.Size = UDim2.new(1, -28, 0, 6)
    distBar.Position = UDim2.new(0, 14, 0, 38)
    distBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    distBar.BorderSizePixel = 0
    distBar.Parent = espDistRow
    Instance.new("UICorner", distBar).CornerRadius = UDim.new(0, 3)

    local distFill = Instance.new("Frame")
    distFill.Size = UDim2.new((Config.ESPDistance - 100) / 1900, 0, 1, 0)
    distFill.BackgroundColor3 = COLORS.bgAccent
    distFill.BorderSizePixel = 0
    distFill.Parent = distBar
    Instance.new("UICorner", distFill).CornerRadius = UDim.new(0, 3)

    local distBtn = Instance.new("TextButton")
    distBtn.Size = UDim2.new(1, 0, 1, 0)
    distBtn.BackgroundTransparency = 1
    distBtn.Text = ""
    distBtn.Parent = distBar

    local distDrag = false
    local function updateDist(x)
        local rel = math.clamp((x - distBar.AbsolutePosition.X) / distBar.AbsoluteSize.X, 0, 1)
        local v = 100 + rel * 1900
        v = math.floor(v / 50 + 0.5) * 50
        Config.ESPDistance = v
        distVal.Text = tostring(v)
        distFill.Size = UDim2.new((v - 100) / 1900, 0, 1, 0)
        for _, data in ipairs(State.ESPHighlights) do
            if data.bg and data.bg.Parent then
                data.bg.MaxDistance = v
            end
        end
    end
    distBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            distDrag = true
            updateDist(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if distDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDist(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then distDrag = false end
    end)

    local espInfo = Instance.new("TextLabel")
    espInfo.Size = UDim2.new(1, -6, 0, 60)
    espInfo.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    espInfo.LayoutOrder = 7
    espInfo.Text = "ESP подсвечивает мобов сквозь стены.\nКрасный — мобы, оранжевый — боссы.\nНики с HP видны над мобами."
    espInfo.TextColor3 = COLORS.textDim
    espInfo.Font = Enum.Font.Gotham
    espInfo.TextSize = 10
    espInfo.TextXAlignment = Enum.TextXAlignment.Center
    espInfo.TextYAlignment = Enum.TextYAlignment.Center
    espInfo.Parent = espScroll
    Instance.new("UICorner", espInfo).CornerRadius = UDim.new(0, 14)

    -- НАСТР
    local cfgPage = Instance.new("Frame")
    cfgPage.Size = UDim2.new(1, -24, 1, -175)
    cfgPage.Position = UDim2.new(0, 12, 0, 100)
    cfgPage.BackgroundTransparency = 1
    cfgPage.Visible = false
    cfgPage.Parent = main

    local cfgScroll = Instance.new("ScrollingFrame")
    cfgScroll.Size = UDim2.new(1, 0, 1, 0)
    cfgScroll.BackgroundTransparency = 1
    cfgScroll.BorderSizePixel = 0
    cfgScroll.ScrollBarThickness = 3
    cfgScroll.ScrollBarImageColor3 = COLORS.bgAccent
    cfgScroll.CanvasSize = UDim2.new(0, 0, 0, 350)
    cfgScroll.Parent = cfgPage

    local cfgl = Instance.new("UIListLayout", cfgScroll)
    cfgl.Padding = UDim.new(0, 8)
    cfgl.SortOrder = Enum.SortOrder.LayoutOrder

    local flyRow = Instance.new("Frame")
    flyRow.Size = UDim2.new(1, -6, 0, 52)
    flyRow.BackgroundColor3 = COLORS.bgPanel
    flyRow.BorderSizePixel = 0
    flyRow.LayoutOrder = 1
    flyRow.Parent = cfgScroll
    Instance.new("UICorner", flyRow).CornerRadius = UDim.new(0, 14)
    local fStroke = Instance.new("UIStroke", flyRow)
    fStroke.Color = COLORS.stroke
    fStroke.Thickness = 1
    fStroke.Transparency = 0.5

    local flyLbl = Instance.new("TextLabel")
    flyLbl.Size = UDim2.new(0.6, 0, 1, 0)
    flyLbl.Position = UDim2.new(0, 14, 0, 0)
    flyLbl.BackgroundTransparency = 1
    flyLbl.Text = "Свободный полёт"
    flyLbl.TextColor3 = COLORS.text
    flyLbl.Font = Enum.Font.GothamBold
    flyLbl.TextSize = 12
    flyLbl.TextXAlignment = Enum.TextXAlignment.Left
    flyLbl.Parent = flyRow

    local flyToggle = Instance.new("TextButton")
    flyToggle.Size = UDim2.new(0, 64, 0, 30)
    flyToggle.Position = UDim2.new(1, -76, 0, 11)
    flyToggle.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
    flyToggle.Text = "ВЫКЛ"
    flyToggle.TextColor3 = Color3.fromRGB(180, 140, 140)
    flyToggle.Font = Enum.Font.GothamBold
    flyToggle.TextSize = 11
    flyToggle.AutoButtonColor = false
    flyToggle.Parent = flyRow
    Instance.new("UICorner", flyToggle).CornerRadius = UDim.new(0, 10)
    flyToggle.MouseButton1Click:Connect(function()
        if State.FlyActive then
            StopFreeFly()
            flyToggle.Text = "ВЫКЛ"
            flyToggle.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
            flyToggle.TextColor3 = Color3.fromRGB(180, 140, 140)
        else
            StartFreeFly()
            flyToggle.Text = "ВКЛ"
            flyToggle.BackgroundColor3 = COLORS.bgStart
            flyToggle.TextColor3 = Color3.fromRGB(230, 255, 230)
        end
    end)

    local function MakeSlider(label, order, key, min, max, step)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 58)
        row.BackgroundColor3 = COLORS.bgPanel
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = cfgScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
        local rs = Instance.new("UIStroke", row)
        rs.Color = COLORS.stroke
        rs.Thickness = 1
        rs.Transparency = 0.5

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 0, 20)
        lbl.Position = UDim2.new(0, 14, 0, 7)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = COLORS.text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.3, 0, 0, 20)
        val.Position = UDim2.new(0.7, -14, 0, 7)
        val.BackgroundTransparency = 1
        val.Text = tostring(Config[key])
        val.TextColor3 = COLORS.textAccent
        val.Font = Enum.Font.GothamBold
        val.TextSize = 12
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -28, 0, 6)
        bar.Position = UDim2.new(0, 14, 0, 38)
        bar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        bar.BorderSizePixel = 0
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((Config[key]-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = COLORS.bgAccent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bar

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

    MakeSlider("Скорость полёта", 2, "FlySpeed", 50, 500, 10)
    MakeSlider("Высота над мобом", 3, "SafeHeight", 3, 40, 1)
    MakeSlider("Размер моба (x)", 4, "MobScale", 1, 8, 0.5)
    MakeSlider("Размер хитбокса", 5, "HitboxSize", 40, 500, 20)

    local function SelectTab(n)
        questPage.Visible = (n == 1)
        tpPage.Visible = (n == 2)
        espPage.Visible = (n == 3)
        cfgPage.Visible = (n == 4)
        if n == 1 then SetTabActive(tabQuest, {tabTP, tabESP, tabCfg})
        elseif n == 2 then SetTabActive(tabTP, {tabQuest, tabESP, tabCfg})
        elseif n == 3 then SetTabActive(tabESP, {tabQuest, tabTP, tabCfg})
        else SetTabActive(tabCfg, {tabQuest, tabTP, tabESP}) end
    end
    tabQuest.MouseButton1Click:Connect(function() SelectTab(1) end)
    tabTP.MouseButton1Click:Connect(function() SelectTab(2) end)
    tabESP.MouseButton1Click:Connect(function() SelectTab(3) end)
    tabCfg.MouseButton1Click:Connect(function() SelectTab(4) end)

    task.spawn(function()
        while gui.Parent do
            if State.Running and State.ActiveSection then
                local uiInfo = State.UIFound
                    and (State.UICurrent.."/"..State.UIRequired)
                    or "нет UI"
                status.Text = State.ActiveSection.name.."  •  "..uiInfo
                status.TextColor3 = Color3.fromRGB(160, 220, 160)
            elseif State.FlyActive then
                status.Text = "свободный полёт"
                status.TextColor3 = Color3.fromRGB(150, 180, 230)
            elseif State.SelectedSection then
                status.Text = State.SelectedSection.name
                status.TextColor3 = COLORS.textAccent
            else
                status.Text = "выбери секцию (правый клик по квесту)"
                status.TextColor3 = COLORS.textDim
            end
            debug.Text = State.DebugText
            task.wait(0.3)
        end
    end)

    local dragging, ds, sp
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ds = input.Position
            sp = main.Position
        end
    end
    local function updateDrag(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end
    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    titleBar.InputBegan:Connect(startDrag)
    title.InputBegan:Connect(startDrag)
    tbCut.InputBegan:Connect(startDrag)
    main.InputBegan:Connect(startDrag)
    UserInputService.InputChanged:Connect(updateDrag)
    UserInputService.InputEnded:Connect(endDrag)
end

CreateUI()
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "BIN QUEST v58",
        Text = "ESP: без стуттеринга, ники + HP",
        Duration = 4,
    })
end)
