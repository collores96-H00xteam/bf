--- v26 beta
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
local function gr()
    if not char or not char.Parent then
        if plr.Character and plr.Character.Parent then bind(plr.Character) end
    end
    if not root or not root.Parent then return nil end
    return root
end
local function getY(x,z,from)
    local ok,res=pcall(function()
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances=char and {char} or {}
        return workspace:Raycast(Vector3.new(x,from or 500,z),Vector3.new(0,-2000,0),rp)
    end)
    if ok and res then return res.Position.Y end
    return nil
end
local function tp(pos)
    local r=gr(); if not r then return false end
    local y=getY(pos.X,pos.Z,pos.Y+500) or pos.Y
    local t=Vector3.new(pos.X,y+3.5,pos.Z)
    if hum then pcall(function() hum:MoveTo(t) end) end
    pcall(function() r.CFrame=CFrame.new(t) end)
    task.wait(0.1)
    pcall(function() r.CFrame=CFrame.new(t) end)
    return true
end
local function getRem()
    local r=RS:FindFirstChild("Remotes")
    return r and (r:FindFirstChild("CommF_") or r:FindFirstChild("CommE_")) or nil
end

-- ============================================================
-- ЛОКАЛИЗАЦИЯ
-- ============================================================
local LANG = "ru"  -- "ru" или "en"

