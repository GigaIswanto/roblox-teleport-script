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

local function isValidCheckpoint(obj)
    -- Skip common non-checkpoint objects
    local skipNames = {"light", "lamp", "part", "basepart", "mesh", "decal", "texture", "sound", "script", "localscript", "module"}
    local nameLower = obj.Name:lower()
    for _, skip in ipairs(skipNames) do
        if nameLower:find(skip, 1, true) and not nameLower:find("checkpoint", 1, true) and not nameLower:find("basecamp", 1, true) then
            return false
        end
    end
    return true
end

local function findCP()
    local cp, f = {}, {}
    -- More specific keywords for checkpoint and basecamp
    local checkpointKeywords = {"checkpoint", "cp", "savepoint", "save", "respawnpoint", "respawn"}
    local basecampKeywords = {"basecamp", "base", "camp", "spawnbox", "spawn", "spawnpoint"}
    
    -- Checkpoint detection
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not isValidCheckpoint(obj) then continue end
        
        local n = obj.Name:lower()
        local isCheckpoint = false
        local isBasecamp = false
        
        -- Check for checkpoint keywords
        for _, k in ipairs(checkpointKeywords) do
            if n:find(k, 1, true) then
                isCheckpoint = true
                break
            end
        end
        
        -- Check for basecamp keywords
        for _, k in ipairs(basecampKeywords) do
            if n:find(k, 1, true) then
                isBasecamp = true
                break
            end
        end
        
        -- Process checkpoint
        if isCheckpoint and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = getPos(obj)
            if pos then
                local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    table.insert(cp, {name = obj.Name, position = pos, object = obj, type = "Checkpoint"})
                end
            end
        end
        
        -- Process basecamp
        if isBasecamp and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = getPos(obj)
            if pos then
                local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                if not f[key] then
                    f[key] = true
                    table.insert(cp, {name = obj.Name, position = pos, object = obj, type = "Basecamp"})
                end
            end
        end
        
        -- Check for models that might contain checkpoint/basecamp parts
        if obj:IsA("Model") then
            local modelName = obj.Name:lower()
            local hasCheckpointKeyword = false
            local hasBasecampKeyword = false
            
            for _, k in ipairs(checkpointKeywords) do
                if modelName:find(k, 1, true) then
                    hasCheckpointKeyword = true
                    break
                end
            end
            
            for _, k in ipairs(basecampKeywords) do
                if modelName:find(k, 1, true) then
                    hasBasecampKeyword = true
                    break
                end
            end
            
            if hasCheckpointKeyword or hasBasecampKeyword then
                local pos = getPos(obj)
                if pos then
                    local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                    if not f[key] then
                        f[key] = true
                        local cpType = hasCheckpointKeyword and "Checkpoint" or "Basecamp"
                        table.insert(cp, {name = obj.Name, position = pos, object = obj, type = cpType})
                    end
                end
            end
        end
        
        -- BillboardGui detection (only if name suggests checkpoint/basecamp)
        if obj:IsA("BasePart") and obj:FindFirstChildOfClass("BillboardGui") then
            local partName = obj.Name:lower()
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            local isRelevant = false
            
            for _, k in ipairs(checkpointKeywords) do
                if partName:find(k, 1, true) or parentName:find(k, 1, true) then
                    isRelevant = true
                    break
                end
            end
            
            for _, k in ipairs(basecampKeywords) do
                if partName:find(k, 1, true) or parentName:find(k, 1, true) then
                    isRelevant = true
                    break
                end
            end
            
            if isRelevant then
                local pos = getPos(obj)
                if pos then
                    local key = obj.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                    if not f[key] then
                        f[key] = true
                        local cpType = (partName:find("basecamp", 1, true) or parentName:find("basecamp", 1, true) or partName:find("base", 1, true) or parentName:find("base", 1, true) or partName:find("camp", 1, true) or parentName:find("camp", 1, true) or partName:find("spawn", 1, true) or parentName:find("spawn", 1, true)) and "Basecamp" or "Checkpoint"
                        table.insert(cp, {name = obj.Name, position = pos, object = obj, type = cpType})
                    end
                end
            end
        end
        
        -- ProximityPrompt detection (only if name suggests checkpoint/basecamp)
        if obj:IsA("ProximityPrompt") and obj.Parent then
            local promptName = obj.ActionText:lower()
            local parentName = obj.Parent.Name:lower()
            local isRelevant = false
            
            for _, k in ipairs(checkpointKeywords) do
                if promptName:find(k, 1, true) or parentName:find(k, 1, true) then
                    isRelevant = true
                    break
                end
            end
            
            for _, k in ipairs(basecampKeywords) do
                if promptName:find(k, 1, true) or parentName:find(k, 1, true) then
                    isRelevant = true
                    break
                end
            end
            
            if isRelevant then
                local pos = getPos(obj.Parent)
                if pos then
                    local key = obj.Parent.Name .. tostring(pos.X) .. tostring(pos.Y) .. tostring(pos.Z)
                    if not f[key] then
                        f[key] = true
                        local name = obj.ActionText ~= "" and obj.ActionText or obj.Parent.Name
                        local cpType = (parentName:find("basecamp", 1, true) or parentName:find("base", 1, true) or parentName:find("camp", 1, true) or parentName:find("spawn", 1, true)) and "Basecamp" or "Checkpoint"
                        table.insert(cp, {name = name, position = pos, object = obj.Parent, type = cpType})
                    end
                end
            end
        end
    end
    
    -- CollectionService tags detection
    local tags = {"Checkpoint", "Basecamp", "Spawn", "SavePoint"}
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
                        local cpType = (tag == "Basecamp" or tag == "Spawn") and "Basecamp" or "Checkpoint"
                        table.insert(cp, {name = obj.Name, position = pos, object = obj, type = cpType})
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
    table.insert(locs, {name = "Spawn", position = s and s.Position or Vector3.new(0, 5, 0), object = s, type = "Basecamp"})
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
mf.Size = UDim2.new(0, 450, 0, 650)
mf.Position = UDim2.new(1, -470, 0.5, -325)
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
tt.Text = "Teleport (" .. #locs .. ")"
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

