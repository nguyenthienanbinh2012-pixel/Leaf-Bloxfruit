-- Leaf Bloxfruit-v1 | Obsidian UI Wrapper
-- Phần 1/5: Khởi tạo UI + Cấu hình + Logic lõi (dòng 1-310)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local SoundService = game:GetService("SoundService")

local NotifySound = Instance.new("Sound")
NotifySound.SoundId = "rbxassetid://18595195017"
NotifySound.Volume = 0.5
NotifySound.Parent = SoundService

local function PlayNotify()
    local s = NotifySound:Clone()
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local Window = Library:CreateWindow({
    Title = "Leaf Bloxfruit-v1",
    Footer = "Leaf Hub | v1.0",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

Library.Scheme.Accent = Color3.fromRGB(0, 200, 100)
Library.Scheme.Text = Color3.fromRGB(240, 240, 240)
Library.Scheme.Background = Color3.fromRGB(18, 22, 18)
Library.Scheme.Outline = Color3.fromRGB(0, 160, 80)
Library.Scheme.Button = Color3.fromRGB(28, 40, 28)
Library.Scheme.ButtonHover = Color3.fromRGB(40, 60, 40)

local Tabs = {
    Combat = Window:AddTab("Combat", "sword"),
    Visual = Window:AddTab("Visual", "eye"),
    Farm = Window:AddTab("Farm", "tractor"),
    Misc = Window:AddTab("Misc", "cog"),
    Settings = Window:AddTab("Settings", "settings"),
}

local Settings = {
    AutoClick = false,
    BringMobs = false,
    BringDistance = 200,
    AutoBuso = false,
    SmoothMode = false,
    NoAimMobs = false,
    FarmTool = "Melee",
    RunningOption = nil,
    RunningMethod = nil,
}

local Connections = {}
local _ENV = getgenv()

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator = Remotes:WaitForChild("Validator2")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")

local Enemies = workspace:WaitForChild("Enemies")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Characters = workspace:WaitForChild("Characters")
local Boats = workspace:WaitForChild("Boats")

local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local EXECUTOR_NAME = string.upper(if identifyexecutor then identifyexecutor() else "NULL")
local IS_BLACKLISTED = table.find({"NULL","XENO","SWIFT","JJSPLOIT"}, EXECUTOR_NAME)

local hookmetamethod = (not IS_BLACKLISTED and hookmetamethod) or function(...) return ... end
local hookfunction = (not IS_BLACKLISTED and hookfunction) or function(...) return ... end
local sethiddenproperty = sethiddenproperty or function() end
local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local BRING_TAG = `b{math.random(80,2e4)}t`
local KILLAURA_TAG = `k{math.random(120,2e4)}t`
_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local function CheckPlayerAlly(p)
    if tostring(p.Team) == "Marines" and p.Team == Player.Team then return false end
    if p:HasTag(`Ally{Player.Name}`) or Player:HasTag(`Ally{p.Name}`) then return false end
    return true
end

local Signal = {}
do
    local Connection = {}
    Connection.__index = Connection
    function Connection:Disconnect()
        if not self.Connected then return end
        local i = table.find(self.Signal, self)
        if i then table.remove(self.Signal, i) end
        self.Function = nil
        self.Connected = false
    end
    function Connection:Fire(...)
        if self.Function then task.spawn(self.Function, ...) end
    end
    function Connection.new()
        return setmetatable({Connected = true}, Connection)
    end
    Signal.__index = Signal
    function Signal:Connect(fn)
        if type(fn) ~= "function" then return end
        local c = Connection.new()
        c.Function = fn
        c.Signal = self
        table.insert(self.Connections, c)
        return c
    end
    function Signal:Fire(...)
        for _, c in ipairs(self.Connections) do
            if c.Connected then c:Fire(...) end
        end
    end
    function Signal.new()
        return setmetatable({Connections = {}}, Signal)
    end
end

local Module = {}
Module.Signals = {}
Module.Signals.Notify = Signal.new()
Module.Signals.EnemyAdded = Signal.new()
Module.Signals.EnemyDied = Signal.new()

Module.Debounce = {TargetDebounce = 0, UpdateDebounce = 0, Skills = {}}
Module.Cached = {Humanoids = {}, Enemies = {}, Bring = {}, Tools = {}, Progress = {}}
Module.GameData = {Sea = 1, SeasName = {"Main","Dressrosa","Zou"}}

if table.find({2753915549, 85211729168715, 113741252407134, 114279672983750}, game.PlaceId) then
    Module.GameData.Sea = 1
elseif table.find({4442272183, 79091703265657}, game.PlaceId) then
    Module.GameData.Sea = 2
elseif table.find({7449423635, 100117331123089}, game.PlaceId) then
    Module.GameData.Sea = 3
end

function Module.FireRemote(...)
    return CommF:InvokeServer(...)
end

function Module.IsAlive(char)
    if not char then return false end
    local h = Module.Cached.Humanoids[char] or char:FindFirstChild("Humanoid")
    if not h and char.Parent == Boats then return true end
    if char.Parent == SeaBeasts then h = char:FindFirstChild("Health") end
    if h then
        Module.Cached.Humanoids[char] = h
        return h[if h.ClassName == "Humanoid" then "Health" else "Value"] > 0
    end
    return false
end

function Module.KillAura(dist, name)
    dist = dist or 500
    for _, e in ipairs(Enemies:GetChildren()) do
        if (not name or e.Name == name) and e.PrimaryPart and not e:HasTag(KILLAURA_TAG) then
            if Module.IsAlive(e) and Player:DistanceFromCharacter(e.PrimaryPart.Position) < dist then
                e:AddTag(KILLAURA_TAG)
            end
        end
    end
end

table.insert(Connections, CollectionService:GetInstanceAddedSignal(KILLAURA_TAG):Connect(function(e)
    local h = e:FindFirstChild("Humanoid")
    local r = e:FindFirstChild("HumanoidRootPart")
    if h and r then
        r.CanCollide = false
        r.Size = Vector3.new(60,60,60)
        h:ChangeState(15)
        h.Health = 0
        task.wait()
        e:RemoveTag(KILLAURA_TAG)
    end
end))

table.insert(Connections, CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(function(e)
    local pr = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local r = e:WaitForChild("HumanoidRootPart")
    local h = e:WaitForChild("Humanoid")
    pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
    local bp = Instance.new("BodyPosition", r)
    bp.Position = r.Position
    bp.P, bp.D = 3e4, 3e3
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    while pr and r and h and h.Health > 0 and e.Parent == Enemies and e:HasTag(BRING_TAG) do
        local t = Module.Cached.Bring[e.Name]
        if t and (pr.Position - r.Position).Magnitude <= Settings.BringDistance then
            if (r.Position - t.Position).Magnitude <= 70 then
                r.CFrame = t
                r.CanCollide = false
            else
                r.CanCollide = false
                bp.Position = t.Position
            end
        end
        task.wait()
    end
    if e:HasTag(BRING_TAG) then e:RemoveTag(BRING_TAG) end
end))

task.spawn(function()
    local CommE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommE")
    table.insert(Connections, CommE.OnClientEvent:Connect(function(method, ...)
        if method == "Notify" then
            Module.Signals.Notify:Fire(...)
        end
    end))
end)

Module.Signals.Notify:Connect(function(msg)
    PlayNotify()
    Library:Notify({Title = "Leaf Hub", Text = tostring(msg), Duration = 3})
end)
-- Phần 2/5: Combat Tab + FastAttack Engine (dòng 311-620)

local CombatGroup = Tabs.Combat:AddLeftGroupbox("Auto Combat")
local CombatGroup2 = Tabs.Combat:AddRightGroupbox("Kill Aura & Bring")

CombatGroup:AddToggle("AutoClick", {
    Text = "Auto Click / Fast Attack",
    Default = false,
    Callback = function(v) Settings.AutoClick = v end
})

CombatGroup:AddToggle("AutoBuso", {
    Text = "Auto Buso Haki",
    Default = false,
    Callback = function(v) Settings.AutoBuso = v end
})

CombatGroup:AddSlider("AttackDist", {
    Text = "Attack Distance",
    Default = 65, Min = 10, Max = 300, Rounding = 0,
    Callback = function(v) if Module.FastAttack then Module.FastAttack.Distance = v end end
})

CombatGroup:AddSlider("DontKillBelow", {
    Text = "Don't Attack Below HP %",
    Default = 0, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v)
        if Module.FastAttack then Module.FastAttack:DontAttackBelowPercent(v) end
    end
})

CombatGroup2:AddToggle("KillAura", {
    Text = "Kill Aura",
    Default = false,
    Callback = function(v) _ENV._KillAuraEnabled = v end
})

CombatGroup2:AddSlider("KillAuraDist", {
    Text = "Kill Aura Distance",
    Default = 500, Min = 50, Max = 2000, Rounding = 0,
    Callback = function(v) _ENV._KillAuraDist = v end
})

CombatGroup2:AddToggle("BringMobs", {
    Text = "Bring Mobs",
    Default = false,
    Callback = function(v) Settings.BringMobs = v end
})

CombatGroup2:AddSlider("BringDist", {
    Text = "Bring Distance",
    Default = 200, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v) Settings.BringDistance = v end
})

