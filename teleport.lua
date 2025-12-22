-- 🚀 Static Checkpoint Teleport GUI

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Reset old GUI
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end
getgenv().CheckpointTeleportLoaded = true

-- Storage untuk checkpoint data
local checkpointData = {} -- Map: number -> {name, obj, position}

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

-- Find checkpoint by number
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
                return {
                    name = name,
                    obj = found,
                    position = pos
                }
            end
        end
    end
    
    return nil
end

-- Scan semua checkpoint dari 1-700
local function scanAllCheckpoints()
    print("🔍 Scanning TeleportCp1 to TeleportCp700...")
    
    local foundCount = 0
    for i = 1, 700 do
        local data = findCheckpoint(i)
        if data then
            checkpointData[i] = data
            foundCount = foundCount + 1
            if foundCount <= 10 or foundCount % 50 == 0 then
                print("✅ Found:", data.name, "at", math.floor(data.position.X), math.floor(data.position.Y), math.floor(data.position.Z))
            end
        end
    end
    
    print("📊 Total checkpoints found:", foundCount, "out of 700")
    return foundCount
end

-- Reliable teleport function
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
    
    local data = checkpointData[num]
    
    -- Method 1: Use saved position
    if data and data.position then
        hrp.CFrame = CFrame.new(data.position + Vector3.new(0, 3, 0))
        print("✅ Teleported to TeleportCp" .. num)
        return true
    end
    
    -- Method 2: Find checkpoint again
    local found = findCheckpoint(num)
    if found and found.position then
        checkpointData[num] = found -- Update cache
        hrp.CFrame = CFrame.new(found.position + Vector3.new(0, 3, 0))
        print("✅ Teleported to TeleportCp" .. num)
        return true
    end
    
    print("❌ TeleportCp" .. num .. " not found!")
    return false
end

-- Initial scan
scanAllCheckpoints()

-- Retry scan setelah beberapa detik
task.spawn(function()
    task.wait(3)
    print("🔄 Retry scan...")
    scanAllCheckpoints()
end)

-- Monitor untuk checkpoint baru
Workspace.DescendantAdded:Connect(function(obj)
    local name = obj.Name:lower()
    if name:match("teleportcp") or name:match("checkpoint") then
        local num = tonumber(name:match("%d+"))
        if num and num >= 1 and num <= 700 then
            task.wait(0.2)
            local data = findCheckpoint(num)
            if data then
                checkpointData[num] = data
            end
        end
    end
end)

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

-- REFRESH BUTTON
local refreshBtn = Instance.new("TextButton", header)
refreshBtn.Size = UDim2.new(0, 30, 0, 30)
refreshBtn.Position = UDim2.new(1, -75, 0, 10)
refreshBtn.Text = "🔄"
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 16
refreshBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
refreshBtn.MouseButton1Click:Connect(function()
    print("🔄 Refreshing checkpoints...")
    scanAllCheckpoints()
    refreshGUI()
end)

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
searchBox.Size = UDim2.new(0, 100, 0, 25)
searchBox.Position = UDim2.new(1, -110, 0, 12)
searchBox.PlaceholderText = "Search..."
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
    local foundCount = 0
    
    -- Create buttons untuk 1-700
    for i = 1, 700 do
        local data = checkpointData[i]
        local displayName = "TeleportCp" .. i
        
        -- Filter berdasarkan search
        if searchText == "" or displayName:lower():find(searchText, 1, true) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 36)
            
            -- Warna berbeda untuk checkpoint yang ditemukan vs tidak ditemukan
            if data then
                btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
                btn.TextColor3 = Color3.fromRGB(235, 235, 235)
                btn.Text = displayName .. " ✅"
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                btn.TextColor3 = Color3.fromRGB(150, 150, 150)
                btn.Text = displayName .. " ❌"
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
                if data then
                    btn.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                end
            end)
            btn.MouseLeave:Connect(function()
                if data then
                    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                end
            end)
            
            -- Teleport on click (hanya jika ditemukan)
            btn.MouseButton1Click:Connect(function()
                if data then
                    teleportToCheckpoint(i)
                else
                    -- Coba cari lagi
                    local found = findCheckpoint(i)
                    if found then
                        checkpointData[i] = found
                        refreshGUI()
                        teleportToCheckpoint(i)
                    else
                        print("❌ TeleportCp" .. i .. " tidak ditemukan!")
                    end
                end
            end)
            
            foundCount = foundCount + 1
        end
    end
    
    -- Update title
    local totalFound = 0
    for _ in pairs(checkpointData) do totalFound = totalFound + 1 end
    title.Text = "🏔️ Checkpoints (" .. totalFound .. "/700)"
end

-- Search functionality
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshGUI()
end)

-- Initial refresh
refreshGUI()

-- Auto refresh setiap 5 detik untuk update checkpoint yang baru muncul
task.spawn(function()
    while task.wait(5) do
        local beforeCount = 0
        for _ in pairs(checkpointData) do beforeCount = beforeCount + 1 end
        
        scanAllCheckpoints()
        
        local afterCount = 0
        for _ in pairs(checkpointData) do afterCount = afterCount + 1 end
        
        if afterCount > beforeCount then
            refreshGUI()
        end
    end
end)

print("✅ Static Checkpoint Teleport Loaded (TeleportCp1-700)")
print("💡 Use search box to filter checkpoints")
