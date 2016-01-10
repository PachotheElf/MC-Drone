API = require("buttonAPI")
local event = require("event")
local serial = require("serialization")
local term = require("term")
local colors = require("colors")
local component = require("component")
local modem = component.modem
local gpu = component.gpu
local nav = component.navigation

--	PROGRAM STATE
--	0 = main screen
--	1 = 
local state	= 0

local running = true

--	COMMUNICATIONS VARIABLES
local s_port = 1;
local s_address = "";

--	PLAYER POSITION
local POS_OFFSET = {256, 0, 512}
local playerPos = {0,0,0}

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
local areaTypes = {"Filled", "Frame", "Walls", "Sphere", "Line", "X-Wall", "Y-Wall", "Z-Wall", "X-Cylinder", "Y-Cylinder", "Z-Cylinder", "X-Pyramid", "Y-Pyramid", "Z-Pyramid", "Grid"}

--	FUNCTIONS
function API.fillTable()
	API.setTable("Close", shutdown, 70,80,1,1)
	if(state == 0) then	--	Main screen
		API.setTable("Come here", approachPlayer, 5, 20, 3, 3)
		API.setTable("Go Home", goHome, 25, 40, 3, 3)
		API.setTable("Set Home", setHome, 25 ,40, 6, 6)
		API.setTable("Status", getStatus, 5, 20, 6, 6)
		API.label(60,3, "Drone Status")
		getStatus()
	else
	end
	API.screen()
end
function approachPlayer()
	lastAction = "Approach player"
	getPlayerPos()
	modem.send(s_address, s_port, serial.serialize("approachPlayer"))
	modem.send(s_address, s_port, serial.serialize(playerPos[0]))
	modem.send(s_address, s_port, serial.serialize(playerPos[1]))
	modem.send(s_address, s_port, serial.serialize(playerPos[2]))
	getStatus()
end
function goHome()
	lastAction = "Go home"
	modem.send(s_address, s_port, serial.serialize("goHome"))
	modem.send(s_address, s_port, serial.serialize(homePos[0]))
	modem.send(s_address, s_port, serial.serialize(homePos[1]))
	modem.send(s_address, s_port, serial.serialize(homePos[2]))
	getStatus()
end
function setHome()
	lastAction = "Home set!"
	getPlayerPos()
	homePos[0] = playerPos[0]
	homePos[1] = playerPos[1]-1
	homePos[2] = playerPos[2]
	getStatus()
end
function getStatus()
	modem.send(s_address, s_port, serial.serialize("status"))
		--	Pressure
	local _,_,_,_,_,message = event.pull("modem_message")
	pressure = serial.unserialize(message)

	--  Position
	local i = 0;
	while i < 3 do
	local _,_,_,_,_,message = event.pull("modem_message")
	position[i] = serial.unserialize(message)
	i = i + 1
	end

	API.label(50, 5, "Action:                ")
	API.label(50, 5, "Action: "..lastAction)
	API.label(50, 6, "Pressure:"..pressure)
	API.label(50, 7, "X Pos: "..position[0])
	API.label(50, 8, "Y Pos: "..position[1])
	API.label(50, 9, "Z Pos: "..position[2])
	
end

function shutdown()
	running = false
end

function getPlayerPos()
	pPosX, pPosY, pPosZ = nav.getPosition()
	playerPos[0] = pPosX + POS_OFFSET[1]
	playerPos[1] = pPosY + POS_OFFSET[2]
	playerPos[2] = pPosZ + POS_OFFSET[3]
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
modem.open(1)
modem.broadcast(1, serial.serialize("init"))
_,_, s_address,_,_,_ = event.pull("modem_message")
term.setCursorBlink(false)
gpu.setResolution(80,25)
API.clear()
API.fillTable()
API.heading("Drone Control Module")
while running do
	getClick()
end