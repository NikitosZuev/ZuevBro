local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction", 30)
local playerGui = player:WaitForChild("PlayerGui")

if not RemoteFunction then
    print("[ERROR] RemoteFunction not found!")
    return
end

local SETTINGS_FILE = "ZuevHub_Settings.json"
local DefaultSettings = {
    WebhookURL = "",
    AutoReconnect = true,
    AntiAfk = true
}

local Settings = {}
local function LoadSettings()
    local success = pcall(function()
        if isfile and readfile then
            if isfile(SETTINGS_FILE) then
                local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
                if type(data) == "table" then
                    Settings = data
                    return true
                end
            end
        end
        return false
    end)
    
    if not success or not next(Settings) then
        Settings = DefaultSettings
    end
end

local function SaveSettings()
    pcall(function()
        if writefile then
            writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings))
        end
    end)
end

LoadSettings()
local WEBHOOK_URL = Settings.WebhookURL or ""

local GameState = "UNKNOWN"
local function UpdateGameState()
    local rewardsGui = playerGui:FindFirstChild("ReactGameNewRewards")
    if rewardsGui and rewardsGui.Enabled then
        local frame = rewardsGui:FindFirstChild("Frame")
        local gameOver = frame and frame:FindFirstChild("gameOver")
        if gameOver and gameOver.Visible then
            GameState = "REWARDS"
            return
        end
    end
    
    if playerGui and playerGui:FindFirstChild("ReactLobbyHud") then
        GameState = "LOBBY"
        return
    end
    
    if playerGui and playerGui:FindFirstChild("ReactUniversalHotbar") then
        GameState = "GAME"
        return
    end
    
    GameState = "UNKNOWN"
end

task.spawn(function()
    while true do
        pcall(UpdateGameState)
        task.wait(1)
    end
end)

local function StartAntiAfk()
    if not Settings.AntiAfk then return end
    
    task.spawn(function()
        while Settings.AntiAfk do
            task.wait(60)
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end)
    
    pcall(function()
        if getconnections then
            for _, connection in pairs(getconnections(player.Idled)) do
                pcall(function()
                    connection:Disable()
                end)
            end
        end
    end)
    
    print("[SYSTEM] Anti-AFK enabled")
end

pcall(StartAntiAfk)

local function StartAutoReconnect()
    if not Settings.AutoReconnect then return end
    
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        local overlay = coreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
        
        overlay.ChildAdded:Connect(function(child)
            if child.Name == 'ErrorPrompt' then
                print("[SYSTEM] Error detected, reconnecting...")
                task.wait(2)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, player)
                end)
            end
        end)
    end)
end

pcall(StartAutoReconnect)

local Stats = {
    Coins = 0,
    Gems = 0,
    StartCoins = 0,
    StartGems = 0,
    EarnedCoins = 0,
    EarnedGems = 0,
    SessionStart = tick(),
    TotalCoins = 0,
    TotalGems = 0
}

local function UpdateStats()
    local success = pcall(function()
        local coinsObj = player:FindFirstChild("Coins")
        local gemsObj = player:FindFirstChild("Gems")
        
        if coinsObj then
            Stats.Coins = coinsObj.Value
        end
        if gemsObj then
            Stats.Gems = gemsObj.Value
        end
        
        Stats.EarnedCoins = Stats.Coins - Stats.StartCoins
        Stats.EarnedGems = Stats.Gems - Stats.StartGems
    end)
    
    if not success then
        print("[DEBUG] Failed to update stats")
    end
end

local function TrackStats()
    pcall(function()
        local coinsObj = player:FindFirstChild("Coins")
        local gemsObj = player:FindFirstChild("Gems")
        
        if coinsObj then
            coinsObj.Changed:Connect(function()
                UpdateStats()
            end)
        end
        if gemsObj then
            gemsObj.Changed:Connect(function()
                UpdateStats()
            end)
        end
    end)
end

local function ResetStats()
    Stats.TotalCoins = Stats.TotalCoins + Stats.EarnedCoins
    Stats.TotalGems = Stats.TotalGems + Stats.EarnedGems
    
    UpdateStats()
    Stats.StartCoins = Stats.Coins
    Stats.StartGems = Stats.Gems
    Stats.SessionStart = tick()
    
    print("[DEBUG] Stats reset - StartCoins:", Stats.StartCoins, "StartGems:", Stats.StartGems)
