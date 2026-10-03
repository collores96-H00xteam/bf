-- Bin's Blox Fruits Hub v19 BETA — QUESTS + FIXED CHEST/FRUIT
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
        rp.IgnoreWater = false
        return workspace:Raycast(Vector3.new(x, y or 500, z), Vector3.new(0, -1000, 0), rp)
    end)
    if ok and res then return res.Position.Y end
    return nil
end

local function tpTo(pos)
    local r = getRoot(); if not r then return end
    local gy = groundY(pos.X, pos.Z, pos.Y + 500)
    if not gy then gy = groundY(pos.X, pos.Z, 1000) end
    if not gy then gy = pos.Y end
    pcall(function() r.CFrame = CFrame.new(pos.X, gy + 3.5, pos.Z) end)
end

local function tpToObject(obj)
    if not obj then return end
    local pp = obj:IsA("Model") and (obj:FindFirstChild("Handle") or obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart) or obj
    if not pp then return end
    tpTo(pp.Position)
end

-- ============================================================
-- REMOTES
-- ============================================================
local function getCommF()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then return nil end
    return r:FindFirstChild("CommF_")
end

-- ============================================================
-- STATE
-- ============================================================
local state = {
    autoFarmLevel=false, autoFarmPirates=false, autoFarmMarines=false, autoFarmBosses=false,
    attackSpeed=0.25, killAura=false, killAuraRange=45,
    hoverHeight=6,
    selectedTP="Pirate Island", espNPCs=false, espPlayers=false,
    autoChest=false, autoFruit=false, lockCamera=true,
    autoFish=false, selectedFruit="Dragon",
    fly=false, flySpeed=120,
    autoStat=false, selectedStat="Melee",
    autoFruitMastery=false, masteryFruit="Dragon",
    chestRange=1500,
    autoQuest=false, selectedQuest="Bandit", questLevel=1,
}

-- ============================================================
-- AUTO STAT
-- ============================================================
local STAT_NAMES = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}

local function allocateStat(statName)
    local remotes = getCommF()
    if not remotes then return false end
    local ok = pcall(function() remotes:InvokeServer("AddPoint", statName, 1) end)
    return ok
end

-- ============================================================
-- HITBOX 30x30x30
-- ============================================================
local HITBOX_SIZE = 30
local origHRP = setmetatable({}, {__mode="k"})

local function applyHitbox(npc)
    if not npc then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not origHRP[hrp] then
        origHRP[hrp] = { size=hrp.Size, trans=hrp.Transparency, coll=hrp.CanCollide, mass=hrp.Massless }
    end
    pcall(function()
        hrp.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
        hrp.Transparency = 1
        hrp.CanCollide = false
        hrp.Massless = true
        hrp.CanQuery = true
        hrp.CanTouch = true
    end)
end

local function restoreHitbox(npc)
    if not npc then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local o = origHRP[hrp]
    if o then
        pcall(function()
            hrp.Size = o.size; hrp.Transparency = o.trans
            hrp.CanCollide = o.coll; hrp.Massless = o.mass
        end)
        origHRP[hrp] = nil
    end
end

-- ============================================================
-- HOVER
-- ============================================================
local hoverTarget, hoverActive = nil, false
local function setHover(npc)
    if hoverActive and hoverTarget and hoverTarget ~= npc then restoreHitbox(hoverTarget) end
    hoverTarget = npc
    hoverActive = npc ~= nil
    if humanoid then pcall(function() humanoid.PlatformStand = hoverActive end) end
    if hoverActive and npc then applyHitbox(npc) end
end

RunService.Heartbeat:Connect(function()
    if not (hoverActive and hoverTarget and hoverTarget.Parent) then return end
    if state.fly then return end
    local r = getRoot()
    local hrp = hoverTarget:FindFirstChild("HumanoidRootPart")
    local hum = hoverTarget:FindFirstChild("Humanoid")
    if not (r and hrp and hum and hum.Health > 0) then
        restoreHitbox(hoverTarget)
        hoverActive = false; hoverTarget = nil
        if humanoid then pcall(function() humanoid.PlatformStand = false end) end
        return
    end
    local target = hrp.Position
    local above = Vector3.new(target.X, target.Y + state.hoverHeight, target.Z)
    pcall(function() r.CFrame = CFrame.lookAt(above, target) end)
    pcall(function() r.Velocity = Vector3.new(0,0,0) end)
    if state.lockCamera and camera then
        pcall(function() camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target) end)
    end
end)

-- ============================================================
-- FLY
-- ============================================================
local flyConn = nil
local function startFly()
    local r = getRoot(); if not r or not humanoid then return end
    pcall(function() humanoid.PlatformStand = true end)
    pcall(function() humanoid.WalkSpeed = 0 end)
    pcall(function() humanoid.JumpPower = 0 end)
    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not state.fly then return end
        local rr = getRoot(); if not rr then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local move = Vector3.new(0,0,0)
        if UserInput:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit * state.flySpeed * dt end
        pcall(function() rr.CFrame = rr.CFrame + move; rr.Velocity = Vector3.new(0,0,0) end)
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if humanoid then
        pcall(function()
            humanoid.PlatformStand = false
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end)
    end
end
task.spawn(function()
    local last = false
    while task.wait(0.1) do
        if state.fly and not last then startFly() end
        if not state.fly and last then stopFly() end
        last = state.fly
    end
end)

-- AUTO STAT loop
task.spawn(function()
    while task.wait(0.5) do
        if state.autoStat then pcall(function() allocateStat(state.selectedStat) end) end
    end
end)

