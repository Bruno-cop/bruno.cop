-- AR2 & Projeto Delta – Script Completo com Prediction e Menu Organizado

-- Evita múltiplas execuções
pcall(function()
    if getgenv().aimGui and getgenv().aimGui.Destroy then
        getgenv().aimGui:Destroy()
    end
end)

-- CONFIGURAÇÕES GLOBAIS
getgenv().Aimlock = true
getgenv().AimPart = "Head"
getgenv().FOV = 50
getgenv().MaxDistance = 1000
getgenv().ESPEnabled = true
getgenv().ESPDistance = 1000
getgenv().Prediction = 0.15

-- SERVIÇOS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local aiming = false

-- FOV CIRCLE
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255,0,255)
fovCircle.Transparency = 0.6
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = getgenv().FOV
    fovCircle.Visible = getgenv().Aimlock
end)

-- INPUT
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- FUNÇÃO PARA ALVO MAIS PRÓXIMO
local function getClosestToMouse()
    local closest, shortest = nil, getgenv().FOV
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer 
           and player.Character 
           and player.Character:FindFirstChild(getgenv().AimPart) 
           and player.Character:FindFirstChild("Humanoid")
           and player.Character.Humanoid.Health > 0 -- IGNORA MORTOS
           and (player.Team ~= LocalPlayer.Team) then -- IGNORA ALIADOS
           
            local part = player.Character[getgenv().AimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            local mousePos = UserInputService:GetMouseLocation()
            local distance = (Vector2.new(screenPos.X,screenPos.Y)-mousePos).Magnitude
            local distanceFromPlayer = (Camera.CFrame.Position - part.Position).Magnitude
            if onScreen and distance < shortest and distanceFromPlayer <= getgenv().MaxDistance then
                closest = part
                shortest = distance
            end
        end
    end
    return closest
end


-- AIMLOCK COM PREDICTION
RunService.RenderStepped:Connect(function()
    if getgenv().Aimlock and aiming then
        local target = getClosestToMouse()
        if target then
            local velocity = target.AssemblyLinearVelocity or Vector3.new(0,0,0)
            local predictedPos = target.Position + velocity * getgenv().Prediction
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
        end
    end
end)

-- ESP DE PLAYERS
local function createESP(player)
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true

    RunService.RenderStepped:Connect(function()
        if getgenv().ESPEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local root = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            local hum = player.Character.Humanoid
            local dist = (Camera.CFrame.Position - root.Position).Magnitude

            if dist <= getgenv().ESPDistance then
                local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
                local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                local legPos, legVis = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                if rootVis and headVis and legVis and hum.Health > 0 then
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height/2
                    box.Size = Vector2.new(width,height)
                    box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                    box.Visible = true
                    box.Color = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                    nameTag.Color = box.Color
                    nameTag.Position = Vector2.new(rootPos.X, headPos.Y-16)
                    nameTag.Text = player.Name.." ["..math.floor(dist).."m]"
                    nameTag.Visible = true
                else
                    box.Visible = false
                    nameTag.Visible = false
                end
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
    if player ~= LocalPlayer then createESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createESP(player) end
end)

-- MENU
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
getgenv().aimGui = ScreenGui
ScreenGui.Name = "AimlockMenu"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,220,0,420) -- aumentado para caber o botão de Prediction
Frame.Position = UDim2.new(0,20,0,100)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,30)
Title.Text = "🎯 Bruno.cop"
Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

local function createButton(parent,y,text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,-20,0,30)
    btn.Position = UDim2.new(0,10,0,y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    return btn
end

local function createTextBox(parent,y,placeholder,default)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1,-20,0,30)
    box.Position = UDim2.new(0,10,0,y)
    box.PlaceholderText = placeholder
    box.Text = tostring(default)
    box.BackgroundColor3 = Color3.fromRGB(50,50,50)
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 16
    return box
end

local y = 40
local gap = 40

-- Botões e caixas
local AimToggle = createButton(Frame, y, getgenv().Aimlock and "Desativar Aimlock" or "Ativar Aimlock")
AimToggle.MouseButton1Click:Connect(function()
    getgenv().Aimlock = not getgenv().Aimlock
    AimToggle.Text = getgenv().Aimlock and "Desativar Aimlock" or "Ativar Aimlock"
end)
y=y+gap

local AimPartBox = createTextBox(Frame,y,"Parte para mirar (ex: Head)",getgenv().AimPart)
AimPartBox.FocusLost:Connect(function() getgenv().AimPart = AimPartBox.Text end)
y=y+gap

local FOVBox = createTextBox(Frame,y,"FOV (ex:50)",getgenv().FOV)
FOVBox.FocusLost:Connect(function() local val=tonumber(FOVBox.Text) if val then getgenv().FOV=val end end)
y=y+gap

local DistBox = createTextBox(Frame,y,"Distância Aimlock",getgenv().MaxDistance)
DistBox.FocusLost:Connect(function() local val=tonumber(DistBox.Text) if val then getgenv().MaxDistance=val end end)
y=y+gap

local ESPDistBox = createTextBox(Frame,y,"Distância ESP",getgenv().ESPDistance)
ESPDistBox.FocusLost:Connect(function() local val=tonumber(ESPDistBox.Text) if val then getgenv().ESPDistance=val end end)
y=y+gap

local ESPToggle = createButton(Frame,y,getgenv().ESPEnabled and "Desativar ESP" or "Ativar ESP")
ESPToggle.MouseButton1Click:Connect(function()
    getgenv().ESPEnabled = not getgenv().ESPEnabled
    ESPToggle.Text = getgenv().ESPEnabled and "Desativar ESP" or "Ativar ESP"
end)
y=y+gap

-- Botão de Prediction
local PredictionToggle = createButton(Frame, y, getgenv().Prediction > 0 and "Desativar Prediction" or "Ativar Prediction")
PredictionToggle.MouseButton1Click:Connect(function()
    if getgenv().Prediction > 0 then
        getgenv().Prediction = 0
        PredictionToggle.Text = "Ativar Prediction"
    else
        getgenv().Prediction = 0.15
        PredictionToggle.Text = "Desativar Prediction"
    end
end)
y = y + gap

local DisableBtn = createButton(Frame,y,"Desativar Script")
DisableBtn.MouseButton1Click:Connect(function()
    if fovCircle then fovCircle:Remove() end
    if getgenv().aimGui then getgenv().aimGui:Destroy() end
    getgenv().Aimlock=false
    getgenv().ESPEnabled=false
end)

-- Minimizar/restaurar com RightShift
local menuVisible = true
UserInputService.InputBegan:Connect(function(input,gpe)
    if not gpe and input.KeyCode==Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        Frame.Visible = menuVisible
    end
end)
