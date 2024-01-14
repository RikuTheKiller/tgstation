/datum/action/bloodslime/delayed_host_action/subjugate
    name = "Subjugate"
    desc = "Take over your host's body and brain, acquiring a basic level of human intelligence. Only works on hosts that aren't overly injured."
    delay = 2 SECONDS

/datum/action/bloodslime/delayed_host_action/subjugate/Trigger(trigger_flags)
    . = ..()
    if (!.)
        return FALSE

    var/mob/living/carbon/human/host = blood_slime.current_host

    owner.visible_message(
		message = span_danger("[blood_slime.current_host] starts convulsing!"),
		self_message = span_notice("You begin circulating around in your host's body..."),
		blind_message = isturf(owner.loc) && owner.has_gravity() ? span_hear("You hear something hitting the [isfloorturf(owner.loc) ? "floor" : "ground"] repeadetly.") : null, // not overengineered at all
		ignored_mobs = list(blood_slime.current_host)
	)

    if (!do_delay())
        return FALSE

    

    return TRUE