-- ============================================================
-- TP LOCATIONS
-- ============================================================
local TP_LOCATIONS = {
    { name="Bandit Camp", icon="🏕️", pos=Vector3.new(-1110,20,3200), sea=1 },
    { name="Pirate Village", icon="🏘️", pos=Vector3.new(-1200,20,3400), sea=1 },
    { name="Marine Fort", icon="🛡️", pos=Vector3.new(-2800,20,4300), sea=1 },
    { name="Jungle", icon="🌴", pos=Vector3.new(-1600,20,200), sea=1 },
    { name="Marine Ford", icon="⚓", pos=Vector3.new(-2760,20,4320), sea=1 },
    { name="Fountain City", icon="⛲", pos=Vector3.new(-1250,20,3200), sea=1 },
    { name="Pirate Island", icon="🏴‍☠️", pos=Vector3.new(1000,20,1200), sea=1 },
    { name="First Sea Port", icon="🚢", pos=Vector3.new(400,20,400), sea=1 },
    { name="Colosseum", icon="🏛️", pos=Vector3.new(-1500,20,200), sea=1 },
    { name="Desert", icon="🏜️", pos=Vector3.new(1000,20,4500), sea=1 },
    { name="Snow Island", icon="❄️", pos=Vector3.new(1250,20,-1500), sea=1 },
    { name="Skylands", icon="☁️", pos=Vector3.new(-500,800,-1500), sea=1 },
    { name="Prison", icon="🔒", pos=Vector3.new(5000,20,800), sea=1 },
    { name="Kingdom of Rose", icon="🌹", pos=Vector3.new(-400,20,6000), sea=2 },
    { name="Green Zone", icon="🌿", pos=Vector3.new(-3500,20,-4500), sea=2 },
    { name="Graveyard", icon="⚰️", pos=Vector3.new(-5500,20,-3000), sea=2 },
    { name="Snow Mountain", icon="🏔️", pos=Vector3.new(-1500,20,-5500), sea=2 },
    { name="Cursed Ship", icon="👻", pos=Vector3.new(9000,20,5000), sea=2 },
    { name="Ice Castle", icon="🏰", pos=Vector3.new(-6000,20,-6000), sea=2 },
    { name="Forgotten Island", icon="🗿", pos=Vector3.new(-3000,20,-8000), sea=2 },
    { name="Port Town", icon="⛵", pos=Vector3.new(-500,20,-10000), sea=3 },
    { name="Hydra Island", icon="🐉", pos=Vector3.new(5000,20,-9000), sea=3 },
    { name="Great Tree", icon="🌳", pos=Vector3.new(-3000,20,-12000), sea=3 },
    { name="Floating Turtle", icon="🐢", pos=Vector3.new(-9000,20,-10000), sea=3 },
    { name="Haunted Castle", icon="🏚️", pos=Vector3.new(3000,20,-12000), sea=3 },
    { name="Castle on the Sea", icon="🏰", pos=Vector3.new(-6000,20,-14000), sea=3 },
    { name="Sea of Treats", icon="🍭", pos=Vector3.new(5000,20,-15000), sea=3 },
}
local function findLoc(n) for _,l in ipairs(TP_LOCATIONS) do if l.name==n then return l end end end

-- ============================================================
-- QUESTS (Quest Givers)
-- ============================================================
local QUESTS = {
    -- Sea 1
    { name="Bandit",           level=1,   pos=Vector3.new(-1143,20,3140),   npc="Bandit" },
    { name="Monkey",           level=15,  pos=Vector3.new(-1594,20,200),    npc="Monkey" },
    { name="Blade Master",     level=25,  pos=Vector3.new(-1449,20,127),    npc="Blade Master" },
    { name="Brute",            level=40,  pos=Vector3.new(-1140,20,1520),   npc="Brute" },
    { name="Pirate",           level=60,  pos=Vector3.new(-1200,20,3400),   npc="Pirate" },
    { name="Marine",           level=90,  pos=Vector3.new(-2800,20,4300),   npc="Marine" },
    { name="Snow Bandit",      level=120, pos=Vector3.new(1250,20,-1500),   npc="Snow Bandit" },
    { name="Snowman",          level=140, pos=Vector3.new(1300,20,-1600),   npc="Snowman" },
    { name="Frost Brigand",    level=160, pos=Vector3.new(1400,20,-1400),   npc="Frost Brigand" },
    { name="Sky Bandit",       level=180, pos=Vector3.new(-500,800,-1500),  npc="Sky Bandit" },
    -- Sea 2
    { name="Raider",           level=375, pos=Vector3.new(-400,20,6000),    npc="Raider" },
    { name="Mercenary",        level=450, pos=Vector3.new(-3600,20,-4500),  npc="Mercenary" },
    { name="Zombie",           level=550, pos=Vector3.new(-5500,20,-3000),  npc="Zombie" },
    -- Sea 3
    { name="Pirate Captain",   level=1000,pos=Vector3.new(-500,20,-10000),  npc="Pirate Captain" },
    { name="Hydra",            level=1100,pos=Vector3.new(5000,20,-9000),   npc="Hydra" },
}

local function startQuest(questName, level)
    local remotes = getCommF()
    if not remotes then return false end
    local ok = pcall(function()
        remotes:InvokeServer("StartQuest", questName, level)
    end)
    return ok
end

local function findQuest(name)
    for _, q in ipairs(QUESTS) do if q.name == name then return q end end
end

-- ============================================================
-- FRUITS
-- ============================================================
local FRUITS = {
    "Dragon","Leopard","Kitsune","Dough","Venom","Shadow","Control",
    "Spirit","Mammoth","T-Rex","Gas","Portal","Buddha","Phoenix",
    "Gravity","Rumble","Magma","Ice","Light","Dark","Rubber",
    "Sand","Diamond","Barrier","Door","Chop","Spring","Bomb",
    "Spike","Flame","Falcon","Blade","Ghost","Rocket","Spin",
    "Smoke","Revive","Love","Spider","Sound","Creation","Pain","Blizzard",
}

local function findFruit(name)
    if not name or name=="" then return nil end
    local key = name:lower()
    local best, bd = nil, math.huge
    local r = getRoot(); if not r then return nil end
    local myPos = r.Position
    local ok, descs = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for _, o in ipairs(descs) do
        if (o:IsA("Tool") or o:IsA("Model") or o:IsA("BasePart")) then
            local on = o.Name:lower()
            if on:find(key, 1, true) then
                local pp = o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart) or o
                if pp and pp.Position then
                    local d = (pp.Position - myPos).Magnitude
                    if d < bd then bd = d; best = o end
                end
            end
        end
    end
    return best
