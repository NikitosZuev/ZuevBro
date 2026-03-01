-- // СЕРВИСЫ
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction", 30)
local playerGui = player:WaitForChild("PlayerGui")
if not RemoteFunction then return end

-- // НАСТРОЙКИ
local SETTINGS_FILE = "ZuevHub_Settings.json"
local DefaultSettings = {WebhookURL = "", AutoReconnect = true, AntiAfk = true}
local Settings = {}

local function LoadSettings()
    local ok = pcall(function()
        if isfile and readfile and isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            if type(data) == "table" then Settings = data return end
        end
        Settings = DefaultSettings
    end)
    if not ok or not next(Settings) then Settings = DefaultSettings end
end

local function SaveSettings()
    pcall(function()
        if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings)) end
    end)
end

LoadSettings()
local WEBHOOK_URL = Settings.WebhookURL or ""
local SendRequest = request or http_request or httprequest  -- общий HTTP [web:315]

-- // СОСТОЯНИЕ ИГРЫ
local GameState = "UNKNOWN"
local function UpdateGameState()
    local rewardsGui = playerGui:FindFirstChild("ReactGameNewRewards")
    if rewardsGui and rewardsGui.Enabled then
        local frame = rewardsGui:FindFirstChild("Frame")
        local gameOver = frame and frame:FindFirstChild("gameOver")
        if gameOver and gameOver.Visible then GameState = "REWARDS" return end
    end
    if playerGui:FindFirstChild("ReactLobbyHud") then GameState = "LOBBY" return end
    if playerGui:FindFirstChild("ReactUniversalHotbar") then GameState = "GAME" return end
    GameState = "UNKNOWN"
end

task.spawn(function()
    while true do pcall(UpdateGameState) task.wait(1) end
end)

-- // АНТИ-АФК
local function StartAntiAfk()
    if not Settings.AntiAfk then return end
    task.spawn(function()
        while Settings.AntiAfk do
            task.wait(60)
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        end
    end)
end
pcall(StartAntiAfk)

-- // АВТО-РЕКОННЕКТ
local function StartAutoReconnect()
    if not Settings.AutoReconnect then return end
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        local overlay = coreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
        overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                task.wait(2)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, player)
                end)
            end
        end)
    end)
end
pcall(StartAutoReconnect)

-- // СТАТИСТИКА
local Stats = {
    Coins = 0, Gems = 0,
    StartCoins = 0, StartGems = 0,
    EarnedCoins = 0, EarnedGems = 0,
    TotalCoins = 0, TotalGems = 0,
    SessionStart = tick()
}

local function UpdateStats()
    pcall(function()
        local c = player:FindFirstChild("Coins")
        local g = player:FindFirstChild("Gems")
        if c then Stats.Coins = c.Value end
        if g then Stats.Gems = g.Value end
        Stats.EarnedCoins = Stats.Coins - Stats.StartCoins
        Stats.EarnedGems = Stats.Gems - Stats.StartGems
    end)
end

local function TrackStats()
    pcall(function()
        local c = player:FindFirstChild("Coins")
        local g = player:FindFirstChild("Gems")
        if c then c.Changed:Connect(UpdateStats) end
        if g then g.Changed:Connect(UpdateStats) end
    end)
end

local function ResetStats()
    Stats.TotalCoins += Stats.EarnedCoins
    Stats.TotalGems += Stats.EarnedGems
    UpdateStats()
    Stats.StartCoins = Stats.Coins
    Stats.StartGems = Stats.Gems
    Stats.SessionStart = tick()
end

pcall(TrackStats)
pcall(UpdateStats)
pcall(ResetStats)

-- // МАКРО / КЭШ БАШЕН
local isRecording, isPlaying = false, false
local macro, macroStartTime, macroName = {}, 0, "macro_1"
local TowerLevels = {}
local TowerInfo = {}  -- [towerInstance] = {name, pos, level}

local function EnsureMacroFolder()
    pcall(function()
        if isfolder and not isfolder("Zuev Hub") then makefolder("Zuev Hub") end
    end)
end

local function ListMacros()
    local list = {}
    pcall(function()
        if not listfiles then return end
        EnsureMacroFolder()
        for _, path in ipairs(listfiles("Zuev Hub")) do
            if path:sub(-5) == ".json" then
                local name = path:match("Zuev Hub[\\/](.+)%.json")
                if name then table.insert(list, name) end
            end
        end
        table.sort(list)
    end)
    return list
end

-- // GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "MacroRecorder_TDS"
gui.Parent = player:WaitForChild("PlayerGui")

