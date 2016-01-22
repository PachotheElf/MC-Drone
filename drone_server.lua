API = require("buttonAPI")
local event = require("event")
local serial = require("serialization")
local term = require("term")
local colors = require("colors")
local component = require("component")
local gpu = component.gpu
local drone = component.droneInterface
local modem = component.modem

--	PROGRAM STATE
--	0 = main screen
--	1 = 
local state	= 0
local xSide = true
local ySide = true
local zSide = true

local running = true

--	POSITIONS
local serverPos = {232,68,445}
local playerPos = {0,0,0}

--	COMMUNICATIONS
s_address = ""
s_port = 1;

--	DRONE STATUS
local pressure = 0.0;
local position = {0,0,0}
local lastAction = ""

--	DRONE AREAS
local importChestPos = {0,0,0}
local exportChestPos = {0,0,0}
local homePos = {0,0,0}
local workingCenter = {0,0,0}
local workingArea = {0,0,0,0,0,0}
local workingAreaType = "Filled"
local areaTypes = {"Filled", "Frame", "Walls", "Sphere", "Line", "X-Wall", "Y-Wall", "Z-Wall", "X-Cylinder", "Y-Cylinder", "Z-Cylinder", "X-Pyramid", "Y-Pyramid", "Z-Pyramid", "Grid"}
local xDist = 0;
local yDist = 0;
local zDist = 0;

--	FUNCTIONS
function API.fillTable()
	API.setTable("Close", shutdown, 70,80,1,1)
	if(state == 0) then	--	Main screen
		API.setTable("Come here", approachPlayer, 5, 20, 3, 3)
		API.setTable("Go Home", goHome, 25, 40, 3, 3)
		API.setTable("Set Home", setHome, 25 ,40, 6, 6)
		API.setTable("Status", getStatus, 5, 20, 6, 6)
		API.setTable("Show Area", areaToggleVisibility, 5,20, 9, 9)
		
		API.setTable("Set Area Center", areaSetCenter, 25, 40, 9, 9)
		API.setTable("---", areaDecX, 	3, 7, 12, 12)
		API.setTable("--" , areaDecX5, 	9, 13, 12, 12)
		API.setTable("-"  , areaDecX10, 15, 19, 12, 12)
		API.label(21, 12, "X")
		API.setTable("+"  , areaIncX, 	23, 27, 12, 12)
		API.setTable("++" , areaIncX5, 	29, 33, 12, 12)
		API.setTable("+++", areaIncX10, 35, 39, 12, 12)
		
		API.setTable("---", areaDecY, 	3, 7, 15, 15)
		API.setTable("--" , areaDecY5, 	9, 13, 15, 15)
		API.setTable("-"  , areaDecY10, 15, 19, 15, 15)
		API.label(21, 15, "Y")
		API.setTable("+"  , areaIncY, 	23, 27, 15, 15)
		API.setTable("++" , areaIncY5, 	29, 33, 15, 15)
		API.setTable("+++", areaIncY10,	35, 39, 15, 15)
		
		API.setTable("---", areaDecZ, 	3, 7, 18, 18)
		API.setTable("--" , areaDecZ5, 	9, 13, 18, 18)
		API.setTable("-"  , areaDecZ10,	15, 19, 18, 18)
		API.label(21, 18, "Z")
		API.setTable("+"  , areaIncZ,	23, 27, 18, 18)
		API.setTable("++" , areaIncZ5, 	29, 33, 18, 18)
		API.setTable("+++", areaIncZ10,	35, 39, 18, 18)
		API.label(60,3, "Drone Status")
		getStatus()
	else
	end
	API.screen()
end
function approachPlayer()
	lastAction = "Approach"
	getPlayerPos()
	drone.clearArea()
	drone.addArea(playerPos[1],playerPos[2],playerPos[3])
	drone.setAction("goto")
	getStatus()
	areaSend()
end
function goHome()
	lastAction = "Go home"
	drone.clearArea()
	drone.addArea(homePos[1],homePos[2],homePos[3])
	drone.setAction("goto")
	getStatus()
	areaSend()
end
function setHome()
	lastAction = "Home set!"
	getPlayerPos()
	homePos[1] = playerPos[1]
	homePos[2] = playerPos[2]-1
	homePos[3] = playerPos[3]
	getStatus()
end
function getStatus()
		--	Pressure
	pressure = drone.getDronePressure()

	--  Position
	position[1], position[2], position[3] = drone.getDronePosition()

	API.label(50, 5, "Action:                ")
	API.label(50, 5, "Action: "..lastAction)
	API.label(50, 6, "Pressure:"..pressure)
	API.label(50, 7, "X Pos: "..position[1])
	API.label(50, 8, "Y Pos: "..position[2])
	API.label(50, 9, "Z Pos: "..position[3])
	
	--	Work Area
	API.label(50, 11, "Work Area")
	API.label(50, 12, "X1: ".. workingArea[1])
	API.label(65, 12, "X2: ".. workingArea[4])
	API.label(50, 13, "Y1: ".. workingArea[2])
	API.label(65, 13, "Y2: ".. workingArea[5])
	API.label(50, 14, "Z1: ".. workingArea[3])
	API.label(65, 14, "Z2: ".. workingArea[6])
	API.label(50, 15, "Type: ".. workingAreaType)
	API.label(50, 17, "Lengths:")
	API.label(50, 18, "X: ".. xDist)
	API.label(57, 18, "Y: ".. yDist)
	API.label(65, 18, "Z: ".. zDist)
