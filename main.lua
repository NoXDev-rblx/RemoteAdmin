----------------------------------------------------------------
-- remote admin 4.3 :: file 1/3 :: core + ui
-- bus in ReplicatedStorage (cross-script visible), UI in PlayerGui
----------------------------------------------------------------
local CORE_OK, CORE_ERR = xpcall(function()

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local TOGGLE_KEYS = { Enum.KeyCode.M, Enum.KeyCode.RightShift }
	local IGNORE_GAMEPROCESSED = true
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

	-- re-inject: wipe everything we own
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

	-- the bus: modules find this. ReplicatedStorage is visible to all client scripts
	local bus = Instance.new("Folder")
	bus.Name = "RA_BUS"
	bus.Parent = ReplicatedStorage

	local conns = {}

	-- ===== HUD =====
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RemoteAdminHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 50
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
	titleText.Text = "REMOTE ADMIN 4.3"
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

	-- players column
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

	-- actions column
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

	-- workspace column
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

	local selectFn = Instance.new("BindableFunction")
	selectFn.Name = "SelectCategory"
	selectFn.Parent = bus
	selectFn.OnInvoke = function(name)
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
	end

	-- ===== open / close =====
	local refreshBadge

	local function setOpen(open)
		screenGui.Enabled = open
		bus:SetAttribute("Open", open)
		if refreshBadge then
			refreshBadge()
		end
		if open then
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	local keySet = {}
	for _, k in ipairs(TOGGLE_KEYS) do
		keySet[k] = true
	end
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not keySet[input.KeyCode] then return end
		if gameProcessed and not IGNORE_GAMEPROCESSED then return end
		if UserInputService:GetFocusedTextBox() then return end
		setOpen(not screenGui.Enabled)
	end))

	-- ===== badge =====
	local badgeGui = Instance.new("ScreenGui")
	badgeGui.Name = "RemoteAdminBadge"
	badgeGui.ResetOnSpawn = false
	badgeGui.IgnoreGuiInset = true
	badgeGui.DisplayOrder = 100
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
		badge.Text = "RA " .. n .. "/4"
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

	-- ===== shutdown =====
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
	bus:SetAttribute("Ready", true)
	print("[RemoteAdmin] core ready | M / RightShift / click RA badge")

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
