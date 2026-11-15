-- init.server.luau
-- Procedural course builder and game server state
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Remote events
local events = Instance.new("Folder")
events.Name = "MF_Events"
events.Parent = ReplicatedStorage

local StageEvent = Instance.new("RemoteEvent")
StageEvent.Name = "StageEvent"
StageEvent.Parent = events

local WinEvent = Instance.new("RemoteEvent")
WinEvent.Name = "WinEvent"
WinEvent.Parent = events

local PlayAgainEvent = Instance.new("RemoteEvent")
PlayAgainEvent.Name = "PlayAgainEvent"
PlayAgainEvent.Parent = events

local StartEvent = Instance.new("RemoteEvent")
StartEvent.Name = "StartEvent"
StartEvent.Parent = events

local ResetEvent = Instance.new("RemoteEvent")
ResetEvent.Name = "ResetEvent"
ResetEvent.Parent = events

-- Server state per player
local playerState = {}

local COLORS = {
    Color3.fromRGB(255, 85, 85),   -- Merah
    Color3.fromRGB(255, 170, 85),  -- Oranye
    Color3.fromRGB(255, 255, 85),  -- Kuning
    Color3.fromRGB(150, 255, 150), -- Hijau
    Color3.fromRGB(120, 170, 255), -- Biru
    Color3.fromRGB(170, 120, 255), -- Ungu
    Color3.fromRGB(255, 150, 220), -- Pink
    Color3.fromRGB(255, 215, 0)    -- Emas
}

local STAGE_DEPTH = 34 -- distance between stages on Z (per-stage length)
local START_POS = Vector3.new(0, 5, 0)

-- Kill plane (fall death)
local killPlane = Instance.new("Part")
killPlane.Size = Vector3.new(4000, 10, 4000)
killPlane.Anchored = true
killPlane.Transparency = 1
killPlane.CanCollide = false
killPlane.Position = Vector3.new(0, -35, 0)
killPlane.Name = "KillPlane"
killPlane.Parent = Workspace

local function damageHumanoid(humanoid)
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
end

killPlane.Touched:Connect(function(hit)
    local h = hit.Parent and hit.Parent:FindFirstChildWhichIsA("Humanoid")
    if h then
        damageHumanoid(h)
    end
end)

-- utility to make signs
local function makeSign(parent, text, pos)
    local sign = Instance.new("Part")
    sign.Size = Vector3.new(6, 4, 0.5)
    sign.Anchored = true
    sign.Position = pos
    sign.BrickColor = BrickColor.new("Institutional white")
    sign.Parent = parent
    local surf = Instance.new("SurfaceGui")
    surf.Face = Enum.NormalId.Top
    surf.AlwaysOnTop = true
    surf.Parent = sign
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1,0,1,0)
    lab.BackgroundTransparency = 1
    lab.Text = text
    lab.TextColor3 = Color3.new(0,0,0)
    lab.TextScaled = true
    lab.Font = Enum.Font.GothamBold
    lab.Parent = surf
    return sign
end

-- small helpers: tree, lamp, cloud, sky block
local function makeTree(parent, pos, scale, color)
    local trunk = Instance.new("Part")
    trunk.Size = Vector3.new(1*scale, 4*scale, 1*scale)
    trunk.Position = pos + Vector3.new(0,2*scale,0)
    trunk.Anchored = true
    trunk.BrickColor = BrickColor.new("Reddish brown")
    trunk.Parent = parent
    local leaves = Instance.new("Part")
    leaves.Size = Vector3.new(4*scale,3*scale,4*scale)
    leaves.Position = pos + Vector3.new(0,4*scale,0)
    leaves.Anchored = true
    leaves.BrickColor = BrickColor.new(color or "Bright green")
    leaves.Parent = parent
end

local function makeLamp(parent, pos)
    local post = Instance.new("Part")
    post.Size = Vector3.new(0.5,6,0.5)
    post.Position = pos + Vector3.new(0,3,0)
    post.Anchored = true
    post.BrickColor = BrickColor.new("Dark stone grey")
    post.Parent = parent
    local light = Instance.new("Part")
    light.Size = Vector3.new(1,1,1)
    light.Position = pos + Vector3.new(0,6,0)
    light.Anchored = true
    light.BrickColor = BrickColor.new("Institutional white")
    light.Material = Enum.Material.Neon
    light.Parent = parent
    local pl = Instance.new("PointLight")
    pl.Parent = light
    pl.Range = 12
    pl.Brightness = 2
end

local function makeCloud(parent, pos, size)
    local c = Instance.new("Part")
    c.Size = Vector3.new(size or 12, 2, (size or 12)/2)
    c.Position = pos
    c.Anchored = true
    c.BrickColor = BrickColor.new("Institutional white")
    c.Transparency = 0.1
    c.Parent = parent