CombatGroup2:AddToggle("AimBot", {
    Text = "Aim Bot (Skills/Gun)",
    Default = false,
    Callback = function(v) _ENV.AimBot_Skills = not v; _ENV.AimBot_Gun = not v; _ENV.AimBot_Tap = not v end
})

CombatGroup2:AddToggle("NoAimMobs", {
    Text = "Don't Aim At Mobs",
    Default = false,
    Callback = function(v) Settings.NoAimMobs = v end
})

Module.FastAttack = (function()
    local FastAttack = {
        Distance = 65,
        attackMobs = true,
        attackPlayers = true,
        Equipped = nil,
        Debounce = 0,
        ComboDebounce = 0,
        ShootDebounce = 0,
        M1Combo = 0,
        Overheat = {
            ["Dragonstorm"] = {MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 500, Shooting = false}
        },
        ShootsPerTarget = {["Dual Flintlock"] = 2},
        SpecialShoots = {
            ["Skull Guitar"] = "TAP",
            ["Bazooka"] = "Position",
            ["Cannon"] = "Position",
            ["Dragonstorm"] = "Overheat"
        },
        FruitClick = {["Blade-Blade"] = true, ["Gas-Gas"] = true},
        NormalClickFruits = {["Light-Light"] = true, ["Ice-Ice"] = true}
    }

    local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
    local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
    local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")

    local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
        return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
    end)

    local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
        return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
    end)

    local HIT_FUNCTION
    task.defer(function()
        if getsenv then
            local ok, env = pcall(getsenv, Net)
            if ok and env and env._G then
                HIT_FUNCTION = env._G.SendHitsToServer
            end
        end
    end)

    local IsAlive = Module.IsAlive
    FastAttack.ShootsFunctions = {
        ["Skull Guitar"] = function(self, Equipped, Position)
            if Equipped.RemoteEvent then
                Equipped.RemoteEvent:FireServer("TAP", Position)
            end
        end
    }

    local CurrentBladeHits = {}
    local MyRootPartPosition = nil
    local NoAttackBelowDebounce = 0
    local BelowHealthPercent = 0

    local function ExpandsHitBox(list)
        for i = 1, #list do
            if list[i][2] then
                list[i][2].Size = Vector3.one * 50
                list[i][2].Transparency = 1
            end
        end
    end

    local function CheckStun(ToolTip, Character, Humanoid)
        if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Gun") then
            return false
        end
        return true
    end

    local function NewBladeHit(RootPart, Character)
        table.insert(CurrentBladeHits, {Character, RootPart})
    end

    local function GetMaxHits(Character)
        if Character:FindFirstChild("HumanoidRootPart") and Character.HumanoidRootPart:FindFirstChild("Buddha") then
            return 10
        end
        return 1
    end

    local function ProcessSeaEventsHits(Distance)
        for _, SeaBeast in SeaBeasts:GetChildren() do
            local BasePart = SeaBeast:FindFirstChildOfClass("MeshPart")
            if IsAlive(SeaBeast) and BasePart and (MyRootPartPosition - BasePart.Position).Magnitude < Distance then
                NewBladeHit(BasePart, SeaBeast)
            end
        end
        for _, Boat in Enemies:GetChildren() do
            if not Boat:GetAttribute("IsBoat") then continue end
            local BasePart = Boat:FindFirstChildOfClass("MeshPart")
            if IsAlive(Boat) and BasePart and (MyRootPartPosition - BasePart.Position).Magnitude < Distance then
                NewBladeHit(BasePart, Boat)
            end
        end
    end

    local function CanChangeGunTarget(Target, Enemy)
        if Enemy.Parent == SeaBeasts then return true end
        if Target.Parent ~= SeaBeasts and Enemy:GetAttribute("IsBoat") then return true end
        return false
    end

    local function ConvertToGunHits()
        local Target, Hitbox
        for i = 1, #CurrentBladeHits do
            local Hit = CurrentBladeHits[i]
            if not Target or CanChangeGunTarget(Target, Hit[1]) then
                Hitbox, Target = Hit[2], Hit[1]
            end
        end
        if not Hitbox then return nil end
        CurrentBladeHits = {Hitbox, math.random()}
        return Hitbox.Position, Hitbox
    end

    local function ProcessHits(List, Equipped, Distance)
        local MyCharacter = Player.Character
        if not MyCharacter then return end
        local Targets = List:GetChildren()
        local MaxHits = GetMaxHits(MyCharacter) + 1
        for i = 1, #Targets do
            if #CurrentBladeHits >= MaxHits then break end
            local Character = Targets[i]
            if Character == MyCharacter or Character:GetAttribute("IsBoat") or not IsAlive(Character) then continue end
            local RootPart = Character.PrimaryPart
            if (tick() - NoAttackBelowDebounce) <= 1 then
                local Humanoid = Character:FindFirstChild("Humanoid")
                if Humanoid and Humanoid.Health / Humanoid.MaxHealth * 100 <= BelowHealthPercent then
                    continue
                end
            end
            local TargetPlayer = Players:GetPlayerFromCharacter(Character)
            if RootPart and (Character.Parent ~= Characters or (TargetPlayer and CheckPlayerAlly(TargetPlayer))) then
                if (MyRootPartPosition - RootPart.Position).Magnitude <= Distance then
                    NewBladeHit(RootPart, Character)
                end
            end
        end
    end

    function FastAttack:DontAttackBelowPercent(Percent)
        BelowHealthPercent = Percent
        NoAttackBelowDebounce = tick()
        return true
    end

    function FastAttack:UpdateBladeHits(Distance, Anything, SeasEvents)
        Distance = Distance or self.Distance
        CurrentBladeHits = {}
        if Anything or self.attackMobs then ProcessHits(Enemies, self.Equipped, Distance) end
        if Anything or self.attackPlayers then ProcessHits(Characters, self.Equipped, Distance) end
        if SeasEvents then ProcessSeaEventsHits(Distance, self.Equipped) end
    end

    function FastAttack:GetClosestEnemy(Distance)
        self:UpdateBladeHits(Distance, true)
        local dist, Closest = math.huge
        for i = 1, #CurrentBladeHits do
            local Magnitude = (MyRootPartPosition - CurrentBladeHits[i][2].Position).Magnitude
            if Magnitude <= dist then dist, Closest = Magnitude, CurrentBladeHits[i][2] end
        end
        return Closest
    end

    function FastAttack:GetCombo()
        local Combo = if tick() - self.ComboDebounce <= 0.4 then self.M1Combo else 0
        Combo = if Combo >= 4 then 1 else Combo + 1
        self.ComboDebounce = tick()
        self.M1Combo = Combo
        return Combo
    end

    function FastAttack:UseFruitM1(Character, Equipped, Combo)
        local MyPosition = Character.Humanoid.RootPart.Position
        for _, Enemy in ipairs(Enemies:GetChildren()) do
            local RootPart = IsAlive(Enemy) and Enemy.PrimaryPart
            if RootPart and (RootPart.Position - MyPosition).Magnitude <= 50 then
                if Equipped.LeftClickRemote then
                    Equipped.LeftClickRemote:FireServer((RootPart.Position - MyPosition).Unit, Combo)
                end
            end
        end
    end

    function FastAttack:UseNormalClick(Cooldown)
        self:UpdateBladeHits()
        if #CurrentBladeHits > 0 then
            local Primary = table.remove(CurrentBladeHits)
            local PrimaryRootPart = Primary and Primary[2]
            if not PrimaryRootPart then return end
            if SUCCESS_FLAGS and COMBAT_REMOTE_THREAD and HIT_FUNCTION then
                RE_RegisterAttack:FireServer(Cooldown)
                pcall(HIT_FUNCTION, PrimaryRootPart, CurrentBladeHits)
            elseif SUCCESS_FLAGS and not COMBAT_REMOTE_THREAD then
                RE_RegisterAttack:FireServer(Cooldown)
                RE_RegisterHit:FireServer(PrimaryRootPart, CurrentBladeHits)
            else
                ExpandsHitBox(CurrentBladeHits)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end
    end

    function FastAttack:GetValidator2()
        if not SUCCESS_SHOOT or not SHOOT_FUNCTION then return 0, 0 end
        local v1 = getupvalue(SHOOT_FUNCTION, 15)
        local v2 = getupvalue(SHOOT_FUNCTION, 13)
        local v3 = getupvalue(SHOOT_FUNCTION, 16)
        local v4 = getupvalue(SHOOT_FUNCTION, 17)
        local v5 = getupvalue(SHOOT_FUNCTION, 14)
        local v6 = getupvalue(SHOOT_FUNCTION, 12)
        local v7 = getupvalue(SHOOT_FUNCTION, 18)
        local v8 = v6 * v2
        local v9 = (v5 * v2 + v6 * v1) % v3
        v9 = (v9 * v3 + v8) % v4
        v5 = math.floor(v9 / v3)
        v6 = v9 - v5 * v3
        v7 = v7 + 1
        setupvalue(SHOOT_FUNCTION, 15, v1)
        setupvalue(SHOOT_FUNCTION, 13, v2)
        setupvalue(SHOOT_FUNCTION, 16, v3)
        setupvalue(SHOOT_FUNCTION, 17, v4)
        setupvalue(SHOOT_FUNCTION, 14, v5)
        setupvalue(SHOOT_FUNCTION, 12, v6)
        setupvalue(SHOOT_FUNCTION, 18, v7)
        return math.floor(v9 / v4 * 16777215), v7
    end

    function FastAttack:UseGunShoot(Character, Equipped)
        if not Equipped.Enabled then return end
        local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
        if ShootType == "Normal" or ShootType == "Overheat" then
            local Distance = if ShootType == "Overheat" then self.Overheat[Equipped.Name].Distance else 200
            self:UpdateBladeHits(Distance, false, true)
            if #CurrentBladeHits == 0 then return end
            local Position, PrimaryPart = ConvertToGunHits()
            if not Position or not PrimaryPart then return end
            local PrimaryTarget = PrimaryPart.Parent
            if ShootType == "Overheat" then
                self.Debounce = tick() + 9e9
                while PrimaryTarget.Parent and IsAlive(PrimaryTarget) and Equipped and Equipped.Parent == Player.Character do
                    if PrimaryPart.Parent ~= PrimaryTarget or Player:DistanceFromCharacter(PrimaryPart.Position) > Distance then break end
                    Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                    GunValidator:FireServer(self:GetValidator2())
                    RE_ShootGunEvent:FireServer(Position, CurrentBladeHits)
                    task.wait()
                end
                self.Debounce = 0
            elseif PrimaryTarget then
                Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                GunValidator:FireServer(self:GetValidator2())
                for i = 1, (self.ShootsPerTarget[Equipped.Name] or 1) do
                    RE_ShootGunEvent:FireServer(Position, CurrentBladeHits)
                end
            end
        elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
            local Target = self:GetClosestEnemy(200)
            if Target then
                if self.ShootsFunctions[Equipped.Name] then
                    return self.ShootsFunctions[Equipped.Name](self, Equipped, Target.Position)
                end
                Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                GunValidator:FireServer(self:GetValidator2())
                if ShootType == "TAP" and Equipped.RemoteEvent then
                    Equipped.RemoteEvent:FireServer("TAP", Target.Position)
                else
                    RE_ShootGunEvent:FireServer(Target.Position)
                end
            end
        end
    end

    function FastAttack.attack()
        if not Settings.AutoClick then return end
        if not IsAlive(Player.Character) then return end
        local self = FastAttack
        local Character = Player.Character
        local Humanoid = Character.Humanoid
        local Equipped = Character:FindFirstChildOfClass("Tool")
        local ToolTip = Equipped and Equipped.ToolTip
        if not Equipped or (ToolTip ~= "Gun" and ToolTip ~= "Melee" and ToolTip ~= "Blox Fruit" and ToolTip ~= "Sword") then
            return
        end
        local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
        if (tick() - self.Debounce) >= Cooldown and CheckStun(ToolTip, Character, Humanoid) then
            local Combo = self:GetCombo()
            if Combo >= 4 then Cooldown += 0.05 end
            self.Equipped = Equipped
            self.Debounce = if Combo >= 4 and ToolTip ~= "Gun" then tick() + (Cooldown / 2) else tick()
            MyRootPartPosition = Character.Humanoid.RootPart.Position
            if ToolTip == "Blox Fruit" and not self.NormalClickFruits[Equipped.Name] and not self.FruitClick[Equipped.Name] then
                if Equipped:FindFirstChild("LeftClickRemote") then
                    Equipped.LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                end
            elseif ToolTip == "Blox Fruit" and self.FruitClick[Equipped.Name] then
                if Equipped:FindFirstChild("LeftClickRemote") then
                    self:UseFruitM1(Character, Equipped, Combo)
                end
            elseif ToolTip == "Gun" then
                if SUCCESS_SHOOT and SHOOT_FUNCTION then
                    self:UseGunShoot(Character, Equipped)
                end
            else
                self:UseNormalClick(Cooldown)
            end
        end
    end

    table.insert(Connections, RunService.Stepped:Connect(FastAttack.attack))
    return FastAttack
