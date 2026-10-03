local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local VI=nil
pcall(function() VI=game:GetService("VirtualInputManager") end)
local plr=Players.LocalPlayer
local pg=plr:WaitForChild("PlayerGui",30)
local cam=workspace.CurrentCamera
local char,root,hum
local function bind(c)
    if not c then return end
    char=c; root=c:WaitForChild("HumanoidRootPart",15); hum=c:WaitForChild("Humanoid",15)
end
if plr.Character then bind(plr.Character) end
plr.CharacterAdded:Connect(bind)
local wt=0
while (not char or not root or not hum) and wt<60 do
    task.wait(0.5); wt=wt+0.5
    if plr.Character then bind(plr.Character) end
end
local killed=false   -- <-- флаг для выхода из чита

local function gr()
    if killed then return nil end
    if not char or not char.Parent then
        if plr.Character and plr.Character.Parent then bind(plr.Character) end
    end
    if not root or not root.Parent then return nil end
    return root
end

-- ФИКС: игнорируем воду при raycast
local function getY(x,z,from)
    local ok,res=pcall(function()
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances=char and {char} or {}
        rp.IgnoreWater=true       -- <-- ИСПРАВЛЕНО: не попадаем в море
        return workspace:Raycast(Vector3.new(x,from or 500,z),Vector3.new(0,-2000,0),rp)
    end)
    if ok and res then return res.Position.Y end
    return nil
end

local function tp(pos)
    local r=gr(); if not r then return false end
    local y=getY(pos.X,pos.Z,pos.Y+800) or getY(pos.X,pos.Z,2000)
    -- если луч не нашёл землю — ставим высоко над водой, персонаж упадёт на сушу
    if not y then y=80 end
    -- если координаты ниже уровня моря — поднимаем
    if y < 5 then y = 80 end
    local t=Vector3.new(pos.X,y+3.5,pos.Z)
    if hum then
        pcall(function() hum:MoveTo(t) end)
    end
    pcall(function() r.CFrame=CFrame.new(t) end)
    task.wait(0.15)
    pcall(function() r.CFrame=CFrame.new(t) end)
    return true
end
local function getRem()
    local r=RS:FindFirstChild("Remotes")
    return r and (r:FindFirstChild("CommF_") or r:FindFirstChild("CommE_")) or nil
end

local S={
    farmLevel=false,farmPirates=false,farmMarines=false,farmBosses=false,
    speed=0.25, hover=6, killAura=false, auraRange=45,
    autoChest=false, chestRange=3000,
    autoStat=false, statName="Melee",
    autoQuest=false, questName="Bandit",
    autoMastery=false,
    fly=false, flySpeed=120, lockCam=true,
    selTP="Bandit Camp", selBoss="Gorilla King",
}

local HB=40
local orig=setmetatable({},{__mode="k"})
local function addHB(npc)
    if not npc then return end
    local h=npc:FindFirstChild("HumanoidRootPart"); if not h then return end
    if not orig[h] then orig[h]={s=h.Size,t=h.Transparency,c=h.CanCollide,m=h.Massless} end
    pcall(function()
        h.Size=Vector3.new(HB,HB,HB)
        h.Transparency=1; h.CanCollide=false; h.Massless=true
        h.CanQuery=true; h.CanTouch=true
    end)
end
local function rmHB(npc)
    if not npc then return end
    local h=npc:FindFirstChild("HumanoidRootPart"); if not h then return end
    local o=orig[h]
    if o then
        pcall(function() h.Size=o.s; h.Transparency=o.t; h.CanCollide=o.c; h.Massless=o.m end)
        orig[h]=nil
    end
end
local hoverT,hoverA=nil,false
local function setHover(npc)
    if hoverA and hoverT and hoverT~=npc then rmHB(hoverT) end
    hoverT=npc; hoverA=npc~=nil
    if hum then pcall(function() hum.PlatformStand=hoverA end) end
    if hoverA and npc then addHB(npc) end
