/obj/item/vacuum_hose
	name = "vacuum hose"
	desc = "A hose attached to the vacuum pack."
	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "mister"
	inhand_icon_state = "mister"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	item_flags = NOBLUDGEON | ABSTRACT  // don't put in storage
	slot_flags = NONE
	spawn_blacklisted = TRUE

	///The vacuum pack we are in
	var/obj/item/vacuum_pack/vac_pack

/obj/item/vacuum_hose/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_STORAGE_INSERT, TRAIT_GENERIC)
	if (!loc || !istype(loc, /obj/item/vacuum_pack))
		return INITIALIZE_HINT_QDEL
	vac_pack = loc

/obj/item/vacuum_hose/Destroy()
	vac_pack = null
	return ..()

/obj/item/vacuum_hose/interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(!vac_pack?.loaded_tank || !ismob(interacting_with))
		return ITEM_INTERACT_BLOCKING

	vac_pack.loaded_tank.load_mob(interacting_with, user)

	return ITEM_INTERACT_SUCCESS

/obj/item/vacuum_hose/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	launch_content(interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/vacuum_hose/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return ranged_interact_with_atom(interacting_with, user, modifiers)

///Launches something from the attached container
/obj/item/vacuum_hose/proc/launch_content(atom/target, mob/user)
	if(!vac_pack?.loaded_tank)
		balloon_alert(user, "No tank!")
		playsound(get_turf(src), 'sound/items/syringeproj.ogg', 30, TRUE, -3)
		return

	var/atom/movable/flying_item = vac_pack.loaded_tank.fire_content(user)
	if(flying_item)
		playsound(get_turf(src), 'sound/items/syringeproj.ogg', 30, TRUE, -3)
		flying_item.throw_at(target, 3, 2)
	else
		playsound(get_turf(src), 'sound/machines/click.ogg', 30, TRUE, -3)



