local component = require("component")
local event = require("event")
serial = require("serialization")

drone = component.droneInterface
modem = component.modem;

--	Communications
s_add = "";
s_port = 1;

-- Program states
running = true;

--	Drone area buffer
areaBuffer = {0,0,0,0,0,0}
areaType = 0;

--	Functions
local function restoreArea()
	drone.clearArea()
	drone.addArea(areaBuffer[0], areaBuffer[1], areaBuffer[2], areaBuffer[3], areaBuffer[4], areaBuffer[5], areaType)
end
local function status()
	if(drone.isConnectedToDrone()) then
		modem.send(s_add, s_port, serial.serialize(drone.getDronePressure()))
		local posX, posY, posZ = drone.getDronePosition()

		position = {posX, posY, posZ}
		modem.send(s_add, s_port, serial.serialize(posX))
		modem.send(s_add, s_port, serial.serialize(posY))
		modem.send(s_add, s_port, serial.serialize(posZ))
	else
		print("Not Connected to drone") 
	end
end

modem.open(s_port)  --  Tablet port
while running do
	local _,_, from, port, dist, msg = event.pull("modem_message")
	message = serial.unserialize(msg)
	if (message == "init") then
		print("initializing")
		modem.send(s_add, s_port, serial.serialize("pong"))
		s_add = from
	elseif ((message == "approachPlayer") || (message == "goHome")) then
		local i = 0;
		local homePos={0,0,0}
		while i < 3 do
			local _,_,_,_,_,message = event.pull("modem_message")
			homePos[i] = serial.unserialize(message)
			i = i + 1
		end
		drone.clearArea()
		drone.addArea(homePos[0], homePos[1], homePos[2])
		drone.setAction("goto")
		restoreArea()
	elseif (message == "goHome") then
	elseif (message == "status") then
		print("sending status")
		status()
		elseif (message == "shutdown") then
		running = false;
	else
		print("||"..message.."||")
	end
end
local actions = drone.getAllActions()
for k,v in actions do
	print(k,v)
end
	