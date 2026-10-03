-- Bin's Blox Fruits Hub v21 BETA — REDESIGN + BOSS TP + FIXES
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
local UIS = game:GetService("UserInputService")

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

local function getCommF()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then return nil end
    return r:FindFirstChild("CommF_") or r:FindFirstChild("CommE_")
end

local state = {
    autoFarmLevel=false, autoFarmPirates=false, autoFarmMarines=false, autoFarmBosses=false,
    attackSpeed=0.25, killAura=false, killAuraRange=45, hoverHeight=6,
    selectedTP="Pirate Island", espNPCs=false, espPlayers=false,
    autoChest=false, autoFruit=false, lockCamera=true,
    autoFish=false, selectedFruit="Dragon", fly=false, flySpeed=120,
    autoStat=false, selectedStat="Melee",
    autoFruitMastery=false,
    chestRange=2000,
    autoQuest=false, selectedQuest="Bandit", questLevel=1,
}

-- ============================================================
-- HITBOX 40x40x40
-- ============================================================
local HITBOX_SIZE = 40
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
        hrp.Transparency = 1; hrp.CanCollide = false; hrp.Massless = true
        hrp.CanQuery = true; hrp.CanTouch = true
    end)
end
local function restoreHitbox(npc)
    if not npc then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local o = origHRP[hrp]
    if o then
        pcall(function()
            hrp.Size=o.size; hrp.Transparency=o.trans
            hrp.CanCollide=o.coll; hrp.Massless=o.mass
        end)
        origHRP[hrp] = nil
    end
end

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
        restoreHitbox(hoverTarget); hoverActive=false; hoverTarget=nil
        if humanoid then pcall(function() humanoid.PlatformStand=false end) end
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

-- FLY
local flyConn = nil
local function startFly()
    local r = getRoot(); if not r or not humanoid then return end
    pcall(function() humanoid.PlatformStand=true end)
    pcall(function() humanoid.WalkSpeed=0 end)
    pcall(function() humanoid.JumpPower=0 end)
    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not state.fly then return end
        local rr=getRoot(); if not rr then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local move=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then move=move+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move=move-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move=move-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move=move+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move=move-Vector3.new(0,1,0) end
        if move.Magnitude>0 then move=move.Unit*state.flySpeed*dt end
        pcall(function() rr.CFrame=rr.CFrame+move; rr.Velocity=Vector3.new(0,0,0) end)
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if humanoid then
        pcall(function() humanoid.PlatformStand=false; humanoid.WalkSpeed=16; humanoid.JumpPower=50 end)
    end
end
task.spawn(function()
    local last=false
    while task.wait(0.1) do
        if state.fly and not last then startFly() end
        if not state.fly and last then stopFly() end
        last=state.fly
    end
end)

local STAT_NAMES = {"Melee","Defense","Sword","Gun","Blox Fruit"}
local function allocateStat(name)
    local remotes = getCommF()
    if not remotes then return false end
    return pcall(function() remotes:InvokeServer("AddPoint", name, 1) end)
end
task.spawn(function()
    while task.wait(0.5) do
        if state.autoStat then pcall(function() allocateStat(state.selectedStat) end) end
    end
end)

-- ============================================================
-- CITIES (для ТП по городам)
-- ============================================================
local CITIES = {
    { name="Bandit Camp",       pos=Vector3.new(-1110,20,3200), sea=1 },
    { name="Pirate Village",    pos=Vector3.new(-1200,20,3400), sea=1 },
    { name="Marine Fort",       pos=Vector3.new(-2800,20,4300), sea=1 },
    { name="Jungle",            pos=Vector3.new(-1600,20,200),  sea=1 },
    { name="Marine Ford",       pos=Vector3.new(-2760,20,4320), sea=1 },
    { name="Fountain City",     pos=Vector3.new(-1250,20,3200), sea=1 },
    { name="Pirate Island",     pos=Vector3.new(1000,20,1200),  sea=1 },
    { name="First Sea Port",    pos=Vector3.new(400,20,400),    sea=1 },
    { name="Colosseum",         pos=Vector3.new(-1500,20,200),  sea=1 },
    { name="Desert",            pos=Vector3.new(1000,20,4500),  sea=1 },
    { name="Snow Island",       pos=Vector3.new(1250,20,-1500), sea=1 },
    { name="Skylands",          pos=Vector3.new(-500,800,-1500),sea=1 },
    { name="Prison",            pos=Vector3.new(5000,20,800),   sea=1 },
    { name="Kingdom of Rose",   pos=Vector3.new(-400,20,6000),  sea=2 },
    { name="Green Zone",        pos=Vector3.new(-3500,20,-4500),sea=2 },
    { name="Graveyard",         pos=Vector3.new(-5500,20,-3000),sea=2 },
    { name="Snow Mountain",     pos=Vector3.new(-1500,20,-5500),sea=2 },
    { name="Cursed Ship",       pos=Vector3.new(9000,20,5000),  sea=2 },
    { name="Ice Castle",        pos=Vector3.new(-6000,20,-6000),sea=2 },
    { name="Forgotten Island",  pos=Vector3.new(-3000,20,-8000),sea=2 },
    { name="Port Town",         pos=Vector3.new(-500,20,-10000),sea=3 },
    { name="Hydra Island",      pos=Vector3.new(5000,20,-9000), sea=3 },
    { name="Great Tree",        pos=Vector3.new(-3000,20,-12000),sea=3 },
    { name="Floating Turtle",   pos=Vector3.new(-9000,20,-10000),sea=3 },
    { name="Haunted Castle",    pos=Vector3.new(3000,20,-12000),sea=3 },
    { name="Castle on the Sea", pos=Vector3.new(-6000,20,-14000),sea=3 },
    { name="Sea of Treats",     pos=Vector3.new(5000,20,-15000),sea=3 },
}
local function findCity(n) for _,l in ipairs(CITIES) do if l.name==n then return l end end end

