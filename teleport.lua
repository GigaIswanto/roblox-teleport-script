-- ✅ Dynamic Checkpoint Teleport | Final Version
-- Responsive, Draggable, Auto-Reset + Close Button
-- GitHub Raw Ready 

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ================= RESET GUI =================
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end

if getgenv().CheckpointTeleportLoaded then
    -- reset listener jika ada
    getgenv().CheckpointTeleportLoaded = false
end
getgenv().CheckpointTeleportLoaded = true

-- ================= STORAGE =================
local checkpoints = {}
local KEYWORDS = {"checkpoint","check","cp","spawn","save","respawn","stage","level"}

-- ================= HELPERS =================
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function getPosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local part = obj.PrimaryPart
            or obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChildWhichIsA("BasePart")
        return part and part.Position
    end
end

local function nameMatch(name)
    name = name:lower()
    for _, k in ipairs(KEYWORDS) do
        if name:find(k,1,true) then return true end
    end
end

local function hasVisualMarker(obj)
    return obj:FindFirstChildWhichIsA("BillboardGui", true)
        or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function isCheckpoint(obj)
    if obj:IsA("SpawnLocation") then return true end
    if CollectionService:HasTag(obj,"Checkpoint") or CollectionService:HasTag(obj,"CP") then return true end
    if obj:GetAttribute("IsCheckpoint") == true then return true end
    if hasVisualMarker(obj) then return true end

    -- fallback by name + size
    if obj:IsA("BasePart") and nameMatch(obj.Name) and obj.Size.Magnitude < 100 then return true end
    if obj:IsA("Model") and nameMatch(obj.Name) then return true end

    return false
end

local function register(obj)
    if checkpoints[obj] then return end
    if not isCheckpoint(obj) then return end
    local pos = getPosition(obj)
    if pos then checkpoints[obj] = {name=obj.Name, position=pos} end
end

local function unregister(obj)
    checkpoints[obj] = nil
end

-- INITIAL SCAN
for _, obj in ipairs(Workspace:GetDescendants()) do register(obj) end
Workspace.DescendantAdded:Connect(register)
Workspace.DescendantRemoving:Connect(unregister)

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,320,0,420)
main.Position = UDim2.new(0.7,0,0.3,0)
main.BackgroundColor3 = Color3.fromRGB(28,28,32)
main.BorderSizePixel = 0
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
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "📍 Checkpoint Teleport"
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
closeBtn.BorderSizePixel = 0
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

-- REFRESH GUI
local function refreshGUI()
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, data in pairs(checkpoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,38)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,62)
        btn.TextColor3 = Color3.fromRGB(235,235,235)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 15
        btn.Text = data.name
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

        btn.MouseButton1Click:Connect(function()
            getHRP().CFrame = CFrame.new(data.position + Vector3.new(0,3,0))
        end)
    end
end

-- AUTO REFRESH EVERY 1s
task.spawn(function()
    while task.wait(1) do
        refreshGUI()
    end
end)

print("✅ Checkpoint Teleport Loaded | GUI reset enabled")