end

-- ============================================================
-- NPC CACHE
-- ============================================================
local npcCache = {}
local KW = {
    pirate={"Pirate","Bandit","Brute","Thief","Criminal","Rogue","Buccaneer","Smoker","Clown","Raider","Mercenary","Zombie"},
    marine={"Marine","Soldier","Officer","Captain","Vice","Commander","Guard","Sword"},
    boss={"Boss","Lord","King","Queen","Admiral","Warden","Diamond","Cyborg"},
}
local function matchKw(n,l) for _,k in ipairs(l) do if n:find(k) then return true end end return false end
local function scan(c,out)
    if not c then return end
    local ok,ch=pcall(function() return c:GetChildren() end); if not ok then return end
    for _,o in ipairs(ch) do
        if o:IsA("Model") and o:FindFirstChild("Humanoid") and o:FindFirstChild("HumanoidRootPart")
           and not Players:GetPlayerFromCharacter(o) then
            local h=o.Humanoid
            if h and h.Health>0 then
                local t="other"
                if matchKw(o.Name,KW.boss) then t="boss"
                elseif matchKw(o.Name,KW.pirate) then t="pirate"
                elseif matchKw(o.Name,KW.marine) then t="marine" end
                table.insert(out,{model=o,tag=t})
            end
        end
    end
end
local function refresh()
    local nc={}
    local ef=workspace:FindFirstChild("Enemies"); if ef then scan(ef,nc) end
    if #nc==0 then scan(workspace,nc) end
    npcCache=nc
end
task.spawn(function() while task.wait(1) do pcall(refresh) end end)

local function nearest(tag)
    local r=getRoot(); if not r then return nil end
    local p=r.Position; local best,bd=nil,math.huge
    for _,e in ipairs(npcCache) do
        if tag=="all" or e.tag==tag then
            local hrp=e.model:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d=(hrp.Position-p).Magnitude
                if d<bd then bd=d; best=e.model end
            end
        end
    end
    return best
end

-- ============================================================
-- ATTACK — ФИКС: фрукты активируются через мышь в центр
-- ============================================================
local function attack(npc)
    if not npc or not npc.Parent then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local hum = npc:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local r = getRoot()
    if r then pcall(function() r.CFrame = CFrame.lookAt(r.Position, hrp.Position) end) end

    -- экип оружия
    local tool
    if character then
        tool = character:FindFirstChildOfClass("Tool")
    end
    if tool and humanoid then pcall(function() humanoid:EquipTool(tool) end) end

    -- камера в куб (куб в центре)
    if camera then
        pcall(function() camera.CFrame = CFrame.lookAt(camera.CFrame.Position, hrp.Position) end)
    end

    -- КЛИК ПО ЦЕНТРУ — для фруктов это важно
    if VirtualInput and camera then
        local vp = camera.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        pcall(function()
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.02)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end

    -- прямая активация оружия/фрукта
    if tool then
        pcall(function() tool:Activate() end)
    end

    -- СКИЛЛЫ: Z X C V — для фрукта это ОСНОВНОЙ урон
    if VirtualInput then
        for _,k in ipairs({"Z","X","C","V"}) do
            pcall(function()
                VirtualInput:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                task.wait(0.03)
                VirtualInput:SendKeyEvent(false, Enum.KeyCode[k], false, game)
            end)
        end
    end

    -- повторная активация
    if tool then pcall(function() tool:Activate() end) end
end

local PRIO = {
    { get=function() return state.autoFarmBosses  end, tag="boss" },
    { get=function() return state.autoFarmMarines end, tag="marine" },
    { get=function() return state.autoFarmPirates end, tag="pirate" },
    { get=function() return state.autoFarmLevel   end, tag="all" },
}
task.spawn(function()
    while true do
        local act=false
        for _,p in ipairs(PRIO) do
            if p.get() or state.autoQuest or state.autoFruitMastery then
                act=true
                local n = p.get() and nearest(p.tag) or nearest("all")
                if n then setHover(n); pcall(attack, n) end
                break
            end
        end
        if not act and not state.fly then setHover(nil) end
        task.wait(act and state.attackSpeed or 0.2)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if state.killAura then
            local r=getRoot()
            if r then
                for _,e in ipairs(npcCache) do
                    local h=e.model:FindFirstChild("HumanoidRootPart")
                    if h and (h.Position-r.Position).Magnitude<=state.killAuraRange then
                        pcall(attack, e.model)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- AUTO QUEST
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        if state.autoQuest then
            local q = findQuest(state.selectedQuest)
            if q then
                -- ТП к квестодателю
                local r = getRoot()
                if r then
                    local distToQ = (r.Position - q.pos).Magnitude
                    if distToQ > 30 then
                        tpTo(q.pos)
                        task.wait(0.5)
                    end
                    -- берём квест
                    pcall(function() startQuest(q.npc, q.level) end)
                    task.wait(0.5)
                end
            end
        end
    end
end)

-- ============================================================
-- AUTO FRUIT MASTERY
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if state.autoFruitMastery then
            if VirtualInput then
                for _,k in ipairs({"Z","X","C","V"}) do
                    pcall(function()
                        VirtualInput:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                        task.wait(0.03)
                        VirtualInput:SendKeyEvent(false, Enum.KeyCode[k], false, game)
                    end)
                end
            end
        end
    end
end)

-- ============================================================
-- AUTO CHEST — улучшенное сканирование
-- ============================================================
local chestCache = {}

local function classifyChest(o)
    pcall(function()
        local isModel = o:IsA("Model")
        local isPart = o:IsA("BasePart")
        if not (isModel or isPart) then return end
        local n = o.Name:lower()
        -- Blox Fruits: chests называются "Chest", "TreasureChest", "RustyChest" и т.д.
        if n == "chest" or n:find("chest") or n:find("crate")
           or n:find("barrel") or n:find("treasure") then
            chestCache[o] = true
        end
    end)
