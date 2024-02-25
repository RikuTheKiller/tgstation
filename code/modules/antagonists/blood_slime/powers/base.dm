/datum/action/cooldown/blood_slime
	name = "Blood Slime Base Action"
	desc = "Please ahelp this."

	/// Our owner's blood slime antag datum.
	var/datum/antagonist/blood_slime/blood_slime

/datum/action/cooldown/blood_slime/Grant(mob/grant_to)
	. = ..()
	blood_slime = grant_to?.mind?.has_antag_datum(/datum/antagonist/blood_slime)

	if (!blood_slime)
		Remove(grant_to)
		CRASH("[grant_to] had [src] granted to them without the blood slime antag datum.") // the blood slime datum is rather volatile due to it's body-swapping nature

/// Blood slime action subtype for cancellable activations.
/datum/action/cooldown/blood_slime/cancellable
	/// Whether the action has been cancelled or not.
	var/cancelled

	/// Whether the delay is currently active or not.
	var/active

/datum/action/cooldown/blood_slime/cancellable/Trigger(trigger_flags)
	if (active && !cancelled)
		cancelled = TRUE
		active = FALSE
		owner.balloon_alert(owner, "cancelled!")
		return FALSE

	. = ..()
	if(.)
		active = TRUE

/datum/action/cooldown/blood_slime/cancellable/proc/do_delay(mob/user, delay, atom/target, timed_action_flags)
	. = do_after(user, delay, target, timed_action_flags, extra_checks = PROC_REF(doafter_cancel_check))

	active = FALSE
	cancelled = FALSE

/datum/action/cooldown/blood_slime/cancellable/proc/doafter_cancel_check()
	return !cancelled
