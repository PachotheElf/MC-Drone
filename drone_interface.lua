API = require("buttonAPI")
local event = require("event")
local serial = require("serialization")
local term = require("term")
local colors = require("colors")
local component = require("component")
local modem = component.modem
local gpu = component.gpu

--	PROGRAM STATE
--	0 = main screen
--	1 = 
local state	= 0

local running = true

--	COMMUNICATIONS VARIABLES
local s_port = 1;
local s_address = "";

--	DRONE STATUS
local pressure = 0.0;
local position = {0,0,0}
local posX = 0.0;
local posY = 0.0;
local posZ = 0.0;


--	FUNCTIONS
function API.fillTable()
	API.setTable("Close", shutdown, 70,80,1,1)
	if(state == 0) then	--	Main screen
		API.setTable("Status", getStatus, 10, 20, 3, 3)
	else
	end
	API.screen()
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

function getStatus()
	modem.broadcast(1, serial.serialize("status"))
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

--	MAIN PROGRAM
modem.open(1)
modem.broadcast(1, serial.serialize("init"))
term.setCursorBlink(false)
gpu.setResolution(80,25)
API.clear()
API.fillTable()
API.heading("Drone Control Module")
while running do
	getClick()
end