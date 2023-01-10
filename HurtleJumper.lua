--                  Name : HurtleJumper
--                Author : Matthew (FaceInCake) Eppel
--                  Date : Oct 14, 2021
--               Version : 1.0.0
-- ComputerCraft Version : 1.4
-- Program for more easily installing and using TurtleHurtle programs
-- Check the README of the repo for how to install the installer

-- Should be able to install new APIs / programs
-- Should be able to view available APIs / programs
-- Should be able to execute installed programs

if keys == nil then -- keys were introduced in version 1.4
    error("You atleast need computercraft version 1.4 for the base installer to work")
end

local basedir = "TurtleHurtles" -- Local directory to store everything besides this file
local branch = "main" -- GitHub branch to pull from, you can change this when tesing/debugging
local baseUrl = "https://github.com/FaceInCake/TurtleHurtles/tree/"
local baseRawUrl = "https://raw.githubusercontent.com/FaceInCake/TurtleHurtles/"

-- Following two functions build paths, using the given parameters
local function getLocalDir (type)
    return basedir.."/"..branch.."/"..(type and type.."/" or "")
end
local function getRemoteUrl (type, raw)
    if raw == true then
        return baseRawUrl..branch.."/src/"..(type and type.."/" or "")
    else
        return baseUrl..branch.."/src/"..(type and type.."/" or "")
    end
end

-- [name] = [type]
local possible = {}

-- Helper function to download list of apis/programs that are available from GitHub
local function __downloadPossible (listOut, subDir)
    -- TODO: Use Dependencies.txt file
    local res = http.get(getRemoteUrl(subDir, false))
    if res == nil then
        print("Failed to download available",subDir,": Couldn't connect")
        return false
    end
    if res:getResponseCode()~=200 then
        print("Failed to download available",subDir,": Error",res:getResponseCode())
        res:close()
        return false
    end
    local line = res.readLine()
    while line ~= nil do
        local m = line:gmatch(">([a-zA-Z0-9_]+)\.lua<")()
        if m ~= nil then listOut[m] = subDir end
        line = res.readLine()
    end
    res:close()
    return true
end

-- Function for fetching all available APIs/programs/tests
local function downloadPossible ()
    if __downloadPossible(possible, "apis") then
        if __downloadPossible(possible, "programs") then
            if __downloadPossible(possible, "tests") then
                return true
            end
        end
    end
    return false
end

-- [name] => true
local installedAPIs = {}
local installedPrograms = {}
local installedTesters = {}

-- Helper function for loading the api/program list
local function __getInstalled (listOut, dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
        return true -- Empty, but still valid
    end
    local l = fs.list(dir)
    listOut = {}
    for i=1, #l do
        if l[i]:sub(-4)==".lua" then
            listOut[l[i]:sub(1,-5)]=true
        end
    end
    return true
end

-- Function for loading the api/program list
local function getInstalled ()
    -- cannot error but just in case `\_('-')_/`
    if __getInstalled(installedAPIs, getLocalDir("apis")) then
        if __getInstalled(installedPrograms, getLocalDir("programs")) then
            if __getInstalled(installedTesters, getLocalDir("tests")) then
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
            print(" -",k)
        end
    end,
    ["programs"] = function ()
        for k, _ in pairs(installedPrograms) do
            print(" -",k)
        end
    end,
    ["tests"] = function ()
        for k, _ in pairs(installedTesters) do
            print(" -",k)
        end
    end
}

-- LUT for the usage documentation of the given command string. Use the below function
local usageLUT = {
    ["install"] = "<apiName/programName>",
    ["list"] = "<'apis'/'programs'/'tests'>",
    ["run"] = "<programName>",
    ["available"] = "['apis'/'programs'/'test']",
    ["help"] = "[command]",
    ["refresh"] = "",
    ["branch"] = "<name>"
}
-- Function for printing the 'usage' documentation for the given command string
local function printUsage (cmd)
    local s = usageLUT[cmd]
    if s == nil then
        print("No usage doc found")
    else
        print("Usage: "..cmd.." "..s)
    end
end

