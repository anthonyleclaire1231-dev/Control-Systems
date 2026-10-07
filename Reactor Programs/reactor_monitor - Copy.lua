-- Multi-Reactor & MFSU Monitor – Sender 
if sensors == nil then
    assert(os.loadAPI("/rom/apis/sensors"), "Unable to load ccSensors API")
end
local side = sensors.getController()
if side == "none" then
    error("No SensorController attached")
end

local modemFound = false
for _, modemSide in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.getType(modemSide) == "modem" then
        rednet.open(modemSide)
        modemFound = true
        break
    end
end

local monSide = "back"
local mon = nil
local monWidth = 37

local function grabMonitor()
    local ok = pcall(function()
        if peripheral.isPresent(monSide) and peripheral.getType(monSide) == "monitor" then
            local wrapped = peripheral.wrap(monSide)
            if wrapped then
                local w, h = wrapped.getSize()
                if w then monWidth = w end
                mon = wrapped
                return
            end
        end
        mon = nil
    end)
    if not ok then mon = nil end
end

local function mprint(y, text)
    if not mon then return end
    pcall(function()
        mon.setCursorPos(1, y)
        mon.write(text .. string.rep(" ", math.max(0, monWidth - #text)))
    end)
end

local function findSensor(shortName)
    local sensorsList = sensors.getSensors(side)
    if not sensorsList then return nil end
    local n = #sensorsList
    for i = 1, n do
        local name = sensorsList[i]
        local info = sensors.getSensorInfo(side, name, "shortName")
        if info and info.shortName == shortName then
            return name
        end
    end
    return nil
end

local sensor = findSensor("IC2")
if not sensor then
    error("No IC2 sensor found")
end

sensors.setSensorRange(side, sensor, "32")

local function hasProbe(wanted)
    local readings = sensors.getAvailableReadings(side, sensor)
    if not readings then return false end
    local n = #readings
    for i = 1, n do
        local probe = readings[i]
        if string.lower(tostring(probe)) == string.lower(wanted) then
            return true
        end
    end
    return false
end

if not hasProbe("Reactor") then
    error("Reactor probe not available")
end

local function getFuelPercent(target)
    local ok, data = pcall(sensors.getSensorReadingAsDict, side, sensor, target, "ReactorContent")
    if not ok or type(data) ~= "table" then return 0 end
    
    local totalDamage = 0
    local cellCount = 0
    
    for _, item in pairs(data) do
        local s = tostring(item)
        if string.find(s, "itemCellUran") and not string.find(s, "Empty") and not string.find(s, "Depleted") then
            cellCount = cellCount + 1
            local damage = tonumber(string.match(s, "@(%d+)"))
            totalDamage = totalDamage + (damage or 0)
        end
    end
    
    if cellCount == 0 then return 0 end
    
    local maxPossibleDamage = cellCount * 9999
    local consumedPercent = (totalDamage / maxPossibleDamage) * 100
    local remainingPercent = math.floor((100 - consumedPercent) + 0.5)
    
    return math.min(100, math.max(0, remainingPercent))
end

local function getStorageEnergy(target)
    local ok, data = pcall(sensors.getSensorReadingAsDict, side, sensor, target, "EUStorage")
    if not ok or type(data) ~= "table" then return 0 end
    return tonumber(data.energy) or 0
end

local function getSortedTargets(probe)
    local ok, targets = pcall(sensors.getAvailableTargetsforProbe, side, sensor, probe)
    if not ok or type(targets) ~= "table" then return {} end
    table.sort(targets)
    return targets
end

local function getCoordKey(targetUid)
    local x, y, z = string.match(targetUid, "%,([%d%-]+),([%d%-]+),([%d%-]+)$")
    if x and y and z then
        return x .. "," .. y .. "," .. z
    end
    return targetUid
end

local mappingFile = "reactor_mappings.txt"
local reactorMappings = {}
local storageMappings = {}

local function loadMappings()
    if fs.exists(mappingFile) then
        local file = fs.open(mappingFile, "r")
        local content = file.readAll()
        file.close()
        for prefix, coordKey, assignedNum in string.gmatch(content, "(%a)_(%S+)=(%d+)") do
            if prefix == "R" then
                reactorMappings[coordKey] = tonumber(assignedNum)
            elseif prefix == "S" then
                storageMappings[coordKey] = tonumber(assignedNum)
            end
        end
    end
end

local function saveMappings()
    local file = fs.open(mappingFile, "w")
    for coordKey, assignedNum in pairs(reactorMappings) do
        file.writeLine("R_" .. coordKey .. "=" .. assignedNum)
    end
    for coordKey, assignedNum in pairs(storageMappings) do
        file.writeLine("S_" .. coordKey .. "=" .. assignedNum)
    end
    file.close()
end

loadMappings()

local function assignPersistentIndices(targets, mappingsTable)
    local assignedList = {}
    local usedNumbers = {}
    local changesMade = false
    
    local n = #targets
    for i = 1, n do
        local targetUid = targets[i]
        local coordKey = getCoordKey(targetUid)
        if mappingsTable[coordKey] then
            local num = mappingsTable[coordKey]
            assignedList[targetUid] = num
            usedNumbers[num] = true
        end
    end
    
    local nextAvailable = 1
    for i = 1, n do
        local targetUid = targets[i]
        local coordKey = getCoordKey(targetUid)
        if not assignedList[targetUid] then
            while usedNumbers[nextAvailable] do
                nextAvailable = nextAvailable + 1
            end
            assignedList[targetUid] = nextAvailable
            mappingsTable[coordKey] = nextAvailable
            usedNumbers[nextAvailable] = true
            changesMade = true
        end
    end
    
    if changesMade then
        saveMappings()
    end
    
    return assignedList
end

local last = {}
for i = 1, 10 do
    last[i] = {out = "0", heat = "0", fuel = 0, rawOut = 0, eu = "0%"}
end

local storageTotals = {}
for i = 1, 10 do
    storageTotals[i] = 0
end

local spinner = {"|", "/", "-", "\\"}
local spinIdx = 1
local startTime = os.clock()
local lastCleared = false

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
    
    local uptimeSecs = math.floor(os.clock() - startTime)
    local mins = math.floor(uptimeSecs / 60)
    local secs = uptimeSecs % 60
    local uptimeStr = string.format("%dm %ds", mins, secs)
    
    mprint(14, string.rep("-", monWidth))
    
    if warningMsg then
        mprint(15, " " .. warningMsg)
    else
        mprint(15, " Uptime: " .. uptimeStr)
    end
    
    local barWidth = 14
    local outBar = makeBar(outPercent, barWidth)
    local euBar = makeBar(euPercent, barWidth)
    
    mprint(16, " Total EU Output: " .. outBar .. " " .. outPercent .. "%")
    mprint(17, " Total EU Storage:" .. euBar .. " " .. euPercent .. "%")
end

while true do
    -- Continually check/re-acquire monitor on every iteration to bypass chunk load/boot race conditions
    grabMonitor()

    if mon then
        if not lastCleared then
            pcall(function() mon.clear() end)
            lastCleared = true
        end

        local reactorTargets = getSortedTargets("Reactor")
        local storageTargets = {}
        if hasProbe("EUStorage") then storageTargets = getSortedTargets("EUStorage") end

        local reactorIndices = assignPersistentIndices(reactorTargets, reactorMappings)
        local storageIndices = assignPersistentIndices(storageTargets, storageMappings)

        for i = 1, 10 do
            last[i] = {out = "0", heat = "0", fuel = 0, rawOut = 0, eu = "0%"}
            storageTotals[i] = 0
        end

        local rCount = #reactorTargets
        for i = 1, rCount do
            local rTarget = reactorTargets[i]
            local displayIdx = reactorIndices[rTarget]
            if displayIdx and displayIdx <= 10 then
                local rok, data = pcall(sensors.getSensorReadingAsDict, side, sensor, rTarget, "Reactor")
                if rok and type(data) == "table" and next(data) then
                    local rawO = tonumber(data.output or 0)
                    last[displayIdx].rawOut = rawO
                    last[displayIdx].out = tostring(rawO)
                    last[displayIdx].heat = tostring(data.heat or 0)
                    last[displayIdx].fuel = getFuelPercent(rTarget)
                end
            end
        end

        local sCount = #storageTargets
        for i = 1, sCount do
            local sTarget = storageTargets[i]
            local displayIdx = storageIndices[sTarget]
            if displayIdx and displayIdx <= 10 then
                local curEnergy = getStorageEnergy(sTarget)
                last[displayIdx].eu = math.floor((curEnergy / 10000000) * 100) .. "%"
                storageTotals[displayIdx] = curEnergy
            end
        end

        spinIdx = (spinIdx % #spinner) + 1

        mprint(1, " ==== TSSR MK7 REACTOR MONITOR " .. spinner[spinIdx] .. " ====")
        mprint(2, makeLine("#", "Out", "Heat", "Fuel", "EU"))
        mprint(3, string.rep("-", monWidth))
        for i = 1, 10 do
            mprint(3 + i, makeLine(i, last[i].out, last[i].heat, last[i].fuel, last[i].eu))
        end
        
        drawFooter(last, storageTotals)

        if modemFound then
            local payload = textutils.serialize({
                app = "reactor_mon",
                spinner = spinner[spinIdx],
                data = last,
                stor = storageTotals,
                uptimeStart = startTime
            })
            rednet.broadcast(payload)
        end
    else
        -- Reset flag so the monitor clears itself when it finally re-links after a chunk reload
        lastCleared = false
    end

    sleep(1)
end