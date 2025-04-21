local Key = "Zuev"
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui

-- Полупрозрачный фон
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.new(0, 0, 0)
background.BackgroundTransparency = 0.5
background.Parent = screenGui

-- Окно ввода ключа
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(0, 350, 0, 150)
inputFrame.Position = UDim2.new(0.5, -175, 0.5, -75)
inputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
inputFrame.Parent = screenGui

local inputUICorner = Instance.new("UICorner", inputFrame)
inputUICorner.CornerRadius = UDim.new(0, 15)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "Введите ключ доступа"
titleLabel.Parent = inputFrame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 40)
keyBox.Position = UDim2.new(0.1, 0, 0.45, 0)
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 20
keyBox.TextColor3 = Color3.fromRGB(100, 100, 100)
keyBox.BackgroundColor3 = Color3.new(1, 1, 1)
keyBox.Text = "Как думаешь какой ключ?)"
keyBox.ClearTextOnFocus = false
keyBox.Parent = inputFrame

local keyBoxCorner = Instance.new("UICorner", keyBox)
keyBoxCorner.CornerRadius = UDim.new(0, 10)

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0.8, 0, 0, 40)
submitButton.Position = UDim2.new(0.1, 0, 0.8, 0)
submitButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
submitButton.Font = Enum.Font.GothamBold
submitButton.TextSize = 22
submitButton.TextColor3 = Color3.new(1, 1, 1)
submitButton.Text = "Подтвердить"
submitButton.Parent = inputFrame

local submitCorner = Instance.new("UICorner", submitButton)
submitCorner.CornerRadius = UDim.new(0, 10)

local errorLabel = Instance.new("TextLabel")
errorLabel.Size = UDim2.new(1, 0, 0, 25)
errorLabel.Position = UDim2.new(0, 0, 1, -30)
errorLabel.BackgroundTransparency = 1
errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
errorLabel.Font = Enum.Font.GothamBold
errorLabel.TextSize = 18
errorLabel.Text = ""
errorLabel.TextWrapped = true
errorLabel.Parent = inputFrame

-- Черное большое окно с сообщением "Подумай еще раз"
local bigErrorFrame = Instance.new("Frame")
bigErrorFrame.Size = UDim2.new(1, 0, 0.5, 0)
bigErrorFrame.Position = UDim2.new(0, 0, 0.5, 0)
bigErrorFrame.BackgroundColor3 = Color3.new(0, 0, 0)
bigErrorFrame.BackgroundTransparency = 0.7
bigErrorFrame.Visible = false
bigErrorFrame.Parent = screenGui

local bigErrorLabel = Instance.new("TextLabel")
bigErrorLabel.Size = UDim2.new(1, 0, 1, 0)
bigErrorLabel.BackgroundTransparency = 1
bigErrorLabel.TextColor3 = Color3.new(1, 1, 1)
bigErrorLabel.Font = Enum.Font.GothamBlack
bigErrorLabel.TextSize = 60
bigErrorLabel.Text = "Подумай еще раз"
bigErrorLabel.TextWrapped = true
bigErrorLabel.TextXAlignment = Enum.TextXAlignment.Center
bigErrorLabel.TextYAlignment = Enum.TextYAlignment.Center
bigErrorLabel.Parent = bigErrorFrame