-- ============================================================
-- BOSSES (с уровнями и координатами)
-- ============================================================
local BOSSES = {
    -- Sea 1
    { name="Gorilla King",   level=100,   pos=Vector3.new(-1170, 20, 3200), sea=1 },
    { name="Bobby",          level=150,   pos=Vector3.new(-1200, 20, 3400), sea=1 },
    { name="Yeti",           level=200,   pos=Vector3.new(1300,  20, -1600), sea=1 },
    { name="Mob Leader",     level=300,   pos=Vector3.new(-1500, 20, 300),  sea=1 },
    { name="Vice Admiral",   level=375,   pos=Vector3.new(-2800, 20, 4300), sea=1 },
    { name="Saber Expert",   level=500,   pos=Vector3.new(-1500, 20, 200),  sea=1 },
    { name="Cyborg",         level=650,   pos=Vector3.new(-2800, 20, 4320), sea=1 },
    -- Sea 2
    { name="Diamond",        level=750,   pos=Vector3.new(-400,  20, 6000), sea=2 },
    { name="Jeremy",         level=850,   pos=Vector3.new(-3600, 20, -4500), sea=2 },
    { name="Smoke Admiral",  level=1000,  pos=Vector3.new(-6000, 20, -6000), sea=2 },
    -- Sea 3
    { name="Yellow Beard",   level=1100,  pos=Vector3.new(-500,  20, -10000), sea=3 },
    { name="Cursed Captain", level=1250,  pos=Vector3.new(3000,  20, -12000), sea=3 },
    { name="Soul Reaper",    level=1400,  pos=Vector3.new(-3000, 20, -12000), sea=3 },
    { name="rip_indra True", level=1500,  pos=Vector3.new(5000,  20, -9000),  sea=3 },
    { name="Cake Queen",     level=1700,  pos=Vector3.new(5000,  20, -15000), sea=3 },
    { name="Dough King",     level=2000,  pos=Vector3.new(-9000, 20, -10000), sea=3 },
}
local function findBoss(n) for _,b in ipairs(BOSSES) do if b.name==n then return b end end end

-- ============================================================
-- QUESTS
-- ============================================================
local QUESTS = {
    { name="Bandit",        level=1,    pos=Vector3.new(-1143, 20, 3140),   npc="Bandit" },
    { name="Monkey",        level=15,   pos=Vector3.new(-1594, 20, 200),    npc="Monkey" },
    { name="Blade Master",  level=25,   pos=Vector3.new(-1449, 20, 127),    npc="Blade Master" },
    { name="Brute",         level=40,   pos=Vector3.new(-1140, 20, 1520),   npc="Brute" },
    { name="Pirate",        level=60,   pos=Vector3.new(-1200, 20, 3400),   npc="Pirate" },
    { name="Marine",        level=90,   pos=Vector3.new(-2800, 20, 4300),   npc="Marine" },
    { name="Snow Bandit",   level=120,  pos=Vector3.new(1250,  20, -1500),  npc="Snow Bandit" },
    { name="Snowman",       level=140,  pos=Vector3.new(1300,  20, -1600),  npc="Snowman" },
    { name="Frost Brigand", level=160,  pos=Vector3.new(1400,  20, -1400),  npc="Frost Brigand" },
    { name="Sky Bandit",    level=180,  pos=Vector3.new(-500,  800, -1500), npc="Sky Bandit" },
    { name="Raider",        level=375,  pos=Vector3.new(-400,  20, 6000),   npc="Raider" },
    { name="Mercenary",     level=450,  pos=Vector3.new(-3600, 20, -4500),  npc="Mercenary" },
    { name="Zombie",        level=550,  pos=Vector3.new(-5500, 20, -3000),  npc="Zombie" },
    { name="Pirate Captain",level=1000, pos=Vector3.new(-500,  20, -10000), npc="Pirate Captain" },
    { name="Hydra",         level=1100, pos=Vector3.new(5000,  20, -9000),  npc="Hydra" },
}
local function findQuest(n) for _,q in ipairs(QUESTS) do if q.name==n then return q end end end

local function startQuest(name, level)
    local remotes = getCommF()
    if not remotes then
        warn("[Bin Hub] CommF_ not found. Path: ReplicatedStorage.Remotes.CommF_")
        return false
    end
    local ok, err = pcall(function()
        remotes:InvokeServer("StartQuest", name, level)
    end)
    if not ok then warn("[Bin Hub] StartQuest failed: "..tostring(err)) end
    return ok
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

local function attack(npc)
    if not npc or not npc.Parent then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local hum = npc:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    local r = getRoot()
    if r then pcall(function() r.CFrame = CFrame.lookAt(r.Position, hrp.Position) end) end
    local tool
    if character then tool = character:FindFirstChildOfClass("Tool") end
    if tool and humanoid then pcall(function() humanoid:EquipTool(tool) end) end
    if camera then pcall(function() camera.CFrame = CFrame.lookAt(camera.CFrame.Position, hrp.Position) end) end
    if VirtualInput and camera then
        local vp = camera.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        pcall(function()
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.02)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end
    if tool then pcall(function() tool:Activate() end) end
    if VirtualInput then
        for _,k in ipairs({"Z","X","C","V"}) do
            pcall(function()
                VirtualInput:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                task.wait(0.03)
                VirtualInput:SendKeyEvent(false, Enum.KeyCode[k], false, game)
            end)
        end
    end
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

-- AUTO QUEST (улучшено)
task.spawn(function()
    while task.wait(1.5) do
        if state.autoQuest then
            local q = findQuest(state.selectedQuest)
            if q then
                local r = getRoot()
                if r then
                    local d = (r.Position - q.pos).Magnitude
                    if d > 30 then
                        tpTo(q.pos)
                        task.wait(1)
                    end
                    startQuest(q.npc, q.level)
                    task.wait(0.5)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if state.autoFruitMastery and VirtualInput then
            for _,k in ipairs({"Z","X","C","V"}) do
                pcall(function()
                    VirtualInput:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                    task.wait(0.03)
                    VirtualInput:SendKeyEvent(false, Enum.KeyCode[k], false, game)
                end)
            end
        end
    end
end)

-- ============================================================
-- CHEST SYSTEM (улучшено — координаты + умное ТП)
-- ============================================================
local chestCache = {}
local function classifyChest(o)
    pcall(function()
        if not (o:IsA("Model") or o:IsA("BasePart")) then return end
        local n = o.Name:lower()
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
        for o in pairs(chestCache) do if not o.Parent then chestCache[o] = nil end end
    end
end)

