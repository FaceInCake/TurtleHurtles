--                  Name : Stone Stripper
--                Author : Matthew (FaceInCake) Eppel
--                  Date : Feb 18, 2020
--               Version : 0.5.5
-- ComputerCraft Version : 1.80
--                 Build : Works for most situations, needs some look-ahead
--                  Desc : Clears a specified area of all non-ores


-- How To Use:
-- This help can also be accessed by typing 'StoneStripper help', or whatever you named the file
-- It will ask you for the dimensions using standard input
-- or, you can specify the dimensions using the args: 'w=123', 'h=123', or 'd=123'
-- w : width, h : height, d : depth of area relative to turtle's forward face direction
-- The turtle starts facing forwards, towards the first bottom-left block

-- TODO: Turtle won't mine an area that it doesn't have the fuel for
-- TODO: Turtle will place torches such that no block has a light level <= 7
-- TODO: Turtle will dump it's inventory when full
-- TODO: Will check if can fit flint in inventory when mining gravel
-- TODO: Turtle will remember blocks it failed to reach and try again later

local args = {...}
local area = {width=0, height=0, depth=0} -- Dimensions of the area to clear out
local knownOres = {} -- Table for remembering encountered ores: "x,y,z" -> true
local toComeBackTo = {} -- Table for remembering blocks we failed to reach before "x,y,z"->true
local curTarget = {x=0, y=0, z=0} -- To keep track how much of the area we've cleared
-- Macros for directions
local NORTH = 1 -- +Z, forwards, starting direction
local EAST = 2  -- +X, right
local SOUTH = 3 -- -Z, backwards
local WEST = 4  -- -X, left
local UP = 5    -- +Y
local DOWN = 6  -- -Y
local DIRS = { "NORTH", "EAST", "SOUTH", "WEST", "UP", "DOWN" }
-- To keep track of turtle's position, relative to start
local turtlePos = {x=0, y=0, z=-1}
local face = NORTH    -- The current direction the turtle is facing

--------------------------------------------------------
--  Code to validate area dimensions from user input  --
--------------------------------------------------------

-- Parse each arg
for i, v in ipairs(args) do
    if v == "-h" or v == "--help" or v == "help" then
        textutils.slowPrint([[
How To Use:
It will ask you for the dimensions using standard input
or, you can specify the dimensions using the args: 'w=123', 'h=123', or 'd=123'
w is width, h is height, and d is depth of area relative to turtle's forward face direction
The turtle starts facing forwards, towards the first bottom-left block
]]      )
        return
    end
    if string.sub(v, 2, 2) == "=" then
        local num = tonumber(string.sub(v, 3, -1))
        if num or num <= 0 then
            if     string.sub(v,1,1) == "w" then
                area.width = num
            elseif string.sub(v,1,1) == "h" then
                area.height = num
            elseif string.sub(v,1,1) == "d" then
                area.depth = num
            else
                printError("Invalid parameter: '"..v.."'")
                printError("Usage: 'w=123', 'h=123', or 'd=123'")
            end
        else
            printError("Invalid value: '"..v.."'")
            printError("Usage: 'w=123', 'h=123', or 'd=123'")
        end
    end
end

-- Ask user for dimensions if not already supplied
for key, v in pairs(area) do
    while v <= 0 do
        print("Please input the "..key.." of the area to mine")
        io.write("> ")
        local s = io.read()
        local n = tonumber(s)
        if n and n>0 then
            area[key] = n
            break
        else
            printError("Nan or negative value given")
        end
    end
end

----------------------------------------------------------------
--  Functions for detecting whether a block is an ore or not  --
----------------------------------------------------------------

local BLOCK_WHITELIST = {
    ["minecraft:stone"]=true,
    ["minecraft:cobblestone"]=true,
    ["minecraft:dirt"]=true,
    ["minecraft:gravel"]=true,
    ["chisel:basalt2"]=true,
    ["chisel:marble2"]=true
}

local function __isNonOre (inspectF)
    success, data = inspectF()
    if success==false then return "air" end
    if BLOCK_WHITELIST[data.name] then
        if data.state.variant == "stone" then
            return "minecraft:cobblestone"
        end
        return data.name
    end
    return "ore"
end

