-- ════════════════════════════════════════════════════════════
--  BlueCode3D | Loader avec système de clés
--  Copiez ce script dans votre exécuteur Roblox.
-- ════════════════════════════════════════════════════════════

local API_URL      = "https://api.bluecode3d.com"
local DISCORD_LINK = "https://discord.gg/bluecode3d"

-- ── Services ──────────────────────────────────────────────
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local userId  = tostring(LocalPlayer.UserId)

-- ── Utilitaires ───────────────────────────────────────────
local function httpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then return res end
    return nil
end

local function execScript(code)
    local ok, err = pcall(loadstring(code))
    if not ok then
        warn("[BlueCode3D] Erreur script : " .. tostring(err))
    end
end

-- ── Étape 1 : Vérifier l'accès ───────────────────────────
local checkUrl = API_URL .. "/checkaccess?userId=" .. userId
local result = httpGet(checkUrl)

if not result then
    warn("[BlueCode3D] Erreur réseau — impossible de contacter l'API.")
    return
end

-- Si on a le script directement (bypass ou clé active)
if result ~= "KEY_REQUIRED" and result ~= "INVALID" and result ~= "ERROR" then
    execScript(result)
    return
end

if result == "INVALID" then
    warn("[BlueCode3D] UserId invalide.")
    return
end

-- ── Étape 2 : Afficher l'interface de clé ─────────────────

-- Supprimer une ancienne UI si elle existe
if game:GetService("CoreGui"):FindFirstChild("BlueCode3D_KeyUI") then
    game:GetService("CoreGui"):FindFirstChild("BlueCode3D_KeyUI"):Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlueCode3D_KeyUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Essayer CoreGui, sinon PlayerGui
local guiParent = game:GetService("CoreGui")
pcall(function()
    screenGui.Parent = guiParent
end)
if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── Fond semi-transparent ─────────────────────────────────
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui

-- ── Frame principal ───────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 320)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(229, 255, 0)  -- #E5FF00
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- ── Barre titre ───────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(229, 255, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Masquer les coins du bas de la barre titre
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(229, 255, 0)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔑  BlueCode3D"
titleLabel.TextColor3 = Color3.fromRGB(18, 18, 24)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- ── Contenu ───────────────────────────────────────────────
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -40, 1, -90)
content.Position = UDim2.new(0, 20, 0, 65)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Label instruction
local instrLabel = Instance.new("TextLabel")
instrLabel.Name = "Instruction"
instrLabel.Size = UDim2.new(1, 0, 0, 30)
instrLabel.BackgroundTransparency = 1
instrLabel.Text = "Entrez votre clé d'accès"
instrLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
instrLabel.TextSize = 14
instrLabel.Font = Enum.Font.Gotham
instrLabel.TextXAlignment = Enum.TextXAlignment.Left
instrLabel.Parent = content

-- TextBox clé
local keyBox = Instance.new("TextBox")
keyBox.Name = "KeyInput"
keyBox.Size = UDim2.new(1, 0, 0, 45)
keyBox.Position = UDim2.new(0, 0, 0, 35)
keyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
keyBox.BorderSizePixel = 0
keyBox.Text = ""
keyBox.PlaceholderText = "BC3D-XXXX-XXXX-XXXX"
keyBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 16
keyBox.Font = Enum.Font.Code
keyBox.ClearTextOnFocus = false
keyBox.Parent = content

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyBox

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = Color3.fromRGB(60, 60, 80)
keyStroke.Thickness = 1
keyStroke.Parent = keyBox

local keyPad = Instance.new("UIPadding")
keyPad.PaddingLeft = UDim.new(0, 12)
keyPad.PaddingRight = UDim.new(0, 12)
keyPad.Parent = keyBox

