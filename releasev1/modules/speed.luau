--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Speed Settings
local speedSettings = {
    -- Module Metadata
    _version = "1.0.0",
    
    -- Main Settings
    enabled = false,
    keybind = Enum.KeyCode.Z, -- Can be KeyCode or UserInputType
    holdMode = false, -- Hold to enable instead of toggle
    
    -- Speed Settings
    speedMultiplier = 0.5,
    speedType = "cframe", -- "cframe", "walkspeed", "bodyvelocity"
    
    -- CFrame Speed Settings
    smoothing = false,
    smoothingFactor = 0.2,
    
    -- WalkSpeed Settings
    normalWalkSpeed = 16, -- Default Roblox walkspeed
    maxWalkSpeed = 100,
    
    -- BodyVelocity Settings
    bodyVelocityForce = Vector3.new(4000, 0, 4000),
    maxVelocity = Vector3.new(math.huge, 0, math.huge),
    
    -- Advanced Settings
    airSpeed = true, -- Allow speed while in air
    waterSpeed = true, -- Allow speed in water
    groundCheck = false, -- Only allow speed when on ground
    
    -- Safety Settings
    antiKick = false, -- Attempt to prevent speed-based kicks
    kickThreshold = 50, -- Speed threshold that might cause kicks
    adaptiveLimit = false, -- Automatically adjust speed to stay under threshold
    
    -- Notification Settings
    notifications = false,
    notificationColor = Color3.fromRGB(85, 255, 127),
    notificationDuration = 1.5,
    notificationSize = 15,
    
    -- Visual Settings
    showSpeedOverlay = false,
    speedOverlayPosition = Vector2.new(0.02, 0.02),
    speedOverlaySize = 16,
    speedOverlayColor = Color3.fromRGB(255, 255, 255),
    
    showTrail = false,
    trailColor = Color3.fromRGB(100, 100, 255),
    trailFadeTime = 0.4,
    trailMinSpeed = 0.3, -- Minimum speed to show trail
    
    -- Debug Settings
    debug = false,
    showDebugOverlay = false,
    debugOverlayPosition = Vector2.new(0.02, 0.25),
    debugOverlaySize = 14,
    debugOverlayColor = Color3.fromRGB(255, 255, 0),
    
    -- Callback Hooks
    onToggle = nil, -- function(enabled)
    onSpeedChange = nil, -- function(newSpeedType)
    onHoldStart = nil, -- function()
    onHoldEnd = nil, -- function()
}

--// Setting Validation
local function ValidateSettings()
    -- Validate speedMultiplier
    if typeof(speedSettings.speedMultiplier) ~= "number" or speedSettings.speedMultiplier < 0 or speedSettings.speedMultiplier > 10 then
        warn("[Eero Speed]: Invalid speedMultiplier: " .. tostring(speedSettings.speedMultiplier) .. " - Defaulting to 0.5")
        speedSettings.speedMultiplier = 0.5
    end
    
    -- Validate speedType
    local validTypes = {cframe=true, walkspeed=true, bodyvelocity=true}
    if not validTypes[speedSettings.speedType] then
        warn("[Eero Speed]: Invalid speedType: " .. tostring(speedSettings.speedType) .. " - Defaulting to 'cframe'")
        speedSettings.speedType = "cframe"
    end
    
    -- Validate keybind
    if not speedSettings.keybind or 
       (typeof(speedSettings.keybind) ~= "EnumItem" or 
        (speedSettings.keybind.EnumType ~= Enum.KeyCode and speedSettings.keybind.EnumType ~= Enum.UserInputType)) then
        warn("[Eero Speed]: Invalid keybind - Defaulting to 'Z'")
        speedSettings.keybind = Enum.KeyCode.Z
    end
    
    -- Validate numeric ranges
    if speedSettings.smoothingFactor <= 0 or speedSettings.smoothingFactor > 1 then
        warn("[Eero Speed]: Invalid smoothingFactor: " .. tostring(speedSettings.smoothingFactor) .. " - Defaulting to 0.2")
        speedSettings.smoothingFactor = 0.2
    end
    
    if speedSettings.maxWalkSpeed <= 0 or speedSettings.maxWalkSpeed > 1000 then
        warn("[Eero Speed]: Invalid maxWalkSpeed: " .. tostring(speedSettings.maxWalkSpeed) .. " - Defaulting to 100")
        speedSettings.maxWalkSpeed = 100
    end
    
    if speedSettings.kickThreshold <= 0 then
        warn("[Eero Speed]: Invalid kickThreshold: " .. tostring(speedSettings.kickThreshold) .. " - Defaulting to 50")
        speedSettings.kickThreshold = 50
    end
    
    -- Validate colors
    if typeof(speedSettings.notificationColor) ~= "Color3" then
        warn("[Eero Speed]: Invalid notificationColor - Defaulting to green")
        speedSettings.notificationColor = Color3.fromRGB(85, 255, 127)
    end
    
    if typeof(speedSettings.trailColor) ~= "Color3" then
        warn("[Eero Speed]: Invalid trailColor - Defaulting to blue")
        speedSettings.trailColor = Color3.fromRGB(100, 100, 255)
    end
    
    -- Validate Vector3
    if typeof(speedSettings.bodyVelocityForce) ~= "Vector3" then
        warn("[Eero Speed]: Invalid bodyVelocityForce - Defaulting to (4000,0,4000)")
        speedSettings.bodyVelocityForce = Vector3.new(4000, 0, 4000)
    end
