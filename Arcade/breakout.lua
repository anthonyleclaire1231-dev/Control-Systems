local sx, sy = term.getSize()

-- Raw key codes
local KEY_ENTER = 28
local KEY_A = 30
local KEY_D = 32
local KEY_R = 19
local KEY_Q = 16
local KEY_LEFT = 203
local KEY_RIGHT = 205
local KEY_UP = 200
local KEY_DOWN = 208

local HIGHSCORE_FILE = "brick_breaker_scores.txt"

local function loadHighScores()
    if fs.exists(HIGHSCORE_FILE) then
        local file = io.open(HIGHSCORE_FILE, "r")
        if file then
            local content = file:read("*a")
            file:close()
            if content and content ~= "" then
                local scores = textutils.unserialize(content)
                if type(scores) == "table" then return scores end
            end
        end
    end
    return {}
end

local function saveHighScores(scores)
    local file = io.open(HIGHSCORE_FILE, "w")
    if file then
        file:write(textutils.serialize(scores))
        file:close()
    end
end

local function addHighScore(id, score)
    local scores = loadHighScores()
    local found = false
    for i, entry in ipairs(scores) do
        if entry.id == id then
            found = true
            if score > entry.score then
                entry.score = score
            end
            break
        end
    end
    if not found then
        table.insert(scores, {id = id, score = score})
    end
    table.sort(scores, function(a, b) return a.score > b.score end)
    saveHighScores(scores)
end

local function titleScreen()
    while true do
        term.clear()
        term.setCursorPos(math.ceil(sx / 2) - 6, math.ceil(sy / 2) - 2)
        term.write("BRICK BREAKER")
        
        term.setCursorPos(math.ceil(sx / 2) - 11, math.ceil(sy / 2))
        term.write("Press ENTER to Play")
        
        term.setCursorPos(math.ceil(sx / 2) - 9, math.ceil(sy / 2) + 1)
        term.write("Controls: A / D")

        local ev, key = os.pullEvent("key")
        if key == KEY_ENTER then
            return true
        end
    end
end

local function difficultyScreen()
    local selected = 1
    local options = {"Easy", "Medium", "Hard"}
    while true do
        term.clear()
        term.setCursorPos(math.ceil(sx / 2) - 8, math.ceil(sy / 2) - 2)
        term.write("SELECT DIFFICULTY")
        for i = 1, #options do
            term.setCursorPos(math.ceil(sx / 2) - 8, math.ceil(sy / 2) + i - 1)
            if i == selected then
                term.write("> " .. options[i] .. " <")
            else
                term.write("  " .. options[i] .. "  ")
            end
        end
        local ev, key = os.pullEvent("key")
        if key == KEY_UP then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == KEY_DOWN then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == KEY_ENTER then
            if selected == 1 then return 4
            elseif selected == 2 then return 3
            else return 2 end
        end
    end
end

