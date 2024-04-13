/datum/action/cooldown/hemoparasite/delayed/marionette
	name = "Marionette"
	desc = "Embed yourself deep into the hosts tissues, controlling them. In this state you are stun-immune, not dextrous and all damage is reflected as bloodloss."

/datum/action/cooldown/hemoparasite/delayed/marionette/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = hemoparasite.host

	owner.visible_message(
		message = span_danger("[host][host.p_s()] muscles tense up!"),
		self_message = span_notice("You begin to embed into your hosts tissues..."),
	)

	host.do_jitter_animation(200) // fluff

	if (!do_delay(owner, 2 SECONDS, target = host))
		owner.visible_message(span_notice("[host] eases up."))
		return FALSE

	owner.visible_message(
		message = span_danger("[host] staggers to their feet!"),
	)

	hemoparasite.marionette_host()

	return TRUE
