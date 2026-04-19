-- LocalScript dans StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG PAR DÉFAUT
-- ============================================================
local config = {
	toggleKey     = Enum.KeyCode.LeftControl,  -- toggle ESP
	menuKey       = Enum.KeyCode.CapsLock,      -- ouvre le menu
	showDisplay   = true,
	showUsername  = true,
	showDistance  = true,
	showTeam      = true,
	showHealth    = true,
	teamColorName = false,
	textSize      = 14,
	maxDistance   = 100,
}

local enabled           = false
local billboards        = {}
local listeningESPKey   = false
local listeningMenuKey  = false

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ESPGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = localPlayer.PlayerGui

-- ============================================================
-- BOUTON ESP ON/OFF
-- ============================================================
local statusButton = Instance.new("TextButton")
statusButton.Size                   = UDim2.new(0, 120, 0, 36)
statusButton.Position               = UDim2.new(1, -136, 1, -46)
statusButton.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
statusButton.BackgroundTransparency = 0.2
statusButton.TextColor3             = Color3.fromRGB(255, 60, 60)
statusButton.TextScaled             = true
statusButton.Font                   = Enum.Font.GothamBold
statusButton.Text                   = "ESP OFF"
statusButton.BorderSizePixel        = 0
statusButton.Parent                 = screenGui
Instance.new("UICorner", statusButton).CornerRadius = UDim.new(0, 6)

-- ============================================================
-- PANEL CONFIG
-- ============================================================
local panel = Instance.new("Frame")
panel.Name                   = "ConfigPanel"
panel.Size                   = UDim2.new(0, 320, 0, 490)
panel.Position               = UDim2.new(0.5, -160, 0.5, -245)
panel.BackgroundColor3       = Color3.fromRGB(14, 14, 14)
panel.BackgroundTransparency = 0
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.Parent                 = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", panel)
stroke.Color     = Color3.fromRGB(55, 55, 55)
stroke.Thickness = 1.2

local titleBar = Instance.new("TextLabel")
titleBar.Size             = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
titleBar.BorderSizePixel  = 0
titleBar.Text             = "⚙  ESP Config"
titleBar.TextColor3       = Color3.fromRGB(200, 200, 200)
titleBar.Font             = Enum.Font.GothamBold
titleBar.TextSize         = 15
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -34, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 13
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Size                   = UDim2.new(1, -16, 1, -48)
scroll.Position               = UDim2.new(0, 8, 0, 44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel        = 0
scroll.ScrollBarThickness     = 3
scroll.ScrollBarImageColor3   = Color3.fromRGB(80, 80, 80)
scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
scroll.Parent                 = panel

local layout = Instance.new("UIListLayout", scroll)
layout.Padding             = UDim.new(0, 6)
layout.SortOrder           = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0, 4)

