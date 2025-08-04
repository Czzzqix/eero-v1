--[[
    Eero Camlock + Triggerbot Loader Script - CORRECTED VERSION
]]--

local eero = {}

-- Load the modules
eero.camlock = loadstring(game:HttpGet("https://raw.githubusercontent.com/Czzzqix/eero/refs/heads/main/eero%20modules/camlock/testing/CamlockTest.luau"))()
eero.triggerbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Czzzqix/eero/refs/heads/main/eero%20modules/triggerbot/testing/triggerbot.luau"))()

-- WAIT A MOMENT FOR MODULES TO FULLY INITIALIZE
task.wait(0.1)

-- Link triggerbot to camlock for target sharing (CORRECTED)
if eero.camlock and eero.triggerbot then
    print("✅ Linking triggerbot to camlock...")
    eero.triggerbot.SetCamlockModule(eero.camlock)
    
    -- Verify the link worked
    if eero.camlock.GetTarget and eero.camlock.GetTargetPlayer then
        print("✅ Camlock functions available")
    else
        print("❌ Camlock functions not found")
        print("Available camlock methods:", table.concat(getmetatable(eero.camlock) and getmetatable(eero.camlock).__index and {} or {}, ", "))
    end
else
    print("❌ Failed to load one or more modules")
end

task.wait(0.5)

--// ========================================
--// CAMLOCK SETTINGS
--// ========================================
eero.camlock.settings.enabled = true
eero.camlock.settings.keybind = Enum.UserInputType.MouseButton2 -- Can also use Enum.UserInputType.MouseButton2, etc.
eero.camlock.settings.aimPart = "UpperTorso" -- "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
eero.camlock.settings.aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"} -- Auto-fallback order
eero.camlock.settings.holdMode = true -- true = hold key to lock, false = toggle on/off

-- Alternative keybind examples:
-- eero.camlock.settings.keybind = Enum.UserInputType.MouseButton2 -- Right mouse button
-- eero.camlock.settings.keybind = Enum.KeyCode.LeftControl -- Left Ctrl key
-- eero.camlock.settings.keybind = Enum.UserInputType.MouseButton1 -- Left mouse button

--// ========================================
--// CAMLOCK FOV SETTINGS
--// ========================================
eero.camlock.settings.FOVRadius = 120
eero.camlock.settings.useFOV = true
eero.camlock.settings.showFOV = false -- Legacy setting (use showFOVFill/showFOVOutline instead)

--// FOV Fill Settings
eero.camlock.settings.showFOVFill = true
eero.camlock.settings.FOVFillColor = Color3.fromRGB(225, 133, 255)
eero.camlock.settings.FOVFillTransparency = 0.2

--// FOV Outline Settings
eero.camlock.settings.showFOVOutline = true
eero.camlock.settings.FOVOutlineColor = Color3.fromRGB(245, 131, 228)
eero.camlock.settings.FOVOutlineThickness = 4
eero.camlock.settings.FOVOutlineTransparency = 1

--// ========================================
--// CAMLOCK PREDICTION SETTINGS
--// ========================================
eero.camlock.settings.autoPrediction = false
eero.camlock.settings.enablePrediction = false
eero.camlock.settings.predictionValue = 0.107 -- Manual fallback value

-- Custom prediction table (ping-based auto prediction)
eero.camlock.settings.predictionTable = {
    [70] = 0.107,   -- <= 70ms ping
    [80] = 0.117,   -- <= 80ms ping  
    [90] = 0.127,   -- <= 90ms ping
    [100] = 0.137,  -- <= 100ms ping
    [110] = 0.147,  -- <= 110ms ping
    [120] = 0.157,  -- <= 120ms ping
    [130] = 0.163,  -- <= 130ms ping
    [140] = 0.173,  -- <= 140ms ping
    [math.huge] = 0.183 -- > 140ms ping (default)
}

--// ========================================
--// CAMLOCK NOTIFICATION SETTINGS
--// ========================================
eero.camlock.settings.notifications = true
eero.camlock.settings.notificationColor = Color3.fromRGB(85, 255, 127) -- Green
eero.camlock.settings.notificationDuration = 1.5
eero.camlock.settings.notificationSize = 15

--// ========================================
--// CAMLOCK DISPLAY SETTINGS
--// ========================================
eero.camlock.settings.showPingDisplay = true
eero.camlock.settings.pingDisplaySize = 16
eero.camlock.settings.pingDisplayColor = Color3.fromRGB(255, 255, 255) -- White
eero.camlock.settings.pingDisplayPosition = Vector2.new(0.5, 0.90) -- Center bottom

