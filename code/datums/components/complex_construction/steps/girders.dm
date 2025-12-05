/datum/construction_controller/girder
	var/list/base_steps = list(
		/datum/construction_step/girder/slice_apart,
		/datum/construction_step/girder/reinforce_frame,
	)

	var/list/base_wall_steps = list(
		/datum/construction_step/girder/make_wall/iron,
		/datum/construction_step/girder/make_wall/false/iron,
		/datum/construction_step/girder/make_wall/rods,
		/datum/construction_step/girder/make_wall/false/rods,
		/datum/construction_step/girder/make_wall/tram/titaniumglass,
		/datum/construction_step/girder/make_wall/plasteel,
		/datum/construction_step/girder/make_wall/false/plasteel,
		/datum/construction_step/girder/make_wall/plastitanium,
		/datum/construction_step/girder/make_wall/runed_metal,
		/datum/construction_step/girder/make_wall/bronze,
	)

	var/list/material_wall_steps = list(
		/datum/construction_step/girder/make_wall/material/normal,
		/datum/construction_step/girder/make_wall/material/concat/false,
		/datum/construction_step/girder/make_wall/material/concat/tram,
	)

/datum/construction_controller/girder/run_controller(mob/living/user, obj/item/used_item, obj/structure/girder/girder, list/modifiers)
	. = run_steps(base_steps)
	if (. & ITEM_INTERACT_SUCCESS)
		return // One of the base steps succeeded, let's stop here.
	if (!isstack(used_item))
		return // This returns ITEM_INTERACT_BLOCKING if one of the base steps was valid, otherwise it makes you whack the girder.

	// Don't whack it with any stack, even if you can't make anything with it.
	. = ITEM_INTERACT_BLOCKING

	var/obj/item/stack/used_stack = used_item

	if (!used_stack.usable_for_construction)
		girder.balloon_alert(user, "unusable material!")
		return

	var/obj/structure/girder/unique_girder_type = used_stack.unique_girder_type
	if (unique_girder_type && !istype(girder, unique_girder_type))
		girder.balloon_alert(user, "needs a different girder!")
		return

	if(iswallturf(girder.loc) || (locate(/obj/structure/falsewall) in girder.loc.contents))
		girder.balloon_alert(user, "wall already present!")
		return
	if (!isfloorturf(girder.loc) && girder.state != GIRDER_TRAM)
		girder.balloon_alert(user, "needs a floor!")
		return
	if (girder.state == GIRDER_TRAM && !(locate(/obj/structure/transport/linear/tram) in girder.loc.contents))
		girder.balloon_alert(user, "needs a tram floor!")
		return

	// If any of the base wall steps were valid, then we stop here.
	if (run_steps(base_wall_steps) & ITEM_INTERACT_ANY_BLOCKER)
		return

	// The amalgamation of all remaining material wall recipes.
	run_steps(material_wall_steps)

/datum/construction_step/girder
	abstract_type = /datum/construction_step/girder

	/// The required state of the girder, if any.
	var/req_girder_state = null

