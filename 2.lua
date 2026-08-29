----------------------------------------------------------------
-- remote admin 4.4.2 :: file 2 :: movement + identifier + aimlock
--                          + bighead + misc
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local uiParent = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10))

local COLORS = {
    Background    = Color3.fromRGB(13, 13, 13),
    Panel         = Color3.fromRGB(22, 22, 22),
    Divider       = Color3.fromRGB(42, 127, 216),
    TextPrimary   = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(189, 189, 189),
    TextMuted     = Color3.fromRGB(141, 141, 141),
    Active        = Color3.fromRGB(78, 163, 255),
}
local FONT_H = Enum.Font.RobotoCondensed
local FONT_B = Enum.Font.RobotoCondensed

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    inst.Parent = parent
    return inst
end

local function strokeOn(inst)
    make("UIStroke", { Color = COLORS.Divider, Thickness = 1, Transparency = 0.4 }, inst)
end

local function resolveUI(_root)
    local hud = uiParent and uiParent:FindFirstChild("RemoteAdminHUD")
    if not hud then return nil end
    local mainFrame = hud:FindFirstChild("MainFrame")
    local body = mainFrame and mainFrame:FindFirstChild("Body")
    local ap = body and body:FindFirstChild("ActionPanel")
    local list = ap and ap:FindFirstChild("ActionMenuList")
    local ws = body and body:FindFirstChild("WorkspacePanel")
    local pages = ws and ws:FindFirstChild("Pages")
    if not (list and pages) then return nil end
    return hud, mainFrame, list, pages
end

local function newCategory(root, list, pages, name)
    local btn = make("TextButton", {
        Name = "CatBtn_" .. name,
        Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_B,
        Text = name, TextSize = 14, TextColor3 = COLORS.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, list)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)

    local page = make("Frame", {
        Name = "Page_" .. name,
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false,
    }, pages)

    local sf = root:FindFirstChild("SelectCategory")
    btn.MouseButton1Click:Connect(function()
        if sf then
            sf:Invoke(page.Visible and nil or name)
        end
    end)
    return page
end

local function newTab(page)
    local content = Instance.new("ScrollingFrame")
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Size = UDim2.new(1, 0, 1, 0)
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = COLORS.Divider
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = page

    make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, content)

    local order = 0
    local function nextOrder()
        order += 1
        return order
    end

    local ui = {}

    function ui.status()
        return make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
            Font = FONT_B, Text = "STATUS  idle", TextSize = 13,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = nextOrder(),
        }, content)
    end

    function ui.button(text, h)
        local btn = make("TextButton", {
            Size = UDim2.new(1, 0, 0, h or 28), BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_H,
            Text = text, TextSize = 14, TextColor3 = COLORS.TextSecondary,
            LayoutOrder = nextOrder(),
        }, content)
        strokeOn(btn)
        return btn
    end

    function ui.section(text)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
            Font = FONT_H, Text = text, TextSize = 13, TextColor3 = COLORS.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
        }, content)
    end

    function ui.label(text)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
            Font = FONT_B, Text = text, TextSize = 13, TextColor3 = COLORS.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
        }, content)
    end

    function ui.row(h)
        return make("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h),
            LayoutOrder = nextOrder(),
        }, content)
    end

    function ui.toggle(labelText, state, key, onChange)
        local row = ui.row(22)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -64, 1, 0),
            Font = FONT_B, Text = labelText, TextSize = 14,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        local btn = make("TextButton", {
            Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(1, -52, 0, 0),
            BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0,
            AutoButtonColor = false, Font = FONT_B, TextSize = 13,
        }, row)
        strokeOn(btn)
        local function refresh()
            btn.Text = state[key] and "ON" or "OFF"
            btn.TextColor3 = state[key] and COLORS.Active or COLORS.TextMuted
        end
        refresh()
        btn.MouseButton1Click:Connect(function()
            state[key] = not state[key]
            refresh()
            if onChange then
                onChange(state[key])
            end
        end)
    end

    function ui.varbox(labelText, state, key, minV, maxV, onSet)
        local row = ui.row(22)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -92, 1, 0),
            Font = FONT_B, Text = labelText, TextSize = 14,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        local box = make("TextBox", {
            Size = UDim2.new(0, 84, 1, 0), Position = UDim2.new(1, -84, 0, 0),
            BackgroundColor3 = COLORS.Background, BorderSizePixel = 0,
            Font = FONT_B, Text = tostring(state[key]), TextSize = 13,
            TextColor3 = COLORS.TextPrimary, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, row)
        strokeOn(box)
        make("UIPadding", { PaddingRight = UDim.new(0, 6) }, box)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then
                state[key] = math.clamp(n, minV, maxV)
                if onSet then
                    onSet(key)
                end
            end
            box.Text = tostring(state[key])
        end)
        if state.__varRefresh then
            table.insert(state.__varRefresh, function()
                box.Text = tostring(state[key])
            end)
        end
    end

    function ui.slider(labelText, state, key, minV, maxV, display)
        local row = ui.row(30)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 14),
            Font = FONT_B, Text = labelText, TextSize = 14,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        local function text(v)
            return display and display(v) or tostring(v)
        end
        local val = make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(0, 60, 0, 14),
            Position = UDim2.new(1, -60, 0, 0), Font = FONT_B,
            Text = text(state[key]), TextSize = 13, TextColor3 = COLORS.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, row)
        local track = make("TextButton", {
            Text = "", AutoButtonColor = false, BackgroundColor3 = COLORS.Background,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 18),
        }, row)
        strokeOn(track)
        local fill = make("Frame", {
            BackgroundColor3 = COLORS.Divider, BorderSizePixel = 0,
            Size = UDim2.new((state[key] - minV) / (maxV - minV), 0, 1, 0),
        }, track)
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            state[key] = math.floor(minV + rel * (maxV - minV) + 0.5)
            val.Text = text(state[key])
            fill.Size = UDim2.new(rel, 0, 1, 0)
        end
        local sliding = false
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
    end

    return ui
end

local function runModule(name, fn)
    task.spawn(function()
        local function attempt(bus)
            if bus:GetAttribute("Mod_" .. name) then
                return
            end
            bus:SetAttribute("Mod_" .. name, true)
            local ok, err = xpcall(fn, function(e)
                warn("[RemoteAdmin/" .. name .. "] failed: " .. tostring(e))
                warn(debug.traceback(e))
            end, bus)
            if ok then
                print("[RemoteAdmin/" .. name .. "] loaded")
            end
        end

        local function hookBus(bus)
            if bus:GetAttribute("Ready") then
                attempt(bus)
                return
            end
            local aconn
            aconn = bus:GetAttributeChangedSignal("Ready"):Connect(function()
                if bus:GetAttribute("Ready") then
                    aconn:Disconnect()
                    attempt(bus)
                end
            end)
        end

        local existing = ReplicatedStorage:FindFirstChild("RA_BUS")
        if existing then
            hookBus(existing)
        end
        ReplicatedStorage.ChildAdded:Connect(function(child)
            if child.Name == "RA_BUS" then
                hookBus(child)
            end
        end)
    end)
end