local function ShowToast(msg)
    local toastGui = gui:FindFirstChild("Toasts")
    if not toastGui then
        toastGui = Instance.new("Frame")
        toastGui.Name = "Toasts"
        toastGui.Parent = gui
        toastGui.BackgroundTransparency = 1
        toastGui.Size = UDim2.new(0, 300, 1, 0)
        toastGui.AnchorPoint = Vector2.new(1,1)
        toastGui.Position = UDim2.new(1, -10, 1, -10)
        local layout = Instance.new("UIListLayout", toastGui)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,40)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.15
    frame.Parent = toastGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,-10,1,0)
    label.Position = UDim2.new(0,5,0,0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(230,230,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = msg

    frame.BackgroundTransparency = 1
    label.TextTransparency = 1
    TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
    TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

    task.delay(2.5, function()
        local o1 = TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        local o2 = TweenService:Create(label, TweenInfo.new(0.2), {TextTransparency = 1})
        o1:Play(); o2:Play()
        o2.Completed:Wait()
        frame:Destroy()
    end)
end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 600, 0, 360)
main.Position = UDim2.new(0.5, -300, 0.4, -180)
main.BackgroundColor3 = Color3.fromRGB(12,12,20)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

do
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1,0,0,50)
topBar.BackgroundColor3 = Color3.fromRGB(18,18,30)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0.6,-10,0.6,0)
title.Position = UDim2.new(0,10,0,2)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.Text = "MACRO RECORDER"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 18

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(0.6,-10,0.4,0)
subtitle.Position = UDim2.new(0,10,0.6,0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "by zuev and temka"
subtitle.TextColor3 = Color3.fromRGB(170,170,200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextSize = 13

local webhookBox = Instance.new("TextBox", topBar)
webhookBox.Size = UDim2.new(0.5,-10,0.6,0)
webhookBox.Position = UDim2.new(0.3,5,0.2,0)
webhookBox.BackgroundColor3 = Color3.fromRGB(22,22,40)
webhookBox.BorderSizePixel = 0
Instance.new("UICorner", webhookBox).CornerRadius = UDim.new(0,6)
webhookBox.Font = Enum.Font.Gotham
webhookBox.Text = WEBHOOK_URL or ""
webhookBox.TextColor3 = Color3.fromRGB(220,220,240)
webhookBox.TextSize = 13
webhookBox.ClearTextOnFocus = false
webhookBox.TextTruncate = Enum.TextTruncate.AtEnd

webhookBox.FocusLost:Connect(function()
    if webhookBox.Text ~= "" then
        Settings.WebhookURL = webhookBox.Text
        WEBHOOK_URL = webhookBox.Text
        SaveSettings()
        ShowToast("Webhook saved")
    end
end)

local testWebhookBtn = Instance.new("TextButton", topBar)
testWebhookBtn.Size = UDim2.new(0,115,0.6,0)
testWebhookBtn.Position = UDim2.new(1,-125,0.2,0)
testWebhookBtn.BackgroundColor3 = Color3.fromRGB(60,40,90)
testWebhookBtn.BorderSizePixel = 0
Instance.new("UICorner", testWebhookBtn).CornerRadius = UDim.new(0,8)
testWebhookBtn.Font = Enum.Font.GothamSemibold
testWebhookBtn.Text = "Test Webhook"
testWebhookBtn.TextColor3 = Color3.fromRGB(230,230,255)
testWebhookBtn.TextSize = 13

local logFrame = Instance.new("Frame", main)
logFrame.Size = UDim2.new(1,-28,1,-130)
logFrame.Position = UDim2.new(0,14,0,60)
logFrame.BackgroundColor3 = Color3.fromRGB(8,8,14)
logFrame.BorderSizePixel = 0
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0,10)

local logScroll = Instance.new("ScrollingFrame", logFrame)
logScroll.Size = UDim2.new(1,-8,1,-8)
logScroll.Position = UDim2.new(0,4,0,4)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.CanvasSize = UDim2.new(0,0,0,0)
logScroll.ScrollBarThickness = 4
logScroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,140)

local logLayout = Instance.new("UIListLayout", logScroll)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0,2)

local bottomBar = Instance.new("Frame", main)
bottomBar.Size = UDim2.new(1,-28,0,40)
bottomBar.Position = UDim2.new(0,14,1,-55)
bottomBar.BackgroundTransparency = 1

local macroNameBox = Instance.new("TextBox", bottomBar)
macroNameBox.Size = UDim2.new(0.32,0,1,0)
macroNameBox.BackgroundColor3 = Color3.fromRGB(18,18,30)
macroNameBox.BorderSizePixel = 0
Instance.new("UICorner", macroNameBox).CornerRadius = UDim.new(0,8)
macroNameBox.Font = Enum.Font.Gotham
macroNameBox.Text = "Macro name"
macroNameBox.TextColor3 = Color3.fromRGB(220,220,240)
macroNameBox.TextSize = 14
macroNameBox.ClearTextOnFocus = false

macroNameBox.Focused:Connect(function()
    if macroNameBox.Text == "Macro name" then
        macroNameBox.Text = ""
    end
end)

macroNameBox.FocusLost:Connect(function()
    if macroNameBox.Text == "" then
        macroNameBox.Text = "Macro name"
    end
end)

local selectMacroBtn = Instance.new("TextButton", bottomBar)
selectMacroBtn.Size = UDim2.new(0.32,0,1,0)
selectMacroBtn.Position = UDim2.new(0.34,0,0,0)
selectMacroBtn.BackgroundColor3 = Color3.fromRGB(18,18,30)
selectMacroBtn.BorderSizePixel = 0
Instance.new("UICorner", selectMacroBtn).CornerRadius = UDim.new(0,8)
selectMacroBtn.Font = Enum.Font.GothamSemibold
selectMacroBtn.Text = "Select macro"
selectMacroBtn.TextColor3 = Color3.fromRGB(220,220,240)
selectMacroBtn.TextSize = 14

local macroListFrame = Instance.new("Frame")
macroListFrame.Size = UDim2.new(0,220,0,180)
macroListFrame.Position = UDim2.new(0,0,1,4)
macroListFrame.BackgroundColor3 = Color3.fromRGB(18,18,30)
macroListFrame.BorderSizePixel = 0
macroListFrame.Visible = false
macroListFrame.ClipsDescendants = true
Instance.new("UICorner", macroListFrame).CornerRadius = UDim.new(0,8)
macroListFrame.Parent = selectMacroBtn