end
RunService.Heartbeat:Connect(function()
    if killed then return end
    if not (hoverA and hoverT and hoverT.Parent) then return end
    if S.fly then return end
    local r=gr(); if not r then return end
    local h=hoverT:FindFirstChild("HumanoidRootPart")
    local hm=hoverT:FindFirstChild("Humanoid")
    if not (h and hm and hm.Health>0) then
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

local flyCon=nil
local function startFly()
    local r=gr(); if not r or not hum then return end
    pcall(function() hum.PlatformStand=true end)
    pcall(function() hum.WalkSpeed=0; hum.JumpPower=0 end)
    if flyCon then flyCon:Disconnect() end
    flyCon=RunService.RenderStepped:Connect(function(dt)
        if killed or not S.fly then return end
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
    if hum then pcall(function() hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end) end
end
task.spawn(function()
    local last=false
    while not killed do
        task.wait(0.1)
        if S.fly and not last then startFly() end
        if not S.fly and last then stopFly() end
        last=S.fly
    end
    stopFly()
end)

local function getPoints()
    local d=plr:FindFirstChild("Data"); if not d then return 0 end
    local s=d:FindFirstChild("Stats"); if not s then return 0 end
    local p=s:FindFirstChild("Points"); if not p then return 0 end
    return p.Value or 0
end
task.spawn(function()
    while not killed do
        task.wait(1.5)
        if S.autoStat then
            local pts=getPoints()
            if pts>0 then
                local r=getRem()
                if r then
                    for i=1,math.min(pts,10) do
                        pcall(function() r:InvokeServer("AddPoint",S.statName,1) end)
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while not killed do
        task.wait(0.5)
        if S.autoMastery and VI then
            for _,k in ipairs({"Z","X","C","V"}) do
                pcall(function()
                    VI:SendKeyEvent(true,Enum.KeyCode.k,false,game)
                    task.wait(0.03)
                    VI:SendKeyEvent(false,Enum.KeyCode[k],false,game)
                end)
            end
        end
    end
end)

-- ============================================================
-- АКТУАЛЬНЫЕ КООРДИНАТЫ (обновлено под текущую версию)
-- ============================================================
local CITIES={
    {n="Bandit Camp",p=Vector3.new(-1160,20,3146)},
    {n="Pirate Village",p=Vector3.new(-1210,20,3400)},
    {n="Marine Fort",p=Vector3.new(-2770,20,4326)},
    {n="Jungle",p=Vector3.new(-1620,20,220)},
    {n="Fountain City",p=Vector3.new(-1245,20,3200)},
    {n="Pirate Island",p=Vector3.new(990,20,1210)},
    {n="Colosseum",p=Vector3.new(-1480,20,215)},
    {n="Desert",p=Vector3.new(1050,20,4480)},
    {n="Snow Island",p=Vector3.new(1240,20,-1510)},
    {n="Skylands",p=Vector3.new(-500,800,-1500)},
    {n="Prison",p=Vector3.new(4990,20,810)},
    {n="Kingdom of Rose",p=Vector3.new(-390,20,5990)},
    {n="Green Zone",p=Vector3.new(-3480,20,-4480)},
    {n="Graveyard",p=Vector3.new(-5420,20,-3510)},
    {n="Ice Castle",p=Vector3.new(-5990,20,-5990)},
    {n="Forgotten Island",p=Vector3.new(-3010,20,-8010)},
    {n="Port Town",p=Vector3.new(-490,20,-9990)},
    {n="Hydra Island",p=Vector3.new(5010,20,-9010)},
    {n="Great Tree",p=Vector3.new(-3010,20,-12010)},
    {n="Haunted Castle",p=Vector3.new(3010,20,-12010)},
    {n="Sea of Treats",p=Vector3.new(5010,20,-15010)},
}
local BOSSES={
    {n="Gorilla King",lv=100,p=Vector3.new(-1160,20,2900)},
    {n="Bobby",lv=150,p=Vector3.new(-1150,20,3260)},
    {n="Yeti",lv=200,p=Vector3.new(1300,20,-1600)},
    {n="Mob Leader",lv=300,p=Vector3.new(-2760,20,4300)},
    {n="Vice Admiral",lv=375,p=Vector3.new(-2780,20,4320)},
    {n="Saber Expert",lv=500,p=Vector3.new(-1470,20,220)},
    {n="Cyborg",lv=650,p=Vector3.new(4990,20,810)},
    {n="Diamond",lv=750,p=Vector3.new(-400,20,6000)},
    {n="Jeremy",lv=850,p=Vector3.new(-3480,20,-4480)},
    {n="Smoke Admiral",lv=1000,p=Vector3.new(-5990,20,-5990)},
    {n="Yellow Beard",lv=1100,p=Vector3.new(-490,20,-9990)},
    {n="Cursed Captain",lv=1250,p=Vector3.new(3010,20,-12010)},
    {n="Soul Reaper",lv=1400,p=Vector3.new(-3010,20,-12010)},
    {n="Cake Queen",lv=1700,p=Vector3.new(5010,20,-15010)},
    {n="Dough King",lv=2000,p=Vector3.new(-9010,20,-10010)},
}
local QUESTS={
    {n="Bandit",lv=1,p=Vector3.new(-1160,20,3146),npc="Bandit"},
    {n="Monkey",lv=15,p=Vector3.new(-1600,20,200),npc="Monkey"},
    {n="Blade Master",lv=25,p=Vector3.new(-1450,20,130),npc="Blade Master"},
    {n="Brute",lv=40,p=Vector3.new(-1140,20,1520),npc="Brute"},
    {n="Pirate",lv=60,p=Vector3.new(-1200,20,3400),npc="Pirate"},
    {n="Marine",lv=90,p=Vector3.new(-2780,20,4320),npc="Marine"},
    {n="Snow Bandit",lv=120,p=Vector3.new(1250,20,-1500),npc="Snow Bandit"},
    {n="Sky Bandit",lv=180,p=Vector3.new(-500,800,-1500),npc="Sky Bandit"},
    {n="Raider",lv=375,p=Vector3.new(-390,20,6000),npc="Raider"},
    {n="Mercenary",lv=450,p=Vector3.new(-3480,20,-4480),npc="Mercenary"},
    {n="Zombie",lv=550,p=Vector3.new(-5420,20,-3510),npc="Zombie"},
}
local function startQ(npc,lv)
    local r=getRem(); if not r then return false end
    return pcall(function() r:InvokeServer("StartQuest",npc,lv) end)
end

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
    local ef=workspace:FindFirstChild("Enemies"); if ef then scan(ef,nc) end
    if #nc==0 then scan(workspace,nc) end
    cache=nc
end
task.spawn(function() while not killed do task.wait(1) pcall(refresh) end end)
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
    local r=gr(); if r then pcall(function() r.CFrame=CFrame.lookAt(r.Position,h.Position) end) end
    local tool; if char then tool=char:FindFirstChildOfClass("Tool") end
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
end
local PRIO={
    {g=function() return S.farmBosses end,t="boss"},
    {g=function() return S.farmMarines end,t="marine"},
    {g=function() return S.farmPirates end,t="pirate"},
    {g=function() return S.farmLevel end,t="all"},
}
task.spawn(function()
    while not killed do
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
    while not killed do
        task.wait(0.2)
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
task.spawn(function()
    while not killed do
        task.wait(1.5)
        if S.autoQuest then
            for _,q in ipairs(QUESTS) do
                if q.n==S.questName then
                    local r=gr()
                    if r then
                        if (r.Position-q.p).Magnitude>30 then tp(q.p); task.wait(1.2) end
                        startQ(q.npc,q.lv)
                        task.wait(0.5)
                    end
                    break
                end
            end
        end
    end
end)

local chests={}
local function isChest(o)
    if not (o:IsA("Model") or o:IsA("BasePart")) then return false end
    local n=o.Name
    if n=="Chest" or n:find("Chest") or n:find("Treasure") then return true end
    return false
end
local function addChest(o) if isChest(o) then chests[o]=true end end
local function fullScan()
    chests={}
    local cf=workspace:FindFirstChild("Chests")
    if cf then for _,o in ipairs(cf:GetChildren()) do addChest(o) end end
    for _,o in ipairs(workspace:GetChildren()) do addChest(o) end
    local ef=workspace:FindFirstChild("Enemies")
    if ef then for _,o in ipairs(ef:GetChildren()) do addChest(o) end end
    local n=0; for _ in pairs(chests) do n=n+1 end
    return n
end
pcall(fullScan)
workspace.DescendantAdded:Connect(function(o) if isChest(o) then chests[o]=true end end)
task.spawn(function()
    while not killed do
        task.wait(3)
        for o in pairs(chests) do if not o.Parent then chests[o]=nil end end
    end
end)
task.spawn(function()
    while not killed do
        task.wait(0.4)
        if S.autoChest then
            local r=gr()
            if r then
                local mp=r.Position
                local best,bd=nil,S.chestRange
                for o in pairs(chests) do
                    local p=o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or o
                    if p and p.Position then
                        local d=(p.Position-mp).Magnitude
                        if d<bd then bd=d; best=p end
                    end
                end
                if best then tp(best.Position); task.wait(0.2) end
            end
        end
    end
end)

-- UI (те же цвета)
local BG=Color3.fromRGB(22,26,42)
local BG2=Color3.fromRGB(30,36,58)
local BG3=Color3.fromRGB(42,50,78)
local BG4=Color3.fromRGB(58,68,105)
local TXT=Color3.fromRGB(240,245,255)
local SUB=Color3.fromRGB(160,175,210)
local ACC=Color3.fromRGB(80,160,255)
local ACC2=Color3.fromRGB(120,100,255)
local GRN=Color3.fromRGB(80,220,140)
local RED=Color3.fromRGB(240,90,110)

local sg=Instance.new("ScreenGui")
sg.Name="BinHubV27"; sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=pg
local function crn(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function tw(o,t,p) TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end

local nh=Instance.new("Frame")
nh.Size=UDim2.new(0,280,1,-40); nh.Position=UDim2.new(1,-300,0,20)
nh.BackgroundTransparency=1; nh.ZIndex=100; nh.Parent=sg
local nll=Instance.new("UIListLayout",nh)
nll.Padding=UDim.new(0,6); nll.SortOrder=Enum.SortOrder.LayoutOrder
local function notify(t,x,col)
    col=col or ACC
    local b=Instance.new("Frame")
    b.Size=UDim2.new(1,0,0,56); b.BackgroundColor3=BG2
    b.BorderSizePixel=0; b.ZIndex=101; b.Parent=nh
    crn(b,10)
    local stripe=Instance.new("Frame")
    stripe.Size=UDim2.new(0,4,1,-12); stripe.Position=UDim2.new(0,6,0,6)
    stripe.BackgroundColor3=col; stripe.BorderSizePixel=0; stripe.ZIndex=102; stripe.Parent=b
    crn(stripe,2)
    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-24,0,20); lb.Position=UDim2.new(0,18,0,8)
    lb.BackgroundTransparency=1; lb.Text=t; lb.TextColor3=col
    lb.Font=Enum.Font.GothamBold; lb.TextSize=13; lb.ZIndex=102
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=b
    local ld=Instance.new("TextLabel")
    ld.Size=UDim2.new(1,-24,0,18); ld.Position=UDim2.new(0,18,0,28)
    ld.BackgroundTransparency=1; ld.Text=x; ld.TextColor3=SUB
    ld.Font=Enum.Font.Gotham; ld.TextSize=11; ld.ZIndex=102
    ld.TextXAlignment=Enum.TextXAlignment.Left; ld.Parent=b
    b.Position=UDim2.new(1,40,0,0)
    tw(b,0.3,{Position=UDim2.new(0,0,0,0)})
    task.delay(3,function()
        if b and b.Parent then
            tw(b,0.3,{Position=UDim2.new(1,40,0,0)})
            task.wait(0.4); b:Destroy()
        end
    end)
end

local VK="h00x"; local keyOk=false
local kb=Instance.new("Frame")
kb.Size=UDim2.new(1,0,1,0); kb.BackgroundColor3=Color3.fromRGB(0,0,0)
kb.BackgroundTransparency=0.3; kb.BorderSizePixel=0
kb.ZIndex=200; kb.Parent=sg
local kg=Instance.new("Frame")
kg.Size=UDim2.new(0,360,0,260); kg.Position=UDim2.new(0.5,-180,0.5,-130)
kg.BackgroundColor3=BG; kg.BorderSizePixel=0; kg.ZIndex=201; kg.Parent=sg
crn(kg,16)
local kgB=Instance.new("UIStroke"); kgB.Color=ACC; kgB.Thickness=2; kgB.Parent=kg
local kLogo=Instance.new("TextLabel")
kLogo.Size=UDim2.new(1,0,0,50); kLogo.Position=UDim2.new(0,0,0,20)
kLogo.BackgroundTransparency=1; kLogo.Text="⚡"
kLogo.TextColor3=ACC; kLogo.Font=Enum.Font.GothamBold
kLogo.TextSize=42; kLogo.ZIndex=202; kLogo.Parent=kg
local kT=Instance.new("TextLabel")
kT.Size=UDim2.new(1,0,0,24); kT.Position=UDim2.new(0,0,0,76)
kT.BackgroundTransparency=1; kT.Text="Bin's Blox Fruits"
kT.TextColor3=TXT; kT.Font=Enum.Font.GothamBold
kT.TextSize=17; kT.ZIndex=202; kT.Parent=kg
local kS=Instance.new("TextLabel")
kS.Size=UDim2.new(1,0,0,16); kS.Position=UDim2.new(0,0,0,102)
kS.BackgroundTransparency=1; kS.Text="v27 · enter key"
kS.TextColor3=SUB; kS.Font=Enum.Font.Gotham
kS.TextSize=11; kS.ZIndex=202; kS.Parent=kg
local kBox=Instance.new("TextBox")
kBox.Size=UDim2.new(1,-60,0,42); kBox.Position=UDim2.new(0,30,0,140)
kBox.BackgroundColor3=BG3; kBox.BorderSizePixel=0
kBox.Text=""; kBox.PlaceholderText="🔑 ключ..."
kBox.PlaceholderColor3=SUB; kBox.TextColor3=TXT
kBox.Font=Enum.Font.GothamBold; kBox.TextSize=15
kBox.ClearTextOnFocus=false; kBox.ZIndex=202; kBox.Parent=kg
crn(kBox,10)
local kBtn=Instance.new("TextButton")
kBtn.Size=UDim2.new(1,-60,0,44); kBtn.Position=UDim2.new(0,30,0,192)
kBtn.BackgroundColor3=ACC; kBtn.Text="UNLOCK"
kBtn.TextColor3=Color3.fromRGB(255,255,255); kBtn.Font=Enum.Font.GothamBold
kBtn.TextSize=14; kBtn.AutoButtonColor=false; kBtn.ZIndex=202; kBtn.Parent=kg
crn(kBtn,10)
kBtn.MouseButton1Click:Connect(function()
    if kBox.Text==VK then
        keyOk=true
        kb:Destroy(); kg:Destroy()
        notify("✓","Добро пожаловать, "..plr.Name,GRN)
    else
        kBox.Text=""
        kBox.PlaceholderText="❌ неверный ключ"
        kBox.PlaceholderColor3=RED
        task.delay(1.2,function()
            if kBox and kBox.Parent then
                kBox.PlaceholderText="🔑 ключ..."
                kBox.PlaceholderColor3=SUB
            end
        end)
    end
end)

local ob=Instance.new("TextButton")
ob.Size=UDim2.new(0,56,0,56); ob.Position=UDim2.new(0,20,0,100)
ob.BackgroundColor3=BG2; ob.Text="⚡"; ob.TextColor3=ACC
ob.Font=Enum.Font.GothamBold; ob.TextSize=26
ob.AutoButtonColor=false; ob.Visible=false; ob.ZIndex=10; ob.Parent=sg
crn(ob,12)
local obS=Instance.new("UIStroke"); obS.Color=ACC; obS.Thickness=2; obS.Parent=ob

local main=Instance.new("Frame")
main.Size=UDim2.new(0,540,0,500)
main.Position=UDim2.new(0,90,0,100)
main.BackgroundColor3=BG; main.BorderSizePixel=0
main.Visible=false; main.Active=true; main.ClipsDescendants=true
main.ZIndex=4; main.Parent=sg
crn(main,14)
local mainS=Instance.new("UIStroke"); mainS.Color=ACC; mainS.Thickness=2; mainS.Parent=main

local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,44); tb.BackgroundColor3=BG2
tb.BorderSizePixel=0; tb.ZIndex=5; tb.Parent=main
crn(tb,14)
local tbIcon=Instance.new("TextLabel")
tbIcon.Size=UDim2.new(0,32,0,32); tbIcon.Position=UDim2.new(0,8,0.5,-16)
tbIcon.BackgroundColor3=BG3; tbIcon.Text="⚡"; tbIcon.TextColor3=ACC
tbIcon.Font=Enum.Font.GothamBold; tbIcon.TextSize=18; tbIcon.ZIndex=6; tbIcon.Parent=tb
crn(tbIcon,8)
local tbTitle=Instance.new("TextLabel")
tbTitle.Size=UDim2.new(1,-140,0,18); tbTitle.Position=UDim2.new(0,48,0,6)
tbTitle.BackgroundTransparency=1; tbTitle.Text="Bin's Blox Fruits"
tbTitle.TextColor3=TXT; tbTitle.Font=Enum.Font.GothamBold; tbTitle.TextSize=13
tbTitle.TextXAlignment=Enum.TextXAlignment.Left; tbTitle.ZIndex=6; tbTitle.Parent=tb
local tbSub=Instance.new("TextLabel")
tbSub.Size=UDim2.new(1,-140,0,14); tbSub.Position=UDim2.new(0,48,0,24)
tbSub.BackgroundTransparency=1; tbSub.Text="v27 · "..plr.Name
tbSub.TextColor3=SUB; tbSub.Font=Enum.Font.Gotham; tbSub.TextSize=10
tbSub.TextXAlignment=Enum.TextXAlignment.Left; tbSub.ZIndex=6; tbSub.Parent=tb
local cbtn=Instance.new("TextButton")
cbtn.Size=UDim2.new(0,28,0,28); cbtn.Position=UDim2.new(1,-36,0.5,-14)
cbtn.BackgroundColor3=BG3; cbtn.Text="✕"; cbtn.TextColor3=SUB
cbtn.Font=Enum.Font.GothamBold; cbtn.TextSize=13
cbtn.AutoButtonColor=false; cbtn.ZIndex=6; cbtn.Parent=tb
crn(cbtn,8)

local dragging=false; local dragStart, startPos
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=main.Position
    end
end)
tb.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=false
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(0,60,1,-52); tabBar.Position=UDim2.new(0,0,0,44)
tabBar.BackgroundColor3=BG2; tabBar.BorderSizePixel=0
tabBar.ZIndex=5; tabBar.Parent=main

local pages={}; local tabs={}
local TN={"farm","boss","quest","stat","tp","misc"}
local TI={"⚔","👑","📜","📊","🌀","⚙"}
for i,name in ipairs(TN) do
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-8,0,48); b.Position=UDim2.new(0,4,0,4+(i-1)*52)
    b.BackgroundColor3=BG2; b.Text=TI[i]; b.TextColor3=SUB
    b.Font=Enum.Font.GothamBold; b.TextSize=20; b.AutoButtonColor=false
    b.ZIndex=6; b.Parent=tabBar
    crn(b,10)
    tabs[name]=b
