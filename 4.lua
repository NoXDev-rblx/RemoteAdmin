----------------------------------------------------------------
-- remote admin 5.2 :: file 4/5 :: bighead + misc + user checker + mod tools
-- install beside main.lua (file 1); runs only if its AllowedUserIds gate passes
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
do
    local t0 = os.clock()
    while not LocalPlayer and os.clock() - t0 < 10 do
        task.wait(0.1)
        LocalPlayer = Players.LocalPlayer
    end
end
assert(LocalPlayer, "[RemoteAdmin] file 4: no LocalPlayer, client only")
local uiParent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
assert(uiParent, "[RemoteAdmin] file 4: PlayerGui never appeared")

----------------------------------------------------------------
-- GATE: main.lua (file 1) creates the shared RA_BUS only after its
-- AllowedUserIds check passes. No bus here = this client is not an
-- admin: stand down so none of this file's modules ever run.
----------------------------------------------------------------
local function gateClosed()
    if LocalPlayer:GetAttribute("RA_GateDenied") == true then
        return true
    end
    local t0 = os.clock()
    while not ReplicatedStorage:FindFirstChild("RA_BUS") and os.clock() - t0 < 30 do
        if LocalPlayer:GetAttribute("RA_GateDenied") == true then
            return true
        end
        task.wait(0.25)
    end
    return not ReplicatedStorage:FindFirstChild("RA_BUS")
end

if gateClosed() then
    print("[RemoteAdmin] file 4: admin gate closed (not on AllowedUserIds) - standing down")
    return
