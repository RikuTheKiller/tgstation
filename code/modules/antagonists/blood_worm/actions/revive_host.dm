/datum/action/cooldown/mob_cooldown/blood_worm_revive
	name = "Revive Host"
	desc = "Restart the blood circulation of your host, bringing them back to life."

	cooldown_time = 30 SECONDS
	shared_cooldown = NONE

	click_to_activate = FALSE

	check_flags = NONE

/datum/action/cooldown/mob_cooldown/blood_worm_revive/IsAvailable(feedback)
	if (!ishuman(owner) && !istype(owner, /mob/living/basic/blood_worm))
		return FALSE

	var/mob/living/basic/blood_worm/worm = target
	var/mob/living/carbon/human/host = worm.host

	if (!run_checks(worm, host, feedback))
		return FALSE

	return ..()

/datum/action/cooldown/mob_cooldown/blood_worm_revive/Activate(atom/target)
	var/mob/living/basic/blood_worm/worm = target
	var/mob/living/carbon/human/host = worm.host

	to_chat(owner, span_danger("You begin restarting \the [host]'s blood circulation..."))

	for (var/i in 1 to 3)
		if (!do_after(owner, 2 SECONDS, host, timed_action_flags = IGNORE_INCAPACITATED | IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(run_checks), worm, host)))
			host.balloon_alert(owner, "interrupted!")
			return FALSE

		playsound(host, 'sound/effects/singlebeat.ogg', vol = 50, vary = TRUE)

		var/original_transform = host.transform
		animate(host, transform = host.transform.Translate(0, 3), time = 0.2 SECONDS, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
		animate(transform = original_transform, time = 0.2 SECONDS, easing = CUBIC_EASING | EASE_IN, flags = ANIMATION_PARALLEL)

		host.visible_message(
			message = span_danger("\The [host] shake[host.p_s()] violently!"),
			ignored_mobs = owner
		)

	if (!host.revive())
		host.balloon_alert(owner, "revival failed!")
		return FALSE

	host.visible_message(
		message = span_danger("\The [host] rise[host.p_s()] from the dead!"),
		ignored_mobs = owner
	)

	to_chat(owner, span_green("You successfully revive \the [host]!"))

	return ..()

/datum/action/cooldown/mob_cooldown/blood_worm_revive/proc/run_checks(mob/living/basic/blood_worm/worm, mob/living/carbon/human/host, feedback = FALSE)
	if (!worm.host)
		return FALSE
	if (host.stat != DEAD)
		if (feedback)
			host.balloon_alert(owner, "not dead!")
		return FALSE
	if (HAS_TRAIT(host, TRAIT_HUSK))
		if (feedback)
			host.balloon_alert(owner, "husked!")
		return FALSE
	if (!host.get_organ_by_type(/obj/item/organ/brain))
		if (feedback)
			host.balloon_alert(owner, "no brain!")
		return FALSE
	if (host.health <= HEALTH_THRESHOLD_DEAD)
		if (feedback)
			host.balloon_alert(owner, "too damaged!")
		return FALSE
	if (!host.can_be_revived()) // Fallback, ideally caught by earlier, more descriptive checks.
		if (feedback)
			host.balloon_alert(owner, "unable to revive!")
		return FALSE
	return TRUE