end)()

task.spawn(function()
    while task.wait(0.3) do
        if _ENV._KillAuraEnabled then
            Module.KillAura(_ENV._KillAuraDist or 500)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Settings.AutoBuso then
            local Character = Player.Character
            if Character and Module.IsAlive(Character) and not Character:FindFirstChild("HasBuso") then
                if Character:HasTag("Buso") then
                    Module.FireRemote("Buso")
                elseif Money.Value >= 25e3 then
                    Module.FireRemote("BuyHaki", "Buso")
                end
            end
        end
    end
end)
  -- Phần 3/5: Visual Tab - ESP System (dòng 621-930)

local VisualLeft = Tabs.Visual:AddLeftGroupbox("ESP Enemies")
local VisualRight = Tabs.Visual:AddRightGroupbox("ESP Objects")

local ESP = {
    Enabled = false,
    Box = false,
    Name = false,
    Health = false,
    Distance = false,
    Tracer = false,
    Color = Color3.fromRGB(0, 255, 100),
    MaxDistance = 1000,
    Drawings = {},
    Highlights = {},
}

local DrawingLib = Drawing
local Camera = workspace.CurrentCamera

local function CreateDrawing(class, props)
    local ok, obj = pcall(DrawingLib.new, class)
    if not ok or not obj then return nil end
    for k, v in pairs(props) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function SafeRemove(t)
    for i = #t, 1, -1 do
        pcall(function() t[i]:Remove() end)
        t[i] = nil
    end