end

-- Run validation
ValidateSettings()

--// State Variables
local speedConnection = nil
local bodyVelocity = nil
local originalWalkSpeed = 16
local currentCFrame = nil
local trailParts = {}
local Connections = {}

--// Debug Function
local function Debug(message)
    if speedSettings.debug then
        print("[Eero Speed Debug]: " .. tostring(message))
    end
end

--// Notification Function
local function Notify(text, color, duration, size)
    if not speedSettings.notifications then return end
    
    task.spawn(function()
        local notif = Drawing.new("Text")
        notif.Text = text
        notif.Size = size or speedSettings.notificationSize
        notif.Font = 2
        notif.Center = true
        notif.Outline = true
        notif.Color = color or speedSettings.notificationColor
        notif.Transparency = 1
        notif.Visible = true

        notif.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.85)

        task.wait(duration or speedSettings.notificationDuration)

        for i = 1, 15 do
            task.wait(0.03)
            notif.Transparency = notif.Transparency - 0.07
        end

        notif:Remove()
    end)
end

--// Visual Elements
local SpeedOverlay = Drawing.new("Text")
local DebugOverlay = Drawing.new("Text")

--// Input matching function
local function DoesInputMatch(input, keybind)
    if keybind.EnumType == Enum.KeyCode then
        return input.KeyCode == keybind
    elseif keybind.EnumType == Enum.UserInputType then
        return input.UserInputType == keybind
    end
    return false
end

--// Ground Check Function
local function IsOnGround()
    if not speedSettings.groundCheck then return true end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- Check if humanoid state indicates grounded
    local state = humanoid:GetState()
    return state ~= Enum.HumanoidStateType.Freefall and 
           state ~= Enum.HumanoidStateType.Flying and
           state ~= Enum.HumanoidStateType.Jumping
end

--// Trail Effect Functions
local function CreateTrailPart(position)
    if not speedSettings.showTrail then return end
    
    local part = Instance.new("Part")
    part.Name = "SpeedTrail"
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Color = speedSettings.trailColor
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Ball
    part.Parent = workspace
    
    table.insert(trailParts, {part = part, time = tick()})
    
    -- Cleanup old trail parts
    for i = #trailParts, 1, -1 do
        local trailData = trailParts[i]
        if tick() - trailData.time > speedSettings.trailFadeTime then
            trailData.part:Destroy()
            table.remove(trailParts, i)
        else
            -- Fade out
            local age = tick() - trailData.time
            local alpha = 1 - (age / speedSettings.trailFadeTime)
            trailData.part.Transparency = 1 - alpha
        end
    end
end

