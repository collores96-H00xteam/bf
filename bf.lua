-- Bin's Blox Fruits Hub v9 — SAFE ATTACK
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInput = nil
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 30)
local camera = workspace.CurrentCamera

local character, root, humanoid
local function bind(char)
    if not char then return end
    character = char
    root = char:WaitForChild("HumanoidRootPart", 15)
    humanoid = char:WaitForChild("Humanoid", 15)
end
if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)
local w = 0
while (not character or not root or not humanoid) and w < 60 do
    task.wait(0.5); w = w + 0.5
    if player.Character then bind(player.Character) end
end

local function getRoot()
    if not character or not character.Parent then
        if player.Character and player.Character.Parent then bind(player.Character) end
    end
    if not root or not root.Parent then return nil end
    return root
end

local function groundY(x, z, y)
    local ok, res = pcall(function()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = character and {character} or {}
        rp.IgnoreWater = true
        return workspace:Raycast(Vector3.new(x, y or 500, z), Vector3.new(0, -1000, 0), rp)
    end)
    if ok and res then return res.Position.Y end
    return nil
end

local function tpTo(pos)
    local r = getRoot(); if not r then return end
    local gy = groundY(pos.X, pos.Z, pos.Y + 400)
    local fy = gy and (gy + 3.5) or (pos.Y + 3.5)
    pcall(function() r.CFrame = CFrame.new(pos.X, fy, pos.Z) end)
    task.wait(0.05)
    local gy2 = groundY(pos.X, pos.Z, fy + 30)
    if gy2 and math.abs(gy2 + 3.5 - fy) > 2 then
        pcall(function() r.CFrame = CFrame.new(pos.X, gy2 + 3.5, pos.Z) end)
    end
end

local function tpToNPC(npc)
    if not npc or not npc.Parent then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local r = getRoot(); if not hrp or not r then return end
    local t = hrp.Position
    local gy = groundY(t.X, t.Z, t.Y + 30)
    local fy = gy and (gy + 3.5) or (t.Y + 3.5)
    pcall(function() r.CFrame = CFrame.lookAt(Vector3.new(t.X, fy, t.Z), t) end)
end

local state = {
    autoFarmLevel = false, autoFarmPirates = false, autoFarmMarines = false,
    autoFarmBosses = false, attackSpeed = 0.35, killAura = false, killAuraRange = 45,
    safeAttackHeight = 14, selectedTP = "Pirate Island", espNPCs = false, espPlayers = false,
    autoChest = false, autoFruit = false,
}

local TP_LOCATIONS = {
    { name = "Bandit Camp",       icon = "🏕️", pos = Vector3.new(-1110, 20, 3200), sea = 1 },
    { name = "Pirate Village",    icon = "🏘️", pos = Vector3.new(-1200, 20, 3400), sea = 1 },
    { name = "Marine Fort",       icon = "🛡️", pos = Vector3.new(-2800, 20, 4300), sea = 1 },
    { name = "Jungle",            icon = "🌴", pos = Vector3.new(-1600, 20, 200),  sea = 1 },
    { name = "Marine Ford",       icon = "⚓", pos = Vector3.new(-2760, 20, 4320), sea = 1 },
    { name = "Fountain City",     icon = "⛲", pos = Vector3.new(-1250, 20, 3200), sea = 1 },
    { name = "Pirate Island",     icon = "🏴‍☠️", pos = Vector3.new(1000, 20, 1200),  sea = 1 },
    { name = "First Sea Port",    icon = "🚢", pos = Vector3.new(400, 20, 400),    sea = 1 },
    { name = "Colosseum",         icon = "🏛️", pos = Vector3.new(-1500, 20, 200),  sea = 1 },
    { name = "Desert",            icon = "🏜️", pos = Vector3.new(1000, 20, 4500),  sea = 1 },
    { name = "Snow Island",       icon = "❄️", pos = Vector3.new(1250, 20, -1500), sea = 1 },
    { name = "Skylands",          icon = "☁️", pos = Vector3.new(-500, 800, -1500), sea = 1 },
    { name = "Prison",            icon = "🔒", pos = Vector3.new(5000, 20, 800),   sea = 1 },
    { name = "Kingdom of Rose",   icon = "🌹", pos = Vector3.new(-400, 20, 6000),  sea = 2 },
    { name = "Green Zone",        icon = "🌿", pos = Vector3.new(-3500, 20, -4500), sea = 2 },
    { name = "Graveyard",         icon = "⚰️", pos = Vector3.new(-5500, 20, -3000), sea = 2 },
    { name = "Snow Mountain",     icon = "🏔️", pos = Vector3.new(-1500, 20, -5500), sea = 2 },
    { name = "Cursed Ship",       icon = "👻", pos = Vector3.new(9000, 20, 5000),  sea = 2 },
    { name = "Ice Castle",        icon = "🏰", pos = Vector3.new(-6000, 20, -6000), sea = 2 },
    { name = "Forgotten Island",  icon = "🗿", pos = Vector3.new(-3000, 20, -8000), sea = 2 },
    { name = "Port Town",         icon = "⛵", pos = Vector3.new(-500, 20, -10000), sea = 3 },
    { name = "Hydra Island",      icon = "🐉", pos = Vector3.new(5000, 20, -9000),  sea = 3 },
    { name = "Great Tree",        icon = "🌳", pos = Vector3.new(-3000, 20, -12000), sea = 3 },
    { name = "Floating Turtle",   icon = "🐢", pos = Vector3.new(-9000, 20, -10000), sea = 3 },
    { name = "Haunted Castle",    icon = "🏚️", pos = Vector3.new(3000, 20, -12000), sea = 3 },
    { name = "Castle on the Sea", icon = "🏰", pos = Vector3.new(-6000, 20, -14000), sea = 3 },
    { name = "Sea of Treats",     icon = "🍭", pos = Vector3.new(5000, 20, -15000), sea = 3 },
}

local function findLoc(name)
    for _, l in ipairs(TP_LOCATIONS) do if l.name == name then return l end end
end

