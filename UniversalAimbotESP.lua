local Environment = getgenv() or _G or {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local PreviousState = Environment.__VIP_AIMESP
if type(PreviousState) == "table" and type(PreviousState.Destroy) == "function" then
    pcall(PreviousState.Destroy)
end

local State = {
    Enabled = true,
    Aimbot = true,
    TargetPart = "Head",
    FOVRadius = 140,
    Smoothness = 0.22,
    ShowFOV = true,
    ESPBox = true,
    ESPTracer = true,
    ESPName = true,
    ESPHealth = true,
    MaxDistance = 1200,
    HeightMin = -60,
    HeightMax = 400,
    HoldKey = Enum.UserInputType.MouseButton2,
    UIKey1 = Enum.KeyCode.RightShift,
    UIKey2 = Enum.KeyCode.Insert,
}

local function GetCamera()
    return Workspace.CurrentCamera
end

local function GetMouseLocation()
    local ok, loc = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if ok and typeof(loc) == "Vector2" then
        return loc
    end
    local cam = GetCamera()
    if cam then
        return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    end
    return Vector2.new(0, 0)
end

local function WorldToViewport(point)
    local cam = GetCamera()
    if not cam then return Vector2.new(0, 0), false end
    local ok, screen, onScreen = pcall(function()
        return cam:WorldToViewportPoint(point)
    end)
    if ok then
        return screen, onScreen == true
    end
    return Vector2.new(0, 0), false
end

local function IsMouseHeld()
    local ok, held = pcall(function()
        return UserInputService:IsMouseButtonPressed(State.HoldKey)
    end)
    return ok and held == true
end

local function DrawingCreate(class, props)
    local ok, obj = pcall(function()
        local d = Drawing.new(class)
        if props then
            for k, v in pairs(props) do
                d[k] = v
            end
        end
        return d
    end)
    if ok then return obj end
    return nil
end

local function DrawingDestroy(obj)
    if not obj then return end
    pcall(function() obj.Visible = false end)
    pcall(function() obj:Destroy() end)
    pcall(function() obj:Remove() end)
end

local function PickMainPart(char)
    if not char then return nil end
    local candidates = {
        char:FindFirstChild("Head"),
        char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("UpperTorso"),
        char:FindFirstChild("Torso"),
        char:FindFirstChild("LowerTorso"),
    }
    for _, part in ipairs(candidates) do
        if part and part:IsA("BasePart") then return part end
    end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then return obj end
    end
    return nil
end

local function IsEntityValid(char)
    if not char or not char:IsA("Model") then return false, nil end
    if LocalPlayer.Character and char == LocalPlayer.Character then return false, nil end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if humanoid.Health <= 0 then return false, nil end
        if humanoid:GetAttribute("Ragdoll") == true then return false, nil end
        if humanoid:GetAttribute("Dead") == true then return false, nil end
    end

    local mainPart = PickMainPart(char)
    if not mainPart then return false, nil end
    if not mainPart:IsDescendantOf(Workspace) then return false, nil end

    local solidCount = 0
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") and obj:IsDescendantOf(Workspace) then
            if obj.Transparency < 1 and obj.CanCollide == true then
                solidCount = solidCount + 1
            end
        end
    end
    if solidCount == 0 then return false, nil end

    return true, mainPart
end

local function IsInLobbyOrDead(char, localChar)
    local root = PickMainPart(char)
    if not root then return true end
    local localRoot = localChar and PickMainPart(localChar)
    if not localRoot then return true end

    local dist = (root.Position - localRoot.Position).Magnitude
    if dist > State.MaxDistance then return true end

    local y = root.Position.Y
    local ly = localRoot.Position.Y
    if y < ly + State.HeightMin then return true end
    if y > ly + State.HeightMax then return true end

    return false
end

local TargetCache = {}
local LastSync = 0

local function SyncTargets()
    local now = tick()
    if now - LastSync < 0.5 then return TargetCache end
    LastSync = now

    TargetCache = {}
    local localChar = LocalPlayer and LocalPlayer.Character

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local valid, mainPart = IsEntityValid(player.Character)
            if valid and not IsInLobbyOrDead(player.Character, localChar) then
                table.insert(TargetCache, {
                    Player = player,
                    Character = player.Character,
                    MainPart = mainPart,
                    Head = player.Character:FindFirstChild("Head"),
                    HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart"),
                    UpperTorso = player.Character:FindFirstChild("UpperTorso"),
                    Torso = player.Character:FindFirstChild("Torso"),
                    Humanoid = player.Character:FindFirstChildOfClass("Humanoid"),
                    Team = player.Team,
                })
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            if Players:GetPlayerFromCharacter(obj) then continue end
            if localChar and obj == localChar then continue end
            local valid, mainPart = IsEntityValid(obj)
            if valid and not IsInLobbyOrDead(obj, localChar) then
                table.insert(TargetCache, {
                    Player = nil,
                    Character = obj,
                    MainPart = mainPart,
                    Head = obj:FindFirstChild("Head"),
                    HumanoidRootPart = obj:FindFirstChild("HumanoidRootPart"),
                    UpperTorso = obj:FindFirstChild("UpperTorso"),
                    Torso = obj:FindFirstChild("Torso"),
                    Humanoid = obj:FindFirstChildOfClass("Humanoid"),
                    Team = nil,
                })
            end
        end
    end

    return TargetCache
end

local function GetTargetPart(target)
    if State.TargetPart == "HumanoidRootPart" then
        return target.HumanoidRootPart or target.MainPart
    end
    return target.Head or target.HumanoidRootPart or target.MainPart
end

local function GetNearestTarget()
    SyncTargets()
    local mouse = GetMouseLocation()
    local cam = GetCamera()
    if not cam then return nil end

    local best, bestDist = nil, math.huge
    for _, target in ipairs(TargetCache) do
        local part = GetTargetPart(target)
        if not part then continue end
        local screen, onScreen = WorldToViewport(part.Position)
        if not onScreen then continue end
        local dist = (screen - mouse).Magnitude
        if dist <= State.FOVRadius and dist < bestDist then
            bestDist = dist
            best = target
        end
    end
    return best, bestDist
end

local function DoAimbot(target)
    if not target then return end
    if State.Enabled == false or State.Aimbot == false then return end
    if not IsMouseHeld() then return end

    local part = GetTargetPart(target)
    if not part then return end

    local cam = GetCamera()
    if not cam then return end

    local targetPos = part.Position
    local desired = CFrame.lookAt(cam.CFrame.Position, targetPos)
    local smooth = State.Smoothness
    if smooth <= 0 then
        cam.CFrame = desired
    elseif smooth >= 1 then
        cam.CFrame = desired
    else
        cam.CFrame = cam.CFrame:Lerp(desired, smooth)
    end
end

local ESPDrawings = {}

local function ESPCreate(target)
    local drawings = {}
    drawings.Box = DrawingCreate("Square", {Visible = false, ZIndex = 2, Thickness = 1.5, Filled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 1})
    drawings.Tracer = DrawingCreate("Line", {Visible = false, ZIndex = 1, Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = 1})
    drawings.Name = DrawingCreate("Text", {Visible = false, ZIndex = 3, Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), OutlineColor = Color3.fromRGB(0, 0, 0)})
    drawings.Health = DrawingCreate("Text", {Visible = false, ZIndex = 3, Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(0, 255, 0), OutlineColor = Color3.fromRGB(0, 0, 0)})
    ESPDrawings[target] = drawings
    return drawings
