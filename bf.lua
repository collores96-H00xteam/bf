local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local VI=nil
pcall(function() VI=game:GetService("VirtualInputManager") end)
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui",30)
local cam=workspace.CurrentCamera
local char,root,hum
local function bind(c)
    if not c then return end
    char=c
    root=c:WaitForChild("HumanoidRootPart",15)
    hum=c:WaitForChild("Humanoid",15)
end
if player.Character then bind(player.Character) end
player.CharacterAdded:Connect(bind)
local ww=0
while (not char or not root or not hum) and ww<60 do
    task.wait(0.5); ww=ww+0.5
    if player.Character then bind(player.Character) end
end
local function gr()
    if not char or not char.Parent then
        if player.Character and player.Character.Parent then bind(player.Character) end
    end
    if not root or not root.Parent then return nil end
    return root
end
local function gy(x,z,y)
    local ok,res=pcall(function()
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances=char and {char} or {}
        rp.IgnoreWater=false
        return workspace:Raycast(Vector3.new(x,y or 500,z),Vector3.new(0,-1000,0),rp)
    end)
    if ok and res then return res.Position.Y end
    return nil
end
local function tp(pos)
    local r=gr(); if not r then return false end
    local Y=gy(pos.X,pos.Z,pos.Y+500) or pos.Y
    pcall(function() r.CFrame=CFrame.new(pos.X,Y+3.5,pos.Z) end)
    return true
end
local function tpo(o)
    if not o then return false end
    local p=o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
    if p and p.Position then return tp(p.Position) end
    return false
end
local function getRem()
    local r=RS:FindFirstChild("Remotes")
    return r and (r:FindFirstChild("CommF_") or r:FindFirstChild("CommE_")) or nil
end

-- ============================================================
-- STATE
-- ============================================================
local S={
    farmLevel=false,farmPirates=false,farmMarines=false,farmBosses=false,
    speed=0.25, hover=6, killAura=false, auraRange=45,
    autoChest=false, chestRange=3000,
    autoStat=false, statName="Melee",
    autoFruit=false, fruitName="Dragon",
    autoQuest=false, questName="Bandit",
    autoMastery=false,
    fly=false, flySpeed=120, lockCam=true,
    espNPC=false, espPlayer=false,
    autoFish=false,
    selTP="Pirate Island", selBoss="Gorilla King",
}

-- HITBOX 40
local HB=40
local orig=setmetatable({},{__mode="k"})
local function addHB(npc)
    if not npc then return end
    local h=npc:FindFirstChild("HumanoidRootPart")
    if not h then return end
    if not orig[h] then orig[h]={s=h.Size,t=h.Transparency,c=h.CanCollide,m=h.Massless} end
    pcall(function()
        h.Size=Vector3.new(HB,HB,HB)
        h.Transparency=1; h.CanCollide=false; h.Massless=true
        h.CanQuery=true; h.CanTouch=true
    end)
end
local function rmHB(npc)
    if not npc then return end
    local h=npc:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local o=orig[h]
    if o then
        pcall(function()
            h.Size=o.s; h.Transparency=o.t
            h.CanCollide=o.c; h.Massless=o.m
        end)
        orig[h]=nil
    end
end
local hoverT,hoverA=nil,false
local function setHover(npc)
    if hoverA and hoverT and hoverT~=npc then rmHB(hoverT) end
    hoverT=npc
    hoverA=npc~=nil
    if hum then pcall(function() hum.PlatformStand=hoverA end) end
    if hoverA and npc then addHB(npc) end
end
RunService.Heartbeat:Connect(function()
    if not (hoverA and hoverT and hoverT.Parent) then return end
    if S.fly then return end
    local r=gr()
    local h=hoverT:FindFirstChild("HumanoidRootPart")
    local hm=hoverT:FindFirstChild("Humanoid")
    if not (r and h and hm and hm.Health>0) then
        rmHB(hoverT); hoverA=false; hoverT=nil
        if hum then pcall(function() hum.PlatformStand=false end) end
        return
    end
    local t=h.Position
    pcall(function() r.CFrame=CFrame.lookAt(Vector3.new(t.X,t.Y+S.hover,t.Z),t) end)
    pcall(function() r.Velocity=Vector3.new(0,0,0) end)
    if S.lockCam and cam then
        pcall(function() cam.CFrame=CFrame.lookAt(cam.CFrame.Position,t) end)
    end
end)

-- FLY
local flyCon=nil
local function startFly()
    local r=gr(); if not r or not hum then return end
    pcall(function() hum.PlatformStand=true end)
    pcall(function() hum.WalkSpeed=0; hum.JumpPower=0 end)
    if flyCon then flyCon:Disconnect() end
    flyCon=RunService.RenderStepped:Connect(function(dt)
        if not S.fly then return end
        local rr=gr(); if not rr then return end
        local c=workspace.CurrentCamera; if not c then return end
        local mv=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
        if mv.Magnitude>0 then mv=mv.Unit*S.flySpeed*dt end
        pcall(function() rr.CFrame=rr.CFrame+mv; rr.Velocity=Vector3.new(0,0,0) end)
    end)
end
local function stopFly()
    if flyCon then flyCon:Disconnect(); flyCon=nil end
    if hum then
        pcall(function() hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end)
    end
end
task.spawn(function()
    local last=false
    while task.wait(0.1) do
        if S.fly and not last then startFly() end
        if not S.fly and last then stopFly() end
        last=S.fly
    end
end)

-- ============================================================
-- AUTO STAT — с проверкой поинтов
-- ============================================================
local function getStatPoints()
    local ok, pts = pcall(function()
        local d = player:FindFirstChild("Data")
        if d then
            local s = d:FindFirstChild("Stats")
            if s then
                local p = s:FindFirstChild("Points")
                if p then return p.Value end
            end
        end
        return nil
    end)
    return ok and pts or nil
end

local lastStatWarn = 0
task.spawn(function()
    while task.wait(1.5) do
        if S.autoStat then
            local pts = getStatPoints()
            if pts and pts > 0 then
                local r=getRem()
                if r then
                    for i=1, math.min(pts, 5) do
                        pcall(function() r:InvokeServer("AddPoint",S.statName,1) end)
                    end
                end
            else
                -- нет поинтов — предупреждаем раз в 10 сек
                if tick() - lastStatWarn > 10 then
                    lastStatWarn = tick()
                    -- тихо, не спамим
                end
            end
        end
    end
end)

-- AUTO MASTERY
task.spawn(function()
    while task.wait(0.5) do
        if S.autoMastery and VI then
            for _,k in ipairs({"Z","X","C","V"}) do
                pcall(function()
                    VI:SendKeyEvent(true,Enum.KeyCode[k],false,game)
                    task.wait(0.03)
                    VI:SendKeyEvent(false,Enum.KeyCode[k],false,game)
                end)
            end
        end
    end
end)