end

local function ClearESPFor(instance)
    local data = ESP.Drawings[instance]
    if data then
        for _, obj in pairs(data) do
            pcall(function() obj:Remove() end)
        end
        ESP.Drawings[instance] = nil
    end
    local hl = ESP.Highlights[instance]
    if hl then
        pcall(function() hl:Destroy() end)
        ESP.Highlights[instance] = nil
    end
end

local function ClearAllESP()
    for inst in pairs(ESP.Drawings) do ClearESPFor(inst) end
    for inst in pairs(ESP.Highlights) do ClearESPFor(inst) end
end

local function GetHealthColor(ratio)
    if ratio > 0.6 then return Color3.fromRGB(0, 255, 100) end
    if ratio > 0.3 then return Color3.fromRGB(255, 200, 0) end
    return Color3.fromRGB(255, 50, 50)
end

local function WorldToViewport(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

local function DrawEntity(instance, rootPart, isEnemy)
    local data = ESP.Drawings[instance]
    if not data then
        data = {
            Box = CreateDrawing("Square", {Thickness = 1, Filled = false}),
            Name = CreateDrawing("Text", {Size = 14, Center = true, Outline = true}),
            HealthBg = CreateDrawing("Square", {Thickness = 1, Filled = true}),
            HealthFg = CreateDrawing("Square", {Thickness = 1, Filled = true}),
            Distance = CreateDrawing("Text", {Size = 12, Center = true, Outline = true}),
            Tracer = CreateDrawing("Line", {Thickness = 1}),
        }
        ESP.Drawings[instance] = data
    end

    local myPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not myPos or not rootPart then return end
    local dist = (myPos.Position - rootPart.Position).Magnitude
    if dist > ESP.MaxDistance then
        for _, obj in pairs(data) do pcall(function() obj.Visible = false end) end
        return
    end

    local topPos, onTop = WorldToViewport(rootPart.Position + Vector3.new(0, 3, 0))
    local botPos = WorldToViewport(rootPart.Position - Vector3.new(0, 3, 0))
    if not onTop then
        for _, obj in pairs(data) do pcall(function() obj.Visible = false end) end
        return
    end

    local height = math.abs(botPos.Y - topPos.Y)
    local width = height / 2
    local centerX = topPos.X
    local topY = math.min(topPos.Y, botPos.Y)
    local baseColor = isEnemy and ESP.Color or Color3.fromRGB(255, 100, 100)

    if ESP.Box then
        pcall(function()
            data.Box.Visible = true
            data.Box.Color = baseColor
            data.Box.Size = Vector2.new(width, height)
            data.Box.Position = Vector2.new(centerX - width / 2, topY)
        end)
    else
        pcall(function() data.Box.Visible = false end)
    end

    if ESP.Name then
        pcall(function()
            data.Name.Visible = true
            data.Name.Color = baseColor
            data.Name.Text = instance.Name
            data.Name.Position = Vector2.new(centerX, topY - 16)
        end)
    else
        pcall(function() data.Name.Visible = false end)
    end

    if ESP.Health then
        local hum = instance:FindFirstChildOfClass("Humanoid")
        if hum then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local hColor = GetHealthColor(ratio)
            pcall(function()
                data.HealthBg.Visible = true
                data.HealthBg.Color = Color3.new(0, 0, 0)
                data.HealthBg.Size = Vector2.new(3, height)
                data.HealthBg.Position = Vector2.new(centerX - width / 2 - 5, topY)
                data.HealthFg.Visible = true
                data.HealthFg.Color = hColor
                data.HealthFg.Size = Vector2.new(3, height * ratio)
                data.HealthFg.Position = Vector2.new(centerX - width / 2 - 5, topY + height * (1 - ratio))
            end)
        end
    else
        pcall(function() data.HealthBg.Visible = false; data.HealthFg.Visible = false end)
    end

    if ESP.Distance then
        pcall(function()
            data.Distance.Visible = true
            data.Distance.Color = baseColor
            data.Distance.Text = string.format("[%d]", math.floor(dist))
            data.Distance.Position = Vector2.new(centerX, topY + height + 2)
        end)
    else
        pcall(function() data.Distance.Visible = false end)
    end

    if ESP.Tracer then
        pcall(function()
            data.Tracer.Visible = true
            data.Tracer.Color = baseColor
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Tracer.To = Vector2.new(centerX, topY + height / 2)
        end)
    else
        pcall(function() data.Tracer.Visible = false end)
    end

    if not ESP.Highlights[instance] then
        local hl = Instance.new("Highlight")
        hl.Name = "LeafESP_HL"
        hl.FillColor = baseColor
        hl.FillTransparency = 0.6
        hl.OutlineColor = baseColor
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = instance
        ESP.Highlights[instance] = hl
    else
        ESP.Highlights[instance].FillColor = baseColor
        ESP.Highlights[instance].OutlineColor = baseColor
    end
end

local function UpdateESP()
    if not ESP.Enabled then return end
    local handled = {}
    for _, enemy in ipairs(Enemies:GetChildren()) do
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            DrawEntity(enemy, root, true)
            handled[enemy] = true
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local char = plr.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                DrawEntity(char, root, false)
                handled[char] = true
            end
        end
    end
    for inst in pairs(ESP.Drawings) do
        if not handled[inst] then
            ClearESPFor(inst)
        end
    end
end

VisualLeft:AddToggle("ESP_Enabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        ESP.Enabled = v
        if not v then ClearAllESP() end
    end
})

