/datum/action/cooldown/hemoparasite/delayed/relinquish
	name = "Relinquish Control"
	desc = "Stop controlling your host, allowing their lifeless body to drop dead to the ground once more. This is much slower in marionette."

/datum/action/cooldown/hemoparasite/delayed/relinquish/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = hemoparasite.host

	to_chat(owner, span_notice("You begin to relinquish control over your host..."))

	if (owner != host)
		to_chat(host, span_userdanger("You feel weak...")) // symbiosis

	host.emote("sway")

	var/delay = hemoparasite.current_state == HEMOPARASITE_STATE_MARIONETTE ? 5 SECONDS : 2 SECONDS

	if (!do_delay(owner, delay, target = host))
		if (owner != host)
			to_chat(host, span_boldnotice("You feel much better again!"))
		return FALSE

	hemoparasite.stop_host_control()
	host.death()
