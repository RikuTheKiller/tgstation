/datum/action/cooldown/blood_slime/blood_barrage
	name = "Barrage"
	desc = "Fire a continuous barrage of blood."
	cooldown_time = 10 SECONDS
	click_to_activate = TRUE

	/// How much blood this uses per shot.
	var/blood_cost = 0.01

	/// The barrage this fires.
	var/obj/item/gun/barrage/barrage

/datum/action/cooldown/blood_slime/blood_barrage/Activate(atom/target)
	. = ..()

	owner.visible_message(
		message = span_boldwarning("[owner] starts firing a barrage of blood!"),
		self_message = span_notice("You start firing a barrage of blood."),
		blind_message = span_hear("You hear constant splashing!")
	)

	/datum/component/automatic_fire

/obj/item/gun/barrage
	name = "Barrage"
	desc = "adminbuse go brr"
	slot_flags = null
	obj_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON

	/// How quickly this barrage fires.
	var/fire_rate = 0.2 SECONDS
