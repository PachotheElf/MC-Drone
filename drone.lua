local component = require("component")
local event = require("event")
serial = require("serialization")

drone = component.droneInterface
modem = component.modem;

s_add = "";
s_port = 1;

running = true;

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
	