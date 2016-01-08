API = require("buttonAPI")
local event = require("event")
local serial = require("serialization")
local term = require("term")
local colors = require("colors")
local component = require("component")
local modem = component.modem

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
	API.setTable("Status", getStatus, 10, 20, 3, 5)
end

function getStatus()
	modem.broadcast(1, serial.serialize("status"))
end


--	MAIN PROGRAM
modem.broadcast(1, serial.serialize("init"))

term.setCursorBlink(false)
gpu.setResolution(80,25)
API.clear()
API.fillTable()
API.heading("Drone Control Module")


modem.open(1)

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

--  Shutdown
modem.broadcast(1, serial.serialize("shutdown"))