-- CITIES
local CITIES={
    {n="Bandit Camp",p=Vector3.new(-1110,20,3200),s=1},
    {n="Pirate Village",p=Vector3.new(-1200,20,3400),s=1},
    {n="Marine Fort",p=Vector3.new(-2800,20,4300),s=1},
    {n="Jungle",p=Vector3.new(-1600,20,200),s=1},
    {n="Marine Ford",p=Vector3.new(-2760,20,4320),s=1},
    {n="Fountain City",p=Vector3.new(-1250,20,3200),s=1},
    {n="Pirate Island",p=Vector3.new(1000,20,1200),s=1},
    {n="First Sea Port",p=Vector3.new(400,20,400),s=1},
    {n="Colosseum",p=Vector3.new(-1500,20,200),s=1},
    {n="Desert",p=Vector3.new(1000,20,4500),s=1},
    {n="Snow Island",p=Vector3.new(1250,20,-1500),s=1},
    {n="Skylands",p=Vector3.new(-500,800,-1500),s=1},
    {n="Prison",p=Vector3.new(5000,20,800),s=1},
    {n="Kingdom of Rose",p=Vector3.new(-400,20,6000),s=2},
    {n="Green Zone",p=Vector3.new(-3500,20,-4500),s=2},
    {n="Graveyard",p=Vector3.new(-5500,20,-3000),s=2},
    {n="Snow Mountain",p=Vector3.new(-1500,20,-5500),s=2},
    {n="Cursed Ship",p=Vector3.new(9000,20,5000),s=2},
    {n="Ice Castle",p=Vector3.new(-6000,20,-6000),s=2},
    {n="Forgotten Island",p=Vector3.new(-3000,20,-8000),s=2},
    {n="Port Town",p=Vector3.new(-500,20,-10000),s=3},
    {n="Hydra Island",p=Vector3.new(5000,20,-9000),s=3},
    {n="Great Tree",p=Vector3.new(-3000,20,-12000),s=3},
    {n="Floating Turtle",p=Vector3.new(-9000,20,-10000),s=3},
    {n="Haunted Castle",p=Vector3.new(3000,20,-12000),s=3},
    {n="Castle on the Sea",p=Vector3.new(-6000,20,-14000),s=3},
    {n="Sea of Treats",p=Vector3.new(5000,20,-15000),s=3},
}
local BOSSES={
    {n="Gorilla King",lv=100,p=Vector3.new(-1170,20,3200)},
    {n="Bobby",lv=150,p=Vector3.new(-1200,20,3400)},
    {n="Yeti",lv=200,p=Vector3.new(1300,20,-1600)},
    {n="Mob Leader",lv=300,p=Vector3.new(-1500,20,300)},
    {n="Vice Admiral",lv=375,p=Vector3.new(-2800,20,4300)},
    {n="Saber Expert",lv=500,p=Vector3.new(-1500,20,200)},
    {n="Cyborg",lv=650,p=Vector3.new(-2800,20,4320)},
    {n="Diamond",lv=750,p=Vector3.new(-400,20,6000)},
    {n="Jeremy",lv=850,p=Vector3.new(-3600,20,-4500)},
    {n="Smoke Admiral",lv=1000,p=Vector3.new(-6000,20,-6000)},
    {n="Yellow Beard",lv=1100,p=Vector3.new(-500,20,-10000)},
    {n="Cursed Captain",lv=1250,p=Vector3.new(3000,20,-12000)},
    {n="Soul Reaper",lv=1400,p=Vector3.new(-3000,20,-12000)},
    {n="Cake Queen",lv=1700,p=Vector3.new(5000,20,-15000)},
    {n="Dough King",lv=2000,p=Vector3.new(-9000,20,-10000)},
}
local QUESTS={
    {n="Bandit",lv=1,p=Vector3.new(-1143,20,3140),npc="Bandit"},
    {n="Monkey",lv=15,p=Vector3.new(-1594,20,200),npc="Monkey"},
    {n="Blade Master",lv=25,p=Vector3.new(-1449,20,127),npc="Blade Master"},
    {n="Brute",lv=40,p=Vector3.new(-1140,20,1520),npc="Brute"},
    {n="Pirate",lv=60,p=Vector3.new(-1200,20,3400),npc="Pirate"},
    {n="Marine",lv=90,p=Vector3.new(-2800,20,4300),npc="Marine"},
    {n="Snow Bandit",lv=120,p=Vector3.new(1250,20,-1500),npc="Snow Bandit"},
    {n="Sky Bandit",lv=180,p=Vector3.new(-500,800,-1500),npc="Sky Bandit"},
    {n="Raider",lv=375,p=Vector3.new(-400,20,6000),npc="Raider"},
    {n="Mercenary",lv=450,p=Vector3.new(-3600,20,-4500),npc="Mercenary"},
    {n="Zombie",lv=550,p=Vector3.new(-5500,20,-3000),npc="Zombie"},
}
local function startQ(npc,lv)
    local r=getRem()
    if not r then return false end
    return pcall(function() r:InvokeServer("StartQuest",npc,lv) end)
end

-- NPC cache
local cache={}
local KW={
    boss={"Boss","Lord","King","Queen","Admiral","Warden","Diamond","Cyborg"},
    pirate={"Pirate","Bandit","Brute","Thief","Criminal","Rogue","Buccaneer","Smoker","Clown","Raider","Mercenary","Zombie"},
    marine={"Marine","Soldier","Officer","Captain","Vice","Commander","Guard","Sword"},
}
local function match(n,l) for _,k in ipairs(l) do if n:find(k) then return true end end return false end
local function scan(c,o)
    if not c then return end
    local ok,ch=pcall(function() return c:GetChildren() end); if not ok then return end
    for _,x in ipairs(ch) do
        if x:IsA("Model") and x:FindFirstChild("Humanoid") and x:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(x) then
            local h=x.Humanoid
            if h and h.Health>0 then
                local t="other"
                if match(x.Name,KW.boss) then t="boss"
                elseif match(x.Name,KW.pirate) then t="pirate"
                elseif match(x.Name,KW.marine) then t="marine" end
                table.insert(o,{model=x,tag=t})
            end
        end
    end
end
local function refresh()
    local nc={}
    local ef=workspace:FindFirstChild("Enemies")
    if ef then scan(ef,nc) end
    if #nc==0 then scan(workspace,nc) end
    cache=nc
end
task.spawn(function() while task.wait(1) do pcall(refresh) end end)
local function nearest(tag)
    local r=gr(); if not r then return nil end
    local p=r.Position; local best,bd=nil,math.huge
    for _,e in ipairs(cache) do
        if tag=="all" or e.tag==tag then
            local h=e.model:FindFirstChild("HumanoidRootPart")
            if h then
                local d=(h.Position-p).Magnitude
                if d<bd then bd=d; best=e.model end
            end
        end
    end
    return best
end
local function attack(npc)
    if not npc or not npc.Parent then return end
    local h=npc:FindFirstChild("HumanoidRootPart")
    local hm=npc:FindFirstChild("Humanoid")
    if not h or not hm or hm.Health<=0 then return end
    local r=gr()
    if r then pcall(function() r.CFrame=CFrame.lookAt(r.Position,h.Position) end) end
    local tool
    if char then tool=char:FindFirstChildOfClass("Tool") end
    if tool and hum then pcall(function() hum:EquipTool(tool) end) end
    if cam then pcall(function() cam.CFrame=CFrame.lookAt(cam.CFrame.Position,h.Position) end) end
    if VI and cam then
        local v=cam.ViewportSize
        pcall(function()
            VI:SendMouseButtonEvent(v.X/2,v.Y/2,0,true,game,1)
            task.wait(0.02)
            VI:SendMouseButtonEvent(v.X/2,v.Y/2,0,false,game,1)
        end)
    end
    if tool then pcall(function() tool:Activate() end) end
    if VI then
        for _,k in ipairs({"Z","X","C","V"}) do
            pcall(function()
                VI:SendKeyEvent(true,Enum.KeyCode[k],false,game)
                task.wait(0.02)
                VI:SendKeyEvent(false,Enum.KeyCode[k],false,game)
            end)
        end
    end
    if tool then pcall(function() tool:Activate() end) end