end

pcall(function()
    for _, o in ipairs(workspace:GetDescendants()) do classifyChest(o) end
end)
workspace.DescendantAdded:Connect(classifyChest)

task.spawn(function()
    while task.wait(3) do
        for o in pairs(chestCache) do
            if not o.Parent then chestCache[o] = nil end
        end
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if state.autoChest then
            local r = getRoot()
            if r then
                local myPos = r.Position
                local best, bd = nil, state.chestRange
                for o in pairs(chestCache) do
                    local pp = o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
                    if pp and pp.Position then
                        local d = (pp.Position - myPos).Magnitude
                        if d < bd then bd = d; best = pp end
                    end
                end
                if best then
                    tpTo(best.Position)
                    task.wait(0.15)
                end
            end
        end
        if state.autoFruit then
            local obj = findFruit(state.selectedFruit)
            if obj then tpToObject(obj); task.wait(0.3) end
        end
    end
end)

-- AUTO FISH
local function findRod()
    if not character then return nil end
    local ok, ch = pcall(function() return character:GetChildren() end)
    if not ok then return nil end
    for _,t in ipairs(ch) do
        if t:IsA("Tool") and (t.Name:lower():find("rod") or t.Name:lower():find("fishing")) then
            return t
        end
    end
    return nil
end
task.spawn(function()
    local fishing = false
    while task.wait(0.3) do
        if state.autoFish and not fishing then
            fishing = true
            task.spawn(function()
                while state.autoFish do
                    local rod = findRod()
                    if rod and humanoid and humanoid.Parent then
                        pcall(function() humanoid:EquipTool(rod) end)
                        task.wait(0.6)
                        pcall(function() rod:Activate() end)
                        task.wait(math.random(30, 80) / 10)
                        pcall(function() rod:Activate() end)
                        task.wait(1.5)
                    else task.wait(1) end
                end
                fishing = false
            end)
        end
    end
end)

-- ESP
local espFolder = Instance.new("Folder"); espFolder.Name="BinESP"; espFolder.Parent=workspace
local function mkESP(ad,col,txt)
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,100,0,30); bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true; bb.Adornee=ad; bb.Parent=espFolder
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=col; l.TextStrokeTransparency=0
    l.Font=Enum.Font.GothamBold; l.TextSize=12; l.Parent=bb
    local box=Instance.new("SelectionBox")
    box.Adornee=ad; box.Color3=col; box.LineThickness=0.05
    box.Transparency=0.5; box.Parent=espFolder
    return {bb=bb,box=box,lbl=l,ad=ad}
