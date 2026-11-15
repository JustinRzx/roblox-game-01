-- Game.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local events = ReplicatedStorage:WaitForChild("MF_Events")
local StageEvent = events:WaitForChild("StageEvent")
local WinEvent = events:WaitForChild("WinEvent")
local PlayAgainEvent = events:WaitForChild("PlayAgainEvent")
local StartEvent = events:WaitForChild("StartEvent")
local ResetEvent = events:WaitForChild("ResetEvent")

-- UI
local screen = Instance.new("ScreenGui")
screen.Name = "MF_HUD"
screen.Parent = playerGui

-- Central top HUD for timer and stage
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0.4,0,0.08,0)
hudFrame.Position = UDim2.new(0.3,0,0.02,0)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = screen

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1,0,0.5,0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "00:00.0"
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.Parent = hudFrame
-- make timer readable over bright sky
timerLabel.TextStrokeTransparency = 0.5
timerLabel.TextStrokeColor3 = Color3.new(0,0,0)
timerLabel.TextStrokeThickness = 2

local stageLabel = Instance.new("TextLabel")
stageLabel.Size = UDim2.new(1,0,0.5,0)
stageLabel.Position = UDim2.new(0,0,0.5,0)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "Stage: 0"
stageLabel.TextScaled = true
stageLabel.Font = Enum.Font.Gotham
stageLabel.TextColor3 = Color3.new(1,1,1)
stageLabel.Parent = hudFrame
-- stroke for readability
stageLabel.TextStrokeTransparency = 0.5
stageLabel.TextStrokeColor3 = Color3.new(0,0,0)
stageLabel.TextStrokeThickness = 2

-- Reset button bottom-right
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0,120,0,48)
resetBtn.Position = UDim2.new(1,-140,1,-80)
resetBtn.AnchorPoint = Vector2.new(0,0)
resetBtn.Text = "RESET"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextScaled = true
resetBtn.Parent = screen

resetBtn.MouseButton1Click:Connect(function()
    ResetEvent:FireServer()
end)

-- Start overlay (semi-transparent)
local startOverlay = Instance.new("Frame")
startOverlay.Size = UDim2.new(1,0,1,0)
startOverlay.Position = UDim2.new(0,0,0,0)
startOverlay.BackgroundColor3 = Color3.new(0,0,0)
startOverlay.BackgroundTransparency = 0.45
startOverlay.ZIndex = 10
startOverlay.Parent = screen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6,0,0.15,0)
title.Position = UDim2.new(0.2,0,0.12,0)
title.BackgroundTransparency = 1
title.Text = "RAINBOW OBBY RUSH"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Parent = startOverlay

local how = Instance.new("TextLabel")
how.Size = UDim2.new(0.6,0,0.1,0)
how.Position = UDim2.new(0.2,0,0.3,0)
how.BackgroundTransparency = 1
how.Text = "Reach checkpoints. Don't fall. Finish fast!"
how.TextScaled = true
how.Font = Enum.Font.Gotham
how.TextColor3 = Color3.new(1,1,1)
how.Parent = startOverlay

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0,200,0,64)
playBtn.Position = UDim2.new(0.5,-100,0.5,-32)
playBtn.Text = "MULAI MAIN"
playBtn.Font = Enum.Font.GothamBold
playBtn.TextScaled = true
playBtn.Parent = startOverlay

playBtn.MouseButton1Click:Connect(function()
    PlayAgainEvent:FireServer()
    startOverlay.Visible = false
end)

-- End overlay
local endOverlay = Instance.new("Frame")
endOverlay.Size = UDim2.new(1,0,1,0)
endOverlay.Position = UDim2.new(0,0,0,0)
endOverlay.BackgroundColor3 = Color3.new(0,0,0)
endOverlay.BackgroundTransparency = 0.45
endOverlay.Visible = false
endOverlay.Parent = screen

local winText = Instance.new("TextLabel")
winText.Size = UDim2.new(0.6,0,0.2,0)
winText.Position = UDim2.new(0.2,0,0.2,0)
winText.BackgroundTransparency = 1
winText.Font = Enum.Font.GothamBlack
winText.TextScaled = true
winText.TextColor3 = Color3.new(1,1,1)
winText.Parent = endOverlay

local againBtn = Instance.new("TextButton")
againBtn.Size = UDim2.new(0,200,0,64)
againBtn.Position = UDim2.new(0.5,-100,0.6,-32)
againBtn.Text = "MAIN LAGI"
againBtn.Font = Enum.Font.GothamBold
againBtn.TextScaled = true
againBtn.Parent = endOverlay

againBtn.MouseButton1Click:Connect(function()
    PlayAgainEvent:FireServer()
    endOverlay.Visible = false
    startOverlay.Visible = false
    -- reset local timer
    started = true
    localStart = tick()
end)

-- Toast for checkpoint
local function toast(msg)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.4,0,0.1,0)
    t.Position = UDim2.new(0.3,0,0.45,0)
    t.BackgroundTransparency = 0.4
    t.Text = msg
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.TextColor3 = Color3.new(1,1,1)
    t.Parent = screen
    delay(1.2, function() t:Destroy() end)
end

-- Timer local tracking
local started = false
local localStart = 0

StartEvent.OnClientEvent:Connect(function()
    started = true
    localStart = tick()
end)

StageEvent.OnClientEvent:Connect(function(stage)
    stageLabel.Text = "Stage: "..tostring(stage)
    toast("Stage "..tostring(stage))
end)

WinEvent.OnClientEvent:Connect(function(elapsed)
    -- elapsed is authoritative from server (seconds)
    local mins = math.floor(elapsed/60)
    local secs = math.floor(elapsed - mins*60)
    local dec = math.floor((elapsed - math.floor(elapsed))*10)
    winText.Text = "YOU WIN!\nTime: "..string.format("%02d:%02d.%d", mins, secs, dec)
    endOverlay.Visible = true
    started = false
end)

-- RenderStepped timer update
RunService.RenderStepped:Connect(function()
    if started then
        local elapsed = tick() - localStart
        local mins = math.floor(elapsed/60)
        local secs = math.floor(elapsed - mins*60)
        local dec = math.floor((elapsed - math.floor(elapsed))*10)
        timerLabel.Text = string.format("%02d:%02d.%d", mins, secs, dec)
    end
end)