--// Speed Type Functions
local function StartCFrameSpeed()
    if speedConnection then return end
    
    speedConnection = RunService.Stepped:Connect(function()
        if speedSettings.enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
            local humanoid = LocalPlayer.Character.Humanoid
            
            -- Ground check
            if not IsOnGround() and not speedSettings.airSpeed then return end
            
            local moveVector = humanoid.MoveDirection * speedSettings.speedMultiplier
            
            -- Anti-kick adaptive limiting
            if speedSettings.adaptiveLimit and moveVector.Magnitude > speedSettings.kickThreshold then
                moveVector = moveVector.Unit * speedSettings.kickThreshold
            end
            
            if speedSettings.smoothing then
                if not currentCFrame then
                    currentCFrame = humanoidRootPart.CFrame
                end
                local targetCFrame = humanoidRootPart.CFrame + moveVector
                currentCFrame = currentCFrame:Lerp(targetCFrame, speedSettings.smoothingFactor)
                humanoidRootPart.CFrame = currentCFrame
            else
                humanoidRootPart.CFrame = humanoidRootPart.CFrame + moveVector
            end
            
            -- Trail effect
            if moveVector.Magnitude > speedSettings.trailMinSpeed then
                CreateTrailPart(humanoidRootPart.Position)
            end
        end
    end)
end

local function StartWalkSpeedBoost()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        originalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = math.min(speedSettings.speedMultiplier * originalWalkSpeed, speedSettings.maxWalkSpeed)
        Debug("WalkSpeed set to: " .. humanoid.WalkSpeed)
    end
end

local function StartBodyVelocitySpeed()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
        
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = speedSettings.bodyVelocityForce
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = humanoidRootPart
        
        speedConnection = RunService.Stepped:Connect(function()
            if speedSettings.enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local humanoid = LocalPlayer.Character.Humanoid
                
                -- Ground check
                if not IsOnGround() and not speedSettings.airSpeed then
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    return
                end
                
                local moveVector = humanoid.MoveDirection * speedSettings.speedMultiplier * 16 -- Scale similar to walkspeed
                bodyVelocity.Velocity = Vector3.new(moveVector.X, bodyVelocity.Velocity.Y, moveVector.Z)
                
                -- Trail effect
                if moveVector.Magnitude > speedSettings.trailMinSpeed then
                    CreateTrailPart(humanoidRootPart.Position)
                end
            end
        end)
        
        Debug("BodyVelocity speed started")
    end
end

--// Speed Control Functions
local function StartSpeed()
    local speedType = speedSettings.speedType
    
    if speedType == "cframe" then
        StartCFrameSpeed()
    elseif speedType == "walkspeed" then
        StartWalkSpeedBoost()
    elseif speedType == "bodyvelocity" then
        StartBodyVelocitySpeed()
    end
    
    Debug("Speed started with type: " .. speedType)
end

local function StopSpeed()
    -- Disconnect speed connection
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    
    -- Clean up BodyVelocity
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    -- Reset WalkSpeed
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = originalWalkSpeed
    end
    
    -- Clear smoothing
    currentCFrame = nil
    
    -- Clean up trail parts
    for _, trailData in ipairs(trailParts) do
        if trailData.part then
            trailData.part:Destroy()
        end
    end
    trailParts = {}
    
    Debug("Speed stopped and cleaned up")
end

local function ToggleSpeed()
    speedSettings.enabled = not speedSettings.enabled
    
    if speedSettings.enabled then
        StartSpeed()
        print("Speed: ON (" .. speedSettings.speedType .. " - " .. speedSettings.speedMultiplier .. ")")
        Notify("Speed enabled: " .. speedSettings.speedType)
    else
        StopSpeed()
        print("Speed: OFF")
        Notify("Speed disabled")
    end
    
    if speedSettings.onToggle then
        speedSettings.onToggle(speedSettings.enabled)
    end
end

--// Input Handlers
Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if DoesInputMatch(input, speedSettings.keybind) then
        if speedSettings.holdMode then
            -- Hold mode: enable on press
            speedSettings.enabled = true
            StartSpeed()
            print("Speed: ON (Hold Mode)")
            if speedSettings.onHoldStart then
                speedSettings.onHoldStart()
            end
            if speedSettings.onToggle then
                speedSettings.onToggle(true)
            end
        else
            -- Toggle mode
            ToggleSpeed()
        end
    end
end)

Connections.InputEnded = UserInputService.InputEnded:Connect(function(input, processed)
    if speedSettings.holdMode and DoesInputMatch(input, speedSettings.keybind) then
        speedSettings.enabled = false
        StopSpeed()
        print("Speed: OFF (Released)")
        if speedSettings.onHoldEnd then
            speedSettings.onHoldEnd()
        end
        if speedSettings.onToggle then
            speedSettings.onToggle(false)
        end
    end
end)

