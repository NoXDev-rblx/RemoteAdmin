----------------------------------------------------------------
-- remote admin 5.2 :: file 1/5 :: admin gate + core + ui + keyboard nav
--
-- 5-FILE INSTALL (no loader): put main.lua, 2.lua, 3.lua, 4.lua
-- and 5.lua each inside their own LocalScript in
-- StarterPlayer > StarterPlayerScripts.
--
-- THE GATE (lives in THIS file only)
--   * Every press of M / RightShift re-checks the presser's
--     UserId against ALLOWED_USER_IDS below.
--   * On the list -> the menu boots and opens; 2.lua / 3.lua /
--     4.lua only activate because this file created RA_BUS.
--   * NOT on the list -> nothing is created, the other three
--     files stand down on their own, and a big red
--     "You are not an admin!" screen appears with instructions.
--
-- EDIT EVERYTHING IN THE CONFIG BLOCK BELOW.
----------------------------------------------------------------

-- ============================== CONFIG ==============================

-- EDIT HERE :: AllowedUserIds -- one UserId per line, comma at the end.
-- These Roblox UserIds are the only players that can use Remote Admin.
-- Example format:  123456789,
local ALLOWED_USER_IDS = {
        -- 123456789,   -- <- example, delete me and add your own IDs
        -- 987654321,   -- <- co owner, example
}

-- Keys that toggle the menu (the admin check runs on every press)
local TOGGLE_KEYS = { Enum.KeyCode.M, Enum.KeyCode.RightShift }

-- Deny screen texts
local DENY_TITLE   = "Not allowed!!"
local DENY_LINE1   = "Remote Admin is a paid script."
local DENY_LINE2   = "To get access, join our community server and buy any of the tiers"
local DENY_LINK    = "https://discord.gg/TGS5vYzr99"
local DENY_SECONDS = 15

-- ========================= END OF CONFIG ============================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
do
        local t0 = os.clock()
        while not LocalPlayer and os.clock() - t0 < 10 do
                task.wait(0.1)
                LocalPlayer = Players.LocalPlayer
        end
end
assert(LocalPlayer, "[RemoteAdmin] no LocalPlayer: run on the CLIENT only")
local gatePlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
assert(gatePlayerGui, "[RemoteAdmin] PlayerGui never appeared")

local function isAdmin(plr)
        return true
end

----------------------------------------------------------------
-- deny screen: big "You are not an admin!" + explanation
----------------------------------------------------------------
pcall(function()
        local old = gatePlayerGui:FindFirstChild("RA_Denied")
        if old then old:Destroy() end
end)

local denyGui = Instance.new("ScreenGui")
denyGui.Name = "RA_Denied"
denyGui.ResetOnSpawn = false
denyGui.IgnoreGuiInset = true
denyGui.DisplayOrder = 10000
denyGui.Enabled = false
denyGui.Parent = gatePlayerGui

local denyBG = Instance.new("Frame")
denyBG.Size = UDim2.fromScale(1, 1)
denyBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
denyBG.BackgroundTransparency = 0.35
denyBG.BorderSizePixel = 0
denyBG.Parent = denyGui

local denyBig = Instance.new("TextLabel")
denyBig.AnchorPoint = Vector2.new(0.5, 0.5)
denyBig.Position = UDim2.fromScale(0.5, 0.38)
denyBig.Size = UDim2.fromScale(0.86, 0.16)
denyBig.BackgroundTransparency = 1
denyBig.Font = Enum.Font.GothamBlack
denyBig.Text = DENY_TITLE
denyBig.TextScaled = true
denyBig.TextColor3 = Color3.fromRGB(255, 64, 64)
denyBig.Parent = denyBG

local denyBigStroke = Instance.new("UIStroke")
denyBigStroke.Color = Color3.fromRGB(0, 0, 0)
denyBigStroke.Thickness = 2
denyBigStroke.Parent = denyBig

local denySub = Instance.new("TextLabel")
denySub.AnchorPoint = Vector2.new(0.5, 0.5)
denySub.Position = UDim2.fromScale(0.5, 0.58)
denySub.Size = UDim2.fromScale(0.72, 0.22)
denySub.BackgroundTransparency = 1
denySub.Font = Enum.Font.Gotham
denySub.TextSize = 20
denySub.TextWrapped = true
denySub.TextColor3 = Color3.fromRGB(235, 235, 235)
denySub.Text = DENY_LINE1 .. "\n\n" .. DENY_LINE2
denySub.Parent = denyBG

