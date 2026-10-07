-- ==========================================
-- TSSR MK7 REACTOR CONTROLLER - SENDER (MASTER)
-- ComputerCraft 1.4 / Tekkit Classic
-- ==========================================

local bundledSide = "right"

-- Open wireless modem automatically
local modemSide = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        modemSide = side
        break
    end
end

local reactors = {
    {name = " Reactor 1",  color = colors.white,  state = true},
    {name = " Reactor 2",  color = colors.black,  state = true},
    {name = " Reactor 3",  color = colors.red,    state = true},
    {name = " Reactor 4",  color = colors.green,  state = true},
    {name = " Reactor 5",  color = colors.blue,   state = true},
    {name = " Reactor 6",  color = colors.yellow, state = true},
    {name = " Reactor 7",  color = colors.purple, state = true},
    {name = " Reactor 8",  color = colors.pink,   state = true},
    {name = " Reactor 9",  color = colors.gray,   state = true},
    {name = "Reactor 10",  color = colors.orange, state = true}
}

-- Updates the bundled cable output based on reactor states
local function updateRedstone()
    local output = 0
    for _, reactor in ipairs(reactors) do
        if not reactor.state then
            output = colors.combine(output, reactor.color)
        end
    end
    rs.setBundledOutput(bundledSide, output)
end

-- Broadcast current reactor states to remote receivers
local function broadcastState()
    if modemSide then
        local payload = textutils.serialize({
            app = "reactor_control",
            type = "status",
            reactors = reactors
        })
        rednet.broadcast(payload)
    end
end

-- Renders the controller interface on the screen
local function drawUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TSSR MK7 REACTOR CONTROLLER (MASTER) ===")
    print("-----------------------------------")
    
    for i, reactor in ipairs(reactors) do
        local statusText = reactor.state and "[ ON  ]" or "[ OFF ]"
        print(string.format("%2d. %-10s  %s", i, reactor.name, statusText))
    end
    
    print("-----------------------------------")
    print("Status: UNLOCKED (Emergency Console)")
    print("Enter 1-10 to toggle | Type 'exit'")
end

-- Initialize state
updateRedstone()
broadcastState()

-- Main program loop
while true do
    drawUI()
    write("Command > ")
    
    -- Use a short timeout on rednet.receive so local input and network sync share the loop smoothly
    local timer = os.startTimer(0.1)
    local input = nil
    
    while true do
        local event, p1, p2 = os.pullEvent()
        if event == "char" or event == "key" then
            -- Let read() handle the line input natively once typing starts
            -- (We catch the first trigger or use standard read approach via a wrapper)
        elseif event == "rednet_message" then
            local senderId, message = p1, p2
            local ok, data = pcall(textutils.unserialize, message)
            if ok and type(data) == "table" and data.app == "reactor_control" then
                if data.type == "command" then
                    local choice = tonumber(data.choice)
                    if choice and choice >= 1 and choice <= #reactors then
                        reactors[choice].state = not reactors[choice].state
                        updateRedstone()
                        broadcastState()
                        break -- Refresh UI to show state change
                    end
                end
            end
        elseif event == "timer" and p1 == timer then
            -- Break out of inner event listener to allow normal prompt handling
            break
        end
    end
    
    -- Read user input line cleanly
    local input = read()
    
    if input == "exit" then
        term.clear()
        term.setCursorPos(1, 1)
        print("Controller closed.")
        print("Reactors remain in current state.")
        break
    elseif input ~= "" then
        local choice = tonumber(input)
        if choice and choice >= 1 and choice <= #reactors then
            reactors[choice].state = not reactors[choice].state
            updateRedstone()
            broadcastState()
        end
    end
end