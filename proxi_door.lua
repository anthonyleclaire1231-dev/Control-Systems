-- ==========================================
-- PROXIMITY DOOR CONTROLLER - ccSensors r11
-- ComputerCraft 1.33 / Tekkit Classic
-- ==========================================

if sensors == nil then
    assert(os.loadAPI("/rom/apis/sensors"))
end

local controllerSide = sensors.getController()
local doorSide = "left"

-- Whitelisted usernames
local whitelist = {
    "apmw17_real",
    "BeefyPleb"
}

local function isWhitelisted(name)
    if not name then return false end
    for _, whitelistedName in ipairs(whitelist) do
        if name == whitelistedName then
            return true
        end
    end
    return false
end

-- Dynamically find the Proximity sensor by shortName "Prox"[cite: 2]
local function findSensor(shortName)
    for _, name in ipairs(sensors.getSensors(controllerSide)) do
        local info = sensors.getSensorInfo(controllerSide, name, "shortName")
        if info.shortName == shortName then
            return name
        end
    end
    return nil
end

local sensor = findSensor("Prox")
if not sensor then
    error("No Proximity sensor connected")
end

-- Set range to 8 (range must be passed as a string)[cite: 2]
sensors.setSensorRange(controllerSide, sensor, "8")

print("Proximity door monitor active...")
sleep(1)

-- Main program loop
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== PROXIMITY SENSOR MONITOR ===")
    print("---------------------------------")
    
    -- Step 1: Enumerate available targets for the "Players" probe[cite: 2]
    local okTargets, targets = pcall(sensors.getAvailableTargetsforProbe, controllerSide, sensor, "Players")
    
    local doorOpen = false
    
    if okTargets and targets and #targets > 0 then
        print("Raw Targets Found: " .. #targets)
        print("---------------------------------")
        
        -- Step 2: Loop through each target handle and fetch its data dictionary[cite: 2]
        for _, target in ipairs(targets) do
            local okRead, data = pcall(sensors.getSensorReadingAsDict, controllerSide, sensor, target, "Players")
            
            if okRead and type(data) == "table" and data.name ~= nil then
                local playerName = data.name
                local distance = tonumber(data.distance) or 999
                
                print(string.format("Name: %s | Dist: %.1f", tostring(playerName), distance))
                
                if distance <= 3 then
                    if isWhitelisted(playerName) then
                        print("  [✔] Whitelist match! Opening door.")
                        doorOpen = true
                    else
                        print("  [✖] In range, but NOT whitelisted.")
                    end
                end
            else
                print("  [!] Failed to read target data.")
            end
        end
    else
        print("Status: No players detected in range.")
    end
    
    redstone.setOutput(doorSide, doorOpen)
    print("---------------------------------")
    print("Door Output (" .. doorSide .. "): " .. tostring(doorOpen))
    
    sleep(0.5)
end