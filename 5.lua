----------------------------------------------------------------
-- remote admin 5.2 :: file 5/5 :: radar + chat spy + shield + tool scanner
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
assert(LocalPlayer, "[RemoteAdmin] file 5: no LocalPlayer, client only")
local uiParent = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
assert(uiParent, "[RemoteAdmin] file 5: PlayerGui never appeared")

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
    print("[RemoteAdmin] file 5: admin gate closed (not on AllowedUserIds) - standing down")
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
-- CHEATER RADAR
-- Client-side heuristic watch over every player, sampled every
-- heartbeat tick:
--   SPEED  - horizontal velocity above the threshold
--   TP     - one-tick displacement far beyond what their velocity
--            could have covered (teleport / lag-switch signature)
--   FLY    - sustained upward velocity without falling back
--   NOCLIP - raycast between their last and current position says
--            geometry blocked the path, yet they moved through it
-- Flags are observations made on YOUR client. Use them to decide
-- who deserves Overseer / Spectator time - they are not server
-- proof by themselves.
-- ================================================================
runModule("CheaterRadar", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/CheaterRadar] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "RADAR")
    local ui = newTab(page, "RADAR", root)
    local radarStatusLabel = ui.status()

    local radar = {
        enabled = false,
        speedThresh = 60,
        tpThresh = 60,
        flyThresh = 60,
        flyTime = 1,
        skipTeam = true,
    }

    local tracks = {}
    local logLines = {}

    local function shouldWatch(plr)
        if plr == LocalPlayer then return false end
        if not plr.Parent then return false end
        if radar.skipTeam and plr.Team and plr.Team == LocalPlayer.Team then return false end
        return true
    end

    local function ensureTrack(plr)
        if not tracks[plr] then
            tracks[plr] = {
                lastPos = nil, lastT = nil, flyStart = nil,
                cool = {}, total = 0,
                flags = { SPEED = 0, TP = 0, FLY = 0, NOCLIP = 0 },
            }
        end
        return tracks[plr]
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true

    -- live board pool -------------------------------------------------
    local LISTN = 16
    local boardPool = {}
    ui.section("LIVE BOARD (sorted by flags)")
    for i = 1, LISTN do
        local lab = make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
            Font = FONT_B, TextSize = 12, Visible = false,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, page:FindFirstChildOfClass("ScrollingFrame"))
        boardPool[i] = lab
    end

    -- event log pool --------------------------------------------------
    local LOGN = 26
    local logPool = {}
    ui.section("EVENT LOG (newest first)")
    for i = 1, LOGN do
        local lab = make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
            Font = FONT_B, TextSize = 12, Visible = false,
            TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, page:FindFirstChildOfClass("ScrollingFrame"))
        logPool[i] = lab
    end

    local function renderLog()
        for i = 1, LOGN do
            local e = logLines[i]
            if e then
                logPool[i].Text = e.text
                logPool[i].TextColor3 = e.color
                logPool[i].Visible = true
            else
                logPool[i].Visible = false
            end
        end
    end

    local function pushLog(text, color)
        table.insert(logLines, 1, { text = text, color = color })
        if #logLines > 60 then
            table.remove(logLines)
        end
        renderLog()
    end

    local function renderBoard()
        local arr = {}
        for plr, st in pairs(tracks) do
            if plr.Parent then
                table.insert(arr, { plr = plr, st = st })
            end
        end
        table.sort(arr, function(a, b)
            return a.st.total > b.st.total
        end)
        for i = 1, LISTN do
            local e = arr[i]
            if e then
                local f = e.st.flags
                local tags = {}
                if f.SPEED > 0 then table.insert(tags, "SPD:" .. f.SPEED) end
                if f.TP > 0 then table.insert(tags, "TP:" .. f.TP) end
                if f.FLY > 0 then table.insert(tags, "FLY:" .. f.FLY) end
                if f.NOCLIP > 0 then table.insert(tags, "NC:" .. f.NOCLIP) end
                local tagStr = (#tags > 0) and ("  [" .. table.concat(tags, " ") .. "]") or ""
                boardPool[i].Text = e.plr.DisplayName .. "   " .. e.st.total .. " flag(s)" .. tagStr
                if e.st.total >= 5 then
                    boardPool[i].TextColor3 = Color3.fromRGB(255, 84, 84)
                elseif e.st.total > 0 then
                    boardPool[i].TextColor3 = Color3.fromRGB(240, 180, 90)
                else
                    boardPool[i].TextColor3 = COLORS.TextMuted
                end
                boardPool[i].Visible = true
            else
                boardPool[i].Visible = false
            end
        end
    end

    local function flag(plr, st, ftype, detail, cool)
        local now = os.clock()
        if st.cool[ftype] and now < st.cool[ftype] then return end
        st.cool[ftype] = now + cool
        st.flags[ftype] += 1
        st.total += 1
        local line = "[" .. os.date("%X") .. "]  " .. plr.DisplayName .. "  " .. ftype .. "  " .. detail
        local color = (ftype == "TP" or ftype == "NOCLIP") and Color3.fromRGB(255, 84, 84)
            or Color3.fromRGB(240, 180, 90)
        pushLog(line, color)
        radarStatusLabel.Text = "STATUS  last: " .. plr.DisplayName .. " " .. ftype .. " (" .. st.total .. " total)"
        radarStatusLabel.TextColor3 = COLORS.Active
        print("[RA Radar] " .. line)
    end

    local function sample(dt)
        local filter = { workspace.CurrentCamera }
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                table.insert(filter, plr.Character)
            end
        end
        rayParams.FilterDescendantsInstances = filter

        for plr, st in pairs(tracks) do
            if not plr.Parent or not shouldWatch(plr) then
                st.lastPos = nil
                st.lastT = nil
            else
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local vel = hrp.AssemblyLinearVelocity
                    local now = os.clock()
                    if st.lastPos and st.lastT then
                        local span = math.max(now - st.lastT, 0.016)

                        local horiz = Vector3.new(vel.X, 0, vel.Z).Magnitude
                        if horiz > radar.speedThresh then
                            flag(plr, st, "SPEED", string.format("%.0f st/s horizontal", horiz), 0.75)
                        end

                        local disp = (pos - st.lastPos).Magnitude
                        local capable = vel.Magnitude * span + 8
                        if disp > radar.tpThresh and disp > capable then
                            flag(plr, st, "TP", string.format("%.0f studs in %.2fs", disp, span), 1.0)
                        end

                        if vel.Y > radar.flyThresh then
                            if not st.flyStart then st.flyStart = now end
                            if now - st.flyStart >= radar.flyTime then
                                flag(plr, st, "FLY", string.format("%.0f st/s up for %.1fs", vel.Y, now - st.flyStart), 2.0)
                                st.flyStart = now
                            end
                        else
                            st.flyStart = nil
                        end

                        if disp > 2 and disp < 400 then
                            local hit = workspace:Raycast(st.lastPos, pos - st.lastPos, rayParams)
                            if hit then
                                local blocked = (hit.Position - st.lastPos).Magnitude
                                if disp - blocked > 2 then
                                    flag(plr, st, "NOCLIP", string.format("moved %.0f studs through geometry", disp - blocked), 2.0)
                                end
                            end
                        end
                    end
                    st.lastPos = pos
                    st.lastT = now
                else
                    st.lastPos = nil
                    st.lastT = nil
                    st.flyStart = nil
                end
            end
        end
    end

    local acc = 0
    local boardAcc = 0
    local heartConn = RunService.Heartbeat:Connect(function(dt)
        if not radar.enabled then return end
        acc = math.min(acc + dt, 0.5)
        boardAcc += dt
        local step = 0.1
        local guard = 0
        while acc >= step and guard < 6 do
            acc -= step
            guard += 1
            sample(step)
        end
        if boardAcc >= 0.4 then
            boardAcc = 0
            renderBoard()
        end
    end)

    local function syncTracks()
        for _, plr in ipairs(Players:GetPlayers()) do
            if shouldWatch(plr) then
                ensureTrack(plr)
            end
        end
    end

    local plrConn = Players.PlayerAdded:Connect(function(plr)
        if radar.enabled and shouldWatch(plr) then
            ensureTrack(plr)
        end
    end)

    ui.section("DETECTORS")
    ui.toggle("Enable Radar", radar, "enabled", function(on)
        if on then
            syncTracks()
            pushLog("[" .. os.date("%X") .. "]  radar enabled", COLORS.Active)
        end
    end)
    ui.toggle("Skip Teammates", radar, "skipTeam")
    ui.slider("Speed Threshold", radar, "speedThresh", 20, 300, function(v)
        return v .. " st/s"
    end)
    ui.slider("Teleport Threshold", radar, "tpThresh", 20, 300, function(v)
        return v .. " studs"
    end)
    ui.slider("Fly Threshold", radar, "flyThresh", 20, 300, function(v)
        return v .. " st/s"
    end)
    ui.slider("Fly Sustain", radar, "flyTime", 1, 5, function(v)
        return v .. "s"
    end)
    ui.label("flags are client-side hints, not server proof")

    ui.action("CLEAR LOG + COUNTS", function()
        table.clear(logLines)
        for _, st in pairs(tracks) do
            st.total = 0
            st.flags = { SPEED = 0, TP = 0, FLY = 0, NOCLIP = 0 }
        end
        renderLog()
        renderBoard()
    end)

    root.Destroying:Connect(function()
        heartConn:Disconnect()
        plrConn:Disconnect()
    end)
    print("[RemoteAdmin/CheaterRadar] loaded")
end)

