///Almost exclusively handled by /proc/convert_blood_to_sentient() in blood_antag.dm
/datum/status_effect/sentient_blood_conversion
    status_type = STATUS_EFFECT_UNIQUE
    tick_interval = 0.5 SECONDS
    alert_type = null

    var/mob/living/carbon/human/human_owner
    var/last_blood_volume = BLOOD_VOLUME_NORMAL
    var/converted = 0 //How much of the owner's blood has been converted in units.

/datum/status_effect/sentient_blood_conversion/on_apply()
    human_owner = owner
    last_blood_volume = human_owner.blood_volume

/datum/status_effect/sentient_blood_conversion/tick(delta_time, times_fired)
    if(!istype(human_owner))
        return

    if(human_owner.stat != DEAD)
        converted += human_owner.blood_volume / 300 * delta_time //5 minutes for full conversion.
    else
        converted -= human_owner.blood_volume / 1200 * delta_time //20 minutes for full deconversion.

    update_blood()

/datum/status_effect/sentient_blood_conversion/proc/update_blood()
    converted -= max(last_blood_volume - human_owner.blood_volume, 0)
    last_blood_volume = human_owner.blood_volume

    if(converted <= 0)
        convert_sentient_to_blood(human_owner)
        qdel(src)
        return

/datum/status_effect/sentient_blood_boost
    status_type = STATUS_EFFECT_REPLACE
    tick_interval = 0.5 SECONDS
    duration = 20 SECONDS
    alert_type = /atom/movable/screen/alert/status_effect/sentient_blood_boost

    var/mob/living/carbon/human/human_owner

/datum/status_effect/sentient_blood_boost/on_apply()
    human_owner = owner
    to_chat(human_owner, span_notice("Your metabolism speeds up."))
    return TRUE

/datum/status_effect/sentient_blood_boost/on_remove()
    to_chat(human_owner, span_notice("Your metabolism calms back down."))
    return TRUE

/datum/status_effect/sentient_blood_boost/tick(delta_time, times_fired)
    if(human_owner.health <= HEALTH_THRESHOLD_DEAD || !istype(human_owner))
        qdel(src)
        return

    if(DT_PROB(30, delta_time))
        human_owner.visible_message(span_danger("[owner]'s skin pulses with a warm red glow."), span_notice("Your wounds are rapidly disappearing."))

    //Totals to 100 healing over the course of 20 seconds.
    human_owner.adjustBruteLoss(-5 * delta_time)
    human_owner.adjustFireLoss(-5 * delta_time)
    human_owner.adjustToxLoss(-5 * delta_time)
    human_owner.adjustOxyLoss(-5 * delta_time)

    for(var/datum/wound/wound in human_owner.all_wounds)
        if(wound.wound_type == WOUND_SLASH)
            wound.adjust_blood_flow(-0.2 * delta_time)

/atom/movable/screen/alert/status_effect/sentient_blood_boost
    name = "Metabolic Boost"
    desc = "Your metabolism is in overdrive, massively boosting your regeneration."
    icon_state = "sentient_blood_boost"
