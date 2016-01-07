event = require("event")
serial = require("serialization")
component = require("component")
modem = component.modem
pressure = 0.0;
position = {0,0,0}
posX = 0.0;
posY = 0.0;
posZ = 0.0;

modem.broadcast(1, serial.serialize("init"))
modem.broadcast(1, serial.serialize("status"))

modem.open(1)
local _,_,_,_,_,message = event.pull("modem_message")
pressure = serial.unserialize(message)
print(pressure)

--  Position
local i = 0;
while i < 3 do
local _,_,_,_,_,message = event.pull("modem_message")
position[i] = serial.unserialize(message)
i = i + 1
end

print(position[0].." | "..position[1].." | "..position[2])

modem.broadcast(1, serial.serialize("shutdown"))