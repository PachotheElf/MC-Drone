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

--	DRONE AREAS
local importChestPos = {0,0,0}
local exportChestPos = {0,0,0}
local homePos = {0,0,0}
local workingCenter = {0,0,0}
local workingArea = {0,0,0,0,0,0}


--	FUNCTIONS
function API.fillTable()
	API.setTable("Close", shutdown, 70,80,1,1)
	if(state == 0) then	--	Main screen
		API.setTable("Come here", approachPlayer, 5, 20, 3, 3)
		API.setTable("Go Home", goHome, 25, 40, 3, 3)
		API.setTable("Set Home", setHome, 25 ,40, 6, 6)
		API.setTable("Status", getStatus, 5, 20, 6, 6)
	else
	end
	API.screen()
end
function approachPlayer()
	getPlayerPos()
	modem.send(s_address, s_port, serial.serialize("approachPlayer"))
	modem.send(s_address, s_port, serial.serialize(playerPos[0]))
	modem.send(s_address, s_port, serial.serialize(playerPos[1]))
	modem.send(s_address, s_port, serial.serialize(playerPos[2]))
end
function goHome()
	modem.send(s_address, s_port, serial.serialize("goHome"))
	modem.send(s_address, s_port, serial.serialize(homePos[0]))
	modem.send(s_address, s_port, serial.serialize(homePos[1]))
	modem.send(s_address, s_port, serial.serialize(homePos[2]))
end
function setHome()
	getPlayerPos()
	homePos = {playerPos[0], playerPos[1]-1, playerPos[2]}
end
function getStatus()
	modem.send(s_address, s_port, serial.serialize("status"))
		--	Pressure
	local _,_,_,_,_,message = event.pull("modem_message")
	pressure = serial.unserialize(message)
	print("Pressure:"..pressure)

	--  Position
	local i = 0;
	while i < 3 do
	local _,_,_,_,_,message = event.pull("modem_message")
	position[i] = serial.unserialize(message)
	i = i + 1
	end

	print("Position: "..position[0].." | "..position[1].." | "..position[2])
end

function shutdown()
	running = false
end

function getPlayerPos()
	pPosX, pPosY, pPosZ = nav.getPosition()
	playerPos[0] = pPosX + 256--POS_OFFSET[0]
	playerPos[1] = pPosY + 0--POS_OFFSET[1]
	playerPos[2] = pPosZ + 512--POS_OFFSET[2]
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