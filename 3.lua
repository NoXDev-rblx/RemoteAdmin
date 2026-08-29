----------------------------------------------------------------
-- remote admin 4.6 :: file 3/4 :: identifier + aimlock + overseer
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
		table.insert(rows, { frame = frame, kind = kind or "row", activate = activate, name = name })
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
		local name = labelText:gsub("%W", "_")
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
		ui.registerRow(row, "row", activate, name)
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
-- IDENTIFIER
-- ================================================================
runModule("Identifier", function(root)
	local hud, mainFrame, list, pages = resolveUI(root)
	if not pages then
		warn("[RemoteAdmin/Identifier] window structure not found")
		return
	end
	local page = newCategory(root, list, pages, "IDENTIFIER")
	local ui = newTab(page, "IDENTIFIER", root)
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
		identGui.Enabled = root:GetAttribute("Open") ~= true
		if not identGui.Enabled then return end
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
									local pt = cam:WorldToScreenPoint(world)
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

	ui.button("ENABLE IDENTIFIER", 32, function()
		ident.enabled = not ident.enabled
		if not ident.enabled then
			for _, obj in pairs(identObjects) do
				obj.root.Visible = false
			end
		end
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
	local ui = newTab(page, "AIMLOCK", root)
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
									local pt = cam:WorldToScreenPoint(pos)
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
		local pt = cam:WorldToScreenPoint(part.Position)
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

		-- armed aimlock always gets a real, visible cursor unless
		-- first person or spectator owns the mouse
		if aim.enabled and root:GetAttribute("Open") ~= true and root:GetAttribute("FP") ~= true then
			UserInputService.MouseIconEnabled = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end

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

		local show = aim.enabled and aim.showFov and root:GetAttribute("Open") ~= true
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
					local pt = cam:WorldToScreenPoint(part.Position)
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

	ui.button("ENABLE AIMLOCK", 32, function()
		aim.enabled = not aim.enabled
		aim.latched = false
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
	ui.registerRow(modeRow, "row", function()
		if aim.mode == "HOLD" then
			aim.mode = "TOGGLE"
		elseif aim.mode == "TOGGLE" then
			aim.mode = "AUTO"
		else
			aim.mode = "HOLD"
		end
		aim.latched = false
		aimModeBtn.Text = "MODE " .. aim.mode
	end, "Cycle_Activation")

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

	ui.button("CLEAR KEYBIND", 22, function()
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

	ui.button("HITBOX HEAD", 24, function()
		aim.part = (aim.part == "HEAD") and "TORSO" or "HEAD"
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
-- OVERSEER
-- ================================================================
runModule("Overseer", function(root)
	local hud, mainFrame, list, pages = resolveUI(root)
	if not pages then
		warn("[RemoteAdmin/Overseer] window structure not found")
		return
	end
	local page = newCategory(root, list, pages, "OVERSEER")
	local ui = newTab(page, "OVERSEER", root)
	local statusLabel = ui.status()

	local ovs = {
		enabled = false,
		showPanels = true,
		showPrediction = true,
		onlyFlagged = false,
		predTicks = 4,
		speedFlag = 60,
		teleportDist = 35,
		flyTime = 2,
		flagScore = 25,
	}

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
	RunService:BindToRenderStep("RA_overseer", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local cam = workspace.CurrentCamera
		local now = os.clock()
		ovsGui.Enabled = ovs.enabled and root:GetAttribute("Open") ~= true
		if not ovs.enabled or not cam or not ovsGui.Enabled then
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

			local showDots = ovs.showPrediction and alive and d.pos and d.vel and d.vel.Magnitude > 6
			local lead = ovs.predTicks / 4
			for k = 1, 4 do
				local dot = d.dots[k]
				if not showDots then
					dot.Visible = false
				else
					local wp = d.pos + d.vel * (lead * k / 4)
					local ok, pt = pcall(function()
						return cam:WorldToScreenPoint(wp)
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

	ui.button("ENABLE OVERSEER", 32, function()
		ovs.enabled = not ovs.enabled
		resetTrackers()
	end)

	ui.section("DETECTION")
	ui.toggle("Show Panels", ovs, "showPanels")
	ui.toggle("Only Flagged", ovs, "onlyFlagged")
	ui.slider("Speed Flag (studs/s)", ovs, "speedFlag", 20, 200)
	ui.slider("Teleport Flag (studs)", ovs, "teleportDist", 10, 150)
	ui.slider("Fly Time (s)", ovs, "flyTime", 1, 5)
	ui.slider("Flag Threshold", ovs, "flagScore", 5, 100)

	ui.section("PREDICTION")
	ui.toggle("Show Prediction", ovs, "showPrediction")
	ui.slider("Prediction Lead", ovs, "predTicks", 1, 12, function(v)
		return string.format("%.2fs", v / 4)
	end)

	ui.section("LEGEND")
	ui.label("TP  position jump   SPD  overspeed")
	ui.label("FLY  sustained vertical thrust")
	ui.label("score decays while a player behaves")

	root.Destroying:Connect(function()
		pcall(function()
			RunService:UnbindFromRenderStep("RA_overseer")
		end)
		ovsGui:Destroy()
	end)
end)