end

local function ESPRemove(target)
    local drawings = ESPDrawings[target]
    if drawings then
        for _, d in pairs(drawings) do DrawingDestroy(d) end
    end
    ESPDrawings[target] = nil
end

local function UpdateESP()
    local active = {}
    for _, target in ipairs(TargetCache) do
        active[target] = true
        local drawings = ESPDrawings[target] or ESPCreate(target)
        local part = GetTargetPart(target)
        if not part then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        local screen, onScreen = WorldToViewport(part.Position)
        if not onScreen then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end

        local head = target.Head or part
        local headScreen, headOnScreen = WorldToViewport(head.Position + Vector3.new(0, 0.5, 0))
        if not headOnScreen then headScreen = screen end

        local cam = GetCamera()
        local dist = 0
        local localChar = LocalPlayer and LocalPlayer.Character
        local localRoot = localChar and PickMainPart(localChar)
        if localRoot then dist = (part.Position - localRoot.Position).Magnitude end

        local boxHeight = math.max(40, math.abs(screen.Y - headScreen.Y) * 1.1)
        local boxWidth = boxHeight * 0.5
        local boxPos = Vector2.new(screen.X - boxWidth / 2, headScreen.Y)

        if State.ESPBox then
            drawings.Box.Visible = true
            drawings.Box.Position = boxPos
            drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
            drawings.Box.Color = Color3.fromRGB(255, 255, 255)
        else
            drawings.Box.Visible = false
        end

        if State.ESPTracer then
            local size = cam.ViewportSize
            drawings.Tracer.Visible = true
            drawings.Tracer.From = Vector2.new(size.X / 2, size.Y)
            drawings.Tracer.To = screen
            drawings.Tracer.Color = Color3.fromRGB(255, 255, 255)
        else
            drawings.Tracer.Visible = false
        end

        if State.ESPName then
            local humanoid = target.Humanoid
            local hp = humanoid and math.floor(humanoid.Health) or 100
            local name = target.Player and target.Player.Name or (target.Character.Name .. " [NPC]")
            drawings.Name.Visible = true
            drawings.Name.Position = Vector2.new(screen.X, headScreen.Y - 22)
            drawings.Name.Text = string.format("%s  [%dm]", name, math.floor(dist))
            drawings.Name.Color = Color3.fromRGB(255, 255, 255)
        else
            drawings.Name.Visible = false
        end

        if State.ESPHealth then
            local humanoid = target.Humanoid
            local hp = humanoid and math.floor(humanoid.Health) or 0
            local hpColor = hp > 60 and Color3.fromRGB(0, 255, 0) or (hp > 25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
            drawings.Health.Visible = true
            drawings.Health.Position = Vector2.new(screen.X, headScreen.Y - 6)
            drawings.Health.Text = string.format("HP %d", hp)
            drawings.Health.Color = hpColor
        else
            drawings.Health.Visible = false
        end
    end

    for target, drawings in pairs(ESPDrawings) do
        if not active[target] then
            ESPRemove(target)
        end
    end
end

local FOVCircle = DrawingCreate("Circle", {Visible = false, ZIndex = 0, Thickness = 1.5, Filled = false, Color = Color3.fromRGB(0, 255, 255), Transparency = 1, Radius = State.FOVRadius})

local function UpdateFOVCircle()
    if State.Enabled and State.ShowFOV then
        local mouse = GetMouseLocation()
        FOVCircle.Visible = true
        FOVCircle.Position = mouse
        FOVCircle.Radius = State.FOVRadius
        FOVCircle.Color = Color3.fromRGB(0, 255, 255)
    else
        FOVCircle.Visible = false
    end
end

local UI = {}
UI.Enabled = true
UI.Container = nil
UI.Frame = nil
UI.Connections = {}

local function GetGuiParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    local ok2, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 5) end)
    if ok2 and pg then return pg end
    return nil