-- ================================================================
-- MOVEMENT
-- ================================================================
runModule("Movement", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Movement] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "MOVEMENT")
    local ui = newTab(page)
    local statusLabel = ui.status()

    local function setStatus(text, color)
        statusLabel.Text = "STATUS  " .. tostring(text)
        statusLabel.TextColor3 = color or COLORS.TextSecondary
    end

    local MODES = {
        { name = "HL2 AFTERPATCH", runSpeed = 32, jumpVel = 50, airAccel = 52, airSpeed = 42, airMaxSpeed = 36.5, speedCap = 80, friction = 6, groundAccel = 14, stepOffset = 1.2 },
        { name = "HL2 PRE-2006", runSpeed = 32, jumpVel = 50, airAccel = 100, airSpeed = 60, airMaxSpeed = 1e9, speedCap = 0, friction = 6, groundAccel = 14, stepOffset = 1.2 },
        { name = "CLASSIC", constant = true, runSpeed = 16, jumpPower = 50, classicSpeed = 100 },
    }

    local settings = {
        enabled = false, cursed = false, autoHop = true, jumpSounds = true,
        customFov = false, fovValue = 90, fpSens = 1, modeIndex = 1,
        runSpeed = 32, jumpVel = 50, airAccel = 52, airSpeed = 42,
        airMaxSpeed = 36.5, speedCap = 80, friction = 6, groundAccel = 14, stepOffset = 1.2,
        classicSpeed = 100, jumpPower = 50, drift = 5,
    }
    settings.__varRefresh = {}

    local M = {
        keys = { W = false, A = false, S = false, D = false, Space = false },
        hvel = Vector3.zero, airFric = 0, jumping = false,
        wasGrounded = false, grounded = false, lastVy = 0, lastSpace = 0,
    }
    local classicVel = Vector3.zero
    local savedWalk, savedJump = 16, 50
    local savedProps = nil
    local cursedBV, cursedGyro
    local cursedDir = Vector3.zero
    local prevW = false
    local engineOn = false
    local alignAtt, alignO
    local fp = false
    local fpYaw, fpPitch = 0, 0
    local smYaw, smPitch = 0, 0
    local bobT, bobAmp, landDip = 0, 0, 0
    local mouseOverUI = false
    local fovBound = false
    local prevFov = 70
    local modeButtons = {}
    local toggleBtn
    local conns = {}
    local currentHum, currentRoot

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    local jumpSounds = {}
    for _, id in ipairs({
        "rbxassetid://7338942417", "rbxassetid://7338942345",
        "rbxassetid://7338942259", "rbxassetid://7338942180",
        "rbxassetid://7338942417",
    }) do
        table.insert(jumpSounds, make("Sound", { SoundId = id, Volume = 1 }, SoundService))
    end

    local function playJumpSound()
        if settings.jumpSounds then
            jumpSounds[math.random(#jumpSounds)]:Play()
        end
    end

    local function getMoveInput()
        if UserInputService:GetFocusedTextBox() then
            return 0, 0
        end
        local f, r = 0, 0
        if M.keys.W then f += 1 end
        if M.keys.S then f -= 1 end
        if M.keys.D then r += 1 end
        if M.keys.A then r -= 1 end
        return f, r
    end

    local function camFlat()
        local cam = workspace.CurrentCamera
        local lv = cam.CFrame.LookVector
        local flat = Vector3.new(lv.X, 0, lv.Z)
        flat = (flat.Magnitude > 0.05) and flat.Unit or Vector3.zAxis
        local rv = cam.CFrame.RightVector
        local right = Vector3.new(rv.X, 0, rv.Z)
        right = (right.Magnitude > 0.05) and right.Unit or Vector3.xAxis
        return flat, right
    end

    local function wishDirOf(f, r)
        if f == 0 and r == 0 then
            return nil
        end
        local flat, right = camFlat()
        local d = flat * f + right * r
        return (d.Magnitude > 0.01) and d.Unit or nil
    end

    local function footOffset(hum, ro)
        local legLen = (hum.RigType == Enum.HumanoidRigType.R6) and 2 or hum.HipHeight
        return ro.Size.Y * 0.5 + legLen
    end

    local function groundInfo(hum, ro)
        local off = footOffset(hum, ro)
        local res = workspace:Raycast(ro.Position, Vector3.new(0, -(off + 1.2), 0), rayParams)
        if not res then
            return false, Vector3.yAxis, 0
        end
        local n = res.Normal
        if n.Y < 0.7 then
            return false, n, 0
        end
        local target = res.Position.Y + off / math.max(n.Y, 0.7)
        local dy = target - ro.Position.Y
        return dy > -0.55, n, dy
    end

    local function applyFriction(dt)
        local speed = M.hvel.Magnitude
        if speed < 0.01 then
            M.hvel = Vector3.zero
            return
        end
        local control = math.max(speed, 10)
        local drop = control * settings.friction * dt
        M.hvel *= math.max(speed - drop, 0) / speed
    end

    local function groundAccel(dir, dt)
        local cur = M.hvel:Dot(dir)
        local add = settings.runSpeed - cur
        if add <= 0 then return end
        M.hvel += dir * math.min(settings.groundAccel * dt * settings.runSpeed, add)
    end

    local function airAccel(dir, dt)
        local cur = M.hvel:Dot(dir)
        local add = settings.airSpeed - cur
        if add <= 0 then return end
        M.hvel += dir * math.min(settings.airAccel * dt * settings.airSpeed, add)
    end

    local function collideFlatten(ro)
        local sp = M.hvel.Magnitude
        if sp < 1 then return end
        local dir = M.hvel / sp
        local res = workspace:Raycast(ro.Position, dir * 1.5, rayParams)
        if res and res.Normal.Y < 0.7 then
            local into = M.hvel:Dot(res.Normal)
            if into < 0 then
                M.hvel -= res.Normal * into
            end
        end
    end

    local function tryStep(ro)
        local off = settings.stepOffset
        if off <= 0 then return end
        local sp = M.hvel.Magnitude
        if sp < 4 then return end
        local dir = M.hvel / sp
        local origin = ro.Position - Vector3.new(0, ro.Size.Y * 0.5, 0)
        local hit = workspace:Raycast(origin + Vector3.new(0, 0.5, 0), dir * 1.2, rayParams)
        if not hit or hit.Normal.Y > 0.7 then return end
        local top = workspace:Raycast(hit.Position + dir * 0.3 + Vector3.new(0, off, 0), Vector3.new(0, -off - 0.1, 0), rayParams)
        if top and top.Normal.Y > 0.7 then
            local rise = (top.Position.Y + ro.Size.Y * 0.5 + 0.05) - ro.Position.Y
            if rise > 0 and rise <= off then
                ro.CFrame += Vector3.new(0, rise, 0)
            end
        end
    end

    local function stepHL(hum, ro, dt)
        local flat, right = camFlat()
        if alignO then
            alignO.CFrame = CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
        end
        local v = ro.AssemblyLinearVelocity
        local grounded, n, dy = groundInfo(hum, ro)
        if M.jumping and v.Y > 0 then
            grounded = false
        end

        local f, r = getMoveInput()
        local wish = wishDirOf(f, r)
        if wish and grounded then
            local fwd = n:Cross(right)
            local side = fwd:Cross(n)
            if fwd.Magnitude > 0.01 and side.Magnitude > 0.01 then
                wish = (fwd.Unit * f + side.Unit * r).Unit
            end
        end

        local wantJump = ((settings.autoHop and M.keys.Space) or (os.clock() - M.lastSpace < 0.12))
            and not UserInputService:GetFocusedTextBox()
        local vy = v.Y

        if grounded and wantJump then
            M.hvel = Vector3.new(v.X, 0, v.Z)
            vy = settings.jumpVel
            M.jumping = true
            M.lastSpace = 0
            playJumpSound()
            grounded = false
        elseif grounded then
            M.hvel = Vector3.new(v.X, 0, v.Z)
            M.airFric = 0
            applyFriction(dt)
            if wish then
                groundAccel(wish, dt)
            end
            collideFlatten(ro)
            tryStep(ro)
            local h3 = Vector3.new(M.hvel.X, 0, M.hvel.Z)
            local slide = h3 - h3:Dot(n) * n
            vy = slide.Y
            if dy > 0.02 then
                ro.CFrame += Vector3.new(0, math.min(dy, 3), 0)
            end
            if not M.wasGrounded and M.lastVy < -30 then
                landDip = math.clamp((-M.lastVy - 30) * 0.004, 0, 0.25)
            end
        else
            M.hvel = Vector3.new(v.X, 0, v.Z)
            if wish then
                airAccel(wish, dt)
            end
            local sp = M.hvel.Magnitude
            if sp > settings.airMaxSpeed then
                M.airFric = 3
            end
            if M.airFric > 0 then
                local drop = math.max(sp, 10) * settings.friction * dt * 0.01 * M.airFric
                M.hvel *= math.max(sp - drop, 0) / math.max(sp, 0.01)
                M.airFric = math.max(0, M.airFric - 0.5 * dt * 60)
            end
            if settings.speedCap > 0 and M.hvel.Magnitude > settings.speedCap then
                M.hvel = M.hvel.Unit * settings.speedCap
            end
            collideFlatten(ro)
            if M.jumping and v.Y <= 0 then
                M.jumping = false
            end
        end

        M.wasGrounded = grounded
        M.grounded = grounded
        M.lastVy = vy
        ro.AssemblyLinearVelocity = Vector3.new(M.hvel.X, vy, M.hvel.Z)
    end

    local function stepClassic(hum, ro, dt)
        local v = ro.AssemblyLinearVelocity
        local f, r = getMoveInput()
        local wish = wishDirOf(f, r)
        local grounded = hum.FloorMaterial ~= Enum.Material.Air
        M.grounded = grounded
        if grounded and settings.autoHop and M.keys.Space and not UserInputService:GetFocusedTextBox() then
            hum.Jump = true
        end
        if wish then
            local target = wish * settings.classicSpeed
            local a = math.clamp(dt * 10, 0, 1)
            local nx = v.X + (target.X - v.X) * a
            local nz = v.Z + (target.Z - v.Z) * a
            ro.AssemblyLinearVelocity = Vector3.new(nx, v.Y, nz)
            classicVel = Vector3.new(nx, 0, nz)
        elseif not grounded then
            ro.AssemblyLinearVelocity = Vector3.new(classicVel.X, v.Y, classicVel.Z)
        else
            classicVel = Vector3.new(v.X, 0, v.Z)
        end
    end

    local function buildCursed(ro)
        if cursedBV then cursedBV:Destroy() end
        if cursedGyro then cursedGyro:Destroy() end
        cursedBV = make("BodyVelocity", { MaxForce = Vector3.new(math.huge, 0, math.huge), Velocity = Vector3.zero }, ro)
        cursedGyro = make("BodyGyro", { MaxTorque = Vector3.new(0, math.huge, 0), P = 30000, CFrame = ro.CFrame }, ro)
    end

    local function destroyCursed()
        if cursedBV then cursedBV:Destroy() cursedBV = nil end
        if cursedGyro then cursedGyro:Destroy() cursedGyro = nil end
        cursedDir = Vector3.zero
        prevW = false
        local char = LocalPlayer.Character
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        if ro then
            local v = ro.AssemblyLinearVelocity
            local h = Vector3.new(v.X, 0, v.Z)
            if h.Magnitude > 16 then
                h = h.Unit * 16
                ro.AssemblyLinearVelocity = Vector3.new(h.X, v.Y, h.Z)
            end
        end
    end

    local function stepCursed(ro, _dt)
        if not cursedBV or not cursedBV.Parent then
            buildCursed(ro)
        end
        local w = UserInputService:IsKeyDown(Enum.KeyCode.W)
        local s = UserInputService:IsKeyDown(Enum.KeyCode.S)
        if w then
            local lv = workspace.CurrentCamera.CFrame.LookVector
            local flat = Vector3.new(lv.X, 0, lv.Z)
            if flat.Magnitude > 0.05 then
                cursedDir = flat.Unit
            end
        elseif prevW and not s then
            cursedDir = cursedDir * settings.drift
        end
        if s then
            cursedDir = Vector3.zero
        end
        prevW = w
        cursedBV.Velocity = cursedDir * settings.classicSpeed
        if cursedDir.Magnitude > 0.01 and cursedGyro then
            local dir = cursedDir.Unit
            cursedGyro.CFrame = CFrame.new(ro.Position, ro.Position + dir)
        end
    end

    local function destroyAlign()
        if alignO then alignO:Destroy() alignO = nil end
        if alignAtt then alignAtt:Destroy() alignAtt = nil end
    end

    local function physicsWanted()
        local mode = MODES[settings.modeIndex]
        return settings.enabled and not settings.cursed and not mode.constant
    end

    local function setEngine(on, hum, ro)
        if on then
            if not (hum and ro) or engineOn then return end
            engineOn = true
            destroyAlign()
            alignAtt = make("Attachment", { Name = "RA_bhopAlignAtt" }, ro)
            alignO = make("AlignOrientation", {
                Mode = Enum.OrientationAlignmentMode.OneAttachment,
                Attachment0 = alignAtt, MaxTorque = 1e7, MaxAngularVelocity = math.huge,
                Responsiveness = 30, RigidityEnabled = false,
                CFrame = CFrame.Angles(0, select(2, ro.CFrame:ToOrientation()), 0),
            }, ro)
            hum.PlatformStand = true
            hum.AutoRotate = false
            savedProps = ro.CustomPhysicalProperties
            ro.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 1, 1)
            local v = ro.AssemblyLinearVelocity
            M.hvel = Vector3.new(v.X, 0, v.Z)
            M.wasGrounded = false
            M.jumping = false
            M.airFric = 0
        else
            if not engineOn then return end
            engineOn = false
            destroyAlign()
            M.hvel = Vector3.zero
            M.airFric = 0
            M.grounded = false
            if ro then
                pcall(function()
                    ro.CustomPhysicalProperties = savedProps
                end)
            end
            savedProps = nil
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
        end
    end

    local function refreshModeButtons()
        for i, btn in ipairs(modeButtons) do
            local sel = (settings.modeIndex == i)
            btn.TextColor3 = sel and COLORS.Active or COLORS.TextSecondary
            btn.BackgroundColor3 = sel and COLORS.Background or COLORS.Panel
        end
    end

    local function loadPreset(i)
        local mode = MODES[i]
        for k, v in pairs(mode) do
            if k ~= "name" and k ~= "constant" then
                settings[k] = v
            end
        end
        refreshModeButtons()
        setStatus("loaded defaults: " .. mode.name, COLORS.Active)
    end

    local function setEnabled(on)
        if settings.enabled == on then return end
        settings.enabled = on
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        currentHum, currentRoot = hum, ro
        if on then
            savedWalk = hum and hum.WalkSpeed or 16
            savedJump = hum and hum.JumpPower or 50
            if hum then
                hum.UseJumpPower = true
            end
            if physicsWanted() then
                setEngine(true, hum, ro)
            elseif hum then
                hum.WalkSpeed = settings.runSpeed
                hum.JumpPower = settings.jumpPower
            end
        else
            setEngine(false, hum, ro)
            destroyCursed()
            if hum then
                hum.WalkSpeed = savedWalk
                hum.JumpPower = savedJump
            end
            if ro then
                local v = ro.AssemblyLinearVelocity
                local h = Vector3.new(v.X, 0, v.Z)
                local max = savedWalk or 16
                if h.Magnitude > max then
                    h = h.Unit * max
                end
                ro.AssemblyLinearVelocity = Vector3.new(h.X, v.Y, h.Z)
            end
            classicVel = Vector3.zero
        end
        if toggleBtn then
            toggleBtn.Text = on and "DISABLE BHOP" or "ENABLE BHOP"
            toggleBtn.TextColor3 = on and COLORS.Active or COLORS.TextSecondary
        end
        setStatus(on and ("active: " .. MODES[settings.modeIndex].name) or "idle",
            on and COLORS.Active or COLORS.TextMuted)
    end

    local function setCharHidden(char, hidden)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then
                d.LocalTransparencyModifier = hidden and 1 or 0
            end
        end
    end

    local function updateFP(dt)
        if not fp then return end
        local cam = workspace.CurrentCamera
        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end
        local k = math.clamp(dt * 28, 0, 1)
        smYaw += (fpYaw - smYaw) * k
        smPitch += (fpPitch - smPitch) * k

        local char = LocalPlayer.Character
        local head = char and char:FindFirstChild("Head")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        local pos
        if head then
            pos = head.Position + Vector3.new(0, 0.25, 0)
        elseif ro then
            pos = ro.Position + Vector3.new(0, 1.5, 0)
        else
            pos = cam.CFrame.Position
        end

        local hspeed = M.hvel.Magnitude
        local want = (M.grounded and hspeed > 4) and 1 or 0
        bobAmp += (want - bobAmp) * math.clamp(dt * 8, 0, 1)
        if bobAmp > 0.01 then
            bobT += dt * (5 + hspeed * 0.12)
        end
        landDip += (0 - landDip) * math.clamp(dt * 7, 0, 1)

        cam.CFrame = CFrame.new(pos)
            * CFrame.fromEulerAnglesYXZ(smPitch, smYaw, math.sin(bobT) * 0.008 * bobAmp)
            * CFrame.new(math.sin(bobT) * 0.035 * bobAmp,
                -math.abs(math.cos(bobT)) * 0.05 * bobAmp - landDip, 0)

        if char then
            setCharHidden(char, true)
        end
        local busy = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
        UserInputService.MouseBehavior = busy and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    end

    local function setFP(on)
        if fp == on then return end
        fp = on
        local cam = workspace.CurrentCamera
        if on then
            local lv = cam.CFrame.LookVector
            fpYaw = math.atan2(-lv.X, -lv.Z)
            fpPitch = math.clamp(math.asin(math.clamp(lv.Y, -1, 1)), -1.45, 1.45)
            smYaw, smPitch = fpYaw, fpPitch
            cam.CameraType = Enum.CameraType.Scriptable
        else
            local char = LocalPlayer.Character
            if char then
                setCharHidden(char, false)
            end
            cam.CameraType = Enum.CameraType.Custom
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        setStatus(on and "first person on" or "first person off",
            on and COLORS.Active or COLORS.TextMuted)
    end

    toggleBtn = ui.button("ENABLE BHOP", 32)
    toggleBtn.MouseButton1Click:Connect(function()
        setEnabled(not settings.enabled)
    end)

    ui.section("MOVEMENT MODE")
    local modeRow = ui.row(26)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, modeRow)

    for i, mode in ipairs(MODES) do
        local btn = make("TextButton", {
            Size = UDim2.new(0.333, -4, 1, 0), BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_B,
            Text = mode.name, TextSize = 13, TextColor3 = COLORS.TextSecondary,
        }, modeRow)
        strokeOn(btn)
        table.insert(modeButtons, btn)

        btn.MouseButton1Click:Connect(function()
            settings.modeIndex = i
            loadPreset(i)
            if settings.enabled then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local ro = char and char:FindFirstChild("HumanoidRootPart")
                if not physicsWanted() then
                    setEngine(false, hum, ro)
                    if hum then
                        hum.WalkSpeed = settings.runSpeed
                        hum.JumpPower = settings.jumpPower
                    end
                elseif ro then
                    setEngine(true, hum, ro)
                end
            end
        end)
    end
    refreshModeButtons()

    ui.section("TOGGLES")
    ui.toggle("Auto Hop", settings, "autoHop")
    ui.toggle("Jump Sounds", settings, "jumpSounds")
    ui.toggle("Cursed Mode", settings, "cursed", function(v)
        if settings.enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local ro = char and char:FindFirstChild("HumanoidRootPart")
            if not physicsWanted() then
                setEngine(false, hum, ro)
            end
        end
        if v then
            setStatus("cursed mode on", COLORS.Active)
        else
            destroyCursed()
            setStatus("cursed mode off", COLORS.TextMuted)
        end
    end)
    ui.toggle("Custom FOV", settings, "customFov", function(v)
        if v then
            prevFov = workspace.CurrentCamera.FieldOfView
            if not fovBound then
                fovBound = true
                RunService:BindToRenderStep("RA_fov", Enum.RenderPriority.Last.Value + 1, function()
                    workspace.CurrentCamera.FieldOfView = settings.fovValue
                end)
            end
            setStatus("fov locked to " .. settings.fovValue, COLORS.Active)
        else
            if fovBound then
                fovBound = false
                pcall(function()
                    RunService:UnbindFromRenderStep("RA_fov")
                end)
                workspace.CurrentCamera.FieldOfView = prevFov or 70
            end
            setStatus("fov released", COLORS.TextMuted)
        end
    end)
    ui.slider("FOV Value", settings, "fovValue", 50, 120)

    ui.section("VARIABLES")
    local function addVar(labelText, key, mn, mx)
        ui.varbox(labelText, settings, key, mn, mx, function()
            if settings.enabled and currentHum and not engineOn then
                if key == "runSpeed" then
                    currentHum.WalkSpeed = settings.runSpeed
                elseif key == "jumpPower" then
                    currentHum.JumpPower = settings.jumpPower
                end
            end
            setStatus(key .. " = " .. tostring(settings[key]))
        end)
    end
    addVar("Run Speed", "runSpeed", 1, 200)
    addVar("Jump Velocity", "jumpVel", 5, 150)
    addVar("Ground Accel", "groundAccel", 0, 100)
    addVar("Air Accel", "airAccel", 0, 300)
    addVar("Air Speed", "airSpeed", 1, 300)
    addVar("Air Max Speed", "airMaxSpeed", 1, 1e9)
    addVar("Speed Cap", "speedCap", 0, 10000)
    addVar("Friction", "friction", 0, 20)
    addVar("Step Offset", "stepOffset", 0, 4)
    addVar("Classic Speed", "classicSpeed", 1, 1000)
    addVar("Jump Power (Classic)", "jumpPower", 5, 300)
    addVar("Cursed Drift", "drift", 1, 50)
    addVar("FP Sensitivity", "fpSens", 0.2, 3)

    ui.section("PRESETS")
    local PRESET_KEYS = { "runSpeed", "jumpVel", "groundAccel", "airAccel", "airSpeed",
        "airMaxSpeed", "speedCap", "friction", "stepOffset", "classicSpeed", "jumpPower", "drift", "fovValue" }
    local presetSlots = {}
    for slot = 1, 3 do
        local prow = ui.row(22)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0),
            Font = FONT_B, Text = "SLOT " .. slot, TextSize = 14,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
        }, prow)
        local saveBtn = make("TextButton", {
            Size = UDim2.new(0.28, -4, 1, 0), Position = UDim2.new(0.4, 0, 0, 0),
            BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, AutoButtonColor = false,
            Font = FONT_B, Text = "SAVE", TextSize = 13, TextColor3 = COLORS.TextSecondary,
        }, prow)
        strokeOn(saveBtn)
        local loadBtn = make("TextButton", {
            Size = UDim2.new(0.32, -4, 1, 0), Position = UDim2.new(0.68, 4, 0, 0),
            BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, AutoButtonColor = false,
            Font = FONT_B, Text = "LOAD", TextSize = 13, TextColor3 = COLORS.TextMuted,
        }, prow)
        strokeOn(loadBtn)

        saveBtn.MouseButton1Click:Connect(function()
            local t = {}
            for _, k in ipairs(PRESET_KEYS) do
                t[k] = settings[k]
            end
            presetSlots[slot] = t
            loadBtn.TextColor3 = COLORS.Active
            setStatus("saved settings to slot " .. slot, COLORS.Active)
        end)
        loadBtn.MouseButton1Click:Connect(function()
            local t = presetSlots[slot]
            if not t then
                setStatus("slot " .. slot .. " is empty", COLORS.TextMuted)
                return
            end
            for k, v in pairs(t) do
                settings[k] = v
            end
            if settings.enabled and currentHum and not engineOn then
                currentHum.WalkSpeed = settings.runSpeed
                currentHum.JumpPower = settings.jumpPower
            end
            for _, fn in ipairs(settings.__varRefresh) do
                fn()
            end
            setStatus("loaded slot " .. slot, COLORS.Active)
        end)
    end

    ui.label("[=] first person   [space] hop   [alt] free cursor")
    ui.label("click the active mode again to reload its defaults")

    table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode and not processed then
            local name = input.KeyCode.Name
            if M.keys[name] ~= nil then
                M.keys[name] = true
            end
            if name == "Space" then
                M.lastSpace = os.clock()
            end
            if name == "Equals" then
                setFP(not fp)
            end
        end
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode and M.keys[input.KeyCode.Name] ~= nil then
            M.keys[input.KeyCode.Name] = false
        end
    end))
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if fp and root:GetAttribute("Open") ~= true and not mouseOverUI
                and not UserInputService:GetFocusedTextBox() then
                local s = 0.0032 * settings.fpSens
                fpYaw -= input.Delta.X * s
                fpPitch = math.clamp(fpPitch - input.Delta.Y * s, -1.45, 1.45)
            end
        end
    end))
    mainFrame.MouseEnter:Connect(function()
        mouseOverUI = true
    end)
    mainFrame.MouseLeave:Connect(function()
        mouseOverUI = false
    end)

    table.insert(conns, RunService.RenderStepped:Connect(function(dt)
        dt = math.min(dt, 0.05)
        updateFP(dt)

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        currentHum, currentRoot = hum, ro
        if not (hum and ro and ro.Parent) then return end
        if hum.Health <= 0 then return end
        if hum.SeatPart then
            if engineOn then
                setEngine(false, hum, ro)
            end
            return
        end
        if not settings.enabled then return end

        if settings.cursed then
            stepCursed(ro, dt)
            return
        end

        local mode = MODES[settings.modeIndex]
        if mode.constant then
            stepClassic(hum, ro, dt)
        else
            if not engineOn then
                setEngine(true, hum, ro)
            end
            stepHL(hum, ro, dt)
        end
    end))

    local function hookCharacter(char)
        rayParams.FilterDescendantsInstances = { char, workspace.CurrentCamera }
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 10)
            local ro = char:WaitForChild("HumanoidRootPart", 10)
            if not hum then return end
            hum.StateChanged:Connect(function(_, new)
                if new == Enum.HumanoidStateType.Jumping and settings.enabled and not engineOn then
                    playJumpSound()
                end
            end)
            if settings.enabled then
                savedWalk = hum.WalkSpeed
                savedJump = hum.JumpPower
                hum.UseJumpPower = true
                if physicsWanted() then
                    setEngine(true, hum, ro)
                else
                    hum.WalkSpeed = settings.runSpeed
                    hum.JumpPower = settings.jumpPower
                end
            end
        end)
    end
    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function(char)
        destroyCursed()
        if engineOn then
            setEngine(false, currentHum, currentRoot)
        end
        M.hvel = Vector3.zero
        M.airFric = 0
        M.jumping = false
        M.wasGrounded = false
        classicVel = Vector3.zero
        hookCharacter(char)
    end))
    if LocalPlayer.Character then
        hookCharacter(LocalPlayer.Character)
    end

    root.Destroying:Connect(function()
        for _, c in ipairs(conns) do
            c:Disconnect()
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        setEngine(false, hum, ro)
        destroyCursed()
        pcall(function()
            RunService:UnbindFromRenderStep("RA_fov")
        end)
        if char then
            setCharHidden(char, false)
        end
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)
end)

