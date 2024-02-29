/datum/action/cooldown/hemoparasite/regen
	name = "Regeneration"
	desc = "Rapidly consume yourself to heal your host. More efficient if your host is dead."

/datum/action/cooldown/hemoparasite/regen/Activate(atom/target)
	. = ..()

	if (hemoparasite.slime.has_status_effect(/datum/status_effect/hemoparasite/regen))
		to_chat(owner, span_notice("You will no longer automatically heal your host."))
		hemoparasite.slime.remove_status_effect(/datum/status_effect/hemoparasite/regen)
	else
		to_chat(owner, span_notice("You will now automatically heal your host."))
		hemoparasite.slime.apply_status_effect(/datum/status_effect/hemoparasite/regen, hemoparasite)

/datum/status_effect/hemoparasite/regen
	id = "hemoparasite_regen"

	/// How often we should notify the player of their regen status.
	var/update_frequency = 15 SECONDS

	/// The time when we will next notify the player of their regen status.
	var/next_update_time

/datum/status_effect/hemoparasite/regen/on_apply()
	. = ..()

	if (!hemoparasite?.host || !hemoparasite?.owner?.current)
		return FALSE

/datum/status_effect/hemoparasite/regen/tick(seconds_between_ticks)
	var/mob/living/carbon/human/host = hemoparasite?.host
	var/mob/living/slime = hemoparasite?.owner?.current

	if (!host || !slime || slime.stat == DEAD)
		qdel(src)
		return

	if (host.health >= host.maxHealth)
		return

	var/update = world.time >= next_update_time

	if (update)
		next_update_time = world.time + update_frequency

	if (hemoparasite.get_host_blood_percentage() <= 0.05) // 5% blood or less, stall
		if (update)
			to_chat(slime, span_danger("Your regeneration stalls due to a lack of blood."))
		return

	var/bloodloss = 0

	if (host.getOxyLoss() > 10) // less than 10 is insignificant as it heals on its own if possible
		host.adjustOxyLoss(-2 * seconds_between_ticks)
		bloodloss += 0.01 // -1% blood per second
		if (update)
			to_chat(slime, span_boldnotice("Your regeneration is reoxygenating your host."))

	if (host.getToxLoss() > 0) // does not heal on it's own
		host.adjustToxLoss(-2 * seconds_between_ticks)
		bloodloss += 0.01 // -1% blood per second
		if (update)
			to_chat(slime, span_boldnotice("Your regeneration is detoxifying your host."))

	var/damage = host.getBruteLoss() + host.getFireLoss()

	if (damage <= 0 && host.all_wounds.len <= 0)
		hemoparasite.adjust_host_blood_amount(-bloodloss * seconds_between_ticks)
		return

	var/potency = 3 + damage * 0.01 * seconds_between_ticks

	bloodloss += 0.004 * potency // -0.4% blood per second per potency (-2% at 200 damage)

	hemoparasite.set_host_blood_percentage(max(hemoparasite.get_host_blood_percentage() - bloodloss * seconds_between_ticks, 0.04)) // make sure we don't kill ourselves

	if (host.stat == DEAD)
		potency *= 1.5

	host.adjustBruteLoss(-potency)
	host.adjustFireLoss(-potency)

	for (var/datum/wound/wound in host.all_wounds)
		wound.on_xadone(host.stat == DEAD ? 3 : 2) // if i ever rework med/chem im going to fix whatever the fuck this is (skeleton/plasmeme livers use this too)

	if (SPT_PROB(10, seconds_between_ticks))
		var/message = pick(list(
			"[host]'s wounds are closing up as unnatural amounts of blood spray out!",
			"[host]'s flesh regenerates as blood surfaces from it!",
			"[host] wounds are knitting shut as blood keeps pouring out!",
			"[host] blood is turning into fresh skin and bone!",
			"[host]'s blood sizzles all over their wounds as they are clamped shut!"
		))

		host.visible_message(
			message = span_warning(message),
			self_message = slime == host ? null : span_boldnotice("[hemoparasite.body] is consuming itself to ."),
			blind_message = span_hear("You hear liquid bubbling and sizzling."),
			ignored_mobs = slime
		)

	if (!update)
		return

	var/slime_message = "Your regeneration is "

	switch (damage)
		if (-INFINITY to 100)
			slime_message += "slowly mending your injured host."
		if (100 to 200)
			slime_message += "quickly mending your mangled host."
		if (200 to INFINITY)
			slime_message += "in overdrive as it mends your unrecognizable wreck of a host."

	to_chat(slime, span_boldnotice(slime_message))
