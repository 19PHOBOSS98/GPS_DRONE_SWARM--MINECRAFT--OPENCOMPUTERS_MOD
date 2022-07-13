# GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD
survival friendly drone swarm using GPS location and Radar targeting (Computronics Addon)
<img width="636" alt="Screen Shot 2022-05-01 at 12 00 48 AM" src="https://user-images.githubusercontent.com/37253663/166113208-693b97e6-ef2d-44d1-9145-fdb640775d44.png">

<img width="645" alt="Screen Shot 2022-05-01 at 12 02 20 AM" src="https://user-images.githubusercontent.com/37253663/166113262-c07ea32c-0eaa-4f4b-9e02-5e0c6f5fd5b5.png">


<img width="572" alt="Screen Shot 2022-05-01 at 12 00 03 AM" src="https://user-images.githubusercontent.com/37253663/166113226-7533368e-9615-4fb7-a6ba-3725be894ae6.png">

<img width="913" alt="Screen Shot 2022-05-01 at 12 03 25 AM" src="https://user-images.githubusercontent.com/37253663/166113228-5acfcf76-4497-4758-bcb7-87f79e6a8644.png">

This actually started around 2018-2019, but I kinda left it alone for a hot minute:

https://oc.cil.li/topic/1687-delux-drone-swarmarmyfor-free/

https://oc.cil.li/topic/1856-budget-drone-army-for-free/?tab=comments#comment-8680

...yeah my code sucked back then so I wanted to "fix it".

See, I found this addon called the Computronics addon for OpenComputers and quickly fell in love with the Radar Upgrade. I decided to slap it on a few drones, made them swarm around me, called it " The Delux Drone Army" and tried to sell it to people... for free.

I didn't realise my build wasn't survival friendly. Each drone needed a Radar Upgrade which was expensive in upgrade slot placement. So I tried to offset the radar to a stationary computer as a radar block. The problem was (not counting the other problems) it was stationary.

I finally want to come back and work on the project, hoping this Computer Engineering degree would be enough to improve whatever cringy code I started with.

## HOW IT WORKS

See, I have two kinds of drones in my swarm. I call them the QUEENS and the PAWNS. 

