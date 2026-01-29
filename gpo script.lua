--[[
        ZuevHub + Bandit Aimbot + Takestam 3sec + WalkSpeed 1-130 (ULTRA FAST FARM)
        ✅ ULTRA FAST AUTO FARM (БЫСТРЕЕ чем EQUIP+SHOT!) + НОВЫЙ ОБХОД!
]]--

local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

-- Core Variables
local autoShooting = false
local speedEnabled = false
local takestamEnabled = false
local showAimLine = false
local aimLine = nil
local currentTargetPos = nil
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local rifleMonitorConnection = nil
local speedConnection = nil
local takestamConnection = nil
local lastEquipTime = 0
local EQUIP_COOLDOWN = 2
local selectedTarget = "Bandit"
local currentWalkSpeed = 16

-- 🔥 АВТО-ОПРЕДЕЛЕНИЕ АККАУНТА (Universal)
local function getPlayerCharacter()
    local playerChars = workspace:FindFirstChild("PlayerCharacters")
    if playerChars then
        local playerModel = playerChars:FindFirstChild(player.Name)
        if playerModel then return playerModel end
        local echoxit = playerChars:FindFirstChild("Echoxit7366")
        if echoxit then return echoxit end
    end
    return player.Character
end

-- 🔥 TAKESTAM ФУНКЦИЯ (3 сек)
local function callTakestam()
    local args = {0.5650000000000001, "dash"}
    local success = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("takestam"):FireServer(unpack(args))
    end)
    if success then 
        print("[takestam] Вызван в " .. os.date("%H:%M:%S"))
    end
    return success
end

local function startTakestamLoop()
    if takestamConnection then task.cancel(takestamConnection) end
    takestamConnection = task.spawn(function()
        callTakestam()
        while takestamEnabled do
            task.wait(3)
            if takestamEnabled then callTakestam() end
        end
    end)
end

local function stopTakestamLoop()
    takestamEnabled = false
    if takestamConnection then task.cancel(takestamConnection); takestamConnection = nil end
end

-- 🔥 WALKSPED BYPASS (1-130)
local function startSpeedBypass()
    if speedConnection then speedConnection:Disconnect() end
    
    speedConnection = RunService.Heartbeat:Connect(function()
        if speedEnabled then
            local playerChar = getPlayerCharacter()
            if playerChar and playerChar:FindFirstChild("Humanoid") then
                local humanoid = playerChar.Humanoid
                humanoid.WalkSpeed = 16
                
                local rootPart = playerChar:FindFirstChild("HumanoidRootPart")
                if rootPart and humanoid.MoveDirection.Magnitude > 0 then
                    local speedFactor = (currentWalkSpeed / 16) * 1.3
                    rootPart.Velocity = Vector3.new(
                        humanoid.MoveDirection.X * speedFactor * 18,
                        rootPart.Velocity.Y, 
                        humanoid.MoveDirection.Z * speedFactor * 18
                    )
                end
            end
        end
    end)
    print("🚀 Speed + Takestam bypass started (1-130)")
end

local function stopSpeedBypass()
    if speedConnection then 
        speedConnection:Disconnect() 
        speedConnection = nil
        local playerChar = getPlayerCharacter()
        if playerChar and playerChar:FindFirstChild("Humanoid") then
            playerChar.Humanoid.WalkSpeed = 16
        end
        print("🚀 Speed bypass stopped")
    end
end

local function updateWalkSpeed()
    currentWalkSpeed = math.clamp(currentWalkSpeed, 1, 130)
    if speedEnabled then startSpeedBypass() end
    print("🚀 WalkSpeed set → " .. currentWalkSpeed)
end