VisualLeft:AddToggle("ESP_Box", {
    Text = "ESP Box",
    Default = true,
    Callback = function(v) ESP.Box = v end
})

VisualLeft:AddToggle("ESP_Name", {
    Text = "ESP Name",
    Default = true,
    Callback = function(v) ESP.Name = v end
})

VisualLeft:AddToggle("ESP_Health", {
    Text = "ESP Health Bar",
    Default = true,
    Callback = function(v) ESP.Health = v end
})

VisualLeft:AddToggle("ESP_Dist", {
    Text = "ESP Distance",
    Default = true,
    Callback = function(v) ESP.Distance = v end
})

VisualLeft:AddToggle("ESP_Tracer", {
    Text = "ESP Tracer",
    Default = false,
    Callback = function(v) ESP.Tracer = v end
})

VisualLeft:AddSlider("ESP_MaxDist", {
    Text = "Max Render Distance",
    Default = 1000, Min = 100, Max = 5000, Rounding = 0,
    Callback = function(v) ESP.MaxDistance = v end
})

VisualLeft:AddColorPicker("ESP_Color", {
    Text = "ESP Color",
    Default = Color3.fromRGB(0, 255, 100),
    Callback = function(c) ESP.Color = c end
})

-- Chest ESP
local ChestESP = {Enabled = false, Highlights = {}}

VisualRight:AddToggle("ChestESP", {
    Text = "Chest ESP",
    Default = false,
    Callback = function(v)
        ChestESP.Enabled = v
        if not v then
            for _, hl in pairs(ChestESP.Highlights) do pcall(function() hl:Destroy() end) end
            ChestESP.Highlights = {}
        end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if ChestESP.Enabled then
            local tagged = CollectionService:GetTagged("_ChestTagged")
            local seen = {}
            for _, chest in ipairs(tagged) do
                if not chest:GetAttribute("IsDisabled") then
                    seen[chest] = true
                    if not ChestESP.Highlights[chest] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 215, 0)
                        hl.FillTransparency = 0.4
                        hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = chest
                        ChestESP.Highlights[chest] = hl
                    end
                end
            end
            for chest, hl in pairs(ChestESP.Highlights) do
                if not seen[chest] or not chest.Parent then
                    pcall(function() hl:Destroy() end)
                    ChestESP.Highlights[chest] = nil
                end
            end
        end
    end
end)

-- Berry ESP
local BerryESP = {Enabled = false, Highlights = {}}