end

pcall(TrackStats)
pcall(UpdateStats)
pcall(ResetStats)

local isRecording = false
local isPlaying = false
local macro = {}
local macroStartTime = 0
local macroName = "macro_1"

local function AddLog(text, kind) end

local function EnsureMacroFolder()
    pcall(function()
        if isfolder and not isfolder("Zuev Hub") then
            makefolder("Zuev Hub")
        end
    end)
end

local function ListMacros()
    local list = {}
    pcall(function()
        if not listfiles then return list end
        EnsureMacroFolder()
        local files = listfiles("Zuev Hub")
        for _, path in ipairs(files) do
            if path:sub(-5) == ".json" then
                local name = path:match("Zuev Hub[\\\\/](.+)%.json")
                if name then
                    table.insert(list, name)
                end
            end
        end
        table.sort(list)
    end)
    return list
end

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "MacroZuevHub_TDSLog"
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
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.15
    frame.Parent = toastGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(230, 230, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = msg

    frame.BackgroundTransparency = 1
    label.TextTransparency = 1
    frame.Position = UDim2.new(0, 0, 0, 10)

    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(frame, ti, {
        BackgroundTransparency = 0.15,
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    TweenService:Create(label, ti, { TextTransparency = 0 }):Play()

    task.delay(3, function()
        local ti2 = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t1 = TweenService:Create(frame, ti2, {BackgroundTransparency = 1})
        local t2 = TweenService:Create(label, ti2, {TextTransparency = 1})
        t1:Play()
        t2:Play()
        t2.Completed:Wait()
        frame:Destroy()
    end)
end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 600, 0, 360)
main.Position = UDim2.new(0.5, -300, 0.4, -180)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

do
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
title.Size = UDim2.new(0.6, -10, 0.6, 0)
title.Position = UDim2.new(0,10,0,2)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.Text = "MACRO RECORDER"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 18
local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(0.6, -10, 0.4, 0)
subtitle.Position = UDim2.new(0,10,0.6,0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "by zuev and temka"
subtitle.TextColor3 = Color3.fromRGB(170,170,200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextSize = 13


local webhookBox = Instance.new("TextBox", topBar)
webhookBox.Size = UDim2.new(0.5, -10, 0.6, 0)
webhookBox.Position = UDim2.new(0.3, 5, 0.2, 0)
webhookBox.BackgroundColor3 = Color3.fromRGB(22, 22, 40)
webhookBox.BorderSizePixel = 0
Instance.new("UICorner", webhookBox).CornerRadius = UDim.new(0, 6)
webhookBox.Font = Enum.Font.Gotham
webhookBox.PlaceholderText = "Discord Webhook URL"
webhookBox.Text = WEBHOOK_URL
webhookBox.TextColor3 = Color3.fromRGB(220,220,240)
webhookBox.TextSize = 13
webhookBox.ClearTextOnFocus = false
webhookBox.ClipsDescendants = true
webhookBox.TextTruncate = Enum.TextTruncate.AtEnd

webhookBox.FocusLost:Connect(function()
    if webhookBox.Text ~= "" then
        Settings.WebhookURL = webhookBox.Text
        WEBHOOK_URL = webhookBox.Text
        SaveSettings()
        AddLog("[SYSTEM] webhook url saved", "system")
        ShowToast("Webhook saved")
    end
end)

local testWebhookBtn = Instance.new("TextButton", topBar)
testWebhookBtn.Size = UDim2.new(0, 115, 0.6, 0)
testWebhookBtn.Position = UDim2.new(1, -125, 0.2, 0)
testWebhookBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
testWebhookBtn.BorderSizePixel = 0
Instance.new("UICorner", testWebhookBtn).CornerRadius = UDim.new(0, 8)
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
macroNameBox.Position = UDim2.new(0,0,0,0)
macroNameBox.BackgroundColor3 = Color3.fromRGB(18,18,30)
macroNameBox.BorderSizePixel = 0
Instance.new("UICorner", macroNameBox).CornerRadius = UDim.new(0,8)
macroNameBox.Font = Enum.Font.Gotham
macroNameBox.PlaceholderText = "macro name"
macroNameBox.Text = ""
macroNameBox.TextColor3 = Color3.fromRGB(220,220,240)
macroNameBox.TextSize = 14
macroNameBox.ClearTextOnFocus = false

local savedMacroBox = Instance.new("TextBox", bottomBar)
savedMacroBox.Size = UDim2.new(0.32,0,1,0)
savedMacroBox.Position = UDim2.new(0.34,0,0,0)
savedMacroBox.BackgroundColor3 = Color3.fromRGB(18,18,30)
savedMacroBox.BorderSizePixel = 0
Instance.new("UICorner", savedMacroBox).CornerRadius = UDim.new(0,8)
savedMacroBox.Font = Enum.Font.Gotham
savedMacroBox.PlaceholderText = "click to choose macro"
savedMacroBox.Text = ""
savedMacroBox.TextColor3 = Color3.fromRGB(220,220,240)
savedMacroBox.TextSize = 14
savedMacroBox.ClearTextOnFocus = false

local macroListFrame = Instance.new("Frame")
macroListFrame.Size = UDim2.new(0, 220, 0, 180)
macroListFrame.Position = UDim2.new(0, 0, 1, 4)
macroListFrame.BackgroundColor3 = Color3.fromRGB(18,18,30)
macroListFrame.BorderSizePixel = 0
macroListFrame.Visible = false
macroListFrame.ClipsDescendants = true
Instance.new("UICorner", macroListFrame).CornerRadius = UDim.new(0,8)
macroListFrame.Parent = savedMacroBox

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

local function RefreshMacroList()
    pcall(function()
        for _, child in ipairs(macroListScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
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
                savedMacroBox.Text = name
                macroListFrame.Visible = false
                AddLog("[SYSTEM] selected macro: "..name, "system")
                ShowToast("Selected macro: "..name)
            end)
        end

        macroListScroll.CanvasSize = UDim2.new(0,0,0,macroListLayout.AbsoluteContentSize.Y + 4)
    end)
end

local function MakeButton(parent, text, relX, widthScale)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(widthScale or 0.1,0,1,0)
    btn.Position = UDim2.new(relX,0,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,70)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(230,230,255)
    btn.TextSize = 14
    return btn
end

local recordBtn = MakeButton(bottomBar, "Rec", 0.68, 0.09)
local stopBtn   = MakeButton(bottomBar, "Stop", 0.79, 0.09)
local deleteBtn = MakeButton(bottomBar, "Del", 0.90, 0.09)
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

local function SendWebhook(title, description, color)
    if WEBHOOK_URL == "" then return end
    
    pcall(function()
        local payload = {
            ["embeds"] = {{
                ["title"] = title,
                ["description"] = description,
                ["color"] = color or 5763719,
                ["footer"] = {
                    ["text"] = "Zuev Hub • " .. os.date("%d.%m.%Y %H:%M")
                }
            }}
        }
        
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

testWebhookBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL == "" then
        AddLog("[SYSTEM] webhook url is empty", "warn")
        ShowToast("Webhook URL is empty")
        return
    end
    SendWebhook("✅ Test Webhook", "Webhook is working correctly!", 5763719)
    AddLog("[SYSTEM] test webhook sent", "system")
    ShowToast("Test webhook sent")
end)

AddLog = function(text, kind)
    kind = kind or "info"
    
    if not (isRecording or isPlaying) then
        print("[TDS-LOG]", text)
        return
    end
    
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
    logScroll.CanvasPosition = Vector2.new(
        0,
        math.max(0, logScroll.CanvasSize.Y.Offset - logScroll.AbsoluteWindowSize.Y)
    )
    
    print("[TDS-LOG]", line.Text)
end

AddLog("[SYSTEM] TDS logger + structured macro ready.", "system")
AddLog("[SYSTEM] GameState: "..GameState, "system")

savedMacroBox.Focused:Connect(function()
    RefreshMacroList()
    macroListFrame.Visible = true
end)

savedMacroBox.FocusLost:Connect(function()
    task.delay(0.15, function()
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            macroListFrame.Visible = false
        end
    end)
end)

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    local results = { old(self, ...) }

    if isRecording and (method == "FireServer" or method == "InvokeServer") then
        local a1, a2, a3, a4 = args[1], args[2], args[3], args[4]

        if method == "InvokeServer" and a1 == "Voting" and a2 == "Skip" then
            AddAction({ type = "skip" })
            AddLog("wave skipped", "skip")
        end
        
        if method == "InvokeServer" and a1 == "Troops" and (a2 == "Place" or a2 == "Plаce") then
            local pos = a3 and a3.Position
            local unitName = a4
            if typeof(pos) == "Vector3" and type(unitName) == "string" then
                local result = results[1]
                
                local isModel = false
                local modelSuccess = pcall(function() 
                    isModel = result:IsA("Model") 
                end)
                
                if modelSuccess and isModel then
                    AddAction({
                        type = "place",
                        unit = unitName,
                        x = pos.X,
                        y = pos.Y,
                        z = pos.Z
                    })
                    AddLog("[RECORD] tower placed: "..unitName, "place")
                    task.spawn(function()
                        task.wait(0.1)
                        UpdateStats()
                    end)
                else
                    AddLog("[SKIP] failed to place "..unitName.." (not enough resources?)", "warn")
                end
            end
        end

        if method == "InvokeServer" and a1 == "Troops" and a2 == "Upgrade" then
            if IsActionSuccessful(results[1]) then
                local tower = nil
                if type(a3) == "table" and a3.Troop then
                    tower = a3.Troop
                elseif type(a4) == "table" and a4.Troop then
                    tower = a4.Troop
                elseif a3 and typeof(a3) == "Instance" and a3:IsA("Model") then
                    tower = a3
                end

                if tower and tower:IsA("Model") then
                    local pos = tower:GetPivot().Position
                    AddAction({
                        type = "upgrade",
                        x = pos.X,
                        y = pos.Y,
                        z = pos.Z
                    })
                    AddLog("[RECORD] tower upgrade", "upgrade")
                else
                    AddAction({ type = "upgrade" })
                    AddLog("[RECORD] upgrade (no position)", "upgrade")
                end
                UpdateStats()
            else
                AddLog("[SKIP] failed to upgrade", "warn")
            end
        end

        if method == "InvokeServer" and a1 == "Troops" and a2 == "Sell" then
            if IsActionSuccessful(results[1]) then
                local tower = a3 and a3.Troop
                if tower and tower:IsA("Model") then
                    local pos = tower:GetPivot().Position
                    AddAction({
                        type = "sell",
                        x = pos.X,
                        y = pos.Y,
                        z = pos.Z
                    })
                    AddLog("[RECORD] tower sold", "success")
                else
                    AddAction({ type = "sell" })
                    AddLog("[RECORD] sell (no position)", "success")
                end
                UpdateStats()
            else
                AddLog("[SKIP] failed to sell", "warn")
            end
        end

        if method == "InvokeServer" and a1 == "Troops" and a2 == "Abilities" and a3 == "Activate" then
            if IsActionSuccessful(results[1]) then
                local tower = a4 and a4.Troop
                local abilityName = a4 and a4.Name
                local abilityData = a4 and a4.Data

                if tower and tower:IsA("Model") and abilityName then
                    local pos = tower:GetPivot().Position
                    local replicator = tower:FindFirstChild("TowerReplicator")
                    local towerNameAttr = replicator and replicator:GetAttribute("Name") or ""

                    if towerNameAttr == "Hacker" and abilityName == "Hologram Tower" and type(abilityData) == "table" then
                        local targetPos = abilityData.towerPosition
                        local cloneTower = abilityData.towerToClone

                        if targetPos and cloneTower then
                            local cloneReplicator = cloneTower:FindFirstChild("TowerReplicator")
                            local cloneName = cloneReplicator and cloneReplicator:GetAttribute("Name") or ""
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
                            AddLog("[RECORD] hacker clone ("..cloneName..")", "ability")
                        end
                    else
                        local dataCopy = {}

                        if abilityData and type(abilityData) == "table" then
                            for k, v in pairs(abilityData) do
                                if typeof(v) == "CFrame" then
                                    local comps = { v:GetComponents() }
                                    dataCopy[k] = {
                                        __cf = true,
                                        v = comps
                                    }
                                else
                                    dataCopy[k] = v
                                end
                            end
                        end

                        AddAction({
                            type = "ability_all",
                            towerName = towerNameAttr,
                            abilityName = abilityName,
                            x = pos.X,
                            y = pos.Y,
                            z = pos.Z,
                            data = dataCopy
                        })
                        AddLog("[RECORD] ability: "..abilityName.." ("..towerNameAttr..")", "ability")
                    end
                else
                    AddAction({ type = "ability_all", name = abilityName or "Ability" })
                    AddLog("[RECORD] ability (no position)", "ability")
                end
            else
                AddLog("[SKIP] failed to activate ability", "warn")
            end
        end
    end

    return table.unpack(results)
end

setreadonly(mt, true)
AddLog("[SYSTEM] namecall hook enabled (with cyrillic)", "system")

local function IsActionSuccessful(result)
    local success, isModel = pcall(function() return result:IsA("Model") end)
    if success and isModel then
        return true
    end
    if type(result) == "table" and result.Success == true then
        return true
    end
    if result == true then
        return true
    end
    if type(result) == "number" then
        return true
    end
    return false
end

local function FindTowerAtPosition(pos)
    local closest = nil
    local minDist = 10

    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local replicator = obj:FindFirstChild("TowerReplicator")
                if replicator then
                    local ownerId = replicator:GetAttribute("OwnerId")
                    if ownerId == player.UserId then
                        local pivot = obj:GetPivot()
                        if pivot then
                            local dist = (pivot.Position - pos).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = obj
                            end
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
            return RemoteFunction:InvokeServer(
                "Troops",
                "Plаce",
                {
                    Rotation = CFrame.new(),
                    Position = TPos
                },
                TName
            )
        end)
        if ok and IsActionSuccessful(res) then
            UpdateStats()
            return true
        end
        task.wait(0.25)
    end
end

local function DoUpgradeTower(TObj, PathId)
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops", "Upgrade", "Set", {
                Troop = TObj,
                Path = PathId or 1
            })
        end)
        if ok and IsActionSuccessful(res) then
            UpdateStats()
            return true
        end
        task.wait(0.25)
    end