local collectedChests = 0
task.spawn(function()
    while task.wait(0.3) do
        if state.autoChest then
            local r = getRoot()
            if r then
                local myPos = r.Position
                local best, bd = nil, state.chestRange
                for o in pairs(chestCache) do
                    local pp = o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o:PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
                    if pp and pp.Position then
                        local d = (pp.Position - myPos).Magnitude
                        if d < bd then bd = d; best = pp end
                    end
                end
                if best then
                    tpTo(best.Position)
                    collectedChests = collectedChests + 1
                    task.wait(0.1)
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
        if t:IsA("Tool") and (t.Name:lower():find("rod") or t.Name:lower():find("fishing")) then return t end
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

-- ============================================================
-- UI — новый дизайн (тёмно-синий + неон)
-- ============================================================
local C = {
    bg        = Color3.fromRGB(8, 12, 24),
    bg2       = Color3.fromRGB(14, 20, 38),
    surface   = Color3.fromRGB(20, 28, 52),
    surface2  = Color3.fromRGB(32, 42, 72),
    surface3  = Color3.fromRGB(52, 62, 100),
    accent    = Color3.fromRGB(0, 200, 255),
    accent2   = Color3.fromRGB(120, 100, 255),
    accent3   = Color3.fromRGB(0, 255, 180),
    green     = Color3.fromRGB(90, 240, 180),
    red       = Color3.fromRGB(255, 90, 120),
    text      = Color3.fromRGB(240, 245, 255),
    sub       = Color3.fromRGB(140, 160, 200),
    dim       = Color3.fromRGB(70, 85, 130),
}

local sg=Instance.new("ScreenGui")
sg.Name="BinBloxFruitsV21"; sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=playerGui

local function tw(o,t,p) TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end
local function crn(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function strk(p,c,t,tr)
    local s=Instance.new("UIStroke"); s.Color=c; s.Thickness=t or 1
    s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

-- NOTIF
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

-- ============================================================
-- KEY SYSTEM (красивая)
-- ============================================================
local VALID_KEY = "h00x"
local keyOk = false

local keyBack = Instance.new("Frame")
keyBack.Size = UDim2.new(1,0,1,0); keyBack.BackgroundColor3 = Color3.fromRGB(0,0,0)
keyBack.BackgroundTransparency = 0.4; keyBack.BorderSizePixel = 0
keyBack.ZIndex = 50; keyBack.Parent = sg

local keyGui = Instance.new("Frame")
keyGui.Size = UDim2.new(0, 400, 0, 300)
keyGui.Position = UDim2.new(0.5, -200, 0.5, -150)
keyGui.BackgroundColor3 = C.bg
keyGui.BorderSizePixel = 0
keyGui.Active = true
keyGui.ZIndex = 51
keyGui.Parent = sg
crn(keyGui, 22)
strk(keyGui, C.accent, 2.5, 0.15)

local kg = Instance.new("UIGradient")
kg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(0.5, C.accent2),
    ColorSequenceKeypoint.new(1, C.accent3),
})
kg.Rotation = 45
kg.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.55),
    NumberSequenceKeypoint.new(1, 0.55),
})
kg.Parent = keyGui

local kLogo = Instance.new("TextLabel")
kLogo.Size = UDim2.new(1,0,0,64); kLogo.Position = UDim2.new(0,0,0,24)
kLogo.BackgroundTransparency = 1; kLogo.Text = "⚡"
kLogo.TextColor3 = C.accent; kLogo.Font = Enum.Font.GothamBold
kLogo.TextSize = 48; kLogo.ZIndex = 52; kLogo.Parent = keyGui

local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1,0,0,28); kTitle.Position = UDim2.new(0,0,0,92)
kTitle.BackgroundTransparency = 1; kTitle.Text = "Bin's Blox Fruits Hub"
kTitle.TextColor3 = C.text; kTitle.Font = Enum.Font.GothamBold
kTitle.TextSize = 20; kTitle.ZIndex = 52; kTitle.Parent = keyGui

local kSub = Instance.new("TextLabel")
kSub.Size = UDim2.new(1,0,0,20); kSub.Position = UDim2.new(0,0,0,122)
kSub.BackgroundTransparency = 1; kSub.Text = "v21 · private build · enter key"
kSub.TextColor3 = C.sub; kSub.Font = Enum.Font.Gotham
kSub.TextSize = 12; kSub.ZIndex = 52; kSub.Parent = keyGui

local kBox = Instance.new("TextBox")
kBox.Size = UDim2.new(1,-80,0,48); kBox.Position = UDim2.new(0,40,0,168)
kBox.BackgroundColor3 = C.surface; kBox.BorderSizePixel = 0
kBox.Text = ""; kBox.PlaceholderText = "🔑 введите ключ..."
kBox.PlaceholderColor3 = C.dim; kBox.TextColor3 = C.text
kBox.Font = Enum.Font.GothamBold; kBox.TextSize = 16
kBox.ClearTextOnFocus = false; kBox.ZIndex = 52; kBox.Parent = keyGui
crn(kBox, 12); strk(kBox, C.surface3, 1.5, 0.3)

local kBtn = Instance.new("TextButton")
kBtn.Size = UDim2.new(1,-80,0,50); kBtn.Position = UDim2.new(0,40,0,226)
kBtn.BackgroundColor3 = C.accent; kBtn.Text = "UNLOCK"
kBtn.TextColor3 = Color3.fromRGB(0,0,0); kBtn.Font = Enum.Font.GothamBold
kBtn.TextSize = 15; kBtn.AutoButtonColor = false; kBtn.ZIndex = 52; kBtn.Parent = keyGui
crn(kBtn, 12)

local kBtnGrad = Instance.new("UIGradient")
kBtnGrad.Color = ColorSequence.new(C.accent, C.accent3)
kBtnGrad.Rotation = 45
kBtnGrad.Parent = kBtn

kBtn.MouseEnter:Connect(function() tw(kBtn, 0.15, {BackgroundColor3 = C.accent3}) end)
kBtn.MouseLeave:Connect(function() tw(kBtn, 0.15, {BackgroundColor3 = C.accent}) end)

kBtn.MouseButton1Click:Connect(function()
    if kBox.Text == VALID_KEY then
        keyOk = true
        tw(keyBack, 0.4, {BackgroundTransparency = 1})
        tw(keyGui, 0.4, {Size = UDim2.new(0, 200, 0, 140), Position = UDim2.new(0.5,-100,0.5,-70)})
        task.wait(0.4)
        keyBack:Destroy()
        keyGui:Destroy()
        notify("✓ Unlocked", "Welcome, "..player.Name, C.green)
        task.spawn(function()
            local greet = Instance.new("TextLabel")
            greet.Size = UDim2.new(0, 600, 0, 80)
            greet.Position = UDim2.new(0.5, -300, 0.4, -40)
            greet.BackgroundTransparency = 1
            greet.Text = "⚡ Добро пожаловать, " .. player.Name .. " ⚡"
            greet.TextColor3 = C.accent
            greet.Font = Enum.Font.GothamBold
            greet.TextSize = 28
            greet.TextStrokeTransparency = 0
            greet.TextStrokeColor3 = C.accent2
            greet.ZIndex = 100
            greet.Parent = sg
            task.wait(2)
            tw(greet, 0.5, {TextTransparency = 1})
            task.wait(0.5); greet:Destroy()
        end)
    else
        kBox.Text = ""
        kBox.PlaceholderText = "❌ неверный ключ"
        kBox.PlaceholderColor3 = C.red
        strk(kBox, C.red, 2.5, 0)
        task.wait(0.15)
        keyGui.Position = UDim2.new(0.5, -205, 0.5, -150)
        task.wait(0.1)
        keyGui.Position = UDim2.new(0.5, -195, 0.5, -150)
        task.wait(0.1)
        keyGui.Position = UDim2.new(0.5, -200, 0.5, -150)
        task.delay(1.2, function()
            if kBox and kBox.Parent then
                kBox.PlaceholderText = "🔑 введите ключ..."
                kBox.PlaceholderColor3 = C.dim
            end
        end)
    end
end)

