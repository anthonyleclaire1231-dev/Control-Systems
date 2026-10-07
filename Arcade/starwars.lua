local filmText = '2\n\n\n\n\n\n\n\n\n\n\n15\n       7h##########h7       \n      7############h7      \n     7##############h7     \n    7################h7    \n    ##################     \n   ####################    \n   ####################    \n   ##CC##CC##CC##CC##EE    \n   ##CC##CC##CC##CC##EE    \n  ######################   \n  ##GG##GG##GG##GG##GG##   \n  ##GG##GG##GG##GG##GG##   \n   ####################    \n     ################      \n\n\n\n\n\n\n\n\n1\n\n\n\n\n\n\n\n\n\n\n   Episode IV                         \n   A NEW HOPE                        \n\n   It is a period of civil war.       \n   Rebel spaceships, striking         \n   from a hidden base, have won       \n   their first victory against        \n   the evil Galactic Empire.          \n\n   During the battle, Rebel           \n   spies managed to steal secret      \n   plans to the Empire\'s              \n   ultimate weapon, the DEATH         \n   STAR, an armored space             \n   station with enough power          \n   to destroy an entire planet.       \n\n   Pursued by the Empire\'s            \n   sinister agents, Princess          \n   Leia races home aboard her         \n   starship, custodian of the         \n   stolen plans that can save her     \n   people and restore                 \n   freedom to the galaxy....          \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\*(Note: If you want to keep your exact copied `filmText` string from `rom/programs/secret/alongtimeago`, just keep the top part of your file with your string, and replace the bottom loop section with the code below)*:

```lua
local function iterator()
    return coroutine.wrap( function()
        for line in string.gmatch( filmText, "([^\n]*)\n" ) do
            coroutine.yield( line )
        end
        return false
    end )
end

term.clear()
local it = iterator()

local bFinished = false
while not bFinished do
    -- Read the frame header
    local holdLine = it()
    if not holdLine then
        bFinished = true
        break
    end

    -- Get dimensions safely with a fallback for large displays
    local w, h = term.getSize()
    if not w or w < 65 then w = 80 end
    if not h or h < 14 then h = 25 end
    
    local startX = math.floor( (w - 65) / 2 )
    local startY = math.floor( (h - 14) / 2 )

    -- Print the frame
    term.clear()
    for n=1,13 do
        local line = it()
        if line then
            term.setCursorPos(startX, startY + n)
            term.write( line )
        else
            bFinished = true
            break
        end
    end

    -- Hold the frame
    local hold = tonumber(holdLine) or 1
    local delay = (hold * 0.05) - 0.01
    if delay > 0 then
        sleep(delay)
    end
end