-- ================================================================
-- IDENTIFIER (camera-synced, junk-proof box)
-- ================================================================
runModule("Identifier", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Identifier] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "IDENTIFIER")
    local ui = newTab(page)
    local statusLabel = ui.status()

    local ident = {
        enabled = false,
        showWhenVisible = true,
        outline = true,
        ignoreTeam = false,
        health = true,
        teamLine = true,
        showDistance = true,
        showTeamName = false,
        showTool = false,
        showUsername = false,
        showUserId = false,
        maxDistance = 500,
    }

    local ID_COLORS = {
        Color3.fromRGB(187, 134, 252),
        Color3.fromRGB(255, 152, 0),
        Color3.fromRGB(96, 255, 96),
        Color3.fromRGB(255, 77, 77),
        Color3.fromRGB(80, 160, 255),
    }
    local function idColorFor(plr)
        return ID_COLORS[(plr.UserId % #ID_COLORS) + 1]
    end

    local identGui = Instance.new("ScreenGui")
    identGui.Name = "RA_Identifier"
    identGui.ResetOnSpawn = false
    identGui.IgnoreGuiInset = true
    identGui.DisplayOrder = 40
    identGui.Parent = uiParent

    local identObjects = {}
    local identRay = RaycastParams.new()
    identRay.FilterType = Enum.RaycastFilterType.Exclude
    identRay.RespectCanCollide = true

    local PRIORITY = {
        Head = true, HumanoidRootPart = true, Torso = true,
        UpperTorso = true, LowerTorso = true,
        ["Left Arm"] = true, ["Right Arm"] = true,
        ["Left Leg"] = true, ["Right Leg"] = true,
        LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
        RightUpperArm = true, RightLowerArm = true, RightHand = true,
        LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
        RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
    }

    local function collectParts(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local origin = hrp.Position
        local parts = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and PRIORITY[d.Name] then
                table.insert(parts, d)
                if #parts >= 20 then break end
            end
        end
        if #parts < 20 then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") and not PRIORITY[d.Name] and d.Transparency < 0.95 then
                    local s = d.Size
                    if s.X <= 6 and s.Y <= 6 and s.Z <= 6
                        and (d.Position - origin).Magnitude <= 6 then
                        table.insert(parts, d)
                        if #parts >= 20 then break end
                    end
                end
            end
        end
        return (#parts > 0) and parts or nil
    end

    local function identOccluded(char)
        local cam = workspace.CurrentCamera
        local ro = char:FindFirstChild("HumanoidRootPart")
        if not (cam and ro) then
            return true
        end
        local filter = {}
        if LocalPlayer.Character then
            table.insert(filter, LocalPlayer.Character)
        end
        table.insert(filter, char)
        table.insert(filter, cam)
        identRay.FilterDescendantsInstances = filter
        return workspace:Raycast(cam.CFrame.Position, ro.Position - cam.CFrame.Position, identRay) ~= nil
    end

    local function identMakeObj(plr)
        local color = idColorFor(plr)

        local frame = Instance.new("Frame")
        frame.Visible = false
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = identGui

        local out = make("Frame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0, -1, 0, -1), Size = UDim2.new(1, 2, 1, 2), ZIndex = 1,
        }, frame)
        local outStroke = make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = ident.outline and 0 or 1 }, out)

        local box = make("Frame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 2,
        }, frame)
        local boxStroke = make("UIStroke", { Color = color, Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, box)

        local name = make("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0, -5), Size = UDim2.new(2, 40, 0, 14),
            Font = Enum.Font.Code, TextSize = 13, TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3,
        }, frame)
        local nameStroke = make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Transparency = ident.outline and 0 or 1 }, name)

        local info = make("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, 9), Size = UDim2.new(2, 40, 0, 13),
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3,
        }, frame)
        local infoStroke = make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Transparency = ident.outline and 0 or 1 }, info)

        local team = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 3),
            Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0, ZIndex = 2, Visible = false,
        }, frame)

        local hpBG = make("Frame", {
            Position = UDim2.new(0, -6, 0, 0), Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
            BorderSizePixel = 0, ZIndex = 2, Visible = false,
        }, frame)
        local hpFill = make("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 1, 0),
            BorderSizePixel = 0, ZIndex = 3,
        }, hpBG)

        return {
            root = frame, outStroke = outStroke, boxStroke = boxStroke,
            name = name, nameStroke = nameStroke, info = info, infoStroke = infoStroke,
            team = team, hpBG = hpBG, hpFill = hpFill,
            lastCheck = 0, occluded = false,
        }
    end

    local function identAdd(plr)
        if plr == LocalPlayer or identObjects[plr] then return end
        identObjects[plr] = identMakeObj(plr)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        identAdd(plr)
    end
    Players.PlayerAdded:Connect(identAdd)
    Players.PlayerRemoving:Connect(function(plr)
        local obj = identObjects[plr]
        if obj then
            obj.root:Destroy()
            identObjects[plr] = nil
        end
    end)

    RunService:BindToRenderStep("RA_identifier", Enum.RenderPriority.Camera.Value + 1, function()
        if not ident.enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local now = os.clock()

        for plr, obj in pairs(identObjects) do
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local ro = char and char:FindFirstChild("HumanoidRootPart")
            local visible = char and hum and ro and hum.Health > 0

            local dist = 0
            if visible then
                dist = (ro.Position - cam.CFrame.Position).Magnitude
                if dist > ident.maxDistance then
                    visible = false
                end
                if visible and ident.ignoreTeam and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
                    visible = false
                end
            end

            if visible and not ident.showWhenVisible then
                if now - obj.lastCheck > 0.1 then
                    obj.lastCheck = now
                    obj.occluded = identOccluded(char)
                end
                if not obj.occluded then
                    visible = false
                end
            end

            if visible then
                local parts = collectParts(char)
                if parts then
                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge
                    local any = false
                    for _, part in ipairs(parts) do
                        local cf, s = part.CFrame, part.Size
                        local hx, hy, hz = s.X * 0.5, s.Y * 0.5, s.Z * 0.5
                        for xs = -1, 1, 2 do
                            for ys = -1, 1, 2 do
                                for zs = -1, 1, 2 do
                                    local world = (cf * CFrame.new(hx * xs, hy * ys, hz * zs)).Position
                                    local pt = cam:WorldToViewportPoint(world)
                                    if pt.Z > 0 then
                                        any = true
                                        if pt.X < minX then minX = pt.X end
                                        if pt.Y < minY then minY = pt.Y end
                                        if pt.X > maxX then maxX = pt.X end
                                        if pt.Y > maxY then maxY = pt.Y end
                                    end
                                end
                            end
                        end
                    end

                    if any then
                        local pad = 4
                        local w = math.max(maxX - minX, 8) + pad * 2
                        local h = math.max(maxY - minY, 16) + pad * 2
                        obj.root.Position = UDim2.fromOffset(minX - pad, minY - pad)
                        obj.root.Size = UDim2.fromOffset(w, h)

                        local nm = string.upper(plr.DisplayName)
                        if ident.showUsername then
                            nm = nm .. "(@" .. string.upper(plr.Name) .. ")"
                        end
                        obj.name.Text = nm

                        local bits = {}
                        if ident.showDistance then
                            table.insert(bits, string.format("%dm", math.floor(dist + 0.5)))
                        end
                        if ident.showTeamName and plr.Team then
                            table.insert(bits, string.upper(plr.Team.Name))
                        end
                        if ident.showTool then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                table.insert(bits, string.upper(tool.Name))
                            end
                        end
                        if ident.showUserId then
                            table.insert(bits, "ID" .. plr.UserId)
                        end
                        obj.info.Text = table.concat(bits, "  ")

                        obj.team.Visible = ident.teamLine and plr.Team ~= nil
                        if obj.team.Visible then
                            obj.team.BackgroundColor3 = plr.TeamColor.Color
                        end

                        obj.hpBG.Visible = ident.health
                        if ident.health then
                            local f = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            obj.hpFill.Size = UDim2.new(1, 0, f, 0)
                            obj.hpFill.BackgroundColor3 = Color3.fromHSV(f * 0.33, 0.85, 1)
                        end

                        obj.root.Visible = true
                    else
                        obj.root.Visible = false
                    end
                else
                    obj.root.Visible = false
                end
            else
                obj.root.Visible = false
            end
        end
    end)

    local identBtn = ui.button("ENABLE IDENTIFIER", 32)
    identBtn.MouseButton1Click:Connect(function()
        ident.enabled = not ident.enabled
        if not ident.enabled then
            for _, obj in pairs(identObjects) do
                obj.root.Visible = false
            end
        end
        identBtn.Text = ident.enabled and "DISABLE IDENTIFIER" or "ENABLE IDENTIFIER"
        identBtn.TextColor3 = ident.enabled and COLORS.Active or COLORS.TextSecondary
        statusLabel.Text = "STATUS  " .. (ident.enabled and "active" or "idle")
        statusLabel.TextColor3 = ident.enabled and COLORS.Active or COLORS.TextMuted
    end)

    ui.section("VISIBILITY")
    ui.toggle("Show When Visible", ident, "showWhenVisible")
    ui.toggle("Outlines", ident, "outline", function(v)
        local t = v and 0 or 1
        for _, obj in pairs(identObjects) do
            obj.outStroke.Transparency = t
            obj.nameStroke.Transparency = t
            obj.infoStroke.Transparency = t
        end
    end)
    ui.toggle("Ignore Teammates", ident, "ignoreTeam")
    ui.slider("Max Distance", ident, "maxDistance", 100, 2000)

    ui.section("OVERLAYS")
    ui.toggle("Health Bar", ident, "health")
    ui.toggle("Team Line", ident, "teamLine")

    ui.section("INFO LINE")
    ui.toggle("Distance", ident, "showDistance")
    ui.toggle("Team Name", ident, "showTeamName")
    ui.toggle("Equipped Tool", ident, "showTool")
    ui.toggle("Username", ident, "showUsername")
    ui.toggle("User ID", ident, "showUserId")

    root.Destroying:Connect(function()
        pcall(function()
            RunService:UnbindFromRenderStep("RA_identifier")
        end)
        identGui:Destroy()
    end)
