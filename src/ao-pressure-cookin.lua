-- Pressure Cookin' v.1
-- Introducing a collaborative game where you must work together to make glorious soups.
-- You are in the kitchen with your fellow chefs. Some have access to areas that others don't.
-- New orders are constantly coming through. Someone's gotta chop the onions and tomatos, and put it in the pot
-- And whose gonna get the plates??? Oh, careful, looks like that soup on the pot is going to burn soon!
-- Fulfill enough orders and double your CRED. Burn the kitchen down, and your CRED goes down with it

-- State Variables --
GameMode = GameMode or "Not-Started"
WaitTime = WaitTime or 2 * 60 * 1000
GameTime = GameTime or 5 * 60 * 1000

PaymentToken = "Y0Mm5Usu_ejPCE8R-PGVW7POgAwQdejiT2KG_Z3_UbI"
PaymentQty = 1000
BonusQty = 1000
MinimumPlayers = 1 -- CHANGE AFTER to 2

Players = Players or {}
TeamScore = 0

BoardWidth = 7
BoardHeight = 5
BoardItems = {
    { name = "Onion Box",                position = { x = 1, y = 5 } },
    { name = "Plate Stack",              position = { x = 1, y = 1 } },
    { name = "Pot on the Stove",         position = { x = 4, y = 3 } },
    { name = "Tomato Box",               position = { x = 7, y = 1 } },
    { name = "Automated Food Dispenser", position = { x = 7, y = 5 } }
}

CookingPot = {
    item = nil,
    timer = 0,
    status = "Empty" -- "Empty" || "Cooking" || "Ready" || "Burnt"
}

NewOrderRate = 20 * 1000 -- 20 Seconds
IncomingOrders = IncomingOrders or {}
FulfilledOrders = FulfilledOrders or 0

-- -- helpers -- --
function isTableTop(x)
    return x == 1 or x == 4 or x == 7
end

function isPositionTaken(x, y)
    local count = 0
    for _, player in ipairs(Players) do
        if player.x == x and player.y == y then
            count = count + 1
            if count > 1 then
                return true
            end
        end
    end
    return false
end

function isMoveValid(newX, newY)
    if newX < 1 or newX > BoardWidth or newY < 1 or newY > BoardHeight then
        return false
    end

    if GameBoard[newY][newX] ~= "Empty Space" then
        return false
    end

    return true
end

function findAdjacentObject(player)
    local directions = {
        { x = -1, y = 0 },  -- Left
        { x = 1,  y = 0 },  -- Right
        { x = 0,  y = -1 }, -- Up
        { x = 0,  y = 1 }   -- Down
    }

    for _, direction in ipairs(directions) do
        local adjX = player.x + direction.x
        local adjY = player.y + direction.y
        if GameBoard[adjY] and GameBoard[adjY][adjX] and GameBoard[adjY][adjX] ~= "Empty Space" then
            return GameBoard[adjY][adjX]
        end
    end
    return nil
end

function findAdjacentObjectCoordinates(player)
    local directions = {
        { x = -1, y = 0 },  -- Left
        { x = 1,  y = 0 },  -- Right
        { x = 0,  y = -1 }, -- Up
        { x = 0,  y = 1 }   -- Down
    }

    for _, direction in ipairs(directions) do
        local adjX = player.x + direction.x
        local adjY = player.y + direction.y

        if GameBoard[adjY] and GameBoard[adjY][adjX] and GameBoard[adjY][adjX] ~= "Empty Space" then
            return adjX, adjY
        end
    end
    return nil, nil
end

function dropItemOnTabletop(inventoryItem, x, y)
    if GameBoard[y] and GameBoard[y][x] == "Table Top" then
        GameBoard[y][x] = inventoryItem
        announce("Item-Dropped", "A chef placed " .. inventoryItem .. " at " .. x .. ", " .. y .. ".")
    else
        print("Cannot drop " .. inventoryItem .. " at (" .. x .. ", " .. y .. "). Invalid position.")
    end
end

function startCooking(inventoryItem, x, y)
    if GameBoard[y][x] == "Pot on the Stove" and CookingPot.status == "Empty" then
        if inventoryItem == "Chopped Onion" or inventoryItem == "Chopped Tomato" then
            CookingPot.item = inventoryItem
            CookingPot.timer = Now
            CookingPot.status = "Cooking"
            announce("Soup-Cookin",
                "Nice one Chefs, looks like we got some tasty " .. inventoryItem .. " on the go! Don't let it burn!")
        else
            print("Cannot cook " .. inventoryItem .. " in the pot.")
        end
    else
        if CookingPot.status ~= "Empty" then
            print("The pot is currently in use.")
        end
    end
end