end
local function selTab(name)
    for n,b in pairs(tabs) do
        if n==name then b.BackgroundColor3=ACC; b.TextColor3=TXT
        else b.BackgroundColor3=BG2; b.TextColor3=SUB end
    end
    for n,p in pairs(pages) do p.Visible=(n==name) end
end
for name,b in pairs(tabs) do
    b.MouseButton1Click:Connect(function() selTab(name) end)
end

local ca=Instance.new("Frame")
ca.Size=UDim2.new(1,-68,1,-52); ca.Position=UDim2.new(0,64,0,48)
ca.BackgroundTransparency=1; ca.ClipsDescendants=true; ca.ZIndex=5; ca.Parent=main
for _,name in ipairs(TN) do
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0); p.BackgroundTransparency=1
    p.BorderSizePixel=0; p.ScrollBarThickness=4
    p.ScrollBarImageColor3=ACC; p.ScrollBarImageTransparency=0.3
    p.CanvasSize=UDim2.new(0,0,0,0); p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false; p.ZIndex=6; p.Parent=ca
    local lay=Instance.new("UIListLayout",p)
    lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",p)
    pad.PaddingRight=UDim.new(0,8); pad.PaddingLeft=UDim.new(0,8)
    pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
    pages[name]=p
end
selTab("farm")

