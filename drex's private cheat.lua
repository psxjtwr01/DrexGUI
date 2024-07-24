-- Initialization and Setup
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local teleportEnabled = false
local lastTeleportTime = 0
local teleportCooldown = 0.0001
local speedValue = 16
local maxHealthValue = 100
local healthValue = 100
local smoothing = 0.5
local healthEnabled = false
local visuals = false
local textESPEnabled = false

local Aimbot = false
local rightMouseButtonHeld = false
print("Script created by drexxy. Enjoy cheating!!!")

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            rightMouseButtonHeld = true
        end
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            rightMouseButtonHeld = false
            if activeTween then
                activeTween:Cancel() -- Stop the current tween
                camera.CFrame = originalCFrame -- Snap back to original CFrame
                activeTween = nil
            end
        end
    end
end)
-- Function to draw skeleton ESP
local function createSkeletonESP(character, isEnabled)
    local bones = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot"
    }
    
    for i = 1, #bones - 1 do
        local part1 = character:FindFirstChild(bones[i])
        local part2 = character:FindFirstChild(bones[i + 1])
        
        if part1 and part2 then
            local line = part1:FindFirstChild("ESPLine" .. i) or Instance.new("Beam")
            line.Name = "ESPLine" .. i
            line.Attachment0 = Instance.new("Attachment", part1)
            line.Attachment1 = Instance.new("Attachment", part2)
            line.Color = ColorSequence.new(Color3.new(1, 0, 0))
            line.Transparency = NumberSequence.new(0.5)
            line.Width0 = 0.1
            line.Width1 = 0.1
            line.Parent = part1
        end
    end
    
    if not isEnabled then
        for _, bone in ipairs(bones) do
            local part = character:FindFirstChild(bone)
            if part then
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Beam") and child.Name:find("ESPLine") then
                        child:Destroy()
                    end
                end
            end
        end
    end
end
-- Player Handling Functions
local function findValidPlayers()
    local validPlayers = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character.Humanoid.Health > 0 then
            
                table.insert(validPlayers, player)
           

            
        end
    end

    return validPlayers
end
local function findNearestPlayerToCrosshair()
    local validPlayers = findValidPlayers()
    local closestPlayer = nil
    local closestDistance = math.huge

    -- Center of the screen (crosshair position)
    local screenCenter = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    
    for _, player in ipairs(validPlayers) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = character.HumanoidRootPart
            local screenPosition, onScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position)
            if onScreen then
                local distance = (screenCenter - Vector2.new(screenPosition.X, screenPosition.Y)).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

local function findNearestPlayer(validPlayers)
    local closestDistance = math.huge
    local closestPlayer = nil
    local myPosition = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in ipairs(validPlayers) do
        local character = player.Character
        if character then
            local distance = (myPosition - character.HumanoidRootPart.Position).magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

local function teleportToPlayer(player)
    if player then
        local character = LocalPlayer.Character
        if
            character and character:FindFirstChild("HumanoidRootPart") and player.Character and
                player.Character:FindFirstChild("HumanoidRootPart")
         then
            local targetPosition = player.Character.HumanoidRootPart.Position
            character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            game.Workspace.CurrentCamera.CFrame = CFrame.new(game.Workspace.CurrentCamera.CFrame.Position, targetPosition)
        end
    end
end
local function aimlock(player)
    if player then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = player.Character.HumanoidRootPart.Position
            local camera = game.Workspace.CurrentCamera

            -- Calculate the direction to move the mouse
            local screenPosition = camera:WorldToScreenPoint(targetPosition)
            local mouse = UserInputService:GetMouseLocation()
            
            -- Determine the movement deltas
            local deltaX = (screenPosition.X - mouse.X) * smoothing
            local deltaY = (screenPosition.Y - mouse.Y) * smoothing

            -- Move the mouse relative to its current position
            UserInputService:SendInput({ 
                UserInputService:InputObject({
                    UserInputService.InputType.MouseMovement, 
                    { 
                        Position = Vector2.new(deltaX, deltaY) 
                    }
                }) 
            })
        end
    end
end
local function onCharacterAdded(character)
    character:WaitForChild("HumanoidRootPart")
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(
        function(character)
            if player ~= LocalPlayer then
                onCharacterAdded(character)
            end
        end
    )
end

Players.PlayerAdded:Connect(
    function(player)
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(onCharacterAdded)
        end
    end
)

