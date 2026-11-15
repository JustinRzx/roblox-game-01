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

local GoEvent = Instance.new("RemoteEvent")
GoEvent.Name = "GoEvent"
GoEvent.Parent = events

local LivesEvent = Instance.new("RemoteEvent")
LivesEvent.Name = "LivesEvent"
LivesEvent.Parent = events

local GameOverEvent = Instance.new("RemoteEvent")
GameOverEvent.Name = "GameOverEvent"
GameOverEvent.Parent = events

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

-- (floating BillboardGui signs removed in round 4 per owner feedback:
--  stage names now live as SurfaceGui text on the checkpoint pads themselves)

-- small helpers: tree, lamp, cloud, sky block
local function makeTree(parent, pos, scale, color)
    -- small island under tree so it is not floating
    local isl = Instance.new("Part")
    isl.Size = Vector3.new(7,1,7)
    isl.Position = pos + Vector3.new(0,-0.5,0)
    isl.Anchored = true
    isl.BrickColor = BrickColor.new("Earth green")
    isl.Parent = parent

    local s = (scale or 1) * 1.5
    local trunk = Instance.new("Part")
    trunk.Size = Vector3.new(1*s, 4*s, 1*s)
    trunk.Position = pos + Vector3.new(0,2*s,0)
    trunk.Anchored = true
    trunk.BrickColor = BrickColor.new("Reddish brown")
    trunk.Parent = parent
    local leaves = Instance.new("Part")
    leaves.Size = Vector3.new(4*s,3*s,4*s)
    leaves.Position = pos + Vector3.new(0,4*s,0)
    leaves.Anchored = true
    leaves.BrickColor = BrickColor.new(color or "Bright green")
    leaves.Parent = parent
end