-- Inspects a block in front/above/below to see if it's a non-ore
-- Returns the block name if the block is a non-ore
-- Returns "ore" if the block is NOT a non-ore
-- Returns "air" if there's no block
local function isNonOre () return __isNonOre(turtle.inspect) end
local function isNonOreUp () return __isNonOre(turtle.inspectUp) end
local function isNonOreDown () return __isNonOre(turtle.inspectDown) end

---------------------------------------------------------------------------
--  Function for detecting whether a block will fit in inventory or not  --
---------------------------------------------------------------------------

-- Checks if the given block will fit in inventory if mined
-- `blockName`:string is the game name of the block, (ex. minecraft:stone)
-- Returns true if the block will fit into inventory if mined, false on error
local function willFit (blockName)
    if blockName==nil then return error("No blockName given") end
    if blockName=="air" then return true end
    if blockName=="ore" then return false end
    for i=1, 16 do
        if  turtle.getItemCount(i) == 0
        or  turtle.getItemDetail(i).name == blockName
        and turtle.getItemSpace(i) > 0
        then return true end
    end
    return false
end

-------------------------------------------------------------
--  Functions for attempting to a mine block if it should  --
-------------------------------------------------------------

local function __strip (isNonOreF, digF, detectF)
    repeat -- Loop in case of sand/gravel
        local blockName = isNonOreF()
        if blockName == "ore" then return "ore" end
        if blockName == "air" then return "air" end
        if not willFit(blockName) then return "full" end
        while not digF() do end
    until not detectF()
    return "dug"
end

-- Attempt to mine a block, as long as it will fit in inventory and it's a non-ore
-- Returns `msg`:string, which can be: "ore", "air", "dug", "full"
local function strip () return __strip(isNonOre, turtle.dig, turtle.detect) end
local function stripUp () return __strip(isNonOreUp, turtle.digUp, turtle.detectUp) end
local function stripDown () return __strip(isNonOreDown, turtle.digDown, turtle.detectDown) end

----------------------------------------------------
--  Personalized functions for moving the turtle  --
----------------------------------------------------

-- Helper LUT for `increment()`
local dirLUT = {
    function(p,d) return { x = p.x, y = p.y, z = p.z + d } end, -- NORTH
    function(p,d) return { x = p.x + d, y = p.y, z = p.z } end, -- EAST
    function(p,d) return { x = p.x, y = p.y, z = p.z - d } end, -- SOUTH
    function(p,d) return { x = p.x - d, y = p.y, z = p.z } end, -- WEST
    function(p,d) return { x = p.x, y = p.y + d, z = p.z } end, -- UP
    function(p,d) return { x = p.x, y = p.y - d, z = p.z } end  -- DOWN
}

-- Returns a new coord incremented with respect to a given direction
-- `pos` is the starting coordinate
-- `dir` is the direction macro
-- `dist` is the amount to increment by, defaults to 1
-- Returns a the new resultant coord
function increment (pos, dir, dist)
    if dir<=0 or dir>6 then return error("Given dir is out of range: ("..dir..")") end
    if dist==nil then dist=1 end
    return dirLUT[dir](pos,dist)
end

-- Turns right and updates the current face
local function turnRight ()
    while not turtle.turnRight() do end
    if face==4 then face = 1
    else face = face + 1 end
end

-- Turns left and updates the current face
local function turnLeft ()
    while not turtle.turnLeft() do end
    if face==1 then face = 4
    else face = face - 1 end
end

-- Does a 180 and updates the current face
local function turn180 ()
    while not turtle.turnRight() do end
    while not turtle.turnRight() do end
    face = face + 2
    if face > 4 then face = face - 4 end
end

-- Moves forward and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
local function moveForward()
    while not turtle.forward() do
        if turtle.detect() then
            return false
        end
    end
    turtlePos = increment(turtlePos, face, 1)
    return true
end

-- Moves upwards and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
local function moveUp ()
    while not turtle.up() do
        if turtle.detectUp() then
            return false
        end
    end
    turtlePos.y = turtlePos.y + 1
    return true
end

-- Moves downwards and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
local function moveDown ()
    while not turtle.down() do
        if turtle.detectDown() then
            return false
        end
    end
    turtlePos.y = turtlePos.y - 1
    return true
end

-- Function that returns
local function voidFunc () return end