end
local PRIO={
    {g=function() return S.farmBosses end,t="boss"},
    {g=function() return S.farmMarines end,t="marine"},
    {g=function() return S.farmPirates end,t="pirate"},
    {g=function() return S.farmLevel end,t="all"},
}
task.spawn(function()
    while true do
        local act=false
        for _,p in ipairs(PRIO) do
            if p.g() or S.autoQuest or S.autoMastery then
                act=true
                local n=nearest(p.t)
                if n then setHover(n); pcall(attack,n) end
                break
            end
        end
        if not act and not S.fly then setHover(nil) end
        task.wait(act and S.speed or 0.2)
    end
end)
task.spawn(function()
    while task.wait(0.2) do
        if S.killAura then
            local r=gr()
            if r then
                for _,e in ipairs(cache) do
                    local h=e.model:FindFirstChild("HumanoidRootPart")
                    if h and (h.Position-r.Position).Magnitude<=S.auraRange then
                        pcall(attack,e.model)
                    end
                end
            end
        end
    end
end)

-- AUTO QUEST
task.spawn(function()
    while task.wait(1.5) do
        if S.autoQuest then
            for _,q in ipairs(QUESTS) do
                if q.n==S.questName then
                    local r=gr()
                    if r then
                        if (r.Position-q.p).Magnitude>30 then tp(q.p); task.wait(1) end
                        startQ(q.npc,q.lv)
                        task.wait(0.5)
                    end
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- CHESTS — прямое сканирование Enemies + workspace
-- ============================================================
local chests={}
local function cc(o)
    pcall(function()
        if not (o:IsA("Model") or o:IsA("BasePart")) then return end
        local n=o.Name:lower()
        -- Blox Fruits: Chest, CommonChest, RareChest, LegendaryChest, MythicalChest, ChestRandom
        if n:find("chest") or n:find("crate") or n:find("barrel") or n:find("treasure") then
            chests[o]=true
        end
    end)
end
pcall(function()
    -- сканируем Enemies отдельно
    local ef=workspace:FindFirstChild("Enemies")
    if ef then
        for _,o in ipairs(ef:GetDescendants()) do cc(o) end
    end
    for _,o in ipairs(workspace:GetDescendants()) do cc(o) end
end)
workspace.DescendantAdded:Connect(function(o)
    if o:IsA("Model") or o:IsA("BasePart") then cc(o) end
end)
task.spawn(function()
    while task.wait(5) do
        for o in pairs(chests) do if not o.Parent then chests[o]=nil end end
    end
end)
-- резервное сканирование если кэш пуст
local function rescanChests()
    local ef=workspace:FindFirstChild("Enemies")
    if ef then
        for _,o in ipairs(ef:GetChildren()) do
            if o.Name:lower():find("chest") then cc(o) end
        end
    end
end
task.spawn(function()
    while task.wait(0.4) do
        if S.autoChest then
            local r=gr()
            if r then
                -- если кэш пуст — обновим
                local cnt=0
                for _ in pairs(chests) do cnt=cnt+1; if cnt>0 then break end end
                if cnt==0 then rescanChests() end

                local mp=r.Position
                local best,bd=nil,S.chestRange
                for o in pairs(chests) do
                    local p=o:IsA("Model") and (o:FindFirstChild("Handle") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
                    if p and p.Position then
                        local d=(p.Position-mp).Magnitude
                        if d<bd then bd=d; best=p end
                    end
                end
                if best then
                    tp(best.Position)
                    task.wait(0.15)
                end
            end
        end
        if S.autoFruit then
            local o=findFruit(S.fruitName)
            if o then tpo(o); task.wait(0.3) end
        end
    end
end)

-- FRUITS
local FRUITS={"Dragon","Leopard","Kitsune","Dough","Venom","Shadow","Control","Spirit","Mammoth","T-Rex","Gas","Portal","Buddha","Phoenix","Gravity","Rumble","Magma","Ice","Light","Dark","Rubber","Sand","Diamond","Barrier","Door","Chop","Spring","Bomb","Spike","Flame","Falcon","Blade","Ghost","Rocket","Spin","Smoke","Revive","Love","Spider","Sound","Creation","Pain","Blizzard"}
local function findFruit(name)
    if not name or name=="" then return nil end
    local k=name:lower()
    local r=gr(); if not r then return nil end
    local mp=r.Position
    local best,bd=nil,math.huge
    local ok,ds=pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for _,o in ipairs(ds) do
        if o:IsA("Tool") or o:IsA("Model") or o:IsA("BasePart") then
            if o.Name:lower():find(k,1,true) then
                local p=o:IsA("Model") and (o:FindFirstChild("Handle") or o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart) or o
                if p and p.Position then
                    local d=(p.Position-mp).Magnitude
                    if d<bd then bd=d; best=o end
                end
            end
        end
    end
    return best
end

-- FISH
local function findRod()
    if not char then return nil end
    local ok,ch=pcall(function() return char:GetChildren() end)
    if not ok then return nil end
    for _,t in ipairs(ch) do
        if t:IsA("Tool") and (t.Name:lower():find("rod") or t.Name:lower():find("fishing")) then return t end
    end
    return nil
end
task.spawn(function()
    local fish=false
    while task.wait(0.3) do
        if S.autoFish and not fish then
            fish=true
            task.spawn(function()
                while S.autoFish do
                    local rod=findRod()
                    if rod and hum and hum.Parent then
                        pcall(function() hum:EquipTool(rod) end)
                        task.wait(0.6)
                        pcall(function() rod:Activate() end)
                        task.wait(math.random(30,80)/10)
                        pcall(function() rod:Activate() end)
                        task.wait(1.5)
                    else task.wait(1) end
                end
                fish=false
            end)
        end
    end
end)

-- ESP
local ef=Instance.new("Folder"); ef.Name="BinESP"; ef.Parent=workspace
local function mkESP(ad,col,txt)
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,100,0,30); bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true; bb.Adornee=ad; bb.Parent=ef
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=col; l.TextStrokeTransparency=0
    l.Font=Enum.Font.GothamBold; l.TextSize=12; l.Parent=bb
    local b=Instance.new("SelectionBox")
    b.Adornee=ad; b.Color3=col; b.LineThickness=0.05
    b.Transparency=0.5; b.Parent=ef
    return {bb=bb,bx=b,lbl=l,ad=ad}
end
local function kESP(e) if e.bb then e.bb:Destroy() end if e.bx then e.bx:Destroy() end end
local nESP,pESP={},{}
task.spawn(function()
    while task.wait(0.5) do
        if S.espNPC then
            local seen={}
            for _,e in ipairs(cache) do
                local h=e.model:FindFirstChild("HumanoidRootPart")
                if h then
                    seen[e.model]=true
                    local col=e.tag=="boss" and Color3.fromRGB(255,80,80)
                             or e.tag=="pirate" and Color3.fromRGB(255,170,70)
                             or e.tag=="marine" and Color3.fromRGB(100,160,250)
                             or Color3.fromRGB(200,200,200)
                    local en=nESP[e.model]
                    if en and en.bb.Parent then
                        if en.ad~=h then en.bb.Adornee=h; en.bx.Adornee=h; en.ad=h end
                        en.lbl.Text=e.model.Name; en.lbl.TextColor3=col; en.bx.Color3=col
                    else nESP[e.model]=mkESP(h,col,e.model.Name) end
                end
            end
            for m,en in pairs(nESP) do if not seen[m] then kESP(en); nESP[m]=nil end end
        else
            for m,en in pairs(nESP) do kESP(en); nESP[m]=nil end
        end
        if S.espPlayer then
            local seen={}
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=player and pl.Character then
                    local h=pl.Character:FindFirstChild("HumanoidRootPart")
                    if h then
                        seen[pl]=true
                        local en=pESP[pl]
                        if en and en.bb.Parent then
                            if en.ad~=h then en.bb.Adornee=h; en.bx.Adornee=h; en.ad=h end
                        else pESP[pl]=mkESP(h,Color3.fromRGB(85,225,145),pl.Name) end
                    end
                end
            end
            for pl,en in pairs(pESP) do if not seen[pl] then kESP(en); pESP[pl]=nil end end
        else
            for pl,en in pairs(pESP) do kESP(en); pESP[pl]=nil end
        end
    end
end)

-- ============================================================
-- UI — ТАБЫ СЛЕВА ВЕРТИКАЛЬНО
-- ============================================================
local C={
    bg=Color3.fromRGB(10,14,26), bg2=Color3.fromRGB(16,22,40),
    surf=Color3.fromRGB(24,32,56), surf2=Color3.fromRGB(38,48,80),
    surf3=Color3.fromRGB(58,68,110),
    acc=Color3.fromRGB(0,200,255), acc2=Color3.fromRGB(120,100,255),
    acc3=Color3.fromRGB(0,255,180), grn=Color3.fromRGB(90,240,180),
    red=Color3.fromRGB(255,90,120), txt=Color3.fromRGB(240,245,255),
    sub=Color3.fromRGB(140,160,200), dim=Color3.fromRGB(70,85,130),
}
local sg=Instance.new("ScreenGui")
sg.Name="BinHubV23"; sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=pg
local function tw(o,t,p) TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end
local function crn(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p; return c end
local function strk(p,c,t,tr)
    local s=Instance.new("UIStroke"); s.Color=c; s.Thickness=t or 1
    s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

-- NOTIF
local nh=Instance.new("Frame")
nh.Size=UDim2.new(0,280,1,-40); nh.Position=UDim2.new(1,-300,0,20)
nh.BackgroundTransparency=1; nh.Parent=sg
local nll=Instance.new("UIListLayout",nh)
nll.Padding=UDim.new(0,8); nll.SortOrder=Enum.SortOrder.LayoutOrder
local function notify(t,x,col)
    col=col or C.acc
    local b=Instance.new("Frame")
    b.Size=UDim2.new(1,0,0,56); b.BackgroundColor3=C.surf
    b.BackgroundTransparency=0.08; b.BorderSizePixel=0; b.Parent=nh
    crn(b,12); strk(b,col,1.5,0.4)
    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-20,0,20); lb.Position=UDim2.new(0,16,0,8)
    lb.BackgroundTransparency=1; lb.Text=t; lb.TextColor3=col
    lb.Font=Enum.Font.GothamBold; lb.TextSize=13
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=b
    local ld=Instance.new("TextLabel")
    ld.Size=UDim2.new(1,-20,0,18); ld.Position=UDim2.new(0,16,0,28)
    ld.BackgroundTransparency=1; ld.Text=x; ld.TextColor3=C.sub
    ld.Font=Enum.Font.Gotham; ld.TextSize=11
    ld.TextXAlignment=Enum.TextXAlignment.Left; ld.Parent=b
    b.Position=UDim2.new(1,40,0,0)
    tw(b,0.35,{Position=UDim2.new(0,0,0,0)})
    task.delay(3,function()
        tw(b,0.35,{Position=UDim2.new(1,40,0,0),BackgroundTransparency=1})
        task.wait(0.4); b:Destroy()
    end)
end

-- KEY
local VK="h00x"
local keyOk=false
local kb=Instance.new("Frame")
kb.Size=UDim2.new(1,0,1,0); kb.BackgroundColor3=Color3.fromRGB(0,0,0)
kb.BackgroundTransparency=0.4; kb.BorderSizePixel=0
kb.ZIndex=50; kb.Parent=sg
local kg=Instance.new("Frame")
kg.Size=UDim2.new(0,380,0,280); kg.Position=UDim2.new(0.5,-190,0.5,-140)
kg.BackgroundColor3=C.bg; kg.BorderSizePixel=0; kg.ZIndex=51; kg.Parent=sg
crn(kg,20); strk(kg,C.acc,2.5,0.15)
local kgG=Instance.new("UIGradient")
kgG.Color=ColorSequence.new(C.acc,C.acc2); kgG.Rotation=45
kgG.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.55),
    NumberSequenceKeypoint.new(1,0.55),
})
kgG.Parent=kg
local kLogo=Instance.new("TextLabel")
kLogo.Size=UDim2.new(1,0,0,60); kLogo.Position=UDim2.new(0,0,0,22)
kLogo.BackgroundTransparency=1; kLogo.Text="⚡"
kLogo.TextColor3=C.acc; kLogo.Font=Enum.Font.GothamBold
kLogo.TextSize=46; kLogo.ZIndex=52; kLogo.Parent=kg
local kT=Instance.new("TextLabel")
kT.Size=UDim2.new(1,0,0,26); kT.Position=UDim2.new(0,0,0,86)
kT.BackgroundTransparency=1; kT.Text="Bin's Blox Fruits Hub"
kT.TextColor3=C.txt; kT.Font=Enum.Font.GothamBold
kT.TextSize=18; kT.ZIndex=52; kT.Parent=kg
local kS=Instance.new("TextLabel")
kS.Size=UDim2.new(1,0,0,18); kS.Position=UDim2.new(0,0,0,114)
kS.BackgroundTransparency=1; kS.Text="v23 · enter key"
kS.TextColor3=C.sub; kS.Font=Enum.Font.Gotham
kS.TextSize=11; kS.ZIndex=52; kS.Parent=kg
local kBox=Instance.new("TextBox")
kBox.Size=UDim2.new(1,-70,0,44); kBox.Position=UDim2.new(0,35,0,155)
kBox.BackgroundColor3=C.surf; kBox.BorderSizePixel=0
kBox.Text=""; kBox.PlaceholderText="🔑 ключ..."
kBox.PlaceholderColor3=C.dim; kBox.TextColor3=C.txt
kBox.Font=Enum.Font.GothamBold; kBox.TextSize=15
kBox.ClearTextOnFocus=false; kBox.ZIndex=52; kBox.Parent=kg
crn(kBox,12); strk(kBox,C.surf3,1.5,0.3)
local kBtn=Instance.new("TextButton")
kBtn.Size=UDim2.new(1,-70,0,46); kBtn.Position=UDim2.new(0,35,0,210)
kBtn.BackgroundColor3=C.acc; kBtn.Text="UNLOCK"
kBtn.TextColor3=Color3.fromRGB(0,0,0); kBtn.Font=Enum.Font.GothamBold
kBtn.TextSize=14; kBtn.AutoButtonColor=false; kBtn.ZIndex=52; kBtn.Parent=kg
crn(kBtn,12)
kBtn.MouseButton1Click:Connect(function()
    if kBox.Text==VK then
        keyOk=true
        tw(kb,0.4,{BackgroundTransparency=1})
        tw(kg,0.4,{Size=UDim2.new(0,150,0,100),Position=UDim2.new(0.5,-75,0.5,-50),BackgroundTransparency=1})
        task.wait(0.4)
        kb:Destroy(); kg:Destroy()
        notify("✓ Unlocked","Welcome, "..player.Name,C.grn)
    else
        kBox.Text=""
        kBox.PlaceholderText="❌ неверный ключ"
        kBox.PlaceholderColor3=C.red
        strk(kBox,C.red,2.5,0)
        task.delay(1.2,function()
            if kBox and kBox.Parent then
                kBox.PlaceholderText="🔑 ключ..."
                kBox.PlaceholderColor3=C.dim
            end
        end)
    end
end)

