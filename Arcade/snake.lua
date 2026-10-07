-- Tekkit Classic Arcade Snake with Persistent High Scores
local w,h = term.getSize()

function printCentred( y, s )
    local x = math.floor((w - string.len(s)) / 2)
    term.setCursorPos(x,y)
    term.clearLine()
    term.write( s )
end

-- High Score Functions
local scoreFile = "snake_scores.txt"

local function loadScores()
    local scores = {}
    if fs.exists(scoreFile) then
        local file = io.open(scoreFile, "r")
        if file then
            for line in file:lines() do
                local name, score = line:match("^(%S+)%s+(%d+)$")
                if name and score then
                    table.insert(scores, {name = name, score = tonumber(score)})
                end
            end
            file:close()
        end
    end
    return scores
end

local function saveScores(scores)
    local file = io.open(scoreFile, "w")
    if file then
        for _, entry in ipairs(scores) do
            file:write(entry.name .. " " .. entry.score .. "\n")
        end
        file:close()
    end
end

local function addHighScore(newName, newScore)
    local scores = loadScores()
    local found = false
    
    for _, entry in ipairs(scores) do
        if entry.name == newName then
            found = true
            if newScore > entry.score then
                entry.score = newScore
            end
            break
        end
    end
    
    if not found then
        table.insert(scores, {name = newName, score = newScore})
    end
    
    table.sort(scores, function(a, b) return a.score > b.score end)
    saveScores(scores)
end