--// ========================================
--// CAMLOCK SMOOTHING SETTINGS
--// ========================================
eero.camlock.settings.smoothing = false
eero.camlock.settings.smoothingFactor = 0.2 -- 0.1 = very smooth, 1 = no smoothing

--// ========================================
--// CAMLOCK ADVANCED SETTINGS
--// ========================================
eero.camlock.settings.wallCheck = false -- Check if target is behind walls
eero.camlock.settings.teamCheck = false -- Don't target teammates
eero.camlock.settings.aliveCheck = true -- Don't target dead players
eero.camlock.settings.maxDistance = math.huge -- Maximum distance to target

--// ========================================
--// CAMLOCK ROBUST TARGETING SETTINGS
--// ========================================
-- Custom aimPart fallback order (if primary aimPart isn't found)
eero.camlock.settings.aimPartFallbacks = {"HumanoidRootPart", "UpperTorso", "LowerTorso", "Head"}
-- This prevents errors with custom character rigs or missing body parts

--// ========================================
--// CAMLOCK VISUAL SETTINGS
--// ========================================
eero.camlock.settings.highlightTarget = false
eero.camlock.settings.highlightColor = Color3.fromRGB(255, 0, 0) -- Red

--// ========================================
--// CAMLOCK DEBUG SETTINGS
--// ========================================
eero.camlock.settings.debug = false
eero.camlock.settings.showDebugOverlay = false -- Live debug HUD
eero.camlock.settings.debugOverlayPosition = Vector2.new(0.02, 0.02) -- Top-left corner
eero.camlock.settings.debugOverlaySize = 14
eero.camlock.settings.debugOverlayColor = Color3.fromRGB(255, 255, 0) -- Yellow

--// ========================================
--// TRIGGERBOT MAIN SETTINGS
--// ========================================
eero.triggerbot.settings.enabled = true
eero.triggerbot.settings.keybind = Enum.KeyCode.T -- Triggerbot toggle key
eero.triggerbot.settings.holdMode = true -- true = hold to enable, false = toggle

--// ========================================
--// TRIGGERBOT FIRING SETTINGS
--// ========================================
eero.triggerbot.settings.delay = 0.15 -- Seconds between shots
eero.triggerbot.settings.minTargetHP = 0 -- Only fire if target health > this
eero.triggerbot.settings.maxClicksPerSecond = 15 -- Rate limit (CPS cap)
eero.triggerbot.settings.randomDelay = true -- Add slight randomization
eero.triggerbot.settings.randomDelayRange = 0.03 -- +/- range for randomization

--// ========================================
--// TRIGGERBOT TARGET VALIDATION
--// ========================================
eero.triggerbot.settings.requireCamlockTarget = false -- Only fire when camlock has target
eero.triggerbot.settings.teamCheck = false -- Don't fire on teammates
eero.triggerbot.settings.aliveCheck = false -- Don't fire on dead players

--// ========================================
--// TRIGGERBOT NOTIFICATION SETTINGS
--// ========================================
eero.triggerbot.settings.notifications = false -- Enable triggerbot notifications
eero.triggerbot.settings.notifyOnFire = false -- Notify each time we fire
eero.triggerbot.settings.notificationColor = Color3.fromRGB(255, 85, 85) -- Red
eero.triggerbot.settings.notificationDuration = 1.0
eero.triggerbot.settings.notificationSize = 14

--// ========================================
--// TRIGGERBOT ADVANCED SETTINGS
--// ========================================
eero.triggerbot.settings.smartFiring = true -- Only fire when crosshair near target
eero.triggerbot.settings.smartFiringTolerance = 75 -- Pixels tolerance for smart firing
eero.triggerbot.settings.burstMode = false -- Fire in bursts instead of continuous
eero.triggerbot.settings.burstCount = 3 -- Shots per burst
eero.triggerbot.settings.burstDelay = 0.8 -- Delay between bursts

--// ========================================
--// TRIGGERBOT VISUAL SETTINGS
--// ========================================
eero.triggerbot.settings.showFireIndicator = true -- Show visual indicator when firing
eero.triggerbot.settings.fireIndicatorColor = Color3.fromRGB(255, 0, 0) -- Red
eero.triggerbot.settings.fireIndicatorDuration = 0.2

--// ========================================
--// TRIGGERBOT DEBUG SETTINGS
--// ========================================
eero.triggerbot.settings.debug = false
eero.triggerbot.settings.showDebugOverlay = false -- Live debug HUD
eero.triggerbot.settings.debugOverlayPosition = Vector2.new(0.02, 0.15) -- Below camlock debug
eero.triggerbot.settings.debugOverlaySize = 12
eero.triggerbot.settings.debugOverlayColor = Color3.fromRGB(255, 165, 0) -- Orange

--// ========================================
--// TRIGGERBOT INPUT METHOD
--// ========================================
eero.triggerbot.settings.inputMethod = "userinput" -- "mouse1click", "virtual", or "userinput"

--// ========================================
--// CAMLOCK CALLBACK HOOKS (Optional)
--// ========================================

-- Called when a target is locked onto
eero.camlock.settings.onTargetLocked = function(targetPlayer)
    print("🎯 Camlock locked onto: " .. targetPlayer.Name)
    -- You can add custom logic here, like:
    -- - Update ESP highlights
    -- - Play sound effects
    -- - Send notifications to UI
end

-- Called when target is unlocked/lost
eero.camlock.settings.onTargetUnlocked = function(previousTargetPlayer)
    print("🔓 Camlock unlocked from: " .. previousTargetPlayer.Name)
    -- Custom logic for target loss
end

-- Called when camlock is toggled on/off
eero.camlock.settings.onToggle = function(enabled)
    print("🔄 Camlock toggled: " .. (enabled and "ON" or "OFF"))
    -- Update UI indicators, etc.
end

--// ========================================
--// TRIGGERBOT CALLBACK HOOKS (Optional)
--// ========================================

-- Called when triggerbot fires
eero.triggerbot.settings.onFire = function(targetPlayer)
    print("🔫 Triggerbot fired on: " .. targetPlayer.Name)
    -- You can add custom logic here like:
    -- - Track shots fired
    -- - Update kill counters
    -- - Play fire sound effects
end

-- Called when triggerbot is toggled on/off
eero.triggerbot.settings.onToggle = function(enabled)
    print("🔄 Triggerbot toggled: " .. (enabled and "ON" or "OFF"))
    -- Update UI indicators, etc.
end

--// ========================================
--// EXAMPLE USAGE OF API METHODS
--// ========================================

-- Get current ping and prediction
local currentPing = eero.camlock:GetLivePing()
local currentPrediction = eero.camlock:GetPrediction(currentPing)
print("📡 Current Ping: " .. currentPing .. "ms | Prediction: " .. currentPrediction)

-- Example: Load game profile based on current game
local gameId = game.PlaceId
local gameProfiles = {
    [2788229376] = "dahood",      -- Da Hood
    [286090429] = "arsenal",      -- Arsenal  
    [292439477] = "phantom_forces", -- Phantom Forces
    [142823291] = "mm2"           -- Murder Mystery 2
}

if gameProfiles[gameId] then
    print("🎮 Auto-loading profile for current game...")
    eero.camlock:LoadProfile(gameProfiles[gameId])
    
    -- Adjust triggerbot settings based on game
    if gameProfiles[gameId] == "dahood" then
        eero.triggerbot:UpdateSettings({
            delay = 0.12,
            smartFiringTolerance = 80,
            burstMode = false
        })
    elseif gameProfiles[gameId] == "arsenal" then
        eero.triggerbot:UpdateSettings({
            delay = 0.08,
            smartFiringTolerance = 60,
            burstMode = true,
            burstCount = 2
        })
    end
else
    print("🎮 No specific profile for this game, using manual config")
end

local availableProfiles = eero.camlock:GetAvailableProfiles()
print("📋 Available camlock profiles: " .. table.concat(availableProfiles, ", "))

print("🎮 KEYBIND SUMMARY:")
print("   Camlock: " .. tostring(eero.camlock.settings.keybind) .. " (" .. (eero.camlock.settings.holdMode and "Hold" or "Toggle") .. ")")
print("   Triggerbot: " .. tostring(eero.triggerbot.settings.keybind) .. " (" .. (eero.triggerbot.settings.holdMode and "Hold" or "Toggle") .. ")")

print("✅ Eero Camlock + Triggerbot loaded and configured!")
print("📖 Camlock Version: " .. eero.camlock.settings._version)
print("📖 Triggerbot Version: " .. eero.triggerbot.settings._version)
print("🎮 Camlock Mode: " .. (eero.camlock.settings.holdMode and "Hold" or "Toggle"))
print("🎮 Triggerbot Mode: " .. (eero.triggerbot.settings.holdMode and "Hold" or "Toggle"))
print("🎯 Aim Part: " .. eero.camlock.settings.aimPart)
print("🔮 Prediction: " .. (eero.camlock.settings.autoPrediction and "Auto" or "Manual") .. " (" .. eero.camlock.settings.predictionValue .. ")")
print("🔫 Triggerbot Delay: " .. eero.triggerbot.settings.delay .. "s")
print("🔫 Fire Method: " .. eero.triggerbot.settings.inputMethod)
