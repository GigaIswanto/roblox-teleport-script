local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local p = Players.LocalPlayer
local pg = p:WaitForChild("PlayerGui")
local char = p.Character or p.CharacterAdded:Wait()
local rp = char:WaitForChild("HumanoidRootPart")
local old = pg:FindFirstChild("MountainTeleportGUI")
if old then old:Destroy() end

local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        if obj:FindFirstChild("HumanoidRootPart") then return obj.HumanoidRootPart.Position end
        local part = obj:FindFirstChildOfClass("BasePart")
        if part then return part.Position end
    end
    return nil
end

local function findCP()
    local cp, f = {}, {}
    local kw = {"checkpoint", "cp", "spawn", "teleport", "tp", "waypoint", "location", "point", "spot", "base", "camp", "station", "save", "respawn"}
    
    -- Keyword-based detection
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        local isCP = false
        for _, k in ipairs(kw) do
            if n:find(k, 1, true) then
                isCP = true
                break
            end
        end
        
        if isCP and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = getPos(obj)
            if pos then
                local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    table.insert(cp, {name = obj.Name, position = pos, object = obj})
                end
            end
        end
        
        -- BillboardGui detection
        if obj:IsA("BasePart") and obj:FindFirstChildOfClass("BillboardGui") then
            local pos = getPos(obj)
            if pos then
                local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    table.insert(cp, {name = obj.Name, position = pos, object = obj})
                end
            end
        end
        
        -- SurfaceGui detection
        if obj:IsA("BasePart") and obj:FindFirstChildOfClass("SurfaceGui") then
            local pos = getPos(obj)
            if pos then
                local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    table.insert(cp, {name = obj.Name, position = pos, object = obj})
                end
            end
        end
        
        -- ProximityPrompt detection
        if obj:IsA("ProximityPrompt") and obj.Parent then
            local pos = getPos(obj.Parent)
            if pos then
                local key = obj.Parent.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    local name = obj.ActionText ~= "" and obj.ActionText or obj.Parent.Name
                    table.insert(cp, {name = name, position = pos, object = obj.Parent})
                end
            end
        end
    end
    
    -- CollectionService tags detection
    local tags = {"Checkpoint", "Spawn", "Teleport", "Waypoint", "Location", "SavePoint"}
    for _, tag in ipairs(tags) do
        local success, tagged = pcall(function()
            return CollectionService:GetTagged(tag)
        end)
        if success and tagged then
            for _, obj in ipairs(tagged) do
                local pos = getPos(obj)
                if pos then
                    local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                    if not f[key] then
                        f[key] = true
                        table.insert(cp, {name = obj.Name, position = pos, object = obj})
                    end
                end
            end
        end
    end
    
    return cp
end

local locs = findCP()
if #locs == 0 then
    local s = Workspace:FindFirstChild("SpawnLocation")
    table.insert(locs, {name = "Spawn", position = s and s.Position or Vector3.new(0, 5, 0), object = s})
end

local function teleport(name, pos)
    if not rp or not rp.Parent then
        char = p.Character
        if char then
            rp = char:WaitForChild("HumanoidRootPart", 5)
        else
            return
        end
    end
    
    if not rp then return end
    
    -- Smooth teleportation with tween
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rp, tweenInfo, {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
    tween:Play()
    tween.Completed:Wait()
    rp.CFrame = CFrame.new(pos)
end

-- UI Creation
local sg = Instance.new("ScreenGui")
sg.Name = "MountainTeleportGUI"
sg.ResetOnSpawn = false
sg.DisplayOrder = 999
sg.IgnoreGuiInset = true
sg.Parent = pg

local mf = Instance.new("Frame")
mf.Name = "MainFrame"
mf.Size = UDim2.new(0, 400, 0, 600)
mf.Position = UDim2.new(1, -420, 0.5, -300)
mf.AnchorPoint = Vector2.new(0, 0.5)
mf.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mf.BorderSizePixel = 0
mf.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mf

local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 0, 1, 0)
shadow.Position = UDim2.new(0, 4, 0, 4)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = mf

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 12)
shadowCorner.Parent = shadow

-- Title Bar
local tb = Instance.new("Frame")
tb.Name = "TitleBar"
tb.Size = UDim2.new(1, 0, 0, 60)
tb.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
tb.BorderSizePixel = 0
tb.Parent = mf

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = tb