local function showLeaderboard()
    local scores = loadScores()
    local page = 1
    local perPage = h - 6
    if perPage < 1 then perPage = 5 end
    local totalPages = math.max(1, math.ceil(#scores / perPage))

    while true do
        term.clear()
        printCentred(2, "=== HIGH SCORES ===")
        
        if #scores == 0 then
            printCentred(math.floor(h/2), "No high scores yet!")
        else
            local startIdx = (page - 1) * perPage + 1
            local endIdx = math.min(startIdx + perPage - 1, #scores)
            
            local yPos = 4
            for i = startIdx, endIdx do
                local entry = scores[i]
                printCentred(yPos, string.format("%d. %s - %d", i, entry.name, entry.score))
                yPos = yPos + 1
            end
        end
        
        printCentred(h - 2, string.format("Page %d of %d (Left/Right to Flip)", page, totalPages))
        printCentred(h - 1, "Press ENTER to Play Again")
        
        local event, p1 = os.pullEvent("key")
        if event == "key" then
            if (p1 == 203 or p1 == 30) and page > 1 then
                page = page - 1
            elseif (p1 == 205 or p1 == 32) and page < totalPages then
                page = page + 1
            elseif p1 == 28 then
                break
            end
        end
    end
end

-- Main Game Loop wrapper
while true do
    local xVel,yVel = 1,0
    local xPos, yPos = math.floor(w/2), math.floor(h/2)
    local pxVel, pyVel = nil, nil

    local nLength = 1
    local nExtraLength = 6
    local bRunning = true

    local tailX,tailY = xPos,yPos
    local nScore = 0
    local nDifficulty = 2
    local nSpeed, nInterval

    local screen = {}
    for x=1,w do
        screen[x] = {}
        for y=1,h do
            screen[x][y] = {}
        end
    end
    screen[xPos][yPos] = { snake = true }

    local nFruit = 1
    local tFruits = {
        "A", "B", "C", "D", "E", "F", "G", "H",
        "I", "J", "K", "L", "M", "N", "O", "P",
        "Q", "R", "S", "T", "U", "V", "W", "X",
        "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h",
        "i", "j", "k", "l", "m", "n", "o", "p",
        "q", "r", "s", "t", "u", "v", "w", "x",
        "y", "z",
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
        "@", "$", "%", "#", "&", "!", "?", "+", "*", "~"
    }

    local function addFruit()
        while true do
            local x = math.random(1,w)
            local y = math.random(2,h)
            local fruit = screen[x][y]
            if fruit.snake == nil and fruit.wall == nil and fruit.fruit == nil then
                screen[x][y] = { fruit = true }
                term.setCursorPos(x,y)
                term.write(tFruits[nFruit])
                break
            end
        end
        
        nFruit = nFruit + 1
        if nFruit > #tFruits then
            nFruit = 1
        end
    end

    local function drawMenu()
        term.setCursorPos(1,1)
        term.write( "SCORE "..nScore )

        term.setCursorPos(w-11,1)
        term.write( "DIFFICULTY "..(nDifficulty or "?") )
    end

    local function update( )
        local x,y = xPos,yPos
        if pxVel and pyVel then
            xVel, yVel = pxVel, pyVel
            pxVel, pyVel = nil, nil
        end

        if nExtraLength == 0 then
            local tail = screen[tailX][tailY]
            screen[tailX][tailY] = {}
            term.setCursorPos(tailX,tailY)
            term.write(" ")
            tailX = tail.nextX
            tailY = tail.nextY
        else
            nExtraLength = nExtraLength - 1
        end
        
        local head = screen[xPos][yPos]
        local newXPos = xPos + xVel
        local newYPos = yPos + yVel
        if newXPos < 1 then
            newXPos = w
        elseif newXPos > w then
            newXPos = 1
        end
        if newYPos < 2 then
            newYPos = h
        elseif newYPos > h then
            newYPos = 2
        end
        
        local newHead = screen[newXPos][newYPos]
        if newHead.snake == true or newHead.wall == true then
            bRunning = false
        else
            if newHead.fruit == true then
                nScore = nScore + 10
                nExtraLength = nExtraLength + 1
                addFruit()
            end
            xPos = newXPos
            yPos = newYPos
            head.nextX = newXPos
            head.nextY = newYPos
            screen[newXPos][newYPos] = { snake = true }
        end
        
        term.setCursorPos(xPos,yPos)
        term.write("S")

        drawMenu()
    end

    term.clear()
    local function drawFrontend()
        printCentred( math.floor(h/2) - 3, "" )
        printCentred( math.floor(h/2) - 2, "SELECT DIFFICULTY" )
        printCentred( math.floor(h/2) - 1, "" )
        printCentred( math.floor(h/2) + 0, ((nDifficulty == 1) and "[ EASY ]") or "EASY" )
        printCentred( math.floor(h/2) + 1, ((nDifficulty == 2) and "[ MEDIUM ]") or "MEDIUM" )
        printCentred( math.floor(h/2) + 2, ((nDifficulty == 3) and "[ HARD ]") or "HARD" )
        printCentred( math.floor(h/2) + 3, "" )
    end

    drawMenu()
    drawFrontend()
    while true do
        local e,key = os.pullEvent( "key" )
        if key == 17 or key == 200 then
            if nDifficulty > 1 then
                nDifficulty = nDifficulty - 1
                drawMenu()
                drawFrontend()
            end
        elseif key == 31 or key == 208 then
            if nDifficulty < 3 then
                nDifficulty = nDifficulty + 1
                drawMenu()
                drawFrontend()
            end
        elseif key == 28 then
            break
        end
    end

    local tSpeeds = { 5, 10, 25 }
    nSpeed = tSpeeds[nDifficulty]
    nInterval = 1 / nSpeed

    term.clear()
    drawMenu()
    screen[tailX][tailY].snake = true
    while nExtraLength > 0 do
        update()
    end
    addFruit()
    addFruit()

    local timer = os.startTimer(0)
    while bRunning do
        local event, p1, p2 = os.pullEvent()
        if event == "timer" and p1 == timer then
            timer = os.startTimer(nInterval)
            update( false )
        elseif event == "key" then
            local key = p1
            if key == 17 or key == 200 then
                if yVel == 0 then pxVel,pyVel = 0,-1 end
            elseif key == 31 or key == 208 then
                if yVel == 0 then pxVel,pyVel = 0,1 end
            elseif key == 30 or key == 203 then
                if xVel == 0 then pxVel,pyVel = -1,0 end
            elseif key == 32 or key == 205 then
                if xVel == 0 then pxVel,pyVel = 1,0 end
            end 
        end
    end

    printCentred( math.floor(h/2) - 3, "" )
    printCentred( math.floor(h/2) - 2, "G A M E O V E R" )
    printCentred( math.floor(h/2) - 1, "FINAL SCORE "..nScore )
    printCentred( math.floor(h/2) + 0, "" )
    printCentred( math.floor(h/2) + 1, "ENTER 3-CHAR NICKNAME:" )
    
    local nickname = ""
    term.setCursorPos(math.floor(w/2) - 1, math.floor(h/2) + 2)
    term.write("[   ]")
    
    while string.len(nickname) < 3 do
        local event, p1 = os.pullEvent()
        if event == "char" then
            nickname = nickname .. string.upper(p1)
            if string.len(nickname) > 3 then
                nickname = string.sub(nickname, 1, 3)
            end
            term.setCursorPos(math.floor(w/2) - 1, math.floor(h/2) + 2)
            term.write("[" .. nickname .. string.rep(" ", 3 - string.len(nickname)) .. "]")
        elseif event == "key" and p1 == 14 and string.len(nickname) > 0 then
            nickname = string.sub(nickname, 1, string.len(nickname) - 1)
            term.setCursorPos(math.floor(w/2) - 1, math.floor(h/2) + 2)
            term.write("[" .. nickname .. string.rep(" ", 3 - string.len(nickname)) .. "]")
        end
    end
    
    if string.len(nickname) == 0 then
        nickname = "AAA"
    end

    addHighScore(nickname, nScore)
    showLeaderboard()
end