/datum/action/cooldown/blood_slime/subjugate
	name = "Subjugate"
	desc = "Take over your host's body and brain, acquiring a basic level of human intelligence. Only works on hosts that aren't overly injured."

/datum/action/cooldown/blood_slime/subjugate/IsAvailable(feedback = FALSE)
	return ..() && blood_slime?.current_host

/datum/action/cooldown/blood_slime/subjugate/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = blood_slime.current_host

	if (host.health < HEALTH_THRESHOLD_DEAD) // you either have to heal the corpse or use marionette instead
		host.balloon_alert(owner, "too damaged!");

	host.visible_message(
		message = span_danger("[blood_slime.current_host] starts convulsing!"),
		self_message = span_notice("You begin circulating around in your host's body..."),
		blind_message = isturf(host.loc) && host.has_gravity() ? span_hear("You hear something hitting the [isfloorturf(host.loc) ? "floor" : "ground"] repeadetly.") : null, // not overengineered at all
		ignored_mobs = list(blood_slime.current_host)
	)

	if (!do_after(owner, 2 SECONDS, timed_action_flags = IGNORE_USER_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(doafter_cancel_check))))
		return FALSE

	if (host.health < HEALTH_THRESHOLD_DEAD)
		owner.balloon_alert(owner, "too damaged!");

	blood_slime.subjugate_host()

	return TRUE