end)

-- ================================================================
-- AIMLOCK
-- ================================================================
runModule("Aimlock", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Aimlock] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "AIMLOCK")
    local ui = newTab(page)
    local aimStatusLabel = ui.status()

    local aim = {
        enabled = false, mode = "HOLD", key = { inputType = Enum.UserInputType.MouseButton2 },
        latched = false, fov = 150, showFov = true, outline = true, accuracy = 85,
        part = "HEAD", teamCheck = false, visibleOnly = false, sticky = true,
        maxDist = 1000, prediction = false, predStrength = 15, marker = true,
    }

    local aimGui = Instance.new("ScreenGui")
    aimGui.Name = "RA_Aimlock"
    aimGui.ResetOnSpawn = false
    aimGui.IgnoreGuiInset = true
    aimGui.DisplayOrder = 39
    aimGui.Parent = uiParent

    local aimBG = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false }, aimGui)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, aimBG)
    local aimBGStroke = make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 1 }, aimBG)

    local aimRing = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false }, aimGui)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, aimRing)
    local aimRingStroke = make("UIStroke", { Color = COLORS.Active, Thickness = 1.5, Transparency = 0.35 }, aimRing)

    local aimMarker = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.fromOffset(12, 12), Visible = false }, aimGui)
    local aimMarkerStroke = make("UIStroke", { Color = COLORS.Active, Thickness = 1 }, aimMarker)

    local aimRay = RaycastParams.new()
    aimRay.FilterType = Enum.RaycastFilterType.Exclude
    aimRay.RespectCanCollide = true

    local currentTarget = nil
    local capturing = false
    local lastStatus = nil
    local aimKeyBtn = nil

    local function aimSetStatus(text)
        if text ~= lastStatus then
            lastStatus = text
            aimStatusLabel.Text = "STATUS  " .. text
            aimStatusLabel.TextColor3 = (text ~= "idle") and COLORS.Active or COLORS.TextMuted
        end
    end

    local function aimKeyLabel()
        if not aim.key then return "NONE" end
        if aim.key.inputType then
            return (aim.key.inputType == Enum.UserInputType.MouseButton1) and "MOUSE1" or "MOUSE2"
        end
        return aim.key.keyCode.Name
    end

    local function aimKeyHeld()
        if not aim.key then return false end
        if aim.key.inputType then
            return UserInputService:IsMouseButtonDown(aim.key.inputType)
        end
        return UserInputService:IsKeyDown(aim.key.keyCode)
    end

    local function aimIsKey(input)
        if not aim.key then return false end
        if aim.key.inputType then
            return input.UserInputType == aim.key.inputType
        end
        return input.KeyCode == aim.key.keyCode
    end

    local function aimTargetPart(char)
        local ro = char:FindFirstChild("HumanoidRootPart")
        if aim.part == "TORSO" then
            return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or ro
        end
        return char:FindFirstChild("Head") or ro
    end

    local function aimVisible(cam, char, pos)
        local filter = {}
        if LocalPlayer.Character then
            table.insert(filter, LocalPlayer.Character)
        end
        table.insert(filter, char)
        table.insert(filter, cam)
        aimRay.FilterDescendantsInstances = filter
        return workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, aimRay) == nil
    end

    local function aimPickTarget(cam)
        local mouse = UserInputService:GetMouseLocation()
        local best, bestD = nil, aim.fov
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    local teamOk = not (aim.teamCheck and plr.Team and plr.Team == LocalPlayer.Team)
                    if teamOk then
                        local part = aimTargetPart(char)
                        if part then
                            local pos = part.Position
                            if (pos - cam.CFrame.Position).Magnitude <= aim.maxDist then
                                local ok = not aim.visibleOnly or aimVisible(cam, char, pos)
                                if ok then
                                    local pt = cam:WorldToViewportPoint(pos)
                                    if pt.Z > 0 then
                                        local d = math.sqrt((pt.X - mouse.X) ^ 2 + (pt.Y - mouse.Y) ^ 2)
                                        if d <= aim.fov and d < bestD then
                                            best, bestD = plr, d
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function aimTargetValid(plr, cam)
        if not plr then return false end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local part = char and aimTargetPart(char)
        if not (hum and part and hum.Health > 0) then return false end
        local pt = cam:WorldToViewportPoint(part.Position)
        if pt.Z <= 0 then return false end
        local mouse = UserInputService:GetMouseLocation()
        local d = math.sqrt((pt.X - mouse.X) ^ 2 + (pt.Y - mouse.Y) ^ 2)
        return d <= aim.fov * 2
    end

    RunService:BindToRenderStep("RA_aimlockStep", Enum.RenderPriority.Camera.Value + 1, function(dt)
        dt = math.min(dt, 0.05)
        local cam = workspace.CurrentCamera
        if not cam then return end
        local mouse = UserInputService:GetMouseLocation()

        local active = false
        if aim.enabled and root:GetAttribute("Open") ~= true then
            if aim.mode == "AUTO" then
                active = true
            elseif aim.mode == "HOLD" then
                active = aimKeyHeld()
            else
                active = aim.latched
            end
        end

        if active then
            if not (aim.sticky and aimTargetValid(currentTarget, cam)) then
                currentTarget = aimPickTarget(cam)
            end
        else
            currentTarget = nil
        end

        local show = aim.enabled and aim.showFov
        aimRing.Visible = show
        aimBG.Visible = show and aim.outline
        if show then
            aimRing.Position = UDim2.fromOffset(mouse.X, mouse.Y)
            aimRing.Size = UDim2.fromOffset(aim.fov * 2, aim.fov * 2)
            aimBG.Position = aimRing.Position
            aimBG.Size = UDim2.fromOffset(aim.fov * 2 + 4, aim.fov * 2 + 4)
            aimRingStroke.Transparency = currentTarget and 0 or 0.35
            aimRingStroke.Color = currentTarget and Color3.fromRGB(255, 77, 77) or COLORS.Active
            aimBGStroke.Transparency = aim.outline and 0.2 or 1
        end

        if currentTarget then
            local char = currentTarget.Character
            local part = char and aimTargetPart(char)
            if part then
                local aimPos = part.Position
                if aim.prediction then
                    aimPos += part.AssemblyLinearVelocity * (aim.predStrength / 100)
                end
                local camPos = cam.CFrame.Position
                local desired = (aimPos - camPos).Unit
                local cur = cam.CFrame.LookVector
                local alpha = (aim.accuracy >= 100) and 1 or math.clamp(dt * (aim.accuracy / 100) * 20, 0, 1)
                local newLook = cur:Lerp(desired, alpha)
                if newLook.Magnitude > 0.001 then
                    cam.CFrame = CFrame.lookAt(camPos, camPos + newLook.Unit)
                end

                aimMarker.Visible = aim.marker
                if aim.marker then
                    local pt = cam:WorldToViewportPoint(part.Position)
                    if pt.Z > 0 then
                        aimMarker.Position = UDim2.fromOffset(pt.X, pt.Y)
                        aimMarkerStroke.Color = Color3.fromRGB(255, 77, 77)
                    else
                        aimMarker.Visible = false
                    end
                end
                aimSetStatus(aim.mode .. " [" .. aimKeyLabel() .. "] LOCK " .. string.upper(currentTarget.DisplayName))
            else
                aimMarker.Visible = false
                aimSetStatus(aim.mode .. " [" .. aimKeyLabel() .. "] searching")
            end
        else
            aimMarker.Visible = false
            if aim.enabled then
                aimSetStatus(aim.mode .. " [" .. aimKeyLabel() .. "] searching")
            else
                aimSetStatus("idle")
            end
        end
    end)

    local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if capturing then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                aim.key = { inputType = input.UserInputType }
                capturing = false
                if aimKeyBtn then aimKeyBtn.Text = "KEY " .. aimKeyLabel() end
            elseif input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                aim.key = { keyCode = input.KeyCode }
                capturing = false
                if aimKeyBtn then aimKeyBtn.Text = "KEY " .. aimKeyLabel() end
            end
            return
        end
        if aim.enabled and aim.mode == "TOGGLE" and aimIsKey(input) then
            aim.latched = not aim.latched
        end
    end)

    local aimBtn = ui.button("ENABLE AIMLOCK", 32)
    aimBtn.MouseButton1Click:Connect(function()
        aim.enabled = not aim.enabled
        aim.latched = false
        aimBtn.Text = aim.enabled and "DISABLE AIMLOCK" or "ENABLE AIMLOCK"
        aimBtn.TextColor3 = aim.enabled and COLORS.Active or COLORS.TextSecondary
    end)

    ui.section("ACTIVATION")
    local modeRow = ui.row(26)
    local aimModeBtn = make("TextButton", {
        Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_B,
        Text = "MODE HOLD", TextSize = 13, TextColor3 = COLORS.TextSecondary,
    }, modeRow)
    strokeOn(aimModeBtn)
    aimModeBtn.MouseButton1Click:Connect(function()
        if aim.mode == "HOLD" then
            aim.mode = "TOGGLE"
        elseif aim.mode == "TOGGLE" then
            aim.mode = "AUTO"
        else
            aim.mode = "HOLD"
        end
        aim.latched = false
        aimModeBtn.Text = "MODE " .. aim.mode
    end)

    aimKeyBtn = make("TextButton", {
        Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new(0.5, 3, 0, 0),
        BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, AutoButtonColor = false,
        Font = FONT_B, Text = "KEY " .. aimKeyLabel(), TextSize = 13,
        TextColor3 = COLORS.TextSecondary,
    }, modeRow)
    strokeOn(aimKeyBtn)
    aimKeyBtn.MouseButton1Click:Connect(function()
        capturing = true
        aimKeyBtn.Text = "PRESS KEY"
    end)

    local clearBtn = ui.button("CLEAR KEYBIND", 22)
    clearBtn.MouseButton1Click:Connect(function()
        aim.key = nil
        capturing = false
        aimKeyBtn.Text = "KEY NONE"
    end)

    ui.section("TARGETING")
    ui.toggle("Team Check", aim, "teamCheck")
    ui.toggle("Visible Only", aim, "visibleOnly")
    ui.toggle("Sticky Aim", aim, "sticky")
    ui.toggle("Prediction", aim, "prediction")
    ui.slider("Prediction Lead", aim, "predStrength", 0, 50, function(v)
        return string.format("%.2fs", v / 100)
    end)
    ui.slider("Max Distance", aim, "maxDist", 100, 5000)

    ui.section("AIMING")
    ui.slider("FOV Radius", aim, "fov", 30, 800)
    ui.toggle("Show FOV Circle", aim, "showFov")
    ui.toggle("Circle Outline", aim, "outline")
    ui.slider("Accuracy", aim, "accuracy", 0, 100, function(v)
        return v .. "%"
    end)

    local partBtn = ui.button("HITBOX HEAD", 24)
    partBtn.MouseButton1Click:Connect(function()
        aim.part = (aim.part == "HEAD") and "TORSO" or "HEAD"
        partBtn.Text = "HITBOX " .. aim.part
    end)

    ui.section("HUD")
    ui.toggle("Lock Marker", aim, "marker")

    root.Destroying:Connect(function()
        inputConn:Disconnect()
        pcall(function()
            RunService:UnbindFromRenderStep("RA_aimlockStep")
        end)
        aimGui:Destroy()
    end)
