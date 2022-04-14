# GPS_DRONE_SWARM--MINECRAFT--OPENCOMPUTERS_MOD
survival friendly drone swarm using GPS location and Radar targeting (Computronics Addon)


This actually started around 2018-2019:
https://oc.cil.li/topic/1687-delux-drone-swarmarmyfor-free/

https://oc.cil.li/topic/1856-budget-drone-army-for-free/?tab=comments#comment-8680

...yeah my code sucked back then so I wanted to "fix it".

See, I found this addon called the Computronics addon for OpenComputers and quickly fell in love with the Radar Upgrade. I decided to slap it on a few drones, made them swarm around me, called it " The Delux Drone Army" and tried to sell it to people... for free.

I didn't realise my build wasn't survival friendly. Each drone needed a Radar Upgrade which was expensive in upgrade slot placement. So I tried to offset the radar to a stationary computer as a radar block. The problem was (not counting the other problems) it was stationary.

I finally want to come back and work on the project, hoping this Computer Engineering degree would be enough to improve whatever cringy code I started with.

Now the plan is to use only a few drones with the radar upgrade (QUEENS) as satellites and have the rest of the swarm (SOLDIERS/PAWNS) use the GPS system instead of having each drone with its own radar upgrade.

Along the way, I realised the radar upgrade wasn't enough for flying in formation and intercepting targets. I needed navigation upgrades for my QUEENS to know where they are and calculate their movement properly. The down side to the navigation upgrade is that it needs a map to craft it. It stops working whe the drone flies out of range of the map.

As I said QUEENS are meant to be GPS satelite references for the PAWNS, they would be stationary most of the time so they don't need to move as much. If need be, I can easily replace QUEENS with ones that have navigation upgrades crafted for the neighboring map.

I made it so that flight formations are regenerative. That is if a drone stops working or gets knocked out of formation I can request another free drone from the swarm to take its place without disturbing the rest of the formation.

Right, flight formations. give the swarm an array of coordinates and they'll do their best to position themselves as so, around a "target". For the GPS Satellite formation the target is myself so I could easily position them better.

For the GPS system I would like to thank these guys:
https://github.com/DOOBW/OC-GPS

https://github.com/OpenPrograms/ds84182-Programs/blob/master/gps/libgps.lua

http://www.computercraft.info/forums2/index.php?/topic/3088-how-to-guide-gps-global-position-system/ (for the satelite formation)

I needed to tweak their code a bit tho. See, their system is request based which means your gps location is only ever updated whenever you ask for it. That means I have to wait for at least 3 satellites to respond before I even have the chance to calculate my GPS position. This gets worse for a drone that needs its GPS location on the spot. In my experience I needed 7 QUEENS in a formation to get a more accurate GPS reading so I'd have to wait a bit longer. Moreover, there's also a chance of having to wait longer for a dead satellite to reply.

So, what I did was have each GPS Satellite continuously broadcast their position instead. This updates a GPS table on each PAWN. This way, the drone can get it's coordinates faster. Refreshing the table would automatically get rid of dead satellites as well. 


In summary, so far I:
+ separated most of the code into libraries
+ made flight formations are easier to edit
+ made swarm flight formations regenerative