-- Turns to face `to` from current face
local function turnTo (to)
    if to==nil then return error("No direction given") end
    if to<=0 or to>4 then return error("Given direction is out of range: ("..to..")") end
    local case = face + (to-1)*4
    local TurnLUT = {
        voidFunc, -- facing north, need to face north
        turnLeft, -- facing east,  need to face north
        turn180,  -- facing south, need to face north
        turnRight,-- facing west,  need to face north
        turnRight,-- facing north, need to face east
        voidFunc, -- facing east,  need to face east
        turnLeft, -- facing south, need to face east
        turn180,  -- facing west,  need to face east
        turn180,  -- facing north, need to face south
        turnRight,-- facing east,  need to face south
        voidFunc, -- facing south, need to face south
        turnLeft, -- facing west,  need to face south
        turnLeft, -- facing north, need to face west
        turn180,  -- facing east,  need to face west
        turnRight,-- facing south, need to face west
        voidFunc  -- facing west,  need to face west
    }
    TurnLUT[case]()
    return true
end

------------------------------------
--        A Star algorithm        --
------------------------------------

-- String representation a coordinate
local function str (pos) return (""..pos.x..","..pos.y..","..pos.z) end

-- Takes a coord string "x,y,z" and returns the numbers x, y, z
local function str2coord (coordStr)
    local ar = {}
    local i = 1
    for s in string.gmatch(coordStr, "-?%d+") do
        ar[i] = tonumber(s)
        i = i + 1
    end
    return {x=ar[1], y=ar[2], z=ar[3]}
end

-- Returns the directional difference, or 0 if there's no difference 
local function getDifference (p0, p1)
    if p1.x > p0.x then return EAST  end
    if p1.x < p0.x then return WEST  end
    if p1.y > p0.y then return UP    end
    if p1.y < p0.y then return DOWN  end
    if p1.z > p0.z then return NORTH end
    if p1.z < p0.z then return SOUTH end
    return 0
end

-- Returns an array of all neighbor coords to coord string `coordStr`
local function getNeighbors (p)
    if type(p)=="string" then
        p = str2coord(p)
    end
    local ar = {}
    ar[1] = {x=p.x, y=p.y, z=p.z+1} -- NORTH
    ar[2] = {x=p.x+1, y=p.y, z=p.z} -- EAST
    ar[3] = {x=p.x, y=p.y, z=p.z-1} -- SOUTH
    ar[4] = {x=p.x-1, y=p.y, z=p.z} -- WEST
    ar[5] = {x=p.x, y=p.y+1, z=p.z} -- UP
    ar[6] = {x=p.x, y=p.y-1, z=p.z} -- DOWN
    return ar
end

-- Checks if coord is in cleared mining area
local function isInRange(p)
    if p.x<0 or p.y<0 or p.z<0 then return false end
    if p.x<area.width and p.y<area.height and p.z<area.depth then
        return true
    end
    return false
end

