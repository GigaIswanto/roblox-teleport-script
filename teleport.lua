-- 🚀 Full Map Checkpoint Teleport GUI
-- Detect all checkpoints globally - Optimized for 700+ checkpoints
-- Draggable, responsive, with debug info

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local player = Players.LocalPlayer

-- Reset old GUI
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end
getgenv().CheckpointTeleportLoaded = true

-- Storage dengan unique ID untuk tracking
local checkpoints = {}
local checkpointIds = {} -- Untuk tracking unique checkpoints
local needsRefresh = false -- Flag untuk refresh GUI

-- Helper: get position from BasePart or Model
local function getPosition(obj)
    if obj:IsA("BasePart") then 
        return obj.Position 
    end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        return part and part.Position
    end
    -- Coba cari di dalam model jika ada BasePart
    if obj:IsA("Folder") or obj:IsA("Model") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
    end
    return nil
end

-- Check if object is checkpoint - EXPANDED PATTERN MATCHING
local function isCheckpoint(obj)
    local name = obj.Name:lower() -- Case insensitive
    
    -- Pattern yang lebih luas untuk menangkap berbagai variasi
    if name:match("checkpoint") or name:match("teleportcp") or name:match("teleport") then
        -- Cek apakah mengandung angka atau kata kunci checkpoint
        if name:match("%d+") or name:match("cp") or name:match("checkpoint") then
            return true
        end
    end
    
    -- Pattern spesifik yang lebih fleksibel
    if name:match("^checkpoint%d+") then return true end
    if name:match("^teleportcp%d+") then return true end
    if name:match("^cp%d+") then return true end
    if name:match("checkpoint_%d+") then return true end
    if name:match("teleport_%d+") then return true end
    if name:match("^checkpoint") and name:match("%d+") then return true end
    
    return false
end

-- Generate unique ID untuk checkpoint
local function getCheckpointId(obj)
    local pos = getPosition(obj)
    if pos then
        return obj.Name .. "_" .. tostring(math.floor(pos.X)) .. "_" .. tostring(math.floor(pos.Y)) .. "_" .. tostring(math.floor(pos.Z))
    end
    return obj.Name .. "_" .. tostring(obj:GetFullName())
end

-- Register checkpoint dengan duplicate checking
local function register(obj)
    if not isCheckpoint(obj) then return end
    
    local pos = getPosition(obj)
    if not pos then 
        -- Retry untuk objek yang mungkin belum siap
        task.wait(0.1)
        pos = getPosition(obj)
        if not pos then return end
    end
    
    local id = getCheckpointId(obj)
    
    -- Skip jika sudah terdaftar
    if checkpointIds[id] then return end
    
    checkpointIds[id] = true
    checkpoints[obj] = {
        name = obj.Name, 
        obj = obj, 
        position = pos,
        id = id
    }
    print("✅ Detected checkpoint:", obj.Name, "| Type:", obj.ClassName, "| Position:", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
end

-- Deep scan function untuk scan rekursif yang lebih agresif
local function deepScan(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        register(obj)
    end
end

-- Scan semua lokasi yang mungkin
local function scanAllLocations()
    print("🔍 Scanning Workspace...")
    deepScan(Workspace)
    
    -- Scan ReplicatedStorage jika ada
    pcall(function()
        if ReplicatedStorage then
            print("🔍 Scanning ReplicatedStorage...")
            deepScan(ReplicatedStorage)
        end
    end)
    
    -- Scan ServerStorage jika bisa diakses (biasanya tidak bisa dari client, tapi coba saja)
    pcall(function()
        if ServerStorage then
            print("🔍 Scanning ServerStorage...")
            deepScan(ServerStorage)
        end
    end)
    
    local count = 0
    for _ in pairs(checkpoints) do count = count + 1 end
    print("📊 Total checkpoints detected:", count)
end

-- Initial scan dengan retry mechanism
scanAllLocations()

-- Retry scan beberapa kali untuk menangkap checkpoint yang dimuat dinamis
task.spawn(function()
    for i = 1, 5 do
        task.wait(2) -- Tunggu 2 detik antara scan
        print("🔄 Retry scan #" .. i .. "...")
        local beforeCount = 0
        for _ in pairs(checkpoints) do beforeCount = beforeCount + 1 end
        scanAllLocations()
        local afterCount = 0
        for _ in pairs(checkpoints) do afterCount = afterCount + 1 end
        if afterCount > beforeCount then
            print("✨ Found " .. (afterCount - beforeCount) .. " new checkpoints!")
            needsRefresh = true
        end
    end
    local finalCount = 0
    for _ in pairs(checkpoints) do finalCount = finalCount + 1 end
    print("✅ Scan completed! Total checkpoints:", finalCount)
end)

-- Monitor untuk checkpoint baru
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1) -- Tunggu sebentar untuk memastikan objek sudah ter-load
    local id = getCheckpointId(obj)
    local wasNew = checkpointIds[id] == nil
    register(obj)
    if wasNew and checkpointIds[id] then
        needsRefresh = true
    end
end)

-- Auto refresh GUI ketika ada checkpoint baru
task.spawn(function()
    while task.wait(0.5) do
        if needsRefresh then
            refreshGUI()
            needsRefresh = false
        end
    end
end)

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.7,0,0.3,0)
main.BackgroundColor3 = Color3.fromRGB(28,28,32)
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)

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
header.Size = UDim2.new(1,0,0,44)
header.BackgroundColor3 = Color3.fromRGB(40,40,46)
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "🏔️ Checkpoints"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(230,230,230)

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,7)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(220,220,220)
closeBtn.BackgroundColor3 = Color3.fromRGB(70,70,75)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    getgenv().CheckpointTeleportLoaded = false
end)

-- SCROLL FRAME
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.new(0,10,0,54)
scroll.Size = UDim2.new(1,-20,1,-64)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10)
end)

-- Helper: Extract number from checkpoint name untuk sorting
local function extractNumber(name)
    local num = name:match("%d+")
    return num and tonumber(num) or 999999
end

-- REFRESH GUI dengan sorting dan optimasi
local function refreshGUI()
    -- Clear existing buttons
    for _, c in ipairs(scroll:GetChildren()) do 
        if c:IsA("TextButton") then c:Destroy() end 
    end
    
    -- Convert checkpoints dict ke array dan sort
    local checkpointList = {}
    for _, data in pairs(checkpoints) do
        table.insert(checkpointList, data)
    end
    
    -- Sort berdasarkan nomor checkpoint
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
        btn.Size = UDim2.new(1,0,0,38)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,62)
        btn.TextColor3 = Color3.fromRGB(235,235,235)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 15
        btn.Text = data.name .. " | Type: " .. data.obj.ClassName
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

        -- Teleport function
        btn.MouseButton1Click:Connect(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(data.position + Vector3.new(0,3,0))
            end
            print("Teleporting to:", data.name, "Object Type:", data.obj.ClassName)
        end)
    end
    
    -- Update title dengan counter
    local count = #checkpointList
    title.Text = "🏔️ Checkpoints (" .. count .. ")"
end

-- Initial refresh
refreshGUI()

-- Auto refresh dengan interval yang lebih panjang untuk performa lebih baik
task.spawn(function()
    while task.wait(3) do -- Refresh setiap 3 detik, bukan 1 detik
        refreshGUI()
    end
end)

print("✅ Full Map Checkpoint Teleport Loaded")
