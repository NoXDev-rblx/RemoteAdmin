----------------------------------------------------------------
-- remote admin 4.4 :: file 4 :: overseer
-- per player anomaly flags (TP / SPD / FLY), suspicion scoring,
-- and linear movement prediction markers
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

runModule("Overseer", function(root)
	local hud = uiParent and uiParent:FindFirstChild("RemoteAdminHUD")
	if not hud then
		warn("[RemoteAdmin/Overseer] window structure not found")
		return
	end
	local mainFrame = hud:FindFirstChild("MainFrame")
	local body = mainFrame and mainFrame:FindFirstChild("Body")
	local ap = body and body:FindFirstChild("ActionPanel")
	local list = ap and ap:FindFirstChild("ActionMenuList")
	local ws = body and body:FindFirstChild("WorkspacePanel")
	local pages = ws and ws:FindFirstChild("Pages")
	if not (list and pages) then
		warn("[RemoteAdmin/Overseer] window structure not found")
		return
	end

	local page = newCategory(root, list, pages, "OVERSEER")

	-- tab ui
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
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, content)

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
	local function label(text)
		make("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
			Font = FONT_B, Text = text, TextSize = 13, TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(),
		}, content)
	end

	local statusLabel = make("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		Font = FONT_B, Text = "STATUS  idle", TextSize = 13,
		TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, content)

	local function button(text, h)
		local btn = make("TextButton", {
			Size = UDim2.new(1, 0, 0, h or 28), BackgroundColor3 = COLORS.Panel,
			BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_H,
			Text = text, TextSize = 14, TextColor3 = COLORS.TextSecondary,
			LayoutOrder = nextOrder(),
		}, content)
		strokeOn(btn)
		return btn
	end

	local function toggle(labelText, state, key, onChange)
		local r = make("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = nextOrder(),
		}, content)
		make("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -64, 1, 0),
			Font = FONT_B, Text = labelText, TextSize = 14,
			TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
		}, r)
		local btn = make("TextButton", {
			Size = UDim2.new(0, 52, 1, 0), Position = UDim2.new(1, -52, 0, 0),
			BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0,
			AutoButtonColor = false, Font = FONT_B, TextSize = 13,
		}, r)
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

	local function slider(labelText, state, key, minV, maxV, display)
		local r = make("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = nextOrder(),
		}, content)
		make("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -64, 0, 14),
			Font = FONT_B, Text = labelText, TextSize = 14,
			TextColor3 = COLORS.TextSecondary, TextXAlignment = Enum.TextXAlignment.Left,
		}, r)
		local function text(v)
			return display and display(v) or tostring(v)
		end
		local val = make("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 60, 0, 14),
			Position = UDim2.new(1, -60, 0, 0), Font = FONT_B,
			Text = text(state[key]), TextSize = 13, TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, r)
		local track = make("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = COLORS.Background,
			BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 18),
		}, r)
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

	-- settings
	local ovs = {
		enabled = false,
		showPanels = true,
		showPrediction = true,
		onlyFlagged = false,
		predTicks = 4,      -- x0.25s lead
		speedFlag = 60,     -- studs/s
		teleportDist = 35,  -- studs per detection tick
		flyTime = 2,        -- seconds of sustained upward velocity
		flagScore = 25,
	}

	-- overlay gui
	local ovsGui = Instance.new("ScreenGui")
	ovsGui.Name = "RA_Overseer"
	ovsGui.ResetOnSpawn = false
	ovsGui.IgnoreGuiInset = true
	ovsGui.DisplayOrder = 41
	ovsGui.Parent = uiParent

	local listHolder = make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 215, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, ovsGui)
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, listHolder)

	local function scoreColor(score)
		if score >= ovs.flagScore then
			return Color3.fromRGB(255, 77, 77)
		end
		if score >= ovs.flagScore * 0.5 then
			return Color3.fromRGB(255, 200, 60)
		end
		return Color3.fromRGB(96, 200, 96)
	end

	local data = {}

	local function makePanel()
		local f = make("Frame", {
			Size = UDim2.new(1, 0, 0, 54),
			BackgroundColor3 = COLORS.Panel, BorderSizePixel = 0, Visible = false,
		}, listHolder)
		local str = make("UIStroke", { Color = COLORS.Divider, Thickness = 1, Transparency = 0.2 }, f)
		local name = make("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 3),
			Size = UDim2.new(1, -64, 0, 14), Font = Enum.Font.Code, TextSize = 12,
			TextColor3 = COLORS.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, f)
		local score = make("TextLabel", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 3), Size = UDim2.new(0, 52, 0, 14),
			Font = Enum.Font.Code, TextSize = 12, TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, f)
		local bar = make("Frame", {
			Position = UDim2.new(0, 8, 0, 19), Size = UDim2.new(1, -16, 0, 3),
			BackgroundColor3 = COLORS.Background, BorderSizePixel = 0,
		}, f)
		local fill = make("Frame", {
			Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = COLORS.Active, BorderSizePixel = 0,
		}, bar)
		local info = make("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 25),
			Size = UDim2.new(1, -16, 0, 12), Font = Enum.Font.Code, TextSize = 11,
			TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, f)
		local flags = make("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 38),
			Size = UDim2.new(1, -16, 0, 12), Font = Enum.Font.Code, TextSize = 11,
			TextColor3 = COLORS.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, f)
		return { frame = f, stroke = str, name = name, score = score, fill = fill, info = info, flags = flags }
	end

	local function makeDots()
		local dots, strokes = {}, {}
		for k = 1, 4 do
			local big = (k == 4)
			local dot = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(big and 10 or 6, big and 10 or 6),
				BackgroundTransparency = 1, BorderSizePixel = 0,
				Rotation = 45, Visible = false, ZIndex = 5,
			}, ovsGui)
			strokes[k] = make("UIStroke", { Color = COLORS.Active, Thickness = 1 }, dot)
			dots[k] = dot
		end
		return dots, strokes
	end

	local function ensure(plr)
		if plr == LocalPlayer or data[plr] then return end
		local dots, dotStrokes = makeDots()
		data[plr] = {
			panel = makePanel(), dots = dots, dotStrokes = dotStrokes,
			cd = {}, recent = {}, score = 0, hits = 0,
			char = nil, hasLast = false, lastPos = Vector3.zero,
			spdT = 0, flyT = 0, hspeed = 0, vel = nil, pos = nil,
			lastDetect = 0, lastPanel = 0, lastFlagAt = 0,
		}
	end

	local function hideAll(d)
		d.panel.frame.Visible = false
		for _, dot in ipairs(d.dots) do
			dot.Visible = false
		end
	end

	local function flagEntry(d, code, pts)
		local now = os.clock()
		if d.cd[code] and now < d.cd[code] then return end
		d.cd[code] = now + 2
		d.score = math.min(d.score + pts, 100)
		d.hits += 1
		table.insert(d.recent, 1, code)
		if #d.recent > 4 then
			table.remove(d.recent)
		end
		d.lastFlagAt = now
	end

	local function resetTrackers()
		for _, d in pairs(data) do
			d.hasLast = false
			d.spdT = 0
			d.flyT = 0
			d.score = 0
			d.recent = {}
			d.cd = {}
			hideAll(d)
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		ensure(plr)
	end
	Players.PlayerAdded:Connect(ensure)
	Players.PlayerRemoving:Connect(function(plr)
		local d = data[plr]
		if d then
			d.panel.frame:Destroy()
			for _, dot in ipairs(d.dots) do
				dot:Destroy()
			end
			data[plr] = nil
		end
	end)

	local statusUpd = 0
	local renderConn = RunService.RenderStepped:Connect(function(dt)
		local cam = workspace.CurrentCamera
		local now = os.clock()
		if not ovs.enabled or not cam then
			for _, d in pairs(data) do
				hideAll(d)
			end
			return
		end
		dt = math.clamp(dt, 0.01, 0.1)
		local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local tracked, flagged = 0, 0

		for plr, d in pairs(data) do
			local char = plr.Character
			if char ~= d.char then
				d.char = char
				d.hasLast = false
				d.spdT = 0
				d.flyT = 0
			end
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local ro = char and char:FindFirstChild("HumanoidRootPart")
			local alive = (hum and ro and hum.Health > 0) and true or false

			if alive then
				tracked += 1
				local pos = ro.Position
				local vel = ro.AssemblyLinearVelocity

				-- anomaly detection at ~16Hz
				if now - d.lastDetect >= 0.06 then
					local ddt = math.clamp(now - d.lastDetect, 0.01, 0.25)
					d.lastDetect = now

					if d.hasLast then
						local disp = (pos - d.lastPos).Magnitude
						if disp > ovs.teleportDist then
							flagEntry(d, "TP", 25)
						end
					end
					d.lastPos = pos
					d.hasLast = true

					local hs = Vector3.new(vel.X, 0, vel.Z).Magnitude
					d.hspeed = hs
					if hs > ovs.speedFlag then
						d.spdT += ddt
					else
						d.spdT = math.max(0, d.spdT - ddt)
					end
					if d.spdT > 0.4 then
						flagEntry(d, "SPD", 8)
					end

					if vel.Y > 25 then
						d.flyT += ddt
					else
						d.flyT = 0
					end
					if d.flyT > ovs.flyTime then
						flagEntry(d, "FLY", 12)
					end

					-- suspicion cools off when clean
					if now - d.lastFlagAt > 1.5 then
						d.score = math.max(0, d.score - 20 * ddt)
					end
				end

				d.pos = pos
				d.vel = vel
				if d.score >= ovs.flagScore then
					flagged += 1
				end
			else
				d.hasLast = false
			end

			-- prediction markers
			local showDots = ovs.showPrediction and alive and d.pos and d.vel and d.vel.Magnitude > 6
			local lead = ovs.predTicks / 4
			for k = 1, 4 do
				local dot = d.dots[k]
				if not showDots then
					dot.Visible = false
				else
					local wp = d.pos + d.vel * (lead * k / 4)
					local ok, pt = pcall(function()
						return cam:WorldToViewportPoint(wp)
					end)
					if ok and pt.Z > 0 then
						dot.Visible = true
						dot.Position = UDim2.fromOffset(pt.X, pt.Y)
						d.dotStrokes[k].Color = scoreColor(d.score)
					else
						dot.Visible = false
					end
				end
			end

			-- panel at 4Hz, sorted by suspicion
			if now - d.lastPanel >= 0.25 then
				d.lastPanel = now
				local dist = nil
				if myRoot and d.pos then
					dist = (d.pos - myRoot.Position).Magnitude
				end
				d.panel.name.Text = string.upper(plr.DisplayName)
				d.panel.score.Text = tostring(math.floor(d.score + 0.5))
				d.panel.info.Text = string.format("SPD %3.0f%s  HITS %d",
					d.hspeed,
					dist and string.format("  DST %dm", math.floor(dist + 0.5)) or "",
					d.hits)
				d.panel.flags.Text = (#d.recent > 0) and table.concat(d.recent, "+") or "clear"
				d.panel.fill.Size = UDim2.new(math.clamp(d.score / 100, 0, 1), 0, 1, 0)
				local col = scoreColor(d.score)
				d.panel.stroke.Color = col
				d.panel.fill.BackgroundColor3 = col
				d.panel.frame.LayoutOrder = math.floor(1000 - d.score)
				d.panel.frame.Visible = ovs.showPanels and alive
					and (not ovs.onlyFlagged or d.score >= ovs.flagScore)
			end
		end

		if now - statusUpd >= 1 then
			statusUpd = now
			statusLabel.Text = "STATUS  tracking " .. tracked .. " | flagged " .. flagged
			statusLabel.TextColor3 = (flagged > 0) and COLORS.Active or COLORS.TextMuted
		end
	end)

	-- tab controls
	local masterBtn = button("ENABLE OVERSEER", 32)
	masterBtn.MouseButton1Click:Connect(function()
		ovs.enabled = not ovs.enabled
		resetTrackers()
		masterBtn.Text = ovs.enabled and "DISABLE OVERSEER" or "ENABLE OVERSEER"
		masterBtn.TextColor3 = ovs.enabled and COLORS.Active or COLORS.TextSecondary
	end)

	section("DETECTION")
	toggle("Show Panels", ovs, "showPanels")
	toggle("Only Flagged", ovs, "onlyFlagged")
	slider("Speed Flag (studs/s)", ovs, "speedFlag", 20, 200)
	slider("Teleport Flag (studs)", ovs, "teleportDist", 10, 150)
	slider("Fly Time (s)", ovs, "flyTime", 1, 5)
	slider("Flag Threshold", ovs, "flagScore", 5, 100)

	section("PREDICTION")
	toggle("Show Prediction", ovs, "showPrediction")
	slider("Prediction Lead", ovs, "predTicks", 1, 12, function(v)
		return string.format("%.2fs", v / 4)
	end)

	section("LEGEND")
	label("TP  position jump   SPD  overspeed")
	label("FLY  sustained vertical thrust")
	label("score decays while a player behaves")

	root.Destroying:Connect(function()
		renderConn:Disconnect()
		ovsGui:Destroy()
	end)
end)