end
local function killESP(e) if e.bb then e.bb:Destroy() end if e.box then e.box:Destroy() end end
local nESP, pESP = {}, {}
task.spawn(function()
    while task.wait(0.5) do
        if state.espNPCs then
            local seen={}
            for _,e in ipairs(npcCache) do
                local h=e.model:FindFirstChild("HumanoidRootPart")
                if h then
                    seen[e.model]=true
                    local col=e.tag=="boss" and Color3.fromRGB(255,80,80)
                             or e.tag=="pirate" and Color3.fromRGB(255,170,70)
                             or e.tag=="marine" and Color3.fromRGB(100,160,250)
                             or Color3.fromRGB(200,200,200)
                    local en=nESP[e.model]
                    if en and en.bb.Parent then
                        if en.ad~=h then en.bb.Adornee=h; en.box.Adornee=h; en.ad=h end
                        en.lbl.Text=e.model.Name; en.lbl.TextColor3=col; en.box.Color3=col
                    else nESP[e.model]=mkESP(h,col,e.model.Name) end
                end
            end
            for m,en in pairs(nESP) do if not seen[m] then killESP(en); nESP[m]=nil end end
        else
            for m,en in pairs(nESP) do killESP(en); nESP[m]=nil end
        end
        if state.espPlayers then
            local seen={}
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=player and pl.Character then
                    local h=pl.Character:FindFirstChild("HumanoidRootPart")
                    if h then
                        seen[pl]=true
                        local en=pESP[pl]
                        if en and en.bb.Parent then
                            if en.ad~=h then en.bb.Adornee=h; en.box.Adornee=h; en.ad=h end
                        else pESP[pl]=mkESP(h,Color3.fromRGB(85,225,145),pl.Name) end
                    end
                end
            end
            for pl,en in pairs(pESP) do if not seen[pl] then killESP(en); pESP[pl]=nil end end
        else
            for pl,en in pairs(pESP) do killESP(en); pESP[pl]=nil end
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
local sg=Instance.new("ScreenGui")
sg.Name="BinBloxFruitsV19"; sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=playerGui
local function tw(o,t,p) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end
local function crn(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function strk(p,c,t,tr)
    local s=Instance.new("UIStroke"); s.Color=c; s.Thickness=t or 1
    s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

local nh=Instance.new("Frame")
nh.Size=UDim2.new(0,300,1,-40); nh.Position=UDim2.new(1,-320,0,20)
nh.BackgroundTransparency=1; nh.Parent=sg
local nll=Instance.new("UIListLayout",nh)
nll.Padding=UDim.new(0,8); nll.SortOrder=Enum.SortOrder.LayoutOrder

local function notify(title,text,col)
    col=col or C.accent
    local b=Instance.new("Frame")
    b.Size=UDim2.new(1,0,0,62); b.BackgroundColor3=C.surface
    b.BackgroundTransparency=0.08; b.BorderSizePixel=0; b.Parent=nh
    crn(b,12); strk(b,col,1.5,0.4)
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,3,1,-14); bar.Position=UDim2.new(0,7,0,7)
    bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=b; crn(bar,2)
    local t=Instance.new("TextLabel")
    t.Size=UDim2.new(1,-24,0,22); t.Position=UDim2.new(0,18,0,8)
    t.BackgroundTransparency=1; t.Text=title; t.TextColor3=col
    t.Font=Enum.Font.GothamBold; t.TextSize=13
    t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=b
    local d=Instance.new("TextLabel")
    d.Size=UDim2.new(1,-24,0,22); d.Position=UDim2.new(0,18,0,31)
    d.BackgroundTransparency=1; d.Text=text; d.TextColor3=C.sub
    d.Font=Enum.Font.Gotham; d.TextSize=12
    d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=b
    b.Position=UDim2.new(1,40,0,0)
    tw(b,0.35,{Position=UDim2.new(0,0,0,0)})
    task.delay(3,function()
        tw(b,0.35,{Position=UDim2.new(1,40,0,0),BackgroundTransparency=1})
        task.wait(0.4); b:Destroy()
    end)
end

local ob=Instance.new("TextButton")
ob.Size=UDim2.new(0,140,0,48); ob.Position=UDim2.new(0,20,0,100)
ob.BackgroundColor3=C.surface; ob.Text=""; ob.AutoButtonColor=false
ob.Active=true; ob.Parent=sg; crn(ob,14); strk(ob,C.accent,1.5,0.2)
local oi=Instance.new("TextLabel")
oi.Size=UDim2.new(0,32,1,0); oi.Position=UDim2.new(0,10,0,0)
oi.BackgroundTransparency=1; oi.Text="⚡"; oi.TextColor3=C.accent
oi.Font=Enum.Font.GothamBold; oi.TextSize=22; oi.Parent=ob
local ot=Instance.new("TextLabel")
ot.Size=UDim2.new(1,-50,1,0); ot.Position=UDim2.new(0,44,0,0)
ot.BackgroundTransparency=1; ot.Text="BF HUB"
ot.TextColor3=C.text; ot.Font=Enum.Font.GothamBold; ot.TextSize=15
ot.TextXAlignment=Enum.TextXAlignment.Left; ot.Parent=ob
ob.MouseEnter:Connect(function() tw(ob,0.2,{BackgroundColor3=C.surface2}) end)
ob.MouseLeave:Connect(function() tw(ob,0.2,{BackgroundColor3=C.surface}) end)

local WW,WH=460,560
local main=Instance.new("Frame")
main.Size=UDim2.new(0,WW,0,WH); main.Position=UDim2.new(0,20,0.5,-WH/2)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0; main.Visible=false
main.Active=true; main.ClipsDescendants=true; main.Parent=sg
crn(main,16); strk(main,C.accent3,1.2,0.55)

local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,56); tb.BackgroundColor3=C.surface
tb.BorderSizePixel=0; tb.Parent=main; crn(tb,16)
local tbf=Instance.new("Frame",tb)
tbf.Size=UDim2.new(1,0,0,14); tbf.Position=UDim2.new(0,0,1,-14)
tbf.BackgroundColor3=C.surface; tbf.BorderSizePixel=0
local lg=Instance.new("TextLabel")
lg.Size=UDim2.new(0,40,0,40); lg.Position=UDim2.new(0,14,0.5,-20)
lg.BackgroundColor3=C.surface2; lg.Text="⚡"; lg.TextColor3=C.accent
lg.Font=Enum.Font.GothamBold; lg.TextSize=22; lg.Parent=tb
crn(lg,10); strk(lg,C.accent,1,0.4)
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,-140,0,20); tl.Position=UDim2.new(0,64,0,12)
tl.BackgroundTransparency=1; tl.Text="Bin's Blox Fruits"
tl.TextColor3=C.text; tl.Font=Enum.Font.GothamBold; tl.TextSize=15
tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=tb
local sl=Instance.new("TextLabel")
sl.Size=UDim2.new(1,-140,0,16); sl.Position=UDim2.new(0,64,0,30)
sl.BackgroundTransparency=1; sl.Text="v19 beta · quests + chest fix"
sl.TextColor3=C.sub; sl.Font=Enum.Font.Gotham; sl.TextSize=11
sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=tb
local cb=Instance.new("TextButton")
cb.Size=UDim2.new(0,32,0,32); cb.Position=UDim2.new(1,-46,0.5,-16)
cb.BackgroundColor3=C.surface2; cb.Text="✕"; cb.TextColor3=C.sub
cb.Font=Enum.Font.GothamBold; cb.TextSize=14; cb.AutoButtonColor=false; cb.Parent=tb
crn(cb,8)
cb.MouseEnter:Connect(function() tw(cb,0.15,{BackgroundColor3=C.red,TextColor3=Color3.fromRGB(255,255,255)}) end)
cb.MouseLeave:Connect(function() tw(cb,0.15,{BackgroundColor3=C.surface2,TextColor3=C.sub}) end)