-- TextESP Functions
-- TextESP Functions
local function createTextLabel(character, isEnabled)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    
    if isEnabled then
        local head = character:FindFirstChild("Head")
        if head and not head:FindFirstChild("ESPLabel") then
            local textLabel = Instance.new("BillboardGui", head)
            textLabel.Name = "ESPLabel"
            textLabel.Adornee = head
            textLabel.Size = UDim2.new(0, 100, 0, 50)
            textLabel.StudsOffset = Vector3.new(0, 2, 0)
            textLabel.AlwaysOnTop = true

            local label = Instance.new("TextLabel", textLabel)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = player.Name -- Set the player's name here
            label.TextColor3 = Color3.new(0, 0, 0)
            label.TextScaled = false
        end
    else
        if character:FindFirstChild("Head") and character.Head:FindFirstChild("ESPLabel") then
            character.Head.ESPLabel:Destroy()
        end
    end
end


-- Box ESP Function
local function createBoxESP(character, isEnabled)
    if character:IsDescendantOf(LocalPlayer.Character) then
        return
    end
    
    if isEnabled then
        local existingBox = character:FindFirstChildOfClass("BoxHandleAdornment")
        if not existingBox then
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = character
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Size = Vector3.new(4, 7, 4) -- Example size, adjust as needed
            box.Color3 = Color3.new(0, 1, 1)
            box.Transparency = 0.1
            box.Parent = character
        end
    else
        local existingBox = character:FindFirstChildOfClass("BoxHandleAdornment")
        if existingBox then
            existingBox:Destroy()
        end
    end
end

-- Update Function
local function update()
 local validPlayers = findValidPlayers()
    if teleportEnabled and tick() - lastTeleportTime >= teleportCooldown then
       
        local nearestPlayer = findNearestPlayer(validPlayers)
        teleportToPlayer(nearestPlayer)
        lastTeleportTime = tick()
    end
    if Aimbot and rightMouseButtonHeld then
        local nearestPlayer = findNearestPlayerToCrosshair()
        aimlock(nearestPlayer)
    end

    local character = LocalPlayer.Character

    -- Update chams, text labels, and box esp based on toggles
    for _, player in ipairs(validPlayers) do
        if player.Character and player.Character ~= character then
            createBoxESP(player.Character, visuals)
            
            createTextLabel(player.Character, textESPEnabled)
        end
    end

    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speedValue
    end

    if character and character:FindFirstChild("Humanoid") and healthEnabled then
        character.Humanoid.MaxHealth = maxHealthValue
        character.Humanoid.Health = character.Humanoid.MaxHealth
    end
end

game:GetService("RunService").Heartbeat:Connect(update)

-- OrionLib Setup
-- OrionLib Setup
local DrexLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/psxjtwr01/DrexGUI/main/DrexLib.lua"))()

-- Create Window
local Window = Drex:MakeWindow({
    Name = "Global Visuals (created by drexxy)",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DrexScript"
})

-- Main Tab
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Main Tab Sections
local MainPlayerSection = MainTab:AddSection({
    Name = "Player"
})

MainPlayerSection:AddToggle({
    Name = "Toggle Health",
    Callback = function(value)
        healthEnabled = value
    end
})

-- Legit Tab
local LegitTab = Window:MakeTab({
    Name = "Legit",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Legit Tab Sections
local AimbotSection = LegitTab:AddSection({
    Name = "Aimbot"
})

AimbotSection:AddToggle({
    Name = "Aimbot",
    Callback = function(value)
        Aimbot = value
    end
})

-- Movement Tab
local MovementTab = Window:MakeTab({
    Name = "Movement",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Movement Tab Sections
local SpeedSection = MovementTab:AddSection({
    Name = "Speed"
})

SpeedSection:AddSlider({
    Name = "Speed",
    Min = 16,
    Max = 300,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        speedValue = value
    end
})

-- Visuals Tab
local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Visuals Tab Sections
local VisualsSection = VisualsTab:AddSection({
    Name = "Visuals"
})

VisualsSection:AddToggle({
    Name = "Visuals",
    Callback = function(value)
        visuals = value
    end
})

local TextESPSection = VisualsTab:AddSection({
    Name = "TextESP"
})

TextESPSection:AddToggle({
    Name = "TextESP",
    Callback = function(value)
        textESPEnabled = value
    end
})

local SkeletonESPSection = VisualsTab:AddSection({
    Name = "Skeleton ESP"
})

SkeletonESPSection:AddButton({
    Name = "Skeleton ESP",
    Callback = function()
        createSkeletonESP(LocalPlayer.Character, true)
    end
})

-- Credits Tab
local CreditsTab = Window:MakeTab({
    Name = "Credits",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Credits Tab Sections
local CreditsSection = CreditsTab:AddSection({
    Name = "Credits"
})

CreditsSection:AddButton({
    Name = "Created by Drexxy",
    Callback = function()
        print("Created by Drexxy button clicked")
    end
})

CreditsSection:AddButton({
    Name = "Destroy UI [ShutDown Script]",
    Callback = function()
        OrionLib:Destroy()
    end
})

-- Initialize OrionLib
OrionLib:Init()