--// Visual Updates
Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    -- Update speed overlay
    if speedSettings.showSpeedOverlay then
        SpeedOverlay.Position = Vector2.new(
            Camera.ViewportSize.X * speedSettings.speedOverlayPosition.X,
            Camera.ViewportSize.Y * speedSettings.speedOverlayPosition.Y
        )
        SpeedOverlay.Size = speedSettings.speedOverlaySize
        SpeedOverlay.Color = speedSettings.speedOverlayColor
        SpeedOverlay.Center = false
        SpeedOverlay.Outline = true
        SpeedOverlay.Font = 2
        SpeedOverlay.Visible = true
        
        local statusText = speedSettings.enabled and "ON" or "OFF"
        local currentSpeed = "0"
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = LocalPlayer.Character.Humanoid
            if speedSettings.speedType == "walkspeed" then
                currentSpeed = tostring(math.floor(humanoid.WalkSpeed))
            else
                currentSpeed = tostring(speedSettings.speedMultiplier)
            end
        end
        
        SpeedOverlay.Text = string.format("Speed: %s | Type: %s | Value: %s", statusText, speedSettings.speedType, currentSpeed)
    else
        SpeedOverlay.Visible = false
    end
    
    -- Update debug overlay
    if speedSettings.showDebugOverlay then
        DebugOverlay.Position = Vector2.new(
            Camera.ViewportSize.X * speedSettings.debugOverlayPosition.X,
            Camera.ViewportSize.Y * speedSettings.debugOverlayPosition.Y
        )
        DebugOverlay.Size = speedSettings.debugOverlaySize
        DebugOverlay.Color = speedSettings.debugOverlayColor
        DebugOverlay.Center = false
        DebugOverlay.Outline = true
        DebugOverlay.Font = 2
        DebugOverlay.Visible = true
        
        local onGroundStatus = IsOnGround() and "Yes" or "No"
        local trailCount = #trailParts
        
        local debugText = string.format(
            "Eero Speed v%s\nEnabled: %s\nType: %s\nMultiplier: %.2f\nMode: %s\nOn Ground: %s\nTrail Parts: %d",
            speedSettings._version,
            speedSettings.enabled and "ON" or "OFF",
            speedSettings.speedType,
            speedSettings.speedMultiplier,
            speedSettings.holdMode and "Hold" or "Toggle",
            onGroundStatus,
            trailCount
        )
        DebugOverlay.Text = debugText
    else
        DebugOverlay.Visible = false
    end
end)

--// Character respawn handling
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
    -- Reset speed state on respawn
    if speedSettings.enabled then
        task.wait(1) -- Wait for character to fully load
        StopSpeed()
        StartSpeed()
        Debug("Speed restarted after character respawn")
    end
end)

--// Cleanup function
local function Cleanup()
    if SpeedOverlay then SpeedOverlay:Remove() end
    if DebugOverlay then DebugOverlay:Remove() end
    
    -- Clean up trail parts
    for _, trailData in ipairs(trailParts) do
        if trailData.part then
            trailData.part:Destroy()
        end
    end
    trailParts = {}
end

--// API Functions
local function Destroy()
    -- Disable speed
    local wasEnabled = speedSettings.enabled
    speedSettings.enabled = false
    
    -- Stop speed and cleanup
    StopSpeed()
    Cleanup()
    
    -- Disconnect all connections
    for connectionName, connection in pairs(Connections) do
        if connection then
            connection:Disconnect()
            Debug("Disconnected: " .. connectionName)
        end
    end
    
    -- Clear connections table
    Connections = {}
    
    -- Trigger callback if was enabled
    if wasEnabled and speedSettings.onToggle then
        speedSettings.onToggle(false)
    end
    
    Debug("Speed module destroyed and cleaned up")
    print("Eero Speed: Module destroyed")
end