local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,-32,0,40); tabBar.Position=UDim2.new(0,16,0,68)
tabBar.BackgroundColor3=C.bg2; tabBar.BorderSizePixel=0; tabBar.Parent=main; crn(tabBar,12)
local pill=Instance.new("Frame")
pill.Size=UDim2.new(0.25,-6,1,-8); pill.Position=UDim2.new(0,4,0,4)
pill.BackgroundColor3=C.accent; pill.BorderSizePixel=0; pill.ZIndex=1; pill.Parent=tabBar
crn(pill,9)
local pages,tabs={},{}
local TN={"farm","quests","stats","tp","visual","misc"}
local TL={"⚔ FARM","📜 QUEST","📊 STAT","🌀 TP","👁 ESP","⚙ MISC"}
local function selTab(name)
    for _,n in ipairs(TN) do if tabs[n] then tabs[n].TextColor3=(n==name) and C.bg or C.sub end end
    local idx=1
    for i,n in ipairs(TN) do if n==name then idx=i; break end end
    tw(pill,0.25,{Position=UDim2.new((idx-1)/#TN,0,0,4)})
    for n,p in pairs(pages) do p.Visible=(n==name) end
    if pages[name] then
        pages[name].Position=UDim2.new(0,30,0,0)
        tw(pages[name],0.25,{Position=UDim2.new(0,0,0,0)})
    end
end
for i,name in ipairs(TN) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1/#TN,0,1,0); b.Position=UDim2.new((i-1)/#TN,0,0,0)
    b.BackgroundTransparency=1; b.Text=TL[i]; b.TextColor3=C.sub
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.ZIndex=2; b.Parent=tabBar
    b.MouseButton1Click:Connect(function() selTab(name) end)
    tabs[name]=b
end

local ca=Instance.new("Frame")
ca.Size=UDim2.new(1,-32,1,-180); ca.Position=UDim2.new(0,16,0,120)
ca.BackgroundTransparency=1; ca.ClipsDescendants=true; ca.Parent=main
for _,name in ipairs(TN) do
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0); p.BackgroundTransparency=1
    p.BorderSizePixel=0; p.ScrollBarThickness=4
    p.ScrollBarImageColor3=C.accent; p.ScrollBarImageTransparency=0.3
    p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false; p.Parent=ca
    local lay=Instance.new("UIListLayout",p)
    lay.Padding=UDim.new(0,8); lay.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",p); pad.PaddingRight=UDim.new(0,8)
    pages[name]=p
end
selTab("farm")

local ordr=0
local function no() ordr=ordr+1; return ordr end
local function section(parent,title)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,24); f.BackgroundTransparency=1
    f.LayoutOrder=no(); f.Parent=parent
    local d=Instance.new("Frame")
    d.Size=UDim2.new(0,6,0,6); d.Position=UDim2.new(0,2,0.5,-3)
    d.BackgroundColor3=C.accent; d.BorderSizePixel=0; d.Parent=f; crn(d,3)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-20,1,0); l.Position=UDim2.new(0,16,0,0)
    l.BackgroundTransparency=1; l.Text=title; l.TextColor3=C.accent
    l.Font=Enum.Font.GothamBold; l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end
local function toggle(parent,name,desc,get,set)
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,56); c.BackgroundColor3=C.surface
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.Parent=parent
    crn(c,10); strk(c,C.surface3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-110,0,20); l.Position=UDim2.new(0,16,0,10)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.text
    l.Font=Enum.Font.GothamBold; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    if desc then
        local d=Instance.new("TextLabel")
        d.Size=UDim2.new(1,-110,0,16); d.Position=UDim2.new(0,16,0,30)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=C.sub
        d.Font=Enum.Font.Gotham; d.TextSize=11
        d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=c
    end
    local tr=Instance.new("Frame")
    tr.Size=UDim2.new(0,46,0,24); tr.Position=UDim2.new(1,-60,0.5,-12)
    tr.BackgroundColor3=C.surface3; tr.BorderSizePixel=0; tr.Parent=c; crn(tr,12)
    local k=Instance.new("Frame")
    k.Size=UDim2.new(0,18,0,18); k.Position=UDim2.new(0,3,0.5,-9)
    k.BackgroundColor3=C.sub; k.BorderSizePixel=0; k.Parent=tr; crn(k,9)
    local hb=Instance.new("TextButton")
    hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.Parent=c
    local function rf(a)
        local v=get()
        local i=TweenInfo.new(a and 0.2 or 0,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
        TweenService:Create(tr,i,{BackgroundColor3=v and C.green or C.surface3}):Play()
        TweenService:Create(k,i,{
            Position=v and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=v and Color3.fromRGB(255,255,255) or C.sub,
        }):Play()
    end
    rf(false)
    hb.MouseButton1Click:Connect(function() set(not get()); rf(true) end)
end
local function slider(parent,name,mn,mx,st,get,set,suf)
    suf=suf or ""
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,76); c.BackgroundColor3=C.surface
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.Parent=parent
    crn(c,10); strk(c,C.surface3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-100,0,20); l.Position=UDim2.new(0,16,0,10)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.text
    l.Font=Enum.Font.GothamBold; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,90,0,20); vl.Position=UDim2.new(1,-106,0,10)
    vl.BackgroundTransparency=1
    vl.Text=string.format("%.2f",get())..suf
    vl.TextColor3=C.accent; vl.Font=Enum.Font.GothamBold; vl.TextSize=13
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=c
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-32,0,8); bg.Position=UDim2.new(0,16,0,42)
    bg.BackgroundColor3=C.surface3; bg.BorderSizePixel=0; bg.Parent=c; crn(bg,4)
    local fl=Instance.new("Frame")
    fl.Size=UDim2.new((get()-mn)/(mx-mn),0,1,0)
    fl.BackgroundColor3=C.accent; fl.BorderSizePixel=0; fl.Parent=bg; crn(fl,4)
    local mi=Instance.new("TextButton")
    mi.Size=UDim2.new(0,36,0,22); mi.Position=UDim2.new(0,16,1,-30)
    mi.BackgroundColor3=C.surface2; mi.Text="−"; mi.TextColor3=C.text
    mi.Font=Enum.Font.GothamBold; mi.TextSize=14; mi.AutoButtonColor=false; mi.Parent=c; crn(mi,6)
    local pl=Instance.new("TextButton")
    pl.Size=UDim2.new(0,36,0,22); pl.Position=UDim2.new(1,-52,1,-30)
    pl.BackgroundColor3=C.accent; pl.Text="+"; pl.TextColor3=C.bg
    pl.Font=Enum.Font.GothamBold; pl.TextSize=14; pl.AutoButtonColor=false; pl.Parent=c; crn(pl,6)
    local function up(v)
        v=math.clamp(v,mn,mx); set(v)
        vl.Text=string.format("%.2f",v)..suf
        tw(fl,0.15,{Size=UDim2.new((v-mn)/(mx-mn),0,1,0)})
    end
    mi.MouseButton1Click:Connect(function() up(get()-st) end)
    pl.MouseButton1Click:Connect(function() up(get()+st) end)
