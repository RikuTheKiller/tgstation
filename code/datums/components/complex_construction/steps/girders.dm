/datum/construction_step/girder
	var/starting_alert_text = null
	var/delete_girder_after = FALSE
	var/use_girder_drops = FALSE

/datum/construction_step/girder/on_started(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	if (starting_alert_text)
		target.balloon_alert(user, starting_alert_text)

/datum/construction_step/girder/get_resulting_atom_types(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	. = ..()
	if (use_girder_drops)
		. += get_girder_drops(target)

/datum/construction_step/girder/proc/get_girder_drops(obj/structure/girder/girder)
	if (girder.state == GIRDER_TRAM)
		return list(/obj/item/stack/sheet/mineral/titanium = 2)
	return list(/obj/item/stack/sheet/iron = 2)

/datum/construction_step/girder/on_completed(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs, list/results)
	if (delete_girder_after)
		qdel(target)

/datum/construction_step/girder/slice_apart
	duration = 4 SECONDS
	req_item_type = /obj/item/gun/energy/plasmacutter
	req_item_amount = 1

	starting_alert_text = "slicing apart..."
	delete_girder_after = TRUE
	use_girder_drops = TRUE