local WAYPOINTS, wpOrder = {}, {}
local function saveWP(name)
    local r = getRoot(); if not r or not name or name == "" then return end
    if not WAYPOINTS[name] then table.insert(wpOrder, name) end
    WAYPOINTS[name] = r.Position
end
local function delWP(name)
    if WAYPOINTS[name] then
        WAYPOINTS[name] = nil
        for i, n in ipairs(wpOrder) do if n == name then table.remove(wpOrder, i); break end end
    end
end

local npcCache = {}
local KW = {
    pirate = {"Pirate","Bandit","Brute","Thief","Criminal","Rogue","Buccaneer","Smoker","Clown"},
    marine = {"Marine","Soldier","Officer","Captain","Vice","Commander","Guard","Sword"},
    boss   = {"Boss","Lord","King","Queen","Captain","Admiral","Warden","Diamond","Cyborg"},
}
local function matchKw(n, list)
    for _, k in ipairs(list) do if n:find(k) then return true end end
    return false
end
local function scan(c, out)
    if not c then return end
    local ok, ch = pcall(function() return c:GetChildren() end)
    if not ok then return end
    for _, o in ipairs(ch) do
        if o:IsA("Model") and o:FindFirstChild("Humanoid") and o:FindFirstChild("HumanoidRootPart")
           and not Players:GetPlayerFromCharacter(o) then
            local h = o.Humanoid
            if h and h.Health > 0 then
                local t = "other"
                if matchKw(o.Name, KW.boss) then t = "boss"
                elseif matchKw(o.Name, KW.pirate) then t = "pirate"
                elseif matchKw(o.Name, KW.marine) then t = "marine" end
                table.insert(out, { model = o, tag = t })
            end
        end
    end
end
local function refresh()
    local nc = {}
    local ef = workspace:FindFirstChild("Enemies")
    if ef then scan(ef, nc) end
    if #nc == 0 then scan(workspace, nc) end
    npcCache = nc
end
task.spawn(function() while task.wait(1) do pcall(refresh) end end)

local function nearest(tag)
    local r = getRoot(); if not r then return nil end
    local p = r.Position
    local best, bd = nil, math.huge
    for _, e in ipairs(npcCache) do
        if tag == "all" or e.tag == tag then
            local hrp = e.model:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - p).Magnitude
                if d < bd then bd = d; best = e.model end
            end
        end
    end
    return best
end

local chestList, fruitList = {}, {}
local function classify(o)
    pcall(function()
        if not (o:IsA("Model") or o:IsA("BasePart")) then return end
        local n = o.Name:lower()
        if n:find("chest") or n:find("crate") then chestList[o] = true
        elseif n:find("fruit") or n:find("devil") then fruitList[o] = true end
    end)
end
pcall(function()
    for _, o in ipairs(workspace:GetDescendants()) do classify(o) end
end)
workspace.DescendantAdded:Connect(classify)
task.spawn(function()
    while task.wait(2) do
        for o in pairs(chestList) do if not o.Parent then chestList[o] = nil end end
        for o in pairs(fruitList) do if not o.Parent then fruitList[o] = nil end end
    end
end)
local function nearestIn(list, md)
    local r = getRoot(); if not r then return nil end
    local p = r.Position
    local best, bd = nil, md or math.huge
    for o in pairs(list) do
        local pp = o:IsA("Model") and (o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Handle") or o.PrimaryPart) or o
        if pp and pp.Position then
            local d = (pp.Position - p).Magnitude
            if d < bd then bd = d; best = o end
        end
    end
    return best
end

-- ============================================================
-- АТАКА СВЕРХУ (safe attack)
-- ============================================================
local function attack(npc)
    if not npc or not npc.Parent then return end
    local r = getRoot(); if not r then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local hum = npc:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local targetPos = hrp.Position
    -- ТП прямо над НПС на безопасную высоту, смотрим вниз
    local abovePos = Vector3.new(targetPos.X, targetPos.Y + state.safeAttackHeight, targetPos.Z)
    pcall(function() r.CFrame = CFrame.lookAt(abovePos, targetPos) end)

    -- экипируем оружие
    local tool
    if character then
        tool = character:FindFirstChildOfClass("Tool")
        if not tool then
            for _, t in ipairs(character:GetChildren()) do
                if t:IsA("Tool") then tool = t; break end
            end
        end
    end
    if tool and humanoid then pcall(function() humanoid:EquipTool(tool) end) end

    -- клик мышью по НПС
    if VirtualInput and camera then
        local ok, sp, os = pcall(function() return camera:WorldToViewportPoint(targetPos) end)
        if ok and os then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(sp.X, sp.Y, 0, true, game, 1)
                task.wait(0.02)
                VirtualInput:SendMouseButtonEvent(sp.X, sp.Y, 0, false, game, 1)
            end)
        end
    end

    if tool then pcall(function() tool:Activate() end) end

    -- скиллы
    if VirtualInput then
        for _, k in ipairs({"Z","X","C","V"}) do
            pcall(function()
                VirtualInput:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                task.wait(0.02)
                VirtualInput:SendKeyEvent(false, Enum.KeyCode[k], false, game)
            end)
        end
    end
end

