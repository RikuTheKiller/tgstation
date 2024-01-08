/datum/action/bloodslime_leave_host
	name = "Emerge"
	desc = "Emerge from your host and take on your true appearance."

/datum/action/bloodslime_leave_host/Trigger(trigger_flags)
	. = ..()
	if (!.)
		return FALSE

	var/datum/antagonist/blood_slime/blood_slime = owner.mind.has_antag_datum(/datum/antagonist/blood_slime)
	if (!blood_slime)
		CRASH("[owner] ([owner.mind]) attempted emerge action without the blood slime antag datum.")

	blood_slime.leave_host()

	return TRUE