local ordr=0
local function no() ordr=ordr+1; return ordr end
local function sect(parent,title)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    f.LayoutOrder=no(); f.ZIndex=6; f.Parent=parent
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=title; l.TextColor3=ACC
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end
local function tog(parent,name,desc,get,set)
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,46); c.BackgroundColor3=BG3
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,8)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-80,0,18); l.Position=UDim2.new(0,12,0,5)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=TXT
    l.Font=Enum.Font.GothamBold; l.TextSize=12; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    if desc and desc~="" then
        local d=Instance.new("TextLabel")
        d.Size=UDim2.new(1,-80,0,14); d.Position=UDim2.new(0,12,0,23)
        d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=SUB
        d.Font=Enum.Font.Gotham; d.TextSize=10; d.ZIndex=7
        d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=c
    end
    local tr=Instance.new("Frame")
    tr.Size=UDim2.new(0,42,0,22); tr.Position=UDim2.new(1,-52,0.5,-11)
    tr.BackgroundColor3=BG4; tr.BorderSizePixel=0; tr.ZIndex=7; tr.Parent=c; crn(tr,11)
    local k=Instance.new("Frame")
    k.Size=UDim2.new(0,16,0,16); k.Position=UDim2.new(0,3,0.5,-8)
    k.BackgroundColor3=SUB; k.BorderSizePixel=0; k.ZIndex=8; k.Parent=tr; crn(k,8)
    local hb=Instance.new("TextButton")
    hb.Size=UDim2.new(1,0,1,0); hb.BackgroundTransparency=1; hb.Text=""; hb.ZIndex=9; hb.Parent=c
    local function rf(a)
        local v=get()
        local i=TweenInfo.new(a and 0.2 or 0,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
        TS:Create(tr,i,{BackgroundColor3=v and GRN or BG4}):Play()
        TS:Create(k,i,{
            Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=v and Color3.fromRGB(255,255,255) or SUB,
        }):Play()
    end
    rf(false)
    hb.MouseButton1Click:Connect(function() set(not get()); rf(true) end)
end
local function sld(parent,name,mn,mx,st,get,set,suf)
    suf=suf or ""
    local c=Instance.new("Frame")
    c.Size=UDim2.new(1,0,0,58); c.BackgroundColor3=BG3
    c.BorderSizePixel=0; c.LayoutOrder=no(); c.ZIndex=6; c.Parent=parent
    crn(c,8)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-90,0,16); l.Position=UDim2.new(0,12,0,5)
    l.BackgroundTransparency=1; l.Text=name; l.TextColor3=TXT
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.ZIndex=7
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,80,0,16); vl.Position=UDim2.new(1,-90,0,5)
    vl.BackgroundTransparency=1
    vl.Text=string.format("%.1f",get())..suf
    vl.TextColor3=ACC; vl.Font=Enum.Font.GothamBold; vl.TextSize=11
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.ZIndex=7; vl.Parent=c
    local mi=Instance.new("TextButton")
    mi.Size=UDim2.new(0,26,0,20); mi.Position=UDim2.new(0,12,0,28)
    mi.BackgroundColor3=BG2; mi.Text="−"; mi.TextColor3=TXT
    mi.Font=Enum.Font.GothamBold; mi.TextSize=13; mi.AutoButtonColor=false; mi.ZIndex=8; mi.Parent=c; crn(mi,5)
    local pl=Instance.new("TextButton")
    pl.Size=UDim2.new(0,26,0,20); pl.Position=UDim2.new(0,44,0,28)
    pl.BackgroundColor3=BG2; pl.Text="+"; pl.TextColor3=TXT
    pl.Font=Enum.Font.GothamBold; pl.TextSize=13; pl.AutoButtonColor=false; pl.ZIndex=8; pl.Parent=c; crn(pl,5)
    local function up(v)
        v=math.clamp(v,mn,mx); set(v)
        vl.Text=string.format("%.1f",v)..suf
    end
    mi.MouseButton1Click:Connect(function() up(get()-st) end)
    pl.MouseButton1Click:Connect(function() up(get()+st) end)
