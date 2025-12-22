-- 🚀 Full Map Checkpoint Teleport GUI
-- Detect all checkpoints globally - Optimized for 700+ checkpoints
-- Draggable, responsive, with reliable teleport system

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Reset old GUI
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end
getgenv().CheckpointTeleportLoaded = true

-- Storage
local checkpoints = {}
local checkpointMap = {} -- Map nama -> data untuk quick lookup
local needsRefresh = false

-- Helper: Get position from any object type
local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position, obj
    elseif obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position, part
        end
    end
    
    -- Deep search untuk BasePart di dalam objek
    for _, descendant in ipairs(obj:GetDescendants()) do
        if descendant:IsA("BasePart") then
            return descendant.Position, descendant
        end
    end
    
    return nil, nil
end

-- Check if object name matches checkpoint pattern
local function isCheckpointName(name)
    name = name:lower()
    
    -- Pattern yang lebih spesifik berdasarkan screenshot
    if name:match("^checkpoint%d+$") then return true end
    if name:match("^teleportcp%d+$") then return true end
    if name:match("^cp%d+$") then return true end
    
    -- Pattern dengan underscore
    if name:match("^checkpoint_%d+$") then return true end
    if name:match("^teleportcp_%d+$") then return true end
    
    -- Pattern lebih fleksibel
    if name:match("checkpoint") and name:match("%d+") then return true end
    if name:match("teleportcp") and name:match("%d+") then return true end
    
    return false
end

-- Register checkpoint
local function registerCheckpoint(obj)
    if not obj or not obj.Parent then return end
    
    local name = obj.Name
    if not isCheckpointName(name) then return end
    
    local pos, part = getPosition(obj)
    if not pos then return end
    
    -- Skip jika sudah ada dengan nama yang sama
    if checkpointMap[name] then return end
    
    local data = {
        name = name,
        obj = obj,
        part = part,
        position = pos
    }
    
    checkpoints[obj] = data
    checkpointMap[name] = data
    
    print("✅ Found:", name, "| Type:", obj.ClassName, "| Pos:", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
end

-- Aggressive scan: Scan semua BasePart dan Model di Workspace
local function scanAllCheckpoints()
    print("🔍 Scanning all objects in Workspace...")
    
    local scanned = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        scanned = scanned + 1
        -- Check jika objek itu sendiri adalah checkpoint
        if obj:IsA("BasePart") or obj:IsA("Model") then
            registerCheckpoint(obj)
        end
    end
    
    print("📊 Scanned", scanned, "objects")
    
    local count = 0
    for _ in pairs(checkpoints) do count = count + 1 end
    print("✅ Total checkpoints found:", count)
    
    return count
end

-- Fallback: Cari checkpoint secara manual berdasarkan nama
local function findCheckpointByName(name)
    -- Coba berbagai variasi nama
    local variations = {
        name,
        "Checkpoint" .. name:match("%d+"),
        "TeleportCp" .. name:match("%d+"),
        "CP" .. name:match("%d+"),
        name:gsub("checkpoint", "Checkpoint"),
        name:gsub("teleportcp", "TeleportCp")
    }
    
    for _, varName in ipairs(variations) do
        local found = Workspace:FindFirstChild(varName, true)
        if found then
            registerCheckpoint(found)
            return found
        end
    end
    
    return nil
end

-- Generate checkpoint list dari 1-700 sebagai fallback
local function generateStaticCheckpoints()
    print("🔄 Generating static checkpoint list (1-700)...")
    
    for i = 1, 700 do
        local names = {
            "Checkpoint" .. i,
            "TeleportCp" .. i,
            "CP" .. i,
            "checkpoint" .. i,
            "teleportcp" .. i,
            "cp" .. i
        }
        
        for _, name in ipairs(names) do
            local found = Workspace:FindFirstChild(name, true)
            if found then
                registerCheckpoint(found)
            end
        end
    end
    
    local count = 0
    for _ in pairs(checkpoints) do count = count + 1 end
    print("📊 Static scan found:", count, "checkpoints")
end

-- Reliable teleport function
local function teleportToCheckpoint(data)
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
    
    -- Method 1: Teleport ke posisi yang sudah disimpan
    if data.position then
        hrp.CFrame = CFrame.new(data.position + Vector3.new(0, 3, 0))
        print("✅ Teleported to:", data.name, "at", data.position)
        return true
    end
    
    -- Method 2: Cari ulang objek checkpoint
    if data.obj and data.obj.Parent then
        local pos, part = getPosition(data.obj)
        if pos then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            print("✅ Teleported to:", data.name, "at", pos)
            return true
        end
    end
    
    -- Method 3: Cari berdasarkan nama
    local found = findCheckpointByName(data.name)
    if found then
        local pos, part = getPosition(found)
        if pos then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            print("✅ Teleported to:", data.name, "at", pos)
            return true
        end
    end
    
    print("❌ Failed to teleport to:", data.name)
    return false
end

-- Initial scan
scanAllCheckpoints()

-- Retry scan dengan static generation
task.spawn(function()
    task.wait(1)
    generateStaticCheckpoints()
    needsRefresh = true
end)

-- Monitor untuk checkpoint baru
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    registerCheckpoint(obj)
    needsRefresh = true
end)

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 350, 0, 500)
main.Position = UDim2.new(0.7, 0, 0.3, 0)
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
title.Text = "🏔️ Checkpoints"
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
    print("🔄 Manual refresh triggered...")
    scanAllCheckpoints()
    generateStaticCheckpoints()
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

-- SCROLL FRAME
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Helper: Extract number from checkpoint name
local function extractNumber(name)
    local num = name:match("%d+")
    return num and tonumber(num) or 999999
end

-- REFRESH GUI
local function refreshGUI()
    -- Clear existing buttons
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    -- Convert to array and sort
    local checkpointList = {}
    for _, data in pairs(checkpoints) do
        table.insert(checkpointList, data)
    end
    
    -- Sort by number
    table.sort(checkpointList, function(a, b)
        local numA = extractNumber(a.name)
        local numB = extractNumber(b.name)
        if numA == numB then
            return a.name < b.name
        end
        return numA < numB
    end)
    
    -- Create buttons
    for _, data in ipairs(checkpointList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        btn.TextColor3 = Color3.fromRGB(235, 235, 235)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = data.name .. " | " .. data.obj.ClassName
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        -- Hover effect
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        end)
        
        -- Teleport on click
        btn.MouseButton1Click:Connect(function()
            teleportToCheckpoint(data)
        end)
    end
    
    -- Update title
    local count = #checkpointList
    title.Text = "🏔️ Checkpoints (" .. count .. ")"
end

-- Initial refresh
refreshGUI()

-- Auto refresh
task.spawn(function()
    while task.wait(2) do
        if needsRefresh then
            refreshGUI()
            needsRefresh = false
        end
    end
end)

print("✅ Full Map Checkpoint Teleport Loaded")
print("💡 Tips: Click refresh button if checkpoints are missing")