end

function areaToggleVisibility()
	API.toggleButton("Show Area")
	showArea = buttonStatus
	areaSend()
end
function areaSetCenter()
	getPlayerPos()
	workingCenter[1] = playerPos[1]
	workingCenter[2] = playerPos[2]
	workingCenter[3] = playerPos[3]
	
	workingArea[1] = workingCenter[1]
	workingArea[2] = workingCenter[2]
	workingArea[3] = workingCenter[3]
	workingArea[4] = workingCenter[1]
	workingArea[5] = workingCenter[2]
	workingArea[6] = workingCenter[3]
	
	workingAreaType = areaTypes[1]
	areaSend()
end
function areaSend()
	drone.clearArea()
	drone.addArea(workingArea[1],workingArea[2],workingArea[3],workingArea[4],workingArea[5],workingArea[6],workingAreaType)
	if(showArea == true) then
		drone.showArea()
	else
		drone.hideArea()
	end
	getStatus()
end

function areaIncX()
	xDist = xDist + 1;
	if(xSide) then
		workingArea[1] = workingArea[1]-1
		xSide = false
	else
		workingArea[4] = workingArea[4]+1
		xSide = true
	end
	areaSend()
end
function areaIncX5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaIncX();
	end
end
function areaIncX10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaIncX();
	end
end
function areaDecX()
	if( xDist > 0 ) then
		xDist = xDist - 1;
		if(xSide) then
			workingArea[4] = workingArea[4]+1
			xSide = false
		else
			workingArea[1] = workingArea[1]-1
			xSide = true
		end
	end
	areaSend()
end
function areaDecX5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaDecX();
	end
end
function areaDecX10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaDecX();
	end
end

function areaIncY()
	yDist = yDist + 1;
	if(ySide) then
		workingArea[2] = workingArea[2]-1
		ySide = false
	else
		workingArea[5] = workingArea[5]+1
		ySide = true
	end
	areaSend()
end
function areaIncY5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaIncY();
	end
end
function areaIncY10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaIncY();
	end
end
function areaDecY()
	if(yDist > 0) then
		yDist = yDist - 1;
		if(ySide) then
			workingArea[4] = workingArea[4]+1
			ySide = false
		else
			workingArea[1] = workingArea[1]-1
			ySide = true
		end
	end
	areaSend()
end
function areaDecY5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaDecY();
	end
end
function areaDecY10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaDecY();
	end
end

function areaIncZ()
	zDist = zDist + 1;
	if(zSide) then
		workingArea[3] = workingArea[3]-1
		zSide = false
	else
		workingArea[6] = workingArea[6]+1
		zSide = true
	end
	areaSend()
end
function areaIncZ5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaIncZ();
	end
end
function areaIncZ10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaIncZ();
	end
end
function areaDecZ()
	if(	zDist > 0 ) then
		zDist = zDist - 1;
		if(zSide) then
			workingArea[4] = workingArea[4]+1
			zSide = false
		else
			workingArea[1] = workingArea[1]-1
			zSide = true
		end
	end
	areaSend()
end
function areaDecZ5()
	local counter = 0;
	while (counter < 5) do
		counter = counter + 1;
		areaDecZ();
	end
end
function areaDecZ10()
	local counter = 0;
	while (counter < 10) do
		counter = counter + 1;
		areaDecZ();
	end
end

function areaMoveXP()
end
function areaMoveXN()
end
function shutdown()
	running = false
end

function getPlayerPos()
	modem.send(s_address, s_port, serial.serialize("getPosition"))
	local i = 1;
	while i <= 3 do
		local _,_,_,_,_,message = event.pull("modem_message")
		playerPos[i] = serial.unserialize(message)
		i = i + 1
	end
end

function getClick()
  local _, _, x, y = event.pull(1,touch)
  if x == nil or y == nil then
    local h, w = gpu.getResolution()
    gpu.set(h, w, ".")
    gpu.set(h, w, " ")
  else 
    API.checkxy(x,y)
  end
end

--	MAIN PROGRAM
print("initializing")
modem.open(s_port)
modem.broadcast(s_port, serial.serialize("init"))
_,_, s_address,_,_,msg = event.pull("modem_message")
message = serial.unserialize(msg)
if (message == "linked!") then
	modem.send(s_address, s_port, serial.serialize("confirm"))
else
	print("Could not find tablet to link to");
	running = false;
end
term.setCursorBlink(false)
gpu.setResolution(80,25)
API.clear()
API.fillTable()
API.heading("Drone Control Module")
while running do
	getClick()
end

modem.send(s_address, s_port, serial.serialize("unlink"))