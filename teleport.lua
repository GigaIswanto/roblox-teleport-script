-- 🚀 Static 1-700 Checkpoints Teleport

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Reset GUI lama
local oldGui = player:FindFirstChild("CheckpointTeleportGUI")
if oldGui then oldGui:Destroy() end
getgenv().CheckpointTeleportLoaded = true

-- ======= GENERATE LIST 1-700 =======
local checkpoints = {}
for i = 1, 700 do
    table.insert(checkpoints, {name = "Checkpoint"..i, position = Vector3.new(0,0,0)})
end

-- ======= GUI =======
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTeleportGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 420)
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
title.Text = "🏔️ Checkpoints 1-700"
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
    for _, data in ipairs(checkpoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,30)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,62)
        btn.TextColor3 = Color3.fromRGB(235,235,235)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = data.name
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

        -- Teleport function
        btn.MouseButton1Click:Connect(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(data.position + Vector3.new(0,3,0))
            end
        end)
    end
end

refreshGUI()
print("✅ Static 1-700 Checkpoints Teleport Loaded")