### QUEENS
The Queens are a bit more expensive than Pawns. They each use a [Navigation Upgrade](https://ocdoc.cil.li/item:navigation_upgrade) and a [Radar Upgrage](https://wiki.vexatos.com/wiki:computronics:radar) (from the Computronics Addon) to intercept a target and fly in formation. They're expensive cause drones can only ever hold three upgrade slots at max:
<img width="354" alt="Screen Shot 2022-04-17 at 11 47 12 AM" src="https://user-images.githubusercontent.com/37253663/163699591-344cb3fa-c74d-42cd-8148-07c39084b1ac.png">

The Navigation Upgrade tells the drone where it is on a map and the Radar Upgrage tells them where players are. Now at first, I thought i could get away with only using the Radar Upgrade but the drones kept over shooting and getting stuck in a loop when they get too far from their target.

<img width="78" alt="Screen Shot 2022-04-17 at 3 27 37 PM" src="https://user-images.githubusercontent.com/37253663/163705055-0d4a3473-0e40-4b5f-b62e-c8589422796a.png">


The Navigation Upgrade fixes this. Knowing where it is relative to a target and doing simple math, it can intercept it without overshooting that much. Getting stuck in a corner wouldn't even be a big issue anymore. If the target gets near enough, it can change direction easily and get itself unstuck.

<img width="71" alt="Screen Shot 2022-04-17 at 3 27 43 PM" src="https://user-images.githubusercontent.com/37253663/163705059-542e6d76-1aac-48c6-acd4-ce31b85bbe1c.png">



The down side is that the Navigation Upgrade can only work within the range of a map that you crafted it with.

<img width="1280" alt="Screen Shot 2022-04-17 at 3 35 57 PM" src="https://user-images.githubusercontent.com/37253663/163705254-274faaef-4d57-4f05-9afd-2399fa81dbb7.png">

Queens are fast but they only can operate within a certain range before we can replace them with another set of Queens that can operate in the next map.

That's why they're mostly used for setting up stationary GPS satellite clusters for Pawns to move around with (More about the GPS System bellow).



### PAWNS

Despite their name, these guys are the main attraction. They don't need upgrades to get arround, they can be as cheap as they can get. 

Instead of each having a Navigation upgrade they can calculate their own GPS location with the help of Queens flying in a satellite formation. 

Also, they each don't need an on board Radar upgrade. A command tablet with a radar upgrade relays a player or an entity's position instead.

Without needing any of these, they have a larger scalable range of operation. As long as they can maintain contact with enough satellite Queens (4 at minimum), they'll know where they are. 

And as long as you're within radar range of the command tablet, They'll know where YOU are...

Depending on how many GPS Satellite Clusters you have spread out in different maps, they can operate almost anywhere.

The best part is that this frees up upgrade slots that you can use to make them do almost anything from delivering Amazon packages to planting bombs... not necessarily in that order.

<img width="327" alt="Screen Shot 2022-04-17 at 3 40 37 PM" src="https://user-images.githubusercontent.com/37253663/163705409-0a514314-fca7-4b3f-bf62-4959398bf62b.png">


The only downside I see is their target intercepting speed because of the delay in broadcasting their targets location from the command tablet.


### SWARM MANAGEMENT:

#### MULTIPLE FLIGHT FORMATIONS
The drone manager maintains a pool of available drones. A player can request some drones from the pool to fill a flight formation. Depending on the size of the swarm a player can have multiple independent flight formations active all at the same time.
<img width="692" alt="Screen Shot 2022-04-17 at 1 35 03 PM" src="https://user-images.githubusercontent.com/37253663/163704219-0b43ea8d-11ba-4cda-8a08-b89fcb7dfcbb.png">

#### IMMORTAL FORMS
Each flight formation is regenerative. That means in case a drone falls out of formation, a player can simply hit refresh and request for a replacement from the pool without disturbing the rest of the flight formation. As long as you have enough spare drones the flight formation will stay immortal.

#### DYNAMIC FIRMWARE
Each drone has a base firmware in their BIOS chip enough to receive and load commands in memory through a wireless receiver. The rest of the Firmware is broadcasted to the drones as they get activated. This way I wouldn't need to replace each drone's BIOS chip each time I need to tweak their firmware.

#### CLIENT BASED REQUEST
A swarm can be controlled through more than one command tablet. Depending on the number of available drones, more than one client can request for a formation from ~~the pool~~ THE SWARM.


### DYNAMIC GPS SYSTEM:

For the GPS system I would like to thank these guys:
credomane and DOOBW: https://github.com/DOOBW/OC-GPS

ds84182: https://github.com/OpenPrograms/ds84182-Programs/blob/master/gps/libgps.lua

BigSHinyToys: http://www.computercraft.info/forums2/index.php?/topic/3088-how-to-guide-gps-global-position-system/ (for the satelite formation)

I tweaked their code a bit to make the GPS updates dynamic. I based it on credomane and DOOBW's work. I have the Sattelite Cluster constantly broadcast GPS coordinates thru a dedicated channel for anyone to listen to. I know this is a big power drain especially since PAWNS only ever need to know ther GPS position once every movement command from the tablet. However, a command tablet, does need that sweet fast GPS channel to constantly update target entity positions for the PAWNS.

Moreover, you'de need to mess with the configurations anyway to get the radar upgrade to work, so might as well mess with the power cost for broadcasting wireless signals.

My Computronics Addon Configurations:
```
...
    # How much energy each 1-block distance takes by OpenComputers radars. [range: 0.0 ~ 10000.0, default: 50.0]
    S:radarCostPerBlock=0.5
}


radar {
    # The maximum range of the Radar. [range: 0 ~ 256, default: 8]
    I:maxRange=50

    # Stop Radars from outputting X/Y/Z coordinates and instead only output the distance from an entity. [default: true]
    B:onlyOutputDistance=false
}
...
```
My OpenComputers Configurations:
```
...
    # The maximum distance a wireless message can be sent. In other words,
    # this is the maximum signal strength a wireless network card supports.
    # This is used to limit the search range in which to check for modems,
    # which may or may not lead to performance issues for ridiculous ranges -
    # like, you know, more than the loaded area.
    # See also: `wirelessCostPerRange`.
    # These values are for the tier 1 and 2 wireless cards, in that order.
    maxWirelessRange=[
      160,
      4000
    ]
...
      # The amount of energy it costs to send a wireless message with signal
      # strength one, which means the signal reaches one block. This is
      # scaled up linearly, so for example to send a signal 400 blocks a
      # signal strength of 400 is required, costing a total of
      # 400 * `wirelessCostPerRange`. In other words, the higher this value,
      # the higher the cost of wireless messages.
      # See also: `maxWirelessRange`.
      # These values are for the tier 1 and 2 wireless cards, in that order.
      wirelessCostPerRange=[
        0.0001,
        0.0001
      ]
    }
...
```
Here are some QUEENS in a "Tetrahedron" formation acting as GPS satellites:
<img width="1280" alt="Screen Shot 2022-04-17 at 1 36 24 PM" src="https://user-images.githubusercontent.com/37253663/163704228-d59ab99a-0319-4fea-8329-a2871817e758.png">


### SWARM CHANNEL/PORTS
I haven't implemented these yet but might as well put it here.

gpsChannel = 65535

QUEEN_CommandChannel = 65534

PAWN_CommandChannel = 65533

QUEEN_ResponseChannel = 65532

PAWN_ResponseChannel = 65531

QUEEN_ErrorChannel = 65530

PAWN_ErrorChannel = 65529

trgChannel = [1-65528]  --these are where separate PAWN formations listen to for their targets location

### DOWNLOAD SHELL COMMANDS
Here are the shell commands to get all the libraries and programs you need, straight from this repo:

#### Libraries:
```
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/lib/Swarm_Utilities_lib.lua" /lib/swarm_utilities.lua
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/lib/QUEEN_DRONE_FIRMWARE_lib.lua" /lib/queen_firmware.lua
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/lib/Flight_Formation_lib.lua" /lib/flight_formation.lua
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/lib/PAWN_DRONE_FIRMWARE_lib.lua" /lib/pawn_firmware.lua
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/lib/Radar_Targeting_lib.lua" /lib/radar_targeting.lua

```
#### Flash these onto your drones' EEPROM Chip:
```
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/flash_BIOS/DRONE_BRAIN_QUEEN.lua" /home/QUEEN_BRAIN.lua
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/flash_BIOS/DRONE_BRAIN_PAWN.lua" /home/PAWN_BRAIN.lua
```
#### Main Client:
```
wget -f "https://raw.githubusercontent.com/19PHOBOSS98/GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD/main/bin/Swarm_Client.lua" /home/Swarm7.lua
```

### MOD DOWNLOAD LINKS
OpenComputers for 1.12.2: https://www.curseforge.com/minecraft/mc-mods/opencomputers

Computronics addon: https://wiki.vexatos.com/wiki:computronics

have fun!
