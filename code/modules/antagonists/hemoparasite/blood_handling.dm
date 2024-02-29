// Collection of methods for handling hemoparasite blood amounts.

/// Gets the maximum blood amount of the slime itself.
/datum/antagonist/hemoparasite/proc/get_max_blood()
	. = BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

	if (current_state == HEMOPARASITE_STATE_SPLIT)
		. *= 0.5

/// Gets the maximum blood amount of the host. Prosthetics and missing limbs can't contain blood. (prosthetics since they can't bleed and would be OP otherwise)
/datum/antagonist/hemoparasite/proc/get_host_max_blood(mob/living/carbon/human/host_override = null)
	var/mob/living/carbon/human/host = host_override ? host_override : host

	if (!host)
		CRASH("[slime] ([owner]) tried to check the maximum blood amount of a nonexistent host.")

	if (HAS_TRAIT(host, TRAIT_NOBLOOD)) // also not checking for exotic blood is on purpose, clearly we suffice as liquid electricity (slimes have electric charge anyway)
		return 0

	. = BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

	if (current_state == HEMOPARASITE_STATE_SPLIT)
		. *= 0.5

	var/suitable_limbs = 0

	for (var/obj/item/bodypart/limb in host.bodyparts)
		if (!IS_ROBOTIC_LIMB(limb))
			suitable_limbs += 1

	// preparing for the day that we get more limbs (we probably wont, but magic numbers aren't great either)
	. = min(., BLOOD_VOLUME_HEMOPARASITE_MAXIMUM * suitable_limbs / (host.bodyparts.len + host.get_missing_limbs().len))

/// Returns how much blood the hemoparasite currently holds.
/datum/antagonist/hemoparasite/proc/get_blood_amount()
	return slime.health * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM / slime.maxHealth

/// Returns how much blood the hemoparasite currently holds as a percentage of BLOOD_VOLUME_HEMOPARASITE_MAXIMUM. (0-1)
/datum/antagonist/hemoparasite/proc/get_blood_percentage()
	return get_blood_amount() / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

/// Sets the blood amount of the hemoparasite to the given amount.
/datum/antagonist/hemoparasite/proc/set_blood_amount(amount, ignore_host_sync)
	slime.setBruteLoss(slime.maxHealth - amount * slime.maxHealth / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM) // it was bruteloss all along
	if (slime.loc == host && !ignore_host_sync)
		set_host_blood_amount(amount, ignore_slime_sync = TRUE)

/// Sets the blood amount of the hemoparasite to the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/set_blood_percentage(percentage, ignore_host_sync)
	set_blood_amount(percentage * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, ignore_host_sync)

/// Adjusts the blood amount of the hemoparasite by the given amount.
/datum/antagonist/hemoparasite/proc/adjust_blood_amount(amount, ignore_host_sync)
	set_blood_amount(get_blood_amount() + amount, ignore_host_sync)

/// Adjusts the blood amount of the hemoparasite by the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/adjust_blood_percentage(percentage, ignore_host_sync)
	set_blood_percentage(get_blood_percentage() + percentage, ignore_host_sync)

/// Returns how much blood the hemoparasite's host currently holds.
/datum/antagonist/hemoparasite/proc/get_host_blood_amount()
	return host ? clamp(host.blood_volume, 0, get_host_max_blood()) : 0

/// Returns how much blood the hemoparasite's host currently holds as a percentage of BLOOD_VOLUME_HEMOPARASITE_MAXIMUM. (0-1)
/datum/antagonist/hemoparasite/proc/get_host_blood_percentage()
	return get_host_blood_amount() / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

/// Sets the blood amount of the hemoparasite's host to the given amount.
/datum/antagonist/hemoparasite/proc/set_host_blood_amount(amount, ignore_slime_sync)
	if (!host)
		return
	host.blood_volume = clamp(amount, 0, get_host_max_blood())
	if (slime.loc == host && !ignore_slime_sync)
		set_blood_amount(amount, ignore_host_sync = TRUE)

/// Sets the blood amount of the hemoparasite's host to the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/set_host_blood_percentage(percentage, ignore_host_sync)
	set_host_blood_amount(percentage * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, ignore_host_sync)

/// Adjusts the blood amount of the hemoparasite's host by the given amount.
/datum/antagonist/hemoparasite/proc/adjust_host_blood_amount(amount, ignore_slime_sync)
	set_host_blood_amount(get_host_blood_amount() + amount, ignore_slime_sync)

/// Adjusts the blood amount of the hemoparasite's host by the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/adjust_host_blood_percentage(percentage, ignore_host_sync)
	set_host_blood_percentage(get_host_blood_percentage() + percentage, ignore_host_sync)
