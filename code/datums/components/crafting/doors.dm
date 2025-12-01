/datum/crafting_recipe/shutters
	name = "Shutters"
	reqs = list(
		/obj/item/stack/sheet/plasteel = 5,
		/obj/item/stack/cable_coil = 5,
		/obj/item/electronics/airlock = 1,
	)
	result = /obj/machinery/door/poddoor/shutters/preopen
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_MULTITOOL, TOOL_WIRECUTTER, TOOL_WELDER)
	time = 10 SECONDS
	category = CAT_DOORS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF

/datum/crafting_recipe/shutter_assembly
	name = "Shutter Assembly"
	reqs = list(/obj/item/stack/sheet/plasteel = 5)
	result = /obj/machinery/door/poddoor/shutters/preopen/deconstructed
	time = 5 SECONDS
	crafting_flags = CRAFT_ONE_PER_TURF
	category = CAT_DOORS

/datum/crafting_recipe/blast_doors
	name = "Blast Door"
	reqs = list(
		/obj/item/stack/sheet/plasteel = 15,
		/obj/item/stack/cable_coil = 15,
		/obj/item/electronics/airlock = 1,
	)
	result = /obj/machinery/door/poddoor/preopen
	tool_behaviors = list(TOOL_SCREWDRIVER, TOOL_MULTITOOL, TOOL_WIRECUTTER, TOOL_WELDER)
	time = 30 SECONDS
	category = CAT_DOORS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF

/datum/crafting_recipe/windoor_frame
	name = "Windoor Frame"
	reqs = list(/obj/item/stack/sheet/glass = 5)
	result = /obj/structure/windoor_assembly
	time = 0
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ON_SOLID_GROUND | CRAFT_CHECK_DIRECTION
	category = CAT_DOORS

/datum/crafting_recipe/firelock_frame
	name = "Firelock Frame"
	reqs = list(/obj/item/stack/sheet/iron = 3)
	result = /obj/structure/firelock_frame
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
	category = CAT_DOORS

/datum/crafting_recipe/directional_firelock_frame
	name = "Directional Firelock Frame"
	reqs = list(/obj/item/stack/sheet/iron = 2)
	result = /obj/structure/firelock_frame/border_only
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ON_SOLID_GROUND | CRAFT_CHECK_DIRECTION
	category = CAT_DOORS

/datum/crafting_recipe/material/airlock_assembly
	name = "Material Airlock Assembly"
	result = /obj/structure/door_assembly/door_assembly_material
	req_sheet_count = 4
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS
	category = CAT_DOORS

/datum/crafting_recipe/alien_airlock_assembly
	name = "Alien Airlock Assembly"
	reqs = list(/obj/item/stack/sheet/mineral/abductor = 4)
	result = /obj/structure/door_assembly/door_assembly_abductor
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
	category = CAT_DOORS

/datum/crafting_recipe/high_security_airlock_assembly
	name = "High Security Airlock Assembly"
	reqs = list(/obj/item/stack/sheet/plasteel = 4)
	result = /obj/structure/door_assembly/door_assembly_highsecurity
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
	category = CAT_DOORS

/datum/crafting_recipe/vault_door_assembly
	name = "Vault Door Assembly"
	reqs = list(/obj/item/stack/sheet/plasteel = 6)
	result = /obj/structure/door_assembly/door_assembly_vault
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
	category = CAT_DOORS

/datum/crafting_recipe/bronze_airlock_assembly
	name = "pinion airlock assembly"
	reqs = list(/obj/item/stack/sheet/bronze = 4)
	result = /obj/structure/door_assembly/door_assembly_bronze
	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
	category = CAT_DOORS

/datum/crafting_recipe/bronze_airlock_assembly/transparent
	name = "transparent pinion airlock assembly"
	result = /obj/structure/door_assembly/door_assembly_bronze/seethru

/datum/crafting_recipe/mineral_door
	abstract_type = /datum/crafting_recipe/mineral_door

	time = 5 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS
	category = CAT_DOORS

/datum/crafting_recipe/mineral_door/sandstone
	name = "sandstone door"
	reqs = list(/obj/item/stack/sheet/mineral/sandstone = 10)
	result = /obj/structure/mineral_door/sandstone

/datum/crafting_recipe/mineral_door/diamond
	name = "diamond door"
	reqs = list(/obj/item/stack/sheet/mineral/diamond = 10)
	result = /obj/structure/mineral_door/transparent/diamond

/datum/crafting_recipe/mineral_door/uranium
	name = "uranium door"
	reqs = list(/obj/item/stack/sheet/mineral/uranium = 10)
	result = /obj/structure/mineral_door/uranium

/datum/crafting_recipe/mineral_door/plasma
	name = "plasma door"
	reqs = list(/obj/item/stack/sheet/mineral/plasma = 10)
	result = /obj/structure/mineral_door/transparent/plasma

/datum/crafting_recipe/mineral_door/gold
	name = "golden door"
	reqs = list(/obj/item/stack/sheet/mineral/gold = 10)
	result = /obj/structure/mineral_door/gold

/datum/crafting_recipe/mineral_door/silver
	name = "silver door"
	reqs = list(/obj/item/stack/sheet/mineral/silver = 10)
	result = /obj/structure/mineral_door/silver

/datum/crafting_recipe/mineral_door/iron
	name = "iron door"
	reqs = list(/obj/item/stack/sheet/iron = 20)
	result = /obj/structure/mineral_door/iron

/datum/crafting_recipe/mineral_door/wood
	name = "wooden door"
	reqs = list(/obj/item/stack/sheet/mineral/wood = 10)
	result = /obj/structure/mineral_door/wood
	time = 2 SECONDS
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND
