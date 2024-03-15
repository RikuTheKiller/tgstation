/*
* ## Hemoparasite
*
* Player-controlled horrid abominations originating from a failed NT cleaning experiment. They're nothing like their relatively docile ancestors.
*/

/mob/living/basic/hemoparasite
	name = "hemoparasite" // sentient blood real???
	desc = "A horrid abomination that takes over the corpses of the deceased and feasts on their blood."
	icon = 'icons/mob/nonhuman-player/hemoparasite.dmi'
	icon_state = "glob"
	icon_living = "glob"
	icon_dead = "glob_dead"
	gender = NEUTER
	mob_biotypes = MOB_SLIME
	faction = list(FACTION_SLIME, FACTION_HOSTILE)
	status_flags = NONE

	health = 200
	maxHealth = 200
	damage_coeff = list(BRUTE = 1, BURN = 0.75, TOX = 1, STAMINA = 0, OXY = 0)

	melee_damage_lower = 15
	melee_damage_upper = 25
	obj_damage = 30
	melee_attack_cooldown = CLICK_CD_MELEE
	wound_bonus = 0 // getting hit by a mass of hardened blood is bound to break some bones (also encourages finding pristine corpses rather than creating mangled ones)

	attack_verb_continuous = "hardens and strikes"
	attack_verb_simple = "harden and strike"
	response_help_continuous = "pets"
	response_help_simple = "pet"

	speak_emote = list("blorbles")
	attack_vis_effect = ATTACK_EFFECT_SMASH
	attack_sound = 'sound/weapons/genhit1.ogg'

	initial_language_holder = /datum/language_holder/slime // perfect for us, can understand slime and common but can only speak slime

	// vivid red
	lighting_cutoff_red = 40
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 15

	unsuitable_atmos_damage = 0
	unsuitable_heat_damage = 5
	unsuitable_cold_damage = 5
	minimum_survivable_temperature = 200
	maximum_survivable_temperature = 500

	/// Our antag datum.
	var/datum/antagonist/hemoparasite/hemoparasite

/mob/living/basic/hemoparasite/Initialize(mapload)
	. = ..()

	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/basic/hemoparasite/get_status_tab_items()
	. = ..()
	if(isnull(hemoparasite))
		return
	. += "Blood: [hemoparasite.get_blood_amount()]/[hemoparasite.get_max_blood()]"
	if(isnull(hemoparasite.host))
		return
	. += "Host Blood: [hemoparasite.get_host_blood_amount()]"

/mob/living/basic/hemoparasite/mind_initialize()
	..()

	hemoparasite = mind.has_antag_datum(/datum/antagonist/hemoparasite)

	if(!hemoparasite)
		hemoparasite = mind.add_antag_datum(/datum/antagonist/hemoparasite)
		mind.set_assigned_role(SSjob.GetJobType(/datum/job/hemoparasite))
		mind.special_role = ROLE_HEMOPARASITE_MIDROUND
