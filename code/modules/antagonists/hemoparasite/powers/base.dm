/datum/action/cooldown/hemoparasite
	name = "Hemoparasite Base Action"
	desc = "Please ahelp this."
	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'

	/// Our owner's hemoparasite antag datum.
	var/datum/antagonist/hemoparasite/hemoparasite

	/// How much blood this costs to use. (percentage, implementation is ability-specific)
	var/cost

/datum/action/cooldown/hemoparasite/IsAvailable(feedback)
	if (hemoparasite.get_blood_percentage() < cost)
		if (feedback)
			owner.balloon_alert("not enough blood!")
	return ..() && owner.stat != DEAD // emerging when you've actually died and magically being revived is like, kind of bad

/datum/action/cooldown/hemoparasite/Grant(mob/grant_to, datum/antagonist/hemoparasite/antag_override)
	hemoparasite = antag_override ? antag_override : grant_to?.mind?.has_antag_datum(/datum/antagonist/hemoparasite)

	if (!hemoparasite)
		Remove(grant_to)
		CRASH("[grant_to] had [src] granted to them without the hemoparasite antag datum.") // the hemoparasite datum is rather volatile due to it's body-swapping nature

	return ..()

/datum/action/cooldown/hemoparasite/Remove(mob/removed_from)
	. = ..()
	hemoparasite = null

/// Hemoparasite action subtype for delayed activations, which it has plenty of.
/datum/action/cooldown/hemoparasite/delayed
	/// Whether the action has been canceled or not.
	var/canceled

	/// Whether the delay is currently active or not.
	var/active

/datum/action/cooldown/hemoparasite/delayed/Trigger(trigger_flags, atom/target)
	if (active) // cancel the action if used again during the delay
		if (!canceled)
			canceled = TRUE
			owner.balloon_alert(owner, "canceled!")
		return FALSE

	return ..()

/datum/action/cooldown/hemoparasite/delayed/proc/do_delay(mob/user, delay, atom/target, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_INCAPACITATED|IGNORE_SLOWDOWNS)
	active = TRUE
	canceled = FALSE

	. = do_after(user, delay, target, timed_action_flags, extra_checks = CALLBACK(src, PROC_REF(doafter_cancel_check)))

	active = FALSE
	canceled = FALSE

/datum/action/cooldown/hemoparasite/delayed/proc/doafter_cancel_check()
	return !canceled

/// Base type for status effects given by the hemoparasite antagonist.
/datum/status_effect/hemoparasite
	/// Reference to the hemoparasite antag datum that owns this.
	var/datum/antagonist/hemoparasite/hemoparasite

/datum/status_effect/hemoparasite/on_creation(mob/living/new_owner, datum/antagonist/hemoparasite/antag_override)
	hemoparasite = antag_override

	return ..()

/datum/status_effect/hemoparasite/on_apply()
	hemoparasite = hemoparasite ? hemoparasite : owner?.mind?.has_antag_datum(/datum/antagonist/hemoparasite)

	if (!istype(hemoparasite))
		return FALSE

	return ..()

/datum/status_effect/hemoparasite/on_remove()
	hemoparasite = null