-- ============================================================
-- PLAYER CARD (слева снизу)
-- ============================================================
local pCard = Instance.new("Frame")
pCard.Size = UDim2.new(0, 240, 0, 70)
pCard.Position = UDim2.new(0, 18, 1, -90)
pCard.BackgroundColor3 = C.surface
pCard.BackgroundTransparency = 0.1
pCard.BorderSizePixel = 0
pCard.Visible = false
pCard.ZIndex = 5
pCard.Parent = sg
crn(pCard, 14); strk(pCard, C.accent, 1.5, 0.3)

local pGrad = Instance.new("UIGradient")
pGrad.Color = ColorSequence.new(C.accent, C.accent2)
pGrad.Rotation = 45
pGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.85),
})
pGrad.Parent = pCard

local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 54, 0, 54)
avatarFrame.Position = UDim2.new(0, 8, 0.5, -27)
avatarFrame.BackgroundColor3 = C.bg2
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 6
avatarFrame.Parent = pCard
crn(avatarFrame, 12); strk(avatarFrame, C.accent, 1.5, 0.2)

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(1, -4, 1, -4)
avatarImg.Position = UDim2.new(0, 2, 0, 2)
avatarImg.BackgroundTransparency = 1
avatarImg.ZIndex = 7
avatarImg.Parent = avatarFrame
crn(avatarImg, 10)

pcall(function()
    local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    avatarImg.Image = thumb
end)

local pName = Instance.new("TextLabel")
pName.Size = UDim2.new(1, -76, 0, 22)
pName.Position = UDim2.new(0, 72, 0, 12)
pName.BackgroundTransparency = 1
pName.Text = player.Name
pName.TextColor3 = C.text
pName.Font = Enum.Font.GothamBold
pName.TextSize = 14
pName.TextXAlignment = Enum.TextXAlignment.Left
pName.TextTruncate = Enum.TextTruncate.AtEnd
pName.ZIndex = 6
pName.Parent = pCard

local pLevel = Instance.new("TextLabel")
pLevel.Size = UDim2.new(1, -76, 0, 18)
pLevel.Position = UDim2.new(0, 72, 0, 34)
pLevel.BackgroundTransparency = 1
pLevel.Text = "Hub v21 BETA"
pLevel.TextColor3 = C.sub
pLevel.Font = Enum.Font.Gotham
pLevel.TextSize = 11
pLevel.TextXAlignment = Enum.TextXAlignment.Left
pLevel.ZIndex = 6
pLevel.Parent = pCard

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local lvl = player:FindFirstChild("Data")
            if lvl and lvl:FindFirstChild("Level") then
                pLevel.Text = "Lvl " .. lvl.Level.Value .. " · Hub v21"
            end
        end)
    end
end)

-- ============================================================
-- MAIN MENU (кнопки слева)
-- ============================================================
local ob=Instance.new("TextButton")
ob.Size=UDim2.new(0,160,0,50); ob.Position=UDim2.new(0,18,0,20)
ob.BackgroundColor3=C.surface; ob.Text=""; ob.AutoButtonColor=false
ob.Active=true; ob.Visible=false; ob.ZIndex = 3; ob.Parent=sg
crn(ob,14); strk(ob,C.accent,2,0.2)

local ogG = Instance.new("UIGradient")
ogG.Color = ColorSequence.new(C.accent, C.accent2)
ogG.Rotation = 45
ogG.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.85),
})
ogG.Parent = ob

local oi=Instance.new("TextLabel")
oi.Size=UDim2.new(0,34,1,0); oi.Position=UDim2.new(0,10,0,0)
oi.BackgroundTransparency=1; oi.Text="⚡"; oi.TextColor3=C.accent
oi.Font=Enum.Font.GothamBold; oi.TextSize=22; oi.ZIndex = 4; oi.Parent=ob

local ot=Instance.new("TextLabel")
ot.Size=UDim2.new(1,-52,1,0); ot.Position=UDim2.new(0,46,0,0)
ot.BackgroundTransparency=1; ot.Text="BF HUB"
ot.TextColor3=C.text; ot.Font=Enum.Font.GothamBold; ot.TextSize=15
ot.TextXAlignment=Enum.TextXAlignment.Left; ot.ZIndex = 4; ot.Parent=ob

ob.MouseEnter:Connect(function() tw(ob,0.2,{BackgroundColor3=C.surface2}) end)
ob.MouseLeave:Connect(function() tw(ob,0.2,{BackgroundColor3=C.surface}) end)

local WW,WH=500,600
local main=Instance.new("Frame")
main.Size=UDim2.new(0,WW,0,WH); main.Position=UDim2.new(0,18,0,80)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0; main.Visible=false
main.Active=true; main.ClipsDescendants=true; main.ZIndex = 4; main.Parent=sg
crn(main,18); strk(main,C.accent,2,0.3)

local mGrad = Instance.new("UIGradient")
mGrad.Color = ColorSequence.new(C.accent, C.accent2)
mGrad.Rotation = 45
mGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 0.85),
})
mGrad.Parent = main

-- title
local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,60); tb.BackgroundColor3=C.surface
tb.BorderSizePixel=0; tb.ZIndex = 5; tb.Parent=main; crn(tb,18)
local tbf=Instance.new("Frame",tb)
tbf.Size=UDim2.new(1,0,0,16); tbf.Position=UDim2.new(0,0,1,-16)
tbf.BackgroundColor3=C.surface; tbf.BorderSizePixel=0; tbf.ZIndex = 5

local tbG = Instance.new("UIGradient")
tbG.Color = ColorSequence.new(C.accent, C.accent2)
tbG.Rotation = 90
tbG.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.6),
    NumberSequenceKeypoint.new(1, 0.95),
})
tbG.Parent = tb

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 44, 0, 44); logoIcon.Position = UDim2.new(0, 14, 0.5, -22)
logoIcon.BackgroundColor3 = C.bg2; logoIcon.Text = "⚡"
logoIcon.TextColor3 = C.accent; logoIcon.Font = Enum.Font.GothamBold
logoIcon.TextSize = 24; logoIcon.ZIndex = 6; logoIcon.Parent = tb
crn(logoIcon, 12); strk(logoIcon, C.accent, 1.5, 0.3)

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-160,0,22); titleLbl.Position=UDim2.new(0,68,0,13)
titleLbl.BackgroundTransparency=1; titleLbl.Text="Bin's Blox Fruits"
titleLbl.TextColor3=C.text; titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=16
titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex = 6; titleLbl.Parent=tb

