# GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD
survival friendly drone swarm using GPS location and Radar targeting (Computronics Addon)


This actually started around 2018-2019, but I kinda left it alone for a hot minute:

https://oc.cil.li/topic/1687-delux-drone-swarmarmyfor-free/

https://oc.cil.li/topic/1856-budget-drone-army-for-free/?tab=comments#comment-8680

...yeah my code sucked back then so I wanted to "fix it".

See, I found this addon called the Computronics addon for OpenComputers and quickly fell in love with the Radar Upgrade. I decided to slap it on a few drones, made them swarm around me, called it " The Delux Drone Army" and tried to sell it to people... for free.

I didn't realise my build wasn't survival friendly. Each drone needed a Radar Upgrade which was expensive in upgrade slot placement. So I tried to offset the radar to a stationary computer as a radar block. The problem was (not counting the other problems) it was stationary.

I finally want to come back and work on the project, hoping this Computer Engineering degree would be enough to improve whatever cringy code I started with.

## HOW IT WORKS...

See, I have two kinds of drones in my swarm. I call them the QUEENS and the PAWNS. 

### QUEENS
The Queens are a bit more expensive than Pawns. They each use a Navigation Upgrade and a Radar Upgrade (from the Computronics Addon) to intercept a target and fly in formation. They are expensive cause drones can only ever hold three upgrade slots at max:
<img width="354" alt="Screen Shot 2022-04-17 at 11 47 12 AM" src="https://user-images.githubusercontent.com/37253663/163699591-344cb3fa-c74d-42cd-8148-07c39084b1ac.png">

The Radar Upgrage tells them where players are and the Navigation Upgrade tells them where they are on a map. Now at first, I thought i could get away with only using the Radar Upgrade but the drones kept over shooting and getting stuck in a loop when they gets too far from their target.

The navigation Upgrade fixes this. Knowing where it is relative to a target and doing simple math, it can intercept it without overshooting. Getting stuck in a corner wouldn't even be a big issue anymore. If the target gets near enough, it can change direction easily and get's itself unstuck.

The down side is that the Navigation Upgrade can only work within a range of a map that you crafted it with.

Queens are fast but they only can operate within a certain range before replacing them with another set of Queens that can operate in the next map.

That's why they're mostly used for setting up GPS satellite clusters for Pawns to use and navigate the world (More about the GPS System bellow).


### PAWNS

Despite their name, these guys are the main attraction. They don't need upgrades to get arround, they can be as cheap as they can be. 

Instead of each having a Navigation upgrade they can calculate their own GPS location with the help of Queens flying in a satellite formation. 

Also, they each don't need an on board Radar upgrade. A command tablet with a radar upgrade relays a player or an entity's position instead.

Without needing any of these, they have a larger scalable range of operation. As long as they can maintain contact with enough satellite Queens (4 at minimum), they'll know where they are. 

And as long as you're within radar range of the command tablet, They'll know where YOU are...

Depending on how many GPS Satellite Clusters you have spread out in different maps, they can operate almost anywhere.

The best part is that they have free upgrade slots that you can use to make them do almost anything from delivering Amazon packages to planting bombs... not necessarily in that order.

The only downside I see is their target intercepting speed because of the delay in broadcasting their targets location from the command tablet.

### SWARM MANAGEMENT

#### MULTIPLE FLIGHT FORMATIONS
The drone manager maintains a pool of available drones. A player can request some drones from the pool to fill a flight formation. Depending on the size of the swarm a player can have multiple independent flight formations active all at the same time.

#### IMMORTAL FORMS
Each flight formation is regenerative. That means in case a drone falls out of formation, a player can simply hit refresh and request for a replacement from the pool without disturbing the rest of the flight formation. As long as you have enough spare drones the flight formation will stay immortal.

#### DYNAMIC FIRMWARE
Each drone has a base firmware in their BIOS chip enough to receive and load commands in memory through a wireless receiver. The rest of the Firmware is broadcasted to the drones as they get activated. This way I wouldn't need to replace each drone's BIOS chip whenever I need to tweak their firmware.

#### CLIENT BASED REQUEST
A swarm can be controlled through more than one command tablet. Depending on the number of available drones, more than one client can request for a formation from ~~the pool~~ THE SWARM.


### DYNAMIC GPS SYSTEM

For the GPS system I would like to thank these guys:
credomane and DOOBW: https://github.com/DOOBW/OC-GPS

ds84182: https://github.com/OpenPrograms/ds84182-Programs/blob/master/gps/libgps.lua

BigSHinyToys: http://www.computercraft.info/forums2/index.php?/topic/3088-how-to-guide-gps-global-position-system/ (for the satelite formation)

I tweaked their code a bit to make the GPS updates dynamic. I based it on credomane and DOOBW's work. I have the Sattelite Cluster constantly broadcast GPS coordinates thru a dedicated channel for anyone to listen to. I know this is a big power drain especially since PAWNS only ever need to know ther GPS position once every movement command from the tablet. However, a command tablet does need that sweet fast GPS channel to constantly update target entity positions for the PAWNS.

Moreover, you'de need to mess with the configuration anyways to get the radar upgrade to work so might as well mess with the power cost for broadcasting wireless signals.

Computronics Addon Configuration:
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
OpenComputers Configuration:
```
...

...
```

Now the plan is to use only a few drones with the radar upgrade (QUEENS) as satellites and have the rest of the swarm (SOLDIERS/PAWNS) use the GPS system instead of having each drone with its own radar upgrade.

Along the way, I realised the radar upgrade wasn't enough for flying in formation and intercepting targets. I needed navigation upgrades for my QUEENS to know where they are and calculate their movement properly. The down side to the navigation upgrade is that it needs a map to craft it. It stops working whe the drone flies out of range of the map.

As I said QUEENS are meant to be GPS satelite references for the PAWNS, they would be stationary most of the time so they don't need to move as much. If need be, I can easily replace QUEENS with ones that have navigation upgrades crafted for the neighboring map.

I made it so that flight formations are regenerative. That is if a drone stops working or gets knocked out of formation I can request another free drone from the swarm to take its place without disturbing the rest of the formation.

Right, flight formations. give the swarm an array of coordinates and they'll do their best to position themselves as so, around a "target". For the GPS Satellite formation the target is myself so I could easily position them better.



I needed to tweak their code a bit tho. See, their system is request based which means your gps location is only ever updated whenever you ask for it. That means I have to wait for at least 3 satellites to respond before I even have the chance to calculate my GPS position. This gets worse for a drone that needs its GPS location on the spot. In my experience I needed 7 QUEENS in a formation to get a more accurate GPS reading so I'd have to wait a bit longer. Moreover, there's also a chance of having to wait longer for a dead satellite to reply.

So, what I did was have each GPS Satellite continuously broadcast their position instead. This updates a GPS table on each PAWN. This way, the drone can get it's coordinates faster. Refreshing the table would automatically get rid of dead satellites as well. 


In summary, so far I:
+ separated most of the code into libraries
+ made flight formations are easier to edit
+ made swarm flight formations regenerative



gpsChannel = 65535

QUEEN_CommandChannel = 65534

PAWN_CommandChannel = 65533

QUEEN_ResponseChannel = 65532

PAWN_ResponseChannel = 65531

QUEEN_ErrorChannel = 65530

PAWN_ErrorChannel = 65529

trgChannel = [1-65528]
