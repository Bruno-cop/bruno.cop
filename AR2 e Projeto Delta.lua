--AR2 e Projeto Delta
-- ⛔ Evita conflitos ao rodar mais de uma vez
pcall(function()
    if getgenv().aimGui and getgenv().aimGui.Destroy then
        getgenv().aimGui:Destroy()
    end
end)

-- ⚙️ CONFIGS GLOBAIS
getgenv().Aimlock = true
getgenv().AimPart = "Head"
getgenv().FOV = 50
getgenv().MaxDistance = 1000
getgenv().ESPEnabled = true

-- SERVIÇOS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local aiming = false

-- 🔵 FOV CIRCLE
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 0, 255)
fovCircle.Transparency = 0.6
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = getgenv().FOV
    fovCircle.Visible = getgenv().Aimlock
end)

-- 🎯 Input botão direito
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        Frame.Visible = not Frame.Visible
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- 🔍 Função: encontrar alvo
local function getClosestToMouse()
    local closest, shortest = nil, getgenv().FOV
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(getgenv().AimPart) then
            local part = player.Character[getgenv().AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            local distanceFromPlayer = (Camera.CFrame.Position - part.Position).Magnitude

            if onScreen and distance < shortest and distanceFromPlayer <= getgenv().MaxDistance then
                closest = part
                shortest = distance
            end
        end
    end
    return closest
end

-- 🎯 Aimlock
RunService.RenderStepped:Connect(function()
    if getgenv().Aimlock and aiming then
        local target = getClosestToMouse()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- 👀 ESP
local function createESP(player)
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(0, 255, 0)

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Color = Color3.new(1, 1, 1)
    nameTag.Center = true
    nameTag.Outline = true

    RunService.RenderStepped:Connect(function()
        if getgenv().ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local root = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            local hum = player.Character.Humanoid

            local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos, legVis = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

            if rootVis and headVis and legVis and hum.Health > 0 then
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                box.Visible = true

                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                nameTag.Position = Vector2.new(rootPos.X, headPos.Y - 16)
                nameTag.Text = player.Name .. " [" .. dist .. "m]"
                nameTag.Visible = true
            else
                box.Visible = false
                nameTag.Visible = false
            end
        else
            box.Visible = false
            nameTag.Visible = false
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

-- 🟩 GUI MENU
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
getgenv().aimGui = ScreenGui
ScreenGui.Name = "AimlockMenu"
ScreenGui.ResetOnSpawn = false

-- Frame principal
Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 270)
Frame.Position = UDim2.new(0, 20, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎯 Bruno.cop"
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- Toggle Aimlock
local Toggle = Instance.new("TextButton", Frame)
Toggle.Size = UDim2.new(1, -20, 0, 30)
Toggle.Position = UDim2.new(0, 10, 0, 40)
Toggle.Text = "Desativar Aimlock"
Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Font = Enum.Font.SourceSans
Toggle.TextSize = 16
Toggle.MouseButton1Click:Connect(function()
    getgenv().Aimlock = not getgenv().Aimlock
    Toggle.Text = getgenv().Aimlock and "Desativar Aimlock" or "Ativar Aimlock"
end)

-- Parte para mirar
local AimPartDropdown = Instance.new("TextBox", Frame)
AimPartDropdown.Size = UDim2.new(1, -20, 0, 30)
AimPartDropdown.Position = UDim2.new(0, 10, 0, 80)
AimPartDropdown.PlaceholderText = "Parte para mirar (ex: Head)"
AimPartDropdown.Text = getgenv().AimPart
AimPartDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimPartDropdown.TextColor3 = Color3.new(1, 1, 1)
AimPartDropdown.Font = Enum.Font.SourceSans
AimPartDropdown.TextSize = 16
AimPartDropdown.FocusLost:Connect(function()
    getgenv().AimPart = AimPartDropdown.Text
end)

-- Campo FOV
local FOVInput = Instance.new("TextBox", Frame)
FOVInput.Size = UDim2.new(1, -20, 0, 30)
FOVInput.Position = UDim2.new(0, 10, 0, 120)
FOVInput.PlaceholderText = "FOV (ex: 50)"
FOVInput.Text = tostring(getgenv().FOV)
FOVInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FOVInput.TextColor3 = Color3.new(1, 1, 1)
FOVInput.Font = Enum.Font.SourceSans
FOVInput.TextSize = 16
FOVInput.FocusLost:Connect(function()
    local val = tonumber(FOVInput.Text)
    if val then
        getgenv().FOV = val
    end
end)

-- Distância Máxima
local DistInput = Instance.new("TextBox", Frame)
DistInput.Size = UDim2.new(1, -20, 0, 30)
DistInput.Position = UDim2.new(0, 10, 0, 160)
DistInput.PlaceholderText = "Distância Máx. (ex: 2000)"
DistInput.Text = tostring(getgenv().MaxDistance)
DistInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DistInput.TextColor3 = Color3.new(1, 1, 1)
DistInput.Font = Enum.Font.SourceSans
DistInput.TextSize = 16
DistInput.FocusLost:Connect(function()
    local val = tonumber(DistInput.Text)
    if val then
        getgenv().MaxDistance = val
    end
end)

-- Toggle ESP
local ESPToggle = Instance.new("TextButton", Frame)
ESPToggle.Size = UDim2.new(1, -20, 0, 30)
ESPToggle.Position = UDim2.new(0, 10, 0, 200)
ESPToggle.Text = "Desativar ESP"
ESPToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ESPToggle.TextColor3 = Color3.new(1, 1, 1)
ESPToggle.Font = Enum.Font.SourceSans
ESPToggle.TextSize = 16
ESPToggle.MouseButton1Click:Connect(function()
    getgenv().ESPEnabled = not getgenv().ESPEnabled
    ESPToggle.Text = getgenv().ESPEnabled and "Desativar ESP" or "Ativar ESP"
end)

-- Botão fechar
local Close = Instance.new("TextButton", Frame)
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -35, 0, 0)
Close.Text = "X"
Close.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 18
Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    fovCircle:Remove()
    getgenv().Aimlock = false
end)

-- 🌞 Sempre Dia (14:00 congelado)
local Lighting = game:GetService("Lighting")
RunService.RenderStepped:Connect(function()
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.FogEnd = 100000 -- sem neblina
    Lighting.GlobalShadows = false -- sem sombras
end)

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local VehiclesFolder = workspace:WaitForChild("Vehicles")

local espItems = {}

local function createVehicleESP(vehicle)
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(0, 170, 255) -- azul

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Color = Color3.new(1,1,1)
    nameTag.Center = true
    nameTag.Outline = true

    espItems[vehicle] = {box = box, nameTag = nameTag}

    RunService.RenderStepped:Connect(function()
        if not vehicle.PrimaryPart or not vehicle.Parent then
            box.Visible = false
            nameTag.Visible = false
            return
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(vehicle.PrimaryPart.Position)
        if onScreen then
            local dist = math.floor((Camera.CFrame.Position - vehicle.PrimaryPart.Position).Magnitude)

            local headPos, headOnScreen = Camera:WorldToViewportPoint(vehicle.PrimaryPart.Position + Vector3.new(0,3,0))
            local footPos, footOnScreen = Camera:WorldToViewportPoint(vehicle.PrimaryPart.Position - Vector3.new(0,3,0))

            if headOnScreen and footOnScreen then
                local height = math.abs(headPos.Y - footPos.Y)
                local width = height / 2
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                box.Visible = true

                nameTag.Position = Vector2.new(rootPos.X, headPos.Y - 16)
                nameTag.Text = vehicle.Name .. " [" .. dist .. "m]"
                nameTag.Visible = true
            else
                box.Visible = false
                nameTag.Visible = false
            end
        else
            box.Visible = false
            nameTag.Visible = false
        end
    end)
end

-- Criar ESP para veículos chamados "UAZ" que já existem
for _, vehicle in pairs(VehiclesFolder:GetChildren()) do
    if vehicle:IsA("Model") and vehicle.PrimaryPart and vehicle.Name == "UAZ" then
        createVehicleESP(vehicle)
    end
end

-- Criar ESP para veículos chamados "UAZ" adicionados depois
VehiclesFolder.ChildAdded:Connect(function(vehicle)
    if vehicle:IsA("Model") and vehicle.PrimaryPart and vehicle.Name == "UAZ" then
        createVehicleESP(vehicle)
    end
end)