-- ================================================================
-- CHAT SPY
-- Full chat visibility for the admin: legacy Player.Chatted AND
-- TextChatService messages (new chat), team chat included, slash
-- commands highlighted. Messages mirror to the console (F9) too.
-- ================================================================
runModule("ChatSpy", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/ChatSpy] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "SPY")
    local ui = newTab(page, "SPY", root)
    local spyStatusLabel = ui.status()

    local spy = {
        enabled = false,
        showTeam = true,
        showCommands = true,
    }

    local lines = {}
    local seen = {}
    local conns = {}

    local POOLN = 30
    local pool = {}
    ui.section("CAPTURED CHAT (newest first)")
    local content = page:FindFirstChildOfClass("ScrollingFrame")
    for i = 1, POOLN do
        local lab = make("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
            Font = FONT_B, TextSize = 12, Visible = false,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, content)
        pool[i] = lab
    end

    local function fresh(key)
        local t = seen[key]
        seen[key] = os.clock()
        return not (t and os.clock() - t < 1.0)
    end

    local function render()
        for i = 1, POOLN do
            local e = lines[i]
            if e then
                pool[i].Text = e.text
                pool[i].TextColor3 = e.color
                pool[i].Visible = true
            else
                pool[i].Visible = false
            end
        end
        spyStatusLabel.Text = "STATUS  " .. #lines .. " line(s) captured"
        spyStatusLabel.TextColor3 = spy.enabled and COLORS.Active or COLORS.TextMuted
    end

    local function capture(name, text, isTeam, isCommand)
        local color = COLORS.TextSecondary
        if isCommand then
            color = Color3.fromRGB(220, 180, 90)
        elseif isTeam then
            color = COLORS.Active
        end
        local tag = isTeam and " [TEAM]" or ""
        local line = "[" .. os.date("%X") .. "] " .. name .. tag .. ": " .. text
        table.insert(lines, 1, { text = line, color = color })
        if #lines > 80 then
            table.remove(lines)
        end
        render()
        print("[RA Spy] " .. line)
    end

    local function onChat(plr, msg)
        if not spy.enabled or type(msg) ~= "string" then return end
        if not fresh(plr.UserId .. "|" .. msg) then return end
        local isCommand = string.sub(msg, 1, 1) == "/"
        if isCommand and not spy.showCommands then return end
        capture(plr.DisplayName, msg, false, isCommand)
    end

    local function hookPlayer(plr)
        table.insert(conns, plr.Chatted:Connect(function(msg)
            onChat(plr, msg)
        end))
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        hookPlayer(plr)
    end
    table.insert(conns, Players.PlayerAdded:Connect(hookPlayer))

    -- new-text chat (TextChatService): deduped against Chatted above
    pcall(function()
        local tcs = game:GetService("TextChatService")
        table.insert(conns, tcs.MessageReceived:Connect(function(msg)
            if not spy.enabled then return end
            if msg.Status ~= nil and msg.Status ~= Enum.TextChatMessageStatus.Success then return end
            local src = msg.TextSource
            if not src then return end
            local plr = Players:FindFirstChild(src.Name)
            if not plr then return end
            if not fresh(plr.UserId .. "|" .. msg.Text) then return end
            local isTeam = false
            pcall(function()
                local chName = msg.TextChannel and msg.TextChannel.Name or ""
                isTeam = string.find(chName, "Team", 1, true) ~= nil
            end)
            if isTeam and not spy.showTeam then return end
            local isCommand = string.sub(msg.Text, 1, 1) == "/"
            if isCommand and not spy.showCommands then return end
            capture(plr.DisplayName, msg.Text, isTeam, isCommand)
        end))
    end)

    ui.section("OPTIONS")
    ui.toggle("Enable Spy", spy, "enabled", render)
    ui.toggle("Show Team Chat", spy, "showTeam")
    ui.toggle("Show Slash Commands", spy, "showCommands")
    ui.label("team chat is tagged [TEAM], commands are gold")
    ui.label("everything is mirrored to the console (F9)")

    ui.action("CLEAR CAPTURE", function()
        table.clear(lines)
        render()
    end)

    root.Destroying:Connect(function()
        for _, c in ipairs(conns) do
            pcall(function()
                c:Disconnect()
            end)
        end
    end)
    print("[RemoteAdmin/ChatSpy] loaded")
