local component = require("component")
local inventory_controller = component.inventory_controller
local robot = component.robot
local modem = component.modem
local PCchannel = 10000

robot.select(1)
inventory_controller.dropIntoSlot(3,1,1)
robot.select(2)
inventory_controller.dropIntoSlot(3,5,1)
robot.select(3)
inventory_controller.dropIntoSlot(3,14,1)
robot.select(4)
inventory_controller.dropIntoSlot(3,17,1)
robot.select(5)
inventory_controller.dropIntoSlot(3,18,1)
robot.select(6)
inventory_controller.dropIntoSlot(3,19,1)
robot.select(7)
inventory_controller.dropIntoSlot(3,20,1)


robot.select(8)
inventory_controller.dropIntoSlot(3,7,1)
robot.select(9)
inventory_controller.dropIntoSlot(3,5,1)

modem.broadcast(PCchannel,"craft")
