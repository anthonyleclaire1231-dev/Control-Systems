while true do
    local empty = true
    for i = 1, 9 do
        if turtle.getItemCount(i) > 0 then
            empty = false
            break
        end
    end
    if empty then
        break
    end

    local placed1_6 = 0
    while placed1_6 < 4 do
        local activeSlot = nil
        for i = 1, 6 do
            if turtle.getItemCount(i) > 0 then
                activeSlot = i
                break
            end
        end
        
        if not activeSlot then
            break
        end

        turtle.select(activeSlot)
        if turtle.forward() then
            turtle.placeDown()
            placed1_6 = placed1_6 + 1
        else
            turtle.dig()
            sleep(0.5)
        end
    end

    local placed7_9 = 0
    while placed7_9 < 2 do
        local activeSlot = nil
        for i = 7, 9 do
            if turtle.getItemCount(i) > 0 then
                activeSlot = i
                break
            end
        end
        
        if not activeSlot then
            break
        end

        turtle.select(activeSlot)
        if turtle.forward() then
            turtle.placeDown()
            placed7_9 = placed7_9 + 1
        else
            turtle.dig()
            sleep(0.5)
        end
    end
end