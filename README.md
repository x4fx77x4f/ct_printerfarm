# Canadian's Turf printer farm
Mostly automatic money printer extinguisher for [Canadian's Turf](https://steamcommunity.com/groups/canadiansturf).

## Usage
1. `git clone https://github.com/x4fx77x4f/ct_printerfarm.git ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/starfall/ct_printerfarm`
2. Flash `/ct_printerfarm/init.lua` to a chip.
3. Place a User (from [Wiremod](https://github.com/wiremod/wire)), wire the "Fire" input of the User to the "Use" output of the chip, and wire the "User" input of the chip to the User.
4. Say `$507 aabb_add Vector(-1352,-2560,48) Vector(-864,-2368,176)` in chat, where "507" is the index of the chip entity, and the positions are the mins and maxs of a rectangular prism in world space that your printers will reside in.
