-- LocalScript dans StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local localPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG PAR DÉFAUT
-- ============================================================
local config = {
	toggleKey      = Enum.KeyCode.LeftControl,
	menuKey        = Enum.KeyCode.CapsLock,
	showDisplay    = true,
	showUsername   = true,
	showDistance   = false,
	showTeam       = false,
	showHealth     = false,
	teamColorName  = true,
	textSize       = 11,
	maxDistance    = 5000,
	fullbright     = false,
	fullbrightVal  = 1,
	noAtmosphere   = false,
}

local enabled          = false
local billboards       = {}
local listeningESPKey  = false
local listeningMenuKey = false
local scriptStopped    = false

-- Sauvegarde lighting original
local originalAmbient       = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalBrightness    = Lighting.Brightness
local originalClockTime     = Lighting.ClockTime
local originalFogEnd        = Lighting.FogEnd
local originalFogStart      = Lighting.FogStart

-- Sauvegarde atmosphere originale
local atmosphereBackup = {}
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphereBackup = {
		Density    = atmosphere.Density,
		Offset     = atmosphere.Offset,
		Color      = atmosphere.Color,
		Decay      = atmosphere.Decay,
		Glare      = atmosphere.Glare,
		Haze       = atmosphere.Haze,
	}
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ESPGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = localPlayer.PlayerGui

-- ============================================================
-- COMPTEUR JOUEURS (haut droite)
-- ============================================================
local playerCount = Instance.new("TextLabel")
playerCount.Size                   = UDim2.new(0, 120, 0, 30)
playerCount.Position               = UDim2.new(1, -136, 0, 12)
playerCount.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
playerCount.BackgroundTransparency = 0.2
playerCount.TextColor3             = Color3.fromRGB(180, 180, 180)
playerCount.Font                   = Enum.Font.GothamBold
playerCount.TextSize               = 13
playerCount.BorderSizePixel        = 0
playerCount.Parent                 = screenGui
Instance.new("UICorner", playerCount).CornerRadius = UDim.new(0, 6)

-- Mise à jour compteur
local function updatePlayerCount()
	local count = #Players:GetPlayers()
	local max   = Players.MaxPlayers
	playerCount.Text = "👥 " .. count .. " / " .. max
end
updatePlayerCount()
Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(function() task.wait() updatePlayerCount() end)

-- ============================================================
-- FEEDBACK "Copié !"
-- ============================================================
local copiedFeedback = Instance.new("TextLabel")
copiedFeedback.Size                   = UDim2.new(0, 120, 0, 26)
copiedFeedback.Position               = UDim2.new(1, -136, 1, -96)
copiedFeedback.BackgroundColor3       = Color3.fromRGB(30, 80, 30)
copiedFeedback.BackgroundTransparency = 0.2
copiedFeedback.TextColor3             = Color3.fromRGB(80, 255, 80)
copiedFeedback.Font                   = Enum.Font.GothamBold
copiedFeedback.TextSize               = 12
copiedFeedback.Text                   = "✅ Copié !"
copiedFeedback.BorderSizePixel        = 0
copiedFeedback.Visible                = false
copiedFeedback.Parent                 = screenGui
Instance.new("UICorner", copiedFeedback).CornerRadius = UDim.new(0, 5)

-- ============================================================
-- BOUTON ESP ON/OFF
-- ============================================================
local statusButton = Instance.new("TextButton")
statusButton.Size                   = UDim2.new(0, 120, 0, 36)
statusButton.Position               = UDim2.new(1, -136, 1, -64)
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
panel.Size                   = UDim2.new(0, 320, 0, 520)
panel.Position               = UDim2.new(0.5, -160, 0.5, -260)
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

local function makeToggle(labelText, configKey, order, callback)
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
		if callback then callback(config[configKey]) end
	end)
end

local function makeSlider(labelText, configKey, minVal, maxVal, step, order, callback)
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
		if callback then callback(snapped) end
	end

	thumb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true updateFromX(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

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

	btn.MouseButton1Click:Connect(function()
		if listeningESPKey or listeningMenuKey then return end
		if configKey == "toggleKey" then listeningESPKey = true
		else listeningMenuKey = true end

		btn.Text       = "Appuie sur une touche…"
		btn.TextColor3 = Color3.fromRGB(255, 200, 50)

		local conn
		conn = UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				local otherKey = configKey == "toggleKey" and config.menuKey or config.toggleKey
				if inp.KeyCode == otherKey then return end
				config[configKey] = inp.KeyCode
				btn.Text          = inp.KeyCode.Name
				btn.TextColor3    = Color3.fromRGB(200, 200, 200)
				if configKey == "toggleKey" then listeningESPKey = false
				else listeningMenuKey = false end
				conn:Disconnect()
			end
		end)
	end)