end
local function action(parent,text,cb2,col)
    col=col or C.accent
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,44); b.BackgroundColor3=col
    b.Text=text; b.TextColor3=C.bg; b.Font=Enum.Font.GothamBold
    b.TextSize=13; b.AutoButtonColor=false; b.LayoutOrder=no(); b.Parent=parent
    crn(b,10)
    b.MouseButton1Click:Connect(function()
        local ok,err=pcall(cb2)
        if not ok then warn("[BF Hub] "..tostring(err)); notify("Error",tostring(err),C.red) end
    end)
end

-- FARM PAGE
section(pages.farm,"FARMING")
toggle(pages.farm,"Auto Farm Level","Any NPC",
    function() return state.autoFarmLevel end, function(v) state.autoFarmLevel=v end)
toggle(pages.farm,"Auto Farm Pirates","Prioritize pirates",
    function() return state.autoFarmPirates end, function(v) state.autoFarmPirates=v end)
toggle(pages.farm,"Auto Farm Marines","Prioritize marines",
    function() return state.autoFarmMarines end, function(v) state.autoFarmMarines=v end)
toggle(pages.farm,"Auto Farm Bosses","Prioritize bosses",
    function() return state.autoFarmBosses end, function(v) state.autoFarmBosses=v end)

section(pages.farm,"COMBAT")
slider(pages.farm,"Attack Speed",0.1,2.0,0.05,
    function() return state.attackSpeed end, function(v) state.attackSpeed=v end,"s")
slider(pages.farm,"Hover Height",3,15,1,
    function() return state.hoverHeight end, function(v) state.hoverHeight=v end," studs")
toggle(pages.farm,"Lock Camera","Force cam on target",
    function() return state.lockCamera end, function(v) state.lockCamera=v end)
toggle(pages.farm,"Kill Aura","Attack nearby",
    function() return state.killAura end, function(v) state.killAura=v end)
slider(pages.farm,"Kill Aura Range",10,300,5,
    function() return state.killAuraRange end, function(v) state.killAuraRange=v end," studs")

section(pages.farm,"FLY")
toggle(pages.farm,"Fly","WASD + Space/Ctrl",
    function() return state.fly end, function(v) state.fly=v end)
slider(pages.farm,"Fly Speed",10,400,5,
    function() return state.flySpeed end, function(v) state.flySpeed=v end,"")

section(pages.farm,"AUTO FISH")
toggle(pages.farm,"Auto Fish","Auto cast",
    function() return state.autoFish end, function(v) state.autoFish=v end)

section(pages.farm,"AUTO COLLECT")
toggle(pages.farm,"Auto Chest","TP to chests (smart scan)",
    function() return state.autoChest end, function(v) state.autoChest=v end)
slider(pages.farm,"Chest Range",100,3000,50,
    function() return state.chestRange end, function(v) state.chestRange=v end," studs")
toggle(pages.farm,"Auto Fruit (selected)","TP to selected fruit",
    function() return state.autoFruit end, function(v) state.autoFruit=v end)

-- QUESTS PAGE
section(pages.quests,"AUTO QUEST")
toggle(pages.quests,"Auto Quest","Take + complete quest loop",
    function() return state.autoQuest end, function(v) state.autoQuest=v end)

local qLabel = Instance.new("TextLabel")
qLabel.Size = UDim2.new(1,0,0,26); qLabel.BackgroundColor3 = C.surface
qLabel.BorderSizePixel = 0; qLabel.LayoutOrder = no(); qLabel.Parent = pages.quests
qLabel.Text = "  Selected: Bandit (Lvl 1)"
qLabel.TextColor3 = C.accent3; qLabel.Font = Enum.Font.GothamBold
qLabel.TextSize = 13; qLabel.TextXAlignment = Enum.TextXAlignment.Left
crn(qLabel, 8); strk(qLabel, C.accent3, 1, 0.4)

local qGrid = Instance.new("Frame")
qGrid.Size = UDim2.new(1,0,0,260); qGrid.BackgroundColor3 = C.surface
qGrid.BorderSizePixel = 0; qGrid.LayoutOrder = no(); qGrid.Parent = pages.quests
crn(qGrid,10); strk(qGrid, C.surface3, 1, 0.5)
local qScroll = Instance.new("ScrollingFrame")
qScroll.Size = UDim2.new(1,-16,1,-16); qScroll.Position = UDim2.new(0,8,0,8)
qScroll.BackgroundTransparency = 1; qScroll.BorderSizePixel = 0
qScroll.ScrollBarThickness = 4; qScroll.ScrollBarImageColor3 = C.accent3
qScroll.CanvasSize = UDim2.new(0,0,0,0); qScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
qScroll.Parent = qGrid
local qLay = Instance.new("UIListLayout", qScroll)
qLay.Padding = UDim.new(0, 5); qLay.SortOrder = Enum.SortOrder.LayoutOrder

local qBtns = {}
local function selQuest(name)
    state.selectedQuest = name
    local q = findQuest(name)
    if q then
        qLabel.Text = "  Selected: " .. q.name .. " (Lvl " .. q.level .. ")"
        state.questLevel = q.level
    end
    for n,b in pairs(qBtns) do
        local a = (n == name)
        tw(b, 0.15, {
            BackgroundColor3 = a and C.accent3 or C.surface2,
            TextColor3 = a and Color3.fromRGB(255,255,255) or C.text,
        })
    end
end

for _, q in ipairs(QUESTS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-6,0,32)
    b.BackgroundColor3 = C.surface2
    b.Text = "  " .. q.name .. "  ·  Lvl " .. q.level
    b.TextColor3 = C.text; b.Font = Enum.Font.Gotham
    b.TextSize = 12; b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false; b.Parent = qScroll; crn(b, 6)
    b.MouseButton1Click:Connect(function() selQuest(q.name) end)
    qBtns[q.name] = b
end
selQuest(state.selectedQuest)

action(pages.quests,"📜  Start Selected Quest (manual)", function()
    local q = findQuest(state.selectedQuest)
    if q then
        tpTo(q.pos)
        task.wait(0.5)
        startQuest(q.npc, q.level)
        notify("Quest", "Started: "..q.name, C.accent3)
    end
end, C.accent3)

