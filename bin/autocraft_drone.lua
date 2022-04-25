local component = require("component")
local inventory_controller = component.inventory_controller
local robot = component.robot

local item = robot.select(2)
inventory_controller.dropIntoSlot(3,1,1)
