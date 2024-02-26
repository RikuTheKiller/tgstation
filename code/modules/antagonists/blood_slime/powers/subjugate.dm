/datum/action/cooldown/blood_slime/delayed/subjugate
	name = "Subjugate"
	desc = "Take over your host's body and brain, acquiring a basic level of human intelligence. Only works on hosts that aren't overly injured."

/datum/action/cooldown/blood_slime/delayed/subjugate/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = blood_slime.current_host

	if (host.health < HEALTH_THRESHOLD_DEAD) // you either have to heal the corpse or use marionette instead
		host.balloon_alert(owner, "too damaged!")
		return FALSE

	owner.visible_message(
		message = span_danger("[host] starts convulsing!"),
		self_message = span_notice("You begin to subjugate your host..."),
		blind_message = isturf(host.loc) && host.has_gravity() ? span_hear("You hear something hitting the [isfloorturf(host.loc) ? "floor" : "ground"] repeadetly.") : null, // not overengineered at all
	)

	host.do_jitter_animation(200) // fluff

	if (!do_delay(owner, 2 SECONDS, target = host))
		owner.visible_message(span_notice("[host] stops convulsing."))
		return FALSE

	if (host.health < HEALTH_THRESHOLD_DEAD)
		owner.balloon_alert(owner, "too damaged!")
		return FALSE

	owner.visible_message(
		message = span_danger("[host] suddenly wakes up!"),
		self_message = span_notice("You subjugate your host."),
		blind_message = isturf(host.loc) && host.has_gravity() ? span_hear("You hear something hitting the [isfloorturf(host.loc) ? "floor" : "ground"] repeadetly.") : null, // not overengineered at all
	)

	blood_slime.subjugate_host()

	return TRUE