end

local function makeSkyBlock(parent, pos, size, color)
    local b = Instance.new("Part")
    b.Size = Vector3.new(size or 6, size or 6, size or 6)
    b.Position = pos
    b.Anchored = true
    b.BrickColor = BrickColor.new(color or "Bright violet")
    b.Parent = parent
end

-- make a checkpoint spawn location
local function makeCheckpoint(parent, idx, position)
    local sp = Instance.new("SpawnLocation")
    sp.Size = Vector3.new(8,1,8)
    sp.Anchored = true
    -- place so its bottom touches the ribbon surface (ribbon Y = 3.5)
    sp.Position = position + Vector3.new(0,2,0)
    sp.Neutral = true
    sp.CanTouch = true
    sp.Name = "Checkpoint"..idx
    sp.Parent = parent
    sp:MakeJoints()
    return sp
end

-- kill brick with per-player debounce
local hitDebounce = {}
local function makeKillBrick(parent, pos, size)
    local p = Instance.new("Part")
    p.Size = size or Vector3.new(6,2,6)
    p.Position = pos
    p.Anchored = true
    p.BrickColor = BrickColor.new("Really red")
    p.Material = Enum.Material.Neon
    p.Name = "KillBrick"
    p.Parent = parent
    p.Touched:Connect(function(hit)
        local pl = Players:GetPlayerFromCharacter(hit.Parent)
        if not pl then return end
        local uid = pl.UserId
        if hitDebounce[uid] then return end
        hitDebounce[uid] = true
        local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
        delay(1, function() hitDebounce[uid] = nil end)
    end)
    return p
end

