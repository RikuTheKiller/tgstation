/datum/action/cooldown/blood_slime/delayed/subjugate
    name = "Subjugate"
    desc = "Take over your host's body and brain, acquiring a basic level of human intelligence. Only works on hosts that aren't overly injured."
    delay = 2 SECONDS

/datum/action/cooldown/blood_slime/delayed/subjugate/Trigger(trigger_flags)
    . = ..()
    if (!.)
        return FALSE

    var/mob/living/carbon/human/host = blood_slime.current_host

    if (host.health < HEALTH_THRESHOLD_DEAD) // you either have to heal the corpse or use marionette instead
        owner.balloon_alert(owner, "too damaged!");

    owner.visible_message(
		message = span_danger("[blood_slime.current_host] starts convulsing!"),
		self_message = span_notice("You begin circulating around in your host's body..."),
		blind_message = isturf(owner.loc) && owner.has_gravity() ? span_hear("You hear something hitting the [isfloorturf(owner.loc) ? "floor" : "ground"] repeadetly.") : null, // not overengineered at all
		ignored_mobs = list(blood_slime.current_host)
	)

    if (!do_delay())
        return FALSE

    if (host.health < HEALTH_THRESHOLD_DEAD)
        owner.balloon_alert(owner, "too damaged!");

    blood_slime.subjugate_host()

    return TRUE