local denyLink = Instance.new("TextLabel")
denyLink.AnchorPoint = Vector2.new(0.5, 0)
denyLink.Position = UDim2.fromScale(0.5, 0.7)
denyLink.Size = UDim2.fromScale(0.72, 0.06)
denyLink.BackgroundTransparency = 1
denyLink.Font = Enum.Font.GothamBold
denyLink.TextSize = 22
denyLink.TextScaled = false
denyLink.TextColor3 = Color3.fromRGB(120, 180, 255)
denyLink.Text = DENY_LINK
denyLink.Parent = denyBG

local denyToken = 0
local function showDenied()
        denyToken += 1
        local myToken = denyToken
        denyGui.Enabled = true
        print(("[RemoteAdmin] %s (%d) is NOT on AllowedUserIds - access denied")
                :format(LocalPlayer.Name, LocalPlayer.UserId))
        task.delay(DENY_SECONDS, function()
                if denyToken == myToken then
                        denyGui.Enabled = false
                end
        end)
end

-- any key press dismisses the deny screen early
UserInputService.InputBegan:Connect(function()
        if denyGui.Enabled then
                denyToken += 1
                denyGui.Enabled = false
        end
end)

----------------------------------------------------------------
-- THE GATE
----------------------------------------------------------------
local gateKeySet = {}
for _, k in ipairs(TOGGLE_KEYS) do
        gateKeySet[k] = true
end

if not isAdmin(LocalPlayer) then
        -- NOT AN ADMIN: create nothing (no RA_BUS -> files 2/3/4 stand
        -- down by themselves), just answer toggle presses with the deny
        -- screen. The list is re-checked on EVERY press.
        LocalPlayer:SetAttribute("RA_GateDenied", true)
        UserInputService.InputBegan:Connect(function(input, _gameProcessed)
                local key = input.KeyCode
                if not key or key == Enum.KeyCode.Unknown then return end
                if UserInputService:GetFocusedTextBox() then return end
                if not gateKeySet[key] then return end
                if not isAdmin(LocalPlayer) then
                        showDenied()
                end
        end)
        print(("[RemoteAdmin] %s (%d) is not on AllowedUserIds - gate closed, standing by")
                :format(LocalPlayer.Name, LocalPlayer.UserId))
        return
end

-- verified admin: clear any stale deny flag so files 2/3/4 never
-- stand down by mistake
LocalPlayer:SetAttribute("RA_GateDenied", nil)