-- ✅ ВСЕ ФУНКЦИИ (equipRifle, rifle monitor, etc.)
local function equipRifle()
    local currentTime = tick()
    if currentTime - lastEquipTime < EQUIP_COOLDOWN then return false end
    
    local playerChar = getPlayerCharacter()
    if not playerChar or not playerChar:FindFirstChild("Humanoid") then return false end
    
    local rifle = player.Backpack:FindFirstChild("Rifle")
    if rifle then
        playerChar.Humanoid:EquipTool(rifle)
        lastEquipTime = currentTime
        print("🔫 Rifle equipped → Target: " .. selectedTarget)
        return true
    end
    return false
end

local function startRifleMonitor()
    if rifleMonitorConnection then rifleMonitorConnection:Disconnect() end
    
    local consecutiveFails = 0
    rifleMonitorConnection = RunService.Heartbeat:Connect(function()
        if autoShooting then
            local playerChar = getPlayerCharacter()
            if playerChar and playerChar:FindFirstChild("Humanoid") then
                local rifleInChar = playerChar:FindFirstChild("Rifle")
                local rifleInBackpack = player.Backpack:FindFirstChild("Rifle")
                
                if not rifleInChar and rifleInBackpack and tick() - lastEquipTime > EQUIP_COOLDOWN then
                    if equipRifle() then consecutiveFails = 0 else consecutiveFails = consecutiveFails + 1 end
                elseif rifleInChar then consecutiveFails = 0 end
                
                if consecutiveFails > 5 then task.wait(1); consecutiveFails = 0 end
            end
        end
    end)
end

local function stopRifleMonitor()
    if rifleMonitorConnection then rifleMonitorConnection:Disconnect(); rifleMonitorConnection = nil end
end

local targetTracking = RunService.Heartbeat:Connect(function()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then currentTargetPos = nil; return end
    
    local targetModel = nil
    if selectedTarget == "Bandit" then targetModel = npcs:FindFirstChild("Bandit")
    elseif selectedTarget == "Bandit Boss" then targetModel = npcs:FindFirstChild("Bandit Boss") end
    
    if targetModel and targetModel:FindFirstChild("Head") then
        local humanoid = targetModel:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            currentTargetPos = targetModel.Head.Position
        else
            currentTargetPos = nil
        end
    else
        currentTargetPos = nil
    end
end)

local function isTargetAlive()
    if not currentTargetPos then return false end
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return false end
    
    local targetModel = selectedTarget == "Bandit" and npcs:FindFirstChild("Bandit") or npcs:FindFirstChild("Bandit Boss")
    return targetModel and targetModel:FindFirstChild("Head") and targetModel:FindFirstChild("Humanoid") and targetModel.Humanoid.Health > 0
end

local function createAimLine(fromPos, headPos)
    if aimLine then aimLine:Destroy() end
    if not headPos then return end
    local distance = (headPos - fromPos).Magnitude
    aimLine = Instance.new("Part")
    aimLine.Name = "AimLine"; aimLine.Anchored = true; aimLine.CanCollide = false
    aimLine.Transparency = 0.3; aimLine.Color = Color3.fromRGB(255, 50, 50)
    aimLine.Material = Enum.Material.Neon; aimLine.Size = Vector3.new(0.2, 0.2, distance)
    local center = (fromPos + headPos) / 2
    aimLine.CFrame = CFrame.lookAt(center, headPos) * CFrame.new(0, 0, -distance/2)
    aimLine.Parent = workspace
end

function shootTargetHead()
    if not currentTargetPos or not isTargetAlive() then return false end
    local playerChar = getPlayerCharacter()
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return false end
    
    local playerPos = playerChar.HumanoidRootPart.Position
    local startCFrame = CFrame.lookAt(playerPos + Vector3.new(0, 2, 0), currentTargetPos)
    
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GunManager"):WaitForChild("gunFunctions"):InvokeServer("reload", {Gun = "Rifle"})
    end)
    
    local fireArgs = {"fire", {Start = startCFrame, Gun = "Rifle", joe = "true", Position = currentTargetPos}}
    local success = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("GunManager"):FireServer(unpack(fireArgs))
    end)
    return success