local macroListScroll = Instance.new("ScrollingFrame", macroListFrame)
macroListScroll.Size = UDim2.new(1,-8,1,-8)
macroListScroll.Position = UDim2.new(0,4,0,4)
macroListScroll.BackgroundTransparency = 1
macroListScroll.BorderSizePixel = 0
macroListScroll.ScrollBarThickness = 4
macroListScroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,140)
macroListScroll.CanvasSize = UDim2.new(0,0,0,0)

local macroListLayout = Instance.new("UIListLayout", macroListScroll)
macroListLayout.SortOrder = Enum.SortOrder.LayoutOrder
macroListLayout.Padding = UDim.new(0,2)

local LOG_COLORS = {
    system  = Color3.fromRGB(180, 200, 255),
    success = Color3.fromRGB(140, 255, 160),
    warn    = Color3.fromRGB(255, 220, 130),
    error   = Color3.fromRGB(255, 130, 130),
    skip    = Color3.fromRGB(255, 105, 180),
    place   = Color3.fromRGB(120, 255, 120),
    upgrade = Color3.fromRGB(100, 180, 255),
    ability = Color3.fromRGB(200, 120, 255),
}

local function AddLog(text, kind)
    kind = kind or "system"
    local color = LOG_COLORS[kind] or Color3.fromRGB(200,200,220)
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1,-4,0,16)
    line.BackgroundTransparency = 1
    line.Font = Enum.Font.Code
    line.TextSize = 13
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.TextColor3 = color
    local timeStr = os.date("%H:%M:%S")
    line.Text = "["..timeStr.."] "..text
    line.Parent = logScroll
    logScroll.CanvasSize = UDim2.new(0,0,0,logLayout.AbsoluteContentSize.Y + 4)
    logScroll.CanvasPosition = Vector2.new(0, math.max(0, logScroll.CanvasSize.Y.Offset - logScroll.AbsoluteWindowSize.Y))
    print("[TDS-LOG]", line.Text)
end

local function RefreshMacroList()
    pcall(function()
        for _, child in ipairs(macroListScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local macros = ListMacros()
        if #macros == 0 then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,-4,0,22)
            btn.BackgroundColor3 = Color3.fromRGB(30,30,50)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(200,200,220)
            btn.Text = "no saved macros"
            btn.Parent = macroListScroll
            macroListScroll.CanvasSize = UDim2.new(0,0,0,macroListLayout.AbsoluteContentSize.Y + 4)
            return
        end
        for _, name in ipairs(macros) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,-4,0,22)
            btn.BackgroundColor3 = Color3.fromRGB(30,30,50)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(220,220,240)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = name
            btn.Parent = macroListScroll
            btn.MouseButton1Click:Connect(function()
                selectMacroBtn.Text = name
                macroListFrame.Visible = false
                AddLog("[SYSTEM] selected: "..name, "system")
                ShowToast("Selected: "..name)
            end)
        end
        macroListScroll.CanvasSize = UDim2.new(0,0,0,macroListLayout.AbsoluteContentSize.Y + 4)
    end)
end

selectMacroBtn.MouseButton1Click:Connect(function()
    RefreshMacroList()
    macroListFrame.Visible = not macroListFrame.Visible
end)

local function MakeButton(parent,text,relX,w)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(w or 0.1,0,1,0)
    b.Position = UDim2.new(relX,0,0,0)
    b.BackgroundColor3 = Color3.fromRGB(40,40,70)
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.Font = Enum.Font.GothamSemibold
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230,230,255)
    b.TextSize = 14
    return b
end

local recordBtn = MakeButton(bottomBar,"Rec",0.68,0.09)
local stopBtn   = MakeButton(bottomBar,"Stop",0.79,0.09)
local deleteBtn = MakeButton(bottomBar,"Del",0.90,0.09)
deleteBtn.TextColor3 = Color3.fromRGB(255,150,150)
deleteBtn.BackgroundColor3 = Color3.fromRGB(70,30,30)

local playBtn = Instance.new("TextButton", main)
playBtn.Size = UDim2.new(0,80,0,24)
playBtn.Position = UDim2.new(1,-94,0,54)
playBtn.BackgroundColor3 = Color3.fromRGB(40,40,70)
playBtn.BorderSizePixel = 0
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0,8)
playBtn.Font = Enum.Font.GothamSemibold
playBtn.Text = "Play"
playBtn.TextColor3 = Color3.fromRGB(230,230,255)
playBtn.TextSize = 14

local function AddAction(action)
    if not isRecording then return end
    action.t = tick() - macroStartTime
    table.insert(macro, action)
end

local function SaveCurrentMacroSafe()
    if #macro == 0 then
        AddLog("[WARNING] no actions to save", "warn")
        ShowToast("No actions to save")
        return
    end
    if not writefile or not isfile then
        ShowToast("writefile/isfile not available")
        return
    end
    EnsureMacroFolder()
    local fileName = "Zuev Hub/"..macroName..".json"
    if isfile(fileName) then
        AddLog("[WARNING] macro already exists: "..macroName, "warn")
        ShowToast("Macro already exists")
        return
    end
    local ok, err = pcall(function()
        writefile(fileName, HttpService:JSONEncode(macro))
    end)
    if ok then
        AddLog("[SUCCESS] macro saved: "..fileName, "success")
        ShowToast("Saved: "..macroName)
        selectMacroBtn.Text = macroName
    else
        AddLog("[ERROR] failed to save macro: "..tostring(err), "error")
        ShowToast("Save error, see F9")
    end
