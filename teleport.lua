-- Roblox Checkpoint Teleport Script untuk Delta Executor
-- Script ini mendeteksi checkpoint di sekitar player dan mengaktifkannya saat dilewati
-- Checkpoint yang sudah dilewati disimpan secara persistent dan bisa digunakan untuk teleport

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local player = Players.LocalPlayer
local character = player.Character
local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")

-- Cache untuk semua checkpoint di map
local allCheckpoints = {}
-- Checkpoint yang sudah dilewati (aktif)
local unlockedCheckpoints = {}
-- DataStore untuk persistent storage
local dataStore = nil
local dataStoreKey = "CheckpointData_" .. player.UserId

-- Konfigurasi
local CONFIG = {
    DetectionRadius = 15, -- Radius deteksi checkpoint (studs)
    TouchRadius = 8, -- Radius untuk mengaktifkan checkpoint (studs)
    SaveInterval = 5 -- Interval save ke DataStore (detik)
}

-- Konfigurasi UI
local UI_CONFIG = {
    MainFrame = {
        Size = UDim2.new(0, 420, 0, 650),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor = Color3.fromRGB(20, 20, 25),
        BorderSize = 0
    },
    TitleBar = {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor = Color3.fromRGB(30, 30, 40)
    },
    ScrollFrame = {
        Size = UDim2.new(1, -20, 1, -120),
        Position = UDim2.new(0, 10, 0, 75),
        BackgroundColor = Color3.fromRGB(15, 15, 20),
        BorderSize = 0
    },
    Button = {
        Size = UDim2.new(1, -10, 0, 42),
        BackgroundColor = Color3.fromRGB(35, 35, 45),
        HoverColor = Color3.fromRGB(60, 140, 220),
        ActiveColor = Color3.fromRGB(50, 200, 100),
        TextColor = Color3.fromRGB(255, 255, 255)
    }
}

-- Variabel untuk GUI
local screenGui = nil
local scrollingFrame = nil
local titleText = nil
local buttonCache = {}

-- Fungsi untuk mendapatkan CFrame dari objek checkpoint
local function getCheckpointCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or 
                     obj:FindFirstChild("HumanoidRootPart") or
                     obj:FindFirstChild("RootPart") or
                     obj:FindFirstChildOfClass("BasePart")
        if part then
            return part.CFrame
        end
    elseif obj:IsA("Attachment") then
        return obj.WorldCFrame
    end
    return nil
end

-- Fungsi untuk mendapatkan part dari checkpoint
local function getCheckpointPart(obj)
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") then
        return obj.PrimaryPart or 
               obj:FindFirstChild("HumanoidRootPart") or
               obj:FindFirstChild("RootPart") or
               obj:FindFirstChildOfClass("BasePart")
    end
    return nil
end

-- Fungsi untuk scan semua checkpoint di workspace
local function scanAllCheckpoints()
    allCheckpoints = {}
    
    print("Scanning checkpoints di map...")
    local startTime = tick()
    
    -- Pattern untuk nama checkpoint
    local checkpointPatterns = {
        "^CheckpointCp(%d+)$",
        "^Cp(%d+)$",
        "^CP(%d+)$",
        "^Checkpoint(%d+)$",
        "^Checkpoint_%d+$",
        "^SpawnCp(%d+)$",
        "^Spawn(%d+)$"
    }
    
    -- Fungsi untuk extract nomor dari nama
    local function extractNumber(name)
        for _, pattern in ipairs(checkpointPatterns) do
            local num = name:match(pattern)
            if num then
                return tonumber(num)
            end
        end
        local numbers = {}
        for num in name:gmatch("%d+") do
            table.insert(numbers, tonumber(num))
        end
        return numbers[1]
    end
    
    -- Scan semua descendants
    local allDescendants = Workspace:GetDescendants()
    
    for _, obj in ipairs(allDescendants) do
        local name = obj.Name
        local num = extractNumber(name)
        
        local isCheckpoint = false
        
        if num then
            -- Cek pattern nama
            for _, pattern in ipairs(checkpointPatterns) do
                if name:match(pattern) then
                    isCheckpoint = true
                    break
                end
            end
            
            -- Cek jika ada di folder checkpoint
            local parent = obj.Parent
            if parent and (parent.Name:lower():find("checkpoint") or 
                          parent.Name:lower():find("cp") or
                          parent.Name:lower():find("spawn")) then
                isCheckpoint = true
            end
        end
        
        if isCheckpoint then
            local cframe = getCheckpointCFrame(obj)
            local part = getCheckpointPart(obj)
            
            if cframe and part then
                local checkpointNum = num or 0
                
                table.insert(allCheckpoints, {
                    Name = name,
                    Number = checkpointNum,
                    CFrame = cframe,
                    Part = part,
                    Object = obj,
                    Unlocked = false
                })
            end
        end
    end
    
    -- Sort berdasarkan nomor
    table.sort(allCheckpoints, function(a, b)
        if a.Number == b.Number then
            return a.Name < b.Name
        end
        return a.Number < b.Number
    end)
    
    local endTime = tick()
    local foundCount = #allCheckpoints
    
    print(string.format("Found %d checkpoints in %.2f seconds", foundCount, endTime - startTime))
    
    return foundCount > 0
