-- Game.client.luau (rewritten per brief5)
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
local GoEvent = events:WaitForChild("GoEvent")

-- root
local screen = Instance.new("ScreenGui")
screen.Name = "MF_HUD"
screen.Parent = playerGui

-- HUD center-top
local hud = Instance.new("Frame")
hud.Size = UDim2.new(0.5,0,0.12,0)
hud.Position = UDim2.new(0.25,0,0.02,0)
hud.BackgroundColor3 = Color3.new(0,0,0)
hud.BackgroundTransparency = 0.35
hud.Parent = screen

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1,0,0.6,0)
timerLabel.Position = UDim2.new(0,0,0,0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "00:00.0"
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.TextStrokeTransparency = 0.5
timerLabel.TextStrokeColor3 = Color3.new(0,0,0)
timerLabel.TextStrokeThickness = 2
timerLabel.Parent = hud

local stageLabel = Instance.new("TextLabel")
stageLabel.Size = UDim2.new(1,0,0.4,0)
stageLabel.Position = UDim2.new(0,0,0.6,0)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "Stage 0/8 - ?"
stageLabel.Font = Enum.Font.Gotham
stageLabel.TextScaled = true
stageLabel.TextColor3 = Color3.new(1,1,1)
stageLabel.TextStrokeTransparency = 0.5
stageLabel.TextStrokeColor3 = Color3.new(0,0,0)
stageLabel.TextStrokeThickness = 2
stageLabel.Parent = hud

-- progress boxes
local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(0.5,0,0.04,0)
progressFrame.Position = UDim2.new(0.25,0,0.13,0)
progressFrame.BackgroundTransparency = 1
progressFrame.Parent = hud
local progressBoxes = {}
for i=1,8 do
    local b = Instance.new("Frame")
    b.Size = UDim2.new(1/8, -4, 1, 0)
    b.Position = UDim2.new((i-1)/8, 2, 0, 0)
    b.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    b.Parent = progressFrame
    progressBoxes[i] = b
end

-- Reset button
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0,120,0,48)
resetBtn.Position = UDim2.new(1,-140,1,-80)
resetBtn.Text = "RESET"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextScaled = true
resetBtn.Parent = screen
resetBtn.MouseButton1Click:Connect(function() ResetEvent:FireServer() end)

-- Start overlay
local startOverlay = Instance.new("Frame")
startOverlay.Size = UDim2.new(1,0,1,0)
startOverlay.BackgroundTransparency = 0
startOverlay.BackgroundColor3 = Color3.new(0,0,0)
startOverlay.BackgroundTransparency = 0.45
startOverlay.ZIndex = 10
startOverlay.Parent = screen

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8,0,0.15,0)
title.Position = UDim2.new(0.1,0,0.1,0)
title.BackgroundTransparency = 1
title.Text = "RAINBOW OBBY RUSH"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Parent = startOverlay

local objective = Instance.new("TextLabel")
objective.Size = UDim2.new(0.8,0,0.12,0)
objective.Position = UDim2.new(0.1,0,0.28,0)
objective.BackgroundTransparency = 1
objective.Text = "Lewati 8 stage pelangi, injak semua checkpoint, hindari LAVA merah, dan capai podium make.fun FINISH secepat mungkin!"
objective.TextWrapped = true
objective.TextScaled = true
objective.Font = Enum.Font.Gotham
objective.TextColor3 = Color3.new(1,1,1)
objective.Parent = startOverlay

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0,240,0,72)
playBtn.Position = UDim2.new(0.5,-120,0.55,-36)
playBtn.Text = "MULAI"
playBtn.Font = Enum.Font.GothamBold
playBtn.TextScaled = true
playBtn.Parent = startOverlay

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(0.4,0,0.2,0)
countdownLabel.Position = UDim2.new(0.3,0,0.35,0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.GothamBlack
countdownLabel.TextColor3 = Color3.new(1,1,1)
countdownLabel.Visible = false
countdownLabel.Parent = screen

-- toast function
local function showToast(text)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.5,0,0.08,0)
    t.Position = UDim2.new(0.25,0,0.25,0)
    t.BackgroundTransparency = 0.3
    t.BackgroundColor3 = Color3.new(0,0,0)
    t.Text = text
    t.TextColor3 = Color3.new(1,1,1)
    t.TextScaled = true
    t.Parent = screen
    delay(4, function() t:Destroy() end)