-- STATS PAGE
section(pages.stats,"AUTO STAT")
toggle(pages.stats,"Auto Stat","Auto allocate points",
    function() return state.autoStat end, function(v) state.autoStat=v end)

local sLabel = Instance.new("TextLabel")
sLabel.Size = UDim2.new(1,0,0,26); sLabel.BackgroundColor3 = C.surface
sLabel.BorderSizePixel = 0; sLabel.LayoutOrder = no(); sLabel.Parent = pages.stats
sLabel.Text = "  Selected: Melee"
sLabel.TextColor3 = C.accent; sLabel.Font = Enum.Font.GothamBold
sLabel.TextSize = 13; sLabel.TextXAlignment = Enum.TextXAlignment.Left
crn(sLabel, 8); strk(sLabel, C.accent, 1, 0.4)

local sGrid = Instance.new("Frame")
sGrid.Size = UDim2.new(1,0,0,50); sGrid.BackgroundColor3 = C.surface
sGrid.BorderSizePixel = 0; sGrid.LayoutOrder = no(); sGrid.Parent = pages.stats
crn(sGrid,10); strk(sGrid, C.surface3, 1, 0.5)
local sLay = Instance.new("UIListLayout", sGrid)
sLay.FillDirection = Enum.FillDirection.Horizontal
sLay.Padding = UDim.new(0, 6)
sLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
sLay.VerticalAlignment = Enum.VerticalAlignment.Center
sLay.SortOrder = Enum.SortOrder.LayoutOrder

local statBtns = {}
local function selStat(name)
    state.selectedStat = name
    sLabel.Text = "  Selected: " .. name
    for n,b in pairs(statBtns) do
        local a = (n == name)
        tw(b, 0.15, {BackgroundColor3 = a and C.accent or C.surface2, TextColor3 = a and C.bg or C.text})
    end
end
for _, sname in ipairs(STAT_NAMES) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 80, 0, 34); b.BackgroundColor3 = C.surface2
    b.Text = sname; b.TextColor3 = C.text; b.Font = Enum.Font.GothamBold
    b.TextSize = 11; b.AutoButtonColor = false; b.Parent = sGrid; crn(b, 6)
    b.MouseButton1Click:Connect(function() selStat(sname) end)
    statBtns[sname] = b
end
selStat(state.selectedStat)

section(pages.stats,"AUTO FRUIT MASTERY")
toggle(pages.stats,"Auto Fruit Mastery","Farming + spam skills",
    function() return state.autoFruitMastery end, function(v) state.autoFruitMastery=v end)

-- TP PAGE
section(pages.tp,"ACTIONS")
action(pages.tp,"✨  Teleport Now",function()
    local l=findLoc(state.selectedTP)
    if l then tpTo(l.pos); notify("Teleport","Warped: "..l.name,C.accent3) end
end,C.accent3)
action(pages.tp,"🛑  Stop Hover",function()
    if hoverTarget then restoreHitbox(hoverTarget) end
    setHover(nil); notify("Hover","Off",C.red)
end,C.surface2)
action(pages.tp,"🍎  TP to Selected Fruit",function()
    local obj = findFruit(state.selectedFruit)
    if obj then tpToObject(obj); notify("Fruit", "TP: "..state.selectedFruit, C.accent2)
    else notify("Fruit", state.selectedFruit.." не найдено", C.red) end
end, C.accent2)

-- VISUAL
section(pages.visual,"ESP")
toggle(pages.visual,"ESP NPCs","Boxes over enemies",
    function() return state.espNPCs end, function(v) state.espNPCs=v end)
toggle(pages.visual,"ESP Players","Boxes over players",
    function() return state.espPlayers end, function(v) state.espPlayers=v end)

-- MISC
section(pages.misc,"INFO")
action(pages.misc,"🔄  Refresh NPC Cache",function()
    refresh(); notify("Cache","Refreshed: "..#npcCache,C.green)
end,C.surface2)

local ft=Instance.new("Frame")
ft.Size=UDim2.new(1,-32,0,32); ft.Position=UDim2.new(0,16,1,-44)
ft.BackgroundColor3=C.bg2; ft.BorderSizePixel=0; ft.Parent=main; crn(ft,10)
local ftL=Instance.new("TextLabel")
ftL.Size=UDim2.new(1,-20,1,0); ftL.Position=UDim2.new(0,12,0,0)
ftL.BackgroundTransparency=1; ftL.Text="made by Bin & Steve  ·  nya~"
ftL.TextColor3=C.dim; ftL.Font=Enum.Font.Gotham; ftL.TextSize=11
ftL.TextXAlignment=Enum.TextXAlignment.Left; ftL.Parent=ft

local isOpen=false
local function tglW()
    isOpen=not isOpen
    if isOpen then
        main.Visible=true
        main.Size=UDim2.new(0,WW*0.85,0,WH*0.85)
        main.BackgroundTransparency=0.3
        tw(main,0.3,{Size=UDim2.new(0,WW,0,WH),BackgroundTransparency=0})
    else
        tw(main,0.2,{Size=UDim2.new(0,WW*0.85,0,WH*0.85),BackgroundTransparency=0.4})
        task.wait(0.2)
        main.Visible=false
        main.Size=UDim2.new(0,WW,0,WH); main.BackgroundTransparency=0
    end
end
ob.MouseButton1Click:Connect(tglW)
cb.MouseButton1Click:Connect(tglW)

do
    local drag,ds,sp
    local function beg(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=main.Position
        end
    end
    local function en(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end
    local function mv(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end
    tb.InputBegan:Connect(beg); tb.InputEnded:Connect(en); UserInput.InputChanged:Connect(mv)
    ob.InputBegan:Connect(beg); ob.InputEnded:Connect(en)
end

notify("Bin's Hub v19","Quests + chest fix",C.accent)
print("[Bin's Hub v19] loaded.")