-- ============================================================
-- MAIN — панель открывается СПРАВА от кнопки
-- ============================================================
local PANEL_X = 18      -- кнопка слева
local PANEL_Y = 100     -- от верха
local PANEL_W = 560
local PANEL_H = 500

-- кнопка ⚡ слева
local ob=Instance.new("TextButton")
ob.Size=UDim2.new(0,56,0,56); ob.Position=UDim2.new(0,PANEL_X,0,PANEL_Y)
ob.BackgroundColor3=C.surf; ob.Text="⚡"; ob.TextColor3=C.acc
ob.Font=Enum.Font.GothamBold; ob.TextSize=26
ob.AutoButtonColor=false; ob.Visible=false; ob.ZIndex=10; ob.Parent=sg
crn(ob,14); strk(ob,C.acc,2,0.2)

-- карточка игрока слева снизу
local pc=Instance.new("Frame")
pc.Size=UDim2.new(0,220,0,64); pc.Position=UDim2.new(0,PANEL_X,1,-84)
pc.BackgroundColor3=C.surf; pc.BackgroundTransparency=0.1
pc.BorderSizePixel=0; pc.Visible=false; pc.ZIndex=5; pc.Parent=sg
crn(pc,14); strk(pc,C.acc,1.5,0.3)
local af=Instance.new("Frame")
af.Size=UDim2.new(0,50,0,50); af.Position=UDim2.new(0,7,0.5,-25)
af.BackgroundColor3=C.bg2; af.BorderSizePixel=0; af.ZIndex=6; af.Parent=pc
crn(af,12); strk(af,C.acc,1.5,0.2)
local ai=Instance.new("ImageLabel")
ai.Size=UDim2.new(1,-4,1,-4); ai.Position=UDim2.new(0,2,0,2)
ai.BackgroundTransparency=1; ai.ZIndex=7; ai.Parent=af
crn(ai,10)
pcall(function()
    ai.Image=Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
end)
local pn=Instance.new("TextLabel")
pn.Size=UDim2.new(1,-70,0,22); pn.Position=UDim2.new(0,66,0,10)
pn.BackgroundTransparency=1; pn.Text=player.Name
pn.TextColor3=C.txt; pn.Font=Enum.Font.GothamBold; pn.TextSize=13
pn.TextXAlignment=Enum.TextXAlignment.Left
pn.TextTruncate=Enum.TextTruncate.AtEnd; pn.ZIndex=6; pn.Parent=pc
local pl=Instance.new("TextLabel")
pl.Size=UDim2.new(1,-70,0,18); pl.Position=UDim2.new(0,66,0,32)
pl.BackgroundTransparency=1; pl.Text="Hub v23"
pl.TextColor3=C.sub; pl.Font=Enum.Font.Gotham; pl.TextSize=10
pl.TextXAlignment=Enum.TextXAlignment.Left; pl.ZIndex=6; pl.Parent=pc