end

showToast("Lewati 8 stage - Hindari LAVA - Capai FINISH!")

-- End overlay
local endOverlay = Instance.new("Frame")
endOverlay.Size = UDim2.new(1,0,1,0)
endOverlay.BackgroundTransparency = 0
endOverlay.BackgroundColor3 = Color3.new(0,0,0)
endOverlay.BackgroundTransparency = 0.45
endOverlay.Visible = false
endOverlay.ZIndex = 10
endOverlay.Parent = screen

local winText = Instance.new("TextLabel")
winText.Size = UDim2.new(0.6,0,0.3,0)
winText.Position = UDim2.new(0.2,0,0.2,0)
winText.BackgroundTransparency = 1
winText.Font = Enum.Font.GothamBlack
winText.TextScaled = true
winText.TextColor3 = Color3.new(1,1,1)
winText.Parent = endOverlay

local playAgainBtn = Instance.new("TextButton")
playAgainBtn.Size = UDim2.new(0,220,0,64)
playAgainBtn.Position = UDim2.new(0.5,-110,0.6,-32)
playAgainBtn.Text = "MAIN LAGI"
playAgainBtn.Font = Enum.Font.GothamBold
playAgainBtn.TextScaled = true
playAgainBtn.Parent = endOverlay

-- stage names
local STAGE_NAMES = {"MERAH","ORANYE","KUNING","HIJAU","BIRU","UNGU","PINK","EMAS"}

-- timer state
local started = false
local localStart = 0

StartEvent.OnClientEvent:Connect(function()
    started = true
    localStart = tick()
end)

StageEvent.OnClientEvent:Connect(function(stage)
    local name = STAGE_NAMES[stage] or "?"
    stageLabel.Text = "Stage "..tostring(stage).."/8 - "..name
    for i=1,8 do
        if i <= stage then
            progressBoxes[i].BackgroundColor3 = Color3.new(0.2,0.8,0.2)
        else
            progressBoxes[i].BackgroundColor3 = Color3.new(0.2,0.2,0.2)
        end
    end
    -- small toast
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.4,0,0.08,0)
    t.Position = UDim2.new(0.3,0,0.4,0)
    t.BackgroundTransparency = 0.4
    t.Text = "Stage "..tostring(stage)
    t.TextScaled = true
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.new(1,1,1)
    t.Parent = screen
    delay(1.5, function() t:Destroy() end)
end)

WinEvent.OnClientEvent:Connect(function(elapsed)
    local mins = math.floor(elapsed/60)
    local secs = math.floor(elapsed - mins*60)
    local dec = math.floor((elapsed - math.floor(elapsed))*10)
    winText.Text = "KAMU MENANG!\nWaktu: "..string.format("%02d:%02d.%d", mins, secs, dec)
    endOverlay.Visible = true
    started = false
end)

local function doCountdownAndFire()
    countdownLabel.Visible = true
    for i=3,1,-1 do
        countdownLabel.Text = tostring(i)
        wait(0.7)
    end
    countdownLabel.Text = "GO!"
    wait(0.4)
    countdownLabel.Visible = false
    GoEvent:FireServer()
end

playBtn.MouseButton1Click:Connect(function()
    PlayAgainEvent:FireServer()
    startOverlay.Visible = false
    doCountdownAndFire()
end)

playAgainBtn.MouseButton1Click:Connect(function()
    PlayAgainEvent:FireServer()
    startOverlay.Visible = false
    endOverlay.Visible = false
    doCountdownAndFire()
end)

-- RenderStepped timer
RunService.RenderStepped:Connect(function()
    if started then
        local elapsed = tick() - localStart
        local mins = math.floor(elapsed/60)
        local secs = math.floor(elapsed - mins*60)
        local dec = math.floor((elapsed - math.floor(elapsed))*10)
        timerLabel.Text = string.format("%02d:%02d.%d", mins, secs, dec)
    end
end)
