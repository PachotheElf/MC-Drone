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
showArea = false;

--	Drone area buffer
areaBuffer = {0,0,0,0,0,0}
areaType = "";

--	Functions
local function restoreArea()
	drone.clearArea()
	drone.addArea(areaBuffer[0], areaBuffer[1], areaBuffer[2], areaBuffer[3], areaBuffer[4], areaBuffer[5], areaType)
	for k,v in pairs(areaBuffer) do
		print(k, v)
	end
	
	drone.hideArea();
	if(showArea == true) then
		drone.showArea()
	end	
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
		s_add = from
		modem.send(s_add, s_port, serial.serialize("pong"))
	elseif ((message == "approachPlayer") or (message == "goHome")) then
		print("moving...")
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
	elseif (message == "status") then
		print("Sending status")
		status()
	elseif (message == "showArea") then
		print("Displaying area")
		drone.showArea()
		showArea = true;
	elseif (message == "hideArea") then	
		print("Hiding area")
		drone.hideArea()
		showArea = false;
	elseif (message == "setArea") then
		print("Setting new area")
		local i = 1
		while i < 7 do
			local _,_,_,_,_,message = event.pull("modem_message")
			areaBuffer[i] = serial.unserialize(message)
			i = i + 1
		end
		local _,_,_,_,_,message = event.pull("modem_message")
		areaType = serial.unserialize(message)
		restoreArea()
		
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
	