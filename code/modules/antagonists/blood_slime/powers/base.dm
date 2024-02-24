/datum/action/cooldown/blood_slime
	name = "Blood Slime Base Action"
	desc = "Please ahelp this."
	click_to_activate = FALSE

	/// Our owner's blood slime antag datum.
	var/datum/antagonist/blood_slime/blood_slime
	var/cancelled

/datum/action/cooldown/blood_slime/Grant(mob/grant_to)
	. = ..()
	if (!.)
		return FALSE

	blood_slime = grant_to?.mind?.has_antag_datum(/datum/antagonist/blood_slime)

	if (!blood_slime)
		Remove(grant_to)
		CRASH("[grant_to] had [src] granted to them without the blood slime antag datum.") // the blood slime datum is rather volatile due to it's body-swapping nature

/datum/action/cooldown/blood_slime/proc/doafter_cancel_check()
	return !cancelled
