--    Name : Nav
--  Author : Matthew (FaceInCake) Eppel
--    Date : March 3, 2021
-- Version : 1.0
-- Should work on any ComputerCraft version
-- Contains functions for navigating the turtle
-- and remembering where it is

if turtle == nil then
    error("API can only be loaded on turtles", 2)
end

-- In case there's another API called Nav
TurtleHurtle = true

-- Direction macros
NORTH = 1
EAST  = 2
SOUTH = 3
WEST  = 4
UP    = 5
DOWN  = 6

-- Turtle's position
tx = 0
ty = 0
tz = 0 -- z-forward
tf = 1 -- Turtle's facing direction

-- Returns a table of the turtle's current position
function getPos () return {x=tx, y=ty, z=tz, f=tf} end

-- Returns a string representation of the given coord
function str (x, y, z) return ""..x..","..y..","..z end

-- Returns a string representation of the given coord plus a direction
function str_f (x, y, z, f) return ""..x..","..y..","..z..";"..f end

-- Returns a list of numbers contained within a single string
function pos (str)
    local ar = {}
    local i = 1
    for s in string.gmatch(coordStr, "-?%d+") do
        ar[i] = tonumber(s)
        i = i + 1
    end
    return {x=ar[1], y=ar[2], z=ar[3]}
end

-- Returns `x, y, z, f` encoded in the given binary string
function pos_f (str)
    local ar = {}
    local i = 1
    for s in string.gmatch(coordStr, "-?%d+") do
        ar[i] = tonumber(s)
        i = i + 1
    end
    return {x=ar[1], y=ar[2], z=ar[3], f=ar[4]}
end

-- Resets known position of turtle to these values
function setPos (newX, newY, newZ, newFace)
    tx = newX and math.floor(newX) or 0
    ty = newY and math.floor(newY) or 0
    tz = newZ and math.floor(newZ) or 0
    tf = newFace and newFace>=0 and newFace<5 and newFace or Nav.NORTH
end

-- Turns right and updates the current face
function turnRight ()
    while not turtle.turnRight() do end
    tf = tf % 4 + 1
end

-- Turns left and updates the current face
function turnLeft ()
    while not turtle.turnLeft() do end
    if tf<=1 then tf = 4
    else tf = tf - 1 end
end

-- Does a 180 and updates the current face
function turn180 ()
    while not turtle.turnRight() do end
    while not turtle.turnRight() do end
    tf = tf + 2
    if tf > 4 then tf = tf - 4 end
end

local function voidFunc () return end

local turnToLUT = {
    voidFunc, -- facing north, need to face north
    Nav.turnLeft, -- facing east,  need to face north
    Nav.turn180,  -- facing south, need to face north
    Nav.turnRight,-- facing west,  need to face north
    Nav.turnRight,-- facing north, need to face east
    voidFunc, -- facing east,  need to face east
    Nav.turnLeft, -- facing south, need to face east
    Nav.turn180,  -- facing west,  need to face east
    Nav.turn180,  -- facing north, need to face south
    Nav.turnRight,-- facing east,  need to face south
    voidFunc, -- facing south, need to face south
    Nav.turnLeft, -- facing west,  need to face south
    Nav.turnLeft, -- facing north, need to face west
    Nav.turn180,  -- facing east,  need to face west
    Nav.turnRight,-- facing south, need to face west
    voidFunc  -- facing west,  need to face west
}

-- Turns to face `to` from current face
function turnTo (to)
    if to==nil then return error("No direction given") end
    if to<=0 or to>4 then return error("Given direction is out of range: ("..to..")") end
    local case = (to-1)*4 + tf
    turnToLUT[case]()
end

local incrementLUT = {
    function(x,y,z,d) return x,y,z+d end, -- NORTH
    function(x,y,z,d) return x+d,y,z end, -- EAST
    function(x,y,z,d) return x,y,z-d end, -- SOUTH
    function(x,y,z,d) return x-d,y,z end, -- WEST
    function(x,y,z,d) return x,y+d,z end, -- UP
    function(x,y,z,d) return x,y-d,z end  -- DOWN
}

-- Returns x y z incremented by d in direction f
local function incrementPos (d)
    tx, ty, tz = incrementLUT[tf](tx,ty,tz,d)
end

-- Increments x y z by d in the direction f
function increment (x,y,z,f,d)
    return incrementLUT[f or tf](x or 0, y or 0, z or 0, d or 1)
end

-- Moves forward and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
-- Only returns once it moves
function forward ()
    while not turtle.forward() do
        if turtle.detect() then
            return false
        end
    end
    incrementPos(1)
    return true
end

-- Attempts to move backwards and update location
-- Returns false it if wasn't able to, (player or block in the way)
-- Immediately returns, unlike 'forward()', which you should use instead
function backward ()
    if turtle.back() then
        incrementPos(-1)
        return true
    end
    return false
end

-- Moves upwards and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
local function up ()
    while not turtle.up() do
        if turtle.detectUp() then
            return false
        end
    end
    ty = ty + 1
    return true
end

-- Moves downwards and updates location
-- Returns true if successfully moved
-- Returns false if there's a block in the way
local function down ()
    while not turtle.down() do
        if turtle.detectDown() then
            return false
        end
    end
    ty = ty - 1
    return true
end