local PRIO = {
    { get = function() return state.autoFarmBosses  end, tag = "boss" },
    { get = function() return state.autoFarmMarines end, tag = "marine" },
    { get = function() return state.autoFarmPirates end, tag = "pirate" },
    { get = function() return state.autoFarmLevel   end, tag = "all" },
}
task.spawn(function()
    while true do
        local act = false
        for _, p in ipairs(PRIO) do
            if p.get() then
                act = true
                local n = nearest(p.tag)
                if n then pcall(attack, n) end
                break
            end
        end
        task.wait(act and state.attackSpeed or 0.2)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if state.killAura then
            local r = getRoot()
            if r then
                for _, e in ipairs(npcCache) do
                    local h = e.model:FindFirstChild("HumanoidRootPart")
                    if h and (h.Position - r.Position).Magnitude <= state.killAuraRange then
                        pcall(attack, e.model)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if state.autoChest then
            local o = nearestIn(chestList, 500)
            if o then
                local pp = o:IsA("Model") and (o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Handle") or o.PrimaryPart) or o
                if pp then
                    local r = getRoot()
                    if r then pcall(function() r.CFrame = CFrame.new(pp.Position + Vector3.new(0, 3, 0)) end) end
                    task.wait(0.1)
                end
            end
        end
        if state.autoFruit then
            local o = nearestIn(fruitList, 500)
            if o then
                local pp = o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart) or o
                if pp then
                    local r = getRoot()
                    if r then pcall(function() r.CFrame = CFrame.new(pp.Position + Vector3.new(0, 3, 0)) end) end
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "BinESP"; espFolder.Parent = workspace
local function mkESP(ad, col, txt)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 30); bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true; bb.Adornee = ad; bb.Parent = espFolder
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1
    l.Text = txt; l.TextColor3 = col; l.TextStrokeTransparency = 0
    l.Font = Enum.Font.GothamBold; l.TextSize = 12; l.Parent = bb
    local box = Instance.new("SelectionBox")
    box.Adornee = ad; box.Color3 = col; box.LineThickness = 0.05
    box.Transparency = 0.5; box.Parent = espFolder
    return { bb = bb, box = box, lbl = l, ad = ad }
end
local function killESP(e)
    if e.bb then e.bb:Destroy() end
    if e.box then e.box:Destroy() end
end
local nESP, pESP = {}, {}
task.spawn(function()
    while task.wait(0.5) do
        if state.espNPCs then
            local seen = {}
            for _, e in ipairs(npcCache) do
                local h = e.model:FindFirstChild("HumanoidRootPart")
                if h then
                    seen[e.model] = true
                    local col = e.tag == "boss" and Color3.fromRGB(255, 80, 80)
                             or e.tag == "pirate" and Color3.fromRGB(255, 170, 70)
                             or e.tag == "marine" and Color3.fromRGB(100, 160, 250)
                             or Color3.fromRGB(200, 200, 200)
                    local en = nESP[e.model]
                    if en and en.bb.Parent then
                        if en.ad ~= h then en.bb.Adornee = h; en.box.Adornee = h; en.ad = h end
                        en.lbl.Text = e.model.Name; en.lbl.TextColor3 = col; en.box.Color3 = col
                    else
                        nESP[e.model] = mkESP(h, col, e.model.Name)
                    end
                end
            end
            for m, en in pairs(nESP) do if not seen[m] then killESP(en); nESP[m] = nil end end
        else
            for m, en in pairs(nESP) do killESP(en); nESP[m] = nil end
        end
        if state.espPlayers then
            local seen = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character then
                    local h = pl.Character:FindFirstChild("HumanoidRootPart")
                    if h then
                        seen[pl] = true
                        local en = pESP[pl]
                        if en and en.bb.Parent then
                            if en.ad ~= h then en.bb.Adornee = h; en.box.Adornee = h; en.ad = h end
                        else
                            pESP[pl] = mkESP(h, Color3.fromRGB(85, 225, 145), pl.Name)
                        end
                    end
                end
            end
            for pl, en in pairs(pESP) do if not seen[pl] then killESP(en); pESP[pl] = nil end end
        else
            for pl, en in pairs(pESP) do killESP(en); pESP[pl] = nil end
        end
    end
end)

-- UI
local C = {
    bg=Color3.fromRGB(12,12,20), bg2=Color3.fromRGB(20,20,32),
    surface=Color3.fromRGB(28,28,44), surface2=Color3.fromRGB(40,40,60),
    surface3=Color3.fromRGB(56,56,82), accent=Color3.fromRGB(255,175,75),
    accent2=Color3.fromRGB(255,95,155), accent3=Color3.fromRGB(130,115,255),
    green=Color3.fromRGB(85,225,145), red=Color3.fromRGB(240,85,105),
    blue=Color3.fromRGB(100,160,250), text=Color3.fromRGB(248,248,255),
    sub=Color3.fromRGB(155,155,190), dim=Color3.fromRGB(95,95,125),
}
local sg = Instance.new("ScreenGui")
sg.Name = "BinBloxFruitsV9"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = playerGui
local function tw(o, t, p) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p):Play() end
local function crn(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c end
local function strk(p, c, t, tr)
    local s = Instance.new("UIStroke"); s.Color = c; s.Thickness = t or 1
    s.Transparency = tr or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local nh = Instance.new("Frame")
nh.Size = UDim2.new(0, 300, 1, -40); nh.Position = UDim2.new(1, -320, 0, 20)
nh.BackgroundTransparency = 1; nh.Parent = sg
local nll = Instance.new("UIListLayout", nh)
nll.Padding = UDim.new(0, 8); nll.SortOrder = Enum.SortOrder.LayoutOrder

local function notify(title, text, col)
    col = col or C.accent
    local b = Instance.new("Frame")
    b.Size = UDim2.new(1, 0, 0, 62); b.BackgroundColor3 = C.surface
    b.BackgroundTransparency = 0.08; b.BorderSizePixel = 0; b.Parent = nh
    crn(b, 12); strk(b, col, 1.5, 0.4)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -14); bar.Position = UDim2.new(0, 7, 0, 7)
    bar.BackgroundColor3 = col; bar.BorderSizePixel = 0; bar.Parent = b; crn(bar, 2)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -24, 0, 22); t.Position = UDim2.new(0, 18, 0, 8)
    t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = col
    t.Font = Enum.Font.GothamBold; t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = b
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -24, 0, 22); d.Position = UDim2.new(0, 18, 0, 31)
    d.BackgroundTransparency = 1; d.Text = text; d.TextColor3 = C.sub
    d.Font = Enum.Font.Gotham; d.TextSize = 12
    d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = b
    b.Position = UDim2.new(1, 40, 0, 0)
    tw(b, 0.35, { Position = UDim2.new(0, 0, 0, 0) })
    task.delay(3, function()
        tw(b, 0.35, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
        task.wait(0.4); b:Destroy()
    end)
end

-- Кнопка открытия — слева сверху
local ob = Instance.new("TextButton")
ob.Size = UDim2.new(0, 140, 0, 48); ob.Position = UDim2.new(0, 20, 0, 100)
ob.BackgroundColor3 = C.surface; ob.Text = ""; ob.AutoButtonColor = false
ob.Active = true; ob.Parent = sg; crn(ob, 14); strk(ob, C.accent, 1.5, 0.2)
local oi = Instance.new("TextLabel")
oi.Size = UDim2.new(0, 32, 1, 0); oi.Position = UDim2.new(0, 10, 0, 0)
oi.BackgroundTransparency = 1; oi.Text = "⚡"; oi.TextColor3 = C.accent
oi.Font = Enum.Font.GothamBold; oi.TextSize = 22; oi.Parent = ob
local ot = Instance.new("TextLabel")
ot.Size = UDim2.new(1, -50, 1, 0); ot.Position = UDim2.new(0, 44, 0, 0)
ot.BackgroundTransparency = 1; ot.Text = "BF HUB"
ot.TextColor3 = C.text; ot.Font = Enum.Font.GothamBold; ot.TextSize = 15
ot.TextXAlignment = Enum.TextXAlignment.Left; ot.Parent = ob
ob.MouseEnter:Connect(function() tw(ob, 0.2, { BackgroundColor3 = C.surface2 }) end)
ob.MouseLeave:Connect(function() tw(ob, 0.2, { BackgroundColor3 = C.surface }) end)

-- Главное окно — тоже слева
local WW, WH = 460, 560
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WW, 0, WH)
main.Position = UDim2.new(0, 20, 0.5, -WH/2)
main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0; main.Visible = false
main.Active = true; main.ClipsDescendants = true; main.Parent = sg
crn(main, 16); strk(main, C.accent3, 1.2, 0.55)