-- Build the course model (procedural)
local function buildCourse()
    local course = Instance.new("Model")
    course.Name = "RainbowObbyCourse"
    course.Parent = Workspace

    -- ensure Baseplate won't stop falls
    local base = Workspace:FindFirstChild("Baseplate")
    if base then
        base.CanCollide = false
        base.Transparency = 0.6
    end

    -- Start platform
    local start = Instance.new("Part")
    start.Size = Vector3.new(40,2,30)
    start.Position = START_POS
    start.Anchored = true
    start.BrickColor = BrickColor.new("Bright violet")
    start.Name = "StartPlatform"
    start.Parent = course

    makeSign(course, "make.fun", START_POS + Vector3.new(0,6,0))

    -- rainbow arch above start
    for i=1,7 do
        local ring = Instance.new("Part")
        ring.Size = Vector3.new(30 + i*2, 1, 2)
        ring.Anchored = true
        ring.Position = START_POS + Vector3.new(0, 12 + i*0.2, -4 - i*0.5)
        ring.BrickColor = BrickColor.new(Color3.fromRGB(255 - i*20, 30 + i*20, 180 - i*10))
        ring.Parent = course
    end

    -- stages: build a continuous ribbon in per-stage segments
    for i=1,8 do
        local z_center = -((i-1) * STAGE_DEPTH + STAGE_DEPTH/2)
        local z_front = -((i-1) * STAGE_DEPTH) -- front edge of the stage
        local stageModel = Instance.new("Model")
        stageModel.Name = "Stage"..i
        stageModel.Parent = course

        -- ribbon segment (the only walkable surface along X -5..5)
        local ribbon = Instance.new("Part")
        ribbon.Size = Vector3.new(10, 1, STAGE_DEPTH)
        ribbon.Position = Vector3.new(0, 3.5, z_center)
        ribbon.Anchored = true
        ribbon.BrickColor = BrickColor.new(COLORS[i])
        ribbon.Name = "RibbonStage"..i
        ribbon.Parent = stageModel

        -- checkpoint pad: provide position that makeCheckpoint will offset so pad bottom touches ribbon
        local cpPos = Vector3.new(0, 2.5, z_front - 4)
        local cp = makeCheckpoint(stageModel, i, cpPos)
        cp.Parent = stageModel

        -- simple decoration: flags (placed outside ribbon area X beyond ±12)
        for f=1,3 do
            local flag = Instance.new("Part")
            flag.Size = Vector3.new(1,3,0.2)
            flag.Position = Vector3.new(-14 + f*7, 6, z_center - 5)
            flag.Anchored = true
            flag.BrickColor = BrickColor.new(COLORS[i])
            flag.Parent = stageModel
        end

        -- additional decoration along the path: trees and lamps
        if i % 2 == 0 then
            makeTree(stageModel, Vector3.new(-18,0,z), 1)
            makeTree(stageModel, Vector3.new(18,0,z), 0.9)
            makeLamp(stageModel, Vector3.new(-14,0,z))
            makeLamp(stageModel, Vector3.new(14,0,z))
        else
            makeTree(stageModel, Vector3.new(-16,0,z), 0.8)
            makeTree(stageModel, Vector3.new(16,0,z), 0.8)
        end

        -- per-stage obstacles
        if i == 1 then
            -- three full-width hurdles across ribbon (width X -5..5 -> size X 10)
            for h=1,3 do
                local hr = Instance.new("Part")
                hr.Size = Vector3.new(10,2,1)
                hr.Position = Vector3.new(0, 3.5 + 1, z_center - 6 - (h-1)*8)
                hr.Anchored = true
                hr.BrickColor = BrickColor.new("Brown")
                hr.Parent = stageModel
            end
        elseif i == 2 then
            -- floating platforms across Z (no ribbon under them). Keep gaps <= 6 studs
            for pidx=1,6 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(6,1,6)
                p.Position = Vector3.new(0, 5 + (pidx%2==0 and 1 or 0), z_center - 10 + (pidx-1) * 6)
                p.Anchored = true
                p.BrickColor = BrickColor.new("Orange")
                p.Parent = stageModel
            end
        elseif i == 3 then
            -- single narrow beam as the only path in this stage
            local beam = Instance.new("Part")
            beam.Size = Vector3.new(2,1,24)
            beam.Position = Vector3.new(0, 5, z_center)
            beam.Anchored = true
            beam.BrickColor = BrickColor.new("New Yeller")
            beam.Parent = stageModel
            -- landing pads at both ends
            local padA = Instance.new("Part")
            padA.Size = Vector3.new(4,1,4)
            padA.Position = Vector3.new(0, 5, z_center + 12)
            padA.Anchored = true
            padA.BrickColor = BrickColor.new("New Yeller")
            padA.Parent = stageModel
            local padB = padA:Clone()
            padB.Position = Vector3.new(0,5,z_center - 12)
            padB.Parent = stageModel
        elseif i == 4 then
            -- three kill bricks spanning ribbon width (player must jump)
            for k=1,3 do
                local kz = z_center - 6 - (k-1)*8
                makeKillBrick(stageModel, Vector3.new(0, 3.5 + 0.5, kz), Vector3.new(10,1,2))
            end
        elseif i == 5 then
            -- zigzag platforms across stage, no ribbon under
            for pidx=1,7 do
                local px = (pidx%2==0) and 3 or -3
                local p = Instance.new("Part")
                p.Size = Vector3.new(6,1,6)
                p.Position = Vector3.new(px, 5, z_center - 12 + (pidx-1)*4)
                p.Anchored = true
                p.BrickColor = BrickColor.new("Bright blue")
                p.Parent = stageModel
            end
        elseif i == 6 then
            -- ascending stairs 5 steps (up), then descending 5 steps to produce a raised connector to stage 7
            for s=1,5 do
                local step = Instance.new("Part")
                step.Size = Vector3.new(6,1,4)
                step.Position = Vector3.new(0, 3.5 + s*0.8, z_center - (s-1)*4)
                step.Anchored = true
                step.BrickColor = BrickColor.new("Royal purple")
                step.Parent = stageModel
            end
            -- descending steps
            for d=1,5 do
                local dstep = Instance.new("Part")
                dstep.Size = Vector3.new(6,1,4)
                dstep.Position = Vector3.new(0, 3.5 + 5*0.8 - d*0.8, z_center - 5*4 - (d-1)*4)
                dstep.Anchored = true
                dstep.BrickColor = BrickColor.new("Royal purple")
                dstep.Parent = stageModel
            end
            -- bridge/platform aligning with start of Stage 7 beam
            local bridge = Instance.new("Part")
            bridge.Size = Vector3.new(8,1,6)
            bridge.Position = Vector3.new(0, 5, z_center - STAGE_DEPTH/2 - 2)
            bridge.Anchored = true
            bridge.BrickColor = BrickColor.new("Royal purple")
            bridge.Parent = stageModel
            makeLamp(stageModel, Vector3.new(-12,3,z_center - 6))
            makeTree(stageModel, Vector3.new(12,0,z_center - 8), 1.0, "Lime green")
        elseif i == 7 then
            -- long beam as the only walkway; no ribbon under
            local beam = Instance.new("Part")
            beam.Size = Vector3.new(2,1,26)
            beam.Position = Vector3.new(0,5,z_center)
            beam.Anchored = true
            beam.BrickColor = BrickColor.new("Hot pink")
            beam.Parent = stageModel
            -- side kill bricks min 2 stud from beam edge: beam half-width 1, so center at ±(1 + 2 + 1) = ±4
            makeKillBrick(stageModel, Vector3.new(4, 5, z_center), Vector3.new(2,1,6))
            makeKillBrick(stageModel, Vector3.new(-4, 5, z_center), Vector3.new(2,1,6))
            makeLamp(stageModel, Vector3.new(-12,3,z_center))
            for f=1,2 do makeTree(stageModel, Vector3.new(14 + f*2,0,z_center - 4), 0.8) end
        else
            -- finish: golden ribbon and finish pad; ribbon segment already created above
        local gold = Instance.new("Part")
            gold.Size = Vector3.new(10,1,STAGE_DEPTH)
            gold.Position = Vector3.new(0,3.55,z_center)
            gold.Anchored = true
            gold.BrickColor = BrickColor.new("Gold")
            gold.Material = Enum.Material.Neon
            gold.Parent = stageModel

            local finish = Instance.new("Part")
            finish.Size = Vector3.new(8,1,8)
            finish.Position = Vector3.new(0, 3.5 + 0.5, z_center - STAGE_DEPTH/2 + 6)
            finish.Anchored = true
            finish.BrickColor = BrickColor.new("Institutional white")
            finish.Name = "FinishPad"
            finish.Parent = stageModel

            local sign = Instance.new("SurfaceGui")
            sign.Face = Enum.NormalId.Top
            sign.Parent = finish
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "make.fun FINISH"
            lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextColor3 = Color3.new(1, 0.8, 0)
            lbl.Parent = sign

            -- small make.fun plaque
            makeSign(stageModel, "make.fun", Vector3.new(0,9,z_center - STAGE_DEPTH/2 + 6))
        end
    end

    -- sky decorations: clouds and floating color blocks above course (build once)
    for c = 1,6 do
        makeCloud(course, Vector3.new(-120 + c*40, 40 + (c%2)*4, -c*STAGE_DEPTH*1.2), 18 + (c%3)*4)
        makeSkyBlock(course, Vector3.new(120 - c*30, 30 + (c%2)*3, -c*STAGE_DEPTH*1.1), 6 + (c%3), COLORS[((c-1)%#COLORS)+1])
    end
end

-- handler for checkpoints
local function onCheckpointTouched(spawnPart, hit)
    local pl = Players:GetPlayerFromCharacter(hit.Parent)
    if not pl then return end
    playerState[pl] = playerState[pl] or {}
    playerState[pl].lastCheckpoint = spawnPart
    -- set player's RespawnLocation
    pl.RespawnLocation = spawnPart
    -- find stage index from parent name
    local stageModel = spawnPart.Parent
    local stageNum = tonumber(stageModel and stageModel.Name:match("Stage(%d+)") or "0") or 0
    StageEvent:FireClient(pl, stageNum)
end

-- connect checkpoint touches after build
local function connectCheckpoints()
    local course = Workspace:FindFirstChild("RainbowObbyCourse")
    if not course then return end
    for _, m in pairs(course:GetChildren()) do
        if m.Name:match("Stage%d+") then
            local cp = m:FindFirstChildWhichIsA("SpawnLocation")
            if cp then
                cp.Touched:Connect(function(hit) onCheckpointTouched(cp, hit) end)
            end
            local finish = m:FindFirstChild("FinishPad")
            if finish then
                finish.Touched:Connect(function(hit)
                    local pl = Players:GetPlayerFromCharacter(hit.Parent)
                    if not pl then return end
                    local state = playerState[pl]
                    if not state or not state.started then return end
                    local elapsed = tick() - (state.startTick or tick())
                    state.started = false
                    WinEvent:FireClient(pl, elapsed)
                end)
            end
        end
    end
end

-- Start a player's run
PlayAgainEvent.OnServerEvent:Connect(function(pl)
    playerState[pl] = playerState[pl] or {}
    playerState[pl].started = true
    playerState[pl].startTick = tick()
    -- teleport player to start
    local char = pl.Character
    if char and char.PrimaryPart then
        char:SetPrimaryPartCFrame(CFrame.new(START_POS + Vector3.new(0,5,0)))
    else
        -- ensure spawn location
        pl:LoadCharacter()
    end
    StartEvent:FireClient(pl)
end)

-- Reset request
ResetEvent.OnServerEvent:Connect(function(pl)
    -- reload character, respawn at their RespawnLocation
    pl:LoadCharacter()
end)

-- Player joining: give default respawn and connect
Players.PlayerAdded:Connect(function(pl)
    playerState[pl] = { started = false }
    pl.CharacterAdded:Connect(function(char)
        wait(0.5)
        -- ensure they spawn on start platform
        local hr = char:FindFirstChildWhichIsA("HumanoidRootPart")
        if hr then hr.CFrame = CFrame.new(START_POS + Vector3.new(0,5,0)) end
    end)
end)

-- Build and wire up
buildCourse()
connectCheckpoints()
