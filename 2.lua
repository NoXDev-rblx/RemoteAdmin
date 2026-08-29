----------------------------------------------------------------
-- remote admin 4.6.1 :: file 2/4 :: movement + spectator
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
        if sf then sf:Invoke(page.Visible and nil or name) end
    end)
    return page
end

local function newTab(page, pageName, root)
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
    make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, content)

    local order = 0
    local function nextOrder()
        order += 1
        return order
    end

    local rows = {}
    local focus = 0
    local prefix = pageName .. "_"
    local hl = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 60, Visible = false,
    }, content)
    make("UIStroke", { Color = COLORS.Active, Thickness = 1.5 }, hl)

    local function setFocus(i)
        local n = #rows
        if n == 0 then
            focus = 0
            hl.Visible = false
            return
        end
        focus = ((i - 1) % n) + 1
        local r = rows[focus]
        hl.Parent = r.frame
        hl.Visible = root:GetAttribute("Open") == true
        root:SetAttribute("NavType", (r.kind == "slider") and "slider" or "row")
    end

    local navConn = root:WaitForChild("NavEvent", 10)
    if navConn then
        navConn.Event:Connect(function(action, a)
            if action == "fire" then
                for _, r in ipairs(rows) do
                    if r.name == a and r.activate then
                        r.activate()
                        break
                    end
                end
                return
            end
            if root:GetAttribute("ActivePage") ~= pageName then return end
            if action == "page" then
                if a == pageName then
                    setFocus(focus == 0 and 1 or focus)
                else
                    hl.Visible = false
                end
            elseif action == "open" then
                if a then
                    setFocus(focus == 0 and 1 or focus)
                else
                    hl.Visible = false
                end
            elseif action == "move" then
                if #rows > 0 then setFocus(focus + a) end
            elseif action == "activate" then
                local r = rows[focus]
                if r and r.activate then r.activate() end
            elseif action == "adjust" then
                local r = rows[focus]
                if r and r.adjust then r.adjust(a) end
            elseif action == "bind" then
                local r = rows[focus]
                if r and r.name then
                    -- one key, one action: strip this key from every other row first
                    for attr, val in pairs(root:GetAttributes()) do
                        if string.sub(attr, 1, 5) == "Bind_" and val == a then
                            root:SetAttribute(attr, "")
                        end
                    end
                    root:SetAttribute("Bind_" .. r.name, a)
                end
            elseif action == "clearbind" then
                local r = rows[focus]
                if r and r.name then
                    root:SetAttribute("Bind_" .. r.name, "")
                end
            end
        end)
    end

    local ui = {}

    function ui.registerRow(frame, kind, activate, name)
        table.insert(rows, {
            frame = frame, kind = kind or "row", activate = activate,
            name = name and (prefix .. name) or nil,
        })
    end

    function ui.status()
        return make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
            Font = FONT_B, Text = "STATUS  idle", TextSize = 13,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = nextOrder(),
        }, content)
    end

    function ui.button(text, h, onClick)
        local btn = make("TextButton", {
            Size = UDim2.new(1, 0, 0, h or 28), BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_H,
            Text = text, TextSize = 14, TextColor3 = COLORS.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
        }, content)
        strokeOn(btn)
        make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)
        if onClick then
            btn.MouseButton1Click:Connect(onClick)
            ui.registerRow(btn, "row", onClick, text:gsub("%W", "_"))
        end
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
            BackgroundTransparency = 1, Size = UDim2.new(1, -110, 1, 0),
            Font = FONT_B, Text = labelText, TextSize = 14,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        local btn = make("TextButton", {
            Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(1, -52, 0, 0),
            BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0,
            AutoButtonColor = false, Font = FONT_B, TextSize = 13,
        }, row)
        strokeOn(btn)
        local name = prefix .. labelText:gsub("%W", "_")
        local chip = make("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -58, 0, 0), Size = UDim2.new(0, 48, 1, 0),
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = COLORS.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right, Text = "[--]",
        }, row)
        local function refresh()
            btn.Text = state[key] and "ON" or "OFF"
            btn.TextColor3 = state[key] and COLORS.Active or COLORS.TextMuted
        end
        local function refreshChip()
            local k = root:GetAttribute("Bind_" .. name)
            chip.Text = "[" .. ((k and k ~= "") and k or "--") .. "]"
            chip.TextColor3 = (k and k ~= "") and COLORS.Active or COLORS.TextMuted
        end
        refresh()
        refreshChip()
        root:GetAttributeChangedSignal("Bind_" .. name):Connect(refreshChip)
        local function activate()
            state[key] = not state[key]
            refresh()
            if onChange then onChange(state[key]) end
        end
        btn.MouseButton1Click:Connect(activate)
        ui.registerRow(row, "row", activate, labelText:gsub("%W", "_"))
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
                if onSet then onSet(key) end
            else
                box.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.delay(0.4, function()
                    box.TextColor3 = COLORS.TextPrimary
                end)
            end
            box.Text = tostring(state[key])
        end)
        if state.__varRefresh then
            table.insert(state.__varRefresh, function()
                box.Text = tostring(state[key])
            end)
        end
        ui.registerRow(row, "varbox", function()
            box:CaptureFocus()
        end)
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
        local function apply(v)
            state[key] = math.clamp(v, minV, maxV)
            val.Text = text(state[key])
            fill.Size = UDim2.new((state[key] - minV) / (maxV - minV), 0, 1, 0)
        end
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            apply(math.floor(minV + rel * (maxV - minV) + 0.5))
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
        ui.registerRow(row, "slider", nil, nil)
        rows[#rows].adjust = apply
    end

    return ui
end

local function runModule(name, fn)
    task.spawn(function()
        local function attempt(bus)
            if bus:GetAttribute("Mod_" .. name) then return end
            bus:SetAttribute("Mod_" .. name, true)
            local ok = xpcall(fn, function(e)
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
        if existing then hookBus(existing) end
        ReplicatedStorage.ChildAdded:Connect(function(child)
            if child.Name == "RA_BUS" then hookBus(child) end
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
    local ui = newTab(page, "MOVEMENT", root)
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
        customFov = false, fovValue = 90, fpSens = 1, modeIndex = 1, fpOn = false,
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

    local spdGui = Instance.new("ScreenGui")
    spdGui.Name = "RA_Speed"
    spdGui.ResetOnSpawn = false
    spdGui.IgnoreGuiInset = true
    spdGui.DisplayOrder = 45
    spdGui.Parent = uiParent
    local spdLbl = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        Size = UDim2.new(0, 220, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code, TextSize = 18,
        TextColor3 = COLORS.Active, Text = "",
    }, spdGui)

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
        -- re-assert every frame, something out there keeps clearing it
        if not hum.PlatformStand then hum.PlatformStand = true end
        if hum.AutoRotate then hum.AutoRotate = false end

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

    local ENGINE_STATES = {
        Enum.HumanoidStateType.Landed,
        Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Freefall,
    }

    local function setEngine(on, hum, ro)
        if on then
            if not (hum and ro) or engineOn then return end
            engineOn = true
            for _, st in ipairs(ENGINE_STATES) do
                pcall(function()
                    hum:SetStateEnabled(st, false)
                end)
            end
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
            for _, st in ipairs(ENGINE_STATES) do
                pcall(function()
                    hum:SetStateEnabled(st, true)
                end)
            end
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
            or root:GetAttribute("Open") == true
        UserInputService.MouseBehavior = busy and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    end

    local function setFP(on)
        if fp == on then return end
        fp = on
        settings.fpOn = on
        root:SetAttribute("FP", on)
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

    local function toggleBhop()
        setEnabled(not settings.enabled)
    end
    toggleBtn = ui.button("ENABLE BHOP", 32, toggleBhop)

    ui.section("MOVEMENT MODE")
    local modeRow = ui.row(26)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, modeRow)

    local function applyModeSwitch(i)
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
    end

    for i, mode in ipairs(MODES) do
        local btn = make("TextButton", {
            Size = UDim2.new(0.333, -4, 1, 0), BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_B,
            Text = mode.name, TextSize = 13, TextColor3 = COLORS.TextSecondary,
        }, modeRow)
        strokeOn(btn)
        table.insert(modeButtons, btn)

        btn.MouseButton1Click:Connect(function()
            applyModeSwitch(i)
        end)
    end
    refreshModeButtons()

    ui.registerRow(modeRow, "row", function()
        applyModeSwitch((settings.modeIndex % #MODES) + 1)
    end, "Cycle_Mode")

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
    ui.toggle("First Person", settings, "fpOn", function(v)
        setFP(v)
    end)
    root:SetAttribute("Bind_MOVEMENT_First_Person", "Equals")

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

        local function doSave()
            local t = {}
            for _, k in ipairs(PRESET_KEYS) do
                t[k] = settings[k]
            end
            presetSlots[slot] = t
            loadBtn.TextColor3 = COLORS.Active
            setStatus("saved settings to slot " .. slot, COLORS.Active)
        end
        local function doLoad()
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
        end
        saveBtn.MouseButton1Click:Connect(doSave)
        loadBtn.MouseButton1Click:Connect(doLoad)
        ui.registerRow(prow, "row", doLoad, "Load_Slot_" .. slot)
    end

    ui.label("[space] hop   [shift+key on a row] bind it   [shift+bksp] clear bind")
    ui.label("click the active mode again to reload its defaults")
    ui.label("left/right on a slider row adjusts it")

    table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode and not processed then
            local name = input.KeyCode.Name
            if M.keys[name] ~= nil then
                M.keys[name] = true
            end
            if name == "Space" then
                M.lastSpace = os.clock()
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

        if settings.enabled then
            spdLbl.Text = string.format("SPD %.1f",
                Vector3.new(ro.AssemblyLinearVelocity.X, 0, ro.AssemblyLinearVelocity.Z).Magnitude)
        else
            spdLbl.Text = ""
        end

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
        spdGui:Destroy()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)
end)

-- ================================================================
-- SPECTATOR
-- ================================================================
runModule("Spectator", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Spectator] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "SPECTATOR")
    local ui = newTab(page, "SPECTATOR", root)
    local statusLabel = ui.status()

    local spec = { enabled = false, speed = 60, showChar = false }
    local conns = {}
    local yaw, pitch = 0, 0
    local pos = Vector3.zero
    local keys = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }
    local camPos = nil

    local function setCharHidden(char, hidden)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then
                d.LocalTransparencyModifier = hidden and 1 or 0
            end
        end
    end

    local function setSpec(on)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        spec.enabled = on
        root:SetAttribute("FP", on)
        if on then
            if ro then
                ro.Anchored = true
                ro.AssemblyLinearVelocity = Vector3.zero
                ro.AssemblyAngularVelocity = Vector3.zero
                pos = ro.Position + Vector3.new(0, 2, 0)
            end
            if char then
                setCharHidden(char, not spec.showChar)
            end
            local lv = cam.CFrame.LookVector
            yaw = math.atan2(-lv.X, -lv.Z)
            pitch = math.clamp(math.asin(math.clamp(lv.Y, -1, 1)), -1.45, 1.45)
            cam.CameraType = Enum.CameraType.Scriptable
            statusLabel.Text = "STATUS  spectating, character frozen"
            statusLabel.TextColor3 = COLORS.Active
        else
            if ro then
                ro.Anchored = false
            end
            if char then
                setCharHidden(char, false)
            end
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                if hum then
                    cam.CameraSubject = hum
                end
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            statusLabel.Text = "STATUS  idle"
            statusLabel.TextColor3 = COLORS.TextMuted
        end
    end

    local specBtn
    specBtn = ui.button("START SPECTATING", 32, function()
        setSpec(not spec.enabled)
        specBtn.Text = spec.enabled and "STOP SPECTATING" or "START SPECTATING"
        specBtn.TextColor3 = spec.enabled and COLORS.Active or COLORS.TextSecondary
    end)

    ui.section("CAMERA")
    ui.slider("Fly Speed", spec, "speed", 10, 400)
    ui.toggle("Show My Character", spec, "showChar", function(v)
        local char = LocalPlayer.Character
        if char and spec.enabled then
            setCharHidden(char, not v)
        end
    end)

    ui.label("[wasd] move   [space] up   [left shift] down")
    ui.label("[alt] free cursor   freecam ignores walls")

    table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode and not processed then
            local n = input.KeyCode.Name
            if keys[n] ~= nil then keys[n] = true end
        end
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode and keys[input.KeyCode.Name] ~= nil then
            keys[input.KeyCode.Name] = false
        end
    end))
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and spec.enabled then
            if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
                and root:GetAttribute("Open") ~= true
                and UserInputService:GetFocusedTextBox() == nil then
                yaw -= input.Delta.X * 0.0032
                pitch = math.clamp(pitch - input.Delta.Y * 0.0032, -1.45, 1.45)
            end
        end
    end))

    RunService:BindToRenderStep("RA_spectator", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not spec.enabled then return end
        dt = math.clamp(dt, 0.001, 0.1)
        local cam = workspace.CurrentCamera
        if not cam then return end
        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end

        local menuOpen = root:GetAttribute("Open") == true
        local busy = menuOpen or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
            or UserInputService:GetFocusedTextBox() ~= nil
        UserInputService.MouseBehavior = busy and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter

        local cf = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        local move = Vector3.zero
        if keys.W then move += cf.LookVector end
        if keys.S then move -= cf.LookVector end
        if keys.D then move += cf.RightVector end
        if keys.A then move -= cf.RightVector end
        if keys.Space then move += Vector3.yAxis end
        if keys.LeftShift then move -= Vector3.yAxis end
        if move.Magnitude > 0.01 then
            pos += move.Unit * spec.speed * dt
        end

        if camPos == nil then
            camPos = pos
        else
            camPos += (pos - camPos) * math.clamp(dt * 20, 0, 1)
        end
        cam.CFrame = CFrame.new(camPos) * cf
    end)

    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function(char)
        if not spec.enabled then return end
        task.spawn(function()
            local ro = char:WaitForChild("HumanoidRootPart", 10)
            if ro and spec.enabled then
                ro.Anchored = true
                ro.AssemblyLinearVelocity = Vector3.zero
                setCharHidden(char, not spec.showChar)
            end
        end)
    end))

    root.Destroying:Connect(function()
        for _, c in ipairs(conns) do
            c:Disconnect()
        end
        pcall(function()
            RunService:UnbindFromRenderStep("RA_spectator")
        end)
        local char = LocalPlayer.Character
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        if ro then
            ro.Anchored = false
        end
        if char then
            setCharHidden(char, false)
        end
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
        root:SetAttribute("FP", false)
    end)
end)