local tb = Instance.new("Frame")
tb.Size = UDim2.new(1, 0, 0, 56); tb.BackgroundColor3 = C.surface
tb.BorderSizePixel = 0; tb.Parent = main; crn(tb, 16)
local tbf = Instance.new("Frame", tb)
tbf.Size = UDim2.new(1, 0, 0, 14); tbf.Position = UDim2.new(0, 0, 1, -14)
tbf.BackgroundColor3 = C.surface; tbf.BorderSizePixel = 0

local lg = Instance.new("TextLabel")
lg.Size = UDim2.new(0, 40, 0, 40); lg.Position = UDim2.new(0, 14, 0.5, -20)
lg.BackgroundColor3 = C.surface2; lg.Text = "⚡"; lg.TextColor3 = C.accent
lg.Font = Enum.Font.GothamBold; lg.TextSize = 22; lg.Parent = tb
crn(lg, 10); strk(lg, C.accent, 1, 0.4)

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1, -140, 0, 20); tl.Position = UDim2.new(0, 64, 0, 12)
tl.BackgroundTransparency = 1; tl.Text = "Bin's Blox Fruits"
tl.TextColor3 = C.text; tl.Font = Enum.Font.GothamBold; tl.TextSize = 15
tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Parent = tb
local sl = Instance.new("TextLabel")
sl.Size = UDim2.new(1, -140, 0, 16); sl.Position = UDim2.new(0, 64, 0, 30)
sl.BackgroundTransparency = 1; sl.Text = "v9 · safe attack"
sl.TextColor3 = C.sub; sl.Font = Enum.Font.Gotham; sl.TextSize = 11
sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Parent = tb

local cb = Instance.new("TextButton")
cb.Size = UDim2.new(0, 32, 0, 32); cb.Position = UDim2.new(1, -46, 0.5, -16)
cb.BackgroundColor3 = C.surface2; cb.Text = "✕"; cb.TextColor3 = C.sub
cb.Font = Enum.Font.GothamBold; cb.TextSize = 14; cb.AutoButtonColor = false; cb.Parent = tb
crn(cb, 8)
cb.MouseEnter:Connect(function() tw(cb, 0.15, { BackgroundColor3 = C.red, TextColor3 = Color3.fromRGB(255, 255, 255) }) end)
cb.MouseLeave:Connect(function() tw(cb, 0.15, { BackgroundColor3 = C.surface2, TextColor3 = C.sub }) end)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -32, 0, 40); tabBar.Position = UDim2.new(0, 16, 0, 68)
tabBar.BackgroundColor3 = C.bg2; tabBar.BorderSizePixel = 0; tabBar.Parent = main; crn(tabBar, 12)
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0.25, -6, 1, -8); pill.Position = UDim2.new(0, 4, 0, 4)
pill.BackgroundColor3 = C.accent; pill.BorderSizePixel = 0; pill.ZIndex = 1; pill.Parent = tabBar
crn(pill, 9)