end

recordBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        ShowToast("Cannot record while playing")
        return
    end
    if GameState ~= "GAME" then
        ShowToast("Must be in game to record")
        return
    end
    macro = {}
    macroStartTime = tick()
    isRecording = true
    if macroNameBox.Text == "" or macroNameBox.Text == "Macro name" then
        macroName = "macro_"..os.time()
    else
        macroName = macroNameBox.Text
    end
    TowerLevels = {}
    TowerInfo = {}
    ShowToast("Recording: "..macroName)
    ResetStats()
end)

stopBtn.MouseButton1Click:Connect(function()
    if isRecording then
        isRecording = false
        AddLog("[SYSTEM] macro recording stopped ("..#macro.." actions)", "system")
        ShowToast("Recording stopped ("..#macro.." actions)")
        SaveCurrentMacroSafe()
    elseif isPlaying then
        isPlaying = false
        AddLog("[SYSTEM] macro play stopped", "system")
        ShowToast("Playback stopped")
    end
end)

deleteBtn.MouseButton1Click:Connect(function()
    local name = selectMacroBtn.Text
    if name=="" or name=="Select macro" then
        ShowToast("Select macro first")
        return
    end
    pcall(function()
        if not delfile or not isfile then
            ShowToast("delfile/isfile not available")
            return
        end
        EnsureMacroFolder()
        local fileName = "Zuev Hub/"..name..".json"
        if not isfile(fileName) then
            ShowToast("Macro not found")
            return
        end
        delfile(fileName)
        ShowToast("Macro deleted: "..name)
        selectMacroBtn.Text = "Select macro"
    end)
end)

local function IsActionSuccessful(result)
    local ok, isModel = pcall(function() return result:IsA("Model") end)
    if ok and isModel then return true end
    if type(result) == "table" and result.Success == true then return true end
    if result == true then return true end
    if type(result) == "number" then return true end
    return false
end

local function FindTowerAtPosition(pos)
    local closest, minDist = nil, 10
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local rep = obj:FindFirstChild("TowerReplicator")
                if rep and rep:GetAttribute("OwnerId") == player.UserId then
                    local pivot = obj:GetPivot()
                    if pivot then
                        local d = (pivot.Position - pos).Magnitude
                        if d < minDist then
                            minDist = d
                            closest = obj
                        end
                    end
                end
            end
        end
    end)
    return closest
end

local function DoPlaceTower(TName, TPos)
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops","Plаce",{Rotation=CFrame.new(),Position=TPos},TName)
        end)
        if ok and IsActionSuccessful(res) then UpdateStats() return true end
        task.wait(0.25)
    end
end

local function DoUpgradeTower(TObj, PathId)
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops","Upgrade","Set",{Troop=TObj,Path=PathId or 1})
        end)
        if ok and IsActionSuccessful(res) then UpdateStats() return true end
        task.wait(0.25)
    end
end

local function DoSellTower(TObj)
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops","Sell",{Troop=TObj})
        end)
        if ok and IsActionSuccessful(res) then UpdateStats() return true end
        task.wait(0.25)
    end
end

local function DoActivateAbility(TObj, AbName, AbData)
    AbData = AbData or {}
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops","Abilities","Activate",{Troop=TObj,Name=AbName,Data=AbData})
        end)
        if ok and IsActionSuccessful(res) then return true end
        task.wait(0.25)
    end
end

local function LoadMacro(name)
    local result
    pcall(function()
        if not readfile or not isfile then
            ShowToast("readfile/isfile not available")
            return
        end
        EnsureMacroFolder()
        local fileName = "Zuev Hub/"..name..".json"
        if not isfile(fileName) then
            ShowToast("Macro file not found")
            return
        end
        local json = readfile(fileName)
        local data = HttpService:JSONDecode(json)
        if type(data) == "table" then
            result = data
        end
    end)
    return result
end

-- // ПРОСТОЙ WEBHOOK (для Game Left / fallback)
local function SendWebhook(title, description, color)
    if WEBHOOK_URL == "" then return end
    pcall(function()
        local payload = {
            embeds = {{
                title = title,
                description = description,
                color = color or 5763719
            }}
        }
        SendRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- // ХУК __namecall (РЕКОРД) — та же логика place/upgrade/sell/ability с кэшем уровня
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt,false)