-- ============================================================
-- HELPERS UI
-- ============================================================
local function makeSection(labelText, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, -8, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = labelText
	lbl.TextColor3             = Color3.fromRGB(100, 100, 100)
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = 11
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.LayoutOrder            = order
	lbl.Parent                 = scroll
end

local function makeToggle(labelText, configKey, order)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -8, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = scroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size                   = UDim2.new(1, -60, 1, 0)
	lbl.Position               = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = labelText
	lbl.TextColor3             = Color3.fromRGB(210, 210, 210)
	lbl.Font                   = Enum.Font.Gotham
	lbl.TextSize               = 13
	lbl.TextXAlignment         = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", row)
	btn.Size            = UDim2.new(0, 44, 0, 22)
	btn.Position        = UDim2.new(1, -52, 0.5, -11)
	btn.BorderSizePixel = 0
	btn.Font            = Enum.Font.GothamBold
	btn.TextSize        = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local function refresh()
		if config[configKey] then
			btn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
			btn.Text             = "ON"
			btn.TextColor3       = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.Text             = "OFF"
			btn.TextColor3       = Color3.fromRGB(150, 150, 150)
		end
	end
	refresh()

	btn.MouseButton1Click:Connect(function()
		config[configKey] = not config[configKey]
		refresh()
	end)
end

local function makeSlider(labelText, configKey, minVal, maxVal, step, order)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -8, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = scroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size                   = UDim2.new(1, -50, 0, 20)
	lbl.Position               = UDim2.new(0, 12, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = labelText
	lbl.TextColor3             = Color3.fromRGB(210, 210, 210)
	lbl.Font                   = Enum.Font.Gotham
	lbl.TextSize               = 13
	lbl.TextXAlignment         = Enum.TextXAlignment.Left

	local valLbl = Instance.new("TextLabel", row)
	valLbl.Size                   = UDim2.new(0, 42, 0, 20)
	valLbl.Position               = UDim2.new(1, -52, 0, 4)
	valLbl.BackgroundTransparency = 1
	valLbl.Font                   = Enum.Font.GothamBold
	valLbl.TextSize               = 13
	valLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
	valLbl.TextXAlignment         = Enum.TextXAlignment.Right
	valLbl.Text                   = tostring(config[configKey])

	local track = Instance.new("Frame", row)
	track.Size             = UDim2.new(1, -24, 0, 6)
	track.Position         = UDim2.new(0, 12, 1, -16)
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	track.BorderSizePixel  = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", track)
	fill.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
	fill.BorderSizePixel  = 0
	fill.Size             = UDim2.new((config[configKey] - minVal) / (maxVal - minVal), 0, 1, 0)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local thumb = Instance.new("Frame", track)
	thumb.Size             = UDim2.new(0, 14, 0, 14)
	thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
	thumb.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	thumb.BorderSizePixel  = 0
	thumb.Position         = UDim2.new((config[configKey] - minVal) / (maxVal - minVal), 0, 0.5, 0)
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local function updateFromX(absX)
		local r       = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local snapped = math.clamp(math.round((minVal + r * (maxVal - minVal)) / step) * step, minVal, maxVal)
		config[configKey] = snapped
		local nr = (snapped - minVal) / (maxVal - minVal)
		fill.Size      = UDim2.new(nr, 0, 1, 0)
		thumb.Position = UDim2.new(nr, 0, 0.5, 0)
		valLbl.Text    = tostring(snapped)
	end

	thumb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true updateFromX(i.Position.X) end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateFromX(i.Position.X) end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- KeyBind générique : configKey = "toggleKey" ou "menuKey"
local function makeKeyBind(labelText, configKey, order)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -8, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = scroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size                   = UDim2.new(1, -130, 1, 0)
	lbl.Position               = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = labelText
	lbl.TextColor3             = Color3.fromRGB(210, 210, 210)
	lbl.Font                   = Enum.Font.Gotham
	lbl.TextSize               = 13
	lbl.TextXAlignment         = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", row)
	btn.Size             = UDim2.new(0, 112, 0, 24)
	btn.Position         = UDim2.new(1, -120, 0.5, -12)
	btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 12
	btn.TextColor3       = Color3.fromRGB(200, 200, 200)
	btn.Text             = config[configKey].Name
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 60)

	local listening = false

	btn.MouseButton1Click:Connect(function()
		if listeningESPKey or listeningMenuKey then return end
		listening = true
		if configKey == "toggleKey" then listeningESPKey = true
		else listeningMenuKey = true end

		btn.Text       = "Appuie sur une touche…"
		btn.TextColor3 = Color3.fromRGB(255, 200, 50)

		local conn
		conn = UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				-- Empêche d'assigner la même touche aux deux
				local otherKey = configKey == "toggleKey" and config.menuKey or config.toggleKey
				if inp.KeyCode == otherKey then return end

				config[configKey] = inp.KeyCode
				btn.Text          = inp.KeyCode.Name
				btn.TextColor3    = Color3.fromRGB(200, 200, 200)
				listening         = false
				if configKey == "toggleKey" then listeningESPKey = false
				else listeningMenuKey = false end
				conn:Disconnect()
			end
		end)
	end)
end

-- ============================================================
-- CONSTRUCTION DU PANEL
-- ============================================================
makeSection("─── TOUCHES",              1)
makeKeyBind("Touche Toggle ESP",  "toggleKey", 2)
makeKeyBind("Touche Menu",        "menuKey",   3)
makeSection("─── INFORMATIONS AFFICHÉES", 4)
makeToggle("Pseudo d'affichage",           "showDisplay",   5)
makeToggle("Colorer pseudo selon la team", "teamColorName", 6)
makeToggle("Pseudo @username",             "showUsername",  7)
makeToggle("Distance",                     "showDistance",  8)
makeToggle("Team / Groupe",                "showTeam",      9)
makeToggle("Vie (Health)",                 "showHealth",    10)
makeSection("─── RENDU", 11)
makeSlider("Taille du texte",   "textSize",    8,  28,  1,  12)
makeSlider("Distance de rendu", "maxDistance", 20, 500, 10, 13)