end
local function act(parent,text,cb,col)
    col=col or ACC
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=col
    b.Text=text; b.TextColor3=TXT; b.Font=Enum.Font.GothamBold
    b.TextSize=12; b.AutoButtonColor=false; b.LayoutOrder=no(); b.ZIndex=6; b.Parent=parent
    crn(b,8)
    b.MouseButton1Click:Connect(function()
        if killed then return end
        local ok,err=pcall(cb)
        if not ok then notify("Error",tostring(err),RED) end
    end)
end
local function listBtn(parent,text,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,28); b.BackgroundColor3=BG3
    b.Text=text; b.TextColor3=TXT; b.Font=Enum.Font.Gotham
    b.TextSize=11; b.TextXAlignment=Enum.TextXAlignment.Left
    b.AutoButtonColor=false; b.LayoutOrder=no(); b.ZIndex=6; b.Parent=parent
    crn(b,6)
    b.MouseButton1Click:Connect(function()
        if killed then return end
        local ok,err=pcall(cb)
        if not ok then notify("Error",tostring(err),RED) end
    end)
end

-- FARM
sect(pages.farm,"ФЕРМА")
tog(pages.farm,"Авто уровень","Любой NPC",function() return S.farmLevel end,function(v) S.farmLevel=v end)
tog(pages.farm,"Авто пираты","Приоритет",function() return S.farmPirates end,function(v) S.farmPirates=v end)
tog(pages.farm,"Авто морпехи","Приоритет",function() return S.farmMarines end,function(v) S.farmMarines=v end)
tog(pages.farm,"Авто боссы","Приоритет",function() return S.farmBosses end,function(v) S.farmBosses=v end)
sect(pages.farm,"БОЙ (хитбокс 40)")
sld(pages.farm,"Скорость атаки",0.1,2,0.05,function() return S.speed end,function(v) S.speed=v end,"s")
sld(pages.farm,"Высота полёта",3,15,1,function() return S.hover end,function(v) S.hover=v end,"")
tog(pages.farm,"Фикс камеры","",function() return S.lockCam end,function(v) S.lockCam=v end)
tog(pages.farm,"Килл-аура","",function() return S.killAura end,function(v) S.killAura=v end)
sld(pages.farm,"Радиус ауры",10,300,5,function() return S.auraRange end,function(v) S.auraRange=v end,"")
sect(pages.farm,"ПОЛЁТ")
tog(pages.farm,"Полёт","WASD+Space/Ctrl",function() return S.fly end,function(v) S.fly=v end)
sld(pages.farm,"Скорость",10,400,5,function() return S.flySpeed end,function(v) S.flySpeed=v end,"")
sect(pages.farm,"АВТО-СБОР")
tog(pages.farm,"Авто сундуки","Умный ТП",function() return S.autoChest end,function(v) S.autoChest=v end)
sld(pages.farm,"Радиус",100,5000,50,function() return S.chestRange end,function(v) S.chestRange=v end,"")
act(pages.farm,"📦  Сканировать сундуки",function()
    local cnt=fullScan()
    notify("Сундуки","Найдено: "..cnt,GRN)
end,ACC2)

