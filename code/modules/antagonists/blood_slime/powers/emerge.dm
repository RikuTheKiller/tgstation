/datum/action/cooldown/blood_slime/cancellable/emerge
	name = "Emerge"
	desc = "Emerge from your host, leaving them bloodless in the process."

/datum/action/cooldown/blood_slime/cancellable/emerge/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = blood_slime.current_host

	owner.visible_message(
		message = span_danger("[host] trembles ominously."),
		self_message = span_notice("You prepare to emerge from your host."),
		ignored_mobs = list(blood_slime.current_host)
	)

	if (!do_delay(owner, 2 SECONDS, target = host, timed_action_flags = IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE))
		return FALSE

	blood_slime.leave_host()
	return TRUE