end)
-- ================================================================
-- ANTI-FLING SHIELD
-- Protects YOUR character from fling exploits: watches the
-- HumanoidRootPart for absurd horizontal velocity or spin, then
-- kills the momentum, straightens the character up and (optionally)
-- anchors for a split second to eat the impulse. Falls are natural
-- downward velocity and are never touched.
-- ================================================================
runModule("AntiFling", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/AntiFling] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "SHIELD")
    local ui = newTab(page, "SHIELD", root)
    local shieldStatusLabel = ui.status()

    local shield = {
        enabled = false,
        thresh = 150,
        anchorTicks = 15,
        upright = true,
    }

    local blocked = 0
    local lastRec = 0

    local function recover(hrp)
        local now = os.clock()
        if now - lastRec < 0.25 then return end
        lastRec = now
        blocked += 1

        local vel = hrp.AssemblyLinearVelocity
        local strength = Vector3.new(vel.X, 0, vel.Z).Magnitude

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if shield.upright then
            local look = hrp.CFrame.LookVector
            local yaw = math.atan2(-look.X, -look.Z)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
        end
        local anchorTime = shield.anchorTicks / 100
        if anchorTime > 0 then
            hrp.Anchored = true
            task.delay(anchorTime, function()
                if hrp and hrp.Parent then
                    hrp.Anchored = false
                end
            end)
        end

        shieldStatusLabel.Text = "STATUS  blocked " .. blocked
            .. " fling(s) | last " .. string.format("%.0f", strength) .. " st/s"
        shieldStatusLabel.TextColor3 = Color3.fromRGB(255, 84, 84)
        print("[RA Shield] fling blocked: " .. string.format("%.0f", strength) .. " st/s horizontal")
    end

    local heartConn = RunService.Heartbeat:Connect(function()
        if not shield.enabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (hum and hum.Health > 0) then return end

        local vel = hrp.AssemblyLinearVelocity
        local horiz = Vector3.new(vel.X, 0, vel.Z).Magnitude
        local spin = hrp.AssemblyAngularVelocity.Magnitude

        if horiz > shield.thresh or spin > 60 then
            recover(hrp)
        end
    end)

    ui.section("SHIELD")
    ui.toggle("Enable Anti-Fling", shield, "enabled", function(on)
        blocked = 0
        if on then
            shieldStatusLabel.Text = "STATUS  armed"
            shieldStatusLabel.TextColor3 = COLORS.Active
        else
            shieldStatusLabel.Text = "STATUS  off"
            shieldStatusLabel.TextColor3 = COLORS.TextMuted
        end
    end)
    ui.slider("Trigger Threshold", shield, "thresh", 60, 500, function(v)
        return v .. " st/s"
    end)
    ui.slider("Anchor Time", shield, "anchorTicks", 0, 30, function(v)
        return string.format("%.2fs", v / 100)
    end)
    ui.toggle("Keep Upright", shield, "upright")
    ui.label("natural falls are never touched (vertical only)")
    ui.label("if the SERVER owns the fling it may need a second block")

    root.Destroying:Connect(function()
        heartConn:Disconnect()
    end)
    print("[RemoteAdmin/AntiFling] loaded")