end

-- 🔥 ULTRA FAST AUTO FARM (БЫСТРЕЕ чем EQUIP+SHOT!)
local function smartAutoLoop()
    print("🚀 ULTRA FAST Auto Farm → Target: " .. selectedTarget)
    equipRifle(); task.wait(0.5); startRifleMonitor()
    
    while autoShooting do
        if currentTargetPos and isTargetAlive() then
            shootTargetHead()
            task.wait(0.1)  -- ✅ 20x БЫСТРЕЕ старого!
        else
            task.wait(0.05)  -- Мгновенный поиск цели!
        end
    end
end

-- Blood Effects Blocker
spawn(function()
    while true do task.wait(0.1)
        for _, gui in pairs(player.PlayerGui:GetChildren()) do
            if gui.Name:lower():find("blood") or gui.Name:lower():find("damage") then gui:Destroy() end
        end
    end
end)

-- ZuevHub UI
local Notifier = Compkiller.newNotify()
local ConfigManager = Compkiller:ConfigManager({Directory = "ZuevHub", Config = "BanditAimbot"})
Compkiller:Loader("rbxassetid://120245531583106", 2.5).yield()

local Window = Compkiller.new({Name = "🎯 ZuevHub", Keybind = "RightAlt", Logo = "rbxassetid://120245531583106", Scale = Compkiller.Scale.Window, TextSize = 15})

Notifier.new({Title = "ZuevHub", Content = "ULTRA FAST FARM + Speed 1-130 + Takestam!", Duration = 5, Icon = "rbxassetid://120245531583106"})

local Watermark = Window:Watermark()
Watermark:AddText({Icon = "skull", Text = "Bandit Farmer"})
Watermark:AddText({Icon = "clock", Text = Compkiller:GetDate()})
local Time = Watermark:AddText({Icon = "timer", Text = "TIME"})
task.spawn(function() while true do task.wait(); Time:SetText(Compkiller:GetTimeNow()) end end)

-- Bandit Aimbot Tab
Window:DrawCategory({Name = "🎯 BANDIT FARM"})
local AimbotTab = Window:DrawTab({Name = "Bandit Aimbot", Icon = "skull", EnableScrolling = true})

local TargetSection = AimbotTab:DrawSection({Name = "🎯 Выбор бандита", Position = 'left'})
TargetSection:AddDropdown({Name = "Target", Default = "Bandit", Flag = "SelectedTarget", Values = {"Bandit", "Bandit Boss"}, Callback = function(Value)
    selectedTarget = Value
    Notifier.new({Title = "🎯 Цель", Content = Value, Duration = 2})
end})

local SpeedSection = AimbotTab:DrawSection({Name = "🚀 WalkSpeed + Takestam", Position = 'left'})
SpeedSection:AddSlider({Name = "Скорость (1-130)", Min = 1, Max = 130, Default = 16, Color = Color3.fromRGB(0, 255, 0), Flag = "WalkSpeedSlider", Callback = function(Value)
    currentWalkSpeed = Value
    updateWalkSpeed()
    Notifier.new({Title = "🚀 Скорость", Content = Value .. " + Takestam 3s", Duration = 1.5})
end})

SpeedSection:AddToggle({
    Name = "🚀 Speed + Takestam ON/OFF", 
    Flag = "SpeedToggle", 
    Default = false,
    Callback = function(Value)
        speedEnabled = Value
        takestamEnabled = Value
        
        if Value then
            startSpeedBypass()
            startTakestamLoop()
            Notifier.new({Title = "🚀 SPEED ON", Content = currentWalkSpeed .. " + Takestam!", Duration = 2})
        else
            stopSpeedBypass()
            stopTakestamLoop()
            Notifier.new({Title = "⏹️ SPEED OFF", Content = "16 studs/s", Duration = 2})
        end
    end,
})