local pages, tabs = {}, {}
local TN = { "farm", "tp", "visual", "misc" }
local TL = { "⚔  FARM", "🌀  TP", "👁  VISUAL", "⚙  MISC" }
local function selTab(name)
    for _, n in ipairs(TN) do if tabs[n] then tabs[n].TextColor3 = (n == name) and C.bg or C.sub end end
    local idx = 1
    for i, n in ipairs(TN) do if n == name then idx = i; break end end
    tw(pill, 0.25, { Position = UDim2.new((idx-1)/#TN, 0, 0, 4) })
    for n, p in pairs(pages) do p.Visible = (n == name) end
    if pages[name] then
        pages[name].Position = UDim2.new(0, 30, 0, 0)
        tw(pages[name], 0.25, { Position = UDim2.new(0, 0, 0, 0) })
    end
end
for i, name in ipairs(TN) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1/#TN, 0, 1, 0); b.Position = UDim2.new((i-1)/#TN, 0, 0, 0)
    b.BackgroundTransparency = 1; b.Text = TL[i]; b.TextColor3 = C.sub
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.ZIndex = 2; b.Parent = tabBar
    b.MouseButton1Click:Connect(function() selTab(name) end)
    tabs[name] = b
end

local ca = Instance.new("Frame")
ca.Size = UDim2.new(1, -32, 1, -180); ca.Position = UDim2.new(0, 16, 0, 120)
ca.BackgroundTransparency = 1; ca.ClipsDescendants = true; ca.Parent = main
for _, name in ipairs(TN) do
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1
    p.BorderSizePixel = 0; p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = C.accent; p.ScrollBarImageTransparency = 0.3
    p.CanvasSize = UDim2.new(0, 0, 0, 0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false; p.Parent = ca
    local lay = Instance.new("UIListLayout", p)
    lay.Padding = UDim.new(0, 8); lay.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", p); pad.PaddingRight = UDim.new(0, 8)
    pages[name] = p
end
selTab("farm")

local ordr = 0
local function no() ordr = ordr + 1; return ordr end

local function section(parent, title)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 24); f.BackgroundTransparency = 1
    f.LayoutOrder = no(); f.Parent = parent
    local d = Instance.new("Frame")
    d.Size = UDim2.new(0, 6, 0, 6); d.Position = UDim2.new(0, 2, 0.5, -3)
    d.BackgroundColor3 = C.accent; d.BorderSizePixel = 0; d.Parent = f; crn(d, 3)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0); l.Position = UDim2.new(0, 16, 0, 0)
    l.BackgroundTransparency = 1; l.Text = title; l.TextColor3 = C.accent
    l.Font = Enum.Font.GothamBold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
end

local function toggle(parent, name, desc, get, set)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 56); c.BackgroundColor3 = C.surface
    c.BorderSizePixel = 0; c.LayoutOrder = no(); c.Parent = parent
    crn(c, 10); strk(c, C.surface3, 1, 0.5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -110, 0, 20); l.Position = UDim2.new(0, 16, 0, 10)
    l.BackgroundTransparency = 1; l.Text = name; l.TextColor3 = C.text
    l.Font = Enum.Font.GothamBold; l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -110, 0, 16); d.Position = UDim2.new(0, 16, 0, 30)
        d.BackgroundTransparency = 1; d.Text = desc; d.TextColor3 = C.sub
        d.Font = Enum.Font.Gotham; d.TextSize = 11
        d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = c
    end
    local tr = Instance.new("Frame")
    tr.Size = UDim2.new(0, 46, 0, 24); tr.Position = UDim2.new(1, -60, 0.5, -12)
    tr.BackgroundColor3 = C.surface3; tr.BorderSizePixel = 0; tr.Parent = c; crn(tr, 12)
    local k = Instance.new("Frame")
    k.Size = UDim2.new(0, 18, 0, 18); k.Position = UDim2.new(0, 3, 0.5, -9)
    k.BackgroundColor3 = C.sub; k.BorderSizePixel = 0; k.Parent = tr; crn(k, 9)
    local hb = Instance.new("TextButton")
    hb.Size = UDim2.new(1, 0, 1, 0); hb.BackgroundTransparency = 1; hb.Text = ""; hb.Parent = c
    local function rf(a)
        local v = get()
        local i = TweenInfo.new(a and 0.2 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(tr, i, { BackgroundColor3 = v and C.green or C.surface3 }):Play()
        TweenService:Create(k, i, {
            Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = v and Color3.fromRGB(255, 255, 255) or C.sub,
        }):Play()
    end
    rf(false)
    hb.MouseButton1Click:Connect(function() set(not get()); rf(true) end)
end

local function slider(parent, name, mn, mx, st, get, set, suf)
    suf = suf or ""
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 76); c.BackgroundColor3 = C.surface
    c.BorderSizePixel = 0; c.LayoutOrder = no(); c.Parent = parent
    crn(c, 10); strk(c, C.surface3, 1, 0.5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -100, 0, 20); l.Position = UDim2.new(0, 16, 0, 10)
    l.BackgroundTransparency = 1; l.Text = name; l.TextColor3 = C.text
    l.Font = Enum.Font.GothamBold; l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 90, 0, 20); vl.Position = UDim2.new(1, -106, 0, 10)
    vl.BackgroundTransparency = 1
    vl.Text = string.format("%.2f", get()) .. suf
    vl.TextColor3 = C.accent; vl.Font = Enum.Font.GothamBold; vl.TextSize = 13
    vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = c
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -32, 0, 8); bg.Position = UDim2.new(0, 16, 0, 42)
    bg.BackgroundColor3 = C.surface3; bg.BorderSizePixel = 0; bg.Parent = c; crn(bg, 4)
    local fl = Instance.new("Frame")
    fl.Size = UDim2.new((get()-mn)/(mx-mn), 0, 1, 0)
    fl.BackgroundColor3 = C.accent; fl.BorderSizePixel = 0; fl.Parent = bg; crn(fl, 4)
    local mi = Instance.new("TextButton")
    mi.Size = UDim2.new(0, 36, 0, 22); mi.Position = UDim2.new(0, 16, 1, -30)
    mi.BackgroundColor3 = C.surface2; mi.Text = "−"; mi.TextColor3 = C.text
    mi.Font = Enum.Font.GothamBold; mi.TextSize = 14; mi.AutoButtonColor = false; mi.Parent = c; crn(mi, 6)
    local pl = Instance.new("TextButton")
    pl.Size = UDim2.new(0, 36, 0, 22); pl.Position = UDim2.new(1, -52, 1, -30)
    pl.BackgroundColor3 = C.accent; pl.Text = "+"; pl.TextColor3 = C.bg
    pl.Font = Enum.Font.GothamBold; pl.TextSize = 14; pl.AutoButtonColor = false; pl.Parent = c; crn(pl, 6)
    local function up(v)
        v = math.clamp(v, mn, mx); set(v)
        vl.Text = string.format("%.2f", v) .. suf
        tw(fl, 0.15, { Size = UDim2.new((v-mn)/(mx-mn), 0, 1, 0) })
    end
    mi.MouseButton1Click:Connect(function() up(get() - st) end)
    pl.MouseButton1Click:Connect(function() up(get() + st) end)
end

local function action(parent, text, cb2, col)
    col = col or C.accent
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 44); b.BackgroundColor3 = col
    b.Text = text; b.TextColor3 = C.bg; b.Font = Enum.Font.GothamBold
    b.TextSize = 13; b.AutoButtonColor = false; b.LayoutOrder = no(); b.Parent = parent
    crn(b, 10)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb2)
        if not ok then
            warn("[BF Hub] " .. tostring(err))
            notify("Error", tostring(err), C.red)
        end
    end)