local STR = {
    ru = {
        title="Bin's Blox Fruits Hub",
        subtitle="v26 · введи ключ",
        key="🔑 ключ...",
        key_placeholder="🔑 ключ...",
        key_wrong="❌ неверный ключ",
        unlock="РАЗБЛОКИРОВАТЬ",
        welcome="⚡ Добро пожаловать, ",
        welcome_end=" ⚡",
        unlocked="✓ Разблокировано",
        welcome_toast="Привет, ",
        ready="✓ Готово",
        ready_hint="Нажми ⚡ слева",
        // TABS
        farm="ФЕРМА", boss="БОССЫ", quest="КВЕСТЫ", stat="СТАТЫ", tp="ТЕЛЕПОРТ", misc="ЕЩЁ",
        // FARM
        farming="ФЕРМА",
        auto_level="Авто уровень", auto_level_desc="Любой NPC",
        auto_pirates="Авто пираты", auto_pirates_desc="Приоритет",
        auto_marines="Авто морпехи", auto_marines_desc="Приоритет",
        auto_bosses="Авто боссы", auto_bosses_desc="Приоритет",
        combat="БОЙ (хитбокс 40)",
        attack_speed="Скорость атаки", hover_height="Высота полёта",
        lock_camera="Фикс камеры", kill_aura="Килл-аура", aura_range="Радиус ауры",
        fly="ПОЛЁТ", fly_toggle="Полёт", fly_desc="WASD + Space/Ctrl", fly_speed="Скорость полёта",
        auto_collect="АВТО-СБОР",
        auto_chest="Авто сундуки", auto_chest_desc="Умный ТП",
        chest_range="Радиус сундуков",
        scan_chests="📦  Сканировать сундуки",
        // BOSS
        boss_tp="ТЕЛЕПОРТ К БОССАМ",
        boss_go="👑  ТП к выбранному боссу",
        boss_selected="Босс выбран: ",
        boss_warped="ТП к: ",
        // QUEST
        auto_quest="АВТО-КВЕСТ",
        auto_quest_toggle="Авто-квест", auto_quest_desc="Цикл",
        quest_start="📜  Начать выбранный квест",
        quest_selected="Квест выбран: ",
        quest_started="Квест начат: ",
        quest_no_remote="Ремоут не найден",
        // STAT
        auto_stat="АВТО-СТАТЫ",
        auto_stat_toggle="Авто-статы", auto_stat_desc="Только если есть поинты",
        auto_mastery="АВТО-МАСТЕРСТВО ФРУКТА",
        auto_mastery_toggle="Авто-мастерство", auto_mastery_desc="Спам Z X C V",
        stat_selected="Стат выбран: ",
        // TP
        cities="ГОРОДА",
        tp_city="✨  ТП к выбранному городу",
        city_selected="Город выбран: ",
        city_warped="Телепорт: ",
        stop_hover="🛑  Остановить полёт",
        hover_off="Полёт выключен",
        // MISC
        info="ИНФО",
        refresh_cache="🔄  Обновить кэш NPC",
        cache_refreshed="Кэш обновлён",
        made_by="Сделано Bin & Steve · nya~",
        stat_points="Поинтов",
        // notifications
        chest_scan="Сундуки", chest_found="Найдено: ",
        boss_sel="Босс", stat_sel="Стат", city_sel="Город", quest_sel="Квест",
        hover="Полёт",
        // language
        lang="ЯЗЫК", lang_current="Русский",
    },
    en = {
        title="Bin's Blox Fruits Hub",
        subtitle="v26 · enter key",
        key="🔑 key...",
        key_placeholder="🔑 key...",
        key_wrong="❌ wrong key",
        unlock="UNLOCK",
        welcome="⚡ Welcome, ",
        welcome_end=" ⚡",
        unlocked="✓ Unlocked",
        welcome_toast="Hi, ",
        ready="✓ Ready",
        ready_hint="Click ⚡ on the left",
        farm="FARM", boss="BOSSES", quest="QUESTS", stat="STATS", tp="TELEPORT", misc="MISC",
        farming="FARMING",
        auto_level="Auto Level", auto_level_desc="Any NPC",
        auto_pirates="Auto Pirates", auto_pirates_desc="Prioritize",
        auto_marines="Auto Marines", auto_marines_desc="Prioritize",
        auto_bosses="Auto Bosses", auto_bosses_desc="Prioritize",
        combat="COMBAT (hitbox 40)",
        attack_speed="Attack Speed", hover_height="Hover Height",
        lock_camera="Lock Camera", kill_aura="Kill Aura", aura_range="Aura Range",
        fly="FLY", fly_toggle="Fly", fly_desc="WASD + Space/Ctrl", fly_speed="Fly Speed",
        auto_collect="AUTO COLLECT",
        auto_chest="Auto Chest", auto_chest_desc="Smart TP",
        chest_range="Chest Range",
        scan_chests="📦  Scan Chests",
        boss_tp="BOSS TELEPORT",
        boss_go="👑  TP to Selected Boss",
        boss_selected="Boss selected: ",
        boss_warped="TP to: ",
        auto_quest="AUTO QUEST",
        auto_quest_toggle="Auto Quest", auto_quest_desc="Loop",
        quest_start="📜  Start Selected Quest",
        quest_selected="Quest selected: ",
        quest_started="Quest started: ",
        quest_no_remote="Remote not found",
        auto_stat="AUTO STAT",
        auto_stat_toggle="Auto Stat", auto_stat_desc="Only if points>0",
        auto_mastery="AUTO FRUIT MASTERY",
        auto_mastery_toggle="Auto Mastery", auto_mastery_desc="Spam Z X C V",
        stat_selected="Stat selected: ",
        cities="CITIES",
        tp_city="✨  TP to Selected City",
        city_selected="City selected: ",
        city_warped="Warped: ",
        stop_hover="🛑  Stop Hover",
        hover_off="Hover off",
        info="INFO",
        refresh_cache="🔄  Refresh NPC Cache",
        cache_refreshed="Cache refreshed",
        made_by="Made by Bin & Steve · nya~",
        stat_points="Points",
        chest_scan="Chests", chest_found="Found: ",
        boss_sel="Boss", stat_sel="Stat", city_sel="City", quest_sel="Quest",
        hover="Hover",
        lang="LANGUAGE", lang_current="English",
    }
}
local function T(key)
    local tbl = STR[LANG] or STR.ru
    return tbl[key] or STR.ru[key] or key
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
    if hum then pcall(function() hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end) end
end
task.spawn(function()
    local last=false
    while task.wait(0.1) do
        if S.fly and not last then startFly() end
        if not S.fly and last then stopFly() end
        last=S.fly
    end
end)

local function getPoints()
    local d=plr:FindFirstChild("Data"); if not d then return 0 end
    local s=d:FindFirstChild("Stats"); if not s then return 0 end
    local p=s:FindFirstChild("Points"); if not p then return 0 end
    return p.Value or 0
