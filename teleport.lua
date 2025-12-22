-- Roblox Checkpoint Teleport Script untuk Delta Executor

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character
local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")

-- Cache untuk checkpoint yang sudah ditemukan
local checkpointCache = {}
local checkpointList = {}

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

-- Fungsi untuk scan semua checkpoint di workspace secara optimal
local function scanAllCheckpoints()
    checkpointCache = {}
    checkpointList = {}
    
    print("Scanning checkpoints di map...")
    local startTime = tick()
    
    -- Pattern untuk nama checkpoint yang umum digunakan
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
        -- Fallback: cari semua angka di nama
        local numbers = {}
        for num in name:gmatch("%d+") do
            table.insert(numbers, tonumber(num))
        end
        return numbers[1] -- Ambil angka pertama
    end
    
    -- Scan semua descendants sekali
    local allDescendants = Workspace:GetDescendants()
    
    for _, obj in ipairs(allDescendants) do
        local name = obj.Name
        local num = extractNumber(name)
        
        -- Cek apakah ini checkpoint berdasarkan pattern atau lokasi
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
            if cframe then
                local checkpointName = name
                local checkpointNum = num or 0
                
                -- Simpan ke cache dengan nama asli sebagai key
                checkpointCache[checkpointName] = {
                    CFrame = cframe,
                    Name = checkpointName,
                    Number = checkpointNum,
                    Object = obj
                }
                
                -- Tambahkan ke list untuk sorting
                table.insert(checkpointList, {
                    Name = checkpointName,
                    Number = checkpointNum,
                    CFrame = cframe
                })
            end
        end
    end
    
    -- Sort berdasarkan nomor
    table.sort(checkpointList, function(a, b)
        if a.Number == b.Number then
            return a.Name < b.Name
        end
        return a.Number < b.Number
    end)
    
    local endTime = tick()
    local foundCount = #checkpointList
    
    print(string.format("Found %d checkpoints in %.2f seconds", foundCount, endTime - startTime))
    
    return foundCount > 0
end

-- Fungsi untuk teleport ke checkpoint dengan CFrame yang sudah di-cache
local function teleportToCheckpoint(checkpointData)
    if not checkpointData or not checkpointData.CFrame then
        warn("Checkpoint data tidak valid!")
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
    
    -- Teleport dengan offset ke atas untuk menghindari stuck di ground
    local targetCFrame = checkpointData.CFrame
    local offset = Vector3.new(0, 5, 0)
    
    -- Cek apakah ada part di bawah untuk menentukan offset yang tepat
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

-- Fungsi untuk membuat UI dengan checkpoint yang ditemukan
local function createGUI()
    local success, err = pcall(function()
        local playerGui = player:WaitForChild("PlayerGui")
        
        -- Hapus GUI lama jika ada
        local oldGui = playerGui:FindFirstChild("CheckpointTeleportGUI")
        if oldGui then
            oldGui:Destroy()
        end
        
        -- Scan checkpoint terlebih dahulu
        if not scanAllCheckpoints() then
            warn("Tidak ada checkpoint ditemukan di map!")
            return nil
        end
        
        -- Membuat ScreenGui
        local screenGui = Instance.new("ScreenGui")
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
        local titleText = Instance.new("TextLabel")
        titleText.Name = "TitleText"
        titleText.Size = UDim2.new(1, -100, 1, 0)
        titleText.Position = UDim2.new(0, 15, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = string.format("Checkpoints (%d)", #checkpointList)
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
            checkpointCache = {}
            checkpointList = {}
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
        local scrollingFrame = Instance.new("ScrollingFrame")
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
        
        -- Fungsi untuk membuat button checkpoint
        local function createCheckpointButton(index, checkpointData)
            local button = Instance.new("TextButton")
            button.Name = "Cp_" .. index
            button.LayoutOrder = index
            button.Size = UI_CONFIG.Button.Size
            button.BackgroundColor3 = UI_CONFIG.Button.BackgroundColor
            button.BorderSizePixel = 0
            button.Text = checkpointData.Name
            button.TextColor3 = UI_CONFIG.Button.TextColor
            button.TextSize = 15
            button.Font = Enum.Font.Gotham
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.Parent = scrollingFrame
            
            -- Padding untuk text
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
            
            -- Click event untuk teleport
            button.MouseButton1Click:Connect(function()
                local success = teleportToCheckpoint(checkpointData)
                
                if success then
                    -- Visual feedback
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
        end
        
        -- Membuat buttons untuk semua checkpoint yang ditemukan
        for i, checkpointData in ipairs(checkpointList) do
            createCheckpointButton(i, checkpointData)
        end
        
        -- Update canvas size ketika layout berubah
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
        end)
        
        -- Drag functionality untuk main frame
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
        
        return screenGui
    end)
    
    if not success then
        warn("Error membuat GUI: " .. tostring(err))
        return nil
    end
end

-- Handler untuk character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- Inisialisasi
if character then
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Membuat GUI
local gui = createGUI()

if gui then
    print("✓ Checkpoint Teleport GUI berhasil dibuat!")
    print("✓ " .. #checkpointList .. " checkpoint ditemukan di map")
    print("Gunakan GUI untuk memilih checkpoint dan teleport ke lokasi tersebut.")
    print("Klik tombol X untuk menutup GUI.")
else
    warn("✗ Gagal membuat Checkpoint Teleport GUI!")
end