-- -- initialization -- --
function initGameBoard()
    local board = {}
    for y = 1, BoardHeight do
        board[y] = {}
        for x = 1, BoardWidth do
            if isTableTop(x) then
                board[y][x] = "Table Top"
            else
                board[y][x] = "Empty Space"
            end
        end
    end

    for _, item in ipairs(BoardItems) do
        local pos = item.position
        board[pos.y][pos.x] = item.name
    end

    return board
end

GameBoard = initGameBoard();

function playerInitState()
    local player = {}
    local isValidPosition = false
    local posX
    local posY

    while not isValidPosition do
        posY = math.random(1, BoardHeight)

        if #Players % 2 == 0 then
            posX = 3
        else
            posX = 5
        end

        isValidPosition = true
        if isPositionTaken(posX, posY) then
            isValidPosition = false
        end
    end

    player = { x = posX, y = posY, inventory = "empty" }

    table.insert(Players, player)

    return player
end

-- -- actions -- --
function move(msg)
    local playerToMove = msg.From
    local direction = msg.Tags.Direction

    local directionMap = {
        Up = { x = 0, y = -1 },
        Down = { x = 0, y = 1 },
        Left = { x = -1, y = 0 },
        Right = { x = 1, y = 0 }
    }

    if directionMap[direction] then
        local newX = Players[playerToMove].x + directionMap[direction].x
        local newY = Players[playerToMove].y + directionMap[direction].y

        if isPositionTaken(newX, newY) then
            ao.send({
                Target = playerToMove,
                Action = "Move-Failed",
                Reason =
                "Movement blocked by another player"
            })
            return
        end

        if not isMoveValid(newX, newY) then
            ao.send({
                Target = playerToMove,
                Action = "Move-Failed",
                Reason =
                "Movement blocked by barrier or surface, stay on the kitchen floor!"
            })
            return
        end

        -- Update player coordinates without wrapping
        Players[playerToMove].x = newX
        Players[playerToMove].y = newY

        announce("Player-Moved", playerToMove .. " moved to " .. newX .. "," .. newY .. ".")
    else
        ao.send({ Target = playerToMove, Action = "Move-Failed", Reason = "Invalid direction." })
    end
end

function grab(msg)
    local player = Players[msg.From]
    local object = findAdjacentObject(player)

    if (object == "Onion Box" or object == "Tomato Box" or object == "Plate Stack" or object == "Tomato" or object == "Plate" or object == "Onion" or object == "Chopped Onion" or object == "Chopped Tomato") then
        if object == "Onion Box" then
            Players[msg.From].inventory = "Onion"
        elseif object == "Tomato Box" then
            Players[msg.From].inventory = "Tomato"
        elseif object == "Plate Stack" then
            Players[msg.From].inventory = "Plate"
        elseif object == "Tomato" then
            Players[msg.From].inventory = "Tomato"
        elseif object == "Plate" then
            Players[msg.From].inventory = "Plate"
        elseif object == "Onion" then
            Players[msg.From].inventory = "Onion"
        elseif object == "Chopped Onion" then
            Players[msg.From].inventory = "Chopped Onion"
        elseif object == "Chopped Tomato" then
            Players[msg.From].inventory = "Chopped Tomato"
        end

        local newInventory = Players[msg.From].inventory
        announce("Player-Grab", msg.From .. " grabbed a " .. newInventory .. ".")
    elseif (object == "Pot on the Stove") then
        -- Checking if the pot contains ready soup and the player is holding a plate
        if CookingPot.status == "Ready" and player.inventory == "Plate" then
            -- Determine the soup type based on what was cooked
            local soupType = CookingPot.item == "Chopped Onion" and "Onion Soup" or "Tomato Soup"
            player.inventory = soupType -- Player now holds the soup

            -- Reset the pot for the next cooking cycle
            CookingPot.item = nil
            CookingPot.status = "Empty"
            CookingPot.timer = 0

            print(msg.From .. " served " .. soupType .. ".")
            announce("Player-Serve", msg.From .. " served " .. soupType .. ".")
        else
            print("Nothing grabbed")
        end
    end
end