end

local function DoSellTower(TObj)
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops", "Sell", {
                Troop = TObj
            })
        end)
        if ok and IsActionSuccessful(res) then
            UpdateStats()
            return true
        end
        task.wait(0.25)
    end
end

local function DoActivateAbility(TObj, AbName, AbData)
    AbData = AbData or {}
    while true do
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Troops", "Abilities", "Activate", {
                Troop = TObj,
                Name = AbName,
                Data = AbData
            })
        end)
        if ok and IsActionSuccessful(res) then
            return true
        end
        task.wait(0.25)
    end
end

local SendRequest = request or http_request or httprequest
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

    local BonusString = ""
    if #match.Others > 0 then
        for _, res in ipairs(match.Others) do
            BonusString = BonusString .. "🎁 **" .. res.Amount .. " " .. res.Name .. "**\n"
        end
    else
        BonusString = "_No bonus rewards found._"
    end

    local PostData = {
        username = "Zuev Hub TDS",
        embeds = {{
            title = (match.Status == "WIN" and "🏆 TRIUMPH" or "💀 DEFEAT"),
            color = (match.Status == "WIN" and 0x2ecc71 or 0xe74c3c),
            description =
                "### 📋 Match Overview\n" ..
                "> **Status:** `" .. match.Status .. "`\n" ..
                "> **Time:** `" .. match.Time .. "`\n" ..
                "> **Wave:** `" .. match.Wave .. "`\n",
                
            fields = {
                {
                    name = "✨ Rewards",
                    value = "```ansi\n" ..
                            "[2;33mCoins:[0m +" .. match.Coins .. "\n" ..
                            "[2;34mGems: [0m +" .. match.Gems .. "\n" ..
                            "[2;32mXP:   [0m +" .. match.XP .. "```",
                    inline = false
                },
                {
                    name = "🎁 Bonus Items",
                    value = BonusString,
                    inline = true
                },
                {
                    name = "📊 Session Totals",
                    value = "```py\n# Total Amount\nCoins: " .. Stats.TotalCoins .. "\nGems:  " .. Stats.TotalGems .. "```",
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
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(PostData)
        })
        AddLog("[SYSTEM] Game stats sent to webhook", "system")
        ShowToast("Game stats sent to Discord")
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
                    "+%d coins (Total: %d)\n+%d gems (Total: %d)",
                    Stats.EarnedCoins, Stats.Coins,
                    Stats.EarnedGems, Stats.Gems
                )
                SendWebhook("📊 Game Finished", description, 5763719)
                ShowToast("Game finished, stats sent")
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
            "+%d coins (Total: %d)\n+%d gems (Total: %d)",
            Stats.EarnedCoins, Stats.Coins,
            Stats.EarnedGems, Stats.Gems
        )
        SendWebhook("📊 Game Left", description, 5763719)
        ShowToast("You left, stats sent")
    end
end)