mt.__namecall = function(self,...)
    local method = getnamecallmethod()
    local args = {...}
    local results = {old(self,...)}

    if isRecording and (method=="FireServer" or method=="InvokeServer") then
        local a1,a2,a3,a4 = args[1],args[2],args[3],args[4]

        if method=="InvokeServer" and a1=="Voting" and a2=="Skip" then
            AddAction({type="skip"})
            AddLog("wave skipped","skip")
        end

        if method=="InvokeServer" and a1=="Troops" and (a2=="Place" or a2=="Plаce") then
            local pos = a3 and a3.Position
            local unitName = a4
            if typeof(pos)=="Vector3" and type(unitName)=="string" then
                local result = results[1]
                local isModel = false
                local ok = pcall(function() isModel = result:IsA("Model") end)
                if ok and isModel then
                    local tower = result
                    local rep = tower:FindFirstChild("TowerReplicator")
                    local attrName = rep and rep:GetAttribute("Name")
                    local towerName = (typeof(attrName)=="string" and attrName ~= "" and attrName) or tower.Name
                    if typeof(towerName) ~= "string" or towerName == "" then towerName = "Unknown" end

                    local pivot = tower:GetPivot()
                    local tpos = pivot and pivot.Position or pos

                    TowerInfo[tower] = {
                        name  = towerName,
                        pos   = tpos,
                        level = 0
                    }

                    AddAction({
                        type = "place",
                        unit = towerName,
                        x = tpos.X,
                        y = tpos.Y,
                        z = tpos.Z
                    })
                    AddLog("placed "..towerName,"place")
                    task.spawn(function() task.wait(0.1) UpdateStats() end)
                else
                    AddLog("[SKIP] failed to place "..unitName.." (not enough resources?)","warn")
                end
            end
        end

        if method=="InvokeServer" and a1=="Troops" and a2=="Upgrade" then
            if IsActionSuccessful(results[1]) then
                local tower
                if type(a3)=="table" and a3.Troop then
                    tower = a3.Troop
                elseif type(a4)=="table" and a4.Troop then
                    tower = a4.Troop
                elseif typeof(a3)=="Instance" and a3:IsA("Model") then
                    tower = a3
                end

                if tower and tower:IsA("Model") then
                    local pivot = tower:GetPivot()
                    local pos = pivot and pivot.Position
                    if pos then
                        local rep = tower:FindFirstChild("TowerReplicator")
                        local attrName = rep and rep:GetAttribute("Name")
                        local towerName = (typeof(attrName)=="string" and attrName ~= "" and attrName) or tower.Name
                        if typeof(towerName) ~= "string" or towerName == "" then towerName = "Unknown" end

                        local oldLevel = 0
                        if TowerInfo[tower] then
                            oldLevel = TowerInfo[tower].level or 0
                        end
                        local newLevel = oldLevel + 1

                        TowerInfo[tower] = {
                            name  = towerName,
                            pos   = pos,
                            level = newLevel
                        }

                        local towerKey = string.format("%s_%.1f_%.1f_%.1f", towerName, pos.X, pos.Y, pos.Z)
                        TowerLevels[towerKey] = newLevel

                        AddAction({
                            type = "upgrade",
                            x = pos.X,
                            y = pos.Y,
                            z = pos.Z,
                            towerName = towerName,
                            oldLevel = oldLevel,
                            newLevel = newLevel
                        })

                        AddLog(string.format("[RECORD] upgrade %s %d -> %d",
                            towerName,
                            oldLevel,
                            newLevel
                        ), "upgrade")
                    else
                        AddAction({type="upgrade"})
                        AddLog("[RECORD] upgrade (no position)","upgrade")
                    end
                else
                    AddAction({type="upgrade"})
                    AddLog("[RECORD] upgrade (no tower instance)","upgrade")
                end
                UpdateStats()
            else
                AddLog("[SKIP] failed to upgrade","warn")
            end
        end

        if method=="InvokeServer" and a1=="Troops" and a2=="Sell" then
            if IsActionSuccessful(results[1]) then
                local tower = a3 and a3.Troop
                if tower and tower:IsA("Model") then
                    local info = TowerInfo[tower]
                    local towerName, pos
                    local level = 0

                    if info then
                        towerName = info.name
                        pos       = info.pos
                        level     = info.level or 0
                    else
                        local pivot = tower:GetPivot()
                        pos = pivot and pivot.Position
                        local rep = tower:FindFirstChild("TowerReplicator")
                        local attrName = rep and rep:GetAttribute("Name")
                        towerName = (typeof(attrName)=="string" and attrName ~= "" and attrName) or tower.Name
                    end

                    if typeof(towerName) ~= "string" or towerName == "" then
                        towerName = "Unknown"
                    end

                    if pos then
                        AddAction({
                            type = "sell",
                            x = pos.X,
                            y = pos.Y,
                            z = pos.Z,
                            towerName = towerName,
                            level = level
                        })
                        AddLog(string.format("[RECORD] tower sold: %s [lvl %d]", towerName, level),"success")
                    else
                        AddAction({type="sell", towerName = towerName, level = level})
                        AddLog(string.format("[RECORD] sell (no position, %s [lvl %d])", towerName, level),"success")
                    end

                    TowerInfo[tower] = nil
                else
                    AddAction({type="sell"})
                    AddLog("[RECORD] sell (no tower instance)","success")
                end
                UpdateStats()
            else
                AddLog("[SKIP] failed to sell","warn")
            end
        end

        if method=="InvokeServer" and a1=="Troops" and a2=="Abilities" and a3=="Activate" then
            if IsActionSuccessful(results[1]) then
                local tower = a4 and a4.Troop
                local abilityName = a4 and a4.Name
                local abilityData = a4 and a4.Data

                if tower and tower:IsA("Model") and abilityName then
                    local pos = tower:GetPivot().Position
                    local rep = tower:FindFirstChild("TowerReplicator")
                    local tName = rep and rep:GetAttribute("Name") or ""

                    if tName == "Hacker" and abilityName == "Hologram Tower" and type(abilityData) == "table" then
                        local targetPos = abilityData.towerPosition
                        local cloneTower = abilityData.towerToClone

                        if targetPos and cloneTower and cloneTower:IsA("Model") then
                            local cloneRep = cloneTower:FindFirstChild("TowerReplicator")
                            local cloneName = cloneRep and cloneRep:GetAttribute("Name") or ""

                            AddAction({
                                type = "hacker_clone",
                                sourceX = pos.X,
                                sourceY = pos.Y,
                                sourceZ = pos.Z,
                                targetX = targetPos.X,
                                targetY = targetPos.Y,
                                targetZ = targetPos.Z,
                                cloneName = cloneName
                            })
                            AddLog("[RECORD] hacker clone ("..cloneName..")","ability")
                        else
                            AddLog("[SKIP] hacker ability data missing towerToClone/position","warn")
                        end
                    else
                        local dataCopy = {}
                        if abilityData and type(abilityData)=="table" then
                            for k,v in pairs(abilityData) do
                                if typeof(v)=="CFrame" then
                                    local comps = {v:GetComponents()}
                                    dataCopy[k]={__cf=true,v=comps}
                                else
                                    dataCopy[k]=v
                                end
                            end
                        end

                        AddAction({
                            type = "ability_all",
                            towerName = tName,
                            abilityName = abilityName,
                            x = pos.X,
                            y = pos.Y,
                            z = pos.Z,
                            data = dataCopy
                        })
                        AddLog("[RECORD] ability: "..abilityName.." ("..tName..")","ability")
                    end
                else
                    AddAction({type="ability_all",name=abilityName or "Ability"})
                    AddLog("[RECORD] ability (no position)","ability")
                end
            else
                AddLog("[SKIP] failed to activate ability","warn")
            end
        end
    end

    return table.unpack(results)