end

-- ============================================================
-- FULLBRIGHT
-- ============================================================
local function applyFullbright(val)
	if config.fullbright then
		Lighting.Ambient        = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness     = val
		Lighting.ClockTime      = 14
		Lighting.FogEnd         = 100000
		Lighting.FogStart       = 100000
	else
		Lighting.Ambient        = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoorAmbient
		Lighting.Brightness     = originalBrightness
		Lighting.ClockTime      = originalClockTime
		Lighting.FogEnd         = originalFogEnd
		Lighting.FogStart       = originalFogStart
	end
end

-- ============================================================
-- NO ATMOSPHERE
-- ============================================================
local function applyNoAtmosphere(enabled)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if enabled then
		if atm then
			atm.Density = 0
			atm.Haze    = 0
			atm.Glare   = 0
			atm.Offset  = 0
		end
	else
		if atm and next(atmosphereBackup) then
			atm.Density = atmosphereBackup.Density
			atm.Offset  = atmosphereBackup.Offset
			atm.Color   = atmosphereBackup.Color
			atm.Decay   = atmosphereBackup.Decay
			atm.Glare   = atmosphereBackup.Glare
			atm.Haze    = atmosphereBackup.Haze
		end
	end
end

-- ============================================================
-- CONSTRUCTION DU PANEL
-- ============================================================
makeSection("─── TOUCHES", 1)
makeKeyBind("Touche Toggle ESP", "toggleKey", 2)
makeKeyBind("Touche Menu",       "menuKey",   3)
makeSection("─── INFORMATIONS AFFICHÉES", 4)
makeToggle("Pseudo d'affichage",           "showDisplay",   5)
makeToggle("Colorer pseudo selon la team", "teamColorName", 6)
makeToggle("Pseudo @username",             "showUsername",  7)
makeToggle("Distance",                     "showDistance",  8)
makeToggle("Team / Groupe",                "showTeam",      9)
makeToggle("Vie (Health)",                 "showHealth",    10)
makeSection("─── RENDU", 11)
makeSlider("Taille du texte",   "textSize",    8,   28,   1, 12)
makeSlider("Distance de rendu", "maxDistance", 20, 5000, 50, 13)
makeSection("─── VISIBILITÉ", 14)
makeToggle("Fullbright", "fullbright", 15, function(val)
	applyFullbright(config.fullbrightVal)
end)
makeSlider("Intensité Fullbright", "fullbrightVal", 0.5, 3, 0.1, 16, function(val)
	if config.fullbright then applyFullbright(val) end
end)
makeToggle("Supprimer Atmosphere", "noAtmosphere", 17, function(val)
	applyNoAtmosphere(val)
end)

makeSection("─── AUTRE", 18)

local stopRow = Instance.new("Frame")
stopRow.Size             = UDim2.new(1, -8, 0, 38)
stopRow.BackgroundColor3 = Color3.fromRGB(60, 15, 15)
stopRow.BorderSizePixel  = 0
stopRow.LayoutOrder      = 19
stopRow.Parent           = scroll
Instance.new("UICorner", stopRow).CornerRadius = UDim.new(0, 7)
local stopStroke = Instance.new("UIStroke", stopRow)
stopStroke.Color     = Color3.fromRGB(140, 30, 30)
stopStroke.Thickness = 1

local stopBtn = Instance.new("TextButton", stopRow)
stopBtn.Size                   = UDim2.new(1, -16, 1, -10)
stopBtn.Position               = UDim2.new(0, 8, 0, 5)
stopBtn.BackgroundColor3       = Color3.fromRGB(180, 30, 30)
stopBtn.BorderSizePixel        = 0
stopBtn.Font                   = Enum.Font.GothamBold
stopBtn.TextSize               = 13
stopBtn.TextColor3             = Color3.fromRGB(255, 200, 200)
stopBtn.Text                   = "⏹  Arrêter le script"
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 5)

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
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- ============================================================
-- CLIPBOARD
-- ============================================================
local copyFeedbackThread = nil
local function showCopied()
	copiedFeedback.Visible = true
	if copyFeedbackThread then task.cancel(copyFeedbackThread) end
	copyFeedbackThread = task.delay(2, function()
		copiedFeedback.Visible = false
	end)