-- главная панель — появляется ПРАВЕЕ кнопки
local main=Instance.new("Frame")
main.Size=UDim2.new(0,0,0,PANEL_H)
main.Position=UDim2.new(0,PANEL_X+66,0,PANEL_Y)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0
main.Visible=false; main.Active=true; main.ClipsDescendants=true
main.ZIndex=4; main.Parent=sg
crn(main,16); strk(main,C.acc,2,0.3)
local mg=Instance.new("UIGradient")
mg.Color=ColorSequence.new(C.acc,C.acc2); mg.Rotation=45
mg.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.9),
    NumberSequenceKeypoint.new(1,0.9),
})
mg.Parent=main

-- title bar
local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,50); tb.BackgroundColor3=C.surf
tb.BorderSizePixel=0; tb.ZIndex=5; tb.Parent=main; crn(tb,16)
local tbG=Instance.new("UIGradient")
tbG.Color=ColorSequence.new(C.acc,C.acc2); tbG.Rotation=90
tbG.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.6),
    NumberSequenceKeypoint.new(1,0.95),
})
tbG.Parent=tb
local tbf=Instance.new("Frame",tb)
tbf.Size=UDim2.new(1,0,0,14); tbf.Position=UDim2.new(0,0,1,-14)
tbf.BackgroundColor3=C.surf; tbf.BorderSizePixel=0; tbf.ZIndex=5
local lg=Instance.new("TextLabel")
lg.Size=UDim2.new(0,36,0,36); lg.Position=UDim2.new(0,10,0.5,-18)
lg.BackgroundColor3=C.bg2; lg.Text="⚡"; lg.TextColor3=C.acc
lg.Font=Enum.Font.GothamBold; lg.TextSize=20; lg.ZIndex=6; lg.Parent=tb
crn(lg,10); strk(lg,C.acc,1.5,0.3)
local ttl=Instance.new("TextLabel")
ttl.Size=UDim2.new(1,-120,0,18); ttl.Position=UDim2.new(0,54,0,10)
ttl.BackgroundTransparency=1; ttl.Text="Bin's Blox Fruits"
ttl.TextColor3=C.txt; ttl.Font=Enum.Font.GothamBold; ttl.TextSize=14
ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.ZIndex=6; ttl.Parent=tb
local stl=Instance.new("TextLabel")
stl.Size=UDim2.new(1,-120,0,14); stl.Position=UDim2.new(0,54,0,27)
stl.BackgroundTransparency=1; stl.Text="v23 · "..player.Name
stl.TextColor3=C.sub; stl.Font=Enum.Font.Gotham; stl.TextSize=10
stl.TextXAlignment=Enum.TextXAlignment.Left; stl.ZIndex=6; stl.Parent=tb
local cbtn=Instance.new("TextButton")
cbtn.Size=UDim2.new(0,30,0,30); cbtn.Position=UDim2.new(1,-40,0.5,-15)
cbtn.BackgroundColor3=C.surf2; cbtn.Text="✕"; cbtn.TextColor3=C.sub
cbtn.Font=Enum.Font.GothamBold; cbtn.TextSize=13
cbtn.AutoButtonColor=false; cbtn.ZIndex=6; cbtn.Parent=tb
crn(cbtn,10)

-- ============================================================
-- ВЕРТИКАЛЬНЫЕ ТАБЫ СЛЕВА
-- ============================================================
local TAB_W = 60
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(0,TAB_W,1,-60)
tabBar.Position=UDim2.new(0,0,0,50)
tabBar.BackgroundColor3=C.bg2; tabBar.BorderSizePixel=0
tabBar.ZIndex=5; tabBar.Parent=main

local pages={}
local tabs={}
local TN={"farm","boss","quest","stat","tp","esp","misc"}
local TL={"⚔","👑","📜","📊","🌀","👁","⚙"}
local TLABELS={"FARM","BOSS","QUEST","STAT","TP","ESP","MISC"}

local pill=Instance.new("Frame")
pill.Size=UDim2.new(1,-8,0,46); pill.Position=UDim2.new(0,4,0,4)
pill.BackgroundColor3=C.acc; pill.BorderSizePixel=0
pill.ZIndex=6; pill.Parent=tabBar; crn(pill,10)
local pillG=Instance.new("UIGradient")
pillG.Color=ColorSequence.new(C.acc,C.acc3); pillG.Rotation=45
pillG.Parent=pill