end

local function input(parent, ph, cb2, bt)
    bt = bt or "OK"
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 44); c.BackgroundColor3 = C.surface
    c.BorderSizePixel = 0; c.LayoutOrder = no(); c.Parent = parent
    crn(c, 10); strk(c, C.surface3, 1, 0.5)
    local bx = Instance.new("TextBox")
    bx.Size = UDim2.new(0.65, -12, 1, -10); bx.Position = UDim2.new(0, 12, 0, 5)
    bx.BackgroundColor3 = C.surface2; bx.Text = ""; bx.PlaceholderText = ph
    bx.PlaceholderColor3 = C.dim; bx.TextColor3 = C.text
    bx.Font = Enum.Font.Gotham; bx.TextSize = 12; bx.ClearTextOnFocus = false; bx.Parent = c
    crn(bx, 6)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, -12, 1, -10); btn.Position = UDim2.new(0.65, 6, 0, 5)
    btn.BackgroundColor3 = C.accent; btn.Text = bt; btn.TextColor3 = C.bg
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    btn.AutoButtonColor = false; btn.Parent = c; crn(btn, 6)
    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function() cb2(bx.Text) end)
        if not ok then notify("Error", tostring(err), C.red) end
    end)
end

-- FARM
section(pages.farm, "FARMING")
toggle(pages.farm, "Auto Farm Level", "Attack any nearby NPC",
    function() return state.autoFarmLevel end, function(v) state.autoFarmLevel = v end)
toggle(pages.farm, "Auto Farm Pirates", "Prioritize pirate NPCs",
    function() return state.autoFarmPirates end, function(v) state.autoFarmPirates = v end)
toggle(pages.farm, "Auto Farm Marines", "Prioritize marine NPCs",
    function() return state.autoFarmMarines end, function(v) state.autoFarmMarines = v end)
toggle(pages.farm, "Auto Farm Bosses", "Prioritize boss NPCs",
    function() return state.autoFarmBosses end, function(v) state.autoFarmBosses = v end)

section(pages.farm, "COMBAT")
slider(pages.farm, "Attack Speed", 0.1, 2.0, 0.05,
    function() return state.attackSpeed end, function(v) state.attackSpeed = v end, "s")
slider(pages.farm, "Safe Attack Height", 5, 30, 1,
    function() return state.safeAttackHeight end, function(v) state.safeAttackHeight = v end, " studs")
toggle(pages.farm, "Kill Aura", "Attack NPCs within range",
    function() return state.killAura end, function(v) state.killAura = v end)
slider(pages.farm, "Kill Aura Range", 10, 200, 5,
    function() return state.killAuraRange end, function(v) state.killAuraRange = v end, " studs")

section(pages.farm, "AUTO COLLECT")
toggle(pages.farm, "Auto Chest", "TP to nearby chests",
    function() return state.autoChest end, function(v) state.autoChest = v end)
toggle(pages.farm, "Auto Fruit", "TP to nearby fruits",
    function() return state.autoFruit end, function(v) state.autoFruit = v end)

section(pages.farm, "STATUS")
local sc = Instance.new("Frame")
sc.Size = UDim2.new(1, 0, 0, 130); sc.BackgroundColor3 = C.surface
sc.BorderSizePixel = 0; sc.LayoutOrder = no(); sc.Parent = pages.farm
crn(sc, 10); strk(sc, C.surface3, 1, 0.5)
local ncL = Instance.new("TextLabel")
ncL.Size = UDim2.new(1, -40, 0, 20); ncL.Position = UDim2.new(0, 16, 0, 10)
ncL.BackgroundTransparency = 1; ncL.Text = "NPCs: 0"; ncL.TextColor3 = C.text
ncL.Font = Enum.Font.Gotham; ncL.TextSize = 12
ncL.TextXAlignment = Enum.TextXAlignment.Left; ncL.Parent = sc
local hpL = Instance.new("TextLabel")
hpL.Size = UDim2.new(1, -40, 0, 20); hpL.Position = UDim2.new(0, 16, 0, 30)
hpL.BackgroundTransparency = 1; hpL.Text = "HP: -"; hpL.TextColor3 = C.sub
hpL.Font = Enum.Font.Gotham; hpL.TextSize = 12
hpL.TextXAlignment = Enum.TextXAlignment.Left; hpL.Parent = sc
local hbBg = Instance.new("Frame")
hbBg.Size = UDim2.new(1, -32, 0, 6); hbBg.Position = UDim2.new(0, 16, 0, 54)
hbBg.BackgroundColor3 = C.surface3; hbBg.BorderSizePixel = 0; hbBg.Parent = sc; crn(hbBg, 3)
local hbF = Instance.new("Frame")
hbF.Size = UDim2.new(1, 0, 1, 0); hbF.BackgroundColor3 = C.green
hbF.BorderSizePixel = 0; hbF.Parent = hbBg; crn(hbF, 3)
local pL = Instance.new("TextLabel")
pL.Size = UDim2.new(1, -40, 0, 20); pL.Position = UDim2.new(0, 16, 0, 70)
pL.BackgroundTransparency = 1; pL.Text = "Pos: -"; pL.TextColor3 = C.sub
pL.Font = Enum.Font.Gotham; pL.TextSize = 11
pL.TextXAlignment = Enum.TextXAlignment.Left; pL.Parent = sc
local sd = Instance.new("Frame")
sd.Size = UDim2.new(0, 8, 0, 8); sd.Position = UDim2.new(1, -22, 0, 16)
sd.BackgroundColor3 = C.red; sd.BorderSizePixel = 0; sd.Parent = sc; crn(sd, 4)
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            ncL.Text = "NPCs: " .. tostring(#npcCache)
            local r = getRoot()
            if humanoid and humanoid.Parent and r then
                hpL.Text = string.format("HP: %d / %d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
                local rt = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                hbF.Size = UDim2.new(rt, 0, 1, 0)
                hbF.BackgroundColor3 = rt > 0.5 and C.green or (rt > 0.25 and C.accent or C.red)
                pL.Text = string.format("Pos: %.0f, %.0f, %.0f", r.Position.X, r.Position.Y, r.Position.Z)
            end
            local act = state.autoFarmLevel or state.autoFarmPirates
                     or state.autoFarmMarines or state.autoFarmBosses or state.killAura
            sd.BackgroundColor3 = act and C.green or C.red
        end)
    end
end)

