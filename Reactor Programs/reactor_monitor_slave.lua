-- Remote Monitor Receiver Script
local monSide = "back"
local mon = nil
local monWidth = 37
local receiverStartTime = os.clock() -- Track uptime locally on the receiver

if peripheral.isPresent(monSide) and peripheral.getType(monSide) == "monitor" then
    local wrapped = peripheral.wrap(monSide)
    if wrapped then
        local w, h = wrapped.getSize()
        if w then monWidth = w end
        mon = wrapped
    end
end

if not mon then
    error("No monitor attached to " .. monSide)
end

local modemOpened = false
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
        modemOpened = true
        break
    end
end

if not modemOpened then
    error("No wireless modem found on this computer")
end

local function mprint(y, text)
    pcall(function()
        mon.setCursorPos(1, y)
        mon.write(text .. string.rep(" ", math.max(0, monWidth - #text)))
    end)
end

local function makeBar(percent, width)
    percent = math.min(100, math.max(0, percent))
    local innerWidth = width - 2
    local filled = math.floor((percent / 100) * innerWidth + 0.5)
    local empty = innerWidth - filled
    return "[" .. string.rep("|", filled) .. string.rep(" ", empty) .. "]"
end

local function drawFooter(dataList, storList)
    if not mon then return end
    
    local totalOut = 0
    local warningMsg = nil
    
    for i = 1, 10 do
        totalOut = totalOut + (dataList[i].rawOut or 0)
        local heatVal = tonumber(dataList[i].heat) or 0
        if heatVal > 5000 and not warningMsg then
            warningMsg = "[!] R" .. i .. " OVERHEAT!"
        end
    end
    
    for i = 1, 10 do
        local fuelVal = tonumber(dataList[i].fuel) or 0
        if fuelVal <= 0 and not warningMsg then
            warningMsg = "[!] R" .. i .. " FUEL EMPTY!"
        end
    end
    
    for i = 1, 10 do
        if (storList[i] or 0) <= 0 and not warningMsg then
            warningMsg = "[!] S" .. i .. " STORAGE EMPTY!"
        end
    end
    
    local totalEU = 0
    for i = 1, 10 do
        totalEU = totalEU + (storList[i] or 0)
    end
    
    local outPercent = math.floor((totalOut / 24000) * 100)
    outPercent = math.min(100, math.max(0, outPercent))
    
    local euPercent = math.floor((totalEU / 10000000) * 100)
    euPercent = math.min(100, math.max(0, euPercent))
    
    -- Use the receiver's local start time for smooth, accurate uptime tracking
    local uptimeSecs = math.floor(os.clock() - receiverStartTime)
    local mins = math.floor(uptimeSecs / 60)
    local secs = uptimeSecs % 60
    local uptimeStr = string.format("%dm %ds", mins, secs)
    
    mprint(14, string.rep("-", monWidth))
    
    if warningMsg then
        mprint(15, " " .. warningMsg)
    else
        mprint(15, " Uptime: " .. uptimeStr)
    end
    
    local barWidth = 12
    local outBar = makeBar(outPercent, barWidth)
    local euBar = makeBar(euPercent, barWidth)
    
    mprint(16, " Total EU Output: " .. outBar .. " " .. outPercent .. "%")
    mprint(17, " Total EU Storage:" .. euBar .. " " .. euPercent .. "%")
end

local function padRight(str, len)
    str = tostring(str)
    if #str >= len then return str end
    return string.rep(" ", len - #str) .. str
end

local function padLeft(str, len)
    str = tostring(str)
    if #str >= len then return str end
    return str .. string.rep(" ", len - #str)
end

local function makeLine(id, out, heat, fuel, eu)
    local idStr = tostring(id)
    if type(id) == "number" and id < 10 then idStr = " " .. idStr end
    local fuelDisplay = tostring(fuel) .. "%"
    if id == "#" then
        return string.format(" R%-2s     %s   %s  %s  %s", idStr, padLeft(out, 5), padLeft(heat, 5), padLeft(fuelDisplay, 5), padLeft(eu, 4))
    else
        return string.format(" R%s   %s   %s   %s   %s", idStr, padRight(out, 5), padRight(heat, 5), padRight(fuelDisplay, 5), padRight(eu, 4))
    end
end

mon.clear()

while true do
    local senderId, message = rednet.receive()
    if type(message) == "string" then
        local msg = textutils.unserialize(message)
        if type(msg) == "table" and msg.app == "reactor_mon" and msg.data then
            local spinnerChar = msg.spinner or "|"
            local last = msg.data
            local stor = msg.stor or {}

            mprint(1, " ==== TSSR MK7 REACTOR MONITOR " .. spinnerChar .. " ====")
            mprint(2, makeLine("#", "Out", "Heat", "Fuel", "EU"))
            mprint(3, string.rep("-", monWidth))

            for i = 1, 10 do
                mprint(3 + i, makeLine(i, last[i].out, last[i].heat, last[i].fuel, last[i].eu))
            end
            
            drawFooter(last, stor)
        end
    end
end