end

local function copyToClipboard(text)
	if setclipboard then
		setclipboard(text)
	elseif Clipboard and Clipboard.set then
		Clipboard.set(text)
	else
		print("[ESP] Copié : " .. text)
	end
	showCopied()
end

-- ============================================================
-- BILLBOARDS
-- ============================================================
local function clearBillboards()
	for _, data in pairs(billboards) do
		if data.gui and data.gui.Parent then
			data.gui:Destroy()
		end
	end
	billboards = {}
end

local function createBillboard(player)
	if player == localPlayer then return end
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	if head:FindFirstChild("DebugTag") then
		head:FindFirstChild("DebugTag"):Destroy()
	end

	local bb = Instance.new("BillboardGui")
	bb.Name        = "DebugTag"
	bb.Size        = UDim2.new(0, 220, 0, 100)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee     = head
	bb.Parent      = head

	local displayBtn = Instance.new("TextButton", bb)
	displayBtn.Name                   = "DisplayBtn"
	displayBtn.Size                   = UDim2.new(1, 0, 0, 20)
	displayBtn.Position               = UDim2.new(0, 0, 0, 0)
	displayBtn.BackgroundTransparency = 1
	displayBtn.BorderSizePixel        = 0
	displayBtn.Font                   = Enum.Font.GothamBold
	displayBtn.TextSize               = config.textSize
	displayBtn.TextStrokeTransparency = 0
	displayBtn.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	displayBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	displayBtn.RichText               = true
	displayBtn.Text                   = ""
	Instance.new("UICorner", displayBtn).CornerRadius = UDim.new(0, 4)

	local usernameBtn = Instance.new("TextButton", bb)
	usernameBtn.Name                   = "UsernameBtn"
	usernameBtn.Size                   = UDim2.new(1, 0, 0, 20)
	usernameBtn.Position               = UDim2.new(0, 0, 0, 20)
	usernameBtn.BackgroundTransparency = 1
	usernameBtn.BorderSizePixel        = 0
	usernameBtn.Font                   = Enum.Font.GothamBold
	usernameBtn.TextSize               = config.textSize
	usernameBtn.TextStrokeTransparency = 0
	usernameBtn.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	usernameBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	usernameBtn.RichText               = true
	usernameBtn.Text                   = ""
	Instance.new("UICorner", usernameBtn).CornerRadius = UDim.new(0, 4)

	local infoLabel = Instance.new("TextLabel", bb)
	infoLabel.Name                   = "InfoLabel"
	infoLabel.Size                   = UDim2.new(1, 0, 1, 0)
	infoLabel.Position               = UDim2.new(0, 0, 0, 42)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	infoLabel.TextStrokeTransparency = 0
	infoLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	infoLabel.Font                   = Enum.Font.GothamBold
	infoLabel.RichText               = true
	infoLabel.TextScaled             = false
	infoLabel.TextYAlignment         = Enum.TextYAlignment.Top

	billboards[player] = {
		gui         = bb,
		displayBtn  = displayBtn,
		usernameBtn = usernameBtn,
		infoLabel   = infoLabel,
		head        = head,
		clicked     = false,
	}
end

-- ============================================================
-- TOGGLE ESP
-- ============================================================
local function toggleESP()
	enabled = not enabled
	if enabled then
		statusButton.Text       = "ESP ON"
		statusButton.TextColor3 = Color3.fromRGB(50, 255, 50)
	else
		statusButton.Text       = "ESP OFF"
		statusButton.TextColor3 = Color3.fromRGB(255, 60, 60)
		clearBillboards()
	end
end

-- ============================================================
-- STOP SCRIPT
-- ============================================================
stopBtn.MouseButton1Click:Connect(function()
	scriptStopped = true
	enabled       = false
	clearBillboards()
	-- Restore lighting avant de quitter
	applyFullbright(false)
	applyNoAtmosphere(false)
	screenGui:Destroy()
end)

-- ============================================================
-- INPUTS
-- ============================================================
statusButton.MouseButton1Click:Connect(toggleESP)
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