-- TP PAGE
section(pages.tp, "SEARCH")
local sf = Instance.new("Frame")
sf.Size = UDim2.new(1, 0, 0, 38); sf.BackgroundColor3 = C.surface
sf.BorderSizePixel = 0; sf.LayoutOrder = no(); sf.Parent = pages.tp
crn(sf, 10); strk(sf, C.surface3, 1, 0.5)
local sb = Instance.new("TextBox")
sb.Size = UDim2.new(1, -32, 1, -8); sb.Position = UDim2.new(0, 16, 0, 4)
sb.BackgroundTransparency = 1; sb.Text = ""; sb.PlaceholderText = "🔍  Search..."
sb.PlaceholderColor3 = C.dim; sb.TextColor3 = C.text
sb.Font = Enum.Font.Gotham; sb.TextSize = 12
sb.TextXAlignment = Enum.TextXAlignment.Left; sb.ClearTextOnFocus = false; sb.Parent = sf

local lc = Instance.new("Frame")
lc.Size = UDim2.new(1, 0, 0, 240); lc.BackgroundColor3 = C.surface
lc.BorderSizePixel = 0; lc.LayoutOrder = no(); lc.Parent = pages.tp
crn(lc, 10); strk(lc, C.surface3, 1, 0.5)
local ll = Instance.new("ScrollingFrame")
ll.Size = UDim2.new(1, -16, 1, -16); ll.Position = UDim2.new(0, 8, 0, 8)
ll.BackgroundTransparency = 1; ll.BorderSizePixel = 0
ll.ScrollBarThickness = 4; ll.ScrollBarImageColor3 = C.accent3
ll.CanvasSize = UDim2.new(0, 0, 0, 0); ll.AutomaticCanvasSize = Enum.AutomaticSize.Y; ll.Parent = lc
local lll = Instance.new("UIListLayout", ll)
lll.Padding = UDim.new(0, 5); lll.SortOrder = Enum.SortOrder.LayoutOrder
local lb = {}
local function selLoc(name)
    state.selectedTP = name
    for n, b in pairs(lb) do
        local a = (n == name)
        tw(b, 0.15, {
            BackgroundColor3 = a and C.accent3 or C.surface2,
            TextColor3 = a and Color3.fromRGB(255, 255, 255) or C.text,
        })
    end
end
local function rebuildLoc(f)
    for _, c in ipairs(ll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    lb = {}; f = (f or ""):lower()
    for _, l in ipairs(TP_LOCATIONS) do
        if f == "" or l.name:lower():find(f, 1, true) then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -6, 0, 34); b.BackgroundColor3 = C.surface2
            b.Text = "  " .. l.icon .. "  " .. l.name .. "   [Sea " .. l.sea .. "]"
            b.TextColor3 = C.text; b.Font = Enum.Font.Gotham; b.TextSize = 12
            b.TextXAlignment = Enum.TextXAlignment.Left; b.AutoButtonColor = false; b.Parent = ll
            crn(b, 8)
            b.MouseEnter:Connect(function()
                if state.selectedTP ~= l.name then tw(b, 0.15, { BackgroundColor3 = C.surface3 }) end
            end)
            b.MouseLeave:Connect(function()
                if state.selectedTP ~= l.name then tw(b, 0.15, { BackgroundColor3 = C.surface2 }) end
            end)
            b.MouseButton1Click:Connect(function() selLoc(l.name) end)
            lb[l.name] = b
        end
    end
    selLoc(state.selectedTP)
end
rebuildLoc("")
sb:GetPropertyChangedSignal("Text"):Connect(function() rebuildLoc(sb.Text) end)

section(pages.tp, "ACTIONS")
action(pages.tp, "✨  Teleport Now (precise)", function()
    local l = findLoc(state.selectedTP)
    if l then tpTo(l.pos); notify("Teleport", "Warped to " .. l.name, C.accent3) end
end, C.accent3)
action(pages.tp, "🏴‍☠️  TP to Nearest Pirate", function()
    local n = nearest("pirate")
    if n then tpToNPC(n); notify("Pirate", "Found: " .. n.Name, C.accent2)
    else notify("Pirate", "No pirates nearby", C.red) end
end, C.accent2)
action(pages.tp, "⚓  TP to Nearest Marine", function()
    local n = nearest("marine")
    if n then tpToNPC(n); notify("Marine", "Found: " .. n.Name, C.blue)
    else notify("Marine", "No marines nearby", C.red) end
end, C.blue)
action(pages.tp, "👑  TP to Nearest Boss", function()
    local n = nearest("boss")
    if n then tpToNPC(n); notify("Boss", "Found: " .. n.Name, C.red)
    else notify("Boss", "No bosses nearby", C.red) end
end, C.red)

section(pages.tp, "WAYPOINTS")
input(pages.tp, "New waypoint name...", function(name)
    if name and name ~= "" then
        saveWP(name); notify("Waypoint", "Saved: " .. name, C.green); rebuildWP()
    end
end, "SAVE")

