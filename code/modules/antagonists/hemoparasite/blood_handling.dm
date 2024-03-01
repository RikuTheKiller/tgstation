// Collection of methods for handling hemoparasite blood amounts.

// Amounts (units of blood)

/// Gets the maximum blood amount of the hemoparasite itself.
/datum/antagonist/hemoparasite/proc/get_max_blood()
	. = BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

	if (current_state == HEMOPARASITE_STATE_SPLIT)
		. *= 0.5

/// Gets the maximum blood amount of the host. Prosthetics and missing limbs can't contain blood. (prosthetics since they can't bleed and would be OP otherwise)
/datum/antagonist/hemoparasite/proc/get_host_max_blood(mob/living/carbon/human/host_override = null)
	var/mob/living/carbon/human/target_host = host_override || host

	if (isnull(target_host))
		CRASH("[parasite] ([owner]) tried to check the maximum blood amount of a nonexistent host.")

	if (HAS_TRAIT(target_host, TRAIT_NOBLOOD))
		return 0

	. = BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

	if (current_state == HEMOPARASITE_STATE_SPLIT)
		. *= 0.5

	var/suitable_limbs = 0

	for (var/obj/item/bodypart/limb in target_host.bodyparts)
		if (!IS_ROBOTIC_LIMB(limb))
			suitable_limbs += 1

	// preparing for the day that we get more limbs (we probably wont, but magic numbers aren't great either)
	. = min(., BLOOD_VOLUME_HEMOPARASITE_MAXIMUM * suitable_limbs / (target_host.bodyparts.len + target_host.get_missing_limbs().len))

/// Returns how much blood the hemoparasite currently holds.
/datum/antagonist/hemoparasite/proc/get_blood_amount()
	return parasite.health * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM / parasite.maxHealth

/// Sets the blood amount of the hemoparasite to the given amount.
/datum/antagonist/hemoparasite/proc/set_blood_amount(amount, ignore_sync)
	parasite.setBruteLoss(clamp(parasite.maxHealth - amount * parasite.maxHealth / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, 0, parasite.maxHealth)) // it was bruteloss all along
	if (is_in_host() && !ignore_sync)
		set_host_blood_amount(amount, ignore_sync = TRUE)
	update_hudtext()

/// Adjusts the blood amount of the hemoparasite by the given amount.
/datum/antagonist/hemoparasite/proc/adjust_blood_amount(amount, ignore_sync)
	set_blood_amount(get_blood_amount() + amount, ignore_sync)

/// Returns the blood volume of the hemoparasite's host.
/datum/antagonist/hemoparasite/proc/get_host_blood_amount()
	return host ? clamp(host.blood_volume, 0, get_host_max_blood()) : 0

/// Sets the blood volume of the hemoparasite's host to the given amount.
/datum/antagonist/hemoparasite/proc/set_host_blood_amount(amount, ignore_sync)
	if (!host)
		return
	host.blood_volume = clamp(amount, 0, get_host_max_blood())
	if (is_in_host() && !ignore_sync)
		set_blood_amount(amount, ignore_sync = TRUE)

/// Adjusts the blood volume of the hemoparasite's host by the given amount.
/datum/antagonist/hemoparasite/proc/adjust_host_blood_amount(amount, ignore_sync)
	set_host_blood_amount(get_host_blood_amount() + amount, ignore_sync)

// Percentages (of BLOOD_VOLUME_HEMOPARASITE_MAXIMUM)

/// Returns the blood amount of the hemoparasite as a percentage. (0-1)
/datum/antagonist/hemoparasite/proc/get_blood_percentage()
	return get_blood_amount() / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

/// Sets the blood amount of the hemoparasite to the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/set_blood_percentage(percentage, ignore_sync)
	set_blood_amount(percentage * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, ignore_sync)

/// Adjusts the blood amount of the hemoparasite by the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/adjust_blood_percentage(percentage, ignore_sync)
	set_blood_percentage(get_blood_percentage() + percentage, ignore_sync)

/// Returns the blood volume of the hemoparasite's host as a percentage. (0-1)
/datum/antagonist/hemoparasite/proc/get_host_blood_percentage()
	return get_host_blood_amount() / BLOOD_VOLUME_HEMOPARASITE_MAXIMUM

/// Sets the blood volume of the hemoparasite's host to the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/set_host_blood_percentage(percentage, ignore_sync)
	set_host_blood_amount(percentage * BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, ignore_sync)

/// Adjusts the blood volume of the hemoparasite's host by the given percentage. (0-1)
/datum/antagonist/hemoparasite/proc/adjust_host_blood_percentage(percentage, ignore_sync)
	set_host_blood_percentage(get_host_blood_percentage() + percentage, ignore_sync)