// Makes it such that if the girder state is invalid, this doesn't block material wall steps.
/datum/construction_step/girder/check_is_valid(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	return ..() && is_valid_girder(target)

// Just in case the girder state somehow changes midway through the action.
/datum/construction_step/girder/can_complete(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	return ..() && is_valid_girder(target)

/datum/construction_step/girder/proc/is_valid_girder(obj/structure/girder/girder)
	return isnull(req_girder_state) || girder.state == req_girder_state

/datum/construction_step/girder/slice_apart
	duration = 4 SECONDS
	req_item_type = /obj/item/gun/energy/plasmacutter
	req_item_amount = 1
	target_handling = CONSTRUCTION_DISASSEMBLE_TARGET
	starting_alert_text = "slicing apart..."

/datum/construction_step/girder/reinforce_frame
	duration = 6 SECONDS
	req_item_type = /obj/item/stack/sheet/plasteel
	req_item_amount = 1
	req_girder_state = GIRDER_NORMAL
	result_types = list(/obj/structure/girder/reinforced = 1)
	construction_flags = CONSTRUCTION_APPLY_SPEED_MODS
	target_handling = CONSTRUCTION_DELETE_TARGET
	starting_alert_text = "reinforcing frame..."

/datum/construction_step/girder/make_wall
	abstract_type = /datum/construction_step/girder/make_wall
	duration = 4 SECONDS
	req_item_type = /obj/item/stack
	req_girder_state = GIRDER_NORMAL
	construction_flags = CONSTRUCTION_APPLY_SPEED_MODS
	target_handling = CONSTRUCTION_DELETE_TARGET
	starting_alert_text = "adding plating..."

/datum/construction_step/girder/make_wall/false
	abstract_type = /datum/construction_step/girder/make_wall/false
	duration = 2 SECONDS
	req_girder_state = GIRDER_DISPLACED
	starting_alert_text = "concealing entrance..."

/datum/construction_step/girder/make_wall/tram
	abstract_type = /datum/construction_step/girder/make_wall/tram
	duration = 2 SECONDS
	req_girder_state = GIRDER_TRAM

/datum/construction_step/girder/make_wall/iron
	req_item_type = /obj/item/stack/sheet/iron
	req_item_amount = 2
	result_types = list(/turf/closed/wall = 1)

/datum/construction_step/girder/make_wall/false/iron
	req_item_type = /obj/item/stack/sheet/iron
	req_item_amount = 2
	result_types = list(/obj/structure/falsewall = 1)

/datum/construction_step/girder/make_wall/rods
	req_item_type = /obj/item/stack/rods
	req_item_amount = 5
	result_types = list(/turf/closed/wall/mineral/iron = 1)

/datum/construction_step/girder/make_wall/false/rods
	req_item_type = /obj/item/stack/rods
	req_item_amount = 5
	result_types = list(/obj/structure/falsewall/iron = 1)

/datum/construction_step/girder/make_wall/tram/titaniumglass
	req_item_type = /obj/item/stack/sheet/titaniumglass
	req_item_amount = 2
	result_types = list(/obj/structure/tram = 1)
	starting_alert_text = "adding panel..."

/datum/construction_step/girder/make_wall/plasteel
	duration = 5 SECONDS
	req_item_type = /obj/item/stack/sheet/plasteel
	req_item_amount = 1
	req_girder_state = GIRDER_REINF
	result_types = list(/turf/closed/wall/r_wall = 1)

/datum/construction_step/girder/make_wall/false/plasteel
	req_item_type = /obj/item/stack/sheet/plasteel
	req_item_amount = 1
	result_types = list(/obj/structure/falsewall/reinforced = 1)

/datum/construction_step/girder/make_wall/plastitanium
	duration = 5 SECONDS
	req_item_type = /obj/item/stack/sheet/mineral/plastitanium
	req_item_amount = 1
	req_girder_state = GIRDER_REINF
	result_types = list(/turf/closed/wall/r_wall/plastitanium = 1)

// For runed girders only.
/datum/construction_step/girder/make_wall/runed_metal
	duration = 5 SECONDS
	req_item_type = /obj/item/stack/sheet/runed_metal
	req_item_amount = 1
	result_types = list(/turf/closed/wall/mineral/cult = 1)

/datum/construction_step/girder/make_wall/runed_metal/is_valid_girder(obj/structure/girder/girder)
	return ..() && istype(girder, /obj/structure/girder/bronze)

// For wall gears only.
/datum/construction_step/girder/make_wall/bronze
	duration = 5 SECONDS
	req_item_type = /obj/item/stack/sheet/bronze
	req_item_amount = 2
	result_types = list(/turf/closed/wall/mineral/bronze = 1)

/datum/construction_step/girder/make_wall/bronze/is_valid_girder(obj/structure/girder/girder)
	return ..() && istype(girder, /obj/structure/girder/bronze)

/datum/construction_step/girder/make_wall/material
	abstract_type = /datum/construction_step/girder/make_wall/material
	duration = 4 SECONDS
	req_item_type = /obj/item/stack/sheet
	req_item_amount = 2
	construction_flags = CONSTRUCTION_APPLY_SPEED_MODS | CONSTRUCTION_APPLY_MATS

/datum/construction_step/girder/make_wall/material/normal
	req_girder_state = GIRDER_NORMAL
	result_types = list(/turf/closed/wall/material = 1)

// Having the wall types on the sheets is okay, but not great.
/datum/construction_step/girder/make_wall/material/normal/get_result_types(mob/living/user, obj/item/stack/sheet/used_sheets, atom/movable/target, list/modifiers)
	return used_sheets.walltype ? list(used_sheets.walltype = 1) : ..()

/datum/construction_step/girder/make_wall/material/concat
	abstract_type = /datum/construction_step/girder/make_wall/material/concat

	/// The base type of the resulting wall for sheets with unique wall types. This is then string concatenated into the final type.
	/// If the sheet's construction path is null, then the default [var/result_types] will be used instead.
	var/result_type_base = null

// This one is dynamic string concatenation, and it fucking sucks.
/datum/construction_step/girder/make_wall/material/concat/get_result_types(mob/living/user, obj/item/stack/sheet/used_sheets, atom/movable/target, list/modifiers)
	return used_sheets.construction_path_type ? list(text2path("[result_type_base]/[used_sheets.construction_path_type]") = 1) : ..()

/datum/construction_step/girder/make_wall/material/concat/false
	duration = 2 SECONDS
	req_girder_state = GIRDER_DISPLACED
	result_types = list(/obj/structure/falsewall/material = 1)
	result_type_base = /obj/structure/falsewall
	starting_alert_text = "concealing entrance..."

/datum/construction_step/girder/make_wall/material/concat/tram
	req_girder_state = GIRDER_TRAM
	result_types = list(/obj/structure/tram = 1)
	result_type_base = /obj/structure/tram/alt
