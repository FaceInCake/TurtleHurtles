--    Name : NavTester
--  Author : FaceInCake
--    Date : Oct 13, 2021
-- Version : 1.0.0
-- Make sure to clear the area around the turtle.
-- The 3x3x3 area centered around the turtle should be air

io.write([[
Make sure the 3x3x3 area centered around the turtle is air before continuing.
Press Enter to continue...
]])
io.read()

if Nav==nil or Nav.TurtleHurtles==nil then
    os.loadAPI("TurtleHurtles/Nav")
end

------------------
--  UNIT TESTS  --
------------------

-- Turtle's current position should default to 0,0,0, facing north
assert(Nav.tx==0, "Turtle x position wasn't 0")
assert(Nav.ty==0, "Turtle y position wasn't 0")
assert(Nav.tz==0, "Turtle z position wasn't 0")
assert(Nav.tf==Nav.NORTH, "Turtle facing direction wasn't north")
local p = Nav.getPos()
assert(p.x==0 and p.y==0 and p.z==0 and p.f==Nav.NORTH, "Failed to getPos")

-- Test those utility functions
assert(Nav.str(p.x, p.y, p.z)=="0,0,0", "Failed to turn a position into a string")
assert(Nav.str_f(p.x,p.y,p.z,p.f)=="0,0,0;1", "Failed to turn a position+direction into a string")
do
    local x, y, z, f = Nav.pos("1,2,3;4")
    assert(x==1 and y==2 and z==3 and f==4, "Failed to convert string to position")
end

-- Try setting position
Nav.setPos(1, 2, 3, Nav.EAST)
assert(Nav.getX()==1, "Failed to set turtle x position")
assert(Nav.getY()==2, "Failed to set turtle y position")
assert(Nav.getZ()==2, "Failed to set turtle z position")
assert(Nav.getF()==Nav.EAST, "Failed to set turtle facing direction")

-- Try moving forward
while not Nav.forward() do
    assert(Nav.getX()==1, "Not moving forward changed position")
end
assert(Nav.getX()==2, "Failed to move forward")

-- Try moving backward
while not Nav.backward() do
    assert(Nav.getX()==2, "Not moving backward changed position")
end
assert(Nav.getX()==1, "Failed to move backward")

-- Try turning right
Nav.turnRight()
assert(Nav.getF()==Nav.SOUTH, "Failed to turn right")

-- Try doing a 180
Nav.turn180()
assert(Nav.getF()==Nav.NORTH, "Failed to do a 180")

-- Try turning left
Nav.turnLeft()
assert(Nav.getF()==Nav.WEST, "Failed to turn left")



-- Try turnTo(north)
Nav.turnTo(Nav.NORTH)
assert(Nav.getF()==Nav.NORTH, "Failed to face north")

-- Check correct movement cancelling
while not Nav.forward() do end
Nav.backward()
assert(Nav)

-------------------------
--  INTEGRATION TESTS  --
-------------------------

Nav.turnTo(Nav.EAST)
Nav.forward()
Nav.backward()

Nav.turnTo(Nav.WEST)
Nav.forward()
Nav.backward()

Nav.turnTo(Nav.SOUTH)
Nav.forward()
Nav.backward()

Nav.up()
Nav.down()

print("Succeeded the tests!")