end

local function CreateUI()
    local parent = GetGuiParent()
    if not parent then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VIP_AIMESP_UI"
    screenGui.ResetOnSpawn = false
    pcall(function() screenGui.Parent = parent end)
    if screenGui.Parent ~= parent then
        screenGui = nil
    end
    if not screenGui then return end

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 260, 0, 340)
    frame.Position = UDim2.new(0, 20, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "VIP Aimbot & ESP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -38)
    scroll.Position = UDim2.new(0, 8, 0, 36)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 6)
    padding.Parent = scroll

    local function MakeLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham
        lbl.TextScaled = true
        lbl.Parent = scroll
        return lbl
    end

    local function MakeToggle(labelText, stateKey)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = (State[stateKey] and "[ON] " or "[OFF] ") .. labelText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextScaled = true
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local function refresh()
            btn.Text = (State[stateKey] and "[ON] " or "[OFF] ") .. labelText
            btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(35, 35, 45)
        end
        refresh()
        btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            refresh()
        end)
        return btn
    end

    local function MakeSelector(labelText, stateKey, options)
        MakeLabel(labelText)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = State[stateKey]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextScaled = true
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local idx = 1
        for i, o in ipairs(options) do
            if o == State[stateKey] then idx = i end
        end
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            State[stateKey] = options[idx]
            btn.Text = State[stateKey]
        end)
        return btn
    end

    local function MakeSlider(labelText, stateKey, minVal, maxVal, step)
        MakeLabel(labelText .. ": " .. tostring(State[stateKey]))
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 6)
        track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        track.BorderSizePixel = 0
        track.Parent = scroll
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((State[stateKey] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        fill.BorderSizePixel = 0
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((State[stateKey] - minVal) / (maxVal - minVal), -7, 0, -4)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function update(val)
            State[stateKey] = val
            local lbl = scroll:FindFirstChildOfClass("TextLabel")
            local pct = (val - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
            knob.Position = UDim2.new(math.clamp(pct, 0, 1), -7, 0, -4)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                local val = minVal + math.clamp(rel, 0, 1) * (maxVal - minVal)
                val = math.floor(val / step + 0.5) * step
                State[stateKey] = val
                local pct = (val - minVal) / (maxVal - minVal)
                fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
                knob.Position = UDim2.new(math.clamp(pct, 0, 1), -7, 0, -4)
                local l = track.Parent:FindFirstChildOfClass("TextLabel")
                if l then l.Text = labelText .. ": " .. tostring(val) end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    MakeToggle("Aimbot", "Aimbot")
    MakeSelector("Target Part", "TargetPart", {"Head", "HumanoidRootPart"})
    MakeSlider("FOV Radius", "FOVRadius", 50, 600, 10)
    MakeSlider("Smoothness", "Smoothness", 0.05, 1, 0.05)
    MakeToggle("Lingkaran FOV", "ShowFOV")
    MakeToggle("ESP Box", "ESPBox")
    MakeToggle("ESP Tracer", "ESPTracer")
    MakeToggle("ESP Nama & Jarak", "ESPName")
    MakeToggle("ESP Health/Status", "ESPHealth")

    UI.Container = screenGui
    UI.Frame = frame

    local draggingUI = false
    local dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingUI = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingUI = false end
    end)
    table.insert(UI.Connections, title.InputBegan)
    table.insert(UI.Connections, title.InputEnded)

    UserInputService.InputChanged:Connect(function(input)
        if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function ToggleUI()
    if UI.Container then
        UI.Enabled = not UI.Enabled
        UI.Container.Enabled = UI.Enabled
    end
end

local function SetupInput()
    local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == State.UIKey1 or input.KeyCode == State.UIKey2 then
            ToggleUI()
        end
    end)
    table.insert(UI.Connections, conn)
end

local RenderConn = nil

local function Start()
    Stop()
    RenderConn = RunService.RenderStepped:Connect(function()
        local ok, err = pcall(function()
            if State.Enabled then
                local target = GetNearestTarget()
                DoAimbot(target)
                UpdateESP()
                UpdateFOVCircle()
            else
                for _, drawings in pairs(ESPDrawings) do
                    for _, d in pairs(drawings) do d.Visible = false end
                end
                FOVCircle.Visible = false
            end
        end)
        if not ok then
            warn("VIP_AIMESP render error:", err)
        end
    end)
end

local function Stop()
    if RenderConn then
        pcall(function() RenderConn:Disconnect() end)
        RenderConn = nil
    end
    for target, drawings in pairs(ESPDrawings) do
        ESPRemove(target)
    end
    FOVCircle.Visible = false
end

local function Destroy()
    Stop()
    for _, conn in ipairs(UI.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    UI.Connections = {}
    if UI.Container then
        pcall(function() UI.Container:Destroy() end)
        UI.Container = nil
    end
    UI.Frame = nil
    Environment.__VIP_AIMESP = nil
end

Start()
SetupInput()
pcall(CreateUI)

Environment.__VIP_AIMESP = {
    State = State,
    Start = Start,
    Stop = Stop,
    Destroy = Destroy,
    GetState = function() return State end,
    SetState = function(key, val) State[key] = val end,
}
