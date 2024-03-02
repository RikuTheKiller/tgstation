/datum/action/cooldown/hemoparasite/delayed/emerge
	name = "Emerge"
	desc = "Emerge from your host, leaving them bloodless in the process."
	button_icon_state = "blood_emerge"

/datum/action/cooldown/hemoparasite/delayed/emerge/Grant(mob/grant_to, datum/antagonist/hemoparasite/antag_override)
	. = ..()

	RegisterSignal(grant_to, COMSIG_ATOM_RELAYMOVE, PROC_REF(host_relaymove))

/datum/action/cooldown/hemoparasite/delayed/emerge/Remove(mob/removed_from)
	. = ..()

	UnregisterSignal(removed_from, COMSIG_ATOM_RELAYMOVE)

/datum/action/cooldown/hemoparasite/delayed/emerge/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = hemoparasite.host

	to_chat(owner, span_notice("You prepare to emerge from your host..."))

	if (owner != host)
		to_chat(host, span_userdanger("Your skin begins to turn pale!")) // symbiosis

	host.emote("tremble")

	host.set_jitter_if_lower(50 SECONDS)

	if (!do_delay(owner, 2 SECONDS, target = host))
		if (owner != host)
			to_chat(host, span_boldnotice("Your skin stops turning pale!"))
		return FALSE

	playsound(owner, 'sound/effects/butcher.ogg', 25, TRUE)
	playsound(owner, 'sound/effects/splat.ogg', 50, TRUE)

	hemoparasite.leave_host()

	return TRUE

/datum/action/cooldown/hemoparasite/delayed/emerge/proc/host_relaymove(mob/living/user, direction)
	if (user != owner)
		return
	owner.balloon_alert(owner, "can't move while in a body!")
	return COMSIG_BLOCK_RELAYMOVE