end

-- Fungsi untuk load data dari DataStore
local function loadCheckpointData()
    local success, data = pcall(function()
        if dataStore then
            return dataStore:GetAsync(dataStoreKey)
        end
        return nil
    end)
    
    if success and data and type(data) == "table" then
        unlockedCheckpoints = data
        print("✓ Loaded " .. #unlockedCheckpoints .. " unlocked checkpoints from DataStore")
        
        -- Update status checkpoint
        for _, checkpoint in ipairs(allCheckpoints) do
            for _, unlockedName in ipairs(unlockedCheckpoints) do
                if checkpoint.Name == unlockedName then
                    checkpoint.Unlocked = true
                    break
                end
            end
        end
    else
        unlockedCheckpoints = {}
        print("No saved checkpoint data found")
    end
end

-- Fungsi untuk save data ke DataStore
local function saveCheckpointData()
    local success, err = pcall(function()
        if dataStore then
            dataStore:SetAsync(dataStoreKey, unlockedCheckpoints)
            return true
        end
        return false
    end)
    
    if success then
        print("✓ Saved " .. #unlockedCheckpoints .. " unlocked checkpoints to DataStore")
    else
        warn("Failed to save checkpoint data: " .. tostring(err))
    end
end

-- Fungsi untuk unlock checkpoint
local function unlockCheckpoint(checkpointName)
    -- Cek apakah sudah unlocked
    for _, name in ipairs(unlockedCheckpoints) do
        if name == checkpointName then
            return false -- Sudah unlocked
        end
    end
    
    -- Tambahkan ke list unlocked
    table.insert(unlockedCheckpoints, checkpointName)
    
    -- Update status checkpoint
    for _, checkpoint in ipairs(allCheckpoints) do
        if checkpoint.Name == checkpointName then
            checkpoint.Unlocked = true
            print("✓ Unlocked checkpoint: " .. checkpointName)
            break
        end
    end
    
    -- Save ke DataStore
    saveCheckpointData()
    
    -- Update UI
    updateGUI()
    
    return true
end

-- Fungsi untuk deteksi checkpoint di sekitar player
local function detectNearbyCheckpoints()
    if not humanoidRootPart or not humanoidRootPart.Parent then
        return
    end
    
    local playerPosition = humanoidRootPart.Position
    
    for _, checkpoint in ipairs(allCheckpoints) do
        if checkpoint.Part and checkpoint.Part.Parent then
            local checkpointPosition = checkpoint.CFrame.Position
            local distance = (playerPosition - checkpointPosition).Magnitude
            
            -- Jika dalam radius touch, unlock checkpoint
            if distance <= CONFIG.TouchRadius and not checkpoint.Unlocked then
                unlockCheckpoint(checkpoint.Name)
            end
        end
    end
end

-- Fungsi untuk teleport ke checkpoint
local function teleportToCheckpoint(checkpointData)
    if not checkpointData or not checkpointData.CFrame then
        warn("Checkpoint data tidak valid!")
        return false
    end
    
    if not checkpointData.Unlocked then
        warn("Checkpoint belum di-unlock!")
        return false
    end
    
    -- Update character reference
    if not character or not character.Parent then
        character = player.Character
        if not character then
            warn("Character tidak tersedia!")
            return false
        end
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end
    
    if not humanoidRootPart then
        warn("HumanoidRootPart tidak ditemukan!")
        return false
    end
    
    -- Teleport dengan offset
    local targetCFrame = checkpointData.CFrame
    local offset = Vector3.new(0, 5, 0)
    
    -- Raycast untuk cek ground
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycast = Workspace:Raycast(targetCFrame.Position, Vector3.new(0, -50, 0), raycastParams)
    if raycast then
        offset = Vector3.new(0, 3, 0)
    end
    
    -- Teleport
    humanoidRootPart.CFrame = targetCFrame + offset
    
    print("✓ Teleported ke " .. checkpointData.Name)
    return true
end

-- Fungsi untuk update GUI
local function updateGUI()
    if not screenGui or not scrollingFrame then
        return
    end
    
    -- Clear existing buttons
    for _, button in pairs(buttonCache) do
        if button and button.Parent then
            button:Destroy()
        end
    end
    buttonCache = {}
    
    -- Get unlocked checkpoints sorted
    local unlockedList = {}
    for _, checkpoint in ipairs(allCheckpoints) do
        if checkpoint.Unlocked then
            table.insert(unlockedList, checkpoint)
        end
    end
    
    -- Sort
    table.sort(unlockedList, function(a, b)
        if a.Number == b.Number then
            return a.Name < b.Name
        end
        return a.Number < b.Number
    end)
    
    -- Update title
    if titleText then
        titleText.Text = string.format("Unlocked Checkpoints (%d)", #unlockedList)
    end
    
    -- Create buttons untuk unlocked checkpoints
    for i, checkpointData in ipairs(unlockedList) do
        local button = Instance.new("TextButton")
        button.Name = "Cp_" .. i
        button.LayoutOrder = i
        button.Size = UI_CONFIG.Button.Size
        button.BackgroundColor3 = UI_CONFIG.Button.BackgroundColor
        button.BorderSizePixel = 0
        button.Text = checkpointData.Name
        button.TextColor3 = UI_CONFIG.Button.TextColor
        button.TextSize = 15
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = scrollingFrame
        
        -- Padding
        local textPadding = Instance.new("UIPadding")
        textPadding.PaddingLeft = UDim.new(0, 12)
        textPadding.Parent = button
        
        -- Rounded corners
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        
        -- Hover effect
        local originalColor = button.BackgroundColor3
        button.MouseEnter:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = UI_CONFIG.Button.HoverColor}
            ):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = originalColor}
            ):Play()
        end)
        
        -- Click event
        button.MouseButton1Click:Connect(function()
            local success = teleportToCheckpoint(checkpointData)
            
            if success then
                local originalText = button.Text
                button.Text = "✓ " .. originalText
                TweenService:Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = UI_CONFIG.Button.ActiveColor}
                ):Play()
                
                wait(0.6)
                
                button.Text = originalText
                TweenService:Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = originalColor}
                ):Play()
            end
        end)
        
        buttonCache[i] = button
    end
