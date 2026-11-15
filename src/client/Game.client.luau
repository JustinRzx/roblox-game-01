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
local LivesEvent = events:WaitForChild("LivesEvent")
local GameOverEvent = events:WaitForChild("GameOverEvent")

-- root
local screen = Instance.new("ScreenGui")
screen.Name = "MF_HUD"
screen.Parent = playerGui

-- HUD center-top (compact pill — the old 50%-wide bar read as a black box)
local hud = Instance.new("Frame")
hud.Size = UDim2.new(0.24,0,0.10,0)
hud.Position = UDim2.new(0.38,0,0.015,0)
hud.BackgroundColor3 = Color3.new(0,0,0)
hud.BackgroundTransparency = 0.5
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
progressFrame.Size = UDim2.new(1,0,0.3,0)
progressFrame.Position = UDim2.new(0,0,1.1,0)
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

-- HP bar (bound to the Humanoid's real Health) + lives pips (5 attempts)
local hpFrame = Instance.new("Frame")
hpFrame.Size = UDim2.new(0.24,0,0.028,0)
hpFrame.Position = UDim2.new(0.38,0,0.165,0)
hpFrame.BackgroundColor3 = Color3.new(0,0,0)
hpFrame.BackgroundTransparency = 0.4
hpFrame.Parent = screen

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1,0,1,0)
hpFill.BackgroundColor3 = Color3.fromRGB(64,217,64)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpFrame

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1,0,1,0)
hpText.BackgroundTransparency = 1
hpText.Text = "HP"
hpText.Font = Enum.Font.GothamBold
hpText.TextScaled = true
hpText.TextColor3 = Color3.new(1,1,1)
hpText.TextStrokeTransparency = 0.5
hpText.TextStrokeColor3 = Color3.new(0,0,0)
hpText.Parent = hpFrame

local livesLabel = Instance.new("TextLabel")
livesLabel.Size = UDim2.new(0.07,0,0.03,0)
livesLabel.Position = UDim2.new(0.38,0,0.20,0)
livesLabel.BackgroundTransparency = 1
livesLabel.Text = "LIVES"
livesLabel.Font = Enum.Font.GothamBold
livesLabel.TextScaled = true
livesLabel.TextColor3 = Color3.new(1,1,1)
livesLabel.TextStrokeTransparency = 0.5
livesLabel.TextStrokeColor3 = Color3.new(0,0,0)
livesLabel.Parent = screen

local livesFrame = Instance.new("Frame")
livesFrame.Size = UDim2.new(0.16,0,0.03,0)
livesFrame.Position = UDim2.new(0.455,0,0.20,0)
livesFrame.BackgroundTransparency = 1
livesFrame.Parent = screen
local lifePips = {}
for i=1,5 do
    local pip = Instance.new("Frame")
    pip.Size = UDim2.new(1/5, -4, 1, 0)
    pip.Position = UDim2.new((i-1)/5, 2, 0, 0)
    pip.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    pip.BorderSizePixel = 0
    pip.Parent = livesFrame
    lifePips[i] = pip
end

local function setLives(n)
    for i=1,5 do
        if i <= n then
            lifePips[i].BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        else
            lifePips[i].BackgroundColor3 = Color3.new(0.25,0.25,0.25)
        end
    end
end
LivesEvent.OnClientEvent:Connect(setLives)

local function bindHealth(char)
    local hum = char:WaitForChild("Humanoid")
    local function upd()
        local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        hpFill.Size = UDim2.new(f,0,1,0)
        hpFill.BackgroundColor3 = Color3.fromHSV(f * 0.33, 0.75, 0.85)
    end
    hum.HealthChanged:Connect(upd)
    upd()
end
if player.Character then bindHealth(player.Character) end
player.CharacterAdded:Connect(bindHealth)

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
objective.Text = "Race through 8 rainbow stages, hit every checkpoint, dodge the red LAVA, and reach the make.fun FINISH podium as fast as you can!"
objective.TextWrapped = true
objective.TextScaled = true
objective.Font = Enum.Font.Gotham
objective.TextColor3 = Color3.new(1,1,1)
objective.Parent = startOverlay

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0,240,0,72)
playBtn.Position = UDim2.new(0.5,-120,0.55,-36)
playBtn.Text = "START"
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

showToast("Clear 8 stages - Dodge the LAVA - Reach the FINISH!")

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
playAgainBtn.Text = "PLAY AGAIN"
playAgainBtn.Font = Enum.Font.GothamBold
playAgainBtn.TextScaled = true
playAgainBtn.Parent = endOverlay

-- stage names
local STAGE_NAMES = {"RED","ORANGE","YELLOW","GREEN","BLUE","PURPLE","PINK","GOLD"}

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
    winText.Text = "YOU WIN!\nTime: "..string.format("%02d:%02d.%d", mins, secs, dec)
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

-- Game over overlay (lives exhausted)
local gameOverOverlay = Instance.new("Frame")
gameOverOverlay.Size = UDim2.new(1,0,1,0)
gameOverOverlay.BackgroundColor3 = Color3.new(0,0,0)
gameOverOverlay.BackgroundTransparency = 0.45
gameOverOverlay.Visible = false
gameOverOverlay.ZIndex = 10
gameOverOverlay.Parent = screen

local gameOverText = Instance.new("TextLabel")
gameOverText.Size = UDim2.new(0.6,0,0.3,0)
gameOverText.Position = UDim2.new(0.2,0,0.2,0)
gameOverText.BackgroundTransparency = 1
gameOverText.Text = "GAME OVER"
gameOverText.Font = Enum.Font.GothamBlack
gameOverText.TextScaled = true
gameOverText.TextColor3 = Color3.fromRGB(255, 90, 90)
gameOverText.Parent = gameOverOverlay

local gameOverBtn = Instance.new("TextButton")
gameOverBtn.Size = UDim2.new(0,220,0,64)
gameOverBtn.Position = UDim2.new(0.5,-110,0.6,-32)
gameOverBtn.Text = "PLAY AGAIN"
gameOverBtn.Font = Enum.Font.GothamBold
gameOverBtn.TextScaled = true
gameOverBtn.Parent = gameOverOverlay

gameOverBtn.MouseButton1Click:Connect(function()
    PlayAgainEvent:FireServer()
    startOverlay.Visible = false
    endOverlay.Visible = false
    gameOverOverlay.Visible = false
    doCountdownAndFire()
end)

GameOverEvent.OnClientEvent:Connect(function()
    started = false
    gameOverOverlay.Visible = true
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
