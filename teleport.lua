--[[ 
    CHECKPOINT TELEPORT SYSTEM (DELTA EXECUTOR SAFE)
    ✔ Persistent cache (getgenv)
    ✔ Full map scan
    ✔ Responsive UI
    ✔ Teleport nearest / unlocked
    ✔ Clean reset on re-execute
]]

-- ======================
-- CLEAN RESET
-- ======================
if _G.CP_TELEPORT_RUNNING then
    _G.CP_TELEPORT_RUNNING = false
    if _G.CP_GUI then
        _G.CP_GUI:Destroy()
    end
    task.wait(0.3)
end
_G.CP_TELEPORT_RUNNING = true

-- ======================
-- SERVICES
-- ======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ======================
-- MEMORY CACHE (PERSIST)
-- ======================
getgenv().CheckpointCache = getgenv().CheckpointCache or {
    unlocked = {},   -- [checkpointName] = true
    last = nil
}

local CACHE = getgenv().CheckpointCache

-- ======================
-- CHARACTER
-- ======================
local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- ======================
-- CHECKPOINT SCAN
-- ======================
local ALL_CP = {}

local function getCFrame(obj)
    if obj:IsA("BasePart") then return obj.CFrame end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if p then return p.CFrame end
    end
end

local function scanCheckpoints()
    table.clear(ALL_CP)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():match("cp") or obj.Name:lower():match("checkpoint") then
            local cf = getCFrame(obj)
            if cf then
                table.insert(ALL_CP, {
                    name = obj.Name,
                    cframe = cf,
                    unlocked = CACHE.unlocked[obj.Name] == true
                })
            end
        end
    end

    table.sort(ALL_CP, function(a,b)
        return a.name < b.name
    end)
end

-- ======================
-- TELEPORT
-- ======================
local function teleportTo(cf)
    local hrp = getHRP()
    hrp.CFrame = cf + Vector3.new(0,3,0)
end

local function teleportNearest()
    local hrp = getHRP()
    local nearest, dist

    for _, cp in ipairs(ALL_CP) do
        local d = (hrp.Position - cp.cframe.Position).Magnitude
        if not dist or d < dist then
            nearest = cp
            dist = d
        end
    end

    if nearest then
        teleportTo(nearest.cframe)
    end
end

-- ======================
-- DETECTION LOOP
-- ======================
task.spawn(function()
    while _G.CP_TELEPORT_RUNNING do
        local hrp = getHRP()
        for _, cp in ipairs(ALL_CP) do
            if not CACHE.unlocked[cp.name] then
                if (hrp.Position - cp.cframe.Position).Magnitude < 8 then
                    CACHE.unlocked[cp.name] = true
                    CACHE.last = cp.name
                    cp.unlocked = true
                end
            end
        end
        task.wait(0.25)
    end
end)

-- ======================
-- UI
-- ======================
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui
_G.CP_GUI = gui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.35,0.55)
frame.Position = UDim2.fromScale(0.5,0.5)
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.BackgroundColor3 = Color3.fromRGB(20,20,28)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-20,0,40)
title.Position = UDim2.new(0,10,0,10)
title.Text = "Checkpoint Teleport"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,40,0,40)
close.Position = UDim2.new(1,-50,0,10)
close.Text = "✕"
close.Font = Enum.Font.GothamBold
close.TextSize = 20
close.BackgroundColor3 = Color3.fromRGB(200,60,60)
Instance.new("UICorner", close)

close.MouseButton1Click:Connect(function()
    _G.CP_TELEPORT_RUNNING = false
    gui:Destroy()
end)

local list = Instance.new("ScrollingFrame", frame)
list.Size = UDim2.new(1,-20,1,-120)
list.Position = UDim2.new(0,10,0,60)
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 6
list.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,6)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)

local function refreshUI()
    list:ClearAllChildren()
    layout.Parent = list

    for _, cp in ipairs(ALL_CP) do
        if cp.unlocked then
            local b = Instance.new("TextButton", list)
            b.Size = UDim2.new(1,-10,0,36)
            b.Text = cp.name
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.BackgroundColor3 = Color3.fromRGB(45,45,60)
            b.TextColor3 = Color3.new(1,1,1)
            Instance.new("UICorner", b)

            b.MouseButton1Click:Connect(function()
                teleportTo(cp.cframe)
            end)
        end
    end
end

-- ======================
-- BUTTONS
-- ======================
local nearest = Instance.new("TextButton", frame)
nearest.Size = UDim2.new(0.48,0,0,40)
nearest.Position = UDim2.new(0.02,0,1,-50)
nearest.Text = "Teleport Nearest"
nearest.Font = Enum.Font.GothamBold
nearest.TextSize = 14
nearest.BackgroundColor3 = Color3.fromRGB(80,160,255)
Instance.new("UICorner", nearest)

nearest.MouseButton1Click:Connect(teleportNearest)

-- ======================
-- INIT
-- ======================
scanCheckpoints()
refreshUI()

print("✓ Checkpoint Teleport Loaded")
print("✓ Cached:", table.getn(CACHE.unlocked))
