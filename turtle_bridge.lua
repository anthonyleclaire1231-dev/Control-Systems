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

    local slot1_6 = nil
    for i = 1, 6 do
        if turtle.getItemCount(i) > 0 then
            slot1_6 = i
            break
        end
    end

    if slot1_6 then
        turtle.select(slot1_6)
        local count = 0
        while count < 4 and turtle.getItemCount(slot1_6) > 0 do
            if turtle.forward() then
                turtle.placeDown()
                count = count + 1
            else
                turtle.dig()
                sleep(0.5)
            end
        end
    end

    local slot7_9 = nil
    for i = 7, 9 do
        if turtle.getItemCount(i) > 0 then
            slot7_9 = i
            break
        end
    end

    if slot7_9 then
        turtle.select(slot7_9)
        local count = 0
        while count < 2 and turtle.getItemCount(slot7_9) > 0 do
            if turtle.forward() then
                turtle.placeDown()
                count = count + 1
            else
                turtle.dig()
                sleep(0.5)
            end
        end
    end
end