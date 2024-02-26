/datum/action/cooldown/blood_slime/delayed/emerge
	name = "Emerge"
	desc = "Emerge from your host, leaving them bloodless in the process."

/datum/action/cooldown/blood_slime/delayed/emerge/Grant(mob/grant_to, datum/antagonist/blood_slime/antag_override)
	. = ..()

	RegisterSignal(grant_to, COMSIG_ATOM_RELAYMOVE, PROC_REF(host_relaymove))

/datum/action/cooldown/blood_slime/delayed/emerge/Remove(mob/removed_from)
	. = ..()

	UnregisterSignal(removed_from, COMSIG_ATOM_RELAYMOVE)

/datum/action/cooldown/blood_slime/delayed/emerge/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/human/host = blood_slime.current_host

	owner.visible_message(
		span_danger("[host] begins to turn pale!"),
		span_notice("You prepare to emerge from your host..."),
		ignored_mobs = host
	)

	if (owner != host)
		to_chat(host, span_userdanger("Your skin begins to turn pale!")) // symbiosis

	host.emote("tremble")

	host.set_jitter_if_lower(50 SECONDS)

	if (!do_delay(owner, 2 SECONDS, target = host))
		return FALSE

	playsound(owner, 'sound/effects/butcher.ogg', 25, TRUE)
	playsound(owner, 'sound/effects/splat.ogg', 50, TRUE)

	blood_slime.leave_host()

	return TRUE

/datum/action/cooldown/blood_slime/delayed/emerge/proc/host_relaymove(mob/living/user, direction)
	if (user != owner)
		return
	owner.balloon_alert(owner, "can't move while in a body!")
	return COMSIG_BLOCK_RELAYMOVE