end

setreadonly(mt,true)

-- // ПРОИГРЫВАНИЕ МАКРО
local function PlayMacro(name)
    if isRecording then
        ShowToast("Stop recording first")
        return
    end
    if isPlaying then
        ShowToast("Already playing")
        return
    end
    if GameState~="GAME" then
        ShowToast("Must be in game")
        return
    end
    local data = LoadMacro(name)
    if not data or #data==0 then
        ShowToast("Macro is empty")
        return
    end
    isPlaying = true
    ResetStats()
    ShowToast("Playing: "..name)

    task.spawn(function()
        local start = tick()
        local okCnt, failCnt = 0,0
        for _,act in ipairs(data) do
            if not isPlaying then break end
            local waitTime = (start + (act.t or 0)) - tick()
            if waitTime>0 then task.wait(waitTime) end
            local ttype = act.type

            if ttype=="skip" then
                pcall(function() RemoteFunction:InvokeServer("Voting","Skip") end)
                AddLog("wave skipped","skip")
                okCnt+=1

            elseif ttype=="place" then
                local unit,x,y,z = act.unit,act.x,act.y,act.z
                if type(unit)=="string" and type(x)=="number" then
                    if DoPlaceTower(unit,Vector3.new(x,y,z)) then
                        AddLog("placed "..unit,"place")
                        okCnt+=1
                    else failCnt+=1 end
                end

            elseif ttype == "upgrade" then
                local x, y, z = act.x, act.y, act.z
                local towerName = act.towerName or "Unknown"
                local oldLevel = tonumber(act.oldLevel) or 0
                local newLevel = tonumber(act.newLevel) or (oldLevel + 1)

                if type(x) == "number" then
                    local tower = FindTowerAtPosition(Vector3.new(x, y, z))
                    if tower then
                        DoUpgradeTower(tower, 1)
                        AddLog(string.format("[SUCCESS] upgrade %s %d -> %d",
                            towerName,
                            oldLevel,
                            newLevel
                        ), "upgrade")
                        okCnt += 1
                    else
                        AddLog(string.format(
                            "[WARNING] tower not found for upgrade (%s)",
                            towerName
                        ), "warn")
                        failCnt += 1
                    end
                end

            elseif ttype=="sell" then
                local x,y,z = act.x,act.y,act.z
                local towerName = act.towerName or "Unknown"
                local level = tonumber(act.level) or 0

                if type(x)=="number" then
                    local tower = FindTowerAtPosition(Vector3.new(x,y,z))
                    if tower then
                        DoSellTower(tower)
                        AddLog(string.format("[SUCCESS] sold %s [lvl %d]", towerName, level), "success")
                        okCnt += 1
                    else
                        AddLog(string.format(
                            "[WARNING] tower not found for sell (%s [lvl %d])",
                            towerName, level
                        ), "warn")
                        failCnt += 1
                    end
                end

            elseif ttype=="hacker_clone" then
                local sourceX,sourceY,sourceZ = act.sourceX,act.sourceY,act.sourceZ
                local targetX,targetY,targetZ = act.targetX,act.targetY,act.targetZ
                local cloneName = act.cloneName

                if sourceX and sourceY and sourceZ and targetX and targetY and targetZ and cloneName then
                    local sourcePos = Vector3.new(sourceX,sourceY,sourceZ)
                    local hackerTower = FindTowerAtPosition(sourcePos)

                    if hackerTower then
                        local towerToClone = nil
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("Model") then
                                local rep = obj:FindFirstChild("TowerReplicator")
                                if rep
                                   and rep:GetAttribute("Name") == cloneName
                                   and rep:GetAttribute("OwnerId") == player.UserId then
                                    towerToClone = obj
                                    break
                                end
                            end
                        end

                        if towerToClone then
                            local args = {
                                Troop = hackerTower,
                                Name = "Hologram Tower",
                                Data = {
                                    towerToClone = towerToClone,
                                    towerPosition = Vector3.new(targetX,targetY,targetZ)
                                }
                            }

                            local ok,res = pcall(function()
                                return RemoteFunction:InvokeServer("Troops","Abilities","Activate",args)
                            end)

                            if ok and IsActionSuccessful(res) then
                                AddLog("[SUCCESS] hacker clone executed ("..cloneName..")","ability")
                                okCnt += 1
                            else
                                AddLog("[ERROR] hacker clone failed","error")
                                failCnt += 1
                            end
                        else
                            AddLog("[WARNING] tower to clone not found: "..cloneName,"warn")
                            failCnt += 1
                        end
                    else
                        AddLog("[WARNING] hacker tower not found","warn")
                        failCnt += 1
                    end
                else
                    AddLog("[WARNING] hacker clone missing data","warn")
                    failCnt += 1
                end

            elseif ttype=="ability_all" then
                local abilityName,x,y,z = act.abilityName,act.x,act.y,act.z
                local savedData = act.data or {}
                if abilityName and type(x)=="number" then
                    local tower = FindTowerAtPosition(Vector3.new(x,y,z))
                    if tower then
                        local finalData = {}
                        for k,v in pairs(savedData) do
                            if type(v)=="table" and v.__cf and type(v.v)=="table" then
                                local c=v.v
                                finalData[k]=CFrame.new(
                                    c[1],c[2],c[3],
                                    c[4],c[5],c[6],
                                    c[7],c[8],c[9],
                                    c[10],c[11],c[12]
                                )
                            else finalData[k]=v end
                        end
                        if DoActivateAbility(tower,abilityName,finalData) then
                            AddLog("[SUCCESS] ability used: "..abilityName,"ability")
                            okCnt+=1
                        else failCnt+=1 end
                    else
                        AddLog("[WARNING] tower not found for ability","warn")
                        failCnt+=1
                    end
                end
            end
        end
        isPlaying = false
        UpdateStats()
        local text = string.format("✅ %d | ❌ %d", okCnt, failCnt)
        AddLog("[SYSTEM] macro play finished - "..text,"system")
        ShowToast("Macro finished")
    end)