end

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
    for k, v in pairs(props) do inst[k] = v end
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
            and root:GetAttribute("Pane") == "content"
            and root:GetAttribute("ActivePage") == pageName
        root:SetAttribute("NavType", (r.kind == "slider") and "slider" or "row")
        if hl.Visible then
            local abs = r.frame.AbsolutePosition.Y - content.AbsolutePosition.Y
            if abs < 0 or abs + r.frame.AbsoluteSize.Y > content.AbsoluteSize.Y then
                content.CanvasPosition = Vector2.new(0, math.max(0, content.CanvasPosition.Y + abs - 40))
            end
        end
    end

    local function contentActive()
        return root:GetAttribute("Pane") == "content"
            and root:GetAttribute("ActivePage") == pageName
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
            if action == "pane" then
                if a == "content" and root:GetAttribute("ActivePage") == pageName then
                    setFocus(focus == 0 and 1 or focus)
                else
                    hl.Visible = false
                end
                return
            end
            if action == "page" then
                if a == pageName and root:GetAttribute("Pane") == "content" then
                    setFocus(focus == 0 and 1 or focus)
                else
                    hl.Visible = false
                end
                return
            end
            if action == "open" then
                if a and contentActive() then
                    setFocus(focus == 0 and 1 or focus)
                else
                    hl.Visible = false
                end
                return
            end
            if not contentActive() then return end
            if action == "move" then
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

    function ui.action(labelText, fn)
        local row = ui.row(24)
        local btn = make("TextButton", {
            Size = UDim2.new(1, -56, 1, 0), BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_B,
            Text = ">  " .. labelText, TextSize = 14, TextColor3 = COLORS.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        strokeOn(btn)
        make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, btn)
        local name = labelText:gsub("%W", "_")
        local chip = make("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -52, 0, 0), Size = UDim2.new(0, 48, 1, 0),
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = COLORS.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right, Text = "[--]",
        }, row)
        local function refreshChip()
            local k = root:GetAttribute("Bind_" .. prefix .. name)
            chip.Text = "[" .. ((k and k ~= "") and k or "--") .. "]"
            chip.TextColor3 = (k and k ~= "") and COLORS.Active or COLORS.TextMuted
        end
        refreshChip()
        root:GetAttributeChangedSignal("Bind_" .. prefix .. name):Connect(refreshChip)
        btn.MouseButton1Click:Connect(fn)
        ui.registerRow(row, "row", fn, name)
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

    function ui.slider(labelText, state, key, minV, maxV, display, onSet)
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
            if onSet then onSet(state[key]) end
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
-- BIGHEAD  (5.0 rewrite: studs based, force apply, safe restore)
-- ================================================================
runModule("Bighead", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Bighead] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "BIGHEAD")
    local ui = newTab(page, "BIGHEAD", root)
    local statusLabel = ui.status()

    local function setStatus(text, color)
        statusLabel.Text = "STATUS  " .. tostring(text)
        statusLabel.TextColor3 = color or COLORS.TextSecondary
    end

    local bh = {
        enabled = false,
        headStuds = 2,          -- THE editable value: head becomes stud x stud x stud
        ghost = true,
        ghostTransparency = 50,
        includeMe = false,
        scaleHats = true,
        neckFix = true,
        massless = true,
        noCollide = true,
        noTouch = true,
    }
    bh.__varRefresh = {}

    -- weak keyed: entries vanish automatically once parts are destroyed
    local bhOrig = setmetatable({}, { __mode = "k" })
    local bhNeck = setmetatable({}, { __mode = "k" })

    local function bhRemember(part)
        if not bhOrig[part] then
            local o = {
                size = part.Size,
                transparency = part.Transparency,
                canCollide = part.CanCollide,
                canTouch = part.CanTouch,
                massless = part.Massless,
            }
            local mesh = part:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                o.mesh = mesh
                o.meshScale = mesh.Scale
            end
            bhOrig[part] = o
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

    local function bhRestorePart(part, o)
        pcall(function()
            if o.mesh then
                o.mesh.Scale = o.meshScale
            end
            part.Size = o.size
            part.Transparency = o.transparency
            part.CanCollide = o.canCollide
            part.CanTouch = o.canTouch
            part.Massless = o.massless
        end)
    end

    -- active = grow head to bh.headStuds cube, inactive = exact original back.
    -- Meshes (R6/R15 head meshes) are scaled by the same ratio so the visual
    -- size really matches the chosen stud value on both rig types.
    local function bhApplyChar(char, active)
        local head = char:FindFirstChild("Head")
        if not (head and head:IsA("BasePart")) then
            return
        end
        local o = bhRemember(head)
        local s = active and bh.headStuds or o.size.X
        local ratio = s / math.max(o.size.X, 0.01)

        pcall(function()
            local wantSize = Vector3.new(s, s, s)
            if head.Size ~= wantSize then
                head.Size = wantSize
            end
            if o.mesh then
                local wantScale = o.meshScale * ratio
                if o.mesh.Scale ~= wantScale then
                    o.mesh.Scale = wantScale
                end
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
                -- lift by HALF the height delta so the head sits on the neck.
                -- the old (scale-1) * fullHeight offset pushed it sky high and
                -- contributed to the flinging.
                want = entry.c0 * CFrame.new(0, (s - o.size.Y) / 2, 0)
            else
                want = entry.c0
            end
            if motor.C0 ~= want then
                pcall(function()
                    motor.C0 = want
                end)
            end
        end

        if bh.scaleHats and active then
            for _, acc in ipairs(char:GetChildren()) do
                if acc:IsA("Accessory") then
                    local handle = acc:FindFirstChild("Handle")
                    if handle then
                        local att = handle:FindFirstChildWhichIsA("Attachment")
                        if att and (att.Name == "HatAttachment" or string.find(att.Name, "Head") ~= nil) then
                            local ho = bhRemember(handle)
                            local wantSize = ho.size * ratio
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
    end

    -- NOTE: never clears the tables, so repeated restores (hard disable)
    -- keep re-asserting the remembered originals against server resets.
    -- Weak keys clean up entries for destroyed parts automatically.
    local function bhRestoreAll()
        for part, o in pairs(bhOrig) do
            bhRestorePart(part, o)
        end
        for motor, entry in pairs(bhNeck) do
            pcall(function()
                motor.C0 = entry.c0
            end)
        end
    end

    -- per frame re-assertion; also heals whatever the game resets
    local renderConn = RunService.RenderStepped:Connect(function()
        if not bh.enabled then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then
                bhApplyChar(char, bh.includeMe or plr ~= LocalPlayer)
            end
        end
    end)

    -- hard disable: restore now, then again across the next second so nothing
    -- (server property resets included) leaves a big head behind. This is the
    -- fix for "bighead cannot be disabled".
    local function bhHardRestore()
        bh.enabled = false
        bhRestoreAll()
        task.defer(bhRestoreAll)
        task.delay(0.1, bhRestoreAll)
        task.delay(0.5, bhRestoreAll)
        task.delay(1, bhRestoreAll)
    end

    -- APPLY: full restart of the effect with the current values
    local function bhForceApply()
        bhRestoreAll()
        if bh.enabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                local char = plr.Character
                if char then
                    bhApplyChar(char, bh.includeMe or plr ~= LocalPlayer)
                end
            end
            setStatus(string.format("applied: %.1f studs", bh.headStuds), COLORS.Active)
        else
            setStatus("values reset (bighead is off)", COLORS.TextMuted)
        end
    end

    local bhBtn
    local function refreshBtn()
        if bhBtn then
            bhBtn.Text = bh.enabled and "DISABLE BIGHEAD" or "ENABLE BIGHEAD"
            bhBtn.TextColor3 = bh.enabled and COLORS.Active or COLORS.TextSecondary
        end
    end
    bhBtn = ui.button("ENABLE BIGHEAD", 32, function()
        if bh.enabled then
            bhHardRestore()
            setStatus("idle", COLORS.TextMuted)
        else
            bh.enabled = true
            setStatus(string.format("active, %.1f studs", bh.headStuds), COLORS.Active)
        end
        refreshBtn()
    end)

    ui.section("OPTIONS")
    ui.toggle("Include Me", bh, "includeMe")
    ui.toggle("Scale Hats", bh, "scaleHats")
    ui.toggle("Neck Offset", bh, "neckFix")
    ui.toggle("Ghost Head", bh, "ghost")
    ui.toggle("Massless", bh, "massless")
    ui.toggle("No Collide", bh, "noCollide")
    ui.toggle("No Touch", bh, "noTouch")

    ui.section("HEAD SIZE (STUDS)")
    local function onSizeChanged()
        if bh.enabled then
            setStatus(string.format("applied: %.1f studs", bh.headStuds), COLORS.Active)
        end
        for _, fn in ipairs(bh.__varRefresh) do
            fn()
        end
    end
    ui.varbox("Exact Size (0.5-10)", bh, "headStuds", 0.5, 10, onSizeChanged)
    ui.slider("Head Size (studs)", bh, "headStuds", 1, 10, function(v)
        return string.format("%.1f studs", v)
    end, onSizeChanged)

    ui.section("ACTIONS")
    ui.button("APPLY (FORCE RESTART)", 32, function()
        bhForceApply()
        refreshBtn()
    end)
    ui.button("RESTORE ALL (TURN OFF)", 32, function()
        bhHardRestore()
        refreshBtn()
        setStatus("idle", COLORS.TextMuted)
    end)

    ui.section("VALUES")
    ui.slider("Ghost Transparency", bh, "ghostTransparency", 0, 100, function(v)
        return v .. "%"
    end)

    ui.label("anti fling: massless + no collide + no touch, 2 studs default")
    ui.label("APPLY reruns the effect; RESTORE clears every changed part")

    root.Destroying:Connect(function()
        renderConn:Disconnect()
        bhRestoreAll()
    end)
end)

