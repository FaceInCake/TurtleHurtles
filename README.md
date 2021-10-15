# TurtleHurtles
This is a library of APIs, programs, and tester programs. For the Minecraft mod _ComputerCraft_.

The goal of this library is to make it easy to download and run other programs, or download and install other APIs, just by knowing their name.

## Installation
Open your computer/turtle and type `lua`. Then copy and paste the following code...

`f=fs.open("HurtleJumper.lua","w");f.write(http.get("https://raw.githubusercontent.com/FaceInCake/TurtleHurtles/main/HurtleJumper.lua"):readAll());f:flush();f:close();exit()`

This code attempts to download the HurtleJumper.lua file and place it in your computer/turtle's root directory. You can then run this program to interact with everything else, as described in [this section](#hurtlejumper).

## HurtleJumper

This is the main program that you can run in order to install and run all other APIs/programs.
As of now, you use it by calling the appropriate commands and passing in the appropriate arguments:
`install`, `run`, `list`, `help`, and `exit`.

### install

Simply pass in the name of the program, API, or tester you want to download.
This is the name of the file without the extension.

Ex. `install Nav` <br>
Will attempt to install the program, api, or tester named 'Nav'.

### run

Pass in the name of the program or tester you want to run.
It must be downloaded on your turtle.

Ex. `run Forward 30` <br>
Will run the program named 'Forward', passing in the argument '30'.

### list

Pass in either `apis`, `programs`, or `tests`. It will print out all files of that type that are downloaded onto the the device. If a program is not on this list, the device cannot run that program.

Ex. `list programs` <br>
Will list all programs that are on the computer/turtle.

### help

Displays the basic help. Which just tells you wish commands you can use.

### exit

ByeBye