local function selTab(name)
    for _,n in ipairs(TN) do
        if tabs[n] then
            tabs[n].TextColor3 = (n==name) and C.bg or C.sub
        end
    end
    local idx=1
    for i,n in ipairs(TN) do if n==name then idx=i; break end end
    tw(pill, 0.25, {Position=UDim2.new(0,4,0,4+(idx-1)*52)})
    for n,p in pairs(pages) do p.Visible=(n==name) end
end

for i,name in ipairs(TN) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-8,0,46); b.Position=UDim2.new(0,4,0,4+(i-1)*52)
    b.BackgroundTransparency=1
    b.Text=TL[i].."\n"..TLABELS[i]
    b.TextColor3=C.sub; b.Font=Enum.Font.GothamBold
    b.TextSize=10; b.ZIndex=7; b.Parent=tabBar
    b.MouseButton1Click:Connect(function() selTab(name) end)
    tabs[name]=b
end

-- content
local CONTENT_X = TAB_W + 4
local ca=Instance.new("Frame")
ca.Size=UDim2.new(1, -CONTENT_X - 8, 1, -60)
ca.Position=UDim2.new(0, CONTENT_X, 0, 54)
ca.BackgroundTransparency=1; ca.ClipsDescendants=true; ca.ZIndex=5; ca.Parent=main
for _,name in ipairs(TN) do
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0); p.BackgroundTransparency=1
    p.BorderSizePixel=0; p.ScrollBarThickness=4
    p.ScrollBarImageColor3=C.acc; p.ScrollBarImageTransparency=0.3
    p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false; p.ZIndex=6; p.Parent=ca
    local lay=Instance.new("UIListLayout",p)
    lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",p); pad.PaddingRight=UDim.new(0,8); pad.PaddingLeft=UDim.new(0,4)
    pages[name]=p
end
selTab("farm")

local ordr=0
local function no() ordr=ordr+1; return ordr end
local function sect(parent,title)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    f.LayoutOrder=no(); f.ZIndex=6; f.Parent=parent
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,3,0,12); bar.Position=UDim2.new(0,0,0.5,-6)
    bar.BackgroundColor3=C.acc; bar.BorderSizePixel=0; bar.ZIndex=7; bar.Parent=f; crn(bar,2)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-12,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=title; l.TextColor3=C.acc
    l.Font=Enum.Font.GothamBold; l.TextSize=10; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end
local function tog(parent,name,desc,get,set)
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,48); c.BackgroundColor3=C.surf
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,10); strk(c,C.surf3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-90,0,18); l.Position=UDim2.new(0,12,0,6)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.txt
    l.Font=Enum.Font.GothamBold; l.TextSize=12; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    if desc then
        local d=Instance.new("TextLabel")
        d.Size=UDim2.new(1,-90,0,14); d.Position=UDim2.new(0,12,0,24)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=C.sub
        d.Font=Enum.Font.Gotham; d.TextSize=9; d.ZIndex=7
        d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=c
    end
    local tr=Instance.new("Frame")
    tr.Size=UDim2.new(0,42,0,22); tr.Position=UDim2.new(1,-52,0.5,-11)
    tr.BackgroundColor3=C.surf3; tr.BorderSizePixel=0; tr.ZIndex=7; tr.Parent=c; crn(tr,11)
    local k=Instance.new("Frame")
    k.Size=UDim2.new(0,16,0,16); k.Position=UDim2.new(0,3,0.5,-8)
    k.BackgroundColor3=C.sub; k.BorderSizePixel=0; k.ZIndex=8; k.Parent=tr; crn(k,8)
    local hb=Instance.new("TextButton")
    hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=9; hb.Parent=c
    local function rf(a)
        local v=get()
        local i=TweenInfo.new(a and 0.2 or 0,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
        TS:Create(tr,i,{BackgroundColor3=v and C.grn or C.surf3}):Play()
        TS:Create(k,i,{
            Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=v and Color3.fromRGB(255,255,255) or C.sub,
        }):Play()
    end
    rf(false)
    hb.MouseButton1Click:Connect(function() set(not get()); rf(true) end)
end
local function sld(parent,name,mn,mx,st,get,set,suf)
    suf=suf or ""
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,62); c.BackgroundColor3=C.surf
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,10); strk(c,C.surf3,1,0.5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-90,0,16); l.Position=UDim2.new(0,12,0,6)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=C.txt
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,80,0,16); vl.Position=UDim2.new(1,-90,0,6)
    vl.BackgroundTransparency=1
    vl.Text=string.format("%.1f",get())..suf
    vl.TextColor3=C.acc; vl.Font=Enum.Font.GothamBold; vl.TextSize=11
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.ZIndex=7; vl.Parent=c
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,-24,0,6); bg.Position=UDim2.new(0,12,0,30)
    bg.BackgroundColor3=C.surf3; bg.BorderSizePixel=0; bg.ZIndex=7; bg.Parent=c; crn(bg,3)
    local fl=Instance.new("Frame")
    fl.Size=UDim2.new((get()-mn)/(mx-mn),0,1,0)
    fl.BackgroundColor3=C.acc; fl.BorderSizePixel=0; fl.ZIndex=8; fl.Parent=bg; crn(fl,3)
    local mi=Instance.new("TextButton")
    mi.Size=UDim2.new(0,28,0,18); mi.Position=UDim2.new(0,12,1,-24)
    mi.BackgroundColor3=C.surf2; mi.Text="−"; mi.TextColor3=C.txt
    mi.Font=Enum.Font.GothamBold; mi.TextSize=12; mi.AutoButtonColor=false; mi.ZIndex=8; mi.Parent=c; crn(mi,6)
    local pl=Instance.new("TextButton")
    pl.Size=UDim2.new(0,28,0,18); pl.Position=UDim2.new(1,-40,1,-24)
    pl.BackgroundColor3=C.acc; pl.Text="+"; pl.TextColor3=C.bg
    pl.Font=Enum.Font.GothamBold; pl.TextSize=12; pl.AutoButtonColor=false; pl.ZIndex=8; pl.Parent=c; crn(pl,6)
    local function up(v)
        v=math.clamp(v,mn,mx); set(v)
        vl.Text=string.format("%.1f",v)..suf
        tw(fl,0.15,{Size=UDim2.new((v-mn)/(mx-mn),0,1,0)})
    end
    mi.MouseButton1Click:Connect(function() up(get()-st) end)
    pl.MouseButton1Click:Connect(function() up(get()+st) end)
end
local function act(parent,text,cb,col)
    col=col or C.acc
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,36); b.BackgroundColor3=col
    b.Text=text; b.TextColor3=C.bg; b.Font=Enum.Font.GothamBold
    b.TextSize=12; b.AutoButtonColor=false; b.LayoutOrder=no(); b.ZIndex=6; b.Parent=parent
    crn(b,10)
    b.MouseButton1Click:Connect(function()
        local ok,err=pcall(cb)
        if not ok then warn("[Bin Hub] "..tostring(err)); notify("Error",tostring(err),C.red) end
    end)
end

