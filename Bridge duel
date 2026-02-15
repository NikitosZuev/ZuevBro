local aimEnabled = false
local autoclickerEnabled = false
local chamsEnabled = false
local bedESPEnabled = false
local radius = 16
local smoothness = 0.3
local targetPart = "HumanoidRootPart"
local currentTarget = nil
local currentTargetPlayer = nil
local wallCheck = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local chamsObjects = {}
local bedESPObjects = {}

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "zuev"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 140, 0, 115)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 20)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "zuev"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = frame

-- Aim статус
local aimStatusFrame = Instance.new("Frame")
aimStatusFrame.Size = UDim2.new(1, 0, 0, 20)
aimStatusFrame.Position = UDim2.new(0, 0, 0, 20)
aimStatusFrame.BackgroundTransparency = 1
aimStatusFrame.Parent = frame

local aimDot = Instance.new("Frame")
aimDot.Size = UDim2.new(0, 12, 0, 12)
aimDot.Position = UDim2.new(0, 15, 0, 4)
aimDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
aimDot.Parent = aimStatusFrame

local aimDotCorner = Instance.new("UICorner")
aimDotCorner.CornerRadius = UDim.new(1, 0)
aimDotCorner.Parent = aimDot

local aimText = Instance.new("TextLabel")
aimText.Size = UDim2.new(0, 100, 0, 20)
aimText.Position = UDim2.new(0, 30, 0, 0)
aimText.BackgroundTransparency = 1
aimText.Text = "AIM (X): OFF"
aimText.TextColor3 = Color3.fromRGB(255, 100, 100)
aimText.TextSize = 12
aimText.Font = Enum.Font.Gotham
aimText.TextXAlignment = Enum.TextXAlignment.Left
aimText.Parent = aimStatusFrame

-- Autoclicker статус
local clickStatusFrame = Instance.new("Frame")
clickStatusFrame.Size = UDim2.new(1, 0, 0, 20)
clickStatusFrame.Position = UDim2.new(0, 0, 0, 45)
clickStatusFrame.BackgroundTransparency = 1
clickStatusFrame.Parent = frame

local clickDot = Instance.new("Frame")
clickDot.Size = UDim2.new(0, 12, 0, 12)
clickDot.Position = UDim2.new(0, 15, 0, 4)
clickDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
clickDot.Parent = clickStatusFrame

local clickDotCorner = Instance.new("UICorner")
clickDotCorner.CornerRadius = UDim.new(1, 0)
clickDotCorner.Parent = clickDot

local clickText = Instance.new("TextLabel")
clickText.Size = UDim2.new(0, 100, 0, 20)
clickText.Position = UDim2.new(0, 30, 0, 0)
clickText.BackgroundTransparency = 1
clickText.Text = "CLICK (M3): OFF"
clickText.TextColor3 = Color3.fromRGB(255, 100, 100)
clickText.TextSize = 12
clickText.Font = Enum.Font.Gotham
clickText.TextXAlignment = Enum.TextXAlignment.Left
clickText.Parent = clickStatusFrame

-- Chams статус
local chamsStatusFrame = Instance.new("Frame")
chamsStatusFrame.Size = UDim2.new(1, 0, 0, 20)
chamsStatusFrame.Position = UDim2.new(0, 0, 0, 70)
chamsStatusFrame.BackgroundTransparency = 1
chamsStatusFrame.Parent = frame

local chamsDot = Instance.new("Frame")
chamsDot.Size = UDim2.new(0, 12, 0, 12)
chamsDot.Position = UDim2.new(0, 15, 0, 4)
chamsDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
chamsDot.Parent = chamsStatusFrame

local chamsDotCorner = Instance.new("UICorner")
chamsDotCorner.CornerRadius = UDim.new(1, 0)
chamsDotCorner.Parent = chamsDot

local chamsText = Instance.new("TextLabel")
chamsText.Size = UDim2.new(0, 100, 0, 20)
chamsText.Position = UDim2.new(0, 30, 0, 0)
chamsText.BackgroundTransparency = 1
chamsText.Text = "CHAMS (Z): OFF"
chamsText.TextColor3 = Color3.fromRGB(255, 100, 100)
chamsText.TextSize = 12
chamsText.Font = Enum.Font.Gotham
chamsText.TextXAlignment = Enum.TextXAlignment.Left
chamsText.Parent = chamsStatusFrame

-- Bed ESP статус
local bedStatusFrame = Instance.new("Frame")
bedStatusFrame.Size = UDim2.new(1, 0, 0, 20)
bedStatusFrame.Position = UDim2.new(0, 0, 0, 95)
bedStatusFrame.BackgroundTransparency = 1
bedStatusFrame.Parent = frame

