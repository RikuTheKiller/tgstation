/datum/action/cooldown/hemoparasite/blood_barrage
	name = "Blood Barrage"
	desc = "Continuously turn yourself into infectious payloads to hurl at your target."

	/// The ranged attack component used alongside the autofire component. Saved for later deletion.
	var/datum/component/ranged_attacks/ranged

	/// The full auto component this uses to make the hemoparasite able to shoot. Saved for later deletion.
	var/datum/component/ranged_mob_full_auto/fullauto

/datum/action/cooldown/hemoparasite/blood_barrage/IsAvailable(feedback)
	return ..()

/datum/action/cooldown/hemoparasite/blood_barrage/Grant(mob/grant_to, datum/antagonist/hemoparasite/antag_override)
	. = ..()

	ranged = owner.AddComponent(
		/datum/component/ranged_attacks, \
		projectile_type = /obj/projectile/hemoparasite/barrage, \
		projectile_sound = 'sound/effects/wounds/blood3.ogg', \
		cooldown_time = 0.1 SECONDS, \
	)
	fullauto = owner.AddComponent(/datum/component/ranged_mob_full_auto, 0.1 SECONDS, src)

	RegisterSignal(owner, COMSIG_BASICMOB_PRE_ATTACK_RANGED, PROC_REF(check_can_fire))

/datum/action/cooldown/hemoparasite/blood_barrage/Remove(mob/removed_from)
	. = ..()

	clear_components()

/datum/action/cooldown/hemoparasite/blood_barrage/Destroy()
	. = ..()

	clear_components()

/datum/action/cooldown/hemoparasite/blood_barrage/proc/check_can_fire(datum/source)
	SIGNAL_HANDLER
	if (source != ranged)
		return
	if (!IsAvailable(feedback = TRUE))
		return COMPONENT_CANCEL_RANGED_ATTACK

/datum/action/cooldown/hemoparasite/blood_barrage/proc/clear_components()
	QDEL_NULL(ranged)
	QDEL_NULL(fullauto)

	UnregisterSignal(owner, list(COMSIG_BASICMOB_PRE_ATTACK_RANGED))
