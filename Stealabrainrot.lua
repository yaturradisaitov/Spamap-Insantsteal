local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local myHomePos = nil 
local autoSteal = false
local autoKick = false

-- Отправка команд (Ragdoll)
local function sendCmd(msg)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels.RBXGeneral
        if channel then channel:SendAsync(msg) end
    else
        local event = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if event then event.SayMessageRequest:FireServer(msg, "All") end
    end
end

-- Защита от смерти (Anti-Death)
task.spawn(function()
    while task.wait() do
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                if hum.Health <= 0 then hum.Health = 100 end
            end
        end)
    end
end)

-- Плавный полет (Tween) с NoClip
local function safeMove(targetCFrame)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local noclip = RunService.Stepped:Connect(function()
        if player.Character then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local tween = TweenService:Create(hrp, TweenInfo.new(dist/25, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
    
    noclip:Disconnect()
    task.wait(0.5)
end

-- Логика фарма
local function doSteal()
    if not myHomePos then return end
    local target = nil
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower():find("brainrot") and v:IsA("BasePart") then
            if (v.Position - myHomePos).Magnitude > 35 then target = v; break end
        end
    end
    if target then
        safeMove(target.CFrame + Vector3.new(0, 5, 0))
        task.wait(0.6)
        -- Возвращаемся в точку базы + 5 метров высоты (ЧТОБЫ НЕ ТЕПАЛО НАЗАД)
        safeMove(CFrame.new(myHomePos + Vector3.new(0, 5, 0)))
        if autoKick then player:Kick("Stolen!") end
    end
end

-- ИНТЕРФЕЙС (Как на скриншоте)
if player.PlayerGui:FindFirstChild("ErZarHub") then player.PlayerGui.ErZarHub:Destroy() end
local ScreenGui = Instance.new("ScreenGui", player.PlayerGui); ScreenGui.Name = "ErZarHub"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 220); Main.Position = UDim2.new(0.05, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Main.Draggable = true; Main.Active = true
Instance.new("UICorner", Main)

local ListFrame = Instance.new("Frame", ScreenGui)
ListFrame.Size = UDim2.new(0, 220, 0, 250); ListFrame.Position = UDim2.new(0.05, 210, 0.3, 0)
ListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ListFrame.Visible = false; ListFrame.Draggable = true; ListFrame.Active = true
Instance.new("UICorner", ListFrame)

local ListTitle = Instance.new("TextLabel", ListFrame)
ListTitle.Size = UDim2.new(1, 0, 0.15, 0); ListTitle.Text = "SPAM AP"; ListTitle.TextColor3 = Color3.new(1,1,1); ListTitle.BackgroundTransparency = 1; ListTitle.Font = Enum.Font.GothamBold; ListTitle.TextSize = 14

local Scroll = Instance.new("ScrollingFrame", ListFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.8, 0); Scroll.Position = UDim2.new(0.05, 0, 0.15, 0); Scroll.BackgroundTransparency = 1; Scroll.CanvasSize = UDim2.new(0,0,0,0); Scroll.ScrollBarThickness = 2
local layout = Instance.new("UIListLayout", Scroll); layout.Padding = UDim.new(0, 5)

local function createBtn(text, pos, parent, color)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.9, 0, 0.2, 0); b.Position = pos; b.Text = text; b.BackgroundColor3 = color; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold; b.TextSize = 10
    Instance.new("UICorner", b); return b
end

local B1 = createBtn("SET MY BASE 🏠", UDim2.new(0.05, 0, 0.05, 0), Main, Color3.fromRGB(0, 110, 210))
local B2 = createBtn("AUTO-STEAL: OFF ⭕", UDim2.new(0.05, 0, 0.28, 0), Main, Color3.fromRGB(0, 90, 190))
local B3 = createBtn("SPAM AP LIST 📢", UDim2.new(0.05, 0, 0.51, 0), Main, Color3.fromRGB(180, 100, 0))
local B4 = createBtn("AUTO-KICK: OFF ❌", UDim2.new(0.05, 0, 0.74, 0), Main, Color3.fromRGB(180, 0, 0))

B1.MouseButton1Click:Connect(function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        myHomePos = hrp.Position
        B1.Text = "BASE SAVED! ✅"
        task.wait(1); B1.Text = "SET MY BASE 🏠"
    end
end)

B2.MouseButton1Click:Connect(function()
    autoSteal = not autoSteal
    B2.Text = autoSteal and "AUTO: ON ✅" or "AUTO: OFF ⭕"
    if autoSteal then task.spawn(function() while autoSteal do pcall(doSteal) task.wait(1.5) end end) end
end)

B3.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)

B4.MouseButton1Click:Connect(function()
    autoKick = not autoKick
    B4.Text = autoKick and "KICK: ON ✅" or "KICK: OFF ❌"
end)

local function update()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player then
            local f = Instance.new("Frame", Scroll); f.Size = UDim2.new(1, 0, 0, 30); f.BackgroundColor3 = Color3.new(0.15,0.15,0.15); Instance.new("UICorner", f)
            local n = Instance.new("TextLabel", f); n.Size = UDim2.new(0.6,0,1,0); n.Text = p.DisplayName; n.TextColor3 = Color3.new(1,1,1); n.BackgroundTransparency = 1; n.TextScaled = true
            local rb = Instance.new("TextButton", f); rb.Size = UDim2.new(0.3,0,0.8,0); rb.Position = UDim2.new(0.65,0,0.1,0); rb.Text = "RAGDOLL"; rb.BackgroundColor3 = Color3.fromRGB(150,0,0); rb.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", rb)
            rb.MouseButton1Click:Connect(function() sendCmd(";ragdoll " .. p.Name) end)
        end
    end
end

game.Players.PlayerAdded:Connect(update); game.Players.PlayerRemoving:Connect(update); update()