-- ================================================================
-- MISC (noclip moved to MOD TOOLS)
-- ================================================================
runModule("Misc", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/Misc] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "MISC")
    local ui = newTab(page, "MISC", root)
    local statusLabel = ui.status()

    local misc = {
        cyber = false, cyberPower = 8,
        antiLook = false, antiLookDot = 97, antiLookDist = 150, antiLookCD = 25,
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

        if misc.cyber and not hum.SeatPart then
            local amp = misc.cyberPower / 100
            local ang = math.random() * math.pi * 2
            local r = math.random() * amp
            ro.CFrame = ro.CFrame * CFrame.new(math.cos(ang) * r, 0, math.sin(ang) * r)
        end

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

        if misc.spin and not hum.SeatPart then
            ro.AssemblyAngularVelocity = Vector3.new(0, misc.spinSpeed, 0)
        end

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
    ui.toggle("Spin", misc, "spin", onToggles)
    ui.slider("Spin Speed", misc, "spinSpeed", 5, 100)

    ui.label("anti-look reads body facing, enemy cameras are not visible client side")
    ui.label("noclip and fly live in MOD TOOLS now")

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
        local ro = char and char:FindFirstChild("HumanoidRootPart")
        if ro then
            ro.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end)

-- ================================================================
-- USER CHECKER
-- ================================================================
runModule("UserChecker", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/UserChecker] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "USER CHECKER")
    local ui = newTab(page, "USER CHECKER", root)

    local state = { autoRefresh = true }

    local headRow = ui.row(104)
    local thumb = make("ImageLabel", {
        Size = UDim2.fromOffset(96, 96), Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = COLORS.Panel, Image = "", ScaleType = Enum.ScaleType.Fit,
    }, headRow)
    strokeOn(thumb)

    local nameBig = make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 106, 0, 4),
        Size = UDim2.new(1, -106, 0, 24), Font = FONT_H,
        Text = "no player selected", TextSize = 20, TextColor3 = COLORS.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, headRow)

    local nameSmall = make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 106, 0, 30),
        Size = UDim2.new(1, -106, 0, 16), Font = FONT_B,
        Text = "click someone in the player list", TextSize = 13,
        TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
    }, headRow)

    local riskLabel = make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 106, 0, 50),
        Size = UDim2.new(1, -106, 0, 16), Font = FONT_B,
        Text = "SMURF RISK  -", TextSize = 13, TextColor3 = COLORS.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, headRow)

    local valueLabels = {}
    local function infoRow(labelText)
        local r = ui.row(18)
        make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
            Font = FONT_B, Text = labelText, TextSize = 13,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
        }, r)
        local val = make("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.Code,
            Text = "-", TextSize = 12, TextColor3 = COLORS.TextSecondary,
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
        }, r)
        valueLabels[labelText] = val
    end

    ui.section("PROFILE")
    infoRow("User ID")
    infoRow("Account Age")
    infoRow("Created (est)")
    infoRow("Verified Badge")
    infoRow("Premium")
    infoRow("Friends With You")
    infoRow("Team")
    infoRow("Time In Server")

    ui.section("LIVE")
    infoRow("Health")
    infoRow("WalkSpeed")
    infoRow("Speed")
    infoRow("Position")
    infoRow("Distance")
    infoRow("Ping")
    infoRow("Tool")
    infoRow("Seated")

    ui.toggle("Auto Refresh", state, "autoRefresh")

    local focused = nil
    local joinedAt = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        joinedAt[plr] = os.clock()
    end
    local addedConn = Players.PlayerAdded:Connect(function(plr)
        joinedAt[plr] = os.clock()
    end)

    local function set(name, text, color)
        local lbl = valueLabels[name]
        if not lbl then return end
        lbl.Text = tostring(text)
        lbl.TextColor3 = color or COLORS.TextSecondary
    end

    local function clearAll()
        nameBig.Text = "no player selected"
        nameBig.TextColor3 = COLORS.TextMuted
        nameSmall.Text = "click someone in the player list"
        riskLabel.Text = "SMURF RISK  -"
        riskLabel.TextColor3 = COLORS.TextMuted
        thumb.Image = ""
        for name in pairs(valueLabels) do
            set(name, "-")
        end
    end

    local function refreshProfile()
        if not focused then
            clearAll()
            return
        end
        local plr = focused
        nameBig.Text = plr.DisplayName
        nameBig.TextColor3 = COLORS.TextPrimary
        nameSmall.Text = "@" .. plr.Name .. "  (" .. plr.UserId .. ")"

        local age = plr.AccountAge
        set("User ID", plr.UserId)
        set("Account Age", string.format("%dd (~%.1f y)", age, age / 365))
        set("Created (est)", os.date("%Y-%m-%d", os.time() - age * 86400))
        set("Verified Badge", plr.HasVerifiedBadge and "YES" or "NO",
            plr.HasVerifiedBadge and COLORS.Active or nil)
        set("Premium", (plr.MembershipType == Enum.MembershipType.Premium) and "YES"
            or tostring(plr.MembershipType))
        set("Team", plr.Team and plr.Team.Name or "none",
            plr.Team and plr.TeamColor.Color or nil)

        local risk, rcolor
        if age < 30 then
            risk, rcolor = "HIGH", Color3.fromRGB(255, 77, 77)
        elseif age < 90 then
            risk, rcolor = "MEDIUM", Color3.fromRGB(255, 152, 0)
        elseif age < 365 then
            risk, rcolor = "LOW", Color3.fromRGB(230, 200, 80)
        else
            risk, rcolor = "MINIMAL", Color3.fromRGB(96, 255, 96)
        end
        riskLabel.Text = "SMURF RISK  " .. risk
        riskLabel.TextColor3 = rcolor

        task.spawn(function()
            local ok, result = pcall(function()
                return LocalPlayer:IsFriendsWith(plr.UserId)
            end)
            if focused == plr then
                set("Friends With You", ok and (result and "YES" or "NO") or "?",
                    (ok and result) and COLORS.Active or nil)
            end
        end)

        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(plr.UserId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if ok and focused == plr then
                thumb.Image = img
            end
        end)
    end

    local function refreshLive()
        if not focused then return end
        local plr = focused
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local ro = char and char:FindFirstChild("HumanoidRootPart")

        if hum then
            set("Health", string.format("%.0f / %.0f", hum.Health, hum.MaxHealth),
                (hum.Health / math.max(hum.MaxHealth, 1) < 0.3) and Color3.fromRGB(255, 77, 77) or nil)
            set("WalkSpeed", string.format("%.0f", hum.WalkSpeed))
        else
            set("Health", "dead / loading", Color3.fromRGB(255, 77, 77))
            set("WalkSpeed", "-")
        end

        if ro then
            local p = ro.Position
            set("Position", string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z))
            set("Speed", string.format("%.1f", ro.AssemblyLinearVelocity.Magnitude))
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then
                set("Distance", string.format("%.0f studs", (p - myRoot.Position).Magnitude))
            else
                set("Distance", "-")
            end
        else
            set("Position", "-")
            set("Speed", "-")
            set("Distance", "-")
        end

        task.spawn(function()
            local ok, ping = pcall(function()
                return plr:GetNetworkPing()
            end)
            if focused == plr then
                set("Ping", ok and string.format("%d ms", ping * 1000) or "?")
            end
        end)

        local tool = char and char:FindFirstChildOfClass("Tool")
        set("Tool", tool and tool.Name or "-")
        local seat = hum and hum.SeatPart
        set("Seated", seat and seat.Parent and seat.Parent.Name or "-")

        local joined = joinedAt[plr]
        if joined then
            set("Time In Server", string.format("%dm %ds", (os.clock() - joined) / 60, (os.clock() - joined) % 60))
        end
    end

    local focusConn = root:WaitForChild("FocusEvent").Event:Connect(function(plr)
        focused = plr
        refreshProfile()
        if plr then
            local sf = root:FindFirstChild("SelectCategory")
            if sf then
                sf:Invoke("USER CHECKER")
            end
        end
    end)

    local acc = 0
    local hb = RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc < 0.5 then return end
        acc = 0
        if focused and not focused.Parent then
            focused = nil
            refreshProfile()
        end
        if state.autoRefresh then
            refreshLive()
        end
    end)

    root.Destroying:Connect(function()
        focusConn:Disconnect()
        hb:Disconnect()
        addedConn:Disconnect()
    end)

    clearAll()
