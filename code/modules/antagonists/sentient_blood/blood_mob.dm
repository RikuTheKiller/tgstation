/mob/living/basic/sentient_blood
    name = "sentient blood"
    desc = "A sentient puddle of blood that can move at blistering speeds. This seems to be the main body and it's fucking terrifying."
    icon = 'icons/mob/nonhuman-player/sentient_blood.dmi'
    icon_state = "sentientblood"
    density = FALSE
    living_flags = NONE
    basic_mob_flags = DEL_ON_DEATH
    pass_flags = PASSTABLE | PASSDOORS | PASSGRILLE | PASSMOB | PASSFLAPS | PASSWINDOOR
    layer = BELOW_OPEN_DOOR_LAYER //Doesn't actually work due to FOV being a thing.
    health = INFINITY //We use the amount of blood we have as a metric for health, so the health variable is useless.
    maxHealth = INFINITY
    speed = 1

    damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, OXY = 0, STAMINA = 0, CLONE = 0) //Even though it doesn't use health, these are used for blood damage multiplication.
    unsuitable_atmos_damage = 0
    unsuitable_heat_damage = 0
    unsuitable_cold_damage = 0

    var/blood_amount = 100
    var/max_blood_amount = 100
    var/current_size = RESIZE_DEFAULT_SIZE
    var/datum/movespeed_modifier/blood_speed_modifier/blood_speed_modifier

/mob/living/basic/sentient_blood/Initialize(mapload)
    . = ..()
    blood_speed_modifier = new()
    add_movespeed_modifier(blood_speed_modifier, update = FALSE)
    ADD_TRAIT(src, TRAIT_MUTE, src) //Handled via traits since there is no other way to stop emotes and doing one of them via a proc and the other via a trait would be stupid.
    ADD_TRAIT(src, TRAIT_EMOTEMUTE, src)

/mob/living/basic/sentient_blood/Life(delta_time, times_fired)
    change_blood(-0.1 * delta_time)

/mob/living/basic/sentient_blood/adjust_health(amount, updating_health = TRUE, forced = FALSE)
    change_blood(-amount)

/mob/living/basic/sentient_blood/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null, filterproof = null, message_range = 7, datum/saymode/saymode = null)
    return FALSE //We cannot talk, simple as that.

/mob/living/basic/sentient_blood/proc/change_blood(amount)
    if(!amount)
        return
    blood_amount += amount
    blood_amount = clamp(blood_amount, 0, max_blood_amount)
    update_blood()

/mob/living/basic/sentient_blood/proc/update_blood()
    if(!blood_amount)
        death()
        return
    var/newsize = 0.5 + blood_amount / max_blood_amount * 0.5 //Near-zero blood_amount makes it absolutely tiny.
    resize = newsize / current_size
    current_size = newsize
    update_transform()
    add_or_update_variable_movespeed_modifier(blood_speed_modifier, TRUE, -0.6 + blood_amount / max_blood_amount * 0.6) //0-60% speed boost based on blood_amount.

/datum/movespeed_modifier/blood_speed_modifier
    variable = TRUE
