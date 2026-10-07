-- ==========================================
-- TSSR MK7 REACTOR CONTROLLER - RECEIVER (REMOTE)
-- ComputerCraft 1.4 / Tekkit Classic
-- ==========================================

local password = "MyAccount1"
local unlockedUntil = 0
local lastDiskState = false

local modemSide = nil
local diskSide = nil

for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        modemSide = side
    elseif peripheral.getType(side) == "drive" then
        diskSide = side
    end
end

if not modemSide then
    error("No wireless modem found on this computer")
end

local reactors = {}
for i = 1, 9 do
    table.insert(reactors, {name = " Reactor " .. i, state = true})
end
table.insert(reactors, {name = "Reactor 10", state = true})

local statusMessage = ""
local statusTimer = 0

local function setStatus(msg)
    statusMessage = msg
    statusTimer = os.clock() + 4
end

local function drawUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TSSR MK7 REACTOR REMOTE TERMINAL ===")
    print("-----------------------------------")
    
    for i, reactor in ipairs(reactors) do
        local statusText = reactor.state and "[ ON  ]" or "[ OFF ]"
        print(string.format("%2d. %-10s  %s", i, reactor.name, statusText))
    end
    
    print("-----------------------------------")
    if unlockedUntil > os.clock() then
        print("Status: UNLOCKED")
    else
        print("Status: LOCKED (Insert Keycard)")
    end
    
    if os.clock() < statusTimer and statusMessage ~= "" then
        print(statusMessage)
    else
        print("Enter 1-10 to toggle | Type 'exit'")
    end
    print()
    write("Command > ")
end

while true do
    -- 1. Check disk insertion/removal state
    if diskSide then
        local currentDiskPresent = disk.isPresent(diskSide)
        if currentDiskPresent and not lastDiskState then
            local mountPath = disk.getMountPath(diskSide)
            if mountPath and fs.exists(mountPath .. "/password.txt") then
                local file = fs.open(mountPath .. "/password.txt", "r")
                local content = file.readAll()
                file.close()
                content = string.gsub(content, "^%s*(.-)%s*$", "%1")
                if content == password then
                    unlockedUntil = os.clock() + 300
                    setStatus("Access granted. Unlocked for 5m.")
                else
                    setStatus("Access denied: Invalid password.")
                end
            else
                setStatus("Invalid keycard: password.txt missing.")
            end
        elseif not currentDiskPresent and unlockedUntil > 0 then
            unlockedUntil = 0
            setStatus("Keycard removed. Controls locked.")
        end
        lastDiskState = currentDiskPresent
    end

    -- 2. Check if 5-minute session has expired; if so, eject the disk
    if unlockedUntil > 0 and os.clock() >= unlockedUntil then
        unlockedUntil = 0
        if diskSide and disk.isPresent(diskSide) then
            disk.eject(diskSide)
            setStatus("Session expired. Disk ejected.")
        end
    end

    drawUI()

    -- 3. Standard clean input prompt (waits for user input smoothly)
    local input = read()
    
    if input then
        input = string.gsub(input, "^%s*(.-)%s*$", "%1")
        if input == "exit" then
            term.clear()
            term.setCursorPos(1, 1)
            if diskSide and disk.isPresent(diskSide) then
                disk.eject(diskSide)
            end
            print("Remote terminal closed.")
            break
        elseif input ~= "" then
            local choice = tonumber(input)
            if choice and choice >= 1 and choice <= #reactors then
                if os.clock() < unlockedUntil then
                    -- Toggle state locally right away for instant feedback
                    reactors[choice].state = not reactors[choice].state
                    
                    -- Send command to master controller
                    local payload = textutils.serialize({
                        app = "reactor_control",
                        type = "command",
                        choice = choice
                    })
                    rednet.broadcast(payload)
                else
                    setStatus("Controls locked! Insert keycard.")
                end
            end
        end
    end
end