-- ── Bouton Valider ────────────────────────────────────────
local validateBtn = Instance.new("TextButton")
validateBtn.Name = "Validate"
validateBtn.Size = UDim2.new(1, 0, 0, 40)
validateBtn.Position = UDim2.new(0, 0, 0, 95)
validateBtn.BackgroundColor3 = Color3.fromRGB(229, 255, 0)
validateBtn.BorderSizePixel = 0
validateBtn.Text = "✅  Valider"
validateBtn.TextColor3 = Color3.fromRGB(18, 18, 24)
validateBtn.TextSize = 16
validateBtn.Font = Enum.Font.GothamBold
validateBtn.AutoButtonColor = true
validateBtn.Parent = content

local valCorner = Instance.new("UICorner")
valCorner.CornerRadius = UDim.new(0, 8)
valCorner.Parent = validateBtn

-- ── Bouton Obtenir une clé ────────────────────────────────
local discordBtn = Instance.new("TextButton")
discordBtn.Name = "Discord"
discordBtn.Size = UDim2.new(1, 0, 0, 40)
discordBtn.Position = UDim2.new(0, 0, 0, 145)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.BorderSizePixel = 0
discordBtn.Text = "🎮  Obtenir une clé (Discord)"
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.TextSize = 14
discordBtn.Font = Enum.Font.GothamBold
discordBtn.AutoButtonColor = true
discordBtn.Parent = content

local discCorner = Instance.new("UICorner")
discCorner.CornerRadius = UDim.new(0, 8)
discCorner.Parent = discordBtn

-- ── Label statut ──────────────────────────────────────────
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 40)
statusLabel.Position = UDim2.new(0, 0, 0, 195)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextWrapped = true
statusLabel.Parent = content

-- ── Logique ───────────────────────────────────────────────
local ERROR_MESSAGES = {
    INVALID_KEY  = "❌ Clé invalide. Vérifiez et réessayez.",
    KEY_EXPIRED  = "⏰ Cette clé a expiré.",
    KEY_USED     = "🔂 Cette clé a déjà été utilisée.",
    KEY_BOUND    = "🔒 Cette clé est liée à un autre joueur.",
    ERROR        = "⚠️ Erreur serveur. Réessayez plus tard.",
    INVALID      = "❌ Erreur d'identification.",
}

local processing = false

validateBtn.MouseButton1Click:Connect(function()
    if processing then return end
    
    local key = keyBox.Text:gsub("%s+", "")
    if key == "" then
        statusLabel.Text = "⚠️ Veuillez entrer une clé."
        statusLabel.TextColor3 = Color3.fromRGB(255, 171, 0)
        return
    end
    
    processing = true
    validateBtn.Text = "⏳  Vérification..."
    validateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusLabel.Text = ""
    
    local activateUrl = API_URL .. "/activate?userId=" .. userId .. "&key=" .. key
    local res = httpGet(activateUrl)
    
    if not res then
        statusLabel.Text = "⚠️ Erreur réseau. Réessayez."
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        validateBtn.Text = "✅  Valider"
        validateBtn.BackgroundColor3 = Color3.fromRGB(229, 255, 0)
        processing = false
        return
    end
    
    -- Vérifier si c'est un message d'erreur
    if ERROR_MESSAGES[res] then
        statusLabel.Text = ERROR_MESSAGES[res]
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        validateBtn.Text = "✅  Valider"
        validateBtn.BackgroundColor3 = Color3.fromRGB(229, 255, 0)
        processing = false
        return
    end
    
    -- Succès ! On a reçu le script
    statusLabel.Text = "✅ Clé validée ! Chargement..."
    statusLabel.TextColor3 = Color3.fromRGB(0, 230, 118)
    
    wait(0.5)
    screenGui:Destroy()
    execScript(res)
end)

discordBtn.MouseButton1Click:Connect(function()
    -- Copier le lien Discord dans le presse-papiers
    pcall(function()
        setclipboard(DISCORD_LINK)
    end)
    statusLabel.Text = "📋 Lien Discord copié ! Collez-le dans votre navigateur."
    statusLabel.TextColor3 = Color3.fromRGB(88, 101, 242)
end)

-- ── Drag pour déplacer la fenêtre ─────────────────────────
local dragging, dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
