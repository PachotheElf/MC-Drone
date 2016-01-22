local component = require("component")
local event = require("event")
computer = require("computer")
serial = require("serialization")

local modem = component.modem;
local nav = component.navigation;

local running = true

--	Communications
s_address = "";
s_port = 1;

--	Position
playerPos = {0,0,0}
POS_OFFSET = {256,0,512}

--	State
confirmed = false;

computer.addUser("Pacho")
modem.open(s_port)  --  Tablet port
while running do
	local _,_, from, port, dist, msg = event.pull("modem_message")
	message = serial.unserialize(msg)
	if (message == "init") and (confirmed == false) then
		print("initializing")
		s_address = from
		modem.send(s_address, s_port, serial.serialize("linked!"))
	elseif (message == "confirm") and (confirmed == false) then
		confirmed = true;
		print("confirmed!")
	elseif (message == "getPosition") and (confirmed == true) then
		pPosX, pPosY, pPosZ = nav.getPosition()
		playerPos[1] = pPosX + POS_OFFSET[1]
		playerPos[2] = pPosY + POS_OFFSET[2]
		playerPos[3] = pPosZ + POS_OFFSET[3]
		modem.send(s_address, s_port, serial.serialize(playerPos[1]))
		modem.send(s_address, s_port, serial.serialize(playerPos[2]))
		modem.send(s_address, s_port, serial.serialize(playerPos[3]))
		print("sending position: "..playerPos[1].." ".. playerPos[2].. " "..playerPos[3]);
	elseif (message == "unlink") and (confirmed == true) then
		print("unlinking")
		s_address = ""
		confirmed = false;
	else
		print("||"..message.."|| Confirmation: "..(serialization.serialize(confirmed)))
	end
end
	