/*
* ## Blood Slime
*
* Player-controlled horrid abominations originating from a failed NT cleaning experiment. They're nothing like their relatively docile ancestors.
*/

/mob/living/basic/blood_slime
    name = "blood slime"
    desc = "A horrid slime-like abomination that takes over the corpses of the deceased and feasts on their blood."
    icon_state = "blood_slime"
    icon_living = "blood_slime"
    icon_dead = "blood_slime_dead"
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

    unsuitable_atmos_damage = 0 // like regular slimes, it doesn't breathe
    unsuitable_heat_damage = 5 // due to being similar to human blood, it's vulnerable to heat
    unsuitable_cold_damage = 5 // the same similarity also dampens it's vulnerability to the cold
    minimum_survivable_temperature = 200 // increased cold resistance compared to regular slimes
    maximum_survivable_temperature = 500 // still retains most of its heat resistance