-- LUT for the help message for each command/topic/whatever
local helpLUT = {
    ["help"] = "You're using it right now, you got the hang if it.",
    ["exit"] = "Quits the program, exits, leaves, says goodbye, dies.",
    ["list"] = "Lists all installed files of the given type.",
    ["run"] = "Executes the given program, runs it, activates, goes, does thing.",
    ["install"] = "Attempts to install the api/program of the given name",
    ["available"] = "Lists all files that are available online for download of the given type, will list every file if no type is given.",
    ["refresh"] = "Re-fetches all online files available for download.",
    ["branch"] = "Changes the remote branch to fetch from, used if you're developing new code. Default is 'main'."
}

-- LUT of functions for enacting instructions
local actLUT = {
    ["install"] = function (ar)
        if ar==nil then
            printUsage("install")
            return false
        end
        if ar:match("[a-zA-Z0-9_]+")==nil then
            print("ERR: Please pass a file NAME")
            return false
        end
        local type = possible[ar]
        if type == nil then
            print("ERR: Sorry I don't see that file")
            return false
        end
        local res = http.get(getRemoteUrl(type, true)..ar..".lua")
        if res == nil then
            print("ERR: Failed to connect or something")
            return false
        end
        if res:getResponseCode()~=200  then
            print("ERR: Failed to download page:",res:getResponseCode())
            return false
        end
        local d = getLocalDir(type)
        if not fs.exists(d) then fs.makeDir(d) end
        local f = fs.open(d..ar..".lua", "w")
        if f == nil then
            print("ERR: Failed to create the new file")
            return false
        end
        f.write(res:readAll()) -- must be f.write, not f:write
        f:flush()
        f:close()
        res:close()
        getInstalled()
        return true
    end,
    ["list"] = function (type)
        if type == nil then
            printUsage("list")
            return false
        end
        local f = listLUT[type]
        if f == nil then
            print("ERR: Options are 'apis', 'programs', or 'tests'")
            printUsage("list")
            return false
        end
        f()
        return true
    end,
    ["run"] = function (ar)
        if ar==nil then
            printUsage("run")
            return false
        end
        local argGetter = ar:gmatch(" *([a-zA-Z0-9_]+)")
        local programName = argGetter()
        if installedPrograms[programName] or installedTesters[programName] then
            local ars = {} -- Arguments to be passed to the program
            local arsl = 0 -- Number of arguments for above
            repeat
                ars[arsl+1] = argGetter()
                arsl = arsl + 1
            until ars[arsl]==nil
            local path = getLocalDir("programs")..programName..".lua"
            if not fs.exists(path) then
                path = getLocalDir("tests")..programName..".lua"
            end
            return shell.run(path, unpack(ars))
        end
        print("ERR: Sorry, I don't recognize that program.")
        printUsage("run")
        return false
    end,
    ["available"] = function (ar)
        if ar == nil then
            for k,v in pairs(possible) do
                print(" -", v, ":", k)
            end
        else
            for k,v in pairs(possible) do
                if v == ar then
                    print(" -", k)
                end
            end
        end
    end,
    ["refresh"] = function ()
        if downloadPossible() then
            print("Successfuly fetched available downloads")
        else
            print("Failed to fetch available downloads")
        end
    end,
    ["branch"] = function (ar)
        if ar ~= nil and ar ~= "" then
            branch = ar
            getInstalled()
            print("Set branch to", ar)
        else
            printUsage("branch")
        end
    end,
    ["help"] = function (ar)
        if ar == nil then
            printUsage("help")
            print("Available commands:")
            print("[help] [exit] [run] [list] [install]")
            print("[available] [refresh] [branch]")
            print("")
            return true
        end
        local s = helpLUT[ar]
        if s ~= nil then
            printUsage(ar)
            print(s)
        end
    end,
    ["exit"] = function (_)
        keepRunning = false
        return true
    end
}

local function getInput()
    local s = io.read()
    local m = s:find(" ", 4, true)
    if m == nil then return s end
    local a = s:sub(m+1, -1)
    local s = s:sub(1, m-1)
    return s, a
end

local function main ()
    if not downloadPossible() then
        print("ERR: Failed to download available APIs/programs")
    end
    getInstalled()
    print("- - = = TurtleHurtles: MainMenu = = - -")
    while keepRunning do
        io.write("TH> ")
        local operation, arguments = getInput()
        if operation~=nil then
            local action = actLUT[operation]
            if action ~= nil then
                action(arguments)
            end
        end
    end
end

-- Time to do it!
main()