-- FARM
sect(pages.farm,"FARMING")
tog(pages.farm,"Auto Level","Any NPC",function() return S.farmLevel end,function(v) S.farmLevel=v end)
tog(pages.farm,"Auto Pirates","Prioritize",function() return S.farmPirates end,function(v) S.farmPirates=v end)
tog(pages.farm,"Auto Marines","Prioritize",function() return S.farmMarines end,function(v) S.farmMarines=v end)
tog(pages.farm,"Auto Bosses","Prioritize",function() return S.farmBosses end,function(v) S.farmBosses=v end)
sect(pages.farm,"COMBAT (hitbox 40)")
sld(pages.farm,"Attack Speed",0.1,2,0.05,function() return S.speed end,function(v) S.speed=v end,"s")
sld(pages.farm,"Hover Height",3,15,1,function() return S.hover end,function(v) S.hover=v end,"")
tog(pages.farm,"Lock Camera","",function() return S.lockCam end,function(v) S.lockCam=v end)
tog(pages.farm,"Kill Aura","",function() return S.killAura end,function(v) S.killAura=v end)
sld(pages.farm,"Aura Range",10,300,5,function() return S.auraRange end,function(v) S.auraRange=v end,"")
sect(pages.farm,"FLY (WASD+Space)")
tog(pages.farm,"Fly","",function() return S.fly end,function(v) S.fly=v end)
sld(pages.farm,"Fly Speed",10,400,5,function() return S.flySpeed end,function(v) S.flySpeed=v end,"")
sect(pages.farm,"AUTO FISH")
tog(pages.farm,"Auto Fish","",function() return S.autoFish end,function(v) S.autoFish=v end)
sect(pages.farm,"AUTO COLLECT")
tog(pages.farm,"Auto Chest","Smart TP",function() return S.autoChest end,function(v) S.autoChest=v end)
sld(pages.farm,"Chest Range",100,5000,50,function() return S.chestRange end,function(v) S.chestRange=v end,"")
tog(pages.farm,"Auto Fruit","TP to selected",function() return S.autoFruit end,function(v) S.autoFruit=v end)

-- BOSS
sect(pages.boss,"BOSS TELEPORT")
local bScr=Instance.new("ScrollingFrame")
bScr.Size=UDim2.new(1,0,0,320); bScr.BackgroundColor3=C.surf
bScr.BorderSizePixel=0; bScr.LayoutOrder=no()
bScr.ScrollBarThickness=4; bScr.ScrollBarImageColor3=C.red
bScr.CanvasSize=UDim2.new(0,0,0,0); bScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
bScr.ZIndex=6; bScr.Parent=pages.boss
crn(bScr,10); strk(bScr,C.surf3,1,0.5)
local bLay=Instance.new("UIListLayout",bScr)
bLay.Padding=UDim.new(0,4); bLay.SortOrder=Enum.SortOrder.LayoutOrder
local bPad=Instance.new("UIPadding",bScr); bPad.PaddingRight=UDim.new(0,6); bPad.PaddingLeft=UDim.new(0,6); bPad.PaddingTop=UDim.new(0,6)
local bBtns={}
for _,b in ipairs(BOSSES) do
    local bb=Instance.new("TextButton")
    bb.Size=UDim2.new(1,-4,0,28); bb.BackgroundColor3=C.surf2
    bb.Text="  👑 "..b.n.."  Lvl "..b.lv
    bb.TextColor3=C.txt; bb.Font=Enum.Font.Gotham
    bb.TextSize=11; bb.TextXAlignment=Enum.TextXAlignment.Left
    bb.AutoButtonColor=false; bb.ZIndex=7; bb.Parent=bScr; crn(bb,6)
    bb.MouseButton1Click:Connect(function()
        S.selBoss=b.n
        for n,btn in pairs(bBtns) do
            local a=(n==b.n)
            tw(btn,0.15,{BackgroundColor3=a and C.red or C.surf2,TextColor3=a and Color3.fromRGB(255,255,255) or C.txt})
        end
        notify("Boss","Selected: "..b.n,C.red)
    end)
    bBtns[b.n]=bb
end
act(pages.boss,"👑  TP to Selected Boss",function()
    for _,b in ipairs(BOSSES) do
        if b.n==S.selBoss then
            local ok=tp(b.p)
            if ok then notify("Boss","TP: "..b.n,C.red)
            else notify("Boss","Ошибка ТП",C.red) end
            break
        end
    end
end,C.red)

-- QUEST
sect(pages.quest,"AUTO QUEST")
tog(pages.quest,"Auto Quest","Loop",function() return S.autoQuest end,function(v) S.autoQuest=v end)
local qScr=Instance.new("ScrollingFrame")
qScr.Size=UDim2.new(1,0,0,320); qScr.BackgroundColor3=C.surf
qScr.BorderSizePixel=0; qScr.LayoutOrder=no()
qScr.ScrollBarThickness=4; qScr.ScrollBarImageColor3=C.acc2
qScr.CanvasSize=UDim2.new(0,0,0,0); qScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
qScr.ZIndex=6; qScr.Parent=pages.quest
crn(qScr,10); strk(qScr,C.surf3,1,0.5)
local qLay=Instance.new("UIListLayout",qScr)
qLay.Padding=UDim.new(0,4); qLay.SortOrder=Enum.SortOrder.LayoutOrder
local qPad=Instance.new("UIPadding",qScr); qPad.PaddingRight=UDim.new(0,6); qPad.PaddingLeft=UDim.new(0,6); qPad.PaddingTop=UDim.new(0,6)
local qBtns={}
for _,q in ipairs(QUESTS) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-4,0,28); b.BackgroundColor3=C.surf2
    b.Text="  📜 "..q.n.."  Lvl "..q.lv
    b.TextColor3=C.txt; b.Font=Enum.Font.Gotham
    b.TextSize=11; b.TextXAlignment=Enum.TextXAlignment.Left
    b.AutoButtonColor=false; b.ZIndex=7; b.Parent=qScr; crn(b,6)
    b.MouseButton1Click:Connect(function()
        S.questName=q.n
        for n,btn in pairs(qBtns) do
            local a=(n==q.n)
            tw(btn,0.15,{BackgroundColor3=a and C.acc2 or C.surf2,TextColor3=a and Color3.fromRGB(255,255,255) or C.txt})
        end
        notify("Quest","Selected: "..q.n,C.acc2)
    end)
    qBtns[q.n]=b
end
act(pages.quest,"📜  Start Selected Quest",function()
    for _,q in ipairs(QUESTS) do
        if q.n==S.questName then
            tp(q.p); task.wait(0.5)
            local ok=startQ(q.npc,q.lv)
            if ok then notify("Quest","Started: "..q.n,C.grn)
            else notify("Quest","CommF_ не найден",C.red) end
            break
        end
    end
end,C.acc2)

-- STAT
sect(pages.stat,"AUTO STAT (level up)")
tog(pages.stat,"Auto Stat","No spam check",function() return S.autoStat end,function(v) S.autoStat=v end)
local sScr=Instance.new("ScrollingFrame")
sScr.Size=UDim2.new(1,0,0,200); sScr.BackgroundColor3=C.surf
sScr.BorderSizePixel=0; sScr.LayoutOrder=no()
sScr.ScrollBarThickness=4; sScr.ScrollBarImageColor3=C.acc
sScr.CanvasSize=UDim2.new(0,0,0,0); sScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
sScr.ZIndex=6; sScr.Parent=pages.stat
crn(sScr,10); strk(sScr,C.surf3,1,0.5)
local sLay=Instance.new("UIListLayout",sScr)
sLay.Padding=UDim.new(0,4); sLay.SortOrder=Enum.SortOrder.LayoutOrder
local sPad=Instance.new("UIPadding",sScr); sPad.PaddingRight=UDim.new(0,6); sPad.PaddingLeft=UDim.new(0,6); sPad.PaddingTop=UDim.new(0,6)
local statBtns={}
local STATS={"Melee","Defense","Sword","Gun","Blox Fruit"}
for _,sn in ipairs(STATS) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-4,0,28); b.BackgroundColor3=C.surf2
    b.Text="  ⚔ "..sn
    b.TextColor3=C.txt; b.Font=Enum.Font.GothamBold
    b.TextSize=11; b.TextXAlignment=Enum.TextXAlignment.Left
    b.AutoButtonColor=false; b.ZIndex=7; b.Parent=sScr; crn(b,6)
    b.MouseButton1Click:Connect(function()
        S.statName=sn
        for n,btn in pairs(statBtns) do
            local a=(n==sn)
            tw(btn,0.15,{BackgroundColor3=a and C.acc or C.surf2,TextColor3=a and C.bg or C.txt})
        end
    end)
    statBtns[sn]=b
