--                  Name : HurtleJumper
--                Author : Matthew (FaceInCake) Eppel
--                  Date : Oct 14, 2021
--               Version : 0.9.0
-- ComputerCraft Version : 1.4
-- Program for more easily installing and using TurtleHurtle programs
-- Check the README of the repo for how to install the installer

-- Should be able to install new APIs / programs
-- Should be able to view available APIs / programs
-- Should be able to execute installed programs

if keys == nil then -- keys weere introduced in version 1.4
    error("You atleast need computercraft version 1.4 for the base installer to work")
end

local basedir = "TurtleHurtles/"

-- Function for creating folder structure, called when accessing a file fails
local function __createFolder(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end
local function createFolderStructure()
    __createFolder(basedir)
    __createFolder(basedir.."apis")
    __createFolder(basedir.."programs")
    __createFolder(basedir.."tests")
end

local baseurl = "https://github.com/FaceInCake/TurtleHurtles/tree/main/src/"

-- Function to download AVAILABLE apis/programs
local function downloadPossible (t, subDir)
    local res = http.get(baseurl..subDir)
    if res == nil then
        print("Failed to download available",subDir,": Couldn't connect")
        return false
    end
    if res:getResponseCode()~=200 then
        print("Failed to download available",subDir,": Error",res:getResponseCode())
        res:close()
        return false
    end
    local line = res:readLine()
    while line ~= nil do
        local m = line:gmatch(">([a-zA-Z0-9_]+)\.lua<")()
        if m ~= nil then t[m] = subDir end
        line = res:readLine()
    end
    res:close()
    return true
end

-- Function for loading the api/program list
local function getList (dir)
    if not fs.exists(dir) then
        createFolderStructure()
    end
    local l = fs.list(dir)
    local r = {}
    for i=1, #l do
        if l[i]:sub(-4)==".lua" then
            r[l[i]:sub(1,-5)]=true
        end
    end
    return r
end

-- Attempt to read in the currently installed APIs
local installedAPIs = getList(basedir.."apis/")
local installedPrograms = getList(basedir.."programs/")
local installedTesters = getList(basedir.."tests")
local possible = {}

-- Function for fetching all available APIs/programs/tests
local function refreshPossible ()
    if downloadPossible(possible, "apis") then
        if downloadPossible(possible, "programs") then
            if downloadPossible(possible, "tests") then
                return true
            end
        end
    end
    return false
end

-- Boolean for continuing or stopping the main loop
local keepRunning = true

-- LUT for listing files of a certain type
local listLUT = {
    ["apis"] = function ()
        for k, _ in pairs(installedAPIs) do
            print("  >",k)
        end
    end,
    ["programs"] = function ()
        for k, _ in pairs(installedPrograms) do
            print("  >",k)
        end
    end,
    ["tests"] = function ()
        for k, _ in pairs(installedTesters) do
            print("  >",k)
        end
    end
}

local function getHelp ()
    print(":= [install] [run] [list] [help] [exit]")
    return true
end

-- LUT of functions for enacting instructions
local actLUT = {
    ["install"] = function (arg)
        if arg==nil then
            print("Usage: install <apiName/programName>")
            return false
        end
        if arg:match("[a-zA-Z0-9_]+")==nil then
            print("ERR: Please pass a file NAME")
            return false
        end
        local type = possible[arg]
        if type == nil then
            print("ERR: Sorry I don't see that file")
            return false
        end
        local res = http.get(baseurl..type.."/"..arg..".lua")
        if res == nil then
            print("ERR: Failed to connect or something")
            return false
        end
        if res:getResponseCode()~=200  then
            print("ERR: Failed to download page:",res:getResponseCode())
            return false
        end
        local f = fs.open(basedir..type.."/"..arg..".lua", "w")
        if f == nil then
            print("ERR: Failed to create the new file")
            return false
        end
        f.write(res:readAll()) -- must be f.write, not f:write
        f:flush()
        f:close()
        res:close()
        return true
    end,
    ["list"] = function (type)
        if type == nil then
            print("Usage: list <'apis'/'programs'/'tests'>")
            return false
        end
        local f = listLUT[type]
        if f == nil then
            print("ERR: Options are 'apis', 'programs', or 'tests'")
            return false
        end
        f()
        return true
    end,
    ["run"] = function (ar)
        if ar==nil then
            print("Usage: run <programName>")
            return false
        end
        local argGetter = ar:gmatch("([a-zA-Z0-9_]+) +|$|\n")
        local programName = argGetter()
        if installedPrograms[programName] or installedTesters[programName] then
            local ars = {} -- Arguments to be passed to the program
            local arsl = 0 -- Number of arguments for above
            repeat
                ars[arsl+1] = argGetter()
                arsl = arsl + 1
            until ars[arsl]==nil
            if shell.run(programName, unpack(ars)) then
                keepRunning = false
                return true
            end
            print("ERR: Failed to run that program")
            return false
        end
        print("ERR: Sorry, I don't recognize that program.")
        return false
    end,
    ["help"] = getHelp,
    ["exit"] = function (_)
        keepRunning = false
        return true
    end
}

local function getInput()
    local s = io.read():lower()
    local m = s:find(" ", 4, true)
    if m == nil then return s end
    local a = s:sub(m+1, -1)
    local s = s:sub(1, m-1)
    return s, a
end

-- Main Loop
print("- - = = TurtleHurtles: MainMenu = = - -")
getHelp() -- You need it, you sick FUGSDHRGI
while keepRunning do
    io.write("TH> ")
    local operation, arguments = getInput()
    if operation~=nil then
        local action = actLUT[operation]
        if action ~= nil then
            action(argument)
        end
    end
end