-- BOSS
sect(pages.boss,"ТЕЛЕПОРТ К БОССАМ")
for _,b in ipairs(BOSSES) do
    listBtn(pages.boss,"  👑 "..b.n.."  Lvl "..b.lv,function()
        S.selBoss=b.n
        notify("Босс","Выбран: "..b.n,ACC2)
    end)
end
act(pages.boss,"👑  ТП к выбранному",function()
    for _,b in ipairs(BOSSES) do
        if b.n==S.selBoss then
            local ok=tp(b.p)
            if ok then notify("Босс","ТП: "..b.n,RED)
            else notify("Босс","Ошибка",RED) end
            break
        end
    end
end,RED)

-- QUEST
sect(pages.quest,"АВТО-КВЕСТ")
tog(pages.quest,"Авто-квест","Цикл",function() return S.autoQuest end,function(v) S.autoQuest=v end)
for _,q in ipairs(QUESTS) do
    listBtn(pages.quest,"  📜 "..q.n.."  Lvl "..q.lv,function()
        S.questName=q.n
        notify("Квест","Выбран: "..q.n,ACC2)
    end)
end
act(pages.quest,"📜  Начать выбранный",function()
    for _,q in ipairs(QUESTS) do
        if q.n==S.questName then
            tp(q.p); task.wait(0.8)
            local ok=startQ(q.npc,q.lv)
            if ok then notify("Квест","Начат: "..q.n,GRN)
            else notify("Квест","Ремоут не найден",RED) end
            break
        end
    end
end,ACC2)