-- ============================================================
-- DRAG PANEL
-- ============================================================
do
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true dragStart = inp.Position startPos = panel.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- ============================================================
-- BILLBOARDS
-- ============================================================
local function clearBillboards()
	for player, label in pairs(billboards) do
		if label and label.Parent then label.Parent:Destroy() end
	end
	billboards = {}
end

local function createBillboard(player)
	if player == localPlayer then return end
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	if head:FindFirstChild("DebugTag") then head:FindFirstChild("DebugTag"):Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "DebugTag" bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 2.5, 0) bb.AlwaysOnTop = true
	bb.Adornee = head bb.Parent = head

	local text = Instance.new("TextLabel", bb)
	text.Size = UDim2.new(1, 0, 1, 0) text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0 text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.Font = Enum.Font.GothamBold text.RichText = true text.TextScaled = false
	billboards[player] = text
end

-- ============================================================
-- TOGGLE ESP
-- ============================================================
local function toggleESP()
	enabled = not enabled
	if enabled then
		statusButton.Text = "ESP ON" statusButton.TextColor3 = Color3.fromRGB(50, 255, 50)
	else
		statusButton.Text = "ESP OFF" statusButton.TextColor3 = Color3.fromRGB(255, 60, 60)
		clearBillboards()
	end
end

-- ============================================================
-- INPUTS
-- ============================================================
statusButton.MouseButton1Click:Connect(toggleESP)
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

UserInputService.InputBegan:Connect(function(inp)
	if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if listeningESPKey or listeningMenuKey then return end

	if inp.KeyCode == config.menuKey then
		panel.Visible = not panel.Visible
	elseif inp.KeyCode == config.toggleKey then
		toggleESP()
	end
end)

-- ============================================================
-- NETTOYAGE DÉCONNEXION
-- ============================================================
Players.PlayerRemoving:Connect(function(player)
	if billboards[player] then
		if billboards[player].Parent then billboards[player].Parent:Destroy() end
		billboards[player] = nil
	end
end)

-- ============================================================
-- BOUCLE PRINCIPALE
-- ============================================================
local function colorToHex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

RunService.RenderStepped:Connect(function()
	if not enabled then return end
	local myChar = localPlayer.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local myPos = myRoot.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if root then
				local dist = (root.Position - myPos).Magnitude
				if dist <= config.maxDistance then
					if not billboards[player] or not billboards[player].Parent then
						createBillboard(player)
					end
					local label = billboards[player]
					if label then
						label.TextSize = config.textSize
						local lines = {}

						if config.showDisplay then
							local col = "#ffffff"
							if config.teamColorName and player.Team then
								col = colorToHex(player.TeamColor.Color)
							end
							lines[#lines+1] = '<font color="'..col..'"><b>'..player.DisplayName..'</b></font>'
						end
						if config.showUsername then
							lines[#lines+1] = '<font color="#ffffff">@'..player.Name..'</font>'
						end
						if config.showDistance then
							lines[#lines+1] = '<font color="#ffff55">📍 '..math.floor(dist)..' studs</font>'
						end
						if config.showTeam and player.Team then
							lines[#lines+1] = '<font color="'..colorToHex(player.TeamColor.Color)..'">🏷 '..tostring(player.Team)..'</font>'
						end
						if config.showHealth then
							local hum = char:FindFirstChildOfClass("Humanoid")
							if hum then
								local pct = math.floor((hum.Health / math.max(hum.MaxHealth,1)) * 100)
								local hex = string.format("#%02x%02x00", math.floor((1-pct/100)*255), math.floor((pct/100)*255))
								lines[#lines+1] = '<font color="'..hex..'">❤ '..pct..'%</font>'
							end
						end
						label.Text = table.concat(lines, "\n")
					end
				else
					if billboards[player] and billboards[player].Parent then
						billboards[player].Parent:Destroy() billboards[player] = nil
					end
				end
			else
				if billboards[player] and billboards[player].Parent then
					billboards[player].Parent:Destroy() billboards[player] = nil
				end
			end
		end
	end
end)
