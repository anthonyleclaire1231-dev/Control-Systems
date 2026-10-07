local w,h = term.getSize()
local sX = w / 2 - 10/2
local sY = 1
local iX = 2
local iY = 2

local HIGHSCORE_FILE = "tetris_scores.txt"

local KEY_ENTER = 28
local KEY_LEFT = 203
local KEY_RIGHT = 205
local KEY_UP = 200
local KEY_DOWN = 208
local KEY_K = 37 -- K key
local KEY_L = 38 -- L key

local heldFigureNum = nil
local hasSwapped = false

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

local function highScoresScreen()
    local scores = loadHighScores()
    local page = 1
    local maxLines = h - 5
    if maxLines < 1 then maxLines = 1 end
    local totalPages = math.max(1, math.ceil(#scores / maxLines))

    while true do
        term.clear()
        term.setCursorPos(math.ceil(w / 2) - 5, 1)
        term.write("HIGH SCORES")
        
        if #scores == 0 then
            term.setCursorPos(math.ceil(w / 2) - 9, math.ceil(h / 2))
            term.write("No high scores yet!")
        else
            local startIndex = (page - 1) * maxLines + 1
            local endIndex = math.min(startIndex + maxLines - 1, #scores)
            
            for i = startIndex, endIndex do
                local entry = scores[i]
                local lineY = 3 + (i - startIndex)
                term.setCursorPos(math.ceil(w / 2) - 8, lineY)
                term.write(string.format("%2d. %s   %d", i, entry.id, entry.score))
            end
        end

        term.setCursorPos(2, h - 1)
        term.write(string.format("Page %d/%d (<-/->)", page, totalPages))
        term.setCursorPos(math.ceil(w / 2) - 10, h)
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
    term.setCursorPos(math.ceil(w / 2) - 9, math.ceil(h / 2) - 2)
    term.write("NEW HIGHSCORE: " .. score)
    term.setCursorPos(math.ceil(w / 2) - 11, math.ceil(h / 2))
    term.write("Enter 3-Character ID:")
    
    local id = ""
    term.setCursorPos(math.ceil(w / 2) - 1, math.ceil(h / 2) + 2)
    term.write("[   ]")
    term.setCursorPos(math.ceil(w / 2), math.ceil(h / 2) + 2)
    
    while true do
        local ev, p1, p2 = os.pullEvent()
        if ev == "char" then
            if #id < 3 then
                id = id .. string.upper(p1)
                term.setCursorPos(math.ceil(w / 2) - 1, math.ceil(h / 2) + 2)
                term.write("[" .. id .. string.rep(" ", 3 - #id) .. "]")
                term.setCursorPos(math.ceil(w / 2) - 1 + #id, math.ceil(h / 2) + 2)
            end
        elseif ev == "key" then
            if p1 == 14 and #id > 0 then
                id = id:sub(1, #id - 1)
                term.setCursorPos(math.ceil(w / 2) - 1, math.ceil(h / 2) + 2)
                term.write("[" .. id .. string.rep(" ", 3 - #id) .. "]")
                term.setCursorPos(math.ceil(w / 2) - 1 + #id, math.ceil(h / 2) + 2)
            elseif p1 == KEY_ENTER and #id == 3 then
                addHighScore(id, score)
                break
            end
        end
    end
end

local matrix = {}
for p = 1 ,200 do
matrix[p] = 0 
end

local figurePosX = 4
local figurePosY = 1
local figureNum = 1
local figureNextNum = math.random(1,7) 
local figureRotateNumber = 1

local figure = {
    {{0,0,1,0,0,1,1,1}},
    {{0,1,1,1,2,1,1,2},{1,0,0,1,1,1,1,2},{1,0,0,1,1,1,2,1},{1,0,1,1,2,1,1,2}},
    {{1,0,1,1,1,2,2,2},{0,1,1,1,2,1,0,2},{0,0,1,0,1,1,1,2},{2,0,0,1,1,1,2,1}},
    {{1,0,1,1,1,2,0,2},{0,0,0,1,1,1,2,1},{1,0,2,0,1,1,1,2},{0,1,1,1,2,1,2,2}},
    {{0,1,1,1,1,2,2,2},{1,0,0,1,1,1,0,2}},
    {{1,1,2,1,0,2,1,2},{0,0,0,1,1,1,1,2}},
    {{0,2,1,2,2,2,3,2},{1,0,1,1,1,2,1,3}} 
}

local run = true
local FIRST = 1
local PAUSE = 2
local GAME_OVER = 3
local GAME = 4
local gameState = FIRST 
local speed = 1.0 
local SCORE = 0 
local LINES = 0 
local LEVEL = 0 

local function paintInfa()
    local y = iY
    
    term.setCursorPos(iX,y)
    term.write("Score : " .. SCORE)
    y = y + 1
    term.setCursorPos(iX,y)
    term.write("Lines : " .. LINES)
    y = y + 1
    term.setCursorPos(iX,y)
    term.write("Level : " .. LEVEL)
    
    y = y + 2
    term.setCursorPos(iX, y)
    term.write("Next Block")
    y = y + 1
    for i = 1,8,2 do 
        term.setCursorPos(iX + figure[figureNextNum][1][i], y + figure[figureNextNum][1][i + 1])
        term.write("0")
    end
    
    y = y + 3
    term.setCursorPos(iX, y)
    term.write("Held Block")
    y = y + 1
    if heldFigureNum then
        for i = 1,8,2 do 
            term.setCursorPos(iX + figure[heldFigureNum][1][i], y + figure[heldFigureNum][1][i + 1])
            term.write("0")
        end
    end

    term.setCursorPos(iX,h - 1)
    term.write("ComputerCraft")
    term.setCursorPos(iX,h)
    term.write("Tetris")

    return    
end

local helpText = {    
    "",
    "------HELP-----", 
    "",
    "Right:   -> or D",
    "---------------",
    "Left: <- or A",
    "---------------",
    "Rotate:",
    " space or enter",
    "---------------",
    "Hold: K",
    "---------------",
    "Swap/Replace: L",
    "---------------",
    "Pause: P",
    "---------------",
    "Exit: backspace",
    "",
    "---------------",
}

local function paintText()
    local y = 1
    local x = sX + 14
    
    while #helpText > y - 1 do
        term.setCursorPos(x,y)
        term.write(helpText[y])
        y = y + 1
    end
    return
end

local function paintMatrix()
    for y = 0,17 do
        term.setCursorPos(sX,sY + y)
        term.write("|..........|")
    end

    local pos = 21 

    for y = sY,18 do
        for x = 1 + sX , 10 + sX do
            if matrix[pos] ~= 0 then 
                term.setCursorPos(x,y)
                term.write("0")    
            end
            if matrix[pos] == -1 then matrix[pos] = 0 end                
            
            pos = pos + 1
        end
    end
end

local function canMove()
    for i = 1,8,2 do 
        local x = figurePosX + figure[figureNum][figureRotateNumber][i];
        local y = figurePosY + (figure[figureNum][figureRotateNumber][i+1] * 10);
        if x < 0 or x > 9 or x+y > 200 or x+y < 1 then 
            return false
        end
        
        if matrix[x+y] == 1 then 
            return false;
        end
    end
    
    return true
end

local function newFigure()
    figurePosX = 4 
    figurePosY = 1 
    figureRotateNumber = 1 
 
    figureNum = figureNextNum
    figureNextNum = math.random(1,7) 
    hasSwapped = false

    return 
end

local function insertFigureToMatrix()     
    local kube,pos = 0, 0
    if canMove() then  
        kube = -1
    else 
        figurePosY = figurePosY - 10 
        kube = 1;
    end
    
    for i = 1,8,2 do  
        pos = figurePosX + figure[figureNum][figureRotateNumber][i] + figurePosY + (figure[figureNum][figureRotateNumber][i+1] * 10)
        matrix[pos] = kube
    end
    
    local linesCount = 0 
    
    local y = 18
    while y >= 1 do
        local rowStart = 21 + (y - 1) * 10
        local count = 0
        for x = 0, 9 do
            if matrix[rowStart + x] == 1 then
                count = count + 1
            end
        end
        
        if y == 1 and count > 0 then
            gameState = GAME_OVER
        end
        
        if count == 10 then
            linesCount = linesCount + 1
            for ry = y, 2, -1 do
                local dest = 21 + (ry - 1) * 10
                local src = 21 + (ry - 2) * 10
                for x = 0, 9 do
                    matrix[dest + x] = matrix[src + x]
                end
            end
            for x = 0, 9 do
                matrix[21 + x] = 0
            end
        else
            y = y - 1
        end
    end
    
    if linesCount > 0 then 
        LINES = LINES + linesCount 
        LEVEL = math.floor (LINES / 10) 
        local bonus = {10,50,100,200}
        SCORE = SCORE + (bonus[linesCount] or 200)
    end
     
    if kube == 1 then 
        newFigure()
    end
        
    return
end

local timer = os.startTimer(0)
local event, p1, p2 = nil

local function game()
    local previosfigureRotateNumber = figureRotateNumber;
    local previosfigurePosX = figurePosX;
    local previosfigurePosY = figurePosY;

    if event == "key" then 
        local key = p1

        if key == 30 or key == 203 then 
            figurePosX = figurePosX - 1
        elseif key == 32 or key == 205 then 
            figurePosX = figurePosX + 1
        elseif key == 57 or key == 28 or key == 200 then 
            figureRotateNumber =  ((#figure[figureNum] > figureRotateNumber  ) and figureRotateNumber + 1) or 1 
        elseif key == 31 or key == 208 then   
            figurePosY = figurePosY + 10
        elseif key == KEY_K then
            if not heldFigureNum and not hasSwapped then
                heldFigureNum = figureNum
                newFigure()
                hasSwapped = true
            end
        elseif key == KEY_L then
            if heldFigureNum and not hasSwapped then
                local temp = figureNum
                figureNum = heldFigureNum
                heldFigureNum = temp
                figurePosX = 4
                figurePosY = 1
                figureRotateNumber = 1
                hasSwapped = true
            end
        end
    end
    
    if canMove() ~= true then 
        figureRotateNumber = previosfigureRotateNumber 
        figurePosX = previosfigurePosX
        figurePosY = previosfigurePosY
    end
    
    speed =  ((speed > 0.1) and 1.0 - LEVEL/10) or 0.1
    
    if event == "timer" and p1 == timer then 
        timer = os.startTimer(speed)
        figurePosY = figurePosY + 10             
    end        
    
    return
end

local function newGame()
    SCORE = 0 
    LINES = 0 
    LEVEL = 0
    heldFigureNum = nil
    hasSwapped = false
    for p = 1 ,200 do matrix[p] = 0  end 
    newFigure()
    return
end

flashing = true
local function paintDialog()
    local text = {    
        {
            "WELCOME TO TETRIS",
            "    P A U S E",
            "G A M E  O V E R",
            "  PLAY TETRIS"
        },    
        {
            "    to start",
            "    to resume",
            "    to start",
            ""
        },    
    }
        
    term.setCursorPos(iX,h/2)
    term.write(text[1][gameState])

    if flashing and gameState ~= GAME  then
        term.setCursorPos(iX,h/2 + 2)
        term.write(" Press any key")
        term.setCursorPos(iX,h/2 + 3)
        term.write(text[2][gameState])
    end
    
    if event == "timer" and p1 == timer then 
        timer = os.startTimer(0.5)
        flashing = flashing ~= true                
    end    
    
    return
end

newGame()

while run do
    event, p1, p2 = os.pullEvent()
    
    if event == "key" then 
        local key = p1        
        if  key == 25 then 
            gameState = PAUSE
        elseif  key == 14 then 
            run = false    
        elseif key > 1 and gameState ~= GAME then 
            if gameState == GAME_OVER then newGame()  end 
            gameState = GAME 
            timer = os.startTimer(0)    
        end
    end
    
    if gameState == GAME then     
        game()
    end

    insertFigureToMatrix() 
    
    if gameState == GAME_OVER then
        promptHighScoreID(SCORE)
        highScoresScreen()
        newGame()
        gameState = GAME
        timer = os.startTimer(0)
    end

    term.clear() 
    paintMatrix()
    paintInfa()
    paintText()    
    paintDialog()     
end

term.clear() 
term.setCursorPos(1,1)