-- Dynamic Checkpoint Teleport with Modern UI
-- GitHub Raw Ready

if not game:IsLoaded() then game.Loaded:Wait() end
if getgenv().CheckpointTeleportLoaded then return end
getgenv().CheckpointTeleportLoaded = true

-- SERVICES
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- PLAYER ROOT
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

-- CHECKPOINT STORAGE
local checkpoints = {}

-- POSITION HELPER
local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local pp = obj.PrimaryPart
            or obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChildWhichIsA("BasePart")
        return pp and pp.Position
    end
end

-- VALID CHECKPOINT CHECK
local function isCheckpoint(obj)
    if obj:IsA("SpawnLocation") then return true end
    if CollectionService:HasTag(obj, "Checkpoint") or CollectionService:HasTag(obj, "CP") then return true end
    if obj:GetAttribute("IsCheckpoint") == true then return true end
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local text = (prompt.ActionText or ""):lower()
        if text:find("checkpoint") or text:find("spawn") or text:find("save") then return true end
    end
    return false
end

-- REGISTER & UNREGISTER CHECKPOINT
local function registerCheckpoint(obj)
    if checkpoints[obj] then return end
    if not isCheckpoint(obj) then return end
    local pos = getPosition(obj)
    if pos then checkpoints[obj] = {name = obj.Name, position = pos} end
end
local function unregisterCheckpoint(obj)
    checkpoints[obj] = nil
end

-- INITIAL SCAN & DYNAMIC UPDATE
for _, obj in ipairs(Workspace:GetDescendants()) do registerCheckpoint(obj) end
Workspace.DescendantAdded:Connect(registerCheckpoint)
Workspace.DescendantRemoving:Connect(unregisterCheckpoint)

-- ================= GUI =================

-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 450)
frame.Position = UDim2.new(1, -300, 0.5, -225)
frame.AnchorPoint = Vector2.new(1,0.5)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.Parent = gui

-- UICorner for rounded edges
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "📍 Checkpoints"
titleText.TextColor3 = Color3.fromRGB(220, 220, 220)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Refresh Button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 35, 0, 35)
refreshBtn.Position = UDim2.new(1, -40, 0, 2)
refreshBtn.BackgroundColor3 = Color3.fromRGB(70,70,75)
refreshBtn.Text = "⟳"
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.TextSize = 22
refreshBtn.TextColor3 = Color3.fromRGB(200,200,200)
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = titleBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = refreshBtn

refreshBtn.MouseButton1Click:Connect(function()
    -- Re-scan
    checkpoints = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do registerCheckpoint(obj) end
end)

-- Scrolling Frame for checkpoints
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scroll

-- AUTO UPDATE CanvasSize
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y + 10)
end)

-- ================= Refresh GUI =================
local function refreshGUI()
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, data in pairs(checkpoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 16
        btn.Text = data.name
        btn.Parent = scroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            local hrp = getHRP()
            hrp.CFrame = CFrame.new(data.position + Vector3.new(0,3,0))
        end)
    end
end

-- AUTO REFRESH EVERY 1s
task.spawn(function()
    while task.wait(1) do
        refreshGUI()
    end
end)

print("✅ Dynamic Checkpoint Teleport Loaded with Responsive UI")
