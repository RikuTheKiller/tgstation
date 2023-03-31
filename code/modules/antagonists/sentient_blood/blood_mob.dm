/mob/living/basic/sentient_blood
    name = "sentient blood"
    desc = "A sentient puddle of blood that can move at blistering speeds. This seems to be the main body and it's fucking terrifying."
    icon = 'icons/mob/nonhuman-player/sentient_blood.dmi'
    icon_state = "sentientblood"
    density = FALSE
    living_flags = NONE
    basic_mob_flags = DEL_ON_DEATH
    mob_size = MOB_SIZE_SMALL
    pass_flags = PASSTABLE | PASSDOORS | PASSGRILLE | PASSMOB | PASSFLAPS | PASSWINDOOR //We squeeze through everything like a true menace.
    layer = BELOW_MOB_LAYER
    health = INFINITY //We use the amount of blood we have as a metric for health, so the health variable is useless.
    maxHealth = INFINITY
    speed = 0.6

    damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, OXY = 0, STAMINA = 0, CLONE = 0) //Even though it doesn't use health, these still apply.
    unsuitable_atmos_damage = 0
    unsuitable_heat_damage = 0
    unsuitable_cold_damage = 0

    var/current_size = RESIZE_DEFAULT_SIZE
    var/pause_life_updates = FALSE

    var/datum/antagonist/sentient_blood/blood_antag //Stores a reference to our antag datum.

    var/datum/movespeed_modifier/blood_speed_modifier/blood_speed_modifier

/mob/living/basic/sentient_blood/New(datum/antagonist/sentient_blood/antag_datum)
    . = ..()

    blood_antag = antag_datum

/mob/living/basic/sentient_blood/Initialize(mapload)
    . = ..()

    blood_speed_modifier = new()
    add_movespeed_modifier(blood_speed_modifier, update = FALSE) //Handles modifying speed based on blood amount.

    ADD_TRAIT(src, TRAIT_MUTE, src) //Handled via traits since there is no other way to stop emotes and doing one of them via a proc and the other via a trait would be stupid.
    ADD_TRAIT(src, TRAIT_EMOTEMUTE, src)

    var/datum/action/cooldown/sentient_blood_subjugate/subjugate = new()
    subjugate.Grant(src)

/mob/living/basic/sentient_blood/Destroy()
    . = ..()

    UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

/mob/living/basic/sentient_blood/melee_attack(atom/target, list/modifiers)
    . = ..()

    var/mob/living/carbon/human/human_target = target
    if(istype(human_target))
        var/obj/item/bodypart/chest = human_target.get_bodypart(BODY_ZONE_CHEST)

        if(!chest)
            return
        if(!(chest.biological_state & BIO_FLESH) || !IS_ORGANIC_LIMB(chest) || HAS_TRAIT(target, TRAIT_NEVER_WOUNDED) || HAS_TRAIT(target, TRAIT_NOBLOOD))
            return

        var/datum/wound/wound_to_replace
        for(var/datum/wound/existing_wound in chest.wounds)
            if(existing_wound.wound_type == WOUND_SLASH)
                if(existing_wound.severity >= WOUND_SEVERITY_CRITICAL)
                    return
                wound_to_replace = existing_wound
                break

        target.visible_message(span_danger("\The [src] is trying to slice [target]'s chest wide open!"), span_userdanger("\The [src] is trying to slice your chest wide open!"), span_danger("You hear aggressive slicing!"))
        playsound(target, 'sound/surgery/scalpel1.ogg', 75, TRUE, falloff_exponent = 12, falloff_distance = 1) //Plays the sound made when you start an incision step.
        human_target.emote("scream")

        if(!do_after(src, human_target.stat == CONSCIOUS ? 6 SECONDS : 3 SECONDS, target))
            return
        if(!chest || !(chest.biological_state & BIO_FLESH) || !IS_ORGANIC_LIMB(chest) || HAS_TRAIT(target, TRAIT_NEVER_WOUNDED))
            return

        var/datum/wound/slash/critical/wound_to_add = new()
        wound_to_add.occur_text = "is sliced wide open, spraying blood wildly"
        wound_to_add.apply_wound(chest, old_wound = wound_to_replace)

/mob/living/basic/sentient_blood/Life(delta_time, times_fired)
    . = ..()

    if(pause_life_updates)
        return

    blood_antag.change_blood(-0.1 * delta_time)

    update_blood()

/mob/living/basic/sentient_blood/adjust_health(amount, updating_health = TRUE, forced = FALSE)
    blood_antag.change_blood(-amount)

    update_blood()

/mob/living/basic/sentient_blood/proc/update_blood()
    if(!blood_antag.get_blood_amount())
        death()
        return
    
    add_or_update_variable_movespeed_modifier(blood_speed_modifier, TRUE, min(-0.5 + blood_antag.get_blood_amount() / BLOOD_VOLUME_NORMAL * 0.5, 0)) //0-50% speed boost based on blood amount.
    var/newsize = 0.5 + blood_antag.get_blood_amount() / BLOOD_VOLUME_NORMAL * 0.5 //Near-zero blood makes it absolutely tiny.
    resize = newsize / current_size
    current_size = newsize
    update_transform()

/datum/movespeed_modifier/blood_speed_modifier
    variable = TRUE