-- STAT
sect(pages.stat,"АВТО-СТАТЫ")
tog(pages.stat,"Авто-статы","Только если есть поинты",function() return S.autoStat end,function(v) S.autoStat=v end)
for _,sn in ipairs({"Melee","Defense","Sword","Gun","Blox Fruit"}) do
    listBtn(pages.stat,"  ⚔ "..sn,function()
        S.statName=sn
        notify("Стат","Выбран: "..sn,ACC)
    end)
end
sect(pages.stat,"АВТО-МАСТЕРСТВО ФРУКТА")
tog(pages.stat,"Авто-мастерство","Спам Z X C V",function() return S.autoMastery end,function(v) S.autoMastery=v end)

-- TP
sect(pages.tp,"ГОРОДА")
for _,l in ipairs(CITIES) do
    listBtn(pages.tp,"  🌍 "..l.n,function()
        S.selTP=l.n
        notify("Город","Выбран: "..l.n,ACC)
    end)
end
act(pages.tp,"✨  ТП к выбранному городу",function()
    for _,l in ipairs(CITIES) do
        if l.n==S.selTP then
            tp(l.p)
            notify("Город","ТП: "..l.n,ACC)
            break
        end
    end
end,ACC)
act(pages.tp,"🛑  Остановить полёт",function()
    if hoverT then rmHB(hoverT) end
    setHover(nil); notify("Полёт","Выкл",RED)
end,BG4)