-- Filter buttons
local filterFrame = Instance.new("Frame")
filterFrame.Name = "FilterFrame"
filterFrame.Size = UDim2.new(1, -40, 0, 35)
filterFrame.Position = UDim2.new(0, 20, 0, 70)
filterFrame.BackgroundTransparency = 1
filterFrame.Parent = mf

local allBtn = Instance.new("TextButton")
allBtn.Name = "AllButton"
allBtn.Size = UDim2.new(0, 80, 1, 0)
allBtn.Position = UDim2.new(0, 0, 0, 0)
allBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
allBtn.BorderSizePixel = 0
allBtn.Text = "All"
allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
allBtn.TextSize = 14
allBtn.Font = Enum.Font.GothamBold
allBtn.Parent = filterFrame

local allCorner = Instance.new("UICorner")
allCorner.CornerRadius = UDim.new(0, 6)
allCorner.Parent = allBtn

local cpBtn = Instance.new("TextButton")
cpBtn.Name = "CPButton"
cpBtn.Size = UDim2.new(0, 100, 1, 0)
cpBtn.Position = UDim2.new(0, 90, 0, 0)
cpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
cpBtn.BorderSizePixel = 0
cpBtn.Text = "Checkpoint"
cpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cpBtn.TextSize = 14
cpBtn.Font = Enum.Font.GothamBold
cpBtn.Parent = filterFrame

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 6)
cpCorner.Parent = cpBtn

local bcBtn = Instance.new("TextButton")
bcBtn.Name = "BCButton"
bcBtn.Size = UDim2.new(0, 100, 1, 0)
bcBtn.Position = UDim2.new(0, 200, 0, 0)
bcBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
bcBtn.BorderSizePixel = 0
bcBtn.Text = "Basecamp"
bcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
bcBtn.TextSize = 14
bcBtn.Font = Enum.Font.GothamBold
bcBtn.Parent = filterFrame

local bcCorner = Instance.new("UICorner")
bcCorner.CornerRadius = UDim.new(0, 6)
bcCorner.Parent = bcBtn

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -40, 0, 40)
searchBox.Position = UDim2.new(0, 20, 0, 115)
searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "Search checkpoint/basecamp..."
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
sf.Size = UDim2.new(1, -40, 1, -170)
sf.Position = UDim2.new(0, 20, 0, 165)
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

local currentFilter = "All"

local function createButtons(filterText, filterType)
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
        -- Text filter
        local textMatch = filterText == "" or loc.name:lower():find(filterText:lower(), 1, true)
        
        -- Type filter
        local typeMatch = filterType == "All" or loc.type == filterType
        
        if textMatch and typeMatch then
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Name = loc.name
            btn.Size = UDim2.new(1, 0, 0, 55)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = cf
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            
            local btnPadding = Instance.new("UIPadding")
            btnPadding.PaddingLeft = UDim.new(0, 15)
            btnPadding.PaddingRight = UDim.new(0, 15)
            btnPadding.Parent = btn
            
            -- Name label
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -80, 0.6, 0)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = loc.name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 16
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = btn
            
            -- Type label
            local typeLabel = Instance.new("TextLabel")
            typeLabel.Size = UDim2.new(1, -80, 0.4, 0)
            typeLabel.Position = UDim2.new(0, 0, 0.6, 0)
            typeLabel.BackgroundTransparency = 1
            typeLabel.Text = loc.type
            typeLabel.TextColor3 = loc.type == "Basecamp" and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(100, 200, 255)
            typeLabel.TextSize = 12
            typeLabel.Font = Enum.Font.Gotham
            typeLabel.TextXAlignment = Enum.TextXAlignment.Left
            typeLabel.Parent = btn
            
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
    tt.Text = "Teleport (" .. count .. ")"
end

-- Filter button functionality
local function updateFilterButtons(activeBtn)
    allBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    cpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    bcBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    activeBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
end

allBtn.MouseButton1Click:Connect(function()
    currentFilter = "All"
    updateFilterButtons(allBtn)
    createButtons(searchBox.Text, currentFilter)
end)

cpBtn.MouseButton1Click:Connect(function()
    currentFilter = "Checkpoint"
    updateFilterButtons(cpBtn)
    createButtons(searchBox.Text, currentFilter)
end)

bcBtn.MouseButton1Click:Connect(function()
    currentFilter = "Basecamp"
    updateFilterButtons(bcBtn)
    createButtons(searchBox.Text, currentFilter)
end)

-- Initial button creation
createButtons("", currentFilter)

-- Refresh button functionality
rb.MouseButton1Click:Connect(function()
    locs = findCP()
    if #locs == 0 then
        local s = Workspace:FindFirstChild("SpawnLocation")
        table.insert(locs, {name = "Spawn", position = s and s.Position or Vector3.new(0, 5, 0), object = s, type = "Basecamp"})
    end
    createButtons(searchBox.Text, currentFilter)
end)

-- Search functionality
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    createButtons(searchBox.Text, currentFilter)
end)

-- Character respawn handling
p.CharacterAdded:Connect(function(newChar)
    char = newChar
    rp = char:WaitForChild("HumanoidRootPart")
end)