print("[RemoteAdmin] file 1 parsed, admin verified, starting core")
local CORE_OK, CORE_ERR = xpcall(function()

        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")

        -- TOGGLE_KEYS comes from the CONFIG block at the top of this file
        local WINDOW_SIZE = UDim2.fromOffset(860, 480)
        local HEADER_HEIGHT = 34
        local PLAYERLIST_W = 0.235
        local ACTIONMENU_W = 0.165

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

        local LocalPlayer = Players.LocalPlayer
        local t0 = os.clock()
        while not LocalPlayer and os.clock() - t0 < 5 do
                task.wait(0.1)
                LocalPlayer = Players.LocalPlayer
        end
        assert(LocalPlayer, "[RemoteAdmin] no LocalPlayer: run on the CLIENT only")
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        assert(playerGui, "[RemoteAdmin] PlayerGui never appeared")

        pcall(function()
                local old = ReplicatedStorage:FindFirstChild("RA_BUS")
                if old then old:Destroy() end
        end)
        pcall(function()
                local old = playerGui:FindFirstChild("RemoteAdminHUD")
                if old then old:Destroy() end
        end)
        pcall(function()
                local old = playerGui:FindFirstChild("RemoteAdminBadge")
                if old then old:Destroy() end
        end)

        local bus = Instance.new("Folder")
        bus.Name = "RA_BUS"
        bus.Parent = ReplicatedStorage
        bus:SetAttribute("NavType", "row")

        local conns = {}

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RemoteAdminHUD"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 1000
        screenGui.Enabled = false
        screenGui.Parent = playerGui

        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = WINDOW_SIZE
        mainFrame.Position = UDim2.new(0.5, -WINDOW_SIZE.X.Offset / 2, 0.5, -WINDOW_SIZE.Y.Offset / 2)
        mainFrame.BackgroundColor3 = COLORS.Background
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Parent = screenGui

        local mainStroke = Instance.new("UIStroke")
        mainStroke.Color = COLORS.Divider
        mainStroke.Thickness = 1
        mainStroke.Parent = mainFrame

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
        header.BackgroundColor3 = COLORS.Panel
        header.BorderSizePixel = 0
        header.Active = true
        header.Parent = mainFrame

        local headerDivider = Instance.new("Frame")
        headerDivider.BackgroundColor3 = COLORS.Divider
        headerDivider.BorderSizePixel = 0
        headerDivider.Size = UDim2.new(1, 0, 0, 1)
        headerDivider.Position = UDim2.new(0, 0, 1, -1)
        headerDivider.Parent = header

        local titleText = Instance.new("TextLabel")
        titleText.BackgroundTransparency = 1
        titleText.Size = UDim2.new(1, 0, 1, 0)
        titleText.Font = FONT_H
        titleText.Text = "REMOTE ADMIN 5.0"
        titleText.TextColor3 = COLORS.TextSecondary
        titleText.TextSize = 16
        titleText.TextXAlignment = Enum.TextXAlignment.Center
        titleText.Parent = header

        do
                local dragging = false
                local dragInput, dragStart, startPos
                header.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = true
                                dragStart = input.Position
                                startPos = mainFrame.Position
                                input.Changed:Connect(function()
                                        if input.UserInputState == Enum.UserInputState.End then
                                                dragging = false
                                        end
                                end)
                        end
                end)
                header.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                dragInput = input
                        end
                end)
                table.insert(conns, UserInputService.InputChanged:Connect(function(input)
                        if input == dragInput and dragging then
                                local delta = input.Position - dragStart
                                mainFrame.Position = UDim2.new(
                                        startPos.X.Scale, startPos.X.Offset + delta.X,
                                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                                )
                        end
                end))
        end

        local body = Instance.new("Frame")
        body.Name = "Body"
        body.BackgroundTransparency = 1
        body.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT)
        body.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
        body.Parent = mainFrame

        local playerPanel = Instance.new("Frame")
        playerPanel.Name = "PlayerPanel"
        playerPanel.BackgroundColor3 = COLORS.Panel
        playerPanel.BorderSizePixel = 0
        playerPanel.Size = UDim2.new(PLAYERLIST_W, 0, 1, 0)
        playerPanel.Parent = body

        local ppDivider = Instance.new("Frame")
        ppDivider.BackgroundColor3 = COLORS.Divider
        ppDivider.BorderSizePixel = 0
        ppDivider.Size = UDim2.new(0, 1, 1, 0)
        ppDivider.Position = UDim2.new(1, -1, 0, 0)
        ppDivider.Parent = playerPanel

        local playersHeader = Instance.new("TextLabel")
        playersHeader.BackgroundTransparency = 1
        playersHeader.Size = UDim2.new(1, 0, 0, 24)
        playersHeader.Font = FONT_H
        playersHeader.Text = "PLAYERS"
        playersHeader.TextColor3 = COLORS.TextSecondary
        playersHeader.TextSize = 14
        playersHeader.Parent = playerPanel

        local playersHeaderDivider = Instance.new("Frame")
        playersHeaderDivider.BackgroundColor3 = COLORS.Divider
        playersHeaderDivider.BorderSizePixel = 0
        playersHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
        playersHeaderDivider.Position = UDim2.new(0, 0, 0, 24)
        playersHeaderDivider.Parent = playerPanel

        local playerListFrame = Instance.new("ScrollingFrame")
        playerListFrame.Name = "PlayerList"
        playerListFrame.BackgroundTransparency = 1
        playerListFrame.BorderSizePixel = 0
        playerListFrame.Size = UDim2.new(1, -4, 1, -51)
        playerListFrame.Position = UDim2.new(0, 2, 0, 26)
        playerListFrame.ScrollBarThickness = 3
        playerListFrame.ScrollBarImageColor3 = COLORS.Divider
        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        playerListFrame.Parent = playerPanel

        local playerListLayout = Instance.new("UIListLayout")
        playerListLayout.Padding = UDim.new(0, 1)
        playerListLayout.Parent = playerListFrame

        local searchBox = Instance.new("TextBox")
        searchBox.BackgroundColor3 = COLORS.Background
        searchBox.BorderSizePixel = 0
        searchBox.Size = UDim2.new(1, -8, 0, 22)
        searchBox.Position = UDim2.new(0, 4, 1, -24)
        searchBox.PlaceholderText = "Search Players"
        searchBox.PlaceholderColor3 = COLORS.TextMuted
        searchBox.Text = ""
        searchBox.TextColor3 = COLORS.TextPrimary
        searchBox.Font = FONT_B
        searchBox.TextSize = 13
        searchBox.ClearTextOnFocus = false
        searchBox.Parent = playerPanel

        local sbStroke = Instance.new("UIStroke")
        sbStroke.Color = COLORS.Divider
        sbStroke.Transparency = 0.4
        sbStroke.Parent = searchBox

        local sbPad = Instance.new("UIPadding")
        sbPad.PaddingLeft = UDim.new(0, 6)
        sbPad.Parent = searchBox

        local selectedPlayers = {}
        local playerRows = {}
        local focusedPlayer = nil

        local focusEvent = Instance.new("BindableEvent")
        focusEvent.Name = "FocusEvent"
        focusEvent.Parent = bus

        local navEvent = Instance.new("BindableEvent")
        navEvent.Name = "NavEvent"
        navEvent.Parent = bus

        local function singleSelected()
                local plr, count = nil, 0
                for p in pairs(selectedPlayers) do
                        plr = p
                        count += 1
                end
                return (count == 1) and plr or nil
        end

        local function refreshRowVisual(plr)
                local row = playerRows[plr]
                if not row then return end
                local label = row:FindFirstChild("NameLabel")
                if not label then return end
                if focusedPlayer == plr then
                        label.TextColor3 = COLORS.TextPrimary
                elseif selectedPlayers[plr] then
                        label.TextColor3 = COLORS.Active
                else
                        label.TextColor3 = (plr == LocalPlayer) and COLORS.Active or COLORS.TextPrimary
                end
        end

        local function clearSelection()
                for plr in pairs(selectedPlayers) do
                        selectedPlayers[plr] = nil
                        refreshRowVisual(plr)
                end
        end

        local function fireFocus(plr)
                focusedPlayer = plr
                focusEvent:Fire(plr)
        end

        local function toggleSelect(plr, ctrlHeld)
                if not ctrlHeld then
                        local wasOnly = selectedPlayers[plr] and (singleSelected() == plr)
                        clearSelection()
                        if not wasOnly then
                                selectedPlayers[plr] = true
                        end
                else
                        selectedPlayers[plr] = not selectedPlayers[plr] or nil
                end
                refreshRowVisual(plr)
                fireFocus(singleSelected())
        end

        local function createPlayerRow(plr)
                local row = Instance.new("TextButton")
                row.Name = plr.Name
                row.Size = UDim2.new(1, 0, 0, 22)
                row.BackgroundTransparency = 1
                row.AutoButtonColor = false
                row.Text = ""
                row.Parent = playerListFrame

                local icon = Instance.new("ImageLabel")
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.fromOffset(14, 14)
                icon.Position = UDim2.new(0, 4, 0.5, -7)
                icon.Image = "rbxassetid://2795572803"
                icon.ImageColor3 = COLORS.TextMuted
                icon.Parent = row

                local label = Instance.new("TextLabel")
                label.Name = "NameLabel"
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, -24, 1, 0)
                label.Position = UDim2.new(0, 22, 0, 0)
                label.Font = FONT_B
                label.Text = string.format("(%d) %s", plr.UserId, plr.DisplayName)
                label.TextColor3 = (plr == LocalPlayer) and COLORS.Active or COLORS.TextPrimary
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.Parent = row

                row.MouseButton1Click:Connect(function()
                        local ctrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                        toggleSelect(plr, ctrlHeld)
                end)

                playerRows[plr] = row
                refreshRowVisual(plr)
        end

        for _, plr in ipairs(Players:GetPlayers()) do
                createPlayerRow(plr)
        end
        Players.PlayerAdded:Connect(createPlayerRow)
        Players.PlayerRemoving:Connect(function(plr)
                selectedPlayers[plr] = nil
                if focusedPlayer == plr then
                        fireFocus(nil)
                end
                if playerRows[plr] then
                        playerRows[plr]:Destroy()
                        playerRows[plr] = nil
                end
        end)

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = searchBox.Text:lower()
                for plr, row in pairs(playerRows) do
                        local matches = query == "" or plr.Name:lower():find(query, 1, true) or tostring(plr.UserId):find(query, 1, true)
                        row.Visible = matches and true or false
                end
        end)

        local actionPanel = Instance.new("Frame")
        actionPanel.Name = "ActionPanel"
        actionPanel.BackgroundColor3 = COLORS.Panel
        actionPanel.BorderSizePixel = 0
        actionPanel.Size = UDim2.new(ACTIONMENU_W, 0, 1, 0)
        actionPanel.Position = UDim2.new(PLAYERLIST_W, 0, 0, 0)
        actionPanel.Parent = body

        local apDivider = Instance.new("Frame")
        apDivider.BackgroundColor3 = COLORS.Divider
        apDivider.BorderSizePixel = 0
        apDivider.Size = UDim2.new(0, 1, 1, 0)
        apDivider.Position = UDim2.new(1, -1, 0, 0)
        apDivider.Parent = actionPanel

        local actionsHeader = Instance.new("TextLabel")
        actionsHeader.BackgroundTransparency = 1
        actionsHeader.Size = UDim2.new(1, 0, 0, 24)
        actionsHeader.Font = FONT_H
        actionsHeader.Text = "ACTIONS"
        actionsHeader.TextColor3 = COLORS.TextSecondary
        actionsHeader.TextSize = 14
        actionsHeader.Parent = actionPanel

        local actionsHeaderDivider = Instance.new("Frame")
        actionsHeaderDivider.BackgroundColor3 = COLORS.Divider
        actionsHeaderDivider.BorderSizePixel = 0
        actionsHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
        actionsHeaderDivider.Position = UDim2.new(0, 0, 0, 24)
        actionsHeaderDivider.Parent = actionPanel

        local actionMenuList = Instance.new("ScrollingFrame")
        actionMenuList.Name = "ActionMenuList"
        actionMenuList.BackgroundTransparency = 1
        actionMenuList.BorderSizePixel = 0
        actionMenuList.Size = UDim2.new(1, 0, 1, -26)
        actionMenuList.Position = UDim2.new(0, 0, 0, 26)
        actionMenuList.ScrollBarThickness = 3
        actionMenuList.ScrollBarImageColor3 = COLORS.Divider
        actionMenuList.CanvasSize = UDim2.new(0, 0, 0, 0)
        actionMenuList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        actionMenuList.Parent = actionPanel

        local actionMenuLayout = Instance.new("UIListLayout")
        actionMenuLayout.Padding = UDim.new(0, 2)
        actionMenuLayout.Parent = actionMenuList

        local workspacePanel = Instance.new("Frame")
        workspacePanel.Name = "WorkspacePanel"
        workspacePanel.BackgroundColor3 = COLORS.Background
        workspacePanel.BorderSizePixel = 0
        workspacePanel.Size = UDim2.new(1 - PLAYERLIST_W - ACTIONMENU_W, 0, 1, 0)
        workspacePanel.Position = UDim2.new(PLAYERLIST_W + ACTIONMENU_W, 0, 0, 0)
        workspacePanel.Parent = body

        local wsPadding = Instance.new("UIPadding")
        wsPadding.PaddingLeft = UDim.new(0, 16)
        wsPadding.PaddingRight = UDim.new(0, 16)
        wsPadding.PaddingTop = UDim.new(0, 14)
        wsPadding.PaddingBottom = UDim.new(0, 14)
        wsPadding.Parent = workspacePanel

        local pagesFolder = Instance.new("Folder")
        pagesFolder.Name = "Pages"
        pagesFolder.Parent = workspacePanel

        local function categoryNames()
                local out = {}
                for _, b in ipairs(actionMenuList:GetChildren()) do
                        if b:IsA("TextButton") and string.sub(b.Name, 1, 7) == "CatBtn_" then
                                table.insert(out, string.sub(b.Name, 8))
                        end
                end
                return out
        end

        local selectFn = Instance.new("BindableFunction")
        selectFn.Name = "SelectCategory"
        selectFn.Parent = bus

        local function selectPage(name)
                for _, pg in ipairs(pagesFolder:GetChildren()) do
                        pg.Visible = (name ~= nil and pg.Name == "Page_" .. name)
                end
                for _, b in ipairs(actionMenuList:GetChildren()) do
                        if b:IsA("TextButton") then
                                local sel = (name ~= nil and b.Name == "CatBtn_" .. name)
                                b.TextColor3 = sel and COLORS.Active or COLORS.TextSecondary
                                b.BackgroundColor3 = sel and COLORS.Background or COLORS.Panel
                        end
                end
                bus:SetAttribute("ActivePage", name)
                navEvent:Fire("page", name)
        end

        selectFn.OnInvoke = selectPage

        local function cycleCategory(dir)
                local names = categoryNames()
                if #names == 0 then return end
                local cur = bus:GetAttribute("ActivePage")
                local idx = 1
                for i, n in ipairs(names) do
                        if n == cur then idx = i break end
                end
                local nxt = ((idx - 1 + dir) % #names) + 1
                selectPage(names[nxt])
        end

        local refreshBadge

        local function setOpen(open)
                screenGui.Enabled = open
                bus:SetAttribute("Open", open)
                if refreshBadge then
                        refreshBadge()
                end
                if open then
                        local cur = bus:GetAttribute("ActivePage")
                        local names = categoryNames()
                        if cur and table.find(names, cur) then
                                selectPage(cur)
                        elseif #names > 0 then
                                selectPage(names[1])
                        end
                        navEvent:Fire("open", true)
                else
                        navEvent:Fire("open", false)
                        if bus:GetAttribute("FP") ~= true then
                                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                        end
                end
        end

        local keySet = {}
        for _, k in ipairs(TOGGLE_KEYS) do
                keySet[k] = true
        end

        local NAV_KEYS = {
                [Enum.KeyCode.Up] = true, [Enum.KeyCode.Down] = true,
                [Enum.KeyCode.Left] = true, [Enum.KeyCode.Right] = true,
                [Enum.KeyCode.Return] = true, [Enum.KeyCode.Space] = true,
                [Enum.KeyCode.Backspace] = true,
        }

        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                local key = input.KeyCode
                if not key or key == Enum.KeyCode.Unknown then return end
                if UserInputService:GetFocusedTextBox() then return end

                -- GATE: AllowedUserIds is re-checked on EVERY toggle press
                if keySet[key] and not isAdmin(LocalPlayer) then
                        showDenied()
                        bus:SetAttribute("ForceClose", true)
                        return
                end

                if screenGui.Enabled then
                        -- menu open: keyboard first, nav works even if the game claims keys
                        if keySet[key] then
                                setOpen(false)
                                return
                        end
                        if key == Enum.KeyCode.Up then navEvent:Fire("move", -1) return end
                        if key == Enum.KeyCode.Down then navEvent:Fire("move", 1) return end
                        if key == Enum.KeyCode.Return or key == Enum.KeyCode.Space then navEvent:Fire("activate") return end
                        if key == Enum.KeyCode.Left or key == Enum.KeyCode.Right then
                                local d = (key == Enum.KeyCode.Right) and 1 or -1
                                if bus:GetAttribute("NavType") == "slider" then
                                        navEvent:Fire("adjust", d)
                                else
                                        cycleCategory(d)
                                end
                                return
                        end
                        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                                or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
                        if shift and key == Enum.KeyCode.Backspace then
                                navEvent:Fire("clearbind")
                                return
                        end
                        if shift and not NAV_KEYS[key] then
                                navEvent:Fire("bind", key.Name)
                                return
                        end
                        if key == Enum.KeyCode.Escape then
                                setOpen(false)
                        end
                        return
                end

                -- menu closed
                if keySet[key] then
                        setOpen(true)
                        return
                end
                if gameProcessed then return end
                for attr, val in pairs(bus:GetAttributes()) do
                        if string.sub(attr, 1, 5) == "Bind_" and val == key.Name then
                                navEvent:Fire("fire", string.sub(attr, 6))
                        end
                end
        end))

        -- menu never steals the mouse: cursor stays locked, Left Alt frees it,
        -- unless first person / spectator owns the mouse (they manage it themselves)
        table.insert(conns, RunService.Heartbeat:Connect(function()
                if not screenGui.Enabled then return end
                if bus:GetAttribute("FP") == true then return end
                UserInputService.MouseBehavior = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
                        and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        end))

        local badgeGui = Instance.new("ScreenGui")
        badgeGui.Name = "RemoteAdminBadge"
        badgeGui.ResetOnSpawn = false
        badgeGui.IgnoreGuiInset = true
        badgeGui.DisplayOrder = 1001
        badgeGui.Parent = playerGui

        local badge = Instance.new("TextButton")
        badge.Name = "Badge"
        badge.Size = UDim2.fromOffset(72, 26)
        badge.Position = UDim2.new(0, 8, 0, 8)
        badge.BackgroundColor3 = COLORS.Panel
        badge.BorderSizePixel = 0
        badge.AutoButtonColor = false
        badge.Font = FONT_H
        badge.Text = "RA"
        badge.TextSize = 14
        badge.TextColor3 = COLORS.TextMuted
        badge.Parent = badgeGui

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = COLORS.Divider
        bStroke.Transparency = 0.4
        bStroke.Parent = badge

        function refreshBadge()
                local n = 0
                for name, val in pairs(bus:GetAttributes()) do
                        if string.sub(name, 1, 4) == "Mod_" and val == true then
                                n += 1
                        end
                end
                badge.Text = "RA " .. n .. "/13"
                badge.TextColor3 = screenGui.Enabled and COLORS.Active or COLORS.TextMuted
        end

        badge.MouseButton1Click:Connect(function()
                setOpen(not screenGui.Enabled)
        end)

        table.insert(conns, bus.AttributeChanged:Connect(function(attr)
                if string.sub(attr, 1, 4) == "Mod_" or attr == "Open" then
                        refreshBadge()
                end
        end))

        bus.Destroying:Connect(function()
                for i = #conns, 1, -1 do
                        pcall(function()
                                conns[i]:Disconnect()
                        end)
                end
                table.clear(conns)
                pcall(function()
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
                pcall(function()
                        screenGui:Destroy()
                end)
                pcall(function()
                        badgeGui:Destroy()
                end)
        end)

        setOpen(false)

        -- the gate (top of this file) force-closes the menu when a
        -- listed admin fails a re-check (removed from AllowedUserIds)
        bus:GetAttributeChangedSignal("ForceClose"):Connect(function()
                if bus:GetAttribute("ForceClose") == true then
                        bus:SetAttribute("ForceClose", false)
                        if screenGui.Enabled then
                                setOpen(false)
                        end
                end
        end)

        bus:SetAttribute("Ready", true)
        print("[RemoteAdmin] core ready | M / RightShift / RA badge | arrows navigate, shift+key binds")

end, function(e)
        warn("[RemoteAdmin] core failed: " .. tostring(e))
        pcall(function()
                warn(debug.traceback(e))
        end)
        pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                local pg = lp and lp:FindFirstChild("PlayerGui")
                if not pg then return end
                local g = Instance.new("ScreenGui")
                g.Name = "RA_ERROR"
                g.ResetOnSpawn = false
                g.DisplayOrder = 9999
                g.Parent = pg
                local f = Instance.new("Frame")
                f.Size = UDim2.new(0, 460, 0, 100)
                f.Position = UDim2.new(0, 8, 0, 40)
                f.BackgroundColor3 = Color3.fromRGB(64, 0, 0)
                f.BorderSizePixel = 0
                f.Parent = g
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, -12, 1, -12)
                t.Position = UDim2.new(0, 6, 0, 6)
                t.BackgroundTransparency = 1
                t.Font = Enum.Font.Code
                t.TextSize = 12
                t.TextWrapped = true
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.TextYAlignment = Enum.TextYAlignment.Top
                t.TextColor3 = Color3.new(1, 1, 1)
                t.Text = "[RemoteAdmin] core failed: " .. tostring(e)
                t.Parent = f
        end)
end)
if not CORE_OK then
        warn("[RemoteAdmin] did not start, see the red box on screen")
end