local function makeLamp(parent, pos)
    -- small island under lamp
    local isl = Instance.new("Part")
    isl.Size = Vector3.new(7,1,7)
    isl.Position = pos + Vector3.new(0,-0.5,0)
    isl.Anchored = true
    isl.BrickColor = BrickColor.new("Dark stone grey")
    isl.Parent = parent

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
    -- add fire and orange light on every kill brick
    local fire = Instance.new("Fire")
    fire.Size = 6
    fire.Heat = 8
    fire.Parent = p
    local ol = Instance.new("PointLight")
    ol.Color = Color3.fromRGB(255,120,0)
    ol.Range = 9
    ol.Brightness = 1.5
    ol.Parent = p
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
        base.Transparency = 1
    end

    -- Start platform
    local start = Instance.new("Part")
    start.Size = Vector3.new(40,2,30)
    start.Position = START_POS
    start.Anchored = true
    start.BrickColor = BrickColor.new("Bright violet")
    start.Name = "StartPlatform"
    start.Parent = course

    -- main spawn on the start platform (place has no other SpawnLocation)
    local mainSpawn = Instance.new("SpawnLocation")
    mainSpawn.Size = Vector3.new(10, 1, 10)
    mainSpawn.Anchored = true
    mainSpawn.Position = START_POS + Vector3.new(0, 1.5, 0)
    mainSpawn.Neutral = true
    mainSpawn.Name = "MainSpawn"
    mainSpawn.Parent = course

    -- four corner bushes on the start platform (platform top y=6)
    for _, bp in ipairs({Vector3.new(-16, 6.75, 11), Vector3.new(16, 6.75, 11), Vector3.new(-16, 6.75, -11), Vector3.new(16, 6.75, -11)}) do
        local bush = Instance.new("Part")
        bush.Size = Vector3.new(2, 1.5, 2)
        bush.Position = bp
        bush.Anchored = true
        bush.BrickColor = BrickColor.new("Bright green")
        bush.Parent = course
    end

    -- start make.fun text removed (replaced by logo banner)

    -- rainbow arch above start: true semicircular arc of 13 rotated blocks
    local archColors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 85, 0), Color3.fromRGB(255, 170, 0),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(170, 255, 0), Color3.fromRGB(0, 220, 80),
        Color3.fromRGB(0, 200, 160), Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 100, 255),
        Color3.fromRGB(85, 0, 255), Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 0, 200),
        Color3.fromRGB(255, 0, 120)
    }
    local archCenter = START_POS + Vector3.new(0, 1, -6)
    local archRadius = 13
    for i = 1, 13 do
        local theta = (i - 1) / 12 * math.pi
        local bx = archCenter.X + archRadius * math.cos(theta)
        local by = archCenter.Y + archRadius * math.sin(theta)
        local block = Instance.new("Part")
        block.Size = Vector3.new(4.6, 2, 2)
        block.Anchored = true
        block.CFrame = CFrame.new(bx, by, archCenter.Z) * CFrame.Angles(0, 0, theta + math.pi / 2)
        block.BrickColor = BrickColor.new(archColors[i])
        block.Name = "RainbowArch"..i
        block.Parent = course
    end

    -- stages: build a continuous ribbon in per-stage segments
    for i=1,8 do
        local z_center = -((i-1) * STAGE_DEPTH + STAGE_DEPTH/2)
        local z_front = -((i-1) * STAGE_DEPTH) -- front edge of the stage
        local stageModel = Instance.new("Model")
        stageModel.Name = "Stage"..i
        stageModel.Parent = course

        -- ribbon segment only for stages 1,4,6,8
        if i == 1 or i == 4 or i == 6 or i == 8 then
            local ribbon = Instance.new("Part")
            ribbon.Size = Vector3.new(10, 1, STAGE_DEPTH)
            ribbon.Position = Vector3.new(0, 3.5, z_center)
            ribbon.Anchored = true
            ribbon.BrickColor = BrickColor.new(COLORS[i])
            ribbon.Name = "RibbonStage"..i
            ribbon.Parent = stageModel
        end

        -- checkpoint pad: provide position that makeCheckpoint will offset so pad bottom touches ribbon
        local cpPos = Vector3.new(0, 2.5, z_front - 4)
        local cp = makeCheckpoint(stageModel, i, cpPos)
        cp.Parent = stageModel
        -- stage name printed ON the checkpoint pad (top face) — no floating text
        local names = {"RED","ORANGE","YELLOW","GREEN","BLUE","PURPLE","PINK","GOLD"}
        local padGui = Instance.new("SurfaceGui")
        padGui.Face = Enum.NormalId.Top
        padGui.Parent = cp
        local padLbl = Instance.new("TextLabel")
        padLbl.Size = UDim2.new(1,0,1,0)
        padLbl.BackgroundTransparency = 1
        padLbl.Text = "STAGE "..tostring(i).." - "..(names[i] or "")
        padLbl.TextScaled = true
        padLbl.Font = Enum.Font.GothamBlack
        padLbl.TextColor3 = Color3.new(0.08,0.08,0.08)
        padLbl.Parent = padGui

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
        -- keep old lower trees
        if i % 2 == 0 then
            makeTree(stageModel, Vector3.new(-18,0,z_center), 1)
            makeTree(stageModel, Vector3.new(18,0,z_center), 0.9)
            makeLamp(stageModel, Vector3.new(-14,0,z_center))
            makeLamp(stageModel, Vector3.new(14,0,z_center))
        else
            makeTree(stageModel, Vector3.new(-16,0,z_center), 0.8)
            makeTree(stageModel, Vector3.new(16,0,z_center), 0.8)
        end
        -- add two larger trees on islands at ribbon height (y=3), with a bush each
        local islY = 3
        makeTree(stageModel, Vector3.new(-10,islY,z_center), 1)
        makeTree(stageModel, Vector3.new(10,islY,z_center), 1)
        local bushL = Instance.new("Part")
        bushL.Size = Vector3.new(2,1.5,2)
        bushL.Position = Vector3.new(-10, islY + 0.75, z_center)
        bushL.Anchored = true
        bushL.BrickColor = BrickColor.new("Bright green")
        bushL.Parent = stageModel
        local bushR = bushL:Clone()
        bushR.Position = Vector3.new(10, islY + 0.75, z_center)
        bushR.Parent = stageModel

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
            -- add one lava bar between hurdle 2 and 3
            local lavaZ = z_center - 6 - (2-1)*8 - 4
            local lava = makeKillBrick(stageModel, Vector3.new(0, 3.5 + 0.5, lavaZ), Vector3.new(10,1,2))
            -- billboard warning above this lava
            local bb = Instance.new("BillboardGui")
            bb.Adornee = lava
            bb.Size = UDim2.new(0,100,0,22)
            bb.StudsOffset = Vector3.new(0,2.5,0)
            bb.AlwaysOnTop = false
            bb.MaxDistance = 55
            bb.Parent = lava
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1,0,1,0)
            t.BackgroundTransparency = 1
            t.Text = "LAVA - WATCH OUT!"
            t.TextColor3 = Color3.new(1,0.9,0.9)
            t.TextScaled = true
            t.Font = Enum.Font.GothamBold
            t.TextStrokeTransparency = 0.4
            t.TextStrokeColor3 = Color3.new(0,0,0)
            t.Parent = bb
        elseif i == 2 then
            -- floating platforms across Z (no ribbon under them). Keep gaps <= 6 studs
            -- stage 2: 5 platforms (6x1x6), top y=5, x pattern 0, +2.5, -2.5, 0, +2.5
            local pattern = {0, 2.5, -2.5, 0, 2.5}
            local startZ = cpPos.Z
            local nextFront = -((2)*STAGE_DEPTH)
            local endZ = nextFront - 4
            local total = 5
            for pidx=1,total do
                local frac = (pidx-1)/(total-1)
                local zpos = startZ + frac * (endZ - startZ)
                local x = pattern[pidx]
                local p = Instance.new("Part")
                p.Size = Vector3.new(6,1,6)
                p.Position = Vector3.new(x, 5, zpos)
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
                local size = Vector3.new(10,1,3)
                local kb = makeKillBrick(stageModel, Vector3.new(0, 3.5 + 0.5, kz), size)
                if k == 1 then
                    -- prominent billboard warning above first kill brick of stage 4
                    local bb = Instance.new("BillboardGui")
                    bb.Adornee = kb
                    bb.Size = UDim2.new(0,100,0,22)
                    bb.StudsOffset = Vector3.new(0,2.5,0)
                    bb.AlwaysOnTop = false
                    bb.MaxDistance = 55
                    bb.Parent = kb
                    local t = Instance.new("TextLabel")
                    t.Size = UDim2.new(1,0,1,0)
                    t.BackgroundTransparency = 1
                    t.Text = "LAVA - WATCH OUT!"
                    t.TextColor3 = Color3.new(1,0.9,0.9)
                    t.TextScaled = true
                    t.Font = Enum.Font.GothamBold
                    t.TextStrokeTransparency = 0.4
                    t.TextStrokeColor3 = Color3.new(0,0,0)
                    t.Parent = bb
                end
            end
        elseif i == 5 then
            -- stage 5: 6 platforms (6x1x6), top y=5.5, x pattern +3,-3,+3,-3,+3,-3, z evenly between cp and next
            local pattern = {3, -3, 3, -3, 3, -3}
            local startZ = cpPos.Z
            local nextFront = -((5)*STAGE_DEPTH)
            local endZ = nextFront - 4
            local total = 6
            for pidx=1,total do
                local frac = (pidx-1)/(total-1)
                local zpos = startZ + frac * (endZ - startZ)
                local x = pattern[pidx]
                local p = Instance.new("Part")
                p.Size = Vector3.new(6,1,6)
                p.Position = Vector3.new(x, 5.5, zpos)
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

            -- small make.fun plaque removed (replaced by logo banner)
        end
    end

    -- sky decorations: clouds and floating color blocks above course (build once)
    for c = 1,6 do
        makeCloud(course, Vector3.new(-120 + c*40, 40 + (c%2)*4, -c*STAGE_DEPTH*1.2), 18 + (c%3)*4)
        makeSkyBlock(course, Vector3.new(120 - c*30, 30 + (c%2)*3, -c*STAGE_DEPTH*1.1), 6 + (c%3), COLORS[((c-1)%#COLORS)+1])
    end
    -- add larger flat clouds under path (sea of clouds)
    for i=1,8 do
        local x = -30 + (i-1)*(60/7)
        local z = - (i-1)*36
        local w = 24 + (i%3)*8
        local d = 14 + (i%4)*2
        local c = Instance.new("Part")
        c.Size = Vector3.new(w, 1, d)
        c.Position = Vector3.new(x, -6, z)
        c.Anchored = true
        c.BrickColor = BrickColor.new("Institutional white")
        c.Transparency = 0.15
        c.Parent = course
    end

    -- add logo banners: start gate and finish
    local function makeLogoBanner(parent, pos)
        local board = Instance.new("Part")
        board.Size = Vector3.new(20,5,0.5)
        board.Position = pos
        board.Anchored = true
        board.BrickColor = BrickColor.new("Institutional white")
        board.Parent = parent
        -- wordmark as SurfaceGui text on BOTH faces: the uploaded logo decal
        -- (asset 114952625373692) is stuck in Roblox moderation ("Pending")
        -- and renders blank in-game; text always renders.
        for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
            local sg = Instance.new("SurfaceGui")
            sg.Face = face
            sg.Parent = board
            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1,0,1,0)
            tl.BackgroundTransparency = 1
            tl.Text = "make.fun"
            tl.TextScaled = true
            tl.Font = Enum.Font.GothamBlack
            tl.TextColor3 = Color3.fromRGB(25,20,25)
            tl.Parent = sg
        end
        -- supports
        local left = Instance.new("Part")
        left.Size = Vector3.new(0.6,5,0.6)
        left.Position = pos + Vector3.new(-9.2,-0.0,0)
        left.Anchored = true
        left.BrickColor = BrickColor.new("Dark stone grey")
        left.Parent = parent
        local right = left:Clone()
        right.Position = pos + Vector3.new(9.2, -0.0, 0)
        right.Parent = parent
    end
    -- place start banner above head height (board bottom at y=10 clears a walking character)
    makeLogoBanner(course, Vector3.new(0,12.5,-18))
    -- place finish banner above stage 8 finish (z_center for stage 8)
    local z8 = -((8-1)*STAGE_DEPTH + STAGE_DEPTH/2)
    makeLogoBanner(course, Vector3.new(0,12.5, z8 - 6))
end

-- handler for checkpoints
local function onCheckpointTouched(spawnPart, hit)
    local pl = Players:GetPlayerFromCharacter(hit.Parent)
    if not pl then return end
    playerState[pl] = playerState[pl] or {}
    playerState[pl].lastCheckpoint = spawnPart
    -- set player's RespawnLocation
    pl.RespawnLocation = spawnPart
    -- if player hasn't started yet, touching any checkpoint will start their run
    if not playerState[pl].started then
        playerState[pl].started = true
        playerState[pl].startTick = tick()
        StartEvent:FireClient(pl)
    end
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
                    local state = playerState[pl] or {}
                    local elapsed = tick() - (state.startTick or tick())
                    state.started = false
                    playerState[pl] = state
                    WinEvent:FireClient(pl, elapsed)
                end)
            end
        end
    end
end

-- Start a player's run
PlayAgainEvent.OnServerEvent:Connect(function(pl)
    -- Preparation phase: reset checkpoint, set respawn to MainSpawn if present, teleport to start and freeze player
    playerState[pl] = playerState[pl] or {}
    playerState[pl].lastCheckpoint = nil
    playerState[pl].started = false
    -- fresh run: lives back to full
    playerState[pl].lives = 5
    LivesEvent:FireClient(pl, 5)
    -- fresh run: respawns go back to the main spawn until a checkpoint is hit
    local course0 = Workspace:FindFirstChild("RainbowObbyCourse")
    local ms0 = course0 and course0:FindFirstChild("MainSpawn") or Workspace:FindFirstChild("MainSpawn")
    if ms0 then pl.RespawnLocation = ms0 end
    -- teleport player to start and freeze
    local char = pl.Character
    if char then
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.JumpHeight = 0
        end
        local hr0 = char:FindFirstChild("HumanoidRootPart")
        if hr0 then hr0.CFrame = CFrame.new(START_POS + Vector3.new(0,5,0)) end
    else
        pl:LoadCharacter()
    end
end)

-- GoEvent: unfreeze and actually start the run
GoEvent.OnServerEvent:Connect(function(pl)
    playerState[pl] = playerState[pl] or {}
    playerState[pl].started = true
    playerState[pl].startTick = tick()
    LivesEvent:FireClient(pl, playerState[pl].lives or 5)
    -- unfreeze character
    local char = pl.Character
    if char then
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            humanoid.JumpHeight = 7.2
        end
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
    playerState[pl] = { started = false, lives = 5 }
    -- deterministic first spawn: the main spawn, never a random checkpoint pad
    local course1 = Workspace:FindFirstChild("RainbowObbyCourse")
    local ms1 = course1 and course1:FindFirstChild("MainSpawn")
    if ms1 then pl.RespawnLocation = ms1 end
    pl.CharacterAdded:Connect(function(char)
        -- lives: each death during an active run costs one life; 0 = game over
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            local st = playerState[pl]
            if st and st.started and st.lives and st.lives > 0 then
                st.lives = st.lives - 1
                LivesEvent:FireClient(pl, st.lives)
                if st.lives <= 0 then
                    st.started = false
                    GameOverEvent:FireClient(pl)
                end
            end
        end)
        wait(0.5)
        -- safety net for the FIRST spawn only; checkpoint respawns keep their pad
        local st = playerState[pl]
        if st and not st.lastCheckpoint then
            local hr = char:FindFirstChild("HumanoidRootPart")
            if hr then hr.CFrame = CFrame.new(START_POS + Vector3.new(0,5,0)) end
        end
    end)
end)

-- Build and wire up
buildCourse()
connectCheckpoints()
