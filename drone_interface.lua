button = require("buttonAPI")
local event = require("event")
local serial = require("serialization")
local term = require("term")
local colors = require("colors")
local component = require("component")
local modem = component.modem

local pressure = 0.0;
local position = {0,0,0}
local posX = 0.0;
local posY = 0.0;
local posZ = 0.0;

modem.broadcast(1, serial.serialize("init"))
modem.broadcast(1, serial.serialize("status"))

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