/* For referencing costs.
var/static/list/construction_cost = list(
		/obj/item/stack/sheet/iron = 2,
		/obj/item/stack/rods = 5,
		/obj/item/stack/sheet/plasteel = 2,
		/obj/item/stack/sheet/bronze = 2,
		/obj/item/stack/sheet/runed_metal = 1,
		/obj/item/stack/sheet/titaniumglass = 2,
		exotic_material = 2 // this needs to be refactored properly
	)
*/

/datum/construction_step/girder
	abstract_type = /datum/construction_step/girder

	/// The required state of the girder, if any.
	var/req_girder_state = null

/datum/construction_step/girder/can_complete(mob/living/user, obj/item/used_item, obj/structure/girder/girder, list/modifiers, list/reqs)
	return ..() && (isnull(req_girder_state) || girder.state == req_girder_state)

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

/datum/construction_step/girder/make_wall/can_start(mob/living/user, obj/item/stack/used_stack, obj/structure/girder/girder, list/modifiers, list/reqs)
	. = ..()
	if (!.) // Base checks come first, like required item type and such.
		return FALSE
	if (!used_stack.usable_for_construction)
		girder.balloon_alert(user, "unusable material!")
		return FALSE
	return TRUE

/datum/construction_step/girder/make_wall/can_complete(mob/living/user, obj/item/stack/used_stack, obj/structure/girder/girder, list/modifiers, list/reqs)
	. = ..()
	if (!.) // Base checks come first, like girder state and such.
		return FALSE
	if(iswallturf(girder.loc) || (locate(/obj/structure/falsewall) in girder.loc.contents))
		girder.balloon_alert(user, "wall already present!")
		return FALSE
	if (!isfloorturf(girder.loc) && girder.state != GIRDER_TRAM)
		girder.balloon_alert(user, "requires a floor!")
		return FALSE
	if (girder.state == GIRDER_TRAM && !(locate(/obj/structure/transport/linear/tram) in girder.loc.contents))
		girder.balloon_alert(user, "requires a tram floor!")
		return FALSE
	return TRUE

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

// For runed metal girders only.
/datum/construction_step/girder/make_wall/runed_metal
	duration = 5 SECONDS
	req_item_type = /obj/item/stack/sheet/runed_metal
	req_item_amount = 1
	result_types = list(/turf/closed/wall/mineral/cult = 1)