function drop(msg)
    local player = Players[msg.From]
    local object = findAdjacentObject(player)
    local adjX, adjY = findAdjacentObjectCoordinates(player)
    if adjX and adjY then
        print("Adjacent object found at: " .. adjX .. "and" .. adjY)
        print(object)
    else
        print("No adjacent object found.")
    end

    local playerInventory = Players[msg.From].inventory

    if object == "Table Top" and (player.inventory ~= "empty") then
        print("Dropping item.")
        dropItemOnTabletop(playerInventory, adjX, adjY)
        Players[msg.From].inventory = "empty"
    elseif object == "Pot on the Stove" and (playerInventory == "Chopped Onion" or playerInventory == "Chopped Tomato") then
        print("Start cooking")
        startCooking(playerInventory, adjX, adjY)
        Players[msg.From].inventory = "empty"
    elseif object == "Automated Food Dispenser" then
        if playerInventory == "Onion Soup" or playerInventory == "Tomato Soup" then
            local soupType = playerInventory
            print("serving: " .. soupType)

            for i, order in ipairs(IncomingOrders) do
                if order == soupType then
                    table.remove(IncomingOrders, i)
                    print(order .. " order fulfilled.")
                    FulfilledOrders = FulfilledOrders + 1
                    Players[msg.From].inventory = "empty"
                    break -- Stop after removing one matching order
                end
            end

            print("Order-Fulfilled: " .. player.name .. " fulfilled an order for " .. soupType .. ".")
        else
            print("Dropping item in Dispenser failed.")
        end
    end
end

function chop(msg)
    local player = Players[msg.From]
    local object = findAdjacentObject(player)

    print(object)

    if (object == "Onion" or object == "Tomato") and (player.inventory == "empty") then
        -- Assuming gameBoard is updated to reflect what's on each tabletop
        local adjX, adjY = findAdjacentObjectCoordinates(player)

        print(adjX)
        print(adjY)

        -- Check if adjX and adjY are not nil (meaning a valid adjacent object was found)
        if adjX and adjY then
            if GameBoard[adjY][adjX] == "Onion" then
                GameBoard[adjY][adjX] = "Chopped Onion"
                print("Chopped Onion!")
                -- print(player.name .. " chopped an onion.")
            elseif GameBoard[adjY][adjX] == "Tomato" then
                GameBoard[adjY][adjX] = "Chopped Tomato"
                print("Chopped Tomato")
                -- print(player.name .. " chopped a tomato.")
            end
        else
            print("No valid adjacent object found.")
        end
    else
        print("Nothing chopped.")
    end
end

-- --  game play -- --
function endGame()
    if CookingPot.status == "On Fire" then
        -- All players lose their deposits
        print("Game Over: The Cooking Pot caught fire! You're all fired and forget about your deposits!")
        announce("Kitchen-on-fire!", "The Cooking Pot caught fire! You're all fired and forget about your deposits!")
    else
        local performance = "appalling"
        local multiplier = 0.5

        if FulfilledOrders >= 8 and FulfilledOrders <= 9 then
            performance = "a pretty good job"
            multiplier = 1.5
        elseif FulfilledOrders >= 10 then
            performance = "bellissimo"
            multiplier = 2
        elseif FulfilledOrders >= 4 and FulfilledOrders <= 6 then
            performance = "very average"
            multiplier = 1
        end

        print("Cooking performance was " .. performance .. ".")

        for player, _ in pairs(Players) do
            sendReward(player, multiplier * tonumber(PaymentQty), "Win")
            Waiting[player] = false
        end
    end

    Players = {}
    CookingPot = {
        item = nil,
        timer = 0,
        status = "Empty" -- "Empty" || "Cooking" || "Ready" || "Burnt"
    }
    FulfilledOrders = 0
    IncomingOrders = {}

    announce("Game-Ended", "The game has ended!")
    startWaitingPeriod()
end

function onTick()
    if GameMode ~= "Playing" then return end

    if not LastOrderTick or Now - LastOrderTick >= NewOrderRate then 
        local newOrder = math.random(1, 2) == 1 and "Onion Soup" or "Tomato Soup"
        table.insert(IncomingOrders, newOrder)
        LastOrderTick = Now
        print("New order: " .. newOrder)
    end
    if CookingPot.status == "Cooking" or CookingPot.status == "Ready" then
        if CookingPot.timer + 60000 < Now and CookingPot.timer + (60000 * 3) > Now then
            CookingPot.status = "Ready"
            print("CookingPot " .. CookingPot.item .. " Soup Ready")
        elseif CookingPot.timer + (60000 * 3) <= Now then
            CookingPot.status = "On Fire"
            print("CookingPot " .. CookingPot.item .. " Soup's On Fire!!!!")
            GameMode = "GameOver"
            endGame()
        else
            print("Soup's still cookin'")
        end
    end
end

-- Handlers
Handlers.add("PlayerMove", Handlers.utils.hasMatchingTag("Action", "PlayerMove"), move)
Handlers.add("PlayerGrab", Handlers.utils.hasMatchingTag("Action", "PlayerGrab"), grab)
Handlers.add("PlayerDrop", Handlers.utils.hasMatchingTag("Action", "PlayerDrop"), drop)
Handlers.add("PlayerChop", Handlers.utils.hasMatchingTag("Action", "PlayerChop"), chop)