local subLbl=Instance.new("TextLabel")
subLbl.Size=UDim2.new(1,-160,0,16); subLbl.Position=UDim2.new(0,68,0,32)
subLbl.BackgroundTransparency=1; subLbl.Text="v21 · "..player.Name
subLbl.TextColor3=C.sub; subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=11
subLbl.TextXAlignment=Enum.TextXAlignment.Left; subLbl.ZIndex = 6; subLbl.Parent=tb

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,34,0,34); closeBtn.Position=UDim2.new(1,-48,0.5,-17)
closeBtn.BackgroundColor3=C.surface2; closeBtn.Text="✕"; closeBtn.TextColor3=C.sub
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=15
closeBtn.AutoButtonColor=false; closeBtn.ZIndex = 6; closeBtn.Parent=tb
crn(closeBtn,10)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,0.15,{BackgroundColor3=C.red,TextColor3=Color3.fromRGB(255,255,255)}) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,0.15,{BackgroundColor3=C.surface2,TextColor3=C.sub}) end)

-- tabs
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,-36,0,42); tabBar.Position=UDim2.new(0,18,0,72)
tabBar.BackgroundColor3=C.bg2; tabBar.BorderSizePixel=0; tabBar.ZIndex = 5; tabBar.Parent=main
crn(tabBar,14)

local pill=Instance.new("Frame")
pill.Size=UDim2.new(1/7,-6,1,-10); pill.Position=UDim2.new(0,5,0,5)
pill.BackgroundColor3=C.accent; pill.BorderSizePixel=0; pill.ZIndex=6; pill.Parent=tabBar
crn(pill,10)
local pillG = Instance.new("UIGradient")
pillG.Color = ColorSequence.new(C.accent, C.accent3)
pillG.Rotation = 45
pillG.Parent = pill

local pages,tabs={},{}
local TN={"farm","boss","quest","stat","tp","visual","misc"}
local TL={"⚔","👑","📜","📊","🌀","👁","⚙"}

local function selTab(name)
    for _,n in ipairs(TN) do if tabs[n] then tabs[n].TextColor3=(n==name) and C.bg or C.sub end end
    local idx=1
    for i,n in ipairs(TN) do if n==name then idx=i; break end end
    tw(pill,0.25,{Position=UDim2.new((idx-1)/#TN,0,0,5)})
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
    b.Font=Enum.Font.GothamBold; b.TextSize=14; b.ZIndex=7; b.Parent=tabBar
    b.MouseButton1Click:Connect(function() selTab(name) end)
    tabs[name]=b
end

local ca=Instance.new("Frame")
ca.Size=UDim2.new(1,-36,1,-196); ca.Position=UDim2.new(0,18,0,130)
ca.BackgroundTransparency=1; ca.ClipsDescendants=true; ca.ZIndex = 5; ca.Parent=main
for _,name in ipairs(TN) do
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0); p.BackgroundTransparency=1
    p.BorderSizePixel=0; p.ScrollBarThickness=4
    p.ScrollBarImageColor3=C.accent; p.ScrollBarImageTransparency=0.3
    p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false; p.ZIndex = 6; p.Parent=ca
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
    f.Size=UDim2.new(1,0,0,26); f.BackgroundTransparency=1
    f.LayoutOrder=no(); f.ZIndex=6; f.Parent=parent
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,4,0,14); bar.Position=UDim2.new(0,0,0.5,-7)
    bar.BackgroundColor3=C.accent; bar.BorderSizePixel=0; bar.ZIndex=7; bar.Parent=f; crn(bar,2)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-20,1,0); l.Position=UDim2.new(0,14,0,0)
    l.BackgroundTransparency=1; l.Text=title; l.TextColor3=C.accent
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end
local function toggle(parent,name,desc,get,set)
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,56); c.BackgroundColor3=C.surface
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,12); strk(c,C.surface3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-110,0,20); l.Position=UDim2.new(0,18,0,10)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.text
    l.Font=Enum.Font.GothamBold; l.TextSize=13; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    if desc then
        local d=Instance.new("TextLabel")
        d.Size=UDim2.new(1,-110,0,16); d.Position=UDim2.new(0,18,0,30)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=C.sub
        d.Font=Enum.Font.Gotham; d.TextSize=11; d.ZIndex=7
        d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=c
    end
    local tr=Instance.new("Frame")
    tr.Size=UDim2.new(0,48,0,26); tr.Position=UDim2.new(1,-64,0.5,-13)
    tr.BackgroundColor3=C.surface3; tr.BorderSizePixel=0; tr.ZIndex=7; tr.Parent=c; crn(tr,13)
    local k=Instance.new("Frame")
    k.Size=UDim2.new(0,20,0,20); k.Position=UDim2.new(0,3,0.5,-10)
    k.BackgroundColor3=C.sub; k.BorderSizePixel=0; k.ZIndex=8; k.Parent=tr; crn(k,10)
    local hb=Instance.new("TextButton")
    hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=9; hb.Parent=c
    local function rf(a)
        local v=get()
        local i=TweenInfo.new(a and 0.2 or 0,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
        TweenService:Create(tr,i,{BackgroundColor3=v and C.green or C.surface3}):Play()
        TweenService:Create(k,i,{
            Position=v and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10),
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
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,12); strk(c,C.surface3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-100,0,20); l.Position=UDim2.new(0,18,0,10)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.text
    l.Font=Enum.Font.GothamBold; l.TextSize=13; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,90,0,20); vl.Position=UDim2.new(1,-108,0,10)
    vl.BackgroundTransparency=1
    vl.Text=string.format("%.2f",get())..suf
    vl.TextColor3=C.accent; vl.Font=Enum.Font.GothamBold; vl.TextSize=13
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.ZIndex=7; vl.Parent=c
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-36,0,8); bg.Position=UDim2.new(0,18,0,42)
    bg.BackgroundColor3=C.surface3; bg.BorderSizePixel=0; bg.ZIndex=7; bg.Parent=c; crn(bg,4)
    local fl=Instance.new("Frame")
    fl.Size=UDim2.new((get()-mn)/(mx-mn),0,1,0)
    fl.BackgroundColor3=C.accent; fl.BorderSizePixel=0; fl.ZIndex=8; fl.Parent=bg; crn(fl,4)
    local mi=Instance.new("TextButton")
    mi.Size=UDim2.new(0,36,0,22); mi.Position=UDim2.new(0,18,1,-30)
    mi.BackgroundColor3=C.surface2; mi.Text="−"; mi.TextColor3=C.text
    mi.Font=Enum.Font.GothamBold; mi.TextSize=14; mi.AutoButtonColor=false; mi.ZIndex=8; mi.Parent=c; crn(mi,6)
    local pl=Instance.new("TextButton")
    pl.Size=UDim2.new(0,36,0,22); pl.Position=UDim2.new(1,-54,1,-30)
    pl.BackgroundColor3=C.accent; pl.Text="+"; pl.TextColor3=C.bg
    pl.Font=Enum.Font.GothamBold; pl.TextSize=14; pl.AutoButtonColor=false; pl.ZIndex=8; pl.Parent=c; crn(pl,6)
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
    b.TextSize=13; b.AutoButtonColor=false; b.LayoutOrder=no(); b.ZIndex=6; b.Parent=parent
    crn(b,12)
    b.MouseButton1Click:Connect(function()
        local ok,err=pcall(cb2)
        if not ok then warn("[BF Hub] "..tostring(err)); notify("Error",tostring(err),C.red) end
    end)