local bedDot = Instance.new("Frame")
bedDot.Size = UDim2.new(0, 12, 0, 12)
bedDot.Position = UDim2.new(0, 15, 0, 4)
bedDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
bedDot.Parent = bedStatusFrame

local bedDotCorner = Instance.new("UICorner")
bedDotCorner.CornerRadius = UDim.new(1, 0)
bedDotCorner.Parent = bedDot

local bedText = Instance.new("TextLabel")
bedText.Size = UDim2.new(0, 100, 0, 20)
bedText.Position = UDim2.new(0, 30, 0, 0)
bedText.BackgroundTransparency = 1
bedText.Text = "BED ESP (B): OFF"
bedText.TextColor3 = Color3.fromRGB(255, 100, 100)
bedText.TextSize = 12
bedText.Font = Enum.Font.Gotham
bedText.TextXAlignment = Enum.TextXAlignment.Left
bedText.Parent = bedStatusFrame

-- Функция обновления GUI
local function updateGUI()
    if aimEnabled then
        aimDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        aimText.Text = "AIM (X): ON"
        aimText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        aimDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        aimText.Text = "AIM (X): OFF"
        aimText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    if autoclickerEnabled then
        clickDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        clickText.Text = "CLICK (M3): ON"
        clickText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        clickDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        clickText.Text = "CLICK (M3): OFF"
        clickText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    if chamsEnabled then
        chamsDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        chamsText.Text = "CHAMS (Z): ON"
        chamsText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        chamsDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        chamsText.Text = "CHAMS (Z): OFF"
        chamsText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    if bedESPEnabled then
        bedDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        bedText.Text = "BED ESP (B): ON"
        bedText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        bedDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        bedText.Text = "BED ESP (B): OFF"
        bedText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Chams функции