VisualRight:AddToggle("BerryESP", {
    Text = "Berry Bush ESP",
    Default = false,
    Callback = function(v)
        BerryESP.Enabled = v
        if not v then
            for _, hl in pairs(BerryESP.Highlights) do pcall(function() hl:Destroy() end) end
            BerryESP.Highlights = {}
        end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if BerryESP.Enabled then
            local tagged = CollectionService:GetTagged("BerryBush")
            local seen = {}
            for _, bush in ipairs(tagged) do
                seen[bush] = true
                if not BerryESP.Highlights[bush] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(180, 80, 220)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(220, 130, 255)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = bush
                    BerryESP.Highlights[bush] = hl
                end
            end
            for bush, hl in pairs(BerryESP.Highlights) do
                if not seen[bush] or not bush.Parent then
                    pcall(function() hl:Destroy() end)
                    BerryESP.Highlights[bush] = nil
                end
            end
        end
    end
end)

table.insert(Connections, RunService.RenderStepped:Connect(UpdateESP))

VisualRight:AddButton("Clear All ESP", function()
    ESP.Enabled = false
    ClearAllESP()
    for _, hl in pairs(ChestESP.Highlights) do pcall(function() hl:Destroy() end) end
    ChestESP.Highlights = {}
    for _, hl in pairs(BerryESP.Highlights) do pcall(function() hl:Destroy() end) end
    BerryESP.Highlights = {}
    PlayNotify()
end)

VisualRight:AddLabel("ESP reload automatically follows camera")
-- Phần 4/5: Farm Tab + Misc Tab + Settings Tab (dòng 931-1240)

local FarmLeft = Tabs.Farm:AddLeftGroupbox("Auto Farm")
local FarmRight = Tabs.Farm:AddRightGroupbox("Teleport & Quest")

local FarmState = {
    AutoFarm = false,
    AutoQuest = false,
    AutoChest = false,
    AutoBerry = false,
    KillAuraFarm = false,
    CurrentTarget = nil,
    QuestName = nil,
}

local function TweenTo(position)
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local bv = _ENV.tween_bodyvelocity
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 1000
        _ENV.tween_bodyvelocity = bv
    end
    bv.Parent = hrp
    bv.Velocity = (position - hrp.Position).Unit * 300
    task.delay(0.35, function()
        if bv then bv.Velocity = Vector3.zero end
    end)
end

local function GetClosestEnemyByName(name, maxDist)
    maxDist = maxDist or 500
    local myChar = Player.Character
    if not myChar then return nil end
    local myPos = myChar:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    local closest, dist = nil, maxDist
    for _, e in ipairs(Enemies:GetChildren()) do
        if e.Name:find(name, 1, true) then
            local hum = e:FindFirstChildOfClass("Humanoid")
            local root = e:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local d = (myPos.Position - root.Position).Magnitude
                if d < dist then dist, closest = d, e end
            end
        end
    end
    return closest
end

local function FarmToBoss(bossName)
    if not FarmState.AutoFarm then return end
    local boss = GetClosestEnemyByName(bossName, 2000)
    if not boss then
        local bossData = Module.Bosses and Module.Bosses[bossName]
        if bossData and bossData.Position then
            TweenTo(bossData.Position.Position)
        end
        return
    end
    local root = boss:FindFirstChild("HumanoidRootPart")
    if root then
        local myChar = Player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (myRoot.Position - root.Position).Magnitude > 20 then
            TweenTo(root.Position)
        end
    end
end

FarmLeft:AddToggle("AutoFarmToggle", {
    Text = "Auto Farm Boss",
    Default = false,
    Callback = function(v) FarmState.AutoFarm = v end
})

local BossList = {"The Gorilla King","Bobby","Yeti","Vice Admiral","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg","Diamond","Jeremy","Orbitus","Smoke Admiral","Awakened Ice Admiral","Tide Keeper","Stone","Hydra Leader","Kilo Admiral","Captain Elephant","Beautiful Pirate","Cake Queen"}

FarmLeft:AddDropdown("BossSelect", {
    Text = "Select Boss",
    Values = BossList,
    Default = "The Gorilla King",
    Multi = false,
    Callback = function(v) FarmState.QuestName = v end
})

FarmLeft:AddToggle("AutoChestToggle", {
    Text = "Auto Collect Chest",
    Default = false,
    Callback = function(v) FarmState.AutoChest = v end
})

FarmLeft:AddToggle("AutoBerryToggle", {
    Text = "Auto Collect Berry",
    Default = false,
    Callback = function(v) FarmState.AutoBerry = v end
})

FarmRight:AddButton("Teleport to Boss", function()
    if FarmState.QuestName and Module.Bosses and Module.Bosses[FarmState.QuestName] then
        local pos = Module.Bosses[FarmState.QuestName].Position
        if pos then TweenTo(pos.Position); PlayNotify() end
    end
end)

FarmRight:AddButton("Accept Current Quest", function()
    if FarmState.QuestName then
        local data = Module.Bosses[FarmState.QuestName]
        if data and data.Quest then
            local questName, npcPos, option = data.Quest[1], data.Quest[2], data.Quest[3]
            TweenTo(npcPos.Position)
            task.wait(0.6)
            pcall(function() Module.FireRemote(questName, option or 1) end)
            PlayNotify()
        end
    end
end)

FarmRight:AddToggle("AutoAcceptQuest", {
    Text = "Auto Accept Quest",
    Default = false,
    Callback = function(v) FarmState.AutoQuest = v end
})

FarmRight:AddButton("Bring Mob (Selected Boss)", function()
    if FarmState.QuestName then
        local boss = GetClosestEnemyByName(FarmState.QuestName, 5000)
        if boss and boss.PrimaryPart then
            Module.Cached.Bring[FarmState.QuestName] = boss.PrimaryPart.CFrame
            Settings.BringMobs = true
            for _, e in ipairs(Enemies:GetChildren()) do
                if e.Name:find(FarmState.QuestName, 1, true) and not e:HasTag(BRING_TAG) then
                    e:AddTag(BRING_TAG)
                end
            end
            PlayNotify()
        end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if FarmState.AutoFarm and FarmState.QuestName then
            local ok, err = pcall(FarmToBoss, FarmState.QuestName)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if FarmState.AutoChest then
            local chest = Module.Chests and Module.Chests()
            if chest then
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    TweenTo(chest:GetPivot().Position)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if FarmState.AutoBerry then
            local bush = Module.Berry and Module.Berry()
            if bush and bush.Parent then
                TweenTo(bush.Parent:GetPivot().Position)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if FarmState.AutoQuest and FarmState.QuestName then
            local data = Module.Bosses[FarmState.QuestName]
            if data and data.Quest then
                local questName, npcPos, option = data.Quest[1], data.Quest[2], data.Quest[3]
                local myChar = Player.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local d = (myChar.HumanoidRootPart.Position - npcPos.Position).Magnitude
                    if d > 20 then TweenTo(npcPos.Position) end
                    task.wait(0.5)
                    pcall(function() Module.FireRemote(questName, option or 1) end)
                end
            end
        end
    end
end)

-- Misc Tab
local MiscLeft = Tabs.Misc:AddLeftGroupbox("Teleport / Server")
local MiscRight = Tabs.Misc:AddRightGroupbox("Utility")

MiscLeft:AddButton("Rejoin Server", function()
    pcall(function() Module.Rejoin() end)
    PlayNotify()
end)

MiscLeft:AddButton("Server Hop", function()
    pcall(function() Module:ServerHop() end)
    PlayNotify()
end)

MiscLeft:AddDropdown("SeaSelect", {
    Text = "Travel to Sea",
    Values = {"Sea 1 (Main)", "Sea 2 (Dressrosa)", "Sea 3 (Zou)"},
    Default = "Sea 1 (Main)",
    Multi = false,
    Callback = function(v)
        local seaNum = tonumber(v:match("Sea (%d)")) or 1
        pcall(function() Module:TravelTo(seaNum) end)
        PlayNotify()
    end
})

MiscLeft:AddButton("Teleport to Raid Island", function()
    local ok, island = pcall(function() return Module:GetRaidIsland() end)
    if ok and island then TweenTo(island.Position); PlayNotify() end
end)

MiscRight:AddButton("Remove Boat Collision", function()
    local myChar = Player.Character
    if myChar then
        for _, boat in ipairs(Boats:GetChildren()) do
            pcall(function() Module:RemoveBoatCollision(boat) end)
        end
    end
    PlayNotify()
end)

MiscRight:AddButton("Remove Volcano Lava", function()
    pcall(function() Module:RemoveVolcanoLava() end)
    PlayNotify()
end)

MiscRight:AddButton("Copy JobId", function()
    if setclipboard then setclipboard(game.JobId) end
    PlayNotify()
end)

MiscRight:AddButton("Unlock FPS (setfpscap)", function()
    if setfpscap then setfpscap(240) end
    PlayNotify()
end)

MiscRight:AddLabel("Executor: " .. EXECUTOR_NAME)
MiscRight:AddLabel("PlaceId: " .. tostring(game.PlaceId))

-- Settings Tab
local SettingsLeft = Tabs.Settings:AddLeftGroupbox("UI Settings")
local SettingsRight = Tabs.Settings:AddRightGroupbox("Info")

SettingsLeft:AddButton("Toggle UI Keybind", function()
    Library:Toggle()
end)

SettingsLeft:AddSlider("NotifyVolume", {
    Text = "Notify Sound Volume",
    Default = 50, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) NotifySound.Volume = v / 100 end
})