end

-- FARM
section(pages.farm,"FARMING")
toggle(pages.farm,"Auto Farm Level","Any NPC",function() return state.autoFarmLevel end,function(v) state.autoFarmLevel=v end)
toggle(pages.farm,"Auto Farm Pirates","Prioritize pirates",function() return state.autoFarmPirates end,function(v) state.autoFarmPirates=v end)
toggle(pages.farm,"Auto Farm Marines","Prioritize marines",function() return state.autoFarmMarines end,function(v) state.autoFarmMarines=v end)
toggle(pages.farm,"Auto Farm Bosses","Prioritize bosses",function() return state.autoFarmBosses end,function(v) state.autoFarmBosses=v end)
section(pages.farm,"COMBAT (hitbox 40)")
slider(pages.farm,"Attack Speed",0.1,2.0,0.05,function() return state.attackSpeed end,function(v) state.attackSpeed=v end,"s")
slider(pages.farm,"Hover Height",3,15,1,function() return state.hoverHeight end,function(v) state.hoverHeight=v end," studs")
toggle(pages.farm,"Lock Camera","Force cam",function() return state.lockCamera end,function(v) state.lockCamera=v end)
toggle(pages.farm,"Kill Aura","Attack nearby",function() return state.killAura end,function(v) state.killAura=v end)
slider(pages.farm,"Kill Aura Range",10,300,5,function() return state.killAuraRange end,function(v) state.killAuraRange=v end," studs")
section(pages.farm,"FLY")
toggle(pages.farm,"Fly","WASD + Space/Ctrl",function() return state.fly end,function(v) state.fly=v end)
slider(pages.farm,"Fly Speed",10,400,5,function() return state.flySpeed end,function(v) state.flySpeed=v end,"")
section(pages.farm,"AUTO FISH")
toggle(pages.farm,"Auto Fish","Auto cast",function() return state.autoFish end,function(v) state.autoFish=v end)

-- BOSS PAGE
section(pages.boss,"BOSS TELEPORT")
local bLabel=Instance.new("TextLabel")
bLabel.Size=UDim2.new(1,0,0,26); bLabel.BackgroundColor3=C.surface
bLabel.BorderSizePixel=0; bLabel.LayoutOrder=no(); bLabel.Text="  Selected: Gorilla King (Lvl 100)"
bLabel.TextColor3=C.red; bLabel.Font=Enum.Font.GothamBold
bLabel.TextSize=13; bLabel.TextXAlignment=Enum.TextXAlignment.Left
crn(bLabel,10); strk(bLabel,C.red,1,0.4)
bLabel.ZIndex=7; bLabel.Parent=pages.boss
local bGrid=Instance.new("Frame")
bGrid.Size=UDim2.new(1,0,0,320); bGrid.BackgroundColor3=C.surface
bGrid.BorderSizePixel=0; bGrid.LayoutOrder=no(); bGrid.ZIndex=6; bGrid.Parent=pages.boss
crn(bGrid,12); strk(bGrid,C.surface3,1,0.5)
local bScroll=Instance.new("ScrollingFrame")
bScroll.Size=UDim2.new(1,-16,1,-16); bScroll.Position=UDim2.new(0,8,0,8)
bScroll.BackgroundTransparency=1; bScroll.BorderSizePixel=0
bScroll.ScrollBarThickness=4; bScroll.ScrollBarImageColor3=C.red
bScroll.CanvasSize=UDim2.new(0,0,0,0); bScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
bScroll.ZIndex=7; bScroll.Parent=bGrid
local bLay=Instance.new("UIListLayout",bScroll)
bLay.Padding=UDim.new(0,5); bLay.SortOrder=Enum.SortOrder.LayoutOrder
local bBtns={}
local selBossName = "Gorilla King"
local selBossPos = BOSSES[1].pos
local function selBoss(b)
    selBossName = b.name
    selBossPos = b.pos
    bLabel.Text = "  Selected: "..b.name.." (Lvl "..b.level..")"
    for n,btn in pairs(bBtns) do
        local a = (n==b.name)
        tw(btn,0.15,{BackgroundColor3=a and C.red or C.surface2,TextColor3=a and Color3.fromRGB(255,255,255) or C.text})
    end
end
for _,b in ipairs(BOSSES) do
    local b2=Instance.new("TextButton")
    b2.Size=UDim2.new(1,-6,0,32); b2.BackgroundColor3=C.surface2
    b2.Text="  👑  "..b.name.."  ·  Lvl "..b.level.."  ·  Sea "..b.sea
    b2.TextColor3=C.text; b2.Font=Enum.Font.Gotham
    b2.TextSize=12; b2.TextXAlignment=Enum.TextXAlignment.Left
    b2.AutoButtonColor=false; b2.ZIndex=8; b2.Parent=bScroll; crn(b2,8)
    b2.MouseButton1Click:Connect(function() selBoss(b) end)
    bBtns[b.name]=b2
end
selBoss(BOSSES[1])
action(pages.boss,"👑  TP to Selected Boss",function()
    tpTo(selBossPos)
    notify("Boss","TP to: "..selBossName, C.red)
end, C.red)
action(pages.boss,"👑  TP to Nearest Boss (auto)",function()
    local b = nearest("boss")
    if b then
        local hrp = b:FindFirstChild("HumanoidRootPart")
        if hrp then tpTo(hrp.Position); notify("Boss","Found: "..b.Name, C.red) end
    else notify("Boss","No boss nearby", C.red) end
end, C.surface2)