end

playBtn.MouseButton1Click:Connect(function()
    local name = selectMacroBtn.Text
    if name == "" or name == "Select macro" or not name then
        name = macroName
    end
    if not name or name == "" then
        ShowToast("No macro selected")
        return
    end
    PlayMacro(name)
end)

testWebhookBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        ShowToast("Webhook URL is empty")
        return
    end
    SendWebhook("✅ Test Webhook","Webhook is working correctly!",5763719)
    ShowToast("Test webhook sent")
end)

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.F5 then
        recordBtn:Activate()
    elseif input.KeyCode==Enum.KeyCode.F6 then
        stopBtn:Activate()
    end
end)

-- // ДЕТАЛЬНЫЙ WEBHOOK ПО ЭКРАНУ НАГРАД

local ItemNames = {
    ["17447507910"] = "Timescale Ticket(s)",
    ["17438486690"] = "Range Flag(s)",
    ["17438486138"] = "Damage Flag(s)",
    ["17438487774"] = "Cooldown Flag(s)",
    ["17429537022"] = "Blizzard(s)",
    ["17448596749"] = "Napalm Strike(s)",
    ["18493073533"] = "Spin Ticket(s)",
    ["17429548305"] = "Supply Drop(s)",
    ["18443277308"] = "Low Grade Consumable Crate(s)",
    ["136180382135048"] = "Santa Radio(s)",
    ["18443277106"] = "Mid Grade Consumable Crate(s)",
    ["18443277591"] = "High Grade Consumable Crate(s)",
    ["132155797622156"] = "Christmas Tree(s)",
    ["124065875200929"] = "Fruit Cake(s)",
    ["17429541513"] = "Barricade(s)",
    ["110415073436604"] = "Holy Hand Grenade(s)",
    ["17429533728"] = "Frag Grenade(s)",
    ["17437703262"] = "Molotov(s)",
    ["139414922355803"] = "Present Clusters(s)"
}

