-- 🚀 Static Checkpoint Teleport GUI 2

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Reset old GUI
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end
getgenv().CheckpointTeleportLoaded = true

-- Storage untuk checkpoint position (statis)
local checkpointPositions = {} -- Map: number -> Vector3 position

-- Helper: Get position from object
local function getPosition(obj)
    if not obj or not obj.Parent then return nil end
    
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position
        end
    end
    
    -- Deep search
    for _, descendant in ipairs(obj:GetDescendants()) do
        if descendant:IsA("BasePart") then
            return descendant.Position
        end
    end
    
    return nil
end

-- Find checkpoint by number (untuk pertama kali teleport)
local function findCheckpoint(num)
    local names = {
        "TeleportCp" .. num,
        "Checkpoint" .. num,
        "CP" .. num,
        "teleportcp" .. num,
        "checkpoint" .. num,
        "cp" .. num
    }
    
    for _, name in ipairs(names) do
        local found = Workspace:FindFirstChild(name, true)
        if found then
            local pos = getPosition(found)
            if pos then
                return pos
            end
        end
    end
    
    return nil
end

-- Smart teleport: Coba teleport ke posisi, jika berhasil simpan posisinya
local function teleportToCheckpoint(num)
    local character = player.Character
    if not character then
        print("❌ Character not found!")
        return false
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("❌ HumanoidRootPart not found!")
        return false
    end
    
    local targetPos = nil
    
    -- Method 1: Gunakan posisi yang sudah disimpan
    if checkpointPositions[num] then
        targetPos = checkpointPositions[num]
        print("📍 Using saved position for TeleportCp" .. num)
    else
        -- Method 2: Cari checkpoint dan ambil posisinya
        print("🔍 Searching for TeleportCp" .. num .. "...")
        targetPos = findCheckpoint(num)
        
        if targetPos then
            -- Simpan posisi untuk penggunaan berikutnya
            checkpointPositions[num] = targetPos
            print("✅ Found and saved TeleportCp" .. num .. " at", math.floor(targetPos.X), math.floor(targetPos.Y), math.floor(targetPos.Z))
        else
            print("❌ TeleportCp" .. num .. " not found!")
            return false
        end
    end
    
    -- Teleport ke posisi
    if targetPos then
        local currentPos = hrp.Position
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        
        -- Debug: Cek apakah teleport berhasil
        task.wait(0.1)
        local newPos = hrp.Position
        local distance = (newPos - targetPos).Magnitude
        
        if distance < 50 then -- Jika jarak kurang dari 50, berarti teleport berhasil
            print("✅ Successfully teleported to TeleportCp" .. num)
            -- Pastikan posisi tersimpan dengan benar
            if not checkpointPositions[num] then
                checkpointPositions[num] = targetPos
            end
            return true
        else
            print("⚠️ Teleport might have failed. Distance:", math.floor(distance))
            return false
        end
    end
    
    return false
end

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 380, 0, 550)
main.Position = UDim2.new(0.7, 0, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- DRAG
do
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- HEADER
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏔️ Checkpoints (1-700)"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(230, 230, 230)

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    getgenv().CheckpointTeleportLoaded = false
end)

-- SEARCH BOX
local searchBox = Instance.new("TextBox", header)
searchBox.Size = UDim2.new(0, 120, 0, 25)
searchBox.Position = UDim2.new(1, -160, 0, 12)
searchBox.PlaceholderText = "Search (1-700)..."
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
searchBox.BorderSizePixel = 0
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)

-- SCROLL FRAME
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- REFRESH GUI
local function refreshGUI()
    -- Clear existing buttons
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    local searchText = searchBox.Text:lower()
    
    -- Create buttons untuk 1-700
    for i = 1, 700 do
        local displayName = "TeleportCp" .. i
        
        -- Filter berdasarkan search
        if searchText == "" or displayName:lower():find(searchText, 1, true) or tostring(i):find(searchText, 1, true) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 36)
            
            -- Warna berbeda untuk checkpoint yang sudah pernah digunakan vs belum
            if checkpointPositions[i] then
                btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
                btn.TextColor3 = Color3.fromRGB(235, 235, 235)
                btn.Text = displayName .. " ✅"
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                btn.TextColor3 = Color3.fromRGB(150, 150, 150)
                btn.Text = displayName
            end
            
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            
            -- Padding untuk text
            local padding = Instance.new("UIPadding", btn)
            padding.PaddingLeft = UDim.new(0, 10)
            
            -- Hover effect
            btn.MouseEnter:Connect(function()
                if checkpointPositions[i] then
                    btn.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                end
            end)
            btn.MouseLeave:Connect(function()
                if checkpointPositions[i] then
                    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                end
            end)
            
            -- Teleport on click
            btn.MouseButton1Click:Connect(function()
                teleportToCheckpoint(i)
                -- Update button setelah teleport
                task.wait(0.2)
                if checkpointPositions[i] then
                    btn.Text = displayName .. " ✅"
                    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
                    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
                end
            end)
        end
    end
    
    -- Update title dengan jumlah checkpoint yang sudah digunakan
    local savedCount = 0
    for _ in pairs(checkpointPositions) do savedCount = savedCount + 1 end
    title.Text = "🏔️ Checkpoints (" .. savedCount .. "/700 saved)"
end

-- Search functionality
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshGUI()
end)

-- Initial refresh
refreshGUI()

-- Debug: Print saved positions saat script dimuat
task.spawn(function()
    task.wait(1)
    local savedCount = 0
    for _ in pairs(checkpointPositions) do savedCount = savedCount + 1 end
    if savedCount > 0 then
        print("📊 Loaded", savedCount, "saved checkpoint positions")
    else
        print("💡 No saved positions yet. Click any checkpoint to teleport and save its position!")
    end
end)

print("✅ Static Checkpoint Teleport Loaded (TeleportCp1-700)")
print("💡 Click any checkpoint to teleport. Position will be saved automatically!")