UserInputService.InputBegan:Connect(function(inp)
	if scriptStopped then return end
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
		if billboards[player].gui and billboards[player].gui.Parent then
			billboards[player].gui:Destroy()
		end
		billboards[player] = nil
	end
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function colorToHex(c)
	return string.format("#%02x%02x%02x",
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255))
end

-- ============================================================
-- BOUCLE PRINCIPALE
-- ============================================================
RunService.RenderStepped:Connect(function()
	if scriptStopped then return end

	-- Maintien fullbright en boucle (au cas où le jeu rechange le lighting)
	if config.fullbright then
		Lighting.Ambient        = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness     = config.fullbrightVal
		Lighting.ClockTime      = 14
		Lighting.FogEnd         = 100000
		Lighting.FogStart       = 100000
	end

	-- Maintien no atmosphere en boucle
	if config.noAtmosphere then
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			atm.Density = 0
			atm.Haze    = 0
			atm.Glare   = 0
			atm.Offset  = 0
		end
	end

	if not enabled then return end

	local myChar = localPlayer.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local myPos    = myRoot.Position
	local camera   = workspace.CurrentCamera
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if root then
				local dist = (root.Position - myPos).Magnitude

				if dist <= config.maxDistance then
					if not billboards[player] or not billboards[player].gui.Parent then
						createBillboard(player)
					end

					local data = billboards[player]
					if not data then continue end

					local head = char:FindFirstChild("Head")
					local isHovered = false
					if head then
						local screenPos, onScreen = camera:WorldToScreenPoint(
							head.Position + Vector3.new(0, 2.5, 0)
						)
						if onScreen then
							local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							isHovered = dist2D < 55
						end
					end

					if isHovered then
						if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
							if not data.clicked then
								data.clicked = true
								copyToClipboard(player.Name)
							end
						else
							data.clicked = false
						end
					else
						data.clicked = false
					end

					local hoverColor  = Color3.fromRGB(255, 220, 50)
					local normalWhite = Color3.fromRGB(255, 255, 255)

					if config.showDisplay then
						data.displayBtn.Visible  = true
						data.displayBtn.TextSize = config.textSize
						local col = "#ffffff"
						if config.teamColorName and player.Team then
							col = colorToHex(player.TeamColor.Color)
						end
						data.displayBtn.Text       = '<font color="' .. col .. '"><b>' .. player.DisplayName .. '</b></font>'
						data.displayBtn.TextColor3 = isHovered and hoverColor or normalWhite
					else
						data.displayBtn.Visible = false
					end

					local offsetY = config.showDisplay and (config.textSize + 2) or 0
					if config.showUsername then
						data.usernameBtn.Visible    = true
						data.usernameBtn.TextSize   = config.textSize
						data.usernameBtn.Position   = UDim2.new(0, 0, 0, offsetY)
						data.usernameBtn.Text       = '<font color="#ffffff">@' .. player.Name .. '</font>'
						data.usernameBtn.TextColor3 = isHovered and hoverColor or normalWhite
					else
						data.usernameBtn.Visible = false
					end

					local infoOffsetY = offsetY + (config.showUsername and (config.textSize + 2) or 0)
					data.infoLabel.Position = UDim2.new(0, 0, 0, infoOffsetY)
					data.infoLabel.TextSize = config.textSize

					local lines = {}
					if config.showDistance then
						lines[#lines+1] = '<font color="#ffff55">📍 ' .. math.floor(dist) .. ' studs</font>'
					end
					if config.showTeam and player.Team then
						lines[#lines+1] = '<font color="' .. colorToHex(player.TeamColor.Color) .. '">🏷 ' .. tostring(player.Team) .. '</font>'
					end
					if config.showHealth then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then
							local pct = math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100)
							local hex = string.format("#%02x%02x00",
								math.floor((1 - pct / 100) * 255),
								math.floor((pct / 100) * 255))
							lines[#lines+1] = '<font color="' .. hex .. '">❤ ' .. pct .. '%</font>'
						end
					end
					data.infoLabel.Text = table.concat(lines, "\n")

				else
					if billboards[player] and billboards[player].gui and billboards[player].gui.Parent then
						billboards[player].gui:Destroy()
						billboards[player] = nil
					end
				end
			else
				if billboards[player] and billboards[player].gui and billboards[player].gui.Parent then
					billboards[player].gui:Destroy()
					billboards[player] = nil
				end
			end
		end
	end
end)