-- Returns an array of actions from a sort of backwards induction table and end goal
-- `cameFrom` is a table where a coord key results in the coord that was previous to that coord, ["x1,y1,z1"] -> "x0,y0,z0"
-- `goalS` is the string repr. of the end coord to start the induction with
-- Returns an array of actions, represented as string, { "east", "forward", "up", north" }
local function reconstructPath (cameFrom, goalS)
    -- Compile the path taken, though it's backwards
    local coords = {} -- backwards array of coords, coords[1]=goal, coords[#]=start
    local i = 1
    coords[i] = goalS
    local node = cameFrom[goalS]
    while node ~= nil do
        i = i + 1
        coords[i] = node
        node = cameFrom[node]
    end
--    for j=i, 1, -1 do
--        print("@"..(i-j+1), coords[j])
--    end
    -- Turn our coord path into actions
    local actions = {}
    local curFace = face
    local k = 1
    -- Helper function for the loop, checks to turn and moves
    local function moveDir (dir)
        if curFace ~= dir then
            actions[k] = DIRS[dir]
            curFace = dir
            k = k + 1
        end
        actions[k] = "FORWARD"
        k = k + 1
    end
    -- Helper function-LUT for the loop, calls the appropriate function
    local ActLUT = {
        moveDir, moveDir,-- N E
        moveDir, moveDir,-- S W
        function()
            actions[k] = "UP"
            k = k + 1
        end,
        function()
            actions[k] = "DOWN"
            k = k + 1
        end
    }   
    -- go throughout the coords and turn'em into actions, from start-to-goal
    for j=i, 2, -1 do
        local case = getDifference(
            str2coord(coords[j]),
            str2coord(coords[j-1])
        )
        ActLUT[case](case)
    end
    return actions
end

-- Shortest-path finding algorithm
-- `goals` is an array of coords to be considered the goal
-- `goalF` is the optional direction to end facing
-- Returns `success`:boolean, `result`:string/array
-- On success, `success` is true, believe it or not, and `result` is an array of actions to take in order
-- On failure, `success` is false, surprise, and `result` is a string, telling what went wrong
-- On success, `result`:array can be { "EAST", "FORWARD", "WEST", "UP" }, where a cardinal-direction is a direction to turn to
-- Logic taken mostly from the 'A*_search_algorithm' wiki page pseudo code
local function A_Star (goals)

    local startS = str(turtlePos)
    local goalsS = {} -- ["x,y,z"]=true, our goals
    for i,g in ipairs(goals) do
        goalsS[str(g)] = true
    end
    
    -- h is the heuristic function. h estimates the cost to reach the closest goal
    local function __h (p0, p1) return math.abs(p1.x - p0.x) + math.abs(p1.y - p0.y) + math.abs(p1.z - p0.z) end
    local function h (pos)
        local m = math.huge
        for i, v in pairs(goals) do
            local n = __h(pos, v)
            if n < m then m = n end
        end
        return m
    end
    
    -- Coords yet to explore, but discovered
    local openSet = {[startS]=true}
    
    -- Stores the coord immediately preceding another, on the cheapest path
    -- cameFrom["x,y,z"] -> "x,y,z"
    local cameFrom  = {}
    
    -- Resultant facing direction at this coord
    -- So if turtle moved from cameFrom[key] to key, it would be facing resFace[key]
    -- resFace["x,y,z"] -> NORTH/EAST/SOUTH/WEST
    local resFace = {[startS]=face}
    
    -- gScore["x,y,z"] is the cost of the cheapest path from start to "x,y,z" currently known.
    local gScore = {[startS]=0}

    -- fScore["x,y,z"] = gScore["x,y,z"] + h("x,y,z"). fScore["x,y,z"] represents our current best guess as to
    -- how short a path from start to finish can be if it goes through "x,y,z"
    local fScore = {[startS] = h(turtlePos)}
    
    local startTime = os.clock()

    local next = next -- Local binding
    local currentS = startS -- Current coord working on as a string key (ie. "x,y,z")
    while currentS ~= nil do
        -- current = coord with the lowest fScore in openSet
        for k, _ in pairs(openSet) do
            if fScore[k] < fScore[currentS] then
                currentS = k
            end
        end
        -- Are we there yet!?
        if goalsS[currentS] then
            return true, reconstructPath(cameFrom, currentS)
        end
        -- We have now explored this coord
        openSet[currentS] = nil
        -- Check each neighbor
        for dir, neighbor in ipairs(getNeighbors(currentS)) do
            local neighborS = str(neighbor)
            if knownOres[neighborS] == nil      -- Make sure it's air there
            and neighborS ~= cameFrom[currentS] -- Make sure were not going backwards
            and isInRange(neighbor) then        -- Make sure we dont leave the area
                local newDir = (dir<5) and dir or resFace[currentS]
                -- n_gScore is the distance from start to the neighbor through current
                local n_gScore = gScore[currentS] + 1 + ((resFace[currentS]==newDir) and 0 or 1)
                if gScore[neighborS]==nil or n_gScore < gScore[neighborS] then
                    -- This path to neighbor is better than any previous one. Record it!
                    resFace[neighborS] = newDir
                    cameFrom[neighborS] = currentS
                    gScore[neighborS] = n_gScore
                    fScore[neighborS] = gScore[neighborS] + h(neighbor)
                    if openSet[neighborS] == nil then
                        openSet[neighborS] = true
                    end
                end
            end
        end
        if os.clock() > startTime + 5.0 then
            return false, "Timed out, unable to find the goal"
        end
        -- Check if openSet is empty
        currentS = next(openSet)
    end
    -- Open set is empty but goal was never reached
    return false, "Exhausted all options trying to find the goal"
end

---------------------------------------------------
--  Functions for navigating to a certain coord  --
---------------------------------------------------

-- Paths to a given coordinate and ends, facing a given direction
-- `p` is the coordinate to go to, origin is the first bottom-left block in our area to mine
-- `f` is an optional direction to face when finished
-- Returns true on success, false on failure
local function navigate(tar)
    -- LUT actions
    local NavLUT = {
        ["FORWARD"] = moveForward,
        ["UP"] = moveUp,
        ["DOWN"] = moveDown,
        ["NORTH"] = function () return turnTo(NORTH) end,
        ["EAST"]  = function () return turnTo(EAST)  end,
        ["SOUTH"] = function () return turnTo(SOUTH) end,
        ["WEST"]  = function () return turnTo(WEST)  end
    }
    -- LUT for direction of movement, has to be a function because `face` can change
    local DirLUT = {
        ["FORWARD"] = function() return face end,
        ["UP"] = function() return UP end,
        ["DOWN"] = function() return DOWN end
    }
    local coords = getNeighbors(tar) -- Goals
    -- helper function, returns true if should loop, false on success, string on failure
    local function attemptNav()
        -- Call upon the mighty
        local success, result = A_Star(coords, f)
        if success then
            -- Carry out the instructions
            for _, act in ipairs(result) do
                local success = NavLUT[act]()
                --print("+",act,"=",success)
                if success == false then
                    local dir = DirLUT[act]()
                    knownOres[str(increment(turtlePos,dir,1))] = true
                    return true
                end
            end
            return false
        else
            return result
        end
    end
    -- loop the nav function until success
    local result = attemptNav()
    while result ~= false do
        if result ~= true then
            printError(result)
            return false
        end
        result = attemptNav()
    end
    -- Final turn to face the block
    local dir = getDifference(turtlePos, tar)
    if dir < 5 then
        NavLUT[DIRS[dir]]()
        return "FORWARD"
    elseif dir==5 then
        return "UP"
    elseif dir==6 then
        return "DOWN"
    end
    return error("Unable to get direction to target")
end

------------------------------------------------------
--  Function for going to and mining a given block  --
------------------------------------------------------

-- Navigates towards given coordinate and mines the block there
-- (x, y, z) is the width/height/depth coord where the origin is the first bottom-left block
-- Returns false if error occurred, true if execution ended normally
local function seekAndDestroy (tar)
    local tarS = str(tar)
    -- Navigate to any block beside the target block
    local result = navigate(tar)
    if result==false then
        printError("Failed to navigate to block.")
        return false
    end
    -- Dig the block using the appropriate function
    local DigLUT = {
        ["FORWARD"] = strip,
        ["UP"] = stripUp,
        ["DOWN"] = stripDown
    }
    local msg = DigLUT[result]() -- "ore", "air", "dug", "full", or "failed"
    if msg == "full" then
        return error("Turtle would dump inv at this point")
    elseif msg == "ore" then
        knownOres[tarS] = true
    elseif msg == "failed" then
        return error("Failed to strip block")
    end
    -- else msg == dug/air
    knownOres[tarS] = nil
    return true
end

-----------------------------
--    Main digging loop    --
-----------------------------

function declareWall (z)
    local pos = {x=0, y=0, ["z"]=z}
    while pos.x < area.width do
        while pos.y < area.height do
            knownOres[str(pos)] = true
            pos.y = pos.y + 1
        end
        pos.x = pos.x + 1
    end
end

local function main ()
    local xStep = 1
    local yStep = 1
    declareWall(0)
    while curTarget.z < area.depth do
        declareWall(curTarget.z+1)
        while curTarget.x >= 0 and curTarget.x < area.width do
            while curTarget.y >= 0 and curTarget.y < area.height do
                print("Targeting:", str(curTarget))
                if seekAndDestroy(curTarget)==false then
                    printError("Failed to seekAndDestroy block")
                end
                curTarget.y = curTarget.y + yStep
            end
            yStep = - yStep
            curTarget.y = curTarget.y + yStep
            curTarget.x = curTarget.x + xStep
        end
        xStep = - xStep
        curTarget.x = curTarget.x + xStep
        curTarget.z = curTarget.z + 1
    end
end

print("Mining an area of:",area.width,",",area.height,",",area.depth)
main()
print("Finished execution :D")


