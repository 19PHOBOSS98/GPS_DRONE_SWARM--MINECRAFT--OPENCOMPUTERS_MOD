local component = require("component")
local event = require("event")
local assembler = component.assembler
local modem = component.modem
local craftChannel = 10000
modem.open(craftChannel)

function craftHandler(evt,l_addr,r_addr,port,dist,msg,...)
    if port == craftChannel and msg == "craft" then
        while true do
            if assembler.status() == "idle" then
                modem.send(l_addr,craftChannel,"idle")
                assembler.start()
				print("crafted")
                return
            end
            modem.send(l_addr,craftChannel,"busy")
            os.sleep(0.5)
        end
    end
end

event.listen("modem_message",craftHandler)