-- QUEST PAGE (с фиксом)
section(pages.quest,"AUTO QUEST")
toggle(pages.quest,"Auto Quest","Take + complete loop",function() return state.autoQuest end,function(v) state.autoQuest=v end)
local qLabel=Instance.new("TextLabel")
qLabel.Size=UDim2.new(1,0,0,26); qLabel.BackgroundColor3=C.surface
qLabel.BorderSizePixel=0; qLabel.LayoutOrder=no(); qLabel.Text="  Selected: Bandit (Lvl 1)"
qLabel.TextColor3=C.accent2; qLabel.Font=Enum.Font.GothamBold
qLabel.TextSize=13; qLabel.TextXAlignment=Enum.TextXAlignment.Left
crn(qLabel,10); strk(qLabel,C.accent2,1,0.4)
qLabel.ZIndex=7; qLabel.Parent=pages.quest
local qGrid=Instance.new("Frame")
qGrid.Size=UDim2.new(1,0,0,260); qGrid.BackgroundColor3=C.surface
qGrid.BorderSizePixel=0; qGrid.LayoutOrder=no(); qGrid.ZIndex=6; qGrid.Parent=pages.quest
crn(qGrid,12); strk(qGrid,C.surface3,1,0.5)
local qScroll=Instance.new("ScrollingFrame")
qScroll.Size=UDim2.new(1,-16,1,-16); qScroll.Position=UDim2.new(0,8,0,8)
qScroll.BackgroundTransparency=1; qScroll.BorderSizePixel=0
qScroll.ScrollBarThickness=4; qScroll.ScrollBarImageColor3=C.accent2
qScroll.CanvasSize=UDim2.new(0,0,0,0); qScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
qScroll.ZIndex=7; qScroll.Parent=qGrid
local qLay=Instance.new("UIListLayout",qScroll)
qLay.Padding=UDim.new(0,5); qLay.SortOrder=Enum.SortOrder.LayoutOrder
local qBtns={}
local function selQuest(name)
    state.selectedQuest=name
    local q=findQuest(name)
    if q then qLabel.Text="  Selected: "..q.name.." (Lvl "..q.level..")"; state.questLevel=q.level end
    for n,b in pairs(qBtns) do
        local a=(n==name)
        tw(b,0.15,{BackgroundColor3=a and C.accent2 or C.surface2,TextColor3=a and Color3.fromRGB(255,255,255) or C.text})
    end
end
for _,q in ipairs(QUESTS) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-6,0,32); b.BackgroundColor3=C.surface2
    b.Text="  📜  "..q.name.."  ·  Lvl "..q.level; b.TextColor3=C.text
    b.Font=Enum.Font.Gotham; b.TextSize=12; b.TextXAlignment=Enum.TextXAlignment.Left
    b.AutoButtonColor=false; b.ZIndex=8; b.Parent=qScroll; crn(b,8)
    b.MouseButton1Click:Connect(function() selQuest(q.name) end)
    qBtns[q.name]=b
end
selQuest(state.selectedQuest)
action(pages.quest,"📜  Start Selected Quest",function()
    local q=findQuest(state.selectedQuest)
    if q then
        tpTo(q.pos)
        task.wait(0.5)
        local ok = startQuest(q.npc, q.level)
        if ok then notify("Quest","Started: "..q.name, C.green)
        else notify("Quest","Не удалось. CommF_ не найден?", C.red) end
    end
end, C.accent2)

-- STAT
section(pages.stat,"AUTO STAT")
toggle(pages.stat,"Auto Stat","Auto allocate",function() return state.autoStat end,function(v) state.autoStat=v end)
local sLabel=Instance.new("TextLabel")
sLabel.Size=UDim2.new(1,0,0,26); sLabel.BackgroundColor3=C.surface
sLabel.BorderSizePixel=0; sLabel.LayoutOrder=no(); sLabel.Text="  Selected: Melee"
sLabel.TextColor3=C.accent; sLabel.Font=Enum.Font.GothamBold
sLabel.TextSize=13; sLabel.TextXAlignment=Enum.TextXAlignment.Left
crn(sLabel,10); strk(sLabel,C.accent,1,0.4)
sLabel.ZIndex=7; sLabel.Parent=pages.stat
local sGrid=Instance.new("Frame")
sGrid.Size=UDim2.new(1,0,0,50); sGrid.BackgroundColor3=C.surface
sGrid.BorderSizePixel=0; sGrid.LayoutOrder=no(); sGrid.ZIndex=6; sGrid.Parent=pages.stat
crn(sGrid,12); strk(sGrid,C.surface3,1,0.5)
local sLay=Instance.new("UIListLayout",sGrid)
sLay.FillDirection=Enum.FillDirection.Horizontal
sLay.Padding=UDim.new(0,4)
sLay.HorizontalAlignment=Enum.HorizontalAlignment.Center
sLay.VerticalAlignment=Enum.VerticalAlignment.Center
sLay.SortOrder=Enum.SortOrder.LayoutOrder
local statBtns={}
local function selStat(name)
    state.selectedStat=name
    sLabel.Text="  Selected: "..name
    for n,b in pairs(statBtns) do
        local a=(n==name)
        tw(b,0.15,{BackgroundColor3=a and C.accent or C.surface2,TextColor3=a and C.bg or C.text})
    end
end
for _,sname in ipairs(STAT_NAMES) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,86,0,34); b.BackgroundColor3=C.surface2
    b.Text=sname; b.TextColor3=C.text; b.Font=Enum.Font.GothamBold
    b.TextSize=10; b.AutoButtonColor=false; b.ZIndex=8; b.Parent=sGrid; crn(b,8)
    b.MouseButton1Click:Connect(function() selStat(sname) end)
    statBtns[sname]=b
end
selStat(state.selectedStat)
section(pages.stat,"AUTO FRUIT MASTERY")
toggle(pages.stat,"Auto Fruit Mastery","Spam skills",function() return state.autoFruitMastery end,function(v) state.autoFruitMastery=v end)

-- TP (города)
section(pages.tp,"CITIES / SEARCH")
local sf=Instance.new("Frame")
sf.Size=UDim2.new(1,0,0,38); sf.BackgroundColor3=C.surface
sf.BorderSizePixel=0; sf.LayoutOrder=no(); sf.ZIndex=6; sf.Parent=pages.tp
crn(sf,12); strk(sf,C.surface3,1,0.5)
local sb=Instance.new("TextBox")
sb.Size=UDim2.new(1,-32,1,-8); sb.Position=UDim2.new(0,16,0,4)
sb.BackgroundTransparency=1; sb.Text=""; sb.PlaceholderText="🔍 search city..."
sb.PlaceholderColor3=C.dim; sb.TextColor3=C.text
sb.Font=Enum.Font.Gotham; sb.TextSize=12; sb.ZIndex=7
sb.TextXAlignment=Enum.TextXAlignment.Left; sb.ClearTextOnFocus=false; sb.Parent=sf

local locContainer=Instance.new("Frame")
locContainer.Size=UDim2.new(1,0,0,280); locContainer.BackgroundColor3=C.surface
locContainer.BorderSizePixel=0; locContainer.LayoutOrder=no(); locContainer.ZIndex=6; locContainer.Parent=pages.tp
crn(locContainer,12); strk(locContainer,C.surface3,1,0.5)
local locList=Instance.new("ScrollingFrame")
locList.Size=UDim2.new(1,-16,1,-16); locList.Position=UDim2.new(0,8,0,8)
locList.BackgroundTransparency=1; locList.BorderSizePixel=0
locList.ScrollBarThickness=4; locList.ScrollBarImageColor3=C.accent
locList.CanvasSize=UDim2.new(0,0,0,0); locList.AutomaticCanvasSize=Enum.AutomaticSize.Y
locList.ZIndex=7; locList.Parent=locContainer
local locLay=Instance.new("UIListLayout",locList)
locLay.Padding=UDim.new(0,5); locLay.SortOrder=Enum.SortOrder.LayoutOrder

