local args = {...}
local component = require("component")
local event = require("event")
local inventory_controller = component.inventory_controller
local robot = component.robot
local modem = component.modem
local craftChannel = 10000
modem.open(craftChannel)
for i=0,tonumber(args[1]) do
	robot.select(1)
	inventory_controller.dropIntoSlot(3,1,1)
	robot.select(2)
	inventory_controller.dropIntoSlot(3,14,1)
	robot.select(3)
	inventory_controller.dropIntoSlot(3,17,1)
	robot.select(4)
	inventory_controller.dropIntoSlot(3,18,1)
	robot.select(5)
	inventory_controller.dropIntoSlot(3,19,1)
	robot.select(6)
	inventory_controller.dropIntoSlot(3,20,1)


	robot.select(7)
	inventory_controller.dropIntoSlot(3,7,1)
	robot.select(8)
	inventory_controller.dropIntoSlot(3,5,1)
	repeat
		modem.broadcast(craftChannel,"craft")
		local msg = {event.pull("modem_message")}
	until msg[6]=="idle"
	robot.select(10)
	suckFromSlot(3,1)
end
