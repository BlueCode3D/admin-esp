-- BlueCode3D | Loader avec Notification
local API_URL = "https://api.bluecode3d.com/getscript"
local userId  = tostring(game:GetService("Players").LocalPlayer.UserId)

-- Fonction pour afficher le message d'erreur à l'écran
local function showDeniedMessage()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BlueCodeError"
    sg.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0, 400, 0, 50)
    txt.Position = UDim2.new(0.5, -200, 0.4, 0)
    txt.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    txt.BackgroundTransparency = 0.2
    txt.TextColor3 = Color3.fromRGB(255, 50, 50) -- Rouge
    txt.Text = "Vous n'êtes pas autorisé à utiliser ce script. Contactez le développeur."
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 12
    txt.Parent = sg
    
    Instance.new("UICorner", txt).CornerRadius = UDim.new(0, 8)
    
    -- Disparition après 5 secondes
    task.wait(5)
    sg:Destroy()
end

-- Requête API
local success, result = pcall(function()
    return game:HttpGet(API_URL .. "?userId=" .. userId)
end)

if success and result ~= "DENIED" then
    loadstring(result)()
else
    -- Affichage du message en rouge sur l'écran
    task.spawn(showDeniedMessage)
end