end

-- Fungsi untuk membuat UI
local function createGUI()
    local success, err = pcall(function()
        local playerGui = player:WaitForChild("PlayerGui")
        
        -- Hapus GUI lama jika ada
        local oldGui = playerGui:FindFirstChild("CheckpointTeleportGUI")
        if oldGui then
            oldGui:Destroy()
        end
        
        -- Membuat ScreenGui
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CheckpointTeleportGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 999
        screenGui.Parent = playerGui
        
        -- Main Frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UI_CONFIG.MainFrame.Size
        mainFrame.Position = UI_CONFIG.MainFrame.Position
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.BackgroundColor3 = UI_CONFIG.MainFrame.BackgroundColor
        mainFrame.BorderSizePixel = UI_CONFIG.MainFrame.BorderSize
        mainFrame.Parent = screenGui
        
        -- Rounded corners
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 14)
        mainCorner.Parent = mainFrame
        
        -- Shadow effect
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 8, 1, 8)
        shadow.Position = UDim2.new(0, -4, 0, -4)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.8
        shadow.BorderSizePixel = 0
        shadow.ZIndex = mainFrame.ZIndex - 1
        shadow.Parent = mainFrame
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 14)
        shadowCorner.Parent = shadow
        
        -- Title Bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UI_CONFIG.TitleBar.Size
        titleBar.BackgroundColor3 = UI_CONFIG.TitleBar.BackgroundColor
        titleBar.BorderSizePixel = 0
        titleBar.Parent = mainFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 14)
        titleCorner.Parent = titleBar
        
        -- Title Text
        titleText = Instance.new("TextLabel")
        titleText.Name = "TitleText"
        titleText.Size = UDim2.new(1, -100, 1, 0)
        titleText.Position = UDim2.new(0, 15, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = "Unlocked Checkpoints (0)"
        titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleText.TextSize = 18
        titleText.Font = Enum.Font.GothamBold
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar
        
        -- Close Button (X)
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 45, 0, 45)
        closeButton.Position = UDim2.new(1, -50, 0, 5)
        closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        closeButton.BorderSizePixel = 0
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextSize = 22
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = titleBar
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 10)
        closeCorner.Parent = closeButton
        
        -- Hover effect untuk close button
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(
                closeButton,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(255, 80, 80)}
            ):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(
                closeButton,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(220, 60, 60)}
            ):Play()
        end)
        
        -- Close functionality
        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            screenGui = nil
            scrollingFrame = nil
            titleText = nil
        end)
        
        -- Scroll Frame Container
        local scrollFrame = Instance.new("Frame")
        scrollFrame.Name = "ScrollFrame"
        scrollFrame.Size = UI_CONFIG.ScrollFrame.Size
        scrollFrame.Position = UI_CONFIG.ScrollFrame.Position
        scrollFrame.BackgroundColor3 = UI_CONFIG.ScrollFrame.BackgroundColor
        scrollFrame.BorderSizePixel = UI_CONFIG.ScrollFrame.BorderSize
        scrollFrame.ClipsDescendants = true
        scrollFrame.Parent = mainFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 10)
        scrollCorner.Parent = scrollFrame
        
        -- Scrolling Frame
        scrollingFrame = Instance.new("ScrollingFrame")
        scrollingFrame.Name = "ScrollingFrame"
        scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
        scrollingFrame.BackgroundTransparency = 1
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.ScrollBarThickness = 10
        scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
        scrollingFrame.Parent = scrollFrame
        
        -- UI List Layout
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 6)
        listLayout.Parent = scrollingFrame
        
        -- Padding
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.Parent = scrollingFrame
        
        -- Update canvas size
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
        end)
        
        -- Drag functionality
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        
        local function update(input)
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
        
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
        
        -- Update GUI dengan unlocked checkpoints
        updateGUI()
        
        return screenGui
    end)
    
    if not success then
        warn("Error membuat GUI: " .. tostring(err))
        return nil
    end
