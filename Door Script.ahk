#NoEnv
#SingleInstance Force
SendMode Event              
SetWorkingDir %A_ScriptDir%

SetKeyDelay, 30, 15

Numpad5::
    scriptText = 
(
os.pullEvent = os.pullEventRaw 

local monitorSide = "top"
local driveSide = "right"
local cableSide = "back"
local correctPassword = "MyAccount1"

local monitor = nil
if peripheral.isPresent(monitorSide) and peripheral.getType(monitorSide) == "monitor" then
    monitor = peripheral.wrap(monitorSide)
    term.redirect(monitor)
end

redstone.setBundledOutput(cableSide, colors.combine(colors.white, colors.black))

local function openDoor()
    print("\nACCESS GRANTED")
    redstone.setBundledOutput(cableSide, colors.white) 
    sleep(0.15) 
    redstone.setBundledOutput(cableSide, 0)
    
    sleep(8)
    
    redstone.setBundledOutput(cableSide, colors.white)
    sleep(0.15)
    redstone.setBundledOutput(cableSide, colors.combine(colors.white, colors.black))
end

while true do
    term.clear()
    term.setCursorPos(1,1)
    
    print("Insert Keycard...")
    
    local event, arg1 = os.pullEvent()
    
    if event == "disk" and arg1 == driveSide then
        local filePath = "disk/password.txt"
        
        if fs.exists(filePath) then
            local file = fs.open(filePath, "r")
            local diskPassword = file.readLine()
            file.close()
            
            if diskPassword == correctPassword then
                disk.eject(driveSide)
                openDoor()
            else
                print("\nACCESS DENIED")
                disk.eject(driveSide)
                sleep(4)
            end
        end
        
    elseif event == "redstone" then
        if redstone.testBundledInput(cableSide, colors.green) then
            openDoor()
        end
    end
end
)

    Loop, parse, scriptText, `n, `r
    {
        SendRaw, %A_LoopField%
        Send, {Enter}
    }
return