local locBtns={}
local function selCity(name)
    state.selectedTP=name
    for n,b in pairs(locBtns) do
        local a=(n==name)
        tw(b,0.15,{BackgroundColor3=a and C.accent or C.surface2,TextColor3=a and C.bg or C.text})
    end
end
local function rebuildLoc(f)
    for _,c in ipairs(locList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    locBtns={}; f=(f or ""):lower()
    for _,l in ipairs(CITIES) do
        if f=="" or l.name:lower():find(f,1,true) then
            local b=Instance.new("TextButton")
            b.Size=UDim2.new(1,-6,0,32); b.BackgroundColor3=C.surface2
            b.Text="  🌍  "..l.name.."   [Sea "..l.sea.."]"
            b.TextColor3=C.text; b.Font=Enum.Font.Gotham; b.TextSize=12
            b.TextXAlignment=Enum.TextXAlignment.Left; b.AutoButtonColor=false
            b.ZIndex=8; b.Parent=locList; crn(b,8)
            b.MouseButton1Click:Connect(function() selCity(l.name) end)
            locBtns[l.name]=b
        end
    end
    selCity(state.selectedTP)
end
rebuildLoc("")
sb:GetPropertyChangedSignal("Text"):Connect(function() rebuildLoc(sb.Text) end)
action(pages.tp,"✨  TP to Selected City",function()
    local l=findCity(state.selectedTP)
    if l then tpTo(l.pos); notify("City","Warped: "..l.name,C.accent) end
end,C.accent)
action(pages.tp,"🛑  Stop Hover",function()
    if hoverTarget then restoreHitbox(hoverTarget) end
    setHover(nil); notify("Hover","Off",C.red)
end,C.surface2)
section(pages.tp,"AUTO CHEST")
toggle(pages.tp,"Auto Chest","Smart TP to chests",function() return state.autoChest end,function(v) state.autoChest=v end)
slider(pages.tp,"Chest Range",100,5000,50,function() return state.chestRange end,function(v) state.chestRange=v end," studs")
action(pages.tp,"📦  Scan Chests (show coords)",function()
    local r = getRoot(); if not r then return end
    local cnt = 0
    for o in pairs(chestCache) do
        local pp = o:IsA("Model") and (o:FindFirstChild("Handle") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
        if pp and pp.Position then
            cnt = cnt + 1
            if cnt <= 3 then
                notify("Chest #"..cnt, string.format("X:%.0f Y:%.0f Z:%.0f", pp.Position.X, pp.Position.Y, pp.Position.Z), C.green)
            end
        end
    end
    notify("Scan", "Найдено сундуков: "..cnt, C.accent)
end, C.green)

-- VISUAL
section(pages.visual,"ESP")
toggle(pages.visual,"ESP NPCs","Boxes over enemies",function() return state.espNPCs end,function(v) state.espNPCs=v end)
toggle(pages.visual,"ESP Players","Boxes over players",function() return state.espPlayers end,function(v) state.espPlayers=v end)

-- MISC
section(pages.misc,"INFO")
action(pages.misc,"🔄  Refresh NPC Cache",function() refresh(); notify("Cache","Refreshed: "..#npcCache,C.green) end,C.surface2)
local infoCard=Instance.new("Frame")
infoCard.Size=UDim2.new(1,0,0,120); infoCard.BackgroundColor3=C.surface
infoCard.BorderSizePixel=0; infoCard.LayoutOrder=no(); infoCard.ZIndex=6; infoCard.Parent=pages.misc
crn(infoCard,12); strk(infoCard,C.surface3,1,0.5)
local infoT=Instance.new("TextLabel")
infoT.Size=UDim2.new(1,-20,1,-16); infoT.Position=UDim2.new(0,16,0,8)
infoT.BackgroundTransparency=1
infoT.Text="Bin's Blox Fruits Hub v21 BETA\nkey: h00x · hitbox 40×40×40\n\nCities: "..#CITIES.."  Bosses: "..#BOSSES.."  Quests: "..#QUESTS.."\nmade by Bin & Steve · nya~"
infoT.TextColor3=C.sub; infoT.Font=Enum.Font.Gotham; infoT.TextSize=12
infoT.TextXAlignment=Enum.TextXAlignment.Left
infoT.TextYAlignment=Enum.TextYAlignment.Top
infoT.TextWrapped=true; infoT.ZIndex=7; infoT.Parent=infoCard

-- FOOTER
local ft=Instance.new("Frame")
ft.Size=UDim2.new(1,-36,0,32); ft.Position=UDim2.new(0,18,1,-46)
ft.BackgroundColor3=C.bg2; ft.BorderSizePixel=0; ft.ZIndex=5; ft.Parent=main; crn(ft,10)
local ftL=Instance.new("TextLabel")
ftL.Size=UDim2.new(1,-24,1,0); ftL.Position=UDim2.new(0,14,0,0)
ftL.BackgroundTransparency=1
ftL.Text="made by Bin & Steve  ·  nya~"
ftL.TextColor3=C.dim; ftL.Font=Enum.Font.Gotham; ftL.TextSize=11
ftL.TextXAlignment=Enum.TextXAlignment.Left; ftL.ZIndex=6; ftL.Parent=ft

-- TOGGLE
local isOpen=false
local function tglW()
    isOpen=not isOpen
    if isOpen then
        main.Visible=true
        main.Size=UDim2.new(0,WW*0.9,0,WH*0.9)
        main.BackgroundTransparency=0.2
        tw(main,0.3,{Size=UDim2.new(0,WW,0,WH),BackgroundTransparency=0})
    else
        tw(main,0.2,{Size=UDim2.new(0,WW*0.9,0,WH*0.9),BackgroundTransparency=0.3})
        task.wait(0.2)
        main.Visible=false
        main.Size=UDim2.new(0,WW,0,WH); main.BackgroundTransparency=0
    end
end

-- ждём ввод ключа → показываем UI
task.spawn(function()
    while not keyOk do task.wait(0.3) end
    ob.Visible = true
    pCard.Visible = true
    pCard.Position = UDim2.new(0, 18, 1, -30)
    pCard.BackgroundTransparency = 1
    task.wait(0.1)
    tw(pCard, 0.4, {Position = UDim2.new(0, 18, 1, -90), BackgroundTransparency = 0.1})
    task.wait(0.6)
    notify("✓ Ready", "Нажми ⚡ BF HUB сверху слева", C.accent)
end)

ob.MouseButton1Click:Connect(function() if keyOk then tglW() end end)
closeBtn.MouseButton1Click:Connect(tglW)

-- drag main by title
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
end

print("[Bin's Hub v21] loaded. key: h00x")