end

-- Inisialisasi DataStore
local function initDataStore()
    local success, store = pcall(function()
        return DataStoreService:GetDataStore("CheckpointTeleportData")
    end)
    
    if success then
        dataStore = store
        print("✓ DataStore initialized")
    else
        warn("DataStore tidak tersedia, menggunakan memory cache")
        dataStore = nil
    end
end

-- Handler untuk character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- Inisialisasi
initDataStore()

if character then
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Scan checkpoint
if scanAllCheckpoints() then
    -- Load saved data
    loadCheckpointData()
    
    -- Deteksi checkpoint setiap frame
    RunService.Heartbeat:Connect(function()
        detectNearbyCheckpoints()
    end)
    
    -- Auto-save setiap interval
    spawn(function()
        while true do
            wait(CONFIG.SaveInterval)
            if #unlockedCheckpoints > 0 then
                saveCheckpointData()
            end
        end
    end)
    
    -- Membuat GUI
    createGUI()
    
    print("✓ Checkpoint Teleport System Loaded!")
    print("✓ " .. #allCheckpoints .. " checkpoints ditemukan di map")
    print("✓ " .. #unlockedCheckpoints .. " checkpoint sudah di-unlock")
    print("Jalankan script untuk membuka GUI dan teleport ke checkpoint yang sudah dilewati.")
else
    warn("✗ Tidak ada checkpoint ditemukan di map!")
end