local wc = Instance.new("Frame")
wc.Size = UDim2.new(1, 0, 0, 200); wc.BackgroundColor3 = C.surface
wc.BorderSizePixel = 0; wc.LayoutOrder = no(); wc.Parent = pages.tp
crn(wc, 10); strk(wc, C.surface3, 1, 0.5)
local wl = Instance.new("ScrollingFrame")
wl.Size = UDim2.new(1, -16, 1, -16); wl.Position = UDim2.new(0, 8, 0, 8)
wl.BackgroundTransparency = 1; wl.BorderSizePixel = 0
wl.ScrollBarThickness = 4; wl.ScrollBarImageColor3 = C.accent3
wl.CanvasSize = UDim2.new(0, 0, 0, 0); wl.AutomaticCanvasSize = Enum.AutomaticSize.Y; wl.Parent = wc
local wll = Instance.new("UIListLayout", wl)
wll.Padding = UDim.new(0, 5); wll.SortOrder = Enum.SortOrder.LayoutOrder
local wEmpty = Instance.new("TextLabel")
wEmpty.Size = UDim2.new(1, -20, 0, 30); wEmpty.Position = UDim2.new(0, 10, 0, 10)
wEmpty.BackgroundTransparency = 1; wEmpty.Text = "No waypoints yet, ня~"
wEmpty.TextColor3 = C.dim; wEmpty.Font = Enum.Font.Gotham; wEmpty.TextSize = 12
wEmpty.TextXAlignment = Enum.TextXAlignment.Left; wEmpty.Parent = wl
function rebuildWP()
    for _, c in ipairs(wl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if #wpOrder == 0 then wEmpty.Visible = true; return end
    wEmpty.Visible = false
    for _, name in ipairs(wpOrder) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 34); row.BackgroundColor3 = C.surface2
        row.BorderSizePixel = 0; row.Parent = wl; crn(row, 8)
        local tb2 = Instance.new("TextButton")
        tb2.Size = UDim2.new(1, -46, 1, 0); tb2.BackgroundTransparency = 1
        tb2.Text = "  📍  " .. name; tb2.TextColor3 = C.text
        tb2.Font = Enum.Font.Gotham; tb2.TextSize = 12
        tb2.TextXAlignment = Enum.TextXAlignment.Left; tb2.AutoButtonColor = false; tb2.Parent = row
        tb2.MouseButton1Click:Connect(function()
            local p = WAYPOINTS[name]
            if p then tpTo(p); notify("Waypoint", "Warped to: " .. name, C.green) end
        end)
        local db = Instance.new("TextButton")
        db.Size = UDim2.new(0, 30, 1, -8); db.Position = UDim2.new(1, -38, 0, 4)
        db.BackgroundColor3 = C.surface3; db.Text = "✕"; db.TextColor3 = C.red
        db.Font = Enum.Font.GothamBold; db.TextSize = 12
        db.AutoButtonColor = false; db.Parent = row; crn(db, 6)
        db.MouseButton1Click:Connect(function()
            delWP(name); rebuildWP(); notify("Waypoint", "Deleted: " .. name, C.red)
        end)
    end
end
rebuildWP()

-- VISUAL
section(pages.visual, "ESP")
toggle(pages.visual, "ESP NPCs", "Boxes over enemies",
    function() return state.espNPCs end, function(v) state.espNPCs = v end)
toggle(pages.visual, "ESP Players", "Boxes over players",
    function() return state.espPlayers end, function(v) state.espPlayers = v end)

-- MISC
section(pages.misc, "INFO")
local ic = Instance.new("Frame")
ic.Size = UDim2.new(1, 0, 0, 130); ic.BackgroundColor3 = C.surface
ic.BorderSizePixel = 0; ic.LayoutOrder = no(); ic.Parent = pages.misc
crn(ic, 10); strk(ic, C.surface3, 1, 0.5)
local it = Instance.new("TextLabel")
it.Size = UDim2.new(1, -20, 1, -16); it.Position = UDim2.new(0, 16, 0, 8)
it.BackgroundTransparency = 1
it.Text = "Bin's Blox Fruits Hub v9\nsafe attack\n\nmade by Bin & Steve\nnya~"
it.TextColor3 = C.sub; it.Font = Enum.Font.Gotham; it.TextSize = 12
it.TextXAlignment = Enum.TextXAlignment.Left
it.TextYAlignment = Enum.TextYAlignment.Top; it.Parent = ic
action(pages.misc, "🔄  Refresh NPC Cache", function()
    refresh(); notify("Cache", "Refreshed · " .. #npcCache .. " NPCs", C.green)
end, C.surface2)

-- FOOTER
local ft = Instance.new("Frame")
ft.Size = UDim2.new(1, -32, 0, 32); ft.Position = UDim2.new(0, 16, 1, -44)
ft.BackgroundColor3 = C.bg2; ft.BorderSizePixel = 0; ft.Parent = main; crn(ft, 10)
local ftL = Instance.new("TextLabel")
ftL.Size = UDim2.new(1, -20, 1, 0); ftL.Position = UDim2.new(0, 12, 0, 0)
ftL.BackgroundTransparency = 1; ftL.Text = "made by Bin & Steve  ·  nya~"
ftL.TextColor3 = C.dim; ftL.Font = Enum.Font.Gotham; ftL.TextSize = 11
ftL.TextXAlignment = Enum.TextXAlignment.Left; ftL.Parent = ft

-- TOGGLE / DRAG
local isOpen = false
local function tglW()
    isOpen = not isOpen
    if isOpen then
        main.Visible = true
        main.Size = UDim2.new(0, WW*0.85, 0, WH*0.85)
        main.BackgroundTransparency = 0.3
        tw(main, 0.3, { Size = UDim2.new(0, WW, 0, WH), BackgroundTransparency = 0 })
    else
        tw(main, 0.2, { Size = UDim2.new(0, WW*0.85, 0, WH*0.85), BackgroundTransparency = 0.4 })
        task.wait(0.2)
        main.Visible = false
        main.Size = UDim2.new(0, WW, 0, WH); main.BackgroundTransparency = 0
    end
end
ob.MouseButton1Click:Connect(tglW)
cb.MouseButton1Click:Connect(tglW)

do
    local drag, ds, sp
    local function beg(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = main.Position
        end
    end
    local function en(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end
    local function mv(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end
    tb.InputBegan:Connect(beg); tb.InputEnded:Connect(en); UserInput.InputChanged:Connect(mv)
    ob.InputBegan:Connect(beg); ob.InputEnded:Connect(en)
end

notify("Bin's Hub v9", "Loaded · click ⚡ BF HUB", C.accent)
print("[Bin's Hub v9] loaded. Safe attack + left UI.")
