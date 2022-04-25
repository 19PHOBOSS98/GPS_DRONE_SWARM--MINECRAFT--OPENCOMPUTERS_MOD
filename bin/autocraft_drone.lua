local component = require("component")
local inventory_controller = component.inventory_controller

local item = inventory_controller.getStackInInternalSlot(1)
inventory_controller.dropIntoSlot(3,1,1)
