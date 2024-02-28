/datum/action/cooldown/blood_slime/blood_barrage
	name = "Blood Barrage"
	desc = "Fire a continuous barrage of blood."
	cooldown_time = 10 SECONDS
	click_to_activate = TRUE

	/// How much blood this uses per shot. Measured as a percentage of BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM
	var/blood_cost = 0.02

	/// The internal barrage item this uses to fire.
	var/obj/item/gun/barrage/blood_barrage/barrage

/datum/action/cooldown/blood_slime/blood_barrage/Activate(atom/target)
	. = ..()

	owner.visible_message(
		message = span_boldwarning("[owner] starts firing a barrage of blood!"),
		self_message = span_notice("You start firing a barrage of blood."),
		blind_message = span_hear("You hear constant splashing!")
	)

/obj/item/gun/barrage/blood_barrage
	name = "Blood Barrage"
	desc = "adminbuse go brr"
	slot_flags = NONE
	obj_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON

	/// How quickly this fires.
	var/fire_rate = 0.2 SECONDS

	/// What ammo this uses.
	var/obj/item/ammo_casing/ammo

/obj/item/gun/barrage/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, fire_rate)
