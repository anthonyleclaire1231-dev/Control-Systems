-- ==========================================
-- TSSR MK7 REACTOR CONTROLLER - RECEIVER (REMOTE)
-- ComputerCraft 1.4 / Tekkit Classic
-- ==========================================

os.pullEvent = os.pullEventRaw

local password = "MyAccount1"
local modemSide = nil
local diskSide = nil

-- Locate peripherals automatically
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

local function drawLockedUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TSSR MK7 REACTOR REMOTE TERMINAL ===")
    print("-----------------------------------")
    print("Status: LOCKED")
    print("Please insert Keycard to access controls.")
    print("-----------------------------------")
    
    if os.clock() < statusTimer and statusMessage ~= "" then
        print(statusMessage)
    end
end

local function drawUnlockedUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TSSR MK7 REACTOR REMOTE TERMINAL ===")
    print("-----------------------------------")
    
    for i, reactor in ipairs(reactors) do
        local statusText = reactor.state and "[ ON  ]" or "[ OFF ]"
        print(string.format("%2d. %-10s  %s", i, reactor.name, statusText))
    end
    
    print("-----------------------------------")
    print("Status: UNLOCKED (5m Session)")
    
    if os.clock() < statusTimer and statusMessage ~= "" then
        print(statusMessage)
    else
        print("Enter 1-10 to toggle | Type 'exit' to lock")
    end
    print()
    write("Command > ")
end

while true do
    -- 1. LOCKED STATE: Wait for keycard insertion using the clean event pattern
    drawLockedUI()
    
    local unlocked = false
    local sessionEnd = 0
    
    while not unlocked do
        -- Check if a card is already sitting in the drive
        if diskSide and disk.isPresent(diskSide) then
            local mountPath = disk.getMountPath(diskSide)
            if mountPath and fs.exists(mountPath .. "/password.txt") then
                local file = fs.open(mountPath .. "/password.txt", "r")
                local content = file.readLine()
                file.close()
                if content then
                    content = string.gsub(content, "^%s*(.-)%s*$", "%1")
                    if content == password then
                        unlocked = true
                        sessionEnd = os.clock() + 300 -- 5 minutes
                        setStatus("Access granted. Unlocked!")
                        break
                    else
                        setStatus("Access denied: Invalid password.")
                        disk.eject(diskSide)
                        sleep(2)
                    end
                end
            else
                setStatus("Invalid keycard: password.txt missing.")
                disk.eject(diskSide)
                sleep(2)
            end
        end
        
        -- Wait for disk insertion or network sync in the background
        local event, p1, p2 = os.pullEvent()
        if event == "disk" and p1 == diskSide then
            -- Loops back immediately to validate the inserted disk
        elseif event == "rednet_message" then
            local ok, data = pcall(textutils.unserialize, p2)
            if ok and type(data) == "table" and data.app == "reactor_control" then
                if data.type == "status" and data.reactors then
                    reactors = data.reactors
                end
            end
        end
    end

    -- 2. UNLOCKED STATE: Clean interactive menu using standard read()
    while unlocked do
        -- Check if 5 minutes have expired or if the disk was manually removed
        if os.clock() >= sessionEnd then
            setStatus("Session expired. Locking...")
            unlocked = false
            break
        end
        
        if diskSide then
            if not disk.isPresent(diskSide) then
                setStatus("Keycard removed. Locking...")
                unlocked = false
                break
            end
        end

        drawUnlockedUI()

        -- Use a short timeout on a background timer combined with a non-blocking check 
        -- so the 5-minute session timer and disk removal are monitored continuously, 
        -- while allowing normal read() input.
        local timerId = os.startTimer(0.2)
        local inputReady = false
        local input = nil

        while true do
            -- Check disk and expiration inside input loop
            if os.clock() >= sessionEnd or (diskSide and not disk.isPresent(diskSide)) then
                unlocked = false
                break
            end

            local event, p1, p2 = os.pullEvent()
            
            if event == "timer" and p1 == timerId then
                -- Timeout reached, proceed to standard read() for smooth typing
                inputReady = true
                break
            elseif event == "rednet_message" then
                local ok, data = pcall(textutils.unserialize, p2)
                if ok and type(data) == "table" and data.app == "reactor_control" then
                    if data.type == "status" and data.reactors then
                        reactors = data.reactors
                        break -- Redraw screen with updated reactor status
                    end
                end
            elseif event == "disk" and p1 == diskSide then
                if not disk.isPresent(diskSide) then
                    unlocked = false
                    break
                end
            end
        end

        if not unlocked then
            break
        end

        if inputReady then
            input = read()
            if input then
                input = string.gsub(input, "^%s*(.-)%s*$", "%1")
                if input == "exit" then
                    unlocked = false
                    break
                elseif input ~= "" then
                    local choice = tonumber(input)
                    if choice and choice >= 1 and choice <= #reactors then
                        reactors[choice].state = not reactors[choice].state
                        local payload = textutils.serialize({
                            app = "reactor_control",
                            type = "command",
                            choice = choice
                        })
                        rednet.broadcast(payload)
                        sleep(0.2)
                    end
                end
            end
        end
    end

    -- Force eject disk when session ends or user exits
    if diskSide and disk.isPresent(diskSide) then
        disk.eject(diskSide)
    end
    setStatus("Terminal locked.")
    sleep(1)
end