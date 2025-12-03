/datum/construction_step/girder
	var/use_girder_drops = FALSE

/datum/construction_step/girder/get_result_types(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	. = ..()
	if (use_girder_drops)
		. += get_girder_drops(target)

/datum/construction_step/girder/proc/get_girder_drops(obj/structure/girder/girder)
	if (girder.state == GIRDER_TRAM)
		return list(/obj/item/stack/sheet/mineral/titanium = 2)
	return list(/obj/item/stack/sheet/iron = 2)

/datum/construction_step/girder/slice_apart
	duration = 4 SECONDS
	req_item_type = /obj/item/gun/energy/plasmacutter
	req_item_amount = 1
	target_handling = CONSTRUCTION_DISASSEMBLE_TARGET
	starting_alert_text = "slicing apart..."
