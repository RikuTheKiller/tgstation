/// Generic barrage for things that aren't really all that magical, but still abstract.
/obj/item/gun/barrage
	name = "Barrage"
	desc = "A barrage of pure, unending nothingness. THERE IS NO BARRAGE IT'S ALL A LIE!"
	slot_flags = NONE
	obj_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL // no trigger
	clumsy_check = FALSE // it would be funny but it's weird for a barrage tbh
	pinless = TRUE // no pin either

	/// How quickly this fires.
	var/fire_rate = 0.2 SECONDS

	/// What ammo type this uses.
	var/obj/item/ammo_casing/ammo_type

/obj/item/gun/barrage/Initialize(mapload)
	. = ..()
	if (ammo_type)
		chambered = new ammo_type(src)
	AddComponent(/datum/component/automatic_fire, fire_rate)

/obj/item/gun/barrage/handle_chamber(empty_chamber, from_firing, chamber_next_round)
	recharge_newshot()

/obj/item/gun/barrage/recharge_newshot()
	chambered.newshot()
