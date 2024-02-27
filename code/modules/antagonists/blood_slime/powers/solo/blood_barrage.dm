/datum/action/cooldown/blood_slime/blood_barrage
	name = "Barrage"
	desc = "Fire a barrage of blood, can be continued until you run out of blood."
	cooldown_time = 10 SECONDS

/datum/action/cooldown/blood_slime/blood_barrage/Activate(atom/target)
	. = ..()

	owner.visible_message(
		message = span_boldwarning("[owner] starts firing a barrage of blood!"),
		self_message = span_notice("You start firing a barrage of blood."),
		blind_message = span_hear("You hear constant splashing!")
	)