end
task.spawn(function()
    while task.wait(1.5) do
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
task.spawn(function()
    while task.wait(1.5) do
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
local function addChest(o)
    if isChest(o) then chests[o]=true end
end
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
    while task.wait(3) do
        for o in pairs(chests) do if not o.Parent then chests[o]=nil end end
    end
end)
task.spawn(function()
    while task.wait(0.4) do
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

-- ============================================================
-- UI
-- ============================================================
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
sg.Name="BinHubV26"; sg.ResetOnSpawn=false
sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=pg
local function crn(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function tw(o,t,p) TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play() end

-- Notifications
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
        tw(b,0.3,{Position=UDim2.new(1,40,0,0)})
        task.wait(0.4); b:Destroy()
    end)
end

-- KEY
local VK="h00x"; local keyOk=false
local kb=Instance.new("Frame")
kb.Size=UDim2.new(1,0,1,0); kb.BackgroundColor3=Color3.fromRGB(0,0,0)
kb.BackgroundTransparency=0.3; kb.BorderSizePixel=0
kb.ZIndex=200; kb.Parent=sg
local kg=Instance.new("Frame")
kg.Size=UDim2.new(0,360,0,300); kg.Position=UDim2.new(0.5,-180,0.5,-150)
kg.BackgroundColor3=BG; kg.BorderSizePixel=0; kg.ZIndex=201; kg.Parent=sg
crn(kg,16)
local kgB=Instance.new("UIStroke")
kgB.Color=ACC; kgB.Thickness=2; kgB.Parent=kg
local kLogo=Instance.new("TextLabel")
kLogo.Size=UDim2.new(1,0,0,50); kLogo.Position=UDim2.new(0,0,0,20)
kLogo.BackgroundTransparency=1; kLogo.Text="⚡"
kLogo.TextColor3=ACC; kLogo.Font=Enum.Font.GothamBold
kLogo.TextSize=42; kLogo.ZIndex=202; kLogo.Parent=kg
local kT=Instance.new("TextLabel")
kT.Size=UDim2.new(1,0,0,24); kT.Position=UDim2.new(0,0,0,76)
kT.BackgroundTransparency=1; kT.Text=T("title")
kT.TextColor3=TXT; kT.Font=Enum.Font.GothamBold
kT.TextSize=17; kT.ZIndex=202; kT.Parent=kg
local kS=Instance.new("TextLabel")
kS.Size=UDim2.new(1,0,0,16); kS.Position=UDim2.new(0,0,0,102)
kS.BackgroundTransparency=1; kS.Text=T("subtitle")
kS.TextColor3=SUB; kS.Font=Enum.Font.Gotham
kS.TextSize=11; kS.ZIndex=202; kS.Parent=kg

-- Language toggle in key window
local kLangBtn=Instance.new("TextButton")
kLangBtn.Size=UDim2.new(0,80,0,24); kLangBtn.Position=UDim2.new(1,-90,0,30)
kLangBtn.BackgroundColor3=BG3; kLangBtn.Text="RU / EN"
kLangBtn.TextColor3=ACC; kLangBtn.Font=Enum.Font.GothamBold
kLangBtn.TextSize=11; kLangBtn.AutoButtonColor=false
kLangBtn.ZIndex=202; kLangBtn.Parent=kg
crn(kLangBtn,6)
kLangBtn.MouseButton1Click:Connect(function()
    LANG = (LANG == "ru") and "en" or "ru"
    kT.Text = T("title")
    kS.Text = T("subtitle")
    kBox.PlaceholderText = T("key_placeholder")
    kBtn.Text = T("unlock")
end)

local kBox=Instance.new("TextBox")
kBox.Size=UDim2.new(1,-60,0,42); kBox.Position=UDim2.new(0,30,0,140)
kBox.BackgroundColor3=BG3; kBox.BorderSizePixel=0
kBox.Text=""; kBox.PlaceholderText=T("key_placeholder")
kBox.PlaceholderColor3=SUB; kBox.TextColor3=TXT
kBox.Font=Enum.Font.GothamBold; kBox.TextSize=15
kBox.ClearTextOnFocus=false; kBox.ZIndex=202; kBox.Parent=kg
crn(kBox,10)
local kBtn=Instance.new("TextButton")
kBtn.Size=UDim2.new(1,-60,0,44); kBtn.Position=UDim2.new(0,30,0,200)
kBtn.BackgroundColor3=ACC; kBtn.Text=T("unlock")
kBtn.TextColor3=Color3.fromRGB(255,255,255); kBtn.Font=Enum.Font.GothamBold
kBtn.TextSize=14; kBtn.AutoButtonColor=false; kBtn.ZIndex=202; kBtn.Parent=kg
crn(kBtn,10)
kBtn.MouseButton1Click:Connect(function()
    if kBox.Text==VK then
        keyOk=true
        kb:Destroy(); kg:Destroy()
        notify(T("unlocked"), T("welcome_toast")..plr.Name, GRN)
    else
        kBox.Text=""
        kBox.PlaceholderText=T("key_wrong")
        kBox.PlaceholderColor3=RED
        task.delay(1.2,function()
            if kBox and kBox.Parent then
                kBox.PlaceholderText=T("key_placeholder")
                kBox.PlaceholderColor3=SUB
            end
        end)
    end
end)

-- OPEN BTN
local ob=Instance.new("TextButton")
ob.Size=UDim2.new(0,56,0,56); ob.Position=UDim2.new(0,20,0,100)
ob.BackgroundColor3=BG2; ob.Text="⚡"; ob.TextColor3=ACC
ob.Font=Enum.Font.GothamBold; ob.TextSize=26
ob.AutoButtonColor=false; ob.Visible=false; ob.ZIndex=10; ob.Parent=sg
crn(ob,12)
local obS=Instance.new("UIStroke"); obS.Color=ACC; obS.Thickness=2; obS.Parent=ob

-- MAIN
local main=Instance.new("Frame")
main.Size=UDim2.new(0,540,0,500)
main.Position=UDim2.new(0,90,0,100)
main.BackgroundColor3=BG; main.BorderSizePixel=0
main.Visible=false; main.Active=true; main.ClipsDescendants=true
main.ZIndex=4; main.Parent=sg
crn(main,14)
local mainS=Instance.new("UIStroke"); mainS.Color=ACC; mainS.Thickness=2; mainS.Parent=main

-- TITLE BAR (drag)
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
tbTitle.Size=UDim2.new(1,-200,0,18); tbTitle.Position=UDim2.new(0,48,0,6)
tbTitle.BackgroundTransparency=1; tbTitle.Text=T("title")
tbTitle.TextColor3=TXT; tbTitle.Font=Enum.Font.GothamBold; tbTitle.TextSize=13
tbTitle.TextXAlignment=Enum.TextXAlignment.Left; tbTitle.ZIndex=6; tbTitle.Parent=tb

local tbSub=Instance.new("TextLabel")
tbSub.Size=UDim2.new(1,-200,0,14); tbSub.Position=UDim2.new(0,48,0,24)
tbSub.BackgroundTransparency=1; tbSub.Text="v26 · "..plr.Name
tbSub.TextColor3=SUB; tbSub.Font=Enum.Font.Gotham; tbSub.TextSize=10
tbSub.TextXAlignment=Enum.TextXAlignment.Left; tbSub.ZIndex=6; tbSub.Parent=tb

-- LANG TOGGLE в панели
local langBtn=Instance.new("TextButton")
langBtn.Size=UDim2.new(0,70,0,26); langBtn.Position=UDim2.new(1,-108,0.5,-13)
langBtn.BackgroundColor3=BG3; langBtn.Text=LANG:upper()
langBtn.TextColor3=ACC; langBtn.Font=Enum.Font.GothamBold
langBtn.TextSize=11; langBtn.AutoButtonColor=false
langBtn.ZIndex=6; langBtn.Parent=tb
crn(langBtn,6)

local cbtn=Instance.new("TextButton")
cbtn.Size=UDim2.new(0,28,0,28); cbtn.Position=UDim2.new(1,-32,0.5,-14)
cbtn.BackgroundColor3=BG3; cbtn.Text="✕"; cbtn.TextColor3=SUB
cbtn.Font=Enum.Font.GothamBold; cbtn.TextSize=13
cbtn.AutoButtonColor=false; cbtn.ZIndex=6; cbtn.Parent=tb
crn(cbtn,8)

-- ПЕРЕТАСКИВАНИЕ
local dragging=false; local dragStart, startPos
local function beginDrag(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPos=main.Position
    end
end
local function endDrag(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=false
    end
end
local function moveDrag(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end
tb.InputBegan:Connect(beginDrag)
tb.InputEnded:Connect(endDrag)
UIS.InputChanged:Connect(moveDrag)

-- TABS
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

-- Строим UI функцию чтобы перестраивать при смене языка
local ordr=0
local function resetOrder() ordr=0 end
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
        local ok,err=pcall(cb)
        if not ok then notify("Error",tostring(err),RED) end
    end)
end

-- ФУНКЦИЯ ПОСТРОЕНИЯ ВСЕХ ВКЛАДОК
local function buildUI()
    -- очистить всё
    for _,p in pairs(pages) do
        for _,ch in ipairs(p:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
        end
    end
    resetOrder()

    -- FARM
    sect(pages.farm, T("farming"))
    tog(pages.farm, T("auto_level"), T("auto_level_desc"), function() return S.farmLevel end, function(v) S.farmLevel=v end)
    tog(pages.farm, T("auto_pirates"), T("auto_pirates_desc"), function() return S.farmPirates end, function(v) S.farmPirates=v end)
    tog(pages.farm, T("auto_marines"), T("auto_marines_desc"), function() return S.farmMarines end, function(v) S.farmMarines=v end)
    tog(pages.farm, T("auto_bosses"), T("auto_bosses_desc"), function() return S.farmBosses end, function(v) S.farmBosses=v end)
    sect(pages.farm, T("combat"))
    sld(pages.farm, T("attack_speed"), 0.1, 2, 0.05, function() return S.speed end, function(v) S.speed=v end, "s")
    sld(pages.farm, T("hover_height"), 3, 15, 1, function() return S.hover end, function(v) S.hover=v end, "")
    tog(pages.farm, T("lock_camera"), "", function() return S.lockCam end, function(v) S.lockCam=v end)
    tog(pages.farm, T("kill_aura"), "", function() return S.killAura end, function(v) S.killAura=v end)
    sld(pages.farm, T("aura_range"), 10, 300, 5, function() return S.auraRange end, function(v) S.auraRange=v end, "")
    sect(pages.farm, T("fly"))
    tog(pages.farm, T("fly_toggle"), T("fly_desc"), function() return S.fly end, function(v) S.fly=v end)
    sld(pages.farm, T("fly_speed"), 10, 400, 5, function() return S.flySpeed end, function(v) S.flySpeed=v end, "")
    sect(pages.farm, T("auto_collect"))
    tog(pages.farm, T("auto_chest"), T("auto_chest_desc"), function() return S.autoChest end, function(v) S.autoChest=v end)
    sld(pages.farm, T("chest_range"), 100, 5000, 50, function() return S.chestRange end, function(v) S.chestRange=v end, "")
    act(pages.farm, T("scan_chests"), function()
        local cnt=fullScan()
        notify(T("chest_scan"), T("chest_found")..cnt, GRN)
    end, ACC2)

    -- BOSS
    sect(pages.boss, T("boss_tp"))
    for _,b in ipairs(BOSSES) do
        listBtn(pages.boss, "  👑 "..b.n.."  Lvl "..b.lv, function()
            S.selBoss=b.n
            notify(T("boss_sel"), T("boss_selected")..b.n, ACC2)
        end)
    end
    act(pages.boss, T("boss_go"), function()
        for _,b in ipairs(BOSSES) do
            if b.n==S.selBoss then
                tp(b.p)
                notify(T("boss_sel"), T("boss_warped")..b.n, RED)
                break
            end
        end
    end, RED)

    -- QUEST
    sect(pages.quest, T("auto_quest"))
    tog(pages.quest, T("auto_quest_toggle"), T("auto_quest_desc"), function() return S.autoQuest end, function(v) S.autoQuest=v end)
    for _,q in ipairs(QUESTS) do
        listBtn(pages.quest, "  📜 "..q.n.."  Lvl "..q.lv, function()
            S.questName=q.n
            notify(T("quest_sel"), T("quest_selected")..q.n, ACC2)
        end)
    end
    act(pages.quest, T("quest_start"), function()
        for _,q in ipairs(QUESTS) do
            if q.n==S.questName then
                tp(q.p); task.wait(0.8)
                local ok=startQ(q.npc,q.lv)
                if ok then notify(T("quest_sel"), T("quest_started")..q.n, GRN)
                else notify(T("quest_sel"), T("quest_no_remote"), RED) end
                break
            end
        end
    end, ACC2)

    -- STAT
    sect(pages.stat, T("auto_stat"))
    tog(pages.stat, T("auto_stat_toggle"), T("auto_stat_desc"), function() return S.autoStat end, function(v) S.autoStat=v end)
    for _,sn in ipairs({"Melee","Defense","Sword","Gun","Blox Fruit"}) do
        listBtn(pages.stat, "  ⚔ "..sn, function()
            S.statName=sn
            notify(T("stat_sel"), T("stat_selected")..sn, ACC)
        end)
    end
    sect(pages.stat, T("auto_mastery"))
    tog(pages.stat, T("auto_mastery_toggle"), T("auto_mastery_desc"), function() return S.autoMastery end, function(v) S.autoMastery=v end)

    -- TP
    sect(pages.tp, T("cities"))
    for _,l in ipairs(CITIES) do
        listBtn(pages.tp, "  🌍 "..l.n, function()
            S.selTP=l.n
            notify(T("city_sel"), T("city_selected")..l.n, ACC)
        end)
    end
    act(pages.tp, T("tp_city"), function()
        for _,l in ipairs(CITIES) do
            if l.n==S.selTP then
                tp(l.p)
                notify(T("city_sel"), T("city_warped")..l.n, ACC)
                break
            end
        end
    end, ACC)
    act(pages.tp, T("stop_hover"), function()
        if hoverT then rmHB(hoverT) end
        setHover(nil); notify(T("hover"), T("hover_off"), RED)
    end, BG4)

    -- MISC
    sect(pages.misc, T("info"))
    act(pages.misc, T("refresh_cache"), function()
        refresh(); notify("Cache", "NPCs: "..#cache, GRN)
    end, BG4)
    local ic=Instance.new("Frame")
    ic.Size=UDim2.new(1,0,0,100); ic.BackgroundColor3=BG3
    ic.BorderSizePixel=0; ic.LayoutOrder=no(); ic.ZIndex=6; ic.Parent=pages.misc
    crn(ic,8)
    local it=Instance.new("TextLabel")
    it.Size=UDim2.new(1,-16,1,-12); it.Position=UDim2.new(0,12,0,6)
    it.BackgroundTransparency=1
    it.Text=T("title").." v26\nkey: h00x · hitbox 40\n\n"..T("cities")..": "..#CITIES.." · "..T("boss")..": "..#BOSSES.." · "..T("quest")..": "..#QUESTS.."\n"..T("made_by")
    it.TextColor3=SUB; it.Font=Enum.Font.Gotham; it.TextSize=10
    it.TextXAlignment=Enum.TextXAlignment.Left
    it.TextYAlignment=Enum.TextYAlignment.Top
    it.TextWrapped=true; it.ZIndex=7; it.Parent=ic
end
buildUI()

-- Language toggle button handler
langBtn.MouseButton1Click:Connect(function()
    LANG = (LANG == "ru") and "en" or "ru"
    langBtn.Text = LANG:upper()
    tbTitle.Text = T("title")
    notify(T("lang"), T("lang_current"), ACC)
    task.wait(0.05)
    buildUI()
    selTab("farm")
end)

-- Toggle
local isOpen=false
local function tglW()
    isOpen=not isOpen
    main.Visible=isOpen
end
task.spawn(function()
    while not keyOk do task.wait(0.3) end
    ob.Visible=true
    notify(T("ready"), T("ready_hint"), ACC)
    task.spawn(function()
        local g=Instance.new("TextLabel")
        g.Size=UDim2.new(0,600,0,80); g.Position=UDim2.new(0.5,-300,0.4,-40)
        g.BackgroundTransparency=1
        g.Text=T("welcome")..plr.Name..T("welcome_end")
        g.TextColor3=ACC; g.Font=Enum.Font.GothamBold
        g.TextSize=26; g.TextStrokeTransparency=0
        g.TextStrokeColor3=ACC2; g.ZIndex=300; g.Parent=sg
        task.wait(2)
        tw(g,0.5,{TextTransparency=1})
        task.wait(0.5); g:Destroy()
    end)
end)
ob.MouseButton1Click:Connect(function() if keyOk then tglW() end end)
cbtn.MouseButton1Click:Connect(tglW)
print("[Bin's Hub v26] loaded. key: h00x · lang: "..LANG)
