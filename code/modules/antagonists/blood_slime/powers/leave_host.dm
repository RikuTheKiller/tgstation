/datum/action/bloodslime/delayed_host_action/leave_host
	name = "Emerge"
	desc = "Emerge from your host, leaving them bloodless in the process."
	delay = 2 SECONDS

/datum/action/bloodslime/delayed_host_action/leave_host/Trigger(trigger_flags)
	. = ..()
	if (!.)
		return FALSE

	var/mob/living/carbon/human/host = blood_slime.current_host

	owner.visible_message(
		message = span_danger("[host] trembles ominously."),
		self_message = span_notice("You prepare to emerge from your host."),
		ignored_mobs = list(blood_slime.current_host)
	)

	if (!do_delay())
		return FALSE

	blood_slime.leave_host()

	return TRUE
