/*
* ## Blood Slime
*
* Player-controlled horrid abominations originating from a failed NT cleaning experiment. They're nothing like their relatively docile ancestors.
*/

/mob/living/basic/blood_slime
	name = "blood slime"
	desc = "A horrid slime-like abomination that takes over the corpses of the deceased and feasts on their blood."
	icon = 'icons/mob/nonhuman-player/blood_slime.dmi'
	icon_state = "large"
	icon_living = "large"
	icon_dead = "dead"
	gender = NEUTER
	mob_biotypes = MOB_SLIME
	faction = list(FACTION_SLIME, FACTION_HOSTILE)
	status_flags = NONE

	health = 200
	maxHealth = 200
	damage_coeff = list(BRUTE = 1, BURN = 0.75, TOX = 1, STAMINA = 0, OXY = 0)

	melee_damage_lower = 20
	melee_damage_upper = 30
	obj_damage = 30
	melee_attack_cooldown = CLICK_CD_MELEE
	wound_bonus = 0 // getting hit by a mass of hardened blood is bound to break some bones (also encourages finding pristine corpses rather than creating mangled ones)

	attack_verb_continuous = "hardens and strikes" // unlike regular slimes, it's objective is killing rather than eating
	attack_verb_simple = "harden and strike"
	response_help_continuous = "pets"
	response_help_simple = "pet"

	speak_emote = list("blorbles")
	attack_vis_effect = ATTACK_EFFECT_SMASH

	lighting_cutoff_red = 30
	lighting_cutoff_green = 5
	lighting_cutoff_blue = 20

	unsuitable_atmos_damage = 0
	unsuitable_heat_damage = 5
	unsuitable_cold_damage = 5
	minimum_survivable_temperature = 200
	maximum_survivable_temperature = 500

	/// If we're currently small or not. Used for animations.
	var/small = FALSE

	/// The health threshold below which we automatically become small.
	var/small_threshold = 80

	/// Our antag datum.
	var/datum/antagonist/blood_slime/blood_slime

/mob/living/basic/blood_slime/mind_initialize()
	..()

	blood_slime = mind.has_antag_datum(/datum/antagonist/blood_slime);

	if(!blood_slime)
		blood_slime = mind.add_antag_datum(/datum/antagonist/blood_slime)
		mind.set_assigned_role(SSjob.GetJobType(/datum/job/bloodslime))
		mind.special_role = ROLE_BLOOD_SLIME_MIDROUND

	RegisterSignal(blood_slime, COMSIG_BS_BLOOD_AMOUNT_CHANGED, PROC_REF(on_blood_amount_changed))

/mob/living/basic/blood_slime/updatehealth()
	. = ..()

	if (health < small_threshold && !small)
		become_small()
	else if (health >= small_threshold)
		become_big()

	blood_slime.set_blood_amount(health * BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM / maxHealth)

/// Makes the blood slime turn small with an animation.
/mob/living/basic/blood_slime/proc/become_small()
	return

/// Makes the blood slime turn big with an animation.
/mob/living/basic/blood_slime/proc/become_big()
	return

/mob/living/basic/blood_slime/proc/on_blood_amount_changed(amount)
	set_health(amount * maxHealth / BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM)