end)

-- ================================================================
-- TOOL SCANNER
-- Inventories read straight off your client: lists every Tool in
-- every player's Backpack and Character (equipped marked), plus
-- loose tools dropped in workspace, with the scripts each tool
-- carries. Click a row for the full script name breakdown.
-- ================================================================
runModule("ToolScanner", function(root)
    local hud, mainFrame, list, pages = resolveUI(root)
    if not pages then
        warn("[RemoteAdmin/ToolScanner] window structure not found")
        return
    end
    local page = newCategory(root, list, pages, "TOOLS")
    local ui = newTab(page, "TOOLS", root)
    local scanStatusLabel = ui.status()

    local scan = {
        auto = false,
        alive = true,
    }
    local details = {}

    local ROWS = 24
    local rowPool = {}

    local function inspect(tool)
        local ls, sc, ms = 0, 0, 0
        local names = {}
        for _, c in ipairs(tool:GetChildren()) do
            if c:IsA("LocalScript") then
                ls += 1
                table.insert(names, "LS:" .. c.Name)
            elseif c:IsA("Script") then
                sc += 1
                table.insert(names, "S:" .. c.Name)
            elseif c:IsA("ModuleScript") then
                ms += 1
                table.insert(names, "M:" .. c.Name)
            end
        end
        return ls, sc, ms, names
    end

    ui.section("RESULTS (click a row for scripts)")
    local content = page:FindFirstChildOfClass("ScrollingFrame")
    for i = 1, ROWS do
        local btn = make("TextButton", {
            BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0,
            AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 18),
            Font = FONT_B, TextSize = 12, Visible = false,
            TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, content)
        make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, btn)
        rowPool[i] = btn
    end

    local function scanNow()
        local results = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local bp = plr:FindFirstChildOfClass("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        table.insert(results, { holder = plr.DisplayName, tool = t, equipped = false })
                    end
                end
            end
            local char = plr.Character
            if char then
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") then
                        table.insert(results, { holder = plr.DisplayName, tool = t, equipped = true })
                    end
                end
            end
        end
        for _, t in ipairs(workspace:GetChildren()) do
            if t:IsA("Tool") then
                table.insert(results, { holder = "(workspace)", tool = t, equipped = false })
            end
        end

        details = {}
        for i = 1, ROWS do
            local r = results[i]
            if r then
                local ls, sc, ms, names = inspect(r.tool)
                local flags = {}
                if r.equipped then table.insert(flags, "EQUIPPED") end
                if ls > 0 then table.insert(flags, "LSx" .. ls) end
                if sc > 0 then table.insert(flags, "Sx" .. sc) end
                if ms > 0 then table.insert(flags, "Mx" .. ms) end
                local flagStr = (#flags > 0) and ("  [" .. table.concat(flags, " ") .. "]") or ""
                rowPool[i].Text = r.holder .. " : " .. r.tool.Name .. flagStr
                rowPool[i].Visible = true
                local detail = r.holder .. " : " .. r.tool.Name
                    .. " | LocalScripts " .. ls .. ", Scripts " .. sc .. ", Modules " .. ms
                if #names > 0 then
                    detail = detail .. " | " .. table.concat(names, ", ")
                end
                details[i] = detail
            else
                rowPool[i].Visible = false
                details[i] = nil
            end
        end
        scanStatusLabel.Text = "STATUS  " .. #results .. " tool(s) found"
        scanStatusLabel.TextColor3 = (#results > 0) and COLORS.Active or COLORS.TextMuted
    end

    for i = 1, ROWS do
        local idx = i
        rowPool[i].MouseButton1Click:Connect(function()
            if details[idx] then
                scanStatusLabel.Text = "STATUS  " .. details[idx]
            end
        end)
    end

    ui.section("ACTIONS")
    ui.button("SCAN NOW", 26, scanNow)
    ui.toggle("Auto Rescan (5s)", scan, "auto")
    ui.label("reads backpacks + characters + loose tools")
    ui.label("LS = LocalScript, S = Script, M = ModuleScript")

    task.spawn(function()
        while scan.alive do
            task.wait(5)
            if scan.auto then
                pcall(scanNow)
            end
        end
    end)

    root.Destroying:Connect(function()
        scan.alive = false
    end)
    print("[RemoteAdmin/ToolScanner] loaded")
end)

print("[RemoteAdmin] file 5 loaded (radar / spy / shield / tools)")