local function highScoresScreen()
    local scores = loadHighScores()
    local page = 1
    local maxLines = sy - 5
    if maxLines < 1 then maxLines = 1 end
    local totalPages = math.max(1, math.ceil(#scores / maxLines))

    while true do
        term.clear()
        term.setCursorPos(math.ceil(sx / 2) - 5, 1)
        term.write("HIGH SCORES")
        
        if #scores == 0 then
            term.setCursorPos(math.ceil(sx / 2) - 9, math.ceil(sy / 2))
            term.write("No high scores yet!")
        else
            local startIndex = (page - 1) * maxLines + 1
            local endIndex = math.min(startIndex + maxLines - 1, #scores)
            
            for i = startIndex, endIndex do
                local entry = scores[i]
                local lineY = 3 + (i - startIndex)
                term.setCursorPos(math.ceil(sx / 2) - 8, lineY)
                term.write(string.format("%2d. %s   %d", i, entry.id, entry.score))
            end
        end

        term.setCursorPos(2, sy - 1)
        term.write(string.format("Page %d/%d (<-/->)", page, totalPages))
        term.setCursorPos(math.ceil(sx / 2) - 10, sy)
        term.write("Press ENTER to Play Again")

        local ev, key = os.pullEvent("key")
        if key == KEY_LEFT then
            page = page - 1
            if page < 1 then page = totalPages end
        elseif key == KEY_RIGHT then
            page = page + 1
            if page > totalPages then page = 1 end
        elseif key == KEY_ENTER then
            return
        end
    end
end

local function promptHighScoreID(score)
    term.clear()
    term.setCursorPos(math.ceil(sx / 2) - 9, math.ceil(sy / 2) - 2)
    term.write("NEW HIGHSCORE: " .. score)
    term.setCursorPos(math.ceil(sx / 2) - 11, math.ceil(sy / 2))
    term.write("Enter 3-Character ID:")
    
    local id = ""
    term.setCursorPos(math.ceil(sx / 2) - 1, math.ceil(sy / 2) + 2)
    term.write("[   ]")
    term.setCursorPos(math.ceil(sx / 2), math.ceil(sy / 2) + 2)
    
    while true do
        local ev, p1, p2 = os.pullEvent()
        if ev == "char" then
            if #id < 3 then
                id = id .. string.upper(p1)
                term.setCursorPos(math.ceil(sx / 2) - 1, math.ceil(sy / 2) + 2)
                term.write("[" .. id .. string.rep(" ", 3 - #id) .. "]")
                term.setCursorPos(math.ceil(sx / 2) - 1 + #id, math.ceil(sy / 2) + 2)
            end
        elseif ev == "key" then
            if p1 == 14 and #id > 0 then -- Backspace key code
                id = id:sub(1, #id - 1)
                term.setCursorPos(math.ceil(sx / 2) - 1, math.ceil(sy / 2) + 2)
                term.write("[" .. id .. string.rep(" ", 3 - #id) .. "]")
                term.setCursorPos(math.ceil(sx / 2) - 1 + #id, math.ceil(sy / 2) + 2)
            elseif p1 == KEY_ENTER and #id == 3 then
                addHighScore(id, score)
                break
            end
        end
    end
end

local function playGame(ballSpeedDivisor)
    local px = math.ceil(sx / 2)
    local bx, by = math.ceil(sx / 2), sy - 3
    local vx, vy = 1, -1
    local score = 0

    local bricks = {}
    for y = 2, 4 do
        for x = 2, sx - 1 do
            table.insert(bricks, {x = x, y = y})
        end
    end

    local function draw()
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Score: " .. score)
        
        for i = 1, #bricks do
            local brick = bricks[i]
            if brick then
                term.setCursorPos(brick.x, brick.y)
                term.write("#")
            end
        end
        
        term.setCursorPos(math.max(1, math.min(sx - 4, px - 2)), sy)
        term.write("=====")
        
        if by >= 1 and by <= sy and bx >= 1 and bx <= sx then
            term.setCursorPos(bx, by)
            term.write("O")
        end
    end

    local timer = os.startTimer(0.05)
    local frameCount = 0
    while true do
        draw()
        
        local event, p1, p2 = os.pullEvent()
        if event == "timer" and p1 == timer then
            timer = os.startTimer(0.05)
            frameCount = frameCount + 1
            
            if frameCount % ballSpeedDivisor == 0 then
                bx = bx + vx
                by = by + vy
                
                if bx <= 1 then 
                    bx = 2 
                    vx = -vx 
                elseif bx >= sx then 
                    bx = sx - 1 
                    vx = -vx 
                end
                
                if by <= 1 then 
                    by = 2 
                    vy = -vy 
                end
                
                for i = #bricks, 1, -1 do
                    local brick = bricks[i]
                    if brick and bx == brick.x and by == brick.y then
                        table.remove(bricks, i)
                        vy = -vy
                        score = score + 10
                        break
                    end
                end
                
                if by == sy - 1 and bx >= px - 2 and bx <= px + 2 then
                    vy = -vy
                elseif by >= sy then
                    promptHighScoreID(score)
                    highScoresScreen()
                    return
                end
            end
        elseif event == "key" then
            local moveDist = p2 and 1 or 3
            if p1 == KEY_A and px > 3 then 
                px = math.max(3, px - moveDist)
            elseif p1 == KEY_D and px < sx - 2 then 
                px = math.min(sx - 2, px + moveDist)
            end
        end
    end
end

while true do
    titleScreen()
    local divisor = difficultyScreen()
    playGame(divisor)
end