local function applyChams(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    
    if chamsObjects[player] then
        for _, obj in pairs(chamsObjects[player]) do
            pcall(function() obj:Destroy() end)
        end
    end
    
    chamsObjects[player] = {}
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(0, 150, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    table.insert(chamsObjects[player], highlight)
    
    local highlight2 = Instance.new("Highlight")
    highlight2.Parent = player.Character
    highlight2.Adornee = player.Character
    highlight2.FillColor = Color3.fromRGB(0, 100, 255)
    highlight2.OutlineColor = Color3.fromRGB(200, 200, 255)
    highlight2.FillTransparency = 0.5
    highlight2.OutlineTransparency = 0.3
    highlight2.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    table.insert(chamsObjects[player], highlight2)
    
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = player.Character:FindFirstChild("Head") or player.Character
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = billboard
    
    table.insert(chamsObjects[player], billboard)
end

local function removeChams(player)
    if chamsObjects[player] then
        for _, obj in pairs(chamsObjects[player]) do
            pcall(function() obj:Destroy() end)
        end
        chamsObjects[player] = nil
    end
end

local function toggleChams()
    chamsEnabled = not chamsEnabled
    
    if chamsEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                applyChams(player)
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            removeChams(player)
        end
    end
    
    updateGUI()
end

-- BED ESP функции (ПРОСТО BED БЕЗ ЦВЕТОВ)
local function findBeds()
    local beds = {}
    local map = workspace:FindFirstChild("Map")
    
    if map then
        for _, obj in pairs(map:GetChildren()) do
            if obj.Name == "Bed" then
                table.insert(beds, obj)
            end
        end
        
        for _, obj in pairs(map:GetDescendants()) do
            if obj.Name == "Bed" and obj:IsA("BasePart") then
                if not table.find(beds, obj) then
                    table.insert(beds, obj)
                end
            end
        end
    end
    
    return beds
end

local function createBedESP(bed)
    if bedESPObjects[bed] then
        for _, obj in pairs(bedESPObjects[bed]) do
            pcall(function() obj:Destroy() end)
        end
        bedESPObjects[bed] = nil
    end
    
    -- Billboard с надписью BED
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = bed
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = bed
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.3
    bg.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = bg
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🛏️ BED"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.Parent = bg
    
    -- Подсветка кровати (белая)
    local highlight = Instance.new("Highlight")
    highlight.Parent = bed
    highlight.Adornee = bed
    highlight.FillColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    bedESPObjects[bed] = {billboard, highlight}
end

local function updateBedESP()
    if not bedESPEnabled then return end
    
    local beds = findBeds()
    
    for _, bed in pairs(beds) do
        if bed and bed.Parent then
            if not bedESPObjects[bed] then
                createBedESP(bed)
            end
        end
    end
    
    for bedObj, _ in pairs(bedESPObjects) do
        if not bedObj or not bedObj.Parent then
            for _, obj in pairs(bedESPObjects[bedObj]) do
                pcall(function() obj:Destroy() end)
            end
            bedESPObjects[bedObj] = nil
        end
    end
end

local function toggleBedESP()
    bedESPEnabled = not bedESPEnabled
    
    if bedESPEnabled then
        updateBedESP()
    else
        for bedObj, objects in pairs(bedESPObjects) do
            for _, obj in pairs(objects) do
                pcall(function() obj:Destroy() end)
            end
        end
        bedESPObjects = {}
    end
    
    updateGUI()
end

-- Отслеживание новых игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if chamsEnabled then
            task.wait(0.5)
            applyChams(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeChams(player)
end)

-- Wall check функция
local function isVisible(targetPart)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local camera = Camera
    local cameraPos = camera.CFrame.Position
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {character, targetPart.Parent}
    
    local direction = (targetPart.Position - cameraPos).Unit * (targetPart.Position - cameraPos).Magnitude
    local result = workspace:Raycast(cameraPos, direction, params)
    
    return result == nil
end

-- AIM функции
local function isTargetAlive()
    if not currentTargetPlayer or not currentTargetPlayer.Character then
        return false
    end
    
    local targetChar = currentTargetPlayer.Character
    local targetHumanoid = targetChar:FindFirstChild("Humanoid")
    local targetPartObj = targetChar:FindFirstChild(targetPart)
    
    if not targetHumanoid or not targetPartObj then
        return false
    end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local distance = (rootPart.Position - targetPartObj.Position).Magnitude
    
    if targetHumanoid.Health > 0 and distance <= radius then
        if wallCheck then
            return isVisible(targetPartObj)
        else
            return true
        end
    end
    
    return false
end

local function findNewTarget()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, nil end
    
    local closestPlayer = nil
    local closestDistance = radius + 1
    local closestPos = nil
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetChar = player.Character
            local targetHumanoid = targetChar:FindFirstChild("Humanoid")
            local targetPartObj = targetChar:FindFirstChild(targetPart)
            
            if targetHumanoid and targetHumanoid.Health > 0 and targetPartObj then
                local distance = (rootPart.Position - targetPartObj.Position).Magnitude
                
                if distance <= radius then
                    if wallCheck then
                        if isVisible(targetPartObj) then
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = player
                                closestPos = targetPartObj.Position
                            end
                        end
                    else
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = player
                            closestPos = targetPartObj.Position
                        end
                    end
                end
            end
        end
    end
    
    if closestDistance <= radius then
        return closestPlayer, closestPos
    end
    return nil, nil
end

local function getTargetPosition()
    if not currentTargetPlayer or not currentTargetPlayer.Character then
        return nil
    end
    
    local targetPartObj = currentTargetPlayer.Character:FindFirstChild(targetPart)
    if targetPartObj then
        return targetPartObj.Position
    end
    return nil
end

local function aimAt(targetPos)
    if not targetPos then return end
    
    local camera = Camera
    local currentCF = camera.CFrame
    local lookAtCF = CFrame.lookAt(currentCF.Position, targetPos)
    
    camera.CFrame = currentCF:Lerp(lookAtCF, smoothness)
end

local function aimLoop()
    while true do
        if aimEnabled then
            if currentTargetPlayer and isTargetAlive() then
                local targetPos = getTargetPosition()
                if targetPos then
                    aimAt(targetPos)
                end
            else
                local newPlayer, newPos = findNewTarget()
                if newPlayer and newPos then
                    currentTargetPlayer = newPlayer
                    currentTarget = newPos
                    aimAt(newPos)
                else
                    currentTargetPlayer = nil
                    currentTarget = nil
                end
            end
        end
        RunService.RenderStepped:Wait()
    end
end

-- Autoclicker функции
local function click()
    mouse1click()
end

local function clickLoop()
    while autoclickerEnabled do
        click()
        local randomDelay = math.random(2, 10) / 1000
        wait(randomDelay)
    end
end

-- Bed ESP цикл
local function bedESPLoop()
    while true do
        if bedESPEnabled then
            updateBedESP()
        end
        RunService.RenderStepped:Wait()
    end
end

-- Бинды
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X then
        aimEnabled = not aimEnabled
        if aimEnabled then
            local newPlayer, newPos = findNewTarget()
            if newPlayer and newPos then
                currentTargetPlayer = newPlayer
                currentTarget = newPos
            end
        else
            currentTargetPlayer = nil
            currentTarget = nil
        end
        updateGUI()
    end
    
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        autoclickerEnabled = not autoclickerEnabled
        if autoclickerEnabled then
            coroutine.wrap(clickLoop)()
        end
        updateGUI()
    end
    
    if input.KeyCode == Enum.KeyCode.Z then
        toggleChams()
    end
    
    if input.KeyCode == Enum.KeyCode.B then
        toggleBedESP()
    end
end)

-- Запуск
coroutine.wrap(aimLoop)()
coroutine.wrap(bedESPLoop)()
updateGUI()

task.wait(1)
if chamsEnabled then
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyChams(player)
        end
    end
end
