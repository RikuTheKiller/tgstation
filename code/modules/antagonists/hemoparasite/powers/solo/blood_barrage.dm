/datum/action/cooldown/hemoparasite/blood_barrage
	name = "Blood Barrage"
	desc = "Continuously turn yourself into infectious payloads to hurl at your target."
	cost = 0.02 // -2% blood per shot

	/// The ranged attack component used alongside the autofire component. Saved for later deletion.
	var/datum/component/ranged_attacks/ranged

	/// The full auto component this uses to make the hemoparasite able to shoot. Saved for later deletion.
	var/datum/component/ranged_mob_full_auto/fullauto

/datum/action/cooldown/hemoparasite/blood_barrage/Grant(mob/grant_to, datum/antagonist/hemoparasite/antag_override)
	. = ..()

	ranged = owner.AddComponent(
		/datum/component/ranged_attacks, \
		projectile_type = /obj/projectile/hemoparasite/barrage, \
		projectile_sound = 'sound/effects/wounds/blood3.ogg', \
		cooldown_time = 0.1 SECONDS, \
	)
	fullauto = owner.AddComponent(/datum/component/ranged_mob_full_auto, 0.1 SECONDS)

	RegisterSignal(owner, COMSIG_BASICMOB_PRE_ATTACK_RANGED, PROC_REF(check_can_fire))
	RegisterSignal(owner, COMSIG_BASICMOB_POST_ATTACK_RANGED, PROC_REF(handle_cost))

/datum/action/cooldown/hemoparasite/blood_barrage/Remove(mob/removed_from)
	. = ..()

	QDEL_NULL(ranged)
	QDEL_NULL(fullauto)

	UnregisterSignal(removed_from, list(COMSIG_BASICMOB_PRE_ATTACK_RANGED, COMSIG_BASICMOB_POST_ATTACK_RANGED))

/datum/action/cooldown/hemoparasite/blood_barrage/proc/check_can_fire(datum/source)
	SIGNAL_HANDLER
	if (source != ranged)
		return COMPONENT_CANCEL_RANGED_ATTACK
	if (!IsAvailable(feedback = TRUE))
		return COMPONENT_CANCEL_RANGED_ATTACK

/datum/action/cooldown/hemoparasite/blood_barrage/proc/handle_cost(datum/source)
	SIGNAL_HANDLER
	if (source != ranged)
		return
	hemoparasite.adjust_blood_percentage(-cost)