-- Логика очистки текста при фокусе в keyBox
keyBox.Focused:Connect(function()
    if keyBox.Text == "Как думаешь какой ключ?)" then
        keyBox.Text = ""
        keyBox.TextColor3 = Color3.new(0,0,0)
    end
end)
keyBox.FocusLost:Connect(function()
    if keyBox.Text == "" then
        keyBox.Text = "Как думаешь какой ключ?)"
        keyBox.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

-- Переменная для хранения текущего бинда (по умолчанию M)
local currentBind = Enum.KeyCode.M

-- Функция создания основного GUI с вкладками
local function createMainGUI()
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 380)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 15)

    -- Панель вкладок
    local tabPanel = Instance.new("Frame")
    tabPanel.Size = UDim2.new(1, 0, 0, 40)
    tabPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tabPanel.Parent = mainFrame

    -- Кнопка Home
    local homeTab = Instance.new("TextButton")
    homeTab.Size = UDim2.new(1/3, 0, 1, 0)
    homeTab.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    homeTab.Font = Enum.Font.GothamBold
    homeTab.TextSize = 18
    homeTab.TextColor3 = Color3.new(1, 1, 1)
    homeTab.Text = "Home"
    homeTab.Parent = tabPanel

    -- Кнопка Info
    local infoTab = Instance.new("TextButton")
    infoTab.Size = UDim2.new(1/3, 0, 1, 0)
    infoTab.Position = UDim2.new(1/3, 0, 0, 0)
    infoTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    infoTab.Font = Enum.Font.GothamBold
    infoTab.TextSize = 18
    infoTab.TextColor3 = Color3.new(1, 1, 1)
    infoTab.Text = "Info"
    infoTab.Parent = tabPanel

    -- Кнопка Misc
    local miscTab = Instance.new("TextButton")
    miscTab.Size = UDim2.new(1/3, 0, 1, 0)
    miscTab.Position = UDim2.new(2/3, 0, 0, 0)
    miscTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    miscTab.Font = Enum.Font.GothamBold
    miscTab.TextSize = 18
    miscTab.TextColor3 = Color3.new(1, 1, 1)
    miscTab.Text = "Misc"
    miscTab.Parent = tabPanel

    -- Контейнер контента
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -40)
    contentFrame.Position = UDim2.new(0, 0, 0, 40)
    contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contentFrame.Parent = mainFrame

    -- Контент вкладки Home
    local homeContent = Instance.new("Frame")
    homeContent.Size = UDim2.new(1, 0, 1, 0)
    homeContent.BackgroundTransparency = 1
    homeContent.Parent = contentFrame

    -- Верхняя панель с выбором игрока и кнопкой обновления
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.Position = UDim2.new(0, 0, 0, 20)
    topBar.BackgroundTransparency = 1
    topBar.Parent = homeContent

    -- Dropdown для игроков
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0.6, 0, 1, 0)
    dropdownFrame.Position = UDim2.new(0.02, 0, 0, 0)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownFrame.Parent = topBar
    local dropdownCorner = Instance.new("UICorner", dropdownFrame)
    dropdownCorner.CornerRadius = UDim.new(0, 8)

    local selectedPlayerText = Instance.new("TextLabel")
    selectedPlayerText.Size = UDim2.new(1, -30, 1, 0)
    selectedPlayerText.Position = UDim2.new(0, 5, 0, 0)
    selectedPlayerText.BackgroundTransparency = 1
    selectedPlayerText.Font = Enum.Font.Gotham
    selectedPlayerText.TextSize = 18
    selectedPlayerText.TextColor3 = Color3.new(0, 0, 0)
    selectedPlayerText.Text = "Выберите игрока"
    selectedPlayerText.TextXAlignment = Enum.TextXAlignment.Left
    selectedPlayerText.Parent = dropdownFrame

    local dropdownArrow = Instance.new("TextLabel")
    dropdownArrow.Size = UDim2.new(0, 20, 1, 0)
    dropdownArrow.Position = UDim2.new(1, -25, 0, 0)
    dropdownArrow.BackgroundTransparency = 1
    dropdownArrow.Font = Enum.Font.GothamBold
    dropdownArrow.TextSize = 24
    dropdownArrow.TextColor3 = Color3.new(0, 0, 0)
    dropdownArrow.Text = "▼"
    dropdownArrow.Parent = dropdownFrame

    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(0.6, 0, 0, 150)
    dropdownList.Position = UDim2.new(0.02, 0, 1, 0)
    dropdownList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dropdownList.BorderSizePixel = 1
    dropdownList.Visible = false
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdownList.ScrollBarThickness = 6
    dropdownList.Parent = homeContent
    local dropdownListCorner = Instance.new("UICorner", dropdownList)
    dropdownListCorner.CornerRadius = UDim.new(0, 8)

    -- Кнопка обновления списка
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0.3, 0, 1, 0)
    refreshButton.Position = UDim2.new(0.65, 0, 0, 0)
    refreshButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 18
    refreshButton.TextColor3 = Color3.new(1, 1, 1)
    refreshButton.Text = "Обновить"
    refreshButton.Parent = topBar
    local refreshCorner = Instance.new("UICorner", refreshButton)
    refreshCorner.CornerRadius = UDim.new(0, 8)

    -- Кнопка "Подбросить"
    local flingButton = Instance.new("TextButton")
    flingButton.Size = UDim2.new(0.8, 0, 0, 50)
    flingButton.Position = UDim2.new(0.1, 0, 0, 200)
    flingButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    flingButton.Font = Enum.Font.GothamBold
    flingButton.TextSize = 24
    flingButton.TextColor3 = Color3.new(1, 1, 1)
    flingButton.Text = "ПОДБРОСИТЬ!"
    flingButton.Parent = homeContent

    -- Клик по dropdownFrame открывает/закрывает список
    dropdownFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropdownList.Visible = not dropdownList.Visible
        end
    end)

    -- Функция обновления списка игроков в dropdown
    local function updatePlayerList()
        for _, child in pairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local yPos = 0
        for _, player in pairs(Players:GetPlayers()) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, yPos)
            btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 18
            btn.TextColor3 = Color3.new(0, 0, 0)
            btn.Text = player.Name
            btn.Parent = dropdownList
            btn.AutoButtonColor = true

            btn.MouseButton1Click:Connect(function()
                selectedPlayerText.Text = player.Name
                dropdownList.Visible = false
            end)

            yPos = yPos + 35
        end
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end

    refreshButton.MouseButton1Click:Connect(function()
        updatePlayerList()
    end)

    updatePlayerList()

    -- Функция подброса
    local function SkidFling(targetName)
        local pl = Players.LocalPlayer
        local target = Players:FindFirstChild(targetName)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
        local targetHRP = target.Character.HumanoidRootPart
        local localHRP = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
        if not localHRP then return end
        localHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        wait(0.1)
        targetHRP.Velocity = Vector3.new(0, 100, 0)
        wait(0.5)
        localHRP.CFrame = localHRP.CFrame * CFrame.new(0, 0, -3)
    end

    flingButton.MouseButton1Click:Connect(function()
        local targetName = selectedPlayerText.Text
        if targetName ~= "" and targetName ~= "Выберите игрока" then
            SkidFling(targetName)
        end
    end)

    -- Контент вкладки Info
    local infoContent = Instance.new("Frame")
    infoContent.Size = UDim2.new(1, 0, 1, 0)
    infoContent.BackgroundTransparency = 1
    infoContent.Visible = false
    infoContent.Parent = contentFrame

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 1, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.GothamBold
    infoLabel.TextSize = 30
    infoLabel.TextColor3 = Color3.new(1, 1, 1)
    infoLabel.Text = "Zuev"
    infoLabel.Parent = infoContent

    -- Контент вкладки Misc
    local miscContent = Instance.new("Frame")
    miscContent.Size = UDim2.new(1, 0, 1, 0)
    miscContent.BackgroundTransparency = 1
    miscContent.Visible = false
    miscContent.Parent = contentFrame

    -- Текст и поле для ввода бинда
    local bindLabel = Instance.new("TextLabel")
    bindLabel.Size = UDim2.new(0.9, 0, 0, 30)
    bindLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    bindLabel.BackgroundTransparency = 1
    bindLabel.Font = Enum.Font.GothamBold
    bindLabel.TextSize = 22
    bindLabel.TextColor3 = Color3.new(1, 1, 1)
    bindLabel.Text = "Бинд для скрытия/показа меню:"
    bindLabel.Parent = miscContent

    local bindBox = Instance.new("TextBox")
    bindBox.Size = UDim2.new(0.9, 0, 0, 40)
    bindBox.Position = UDim2.new(0.05, 0, 0.4, 0)
    bindBox.Font = Enum.Font.Gotham
    bindBox.TextSize = 20
    bindBox.TextColor3 = Color3.new(0, 0, 0)
    bindBox.BackgroundColor3 = Color3.new(1, 1, 1)
    bindBox.Text = currentBind.Name
    bindBox.ClearTextOnFocus = false
    bindBox.Parent = miscContent

    -- Скругления
    Instance.new("UICorner", inputFrame)
    Instance.new("UICorner", submitButton)
    Instance.new("UICorner", keyBox)
    Instance.new("UICorner", mainFrame)
    Instance.new("UICorner", flingButton)
    Instance.new("UICorner", dropdownFrame)
    Instance.new("UICorner", dropdownList)
    Instance.new("UICorner", refreshButton)
    Instance.new("UICorner", bindBox)
    Instance.new("UICorner", topBar)

    -- Обновление бинда при вводе и нажатии Enter
    bindBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local text = bindBox.Text:upper()
            local found = false
            for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
                if key.Name == text then
                    currentBind = key
                    bindBox.Text = currentBind.Name
                    found = true
                    break
                end
            end
            if not found then
                bindBox.Text = currentBind.Name
            end
        end
    end)

    -- Переключение вкладок
    local function setActiveTab(activeTab)
        homeTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        infoTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        miscTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        homeContent.Visible = false
        infoContent.Visible = false
        miscContent.Visible = false

        activeTab.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        if activeTab == homeTab then
            homeContent.Visible = true
        elseif activeTab == infoTab then
            infoContent.Visible = true
        elseif activeTab == miscTab then
            miscContent.Visible = true
        end
    end

    homeTab.MouseButton1Click:Connect(function()
        setActiveTab(homeTab)
    end)

    infoTab.MouseButton1Click:Connect(function()
        setActiveTab(infoTab)
    end)

    miscTab.MouseButton1Click:Connect(function()
        setActiveTab(miscTab)
    end)

    -- По умолчанию активна вкладка Home
    setActiveTab(homeTab)

    -- Скрытие/показ меню по бинду
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentBind then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
end

-- Проверка ключа
local function CheckKey()
    if keyBox.Text == Key then
        errorLabel.Text = ""
        bigErrorFrame.Visible = false
        inputFrame.Visible = false
        background.Visible = false
        createMainGUI()
        -- Отправляем сообщение в чат
        local plr = Players.LocalPlayer
        if plr and plr.Character then
            local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvent and chatEvent:FindFirstChild("SayMessageRequest") then
                chatEvent.SayMessageRequest:FireServer("zuev", "All")
            else
                -- Альтернативный способ через StarterGui:SetCore (если доступно)
                local success, err = pcall(function()
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "zuev";
                        Color = Color3.new(1,1,1);
                        Font = Enum.Font.SourceSansBold;
                        FontSize = Enum.FontSize.Size24;
                    })
                end)
            end
        end
    else
        errorLabel.Text = ""
        bigErrorFrame.Visible = true
        -- Скрываем bigError через 3 секунды
        delay(3, function()
            bigErrorFrame.Visible = false
        end)
        keyBox.Text = ""
        keyBox.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
end

submitButton.MouseButton1Click:Connect(CheckKey)
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CheckKey()
    end
end)