-- MISC — ИНФО + ВЫХОД
sect(pages.misc,"ИНФО")
act(pages.misc,"🔄  Обновить кэш NPC",function()
    refresh(); notify("Кэш","NPCs: "..#cache,GRN)
end,BG4)
local ic=Instance.new("Frame")
ic.Size=UDim2.new(1,0,0,100); ic.BackgroundColor3=BG3
ic.BorderSizePixel=0; ic.LayoutOrder=no(); ic.ZIndex=6; ic.Parent=pages.misc
crn(ic,8)
local it=Instance.new("TextLabel")
it.Size=UDim2.new(1,-16,1,-12); it.Position=UDim2.new(0,12,0,6)
it.BackgroundTransparency=1
it.Text="Bin's Blox Fruits Hub v27\nkey: h00x · hitbox 40\n\nГорода: "..#CITIES.." · Боссы: "..#BOSSES.." · Квесты: "..#QUESTS.."\nСделано Bin & Steve · nya~"
it.TextColor3=SUB; it.Font=Enum.Font.Gotham; it.TextSize=10
it.TextXAlignment=Enum.TextXAlignment.Left
it.TextYAlignment=Enum.TextYAlignment.Top
it.TextWrapped=true; it.ZIndex=7; it.Parent=ic

sect(pages.misc,"ОПАСНАЯ ЗОНА")
act(pages.misc,"🚪  ВЫЙТИ ИЗ ЧИТА (закрыть всё)",function()
    killed=true
    -- отключить hover
    if hoverT then rmHB(hoverT) end
    -- отключить fly
    if flyCon then flyCon:Disconnect(); flyCon=nil end
    if hum then pcall(function() hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end) end
    -- убрать ESP
    local ef=workspace:FindFirstChild("BinESP")
    if ef then ef:Destroy() end
    -- уничтожить GUI
    task.wait(0.1)
    sg:Destroy()
    print("[Bin's Hub v27] unloaded by user.")
end,RED)

-- toggle
local isOpen=false
local function tglW()
    isOpen=not isOpen
    main.Visible=isOpen
end
task.spawn(function()
    while not keyOk do task.wait(0.3) end
    ob.Visible=true
    notify("✓ Готово","Нажми ⚡ слева",ACC)
    task.spawn(function()
        local g=Instance.new("TextLabel")
        g.Size=UDim2.new(0,600,0,80); g.Position=UDim2.new(0.5,-300,0.4,-40)
        g.BackgroundTransparency=1
        g.Text="⚡ Добро пожаловать, "..plr.Name.." ⚡"
        g.TextColor3=ACC; g.Font=Enum.Font.GothamBold
        g.TextSize=26; g.TextStrokeTransparency=0
        g.TextStrokeColor3=ACC2; g.ZIndex=300; g.Parent=sg
        task.wait(2)
        tw(g,0.5,{TextTransparency=1})
        task.wait(0.5); g:Destroy()
    end)
end)
ob.MouseButton1Click:Connect(function() if keyOk and not killed then tglW() end end)
cbtn.MouseButton1Click:Connect(tglW)
print("[Bin's Hub v27] loaded. key: h00x")