local function GetAllRewards()
    local results = {
        Coins = 0,
        Gems = 0,
        XP = 0,
        Wave = 0,
        Time = "00:00",
        Status = "UNKNOWN",
        Others = {}
    }

    local UiRoot = playerGui:FindFirstChild("ReactGameNewRewards")
    if not UiRoot or not UiRoot.Enabled then return results end

    local MainFrame = UiRoot:FindFirstChild("Frame")
    if not MainFrame then return results end

    local GameOver = MainFrame:FindFirstChild("gameOver")
    if not GameOver or not GameOver.Visible then return results end

    local RewardsScreen = GameOver:FindFirstChild("RewardsScreen")
    if not RewardsScreen then return results end

    local GameStats = RewardsScreen:FindFirstChild("gameStats")
    local StatsList = GameStats and GameStats:FindFirstChild("stats")

    if StatsList then
        for _, frame in ipairs(StatsList:GetChildren()) do
            local l1 = frame:FindFirstChild("textLabel")
            local l2 = frame:FindFirstChild("textLabel2")
            if l1 and l2 and l1.Text:find("Time Completed:") then
                results.Time = l2.Text
                break
            end
        end
    end

    local TopBanner = RewardsScreen:FindFirstChild("RewardBanner")
    if TopBanner and TopBanner:FindFirstChild("textLabel") then
        local txt = TopBanner.textLabel.Text:upper()
        results.Status = txt:find("TRIUMPH") and "WIN" or (txt:find("LOST") and "LOSS" or "UNKNOWN")
    end

    local label = playerGui:FindFirstChild("ReactGameTopGameDisplay")
        and playerGui.ReactGameTopGameDisplay:FindFirstChild("Frame")
        and playerGui.ReactGameTopGameDisplay.Frame:FindFirstChild("wave")
        and playerGui.ReactGameTopGameDisplay.Frame.wave:FindFirstChild("container")
        and playerGui.ReactGameTopGameDisplay.Frame.wave.container:FindFirstChild("value")

    if label then
        local WaveNum = label.Text:match("^(%d+)")
        if WaveNum then
            results.Wave = tonumber(WaveNum) or 0
        end
    end

    local SectionRewards = RewardsScreen:FindFirstChild("RewardsSection")
    if SectionRewards then
        for _, item in ipairs(SectionRewards:GetChildren()) do
            if tonumber(item.Name) then
                local IconId = "0"
                local img = item:FindFirstChildWhichIsA("ImageLabel", true)
                if img then
                    IconId = img.Image:match("%d+") or "0"
                end

                for _, child in ipairs(item:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local text = child.Text
                        local amt = tonumber(text:match("(%d+)")) or 0

                        if text:find("Coins") then
                            results.Coins = amt
                        elseif text:find("Gems") then
                            results.Gems = amt
                        elseif text:find("XP") then
                            results.XP = amt
                        elseif text:lower():find("x%d+") then
                            local displayName = ItemNames[IconId] or "Unknown Item (" .. IconId .. ")"
                            table.insert(results.Others, {Amount = text:match("x%d+"), Name = displayName})
                        end
                    end
                end
            end
        end
    end

    return results
end

local function SendDetailedWebhook(match)
    if WEBHOOK_URL == "" then return end

    Stats.TotalCoins = Stats.TotalCoins + match.Coins
    Stats.TotalGems = Stats.TotalGems + match.Gems

    local bonusLines = {}
    if #match.Others > 0 then
        for _, res in ipairs(match.Others) do
            table.insert(bonusLines, string.format("🎁 **%s %s**", res.Amount, res.Name))
        end
    end
    local BonusString = (#bonusLines > 0) and table.concat(bonusLines, "\n") or "_No bonus rewards found._"

    local PostData = {
        username = "Zuev Hub TDS",
        embeds = {{
            title = (match.Status == "WIN" and "🏆 TRIUMPH" or "💀 DEFEAT"),
            color = (match.Status == "WIN" and 0x2ecc71 or 0xe74c3c),
            description = string.format(
                "### 📋 Match Overview\n> **Status:** `%s`\n> **Time:** `%s`\n> **Wave:** `%s`",
                match.Status,
                match.Time,
                tostring(match.Wave)
            ),
            fields = {
                {
                    name = "✨ Rewards",
                    value = string.format(
                        "```ansi\nCoins: +%d\nGems:  +%d\nXP:    +%d```",
                        match.Coins,
                        match.Gems,
                        match.XP
                    ),
                    inline = false
                },
                {
                    name = "🎁 Bonus Items",
                    value = BonusString,
                    inline = true
                },
                {
                    name = "📊 Session Totals",
                    value = string.format(
                        "```py\nCoins: %d\nGems:  %d```",
                        Stats.TotalCoins,
                        Stats.TotalGems
                    ),
                    inline = true
                }
            },
            footer = { text = "Logged for " .. player.Name .. " • Zuev Hub" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    pcall(function()
        SendRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(PostData)
        })
        print("[SYSTEM] Game stats sent to webhook")
    end)
end


local lastGameState = GameState
local gameEndProcessed = false

local function CheckGameEnd()
    UpdateGameState()

    if GameState == "REWARDS" and not gameEndProcessed then
        print("[DEBUG] Game ended! Rewards screen detected")
        gameEndProcessed = true

        task.wait(1)

        local match = GetAllRewards()

        if match and (match.Coins > 0 or match.Gems > 0 or match.XP > 0) then
            print("[DEBUG] Found rewards - Coins: "..match.Coins..", Gems: "..match.Gems)
            SendDetailedWebhook(match)
        else
            print("[DEBUG] No rewards found in screen, using stats")
            UpdateStats()
            if WEBHOOK_URL ~= "" and (Stats.EarnedCoins > 0 or Stats.EarnedGems > 0) then
                local description = string.format(
                    "+%d coins (Total: %d)\\n+%d gems (Total: %d)",
                    Stats.EarnedCoins, Stats.Coins,
                    Stats.EarnedGems, Stats.Gems
                )
                SendWebhook("📊 Game Finished", description, 5763719)
            end
        end
    end

    if GameState == "LOBBY" and lastGameState == "REWARDS" then
        ResetStats()
        gameEndProcessed = false
        print("[DEBUG] Returned to lobby, stats reset")
    end

    if GameState == "LOBBY" and lastGameState ~= "LOBBY" then
        gameEndProcessed = false
    end

    lastGameState = GameState
end

task.spawn(function()
    print("[SYSTEM] Game end detector started")
    while true do
        pcall(CheckGameEnd)
        task.wait(0.5)
    end
end)

player.OnTeleport:Connect(function()
    UpdateStats()
    if WEBHOOK_URL ~= "" and (Stats.EarnedCoins > 0 or Stats.EarnedGems > 0) and not gameEndProcessed then
        local description = string.format(
            "+%d coins (Total: %d)\\n+%d gems (Total: %d)",
            Stats.EarnedCoins, Stats.Coins,
            Stats.EarnedGems, Stats.Gems
        )
        SendWebhook("📊 Game Left", description, 5763719)
    end
end)

UpdateGameState()
ResetStats()
print("[SYSTEM] Macro + webhook loaded")