end)

-- ================================================================
-- MOD TOOLS
-- ================================================================
runModule("ModTools", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/ModTools] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "MOD TOOLS")
    local ui = newTab(page, "MOD TOOLS", root)
    local statusLabel = ui.status()

    local tools = {
        fly = false, flySpeed = 60,
        noclip = false,
        xray = false, xrayAmount = 75,
        fullbright = false,
        highlights = false,
    }

    local conns = {}
    local focused = nil
    table.insert(conns, root:WaitForChild("FocusEvent").Event:Connect(function(plr)
        focused = plr
    end))

    local function activeList()
        local t = {}
        if tools.fly then table.insert(t, "fly") end
        if tools.noclip then table.insert(t, "noclip") end
        if tools.xray then table.insert(t, "xray") end
        if tools.fullbright then table.insert(t, "fullbright") end
        if tools.highlights then table.insert(t, "highlights") end
        if #t == 0 then return nil end
        return table.concat(t, "+")
    end

    local function refreshStatus()
        local a = activeList()
        statusLabel.Text = "STATUS  " .. (a or "idle")
        statusLabel.TextColor3 = a and COLORS.Active or COLORS.TextMuted
    end

    -- x-ray: walls go translucent locally, characters stay solid
    local xrayOrig = setmetatable({}, { __mode = "k" })
    local xrayConn = nil
    local function xrayApplyPart(d)
        if not d:IsA("BasePart") or d:IsA("Terrain") then return end
        local m = d:FindFirstAncestorOfClass("Model")
        if m and m:FindFirstChildOfClass("Humanoid") then return end
        if xrayOrig[d] == nil then
            xrayOrig[d] = d.Transparency
        end
        d.Transparency = math.max(d.Transparency, tools.xrayAmount / 100)
    end
    local function setXray(on)
        if on then
            for _, d in ipairs(workspace:GetDescendants()) do
                xrayApplyPart(d)
            end
            xrayConn = workspace.DescendantAdded:Connect(function(d)
                task.defer(xrayApplyPart, d)
            end)
        else
            if xrayConn then
                xrayConn:Disconnect()
                xrayConn = nil
            end
            for part, t in pairs(xrayOrig) do
                pcall(function()
                    part.Transparency = t
                end)
            end
            table.clear(xrayOrig)
        end
    end

    -- fullbright
    local fbStore = nil
    local function setFullbright(on)
        local L = game:GetService("Lighting")
        if on then
            fbStore = {
                brightness = L.Brightness, ambient = L.Ambient,
                outdoor = L.OutdoorAmbient, clock = L.ClockTime,
                fogEnd = L.FogEnd, shadows = L.GlobalShadows,
            }
            L.Brightness = 3
            L.Ambient = Color3.fromRGB(200, 200, 200)
            L.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            L.ClockTime = 14
            L.FogEnd = 1e6
            L.GlobalShadows = false
            local atmo = L:FindFirstChildOfClass("Atmosphere")
            if atmo then
                fbStore.density = atmo.Density
                atmo.Density = 0
            end
        else
            if fbStore then
                L.Brightness = fbStore.brightness
                L.Ambient = fbStore.ambient
                L.OutdoorAmbient = fbStore.outdoor
                L.ClockTime = fbStore.clock
                L.FogEnd = fbStore.fogEnd
                L.GlobalShadows = fbStore.shadows
                local atmo = L:FindFirstChildOfClass("Atmosphere")
                if atmo and fbStore.density then
                    atmo.Density = fbStore.density
                end
                fbStore = nil
            end
        end
    end

    -- player highlights
    local hlTab = setmetatable({}, { __mode = "k" })
    local hlScanAcc = 0
    local function hlScan()
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char and not hlTab[char] then
                local h = Instance.new("Highlight")
                h.FillTransparency = 1
                h.OutlineColor = plr.Team and plr.TeamColor.Color or Color3.fromRGB(255, 80, 80)
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee = char
                h.Parent = char
                hlTab[char] = h
            end
        end
        for char in pairs(hlTab) do
            if not char.Parent then
                hlTab[char] = nil
            end
        end
    end
    local function setHighlights(on)
        if not on then
            for _, h in pairs(hlTab) do
                pcall(function()
                    h:Destroy()
                end)
            end
            table.clear(hlTab)
        end
    end

    -- actions
    local function tpCursor()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not (hrp and cam) then return end
        local m = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(m.X, m.Y)
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.FilterDescendantsInstances = { char }
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, p)
        local pos
        if hit then
            pos = hit.Position + hit.Normal * 3 + Vector3.new(0, 2, 0)
        else
            pos = ray.Origin + ray.Direction * 500
        end
        hrp.CFrame = CFrame.new(pos)
        statusLabel.Text = "STATUS  tp to cursor"
        statusLabel.TextColor3 = COLORS.Active
    end

    local function tpSelected()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not focused then
            statusLabel.Text = "STATUS  no player selected (PLAYERS pane)"
            statusLabel.TextColor3 = COLORS.TextMuted
            return
        end
        local t = focused.Character and focused.Character:FindFirstChild("HumanoidRootPart")
        if not t then
            statusLabel.Text = "STATUS  target has no character"
            statusLabel.TextColor3 = COLORS.TextMuted
            return
        end
        hrp.CFrame = t.CFrame * CFrame.new(0, 0, 4)
        statusLabel.Text = "STATUS  tp to " .. focused.DisplayName
        statusLabel.TextColor3 = COLORS.Active
    end

    -- per frame: noclip + fly + highlight scan
    RunService:BindToRenderStep("RA_modtools", Enum.RenderPriority.Camera.Value + 1, function(dt)
        dt = math.clamp(dt, 0.001, 0.1)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if not (char and hum and hrp and cam) then return end
        if hum.Health <= 0 then return end

        if tools.noclip and not hum.SeatPart then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.CanCollide = false
                end
            end
        end

        if tools.fly and not hum.SeatPart then
            local f, r = 0, 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then f += 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then f -= 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then r += 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then r -= 1 end
            local up = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up += 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then up -= 1 end
            local mv = cam.CFrame.LookVector * f + cam.CFrame.RightVector * r + Vector3.new(0, up, 0)
            if mv.Magnitude > 0.01 then
                hrp.AssemblyLinearVelocity = mv.Unit * tools.flySpeed
            else
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end

        if tools.highlights then
            hlScanAcc += dt
            if hlScanAcc > 0.5 then
                hlScanAcc = 0
                hlScan()
            end
        end
    end)

    local function onToggles(key, v)
        if key == "xray" then
            setXray(v)
        elseif key == "fullbright" then
            setFullbright(v)
        elseif key == "highlights" then
            setHighlights(v)
        elseif key == "fly" and not v then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        elseif key == "noclip" and not v then
            local char = LocalPlayer.Character
            if char then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.CanCollide = true
                    end
                end
            end
        end
        refreshStatus()
    end

    ui.section("MOVEMENT")
    ui.toggle("Fly", tools, "fly", onToggles)
    ui.slider("Fly Speed", tools, "flySpeed", 10, 300)
    ui.toggle("Noclip", tools, "noclip", onToggles)

    ui.section("TELEPORT")
    ui.action("TP To Cursor", tpCursor)
    ui.action("TP To Selected Player", tpSelected)
    ui.label("select a player in the PLAYERS pane first (TAB to reach it)")

    ui.section("VISION")
    ui.toggle("X-Ray Walls", tools, "xray", onToggles)
    ui.slider("X-Ray Amount", tools, "xrayAmount", 20, 95, function(v)
        return v .. "%"
    end)
    ui.toggle("Fullbright", tools, "fullbright", onToggles)
    ui.toggle("Player Highlights", tools, "highlights", onToggles)

    ui.label("everything here is client side only")
    ui.label("actions can be bound: focus the row, SHIFT+KEY")

    table.insert(conns, LocalPlayer.CharacterAdded:Connect(function()
        if tools.noclip then
            task.wait(0.5)
            if tools.noclip then
                local char = LocalPlayer.Character
                if char then
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") then
                            d.CanCollide = false
                        end
                    end
                end
            end
        end
    end))

    root.Destroying:Connect(function()
        for _, c in ipairs(conns) do
            c:Disconnect()
        end
        setXray(false)
        setFullbright(false)
        setHighlights(false)
        pcall(function()
            RunService:UnbindFromRenderStep("RA_modtools")
        end)
        local char = LocalPlayer.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.CanCollide = true
                end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end)