end)

-- ================================================================
-- BIGHEAD
-- ================================================================
runModule("Bighead", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Bighead] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "BIGHEAD")
    local ui = newTab(page)
    local statusLabel = ui.status()

    local bh = {
        enabled = false,
        scale = 10,
        ghost = true,
        ghostTransparency = 50,
        includeMe = false,
        scaleHats = true,
        neckFix = true,
        massless = true,
        noCollide = true,
        noTouch = true,
    }

    local bhOrig = setmetatable({}, { __mode = "k" })
    local bhNeck = setmetatable({}, { __mode = "k" })

    local function bhRemember(part)
        if not bhOrig[part] then
            bhOrig[part] = {
                size = part.Size,
                transparency = part.Transparency,
                canCollide = part.CanCollide,
                canTouch = part.CanTouch,
                massless = part.Massless,
            }
        end
        return bhOrig[part]
    end

    local function bhNeckFor(char)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") and d.Name == "Neck" then
                return d
            end
        end
        return nil
    end

    local function bhApplyChar(char, active)
        local head = char:FindFirstChild("Head")
        if not (head and head:IsA("BasePart")) then
            return
        end
        local o = bhRemember(head)
        local scale = active and bh.scale or 1

        pcall(function()
            local target = o.size * scale
            if head.Size ~= target then
                head.Size = target
            end
            local wantT = (active and bh.ghost) and (bh.ghostTransparency / 100) or o.transparency
            if head.Transparency ~= wantT then
                head.Transparency = wantT
            end
            local wantC = (active and bh.noCollide) and false or o.canCollide
            if head.CanCollide ~= wantC then
                head.CanCollide = wantC
            end
            local wantK = (active and bh.noTouch) and false or o.canTouch
            if head.CanTouch ~= wantK then
                head.CanTouch = wantK
            end
            local wantM = (active and bh.massless) and true or o.massless
            if head.Massless ~= wantM then
                head.Massless = wantM
            end
        end)

        local motor = bhNeckFor(char)
        if motor then
            local entry = bhNeck[motor]
            if not entry then
                entry = { c0 = motor.C0 }
                bhNeck[motor] = entry
            end
            local want
            if active and bh.neckFix then
                want = entry.c0 * CFrame.new(0, (bh.scale - 1) * (o.size.Y / 2), 0)
            else
                want = entry.c0
            end
            if motor.C0 ~= want then
                pcall(function()
                    motor.C0 = want
                end)
            end
        end

        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    local att = handle:FindFirstChildWhichIsA("Attachment")
                    if att and (att.Name == "HatAttachment" or string.find(att.Name, "Head") ~= nil) then
                        local ho = bhRemember(handle)
                        local wantSize = (active and bh.scaleHats) and ho.size * bh.scale or ho.size
                        if handle.Size ~= wantSize then
                            pcall(function()
                                handle.Size = wantSize
                            end)
                        end
                    end
                end
            end
        end
    end

    local function bhRestoreAll()
        for part, o in pairs(bhOrig) do
            pcall(function()
                part.Size = o.size
                part.Transparency = o.transparency
                part.CanCollide = o.canCollide
                part.CanTouch = o.canTouch
                part.Massless = o.massless
            end)
        end
        table.clear(bhOrig)
        for motor, entry in pairs(bhNeck) do
            pcall(function()
                motor.C0 = entry.c0
            end)
        end
        table.clear(bhNeck)
    end

    local renderConn = RunService.RenderStepped:Connect(function()
        if not bh.enabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                bhApplyChar(char, bh.includeMe or plr ~= LocalPlayer)
            end
        end
    end)

    local function refreshStatus()
        if bh.enabled then
            statusLabel.Text = "STATUS  active, x" .. bh.scale
            statusLabel.TextColor3 = COLORS.Active
        else
            statusLabel.Text = "STATUS  idle"
            statusLabel.TextColor3 = COLORS.TextMuted
        end
    end

    local bhBtn = ui.button("ENABLE BIGHEAD", 32)
    bhBtn.MouseButton1Click:Connect(function()
        bh.enabled = not bh.enabled
        if not bh.enabled then
            bhRestoreAll()
        end
        bhBtn.Text = bh.enabled and "DISABLE BIGHEAD" or "ENABLE BIGHEAD"
        bhBtn.TextColor3 = bh.enabled and COLORS.Active or COLORS.TextSecondary
        refreshStatus()
    end)

    ui.section("OPTIONS")
    ui.toggle("Include Me", bh, "includeMe")
    ui.toggle("Scale Hats", bh, "scaleHats")
    ui.toggle("Neck Offset", bh, "neckFix")
    ui.toggle("Ghost Head", bh, "ghost")
    ui.toggle("Massless", bh, "massless")
    ui.toggle("No Collide", bh, "noCollide")
    ui.toggle("No Touch", bh, "noTouch")

    ui.section("VALUES")
    ui.slider("Head Scale", bh, "scale", 1, 25)
    ui.slider("Ghost Transparency", bh, "ghostTransparency", 0, 100, function(v)
        return v .. "%"
    end)

    root.Destroying:Connect(function()
        renderConn:Disconnect()
        bhRestoreAll()
    end)