local function AddAction(action)
    if not isRecording then return end
    action.t = tick() - macroStartTime
    table.insert(macro, action)
end

local function StartRecording(name)
    if isPlaying then
        AddLog("[SYSTEM] cannot record while playing", "system")
        ShowToast("Cannot record while playing")
        return
    end
    if GameState ~= "GAME" then
        AddLog("[SYSTEM] must be in game to record", "warn")
        ShowToast("Must be in game to record")
        return
    end
    macro = {}
    macroStartTime = tick()
    isRecording = true
    macroName = (name and name ~= "") and name or ("macro_"..os.time())
    AddLog("[SYSTEM] macro recording started: "..macroName, "system")
    ShowToast("Recording started: "..macroName)
    ResetStats()
end

local function StopRecording()
    if not isRecording then return end
    isRecording = false
    AddLog("[SYSTEM] macro recording stopped ("..#macro.." actions)", "system")
    ShowToast("Recording stopped ("..#macro.." actions)")
end

local function SaveCurrentMacro()
    if #macro == 0 then
        AddLog("[WARNING] no actions to save", "warn")
        ShowToast("No actions to save")
        return
    end
    
    pcall(function()
        if not writefile or not isfile then
            AddLog("[ERROR] writefile/isfile not available", "error")
            ShowToast("writefile/isfile not available")
            return
        end

        EnsureMacroFolder()
        local fileName = "Zuev Hub/"..macroName..".json"

        if isfile(fileName) then
            AddLog("[WARNING] macro with this name already exists", "warn")
            ShowToast("Macro already exists")
            return
        end

        local json = HttpService:JSONEncode(macro)
        writefile(fileName, json)
        AddLog("[SUCCESS] macro saved to "..fileName, "success")
        ShowToast("Macro saved: "..macroName)
    end)
end

local function LoadMacro(name)
    local result = nil
    pcall(function()
        if not readfile or not isfile then
            AddLog("[ERROR] readfile/isfile not available", "error")
            ShowToast("readfile/isfile not available")
            return
        end

        EnsureMacroFolder()
        local fileName = "Zuev Hub/"..name..".json"
        if not isfile(fileName) then
            AddLog("[ERROR] macro file not found: "..fileName, "error")
            ShowToast("Macro file not found")
            return
        end

        local json = readfile(fileName)
        local data = HttpService:JSONDecode(json)
        if type(data) == "table" then
            result = data
            AddLog("[SUCCESS] macro loaded: "..name.." ("..tostring(#data).." actions)", "success")
            ShowToast("Macro loaded: "..name)
        end
    end)
    return result
end

local function DeleteMacro(name)
    pcall(function()
        if not name or name == "" then
            AddLog("[SYSTEM] enter macro name to delete", "system")
            ShowToast("Enter macro name to delete")
            return
        end
        if not delfile or not isfile then
            AddLog("[ERROR] delfile/isfile not available", "error")
            ShowToast("delfile/isfile not available")
            return
        end

        EnsureMacroFolder()
        local fileName = "Zuev Hub/"..name..".json"
        if not isfile(fileName) then
            AddLog("[ERROR] macro file not found: "..fileName, "error")
            ShowToast("Macro not found: "..name)
            return
        end

        delfile(fileName)
        AddLog("[SUCCESS] macro deleted: "..name, "success")
        ShowToast("Macro deleted: "..name)
    end)
end

local function PlayMacro(name)
    if isRecording then
        AddLog("[SYSTEM] stop recording before play", "system")
        ShowToast("Stop recording first")
        return
    end
    if isPlaying then
        AddLog("[SYSTEM] already playing", "system")
        ShowToast("Already playing")
        return
    end
    if GameState ~= "GAME" then
        AddLog("[SYSTEM] must be in game to play macro", "warn")
        ShowToast("Must be in game to play")
        return
    end

    local data = LoadMacro(name)
    if not data or #data == 0 then
        AddLog("[SYSTEM] macro is empty", "system")
        ShowToast("Macro is empty")
        return
    end

    isPlaying = true
    ResetStats()
    AddLog("[SYSTEM] macro play started: "..name, "system")
    ShowToast("Playing macro: "..name)

    task.spawn(function()
        local start = tick()
        local successCount = 0
        local failCount = 0

        for _, act in ipairs(data) do
            if not isPlaying then break end

            local waitTime = (start + (act.t or 0)) - tick()
            if waitTime > 0 then
                task.wait(waitTime)
            end

            local ttype = act.type

            if ttype == "skip" then
                pcall(function()
                    RemoteFunction:InvokeServer("Voting", "Skip")
                end)
                AddLog("wave skipped by macro", "skip")
                successCount = successCount + 1

            elseif ttype == "place" then
                local unit = act.unit
                local x, y, z = act.x, act.y, act.z
                if type(unit) == "string" and type(x) == "number" and type(y) == "number" and type(z) == "number" then
                    local pos = Vector3.new(x, y, z)
                    if DoPlaceTower(unit, pos) then
                        AddLog("placed "..unit.." by macro", "place")
                        successCount = successCount + 1
                    else
                        failCount = failCount + 1
                    end
                end

            elseif ttype == "upgrade" then
                local x, y, z = act.x, act.y, act.z
                if type(x) == "number" and type(y) == "number" and type(z) == "number" then
                    local pos = Vector3.new(x, y, z)
                    local tower = FindTowerAtPosition(pos)
                    if tower then
                        DoUpgradeTower(tower, 1)
                        AddLog("[SUCCESS] upgrade executed", "upgrade")
                        successCount = successCount + 1
                        task.wait(0.3)
                    else
                        AddLog("[WARNING] tower not found for upgrade", "warn")
                        failCount = failCount + 1
                    end
                else
                    AddLog("[WARNING] upgrade action missing position", "warn")
                    failCount = failCount + 1
                end

            elseif ttype == "sell" then
                local x, y, z = act.x, act.y, act.z
                if type(x) == "number" and type(y) == "number" and type(z) == "number" then
                    local pos = Vector3.new(x, y, z)
                    local tower = FindTowerAtPosition(pos)
                    if tower then
                        DoSellTower(tower)
                        AddLog("[SUCCESS] tower sold", "success")
                        successCount = successCount + 1
                    else
                        AddLog("[WARNING] tower not found for sell", "warn")
                        failCount = failCount + 1
                    end
                else
                    AddLog("[WARNING] sell action missing position", "warn")
                    failCount = failCount + 1
                end

            elseif ttype == "hacker_clone" then
                local sourceX, sourceY, sourceZ = act.sourceX, act.sourceY, act.sourceZ
                local targetX, targetY, targetZ = act.targetX, act.targetY, act.targetZ
                local cloneName = act.cloneName

                if sourceX and sourceY and sourceZ and targetX and targetY and targetZ and cloneName then
                    local sourcePos = Vector3.new(sourceX, sourceY, sourceZ)
                    local hackerTower = FindTowerAtPosition(sourcePos)

                    if hackerTower then
                        local towerToClone = nil
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("Model") then
                                local replicator = obj:FindFirstChild("TowerReplicator")
                                if replicator and replicator:GetAttribute("Name") == cloneName
                                   and replicator:GetAttribute("OwnerId") == player.UserId then
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
                                    towerPosition = Vector3.new(targetX, targetY, targetZ)
                                }
                            }

                            local ok, res = pcall(function()
                                return RemoteFunction:InvokeServer("Troops", "Abilities", "Activate", args)
                            end)

                            if ok and IsActionSuccessful(res) then
                                AddLog("[SUCCESS] hacker clone executed ("..cloneName..")", "ability")
                                successCount = successCount + 1
                            else
                                AddLog("[ERROR] hacker clone failed", "error")
                                failCount = failCount + 1
                            end
                        else
                            AddLog("[WARNING] tower to clone not found: "..cloneName, "warn")
                            failCount = failCount + 1
                        end
                    else
                        AddLog("[WARNING] hacker tower not found", "warn")
                        failCount = failCount + 1
                    end
                else
                    AddLog("[WARNING] hacker clone missing data", "warn")
                    failCount = failCount + 1
                end

            elseif ttype == "ability_all" then
                local towerName = act.towerName
                local abilityName = act.abilityName
                local x, y, z = act.x, act.y, act.z
                local savedData = act.data or {}

                if type(x) == "number" and type(y) == "number" and type(z) == "number" and abilityName then
                    local pos = Vector3.new(x, y, z)
                    local tower = FindTowerAtPosition(pos)

                    if tower then
                        local finalData = {}

                        for k, v in pairs(savedData) do
                            if type(v) == "table" and v.__cf and type(v.v) == "table" then
                                local c = v.v
                                finalData[k] = CFrame.new(
                                    c[1], c[2], c[3],
                                    c[4], c[5], c[6],
                                    c[7], c[8], c[9],
                                    c[10], c[11], c[12]
                                )
                            else
                                finalData[k] = v
                            end
                        end

                        if DoActivateAbility(tower, abilityName, finalData) then
                            AddLog("[SUCCESS] ability used: "..abilityName.." ("..tostring(towerName or "unknown")..")", "ability")
                            successCount = successCount + 1
                        else
                            failCount = failCount + 1
                        end
                    else
                        AddLog("[WARNING] tower not found for ability", "warn")
                        failCount = failCount + 1
                    end
                else
                    AddLog("[WARNING] ability action missing data", "warn")
                    failCount = failCount + 1
                end
            end
        end

        isPlaying = false
        UpdateStats()
        
        local resultText = string.format("✅ Success: %d | ❌ Failed: %d | Coins: %d (+%d) | Gems: %d (+%d)", 
            successCount, failCount, 
            Stats.Coins, Stats.EarnedCoins,
            Stats.Gems, Stats.EarnedGems)
        AddLog("[SYSTEM] macro play finished - "..resultText, "system")
        ShowToast("Macro finished: "..resultText)
    end)
end

recordBtn.MouseButton1Click:Connect(function()
    StartRecording(macroNameBox.Text)
end)

stopBtn.MouseButton1Click:Connect(function()
    if isRecording then
        StopRecording()
        SaveCurrentMacro()
    elseif isPlaying then
        isPlaying = false
        AddLog("[SYSTEM] macro play stopped", "system")
        ShowToast("Playback stopped")
    end
end)

playBtn.MouseButton1Click:Connect(function()
    local name = savedMacroBox.Text
    if name == "" then
        AddLog("[SYSTEM] enter saved macro name", "system")
        ShowToast("Enter macro name")
        return
    end
    PlayMacro(name)
end)

deleteBtn.MouseButton1Click:Connect(function()
    local name = savedMacroBox.Text
    if name == "" then
        AddLog("[SYSTEM] enter macro name to delete", "system")
        ShowToast("Enter macro name")
        return
    end
    DeleteMacro(name)
    savedMacroBox.Text = ""
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F5 then
        StartRecording(macroNameBox.Text)
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if isRecording then
            StopRecording()
            SaveCurrentMacro()
        elseif isPlaying then
            isPlaying = false
            AddLog("[SYSTEM] macro play stopped", "system")
            ShowToast("Playback stopped")
        end
    end
end)

pcall(TrackStats)
pcall(UpdateStats)
pcall(ResetStats)

print("[SYSTEM] All features loaded - Final Version")
