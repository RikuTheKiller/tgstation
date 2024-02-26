/datum/action/cooldown/blood_slime
	name = "Blood Slime Base Action"
	desc = "Please ahelp this."
	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'

	/// Our owner's blood slime antag datum.
	var/datum/antagonist/blood_slime/blood_slime

/datum/action/cooldown/blood_slime/IsAvailable(feedback)
	return ..() && owner.stat != DEAD // emerging when you've actually died and magically being revived is like, kind of bad

/datum/action/cooldown/blood_slime/Grant(mob/grant_to, datum/antagonist/blood_slime/antag_override)
	. = ..()

	blood_slime = antag_override ? antag_override : grant_to?.mind?.has_antag_datum(/datum/antagonist/blood_slime)

	if (!blood_slime)
		Remove(grant_to)
		CRASH("[grant_to] had [src] granted to them without the blood slime antag datum.") // the blood slime datum is rather volatile due to it's body-swapping nature

/datum/action/cooldown/blood_slime/Remove(mob/removed_from)
	. = ..()
	blood_slime = null

/// Blood slime action subtype for delayed activations, which it has plenty of.
/datum/action/cooldown/blood_slime/delayed
	/// Whether the action has been canceled or not.
	var/canceled

	/// Whether the delay is currently active or not.
	var/active

/datum/action/cooldown/blood_slime/delayed/Trigger(trigger_flags, atom/target)
	if (active) // cancel the action if used again during the delay
		if (!canceled)
			canceled = TRUE
			owner.balloon_alert(owner, "canceled!")
		return FALSE

	return ..()

/datum/action/cooldown/blood_slime/delayed/proc/do_delay(mob/user, delay, atom/target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_INCAPACITATED|IGNORE_SLOWDOWNS)
	active = TRUE
	canceled = FALSE

	. = do_after(user, delay, target, timed_action_flags, extra_checks = CALLBACK(src, PROC_REF(doafter_cancel_check)))

	active = FALSE
	canceled = FALSE

/datum/action/cooldown/blood_slime/delayed/proc/doafter_cancel_check()
	return !canceled
