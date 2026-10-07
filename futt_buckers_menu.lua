-- Configuration
local monitorSide = "right" -- Change to your monitor's side (e.g., "top", "left", "back")
local textScale = 1         -- Valid scale (1 to 5)

-- Wrap the monitor peripheral
local monitor = peripheral.wrap(monitorSide)

if not monitor then
    print("Error: No monitor found on the " .. monitorSide .. " side!")
    return
end

-- Apply text scale
monitor.setTextScale(textScale)

-- Redirect terminal output to the monitor
term.redirect(monitor)

-- Page 1 lines (First 3 items)
local page1 = {
    "X=================================================================X",
    "|Exxxtra Cream Pie | Cannabisto's Happy Ending | Flounder Pounder |",
    "X=================================================================X",
    "|      Qty:  1     |           Qty:  10          |     Qty:  10     |",
    "X=================================================================X",
    "|      Price:      |             Price:          |       Price:     |",
    "|                  |                             |                  |",
    "|      $9.27       |             $4.96           |       $14.44     |",
    "X=================================================================X"
}

-- Page 2 lines (Last 3 items)
local page2 = {
    "X====================================================================X",
    "| Chicken Futt Bucker | Beefy's Beef Futt Bucker | Bacon Futt Bucker |",
    "X====================================================================X",
    "|       Qty: 10       |         Qty:  10         |      Qty:  10     |",
    "X====================================================================X",
    "|        Price:       |          Price:          |       Price:      |",
    "|                     |                          |                   |",
    "|        $14.42       |          $14.44          |       $14.44      |",
    "X====================================================================X"
}

-- Function to draw a specific page
local function drawPage(lines)
    monitor.clear()
    for i = 1, #lines do
        monitor.setCursorPos(1, i)
        monitor.write(lines[i])
    end
end

-- Main loop to swap pages every 10 seconds
while true do
    -- Display Page 1
    drawPage(page1)
    sleep(10)
    
    -- Display Page 2
    drawPage(page2)
    sleep(10)
end

-- Reset terminal back to the computer screen if stopped
term.restore()