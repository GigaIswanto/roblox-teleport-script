-- Roblox Checkpoint Teleport Script untuk Delta Executor
-- Script ini membuat GUI scrollable dengan checkpoint Cp1 sampai Cp700
-- Klik checkpoint untuk teleport ke lokasi tersebut

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Konfigurasi UI
local UI_CONFIG = {
    MainFrame = {
        Size = UDim2.new(0, 400, 0, 600),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor = Color3.fromRGB(25, 25, 30),
        BorderSize = 0
    },
    TitleBar = {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor = Color3.fromRGB(35, 35, 45)
    },
    ScrollFrame = {
        Size = UDim2.new(1, -20, 1, -100),
        Position = UDim2.new(0, 10, 0, 70),
        BackgroundColor = Color3.fromRGB(20, 20, 25),
        BorderSize = 0
    },
    Button = {
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor = Color3.fromRGB(40, 40, 50),
        HoverColor = Color3.fromRGB(50, 120, 200),
        TextColor = Color3.fromRGB(255, 255, 255)
    }
}

-- Fungsi untuk mencari checkpoint di workspace
local function findCheckpoint(checkpointName)
    -- Cari di berbagai lokasi umum
    local searchLocations = {
        Workspace,
        Workspace:FindFirstChild("Checkpoints"),
        Workspace:FindFirstChild("Checkpoint"),
        Workspace:FindFirstChild("CP"),
        Workspace:FindFirstChild("Spawn"),
        Workspace:FindFirstChild("Spawns")
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            local checkpoint = location:FindFirstChild(checkpointName, true)
            if checkpoint then
                -- Jika ditemukan Part/BasePart, return CFrame-nya
                if checkpoint:IsA("BasePart") then
                    return checkpoint.CFrame
                -- Jika ditemukan Model, cari HumanoidRootPart atau PrimaryPart
                elseif checkpoint:IsA("Model") then
                    local part = checkpoint:FindFirstChild("HumanoidRootPart") or 
                                 checkpoint:FindFirstChild("PrimaryPart") or
                                 checkpoint:FindFirstChildOfClass("BasePart")
                    if part then
                        return part.CFrame
                    end
                end
            end
        end
    end
    
    -- Jika tidak ditemukan, cari dengan pattern matching di seluruh workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == checkpointName then
            if obj:IsA("BasePart") then
                return obj.CFrame
            elseif obj:IsA("Model") then
                local part = obj:FindFirstChild("HumanoidRootPart") or 
                             obj:FindFirstChild("PrimaryPart") or
                             obj:FindFirstChildOfClass("BasePart")
                if part then
                    return part.CFrame
                end
            end
        end
    end
    
    return nil
end

-- Fungsi untuk teleport dengan smooth animation
local function teleportToCheckpoint(checkpointName)
    local checkpointCFrame = findCheckpoint(checkpointName)
    
    if not checkpointCFrame then
        warn("Checkpoint " .. checkpointName .. " tidak ditemukan!")
        return false
    end
    
    -- Update character reference jika perlu
    if not character or not character.Parent then
        character = player.Character
        if character then
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        else
            warn("Character tidak tersedia!")
            return false
        end
    end
    
    -- Teleport langsung (lebih reliable untuk mountain maps)
    humanoidRootPart.CFrame = checkpointCFrame + Vector3.new(0, 5, 0) -- Offset sedikit ke atas
    
    print("Teleported ke " .. checkpointName)
    return true
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
        
        -- Rounded corners untuk main frame
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 12)
        mainCorner.Parent = mainFrame
        
        -- Shadow effect
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 10, 1, 10)
        shadow.Position = UDim2.new(0, -5, 0, -5)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.7
        shadow.ZIndex = mainFrame.ZIndex - 1
        shadow.Parent = mainFrame
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 12)
        shadowCorner.Parent = shadow
        
        -- Title Bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UI_CONFIG.TitleBar.Size
        titleBar.BackgroundColor3 = UI_CONFIG.TitleBar.BackgroundColor
        titleBar.BorderSizePixel = 0
        titleBar.Parent = mainFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 12)
        titleCorner.Parent = titleBar
        
        -- Title Text
        local titleText = Instance.new("TextLabel")
        titleText.Name = "TitleText"
        titleText.Size = UDim2.new(1, -60, 1, 0)
        titleText.Position = UDim2.new(0, 15, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Text = "Checkpoint Teleport"
        titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleText.TextSize = 20
        titleText.Font = Enum.Font.GothamBold
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar
        
        -- Close Button (X)
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 40, 0, 40)
        closeButton.Position = UDim2.new(1, -45, 0, 5)
        closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeButton.BorderSizePixel = 0
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextSize = 24
        closeButton.Font = Enum.Font.GothamBold
        closeButton.Parent = titleBar
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeButton
        
        -- Hover effect untuk close button
        closeButton.MouseEnter:Connect(function()
            local tween = TweenService:Create(
                closeButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}
            )
            tween:Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            local tween = TweenService:Create(
                closeButton,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}
            )
            tween:Play()
        end)
        
        -- Scroll Frame
        local scrollFrame = Instance.new("Frame")
        scrollFrame.Name = "ScrollFrame"
        scrollFrame.Size = UI_CONFIG.ScrollFrame.Size
        scrollFrame.Position = UI_CONFIG.ScrollFrame.Position
        scrollFrame.BackgroundColor3 = UI_CONFIG.ScrollFrame.BackgroundColor
        scrollFrame.BorderSizePixel = UI_CONFIG.ScrollFrame.BorderSize
        scrollFrame.ClipsDescendants = true
        scrollFrame.Parent = mainFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = scrollFrame
        
        -- Scrolling Frame
        local scrollingFrame = Instance.new("ScrollingFrame")
        scrollingFrame.Name = "ScrollingFrame"
        scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
        scrollingFrame.BackgroundTransparency = 1
        scrollingFrame.BorderSizePixel = 0
        scrollingFrame.ScrollBarThickness = 8
        scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
        scrollingFrame.Parent = scrollFrame
        
        -- UI List Layout
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.Name
        listLayout.Padding = UDim.new(0, 8)
        listLayout.Parent = scrollingFrame
        
        -- Padding untuk list
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 8)
        padding.PaddingBottom = UDim.new(0, 8)
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        padding.Parent = scrollingFrame
        
        -- Membuat buttons untuk setiap checkpoint
        local buttonHeight = 40
        local paddingValue = 8
        local totalButtons = 700
        local totalHeight = (buttonHeight + paddingValue) * totalButtons + paddingValue * 2
        
        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        
        -- Fungsi untuk membuat button checkpoint
        local function createCheckpointButton(checkpointNumber)
            local button = Instance.new("TextButton")
            button.Name = "Cp" .. checkpointNumber
            button.Size = UI_CONFIG.Button.Size
            button.BackgroundColor3 = UI_CONFIG.Button.BackgroundColor
            button.BorderSizePixel = 0
            button.Text = "CheckpointCp" .. checkpointNumber
            button.TextColor3 = UI_CONFIG.Button.TextColor
            button.TextSize = 16
            button.Font = Enum.Font.Gotham
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.Parent = scrollingFrame
            
            -- Padding untuk text
            local textPadding = Instance.new("UIPadding")
            textPadding.PaddingLeft = UDim.new(0, 15)
            textPadding.Parent = button
            
            -- Rounded corners
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 8)
            buttonCorner.Parent = button
            
            -- Hover effect
            local originalColor = button.BackgroundColor3
            button.MouseEnter:Connect(function()
                local tween = TweenService:Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = UI_CONFIG.Button.HoverColor}
                )
                tween:Play()
            end)
            
            button.MouseLeave:Connect(function()
                local tween = TweenService:Create(
                    button,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundColor3 = originalColor}
                )
                tween:Play()
            end)
            
            -- Click event untuk teleport
            button.MouseButton1Click:Connect(function()
                local checkpointName = "CheckpointCp" .. checkpointNumber
                teleportToCheckpoint(checkpointName)
                
                -- Visual feedback
                button.Text = "✓ " .. button.Text
                wait(0.5)
                button.Text = "CheckpointCp" .. checkpointNumber
            end)
        end
        
        -- Membuat semua buttons
        for i = 1, 700 do
            createCheckpointButton(i)
        end
        
        -- Update canvas size ketika layout berubah
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
        end)
        
        -- Close button functionality
        closeButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
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
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
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
    print("Checkpoint Teleport GUI berhasil dibuat!")
    print("Gunakan GUI untuk memilih checkpoint dan teleport ke lokasi tersebut.")
    print("Klik tombol X untuk menutup GUI.")
else
    warn("Gagal membuat Checkpoint Teleport GUI!")
end

