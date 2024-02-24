/datum/action/bloodslime
	name = "Blood Slime Base Action"
	desc = "Please ahelp this."

	/// Our owner's blood slime antag datum.
	var/datum/antagonist/blood_slime/blood_slime

/datum/action/bloodslime/Grant(mob/grant_to)
	. = ..()
	if (!.)
		return FALSE

	blood_slime = grant_to?.mind?.has_antag_datum(/datum/antagonist/blood_slime)

	if (!blood_slime)
		Remove(grant_to)
		CRASH("[grant_to] had [src] granted to them without the blood slime antag datum.") // the blood slime datum is rather volatile due to it's body-swapping nature

/datum/action/bloodslime/delayed_host_action

	/// How long the action should take.
	var/delay

	/// Whether the action has been cancelled or not.
	var/canceled = FALSE

	/// Whether the action is being used.
	var/active = FALSE

/datum/action/bloodslime/delayed_host_action/IsAvailable(feedback)
	. = ..()

	if (!blood_slime)
		Remove(owner)
		CRASH("[owner] tried to use [src] without the blood slime antag datum.") // the blood slime datum is rather volatile due to it's body-swapping nature

	if (active && !canceled)
		canceled = TRUE
		if (feedback)
			owner.balloon_alert("canceled!")

	return . && !canceled

/// Returns TRUE if we passed the cancellable delay, otherwise FALSE. Ignores the user's loc.
/datum/action/bloodslime/delayed_host_action/proc/do_delay()
	if (!delay)
		return TRUE

	active = TRUE

	var/passed = FALSE

	if (do_after(owner, delay, timed_action_flags = IGNORE_USER_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(doafter_cancel_check))))
		passed = TRUE

	canceled = FALSE
	active = FALSE

	return passed

/datum/action/bloodslime/delayed_host_action/proc/doafter_cancel_check()
	return !canceled