SettingsLeft:AddToggle("NotifyEnable", {
    Text = "Enable Notify Sound",
    Default = true,
    Callback = function(v) _ENV._NotifySound = v end
})

SettingsLeft:AddButton("Test Notification", function()
    PlayNotify()
    Library:Notify({Title = "Leaf Hub", Text = "Test notification!", Duration = 3})
end)

SettingsLeft:AddButton("Unload Script", function()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    ClearAllESP()
    if Library and Library.Unload then pcall(function() Library:Unload() end) end
end)

SettingsRight:AddLabel("Leaf Hub | Bloxfruit v1")
SettingsRight:AddLabel("Build: " .. tostring(Module.GameData and Module.GameData.StringVersion or "N/A"))
SettingsRight:AddLabel("Sea: " .. tostring(Module.GameData and Module.GameData.Sea or 1))
SettingsRight:AddLabel("Discord: leafhub.gg")

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("LeafHub")
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("LeafHub/Bloxfruit")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify({Title = "Leaf Hub", Text = "Bloxfruit v1 loaded successfully!", Duration = 5})
PlayNotify()
  -- Phần 5/5: Final Wiring + Module.Enemies + Startup (dòng 1241-1550)

-- Boss data (rút gọn từ Module gốc)
Module.Bosses = {
    ["The Gorilla King"] = {IsBoss=true, Level=20, Position=CFrame.new(-1128,6,-451), Quest={"JungleQuest",CFrame.new(-1598,37,153)}},
    ["Bobby"] = {IsBoss=true, Level=55, Position=CFrame.new(-1131,14,4080), Quest={"BuggyQuest1",CFrame.new(-1140,4,3829)}},
    ["Yeti"] = {IsBoss=true, Level=105, Position=CFrame.new(1185,106,-1518), Quest={"SnowQuest",CFrame.new(1385,87,-1298)}},
    ["Vice Admiral"] = {IsBoss=true, Level=130, Position=CFrame.new(-4807,21,4360), Quest={"MarineQuest2",CFrame.new(-5035,29,4326),2}},
    ["Swan"] = {IsBoss=true, Level=240, Position=CFrame.new(5230,4,749), Quest={"ImpelQuest",CFrame.new(5191,4,692)}},
    ["Magma Admiral"] = {IsBoss=true, Level=350, Position=CFrame.new(-5694,18,8735), Quest={"MagmaQuest",CFrame.new(-5319,12,8515)}},
    ["Fishman Lord"] = {IsBoss=true, Level=425, Position=CFrame.new(61350,31,1095), Quest={"FishmanQuest",CFrame.new(61122,18,1567)}},
    ["Wysper"] = {IsBoss=true, Level=500, Position=CFrame.new(-7927,5551,-637), Quest={"SkyExp1Quest",CFrame.new(-7861,5545,-381)}},
    ["Thunder God"] = {IsBoss=true, Level=575, Position=CFrame.new(-7751,5607,-2315), Quest={"SkyExp2Quest",CFrame.new(-7903,5636,-1412)}},
    ["Cyborg"] = {IsBoss=true, Level=675, Position=CFrame.new(6138,10,3939), Quest={"FountainQuest",CFrame.new(5258,39,4052)}},
    ["Diamond"] = {IsBoss=true, Level=750, Position=CFrame.new(-1569,199,-31), Quest={"Area1Quest",CFrame.new(-427,73,1835)}},
    ["Jeremy"] = {IsBoss=true, Level=850, Position=CFrame.new(2316,449,787), Quest={"Area2Quest",CFrame.new(635,73,919)}},
    ["Orbitus"] = {IsBoss=true, Level=925, Position=CFrame.new(-2086,73,-4208), Quest={"MarineQuest3",CFrame.new(-2441,73,-3219)}},
    ["Smoke Admiral"] = {IsBoss=true, Level=1150, Position=CFrame.new(-5078,24,-5352), Quest={"IceSideQuest",CFrame.new(-6229,82,-4853)}},
    ["Awakened Ice Admiral"] = {IsBoss=true, Level=1400, Position=CFrame.new(6473,297,-6944), Quest={"FrostQuest",CFrame.new(5668,28,-6484)}},
    ["Tide Keeper"] = {IsBoss=true, Level=1475, Position=CFrame.new(-3711,77,-11469), Quest={"ForgottenQuest",CFrame.new(-3056,240,-10145)}},
    ["Stone"] = {IsBoss=true, Level=1550, Position=CFrame.new(-1049,40,6791), Quest={"PiratePortQuest",CFrame.new(-449,109,5950)}},
    ["Hydra Leader"] = {IsBoss=true, Level=1675, Position=CFrame.new(5836,1019,-83), Quest={"VenomCrewQuest",CFrame.new(5214,1004,761)}},
    ["Kilo Admiral"] = {IsBoss=true, Level=1750, Position=CFrame.new(2904,509,-7349), Quest={"MarineTreeIsland",CFrame.new(2485,74,-6788)}},
    ["Captain Elephant"] = {IsBoss=true, Level=1875, Position=CFrame.new(-13393,319,-8423), Quest={"DeepForestIsland",CFrame.new(-13233,332,-7626)}},
    ["Beautiful Pirate"] = {IsBoss=true, Level=1950, Position=CFrame.new(5370,22,-89), Quest={"DeepForestIsland2",CFrame.new(-12682,391,-9901)}},
    ["Cake Queen"] = {IsBoss=true, Level=2175, Position=CFrame.new(-710,382,-11150), Quest={"IceCreamIslandQuest",CFrame.new(-818,66,-10964)}},
}

-- Chests / Berry finder
Module.Chests = setmetatable({}, {
    __call = function(self)
        if self.Cached and not self.Cached:GetAttribute("IsDisabled") and self.Cached.Parent then
            return self.Cached
        end
        if self.Debounce and (tick() - self.Debounce) < 0.5 then return nil end
        local char = Player.Character
        if not char then return nil end
        local pos = char:GetPivot().Position
        local list = CollectionService:GetTagged("_ChestTagged")
        local dist, nearest = math.huge, nil
        for _, c in ipairs(list) do
            if not c:GetAttribute("IsDisabled") then
                local d = (c:GetPivot().Position - pos).Magnitude
                if d < dist then dist, nearest = d, c end
            end
        end
        self.Debounce = tick()
        self.Cached = nearest
        return nearest
    end
})

