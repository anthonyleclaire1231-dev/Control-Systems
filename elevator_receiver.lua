-- ==========================================
-- FLOOR TERMINAL (CLIENT CALLER)
-- ==========================================

local modemSide = "back" -- Side where the wireless modem is attached

rednet.open(modemSide)

while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("=== FLOOR TERMINAL ===")
    print("-----------------------")
    print("Available floors:")
    print("1, 2, 3, 4, 5, 6, 7, 8, 9")
    print("-----------------------")
    write("Call elevator to floor: ")
    
    local targetFloor = read()
    
    local validFloors = {
        ["1"]=true, ["2"]=true, ["3"]=true, 
        ["4"]=true, ["5"]=true, ["6"]=true, 
        ["7"]=true, ["8"]=true, ["9"]=true
    }
    
    if validFloors[targetFloor] then
        print("\nSending call...")
        local payload = textutils.serialize({
            app = "elevator",
            floor = targetFloor
        })
        rednet.broadcast(payload)
        print("Call sent successfully!")
        sleep(1.5)
    else
        print("\nInvalid floor name! Press any key.")
        os.pullEvent("key")
    end
end