local tt = Instance.new("TextLabel")
tt.Name = "Title"
tt.Size = UDim2.new(1, -100, 1, 0)
tt.Position = UDim2.new(0, 20, 0, 0)
tt.BackgroundTransparency = 1
tt.Text = "Checkpoint Teleport (" .. #locs .. ")"
tt.TextColor3 = Color3.fromRGB(255, 255, 255)
tt.TextSize = 20
tt.Font = Enum.Font.GothamBold
tt.TextXAlignment = Enum.TextXAlignment.Left
tt.Parent = tb

local rb = Instance.new("TextButton")
rb.Name = "RefreshButton"
rb.Size = UDim2.new(0, 80, 0, 40)
rb.Position = UDim2.new(1, -90, 0.5, -20)
rb.AnchorPoint = Vector2.new(0, 0.5)
rb.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
rb.BorderSizePixel = 0
rb.Text = "Refresh"
rb.TextColor3 = Color3.fromRGB(255, 255, 255)
rb.TextSize = 16
rb.Font = Enum.Font.GothamBold
rb.Parent = tb

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = rb

rb.MouseEnter:Connect(function()
    local tween = TweenService:Create(rb, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 140, 220)})
    tween:Play()
end)

rb.MouseLeave:Connect(function()
    local tween = TweenService:Create(rb, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 162, 255)})
    tween:Play()
end)

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -40, 0, 40)
searchBox.Position = UDim2.new(0, 20, 0, 70)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
searchBox.BorderSizePixel = 0
searchBox.Text = "Search checkpoint..."
searchBox.PlaceholderText = "Search checkpoint..."
searchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBox.TextSize = 14
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = mf

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 15)
searchPadding.PaddingRight = UDim.new(0, 15)
searchPadding.Parent = searchBox

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

-- Scrolling Frame
local sf = Instance.new("ScrollingFrame")
sf.Name = "ScrollFrame"
sf.Size = UDim2.new(1, -40, 1, -130)
sf.Position = UDim2.new(0, 20, 0, 120)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 6
sf.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.Parent = mf

local cf = Instance.new("Frame")
cf.Name = "ContentFrame"
cf.Size = UDim2.new(1, 0, 1, 0)
cf.BackgroundTransparency = 1
cf.Parent = sf

local ul = Instance.new("UIListLayout")
ul.Padding = UDim.new(0, 8)
ul.SortOrder = Enum.SortOrder.Name
ul.Parent = cf

ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y + 10)
end)

local function createButtons(filterText)
    -- Clear existing buttons
    for _, c in ipairs(cf:GetChildren()) do
        if c:IsA("TextButton") then
            c:Destroy()
        end
    end
    
    -- Sort checkpoints
    table.sort(locs, function(a, b)
        return a.name < b.name
    end)
    
    -- Filter and create buttons
    local count = 0
    for _, loc in ipairs(locs) do
        if filterText == "" or loc.name:lower():find(filterText:lower(), 1, true) then
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Name = loc.name
            btn.Size = UDim2.new(1, 0, 0, 50)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.BorderSizePixel = 0
            btn.Text = loc.name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 16
            btn.Font = Enum.Font.Gotham
            btn.AutoButtonColor = false
            btn.Parent = cf
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            
            local btnPadding = Instance.new("UIPadding")
            btnPadding.PaddingLeft = UDim.new(0, 15)
            btnPadding.PaddingRight = UDim.new(0, 15)
            btnPadding.Parent = btn
            
            -- Hover effects
            btn.MouseEnter:Connect(function()
                local tween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)})
                tween:Play()
            end)
            
            btn.MouseLeave:Connect(function()
                local tween = TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)})
                tween:Play()
            end)
            
            -- Click to teleport
            btn.MouseButton1Click:Connect(function()
                teleport(loc.name, loc.position)
            end)
        end
    end
    
    -- Update title
    tt.Text = "Checkpoint Teleport (" .. count .. ")"
end

-- Initial button creation
createButtons("")

-- Refresh button functionality
rb.MouseButton1Click:Connect(function()
    locs = findCP()
    if #locs == 0 then
        local s = Workspace:FindFirstChild("SpawnLocation")
        table.insert(locs, {name = "Spawn", position = s and s.Position or Vector3.new(0, 5, 0), object = s})
    end
    createButtons(searchBox.Text)
end)

-- Search functionality
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    createButtons(searchBox.Text)
end)

-- Character respawn handling
p.CharacterAdded:Connect(function(newChar)
    char = newChar
    rp = char:WaitForChild("HumanoidRootPart")
end)
