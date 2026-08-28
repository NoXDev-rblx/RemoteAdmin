----------------------------------------------------------------
-- remote admin 4.3 :: file 3/3 :: user checker
-- event driven attach: never waits, reattaches on core re-inject
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

runModule("UserChecker", function(root)
	local hud = uiParent and uiParent:FindFirstChild("RemoteAdminHUD")
	if not hud then
		warn("[RemoteAdmin/UserChecker] window structure not found")
		return
	end
	local mainFrame = hud:FindFirstChild("MainFrame")
	local body = mainFrame and mainFrame:FindFirstChild("Body")
	local ap = body and body:FindFirstChild("ActionPanel")
	local list = ap and ap:FindFirstChild("ActionMenuList")
	local ws = body and body:FindFirstChild("WorkspacePanel")
	local pages = ws and ws:FindFirstChild("Pages")
	if not (list and pages) then
		warn("[RemoteAdmin/UserChecker] window structure not found")
		return
	end

	local page = newCategory(root, list, pages, "USER CHECKER")

	-- tab content
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
	local function section(text)
		make("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
			Font = FONT_H, Text = text, TextSize = 13, TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
		}, content)
	end
	local function row(h)
		return make("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), LayoutOrder = nextOrder(),
		}, content)
	end

	local state = { autoRefresh = true }

	local headRow = row(104)
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
		local r = row(18)
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

	section("PROFILE")
	infoRow("User ID")
	infoRow("Account Age")
	infoRow("Created (est)")
	infoRow("Verified Badge")
	infoRow("Premium")
	infoRow("Friends With You")
	infoRow("Team")
	infoRow("Time In Server")

	section("LIVE")
	infoRow("Health")
	infoRow("WalkSpeed")
	infoRow("Speed")
	infoRow("Position")
	infoRow("Distance")
	infoRow("Ping")
	infoRow("Tool")
	infoRow("Seated")

	-- auto refresh toggle
	local tRow = row(22)
	make("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -64, 1, 0),
		Font = FONT_B, Text = "Auto Refresh", TextSize = 14,
		TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
	}, tRow)
	local tBtn = make("TextButton", {
		Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(1, -52, 0, 0),
		BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0,
		AutoButtonColor = false, Font = FONT_B, TextSize = 13,
	}, tRow)
	strokeOn(tBtn)
	local function refreshToggle()
		tBtn.Text = state.autoRefresh and "ON" or "OFF"
		tBtn.TextColor3 = state.autoRefresh and COLORS.Active or COLORS.TextMuted
	end
	refreshToggle()
	tBtn.MouseButton1Click:Connect(function()
		state.autoRefresh = not state.autoRefresh
		refreshToggle()
	end)

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