end)

-- ================================================================
-- MISC (fun + visual)
-- ================================================================
runModule("Misc", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Misc] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "MISC")
    local ui = newTab(page)
    local statusLabel = ui.status()

    local misc = {
        cyber = false, cyberPower = 8,
        antiLook = false, antiLookDot = 97, antiLookDist = 150, antiLookCD = 25,
        noclip = false,
        spin = false, spinSpeed = 40,
        flicker = false, flickerRate = 10,
    }

    local conns = {}
    local dodgeFlip = false
    local antiLookNext = 0
    local flickerAcc = 0
    local flickerSnap = nil

    local function activeList()
        local t = {}
        if misc.cyber then table.insert(t, "cyber") end
        if misc.antiLook then table.insert(t, "anti-look") end
        if misc.noclip then table.insert(t, "noclip") end
        if misc.spin then table.insert(t, "spin") end
        if misc.flicker then table.insert(t, "flicker") end
        if #t == 0 then return nil end
        return table.concat(t, "+")
    end

    local function refreshStatus()
        local a = activeList()
        statusLabel.Text = "STATUS  " .. (a or "idle")
        statusLabel.TextColor3 = a and COLORS.Active or COLORS.TextMuted
    end

    local function startFlicker()
        local char = LocalPlayer.Character
        if not char then return end
        flickerSnap = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency < 1 then
                flickerSnap[d] = d.Transparency
            end
        end
    end

    local function stopFlicker()
        if flickerSnap then
            for part, t in pairs(flickerSnap) do
                pcall(function()
                    part.Transparency = t
                end)
            end
            flickerSnap = nil
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    RunService:BindToRenderStep("RA_misc", Enum.RenderPriority.Camera.Value + 1, function(dt)
        dt = math.clamp(dt, 0.001, 0.1)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not (char and hum and ro and cam) then return end
        if hum.Health <= 0 then return end

        -- cyberpsychosis: random horizontal jitter every frame, y untouched
        if misc.cyber and not hum.SeatPart then
            local amp = misc.cyberPower / 100
            local ang = math.random() * math.pi * 2
            local r = math.random() * amp
            ro.CFrame = ro.CFrame * CFrame.new(math.cos(ang) * r, 0, math.sin(ang) * r)
        end

        -- anti-look: dodge 1 stud sideways when a head is facing us with a clear shot
        if misc.antiLook and not hum.SeatPart then
            local now = os.clock()
            if now >= antiLookNext then
                local myHead = char:FindFirstChild("Head")
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local c = plr.Character
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        local head = c and c:FindFirstChild("Head")
                        local proot = c and c:FindFirstChild("HumanoidRootPart")
                        if h and head and proot and h.Health > 0 then
                            local toMe = ro.Position - head.Position
                            local dist = toMe.Magnitude
                            if dist > 0.5 and dist <= misc.antiLookDist then
                                if head.CFrame.LookVector:Dot(toMe.Unit) >= misc.antiLookDot / 100 then
                                    local filter = { c, char, cam }
                                    rayParams.FilterDescendantsInstances = filter
                                    local blocked = workspace:Raycast(head.Position, toMe, rayParams) ~= nil
                                    if not blocked and myHead then
                                        blocked = workspace:Raycast(head.Position, myHead.Position - head.Position, rayParams) ~= nil
                                    end
                                    if not blocked then
                                        local flat = Vector3.new(toMe.X, 0, toMe.Z)
                                        if flat.Magnitude > 0.01 then
                                            flat = flat.Unit
                                            local perp = Vector3.new(-flat.Z, 0, flat.X)
                                            dodgeFlip = not dodgeFlip
                                            ro.CFrame += (dodgeFlip and perp or -perp)
                                            antiLookNext = now + misc.antiLookCD / 100
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- noclip
        if misc.noclip and not hum.SeatPart then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.CanCollide = false
                end
            end
        end

        -- spin
        if misc.spin and not hum.SeatPart then
            ro.AssemblyAngularVelocity = Vector3.new(0, misc.spinSpeed, 0)
        end

        -- ghost flicker
        if misc.flicker and flickerSnap then
            flickerAcc += dt
            local interval = 1 / math.max(misc.flickerRate, 1)
            if flickerAcc >= interval then
                flickerAcc = 0
                local target = (math.random() < 0.5) and 1 or 0
                for part in pairs(flickerSnap) do
                    pcall(function()
                        part.Transparency = target
                    end)
                end
            end
        end
    end)

    local function onToggles(key, v)
        if key == "flicker" then
            if v then
                startFlicker()
            else
                stopFlicker()
            end
        end
        if key == "noclip" and not v then
            local char = LocalPlayer.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.CanCollide = true
                    end
                end
            end
        end
        if key == "spin" and not v then
            local char = LocalPlayer.Character
            local ro = char and char:FindFirstChild("HumanoidRootPart")
            if ro then
                ro.AssemblyAngularVelocity = Vector3.zero
            end
        end
        refreshStatus()
    end

    ui.section("MIND")
    ui.toggle("Cyberpsychosis", misc, "cyber", onToggles)
    ui.slider("Jitter Power", misc, "cyberPower", 1, 60)
    ui.toggle("Ghost Flicker", misc, "flicker", onToggles)
    ui.slider("Flicker Rate", misc, "flickerRate", 2, 30)

    ui.section("DEFENSE")
    ui.toggle("Anti-Look Dodge", misc, "antiLook", onToggles)
    ui.slider("Aim Cone", misc, "antiLookDot", 90, 100, function(v)
        return v .. "%"
    end)
    ui.slider("Range", misc, "antiLookDist", 25, 500)
    ui.slider("Dodge Cooldown", misc, "antiLookCD", 5, 100, function(v)
        return string.format("%.2fs", v / 100)
    end)

    ui.section("TRICKS")
    ui.toggle("Noclip", misc, "noclip", onToggles)
    ui.toggle("Spin", misc, "spin", onToggles)
    ui.slider("Spin Speed", misc, "spinSpeed", 5, 100)

    ui.label("anti-look reads body facing, enemy cameras are not visible client side")

    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function()
        antiLookNext = 0
        if misc.flicker then
            task.wait(0.5)
            if misc.flicker then
                startFlicker()
            end
        end
    end))

    root.Destroying:Connect(function()
        for _, c in ipairs(conns) do
            c:Disconnect()
        end
        stopFlicker()
        pcall(function()
            RunService:UnbindFromRenderStep("RA_misc")
        end)
        local char = LocalPlayer.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.CanCollide = true
                end
            end
            local ro = char:FindFirstChild("HumanoidRootPart")
            if ro then
                ro.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)