local FarmSection = AimbotTab:DrawSection({Name = "Auto Farm", Position = 'left'})
FarmSection:AddToggle({Name = "🧠 ULTRA FAST FARM", Flag = "BanditAuto", Default = false, Callback = function(Value)
    autoShooting = Value
    if Value then
        spawn(smartAutoLoop)
        Notifier.new({Title = "🚀 ULTRA FAST ON", Content = "600 выстр/мин " .. selectedTarget .. "!", Duration = 4})
    else
        stopRifleMonitor()
        Notifier.new({Title = "⏹️ FARM OFF", Content = "Остановлен", Duration = 2})
    end
end})

FarmSection:AddButton({Name = "🔫 EQUIP + SHOOT", Callback = function()
    equipRifle(); task.wait(0.5)
    if shootTargetHead() then Notifier.new({Title = "💀 HEADSHOT", Content = selectedTarget .. " убит!", Duration = 2})
    else Notifier.new({Title = "❌ NO TARGET", Content = selectedTarget .. " нет", Duration = 2}) end
end})

local AimToggle = FarmSection:AddToggle({Name = "📍 Aim Line", Flag = "AimLine", Default = false, Callback = function(Value)
    showAimLine = Value
    if Value and currentTargetPos then
        local playerChar = getPlayerCharacter()
        if playerChar and playerChar:FindFirstChild("HumanoidRootPart") then 
            createAimLine(playerChar.HumanoidRootPart.Position, currentTargetPos) 
        end
    elseif not Value and aimLine then aimLine:Destroy(); aimLine = nil end
end})

-- Info Section
local InfoSection = AimbotTab:DrawSection({Name = "Info", Position = 'right'})
local TargetLabel = InfoSection:AddParagraph({Title = "Target", Content = selectedTarget})
local SpeedLabel = InfoSection:AddParagraph({Title = "Speed+Takestam", Content = "16 (OFF)"})
local DistanceLabel = InfoSection:AddParagraph({Title = "Distance", Content = "⏳ Waiting..."})

spawn(function()
    while true do task.wait(0.2)
        TargetLabel:SetContent(selectedTarget)
        SpeedLabel:SetContent(speedEnabled and (currentWalkSpeed .. " (ON)") or "16 (OFF)")
        if currentTargetPos and isTargetAlive() then
            local playerChar = getPlayerCharacter()
            if playerChar and playerChar:FindFirstChild("HumanoidRootPart") then
                local dist = (currentTargetPos - playerChar.HumanoidRootPart.Position).Magnitude
                DistanceLabel:SetContent("✅ " .. math.floor(dist) .. "m")
            end
        else DistanceLabel:SetContent("⏳ Нет цели...") end
    end
end)

-- Themes
Window:DrawCategory({Name = "🎨 THEMES"})
local ThemeTab = Window:DrawTab({Icon = "paintbrush", Name = "Themes", Type = "Single"})
local ThemeSection = ThemeTab:DrawSection({Name = "UI Themes", Position = 'left'})
ThemeSection:AddDropdown({Name = "Theme", Default = "Default", Flag = "UI_Theme", Values = {"Default", "Dark Green", "Dark Blue", "Purple Rose", "Skeet"}, Callback = function(Value)
    Compkiller:SetTheme(Value); Notifier.new({Title = "Theme", Content = Value, Duration = 2})
end})

local ConfigUI = Window:DrawConfig({Name = "Config", Icon = "folder", Config = ConfigManager}); ConfigUI:Init()

-- Auto speed on spawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    if speedEnabled then 
        startSpeedBypass()
        startTakestamLoop()
    end
end)

print("🎯 ZuevHub ULTRA FAST FARM (600 выстр/мин) + Speed 1-130 + Takestam READY!")
print("✅ БЫСТРЕЕ чем EQUIP+SHOT! Работает с ЛЮБЫМ аккаунтом!")
