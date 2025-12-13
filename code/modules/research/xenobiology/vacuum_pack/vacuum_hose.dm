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