end
tog(pages.stat,"Auto Fruit Mastery","Spam Z X C V",function() return S.autoMastery end,function(v) S.autoMastery=v end)

-- TP
sect(pages.tp,"CITIES / SEARCH")
local sf=Instance.new("Frame")
sf.Size=UDim2.new(1,0,0,32); sf.BackgroundColor3=C.surf
sf.BorderSizePixel=0; sf.LayoutOrder=no(); sf.ZIndex=6; sf.Parent=pages.tp
crn(sf,10); strk(sf,C.surf3,1,0.5)
local sbx=Instance.new("TextBox")
sbx.Size=UDim2.new(1,-20,1,-6); sbx.Position=UDim2.new(0,10,0,3)
sbx.BackgroundTransparency=1; sbx.Text=""; sbx.PlaceholderText="🔍 search city..."
sbx.PlaceholderColor3=C.dim; sbx.TextColor3=C.txt
sbx.Font=Enum.Font.Gotham; sbx.TextSize=11; sbx.ZIndex=7
sbx.TextXAlignment=Enum.TextXAlignment.Left; sbx.ClearTextOnFocus=false; sbx.Parent=sf
local cScr=Instance.new("ScrollingFrame")
cScr.Size=UDim2.new(1,0,0,280); cScr.BackgroundColor3=C.surf
cScr.BorderSizePixel=0; cScr.LayoutOrder=no()
cScr.ScrollBarThickness=4; cScr.ScrollBarImageColor3=C.acc
cScr.CanvasSize=UDim2.new(0,0,0,0); cScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
cScr.ZIndex=6; cScr.Parent=pages.tp
crn(cScr,10); strk(cScr,C.surf3,1,0.5)
local cLay=Instance.new("UIListLayout",cScr)
cLay.Padding=UDim.new(0,4); cLay.SortOrder=Enum.SortOrder.LayoutOrder
local cPad=Instance.new("UIPadding",cScr); cPad.PaddingRight=UDim.new(0,6); cPad.PaddingLeft=UDim.new(0,6); cPad.PaddingTop=UDim.new(0,6)
local cBtns={}
local function rebuild(f)
    for _,c in ipairs(cScr:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    cBtns={}; f=(f or ""):lower()
    for _,l in ipairs(CITIES) do
        if f=="" or l.n:lower():find(f,1,true) then
            local b=Instance.new("TextButton")
            b.Size=UDim2.new(1,-4,0,26); b.BackgroundColor3=C.surf2
            b.Text="  🌍 "..l.n
            b.TextColor3=C.txt; b.Font=Enum.Font.Gotham
            b.TextSize=11; b.TextXAlignment=Enum.TextXAlignment.Left
            b.AutoButtonColor=false; b.ZIndex=7; b.Parent=cScr; crn(b,6)
            b.MouseButton1Click:Connect(function()
                S.selTP=l.n
                for n,btn in pairs(cBtns) do
                    local a=(n==l.n)
                    tw(btn,0.15,{BackgroundColor3=a and C.acc or C.surf2,TextColor3=a and C.bg or C.txt})
                end
            end)
            cBtns[l.n]=b
        end
    end
end
rebuild("")
sbx:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sbx.Text) end)
act(pages.tp,"✨  TP to Selected City",function()
    for _,l in ipairs(CITIES) do
        if l.n==S.selTP then
            local ok=tp(l.p)
            if ok then notify("City","Warped: "..l.n,C.acc)
            else notify("City","Ошибка ТП",C.red) end
            break
        end
    end
end,C.acc)
act(pages.tp,"🛑  Stop Hover",function()
    if hoverT then rmHB(hoverT) end
    setHover(nil); notify("Hover","Off",C.red)
end,C.surf2)
act(pages.tp,"📦  Scan Chests (coords)",function()
    local cnt=0
    for o in pairs(chests) do
        local p=o:IsA("Model") and (o:FindFirstChild("Handle") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
        if p and p.Position then
            cnt=cnt+1
            if cnt<=3 then
                notify("Chest #"..cnt,string.format("%.0f, %.0f, %.0f",p.Position.X,p.Position.Y,p.Position.Z),C.grn)
            end
        end
    end
    notify("Scan","Всего: "..cnt,C.acc)
end,C.grn)

-- ESP
sect(pages.esp,"ESP")
tog(pages.esp,"ESP NPCs","Boxes",function() return S.espNPC end,function(v) S.espNPC=v end)
tog(pages.esp,"ESP Players","Boxes",function() return S.espPlayer end,function(v) S.espPlayer=v end)

-- MISC
sect(pages.misc,"INFO")
act(pages.misc,"🔄  Refresh NPC Cache",function()
    refresh(); notify("Cache","Refreshed: "..#cache,C.grn)
end,C.surf2)
local ic=Instance.new("Frame")
ic.Size=UDim2.new(1,0,0,110); ic.BackgroundColor3=C.surf
ic.BorderSizePixel=0; ic.LayoutOrder=no(); ic.ZIndex=6; ic.Parent=pages.misc
crn(ic,10); strk(ic,C.surf3,1,0.5)
local it=Instance.new("TextLabel")
it.Size=UDim2.new(1,-16,1,-12); it.Position=UDim2.new(0,12,0,6)
it.BackgroundTransparency=1
it.Text="Bin's Blox Fruits Hub v23\nkey: h00x · hitbox 40\n\nCities: "..#CITIES.." · Bosses: "..#BOSSES.." · Quests: "..#QUESTS.."\nmade by Bin & Steve · nya~"
it.TextColor3=C.sub; it.Font=Enum.Font.Gotham; it.TextSize=10
it.TextXAlignment=Enum.TextXAlignment.Left
it.TextYAlignment=Enum.TextYAlignment.Top
it.TextWrapped=true; it.ZIndex=7; it.Parent=ic

-- toggle
local isOpen=false
local function tglW()
    isOpen=not isOpen
    if isOpen then
        main.Visible=true
        main.Size=UDim2.new(0,0,0,PANEL_H)
        tw(main,0.3,{Size=UDim2.new(0,PANEL_W,0,PANEL_H)})
    else
        tw(main,0.2,{Size=UDim2.new(0,0,0,PANEL_H)})
        task.wait(0.2)
        main.Visible=false
    end
end

task.spawn(function()
    while not keyOk do task.wait(0.3) end
    ob.Visible=true
    pc.Visible=true
    pc.Position=UDim2.new(0,PANEL_X,1,-30)
    pc.BackgroundTransparency=1
    task.wait(0.1)
    tw(pc,0.4,{Position=UDim2.new(0,PANEL_X,1,-84),BackgroundTransparency=0.1})
    task.wait(0.4)
    notify("✓ Ready","Нажми ⚡ слева",C.acc)
end)
ob.MouseButton1Click:Connect(function() if keyOk then tglW() end end)
cbtn.MouseButton1Click:Connect(tglW)

print("[Bin's Hub v23] loaded. key: ///")