local function UpdateSettings(newSettings)
    if typeof(newSettings) ~= "table" then
        warn("[Eero Speed]: UpdateSettings requires a table")
        return false
    end
    
    local updated = {}
    for key, value in pairs(newSettings) do
        if speedSettings[key] ~= nil then
            local oldValue = speedSettings[key]
            speedSettings[key] = value
            updated[key] = {old = oldValue, new = value}
            Debug("Setting updated: " .. key .. " = " .. tostring(value))
            
            -- Handle special cases that need immediate effect
            if key == "speedType" and speedSettings.enabled then
                StopSpeed()
                StartSpeed()
                if speedSettings.onSpeedChange then
                    speedSettings.onSpeedChange(value)
                end
            end
        else
            warn("[Eero Speed]: Unknown setting: " .. tostring(key))
        end
    end
    
    -- Re-validate settings after update
    ValidateSettings()
    
    print("[Eero Speed]: Updated " .. #updated .. " settings")
    return updated
end

local function GetCurrentType()
    return speedSettings.speedType
end

local function SetSpeedType(newType)
    if not newType or typeof(newType) ~= "string" then
        warn("[Eero Speed]: SetSpeedType requires a string")
        return false
    end
    
    local validTypes = {cframe=true, walkspeed=true, bodyvelocity=true}
    if not validTypes[newType] then
        warn("[Eero Speed]: Invalid speed type: " .. newType)
        return false
    end
    
    local oldType = speedSettings.speedType
    speedSettings.speedType = newType
    
    -- Restart speed if currently enabled
    if speedSettings.enabled then
        StopSpeed()
        StartSpeed()
    end
    
    Debug("Speed type changed from " .. oldType .. " to " .. newType)
    
    if speedSettings.onSpeedChange then
        speedSettings.onSpeedChange(newType)
    end
    
    return true
end

local function Pause()
    if not speedSettings._paused then
        speedSettings._paused = true
        speedSettings._wasEnabled = speedSettings.enabled
        speedSettings.enabled = false
        StopSpeed()
        Debug("Speed paused")
        print("Speed: PAUSED")
    end
end

local function Resume()
    if speedSettings._paused then
        speedSettings._paused = false
        speedSettings.enabled = speedSettings._wasEnabled or false
        speedSettings._wasEnabled = nil
        if speedSettings.enabled then
            StartSpeed()
        end
        Debug("Speed resumed")
        print("Speed: RESUMED")
    end
end

-- Game profile loader
local GameProfiles = {
    dahood = {
        speedType = "cframe",
        speedMultiplier = 0.4,
        smoothing = true,
        groundCheck = false,
        antiKick = true,
        kickThreshold = 30
    },
    arsenal = {
        speedType = "walkspeed",
        speedMultiplier = 1.5,
        maxWalkSpeed = 25,
        groundCheck = true
    },
    phantom_forces = {
        speedType = "bodyvelocity",
        speedMultiplier = 0.3,
        groundCheck = true,
        antiKick = true
    },
    mm2 = {
        speedType = "cframe",
        speedMultiplier = 0.35,
        smoothing = false,
        antiKick = true,
        kickThreshold = 25
    }
}

local function LoadProfile(profileName)
    if typeof(profileName) ~= "string" then
        warn("[Eero Speed]: Profile name must be a string")
        return false
    end
    
    local profile = GameProfiles[profileName:lower()]
    if not profile then
        warn("[Eero Speed]: Unknown profile: " .. profileName)
        print("Available profiles: " .. table.concat({"dahood", "arsenal", "phantom_forces", "mm2"}, ", "))
        return false
    end
    
    local updated = UpdateSettings(profile)
    print("[Eero Speed]: Loaded '" .. profileName .. "' profile")
    return updated
end

--// Create API Table
local SpeedAPI = {
    -- Settings access
    settings = speedSettings,
    
    -- Control functions
    Destroy = Destroy,
    UpdateSettings = UpdateSettings,
    GetCurrentType = GetCurrentType,
    SetSpeedType = SetSpeedType,
    Pause = Pause,
    Resume = Resume,
    LoadProfile = LoadProfile,
    
    -- Utility functions
    ValidateSettings = ValidateSettings,
    
    -- Game profiles
    GetAvailableProfiles = function()
        return {"dahood", "arsenal", "phantom_forces", "mm2"}
    end
}

-- Add Destroy method to settings table for backwards compatibility
speedSettings.Destroy = Destroy

--// Setup cleanup on script end
Connections.PlayerRemoving = game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        Destroy()
    end
end)

--// Print module loaded message
print("Eero Speed v" .. speedSettings._version .. " loaded!")

--// Return the API table
return SpeedAPI
