/// Generic barrage for things that aren't really all that magical.
/obj/item/gun/barrage
	name = "Barrage"
	desc = "A barrage of something."
	slot_flags = NONE
	obj_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON

	/// How quickly this fires.
	var/fire_rate = 0.2 SECONDS

	/// What ammo this uses.
	var/obj/item/ammo_casing/ammo

/obj/item/gun/barrage/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, fire_rate)