Module.Berry = setmetatable({}, {
    __call = function(self)
        if self.Cached and self.Cached.Parent then
            for _ in pairs(self.Cached:GetAttributes()) do return self.Cached end
        end
        if self.Debounce and (tick() - self.Debounce) < 0.5 then return nil end
        local char = Player.Character
        if not char then return nil end
        local pos = char:GetPivot().Position
        local list = CollectionService:GetTagged("BerryBush")
        local dist, nearest = math.huge, nil
        for _, b in ipairs(list) do
            for _, _ in pairs(b:GetAttributes()) do
                local parent = b.Parent
                if parent then
                    local d = (parent:GetPivot().Position - pos).Magnitude
                    if d < dist then dist, nearest = d, b end
                end
                break
            end
        end
        self.Debounce = tick()
        self.Cached = nearest
        return nearest
    end
})

-- Enemies module (đơn giản hóa - dùng trực tiếp workspace.Enemies)
Module.Enemies = {
    GetTagged = function(self, name)
        local list = {}
        for _, e in ipairs(Enemies:GetChildren()) do
            if e.Name == name then table.insert(list, e) end
        end
        return #list > 0 and list or nil
    end,
    GetEnemyByTag = function(self, name)
        for _, e in ipairs(Enemies:GetChildren()) do
            if e.Name == name then
                local hum = e:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return e end
            end
        end
    end,
    GetClosestByTag = function(self, name)
        local char = Player.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local dist, closest = math.huge, nil
        for _, e in ipairs(Enemies:GetChildren()) do
            if e.Name == name then
                local hum = e:FindFirstChildOfClass("Humanoid")
                local r = e:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r then
                    local d = (root.Position - r.Position).Magnitude
                    if d < dist then dist, closest = d, e end
                end
            end
        end
        return closest
    end
}

-- Rejoin / ServerHop
function Module.Rejoin()
    local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser")
    if sb then
        task.spawn(function() pcall(function() sb:InvokeServer("teleport", game.JobId) end) end)
    else
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end
end

function Module.ServerHop()
    local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser")
    if not sb then
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
        return
    end
    for i = 1, 100 do
        local ok, servers = pcall(function() return sb:InvokeServer(i) end)
        if ok and servers then
            for id, info in pairs(servers) do
                if id ~= game.JobId and info["Count"] < 11 then
                    task.spawn(function() pcall(function() sb:InvokeServer("teleport", id) end) end)
                    return
                end
            end
        end
    end
end

function Module:TravelTo(sea)
    if sea and self.GameData.SeasName[sea] then
        pcall(function() Module.FireRemote("Travel" .. self.GameData.SeasName[sea]) end)
    end
end

function Module:GetRaidIsland()
    local Loc = workspace:FindFirstChild("_WorldOrigin")
    if not Loc then return nil end
    local Locations = Loc:FindFirstChild("Locations")
    if not Locations then return nil end
    local char = Player.Character
    if not char then return nil end
    for i = 5, 1, -1 do
        for _, isl in ipairs(Locations:GetChildren()) do
            if isl.Name == "Island " .. i then
                if Player:DistanceFromCharacter(isl.Position) < 3500 then
                    return isl
                end
            end
        end
    end
end

function Module:RemoveVolcanoLava()
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    local PI = Map:FindFirstChild("PrehistoricIsland")
    if not PI then return end
    for _, inst in ipairs(PI:GetDescendants()) do
        if inst:IsA("BasePart") and string.find(string.lower(inst.Name), "lava") then
            pcall(function() inst:Destroy() end)
        end
    end
end

function Module:RemoveBoatCollision(boat)
    if not boat then return end
    for _, inst in ipairs(boat:GetDescendants()) do
        if inst:IsA("BasePart") then
            pcall(function() inst.CanCollide = false end)
        end
    end
end

-- Noclip / BodyVelocity loop
task.spawn(function()
    while task.wait() do
        if _ENV.OnFarm or FarmState.AutoFarm then
            local char = Player.Character
            if char then
                local bv = _ENV.tween_bodyvelocity
                local root = char:FindFirstChild("HumanoidRootPart")
                if bv and root and bv.Parent ~= root then bv.Parent = root end
                for _, inst in ipairs(char:GetDescendants()) do
                    if inst:IsA("BasePart") and inst.CanCollide then
                        pcall(function() inst.CanCollide = false end)
                    end
                end
            end
        end
    end
end)

-- Bind keys
Library:BindKey({Text = "Toggle UI", Keybind = Enum.KeyCode.RightShift, Callback = function() Library:Toggle() end})
Library:BindKey({Text = "Toggle AutoFarm", Keybind = Enum.KeyCode.F1, Callback = function()
    FarmState.AutoFarm = not FarmState.AutoFarm
    Library:Notify({Title = "Leaf Hub", Text = "AutoFarm: " .. (FarmState.AutoFarm and "ON" or "OFF"), Duration = 2})
    PlayNotify()
end})
Library:BindKey({Text = "Toggle KillAura", Keybind = Enum.KeyCode.F2, Callback = function()
    _ENV._KillAuraEnabled = not _ENV._KillAuraEnabled
    Library:Notify({Title = "Leaf Hub", Text = "KillAura: " .. (_ENV._KillAuraEnabled and "ON" or "OFF"), Duration = 2})
    PlayNotify()
end})
Library:BindKey({Text = "Toggle AutoClick", Keybind = Enum.KeyCode.F3, Callback = function()
    Settings.AutoClick = not Settings.AutoClick
    Library:Notify({Title = "Leaf Hub", Text = "AutoClick: " .. (Settings.AutoClick and "ON" or "OFF"), Duration = 2})
    PlayNotify()
end})

-- Sync initial settings vào Module
Settings.FarmTool = "Melee"
Settings.RunningOption = nil
Settings.RunningMethod = nil
_ENV.OnFarm = false

-- Character reset handler
table.insert(Connections, Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if FarmState.AutoFarm then
        _ENV.OnFarm = true
    end
end))

-- Auto pickup chest when near
task.spawn(function()
    while task.wait(0.5) do
        if FarmState.AutoChest then
            local char = Player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
                        if not chest:GetAttribute("IsDisabled") then
                            local cpos = chest:GetPivot().Position
                            if (hrp.Position - cpos).Magnitude < 15 then
                                pcall(function() Module.FireRemote("ChestReward", chest.Name) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Final notify
task.delay(1, function()
    Library:Notify({Title = "Leaf Hub", Text = "Ready! Press RightShift to toggle UI", Duration = 6})
    PlayNotify()
end)

print("[Leaf Hub] Bloxfruit v1 loaded | Sea: " .. tostring(Module.GameData.Sea) .. " | Executor: " .. EXECUTOR_NAME)
