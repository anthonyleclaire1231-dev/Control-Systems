-- ==========================================
-- MASTER ELEVATOR (SERVER / REDSTONE CONTROLLER)
-- ==========================================

local cableSide = "back"  -- Side where the bundled cable is connected
local modemSide = "top"   -- Side where the wireless modem is attached

local floorHeights = {
    ["1"]  = 0,
    ["2"]  = 12,
    ["2a"] = 6,
    ["3"]  = 22,
    ["3a"] = 16,
    ["4"]  = 32,
    ["4a"] = 26,
    ["5"]  = 42,
    ["5a"] = 36,
    ["6"]  = 50,
    ["7"]  = 58
}

local stateFile = "elevator_floor.txt"

local function getSavedFloor()
    if fs.exists(stateFile) then
        local file = fs.open(stateFile, "r")
        local floor = file.readLine()
        file.close()
        if floorHeights[floor] then
            return floor
        end
    end
    return "5"
end

local function saveCurrentFloor(floor)
    local file = fs.open(stateFile, "w")
    file.write(floor)
    file.close()
end

local function moveElevator(direction, blocks)
    local color
    if direction == "up" then
        color = colors.green
    else
        color = colors.black
    end
    
    for i = 1, blocks do
        redstone.setBundledOutput(cableSide, color)
        sleep(0.05)
        redstone.setBundledOutput(cableSide, 0)
        sleep(0.05)
    end
end

rednet.open(modemSide)
local currentFloor = getSavedFloor()

while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== MASTER ELEVATOR ===")
    print("Current Floor: " .. currentFloor)
    print("Status: Listening for calls...")
    print("-----------------------")
    
    -- Listens for incoming elevator calls, dropping everything else
    local senderId, targetFloor = nil, nil
    while not targetFloor do
        local id, message = rednet.receive()
        if type(message) == "string" then
            local data = textutils.unserialize(message)
            if type(data) == "table" and data.app == "elevator" then
                senderId = id
                targetFloor = data.floor
            end
        end
    end
    
    if targetFloor and floorHeights[targetFloor] then
        if targetFloor == currentFloor then
            print("\nAlready on floor " .. targetFloor)
        else
            print("\nCall from Terminal #" .. senderId)
            print("Moving to Floor " .. targetFloor .. "...")
            
            local currentHeight = floorHeights[currentFloor]
            local targetHeight = floorHeights[targetFloor]
            local diff = targetHeight - currentHeight
            
            if diff > 0 then
                moveElevator("down", diff)
            else
                moveElevator("up", math.abs(diff))
            end
            
            currentFloor = targetFloor
            saveCurrentFloor(currentFloor)
            print("Arrived at Floor " .. currentFloor)
        end
    end
    sleep(1)
end