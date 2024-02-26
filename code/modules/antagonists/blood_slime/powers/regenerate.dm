/datum/action/cooldown/blood_slime/regen
	name = "Regeneration"
	desc = "Rapidly consume yourself to heal your host. More efficient if your host is dead. Toggleable."

/datum/action/cooldown/blood_slime/regen/Activate(atom/target)
	. = ..()

	if (blood_slime.slime.has_status_effect(/datum/status_effect/blood_slime/regen))
		to_chat(owner, span_notice("You will no longer automatically heal your host."))
		blood_slime.slime.remove_status_effect(/datum/status_effect/blood_slime/regen)
	else
		to_chat(owner, span_notice("You will now automatically heal your host."))
		blood_slime.slime.apply_status_effect(/datum/status_effect/blood_slime/regen, blood_slime)

/datum/status_effect/blood_slime/regen
	id = "blood_slime_regen"

	/// How often we should notify the player of their regen status.
	var/update_frequency = 10 SECONDS

	/// The time when we will next notify the player of their regen status.
	var/next_update_time

/datum/status_effect/blood_slime/regen/on_apply()
	. = ..()

	if (!blood_slime?.current_host || !blood_slime?.owner?.current)
		return FALSE

/datum/status_effect/blood_slime/regen/tick(seconds_between_ticks)
	var/mob/living/carbon/human/host = blood_slime?.current_host
	var/mob/living/slime = blood_slime?.owner?.current

	if (!host || !slime || slime.stat == DEAD)
		qdel(src)
		return

	if (host.health >= host.maxHealth)
		return

	var/update = world.time >= next_update_time

	if (update)
		next_update_time = world.time + update_frequency

	if (blood_slime.get_blood_amount() < BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * 0.05) // less than 5% blood, don't regen
		if (update)
			to_chat(slime, span_danger("You have too little blood to sustain your regeneration."))
		return

	var/bloodloss = 0

	if (host.getOxyLoss() > 10) // less than 10 is insignificant (avoid wasting blood if its being outhealed by something else)
		host.adjustOxyLoss(-2 * seconds_between_ticks)
		bloodloss += BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * 0.01 // -1% blood per second
		if (update)
			to_chat(slime, span_boldnotice("Your regeneration is energizing your host's cells in place of oxygen."))

	if (host.getToxLoss() > 10) // less than 10 is insignificant (avoid wasting blood if its being outhealed by something else)
		host.adjustToxLoss(-2 * seconds_between_ticks)
		bloodloss += BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * 0.01 // -1% blood per second
		if (update)
			to_chat(slime, span_boldnotice("Your regeneration is detoxifying your host's cells."))

	var/damage = host.getBruteLoss() + host.getFireLoss()

	if (damage <= 0 && host.all_wounds.len <= 0)
		blood_slime.adjust_host_blood_amount(-bloodloss * seconds_between_ticks)
		return

	var/potency = 3 + damage * 0.01 * seconds_between_ticks

	bloodloss += BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * 0.004 * potency // -0.4% blood per second per potency (-2% at 200 damage)

	blood_slime.adjust_host_blood_amount(-bloodloss * seconds_between_ticks)

	if (host.stat == DEAD)
		potency *= 1.5

	host.adjustBruteLoss(-potency)
	host.adjustFireLoss(-potency)

	for (var/datum/wound/wound in host.all_wounds)
		wound.on_xadone(host.stat == DEAD ? 3 : 2) // if i ever rework med/chem im going to fix whatever the fuck this is (skeleton/plasmeme livers use this too)

	if (SPT_PROB(10, seconds_between_ticks))
		var/message = pick(list(
			"[host]'s wounds close as blood spreads all over them!",
			"Blood gathers on [host] as their flesh regenerates!",
			"[host] wounds are knitting shut as blood keeps pouring out!",
			"You see [host]'s blood turning into fresh skin and bone!",
			"Steam rises from [host]'s blood as it sizzles on their wounds!"
		))

		host.visible_message(
			message = span_danger(message),
			self_message = slime == host ? null : span_boldnotice("Your wounds are gushing far more blood than usual, yet somehow you feel better."),
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
