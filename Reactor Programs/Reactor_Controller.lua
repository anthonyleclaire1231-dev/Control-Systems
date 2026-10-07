-- ==========================================
-- TSSR MK7 REACTOR CONTROLLER
-- ComputerCraft 1.4 / Tekkit Classic
-- ==========================================

-- Change this to match the side your bundled cable is connected to
local bundledSide = "back"

-- Map each reactor to its specified bundled cable color
local reactors = {
    {name = "Reactor 1 ", color = colors.white,  state = true},
    {name = "Reactor 2 ", color = colors.black,  state = true},
    {name = "Reactor 3 ", color = colors.red,    state = true},
    {name = "Reactor 4 ", color = colors.green,  state = true},
    {name = "Reactor 5 ", color = colors.blue,   state = true},
    {name = "Reactor 6 ", color = colors.yellow, state = true},
    {name = "Reactor 7 ", color = colors.purple, state = true},
    {name = "Reactor 8 ", color = colors.pink,   state = true},
    {name = "Reactor 9 ", color = colors.gray,   state = true},
    {name = "Reactor 10", color = colors.orange, state = true}
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

-- Renders the controller interface on the screen
local function drawUI()
    term.clear()
    term.setCursorPos(1, 1)
    print("=== TSSR MK7 REACTOR CONTROLLER ===")
    print("-----------------------------------")
    
    for i, reactor in ipairs(reactors) do
        local statusText = reactor.state and "[ ON  ]" or "[ OFF ]"
        print(i .. ". " .. reactor.name .. " " .. statusText)
    end
    
    print("-----------------------------------")
    print("Enter 1-10 to toggle | Type 'exit'")
end

-- Initialize reactors to default ON state
updateRedstone()

-- Main program loop
while true do
    drawUI()
    write("Command > ")
    local input = read()
    
    if input == "exit" then
        term.clear()
        term.setCursorPos(1, 1)
        print("Controller closed.")
        print("Reactors remain in current state.")
        break
    end
    
    local choice = tonumber(input)
    if choice and choice >= 1 and choice <= #reactors then
        reactors[choice].state = not reactors[choice].state
        updateRedstone()
    end
end