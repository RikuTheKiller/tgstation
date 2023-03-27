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
    speed = 1

    damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, OXY = 0, STAMINA = 0, CLONE = 0) //Even though it doesn't use health, these still apply.
    unsuitable_atmos_damage = 0
    unsuitable_heat_damage = 0
    unsuitable_cold_damage = 0

    var/blood_amount = SENTIENT_BLOOD_MAX //Blood amount, handled by abilities and other conditions.
    var/current_size = RESIZE_DEFAULT_SIZE
    var/pause_size_updates = FALSE

//Here we store all of the variables associated with the host when we swap with them. Handled very similarly to split_personality.dm, I'm not reinventing the wheel.
    var/mob/living/carbon/human/host_body
    var/datum/mind/host_mind
    var/host_ckey
    var/host_ip
    var/host_computer_id

    var/datum/mind/actual_mind //References the original mind when they're outside of this mob, such as when they're inhabiting someone.

    var/datum/movespeed_modifier/blood_speed_modifier/blood_speed_modifier

/mob/living/basic/sentient_blood/Initialize(mapload)
    . = ..()

    blood_speed_modifier = new()
    add_movespeed_modifier(blood_speed_modifier, update = FALSE) //Handles modifying speed based on blood amount.

    ADD_TRAIT(src, TRAIT_MUTE, src) //Handled via traits since there is no other way to stop emotes and doing one of them via a proc and the other via a trait would be stupid.
    ADD_TRAIT(src, TRAIT_EMOTEMUTE, src)

    var/datum/action/innate/sentient_blood_subjugate/subjugate = new()
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
        if(!(chest.biological_state & BIO_FLESH) || !IS_ORGANIC_LIMB(chest) || HAS_TRAIT(target, TRAIT_NEVER_WOUNDED))
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
        if(!chest)
            return
        if(!(chest.biological_state & BIO_FLESH) || !IS_ORGANIC_LIMB(chest) || HAS_TRAIT(target, TRAIT_NEVER_WOUNDED))
            return

        if(wound_to_replace)
            wound_to_replace.replace_wound(/datum/wound/slash/critical)
        else
            var/datum/wound/slash/critical/wound_to_add = new()
            wound_to_add.apply_wound(chest)

/mob/living/basic/sentient_blood/Life(delta_time, times_fired)
    change_blood(-0.1 * delta_time)

/mob/living/basic/sentient_blood/adjust_health(amount, updating_health = TRUE, forced = FALSE)
    change_blood(-amount)

/mob/living/basic/sentient_blood/proc/on_eject()
    SIGNAL_HANDLER

    UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

///Changes the amount of blood the sentient blood mob has by the given amount. Maximum can be set to 0 to bypass it entirely.
/mob/living/basic/sentient_blood/proc/change_blood(amount, max = SENTIENT_BLOOD_MAX)
    if(!amount)
        return
    
    if(max > 0)
        blood_amount += clamp(amount, -blood_amount, max(max - blood_amount, 0))
    else
        blood_amount += amount
    
    update_blood()

///Sets the amount of blood the sentient blood mob has. Maximum can be set to 0 to bypass it entirely.
/mob/living/basic/sentient_blood/proc/set_blood(amount, max = SENTIENT_BLOOD_MAX)
    if(!amount)
        return

    if(max > 0)
        blood_amount = clamp(amount, 0, max)
    else
        blood_amount = min(amount, 0)

    update_blood()

/mob/living/basic/sentient_blood/proc/update_blood()
    if(!blood_amount)
        death()
        return
    
    add_or_update_variable_movespeed_modifier(blood_speed_modifier, TRUE, min(-0.6 + blood_amount / SENTIENT_BLOOD_MAX * 0.6, 0)) //0-60% speed boost based on blood amount.

    if(pause_size_updates)
        return
    var/newsize = 0.5 + blood_amount / SENTIENT_BLOOD_MAX * 0.5 //Near-zero blood makes it absolutely tiny.
    resize = newsize / current_size
    current_size = newsize
    update_transform()

///Actually subjugate a target. This is where the magic happens.
/mob/living/basic/sentient_blood/proc/subjugate(mob/living/carbon/human/target)
    var/datum/antagonist/sentient_blood/blood_antag = mind.has_antag_datum(/datum/antagonist/sentient_blood)

    if(!blood_antag)
        return

    if(target.mind)
        if(target.mind.active)
            blood_antag.subjugations += 1 //WOOOOO you took a sentient person over... on second thought that's pretty horrible. What have I made?
        target.ghostize(FALSE)

//Saving all of the host's variables.
    host_body = target
    host_mind = target.mind
    host_ip = target.lastKnownIP
    host_ckey = target.ckey
    host_computer_id = target.computer_id

//Moving our variables into the host's body.
    blood_antag.main_body = src
    actual_mind = mind
    target.mind = mind
    target.ckey = src.ckey
    target.computer_id = computer_id
    target.lastKnownIP = lastKnownIP

//Nulling our variables, these are returned if and when we come back. The only one left is lastKnownIP.
    mind = null
    src.ckey = null
    computer_id = null

//Moving the mob into the target to await it's reawakening.
    forceMove(target)
    RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_eject))

/datum/movespeed_modifier/blood_speed_modifier
    variable = TRUE
