/datum/action/cooldown/sentient_blood_subjugate
    name = "Subjugate"
    desc = "Attempt to enter the bloodstream of a target to subjugate them."
    button_icon = 'icons/mob/actions/actions_sentient_blood.dmi'
    button_icon_state = "subjugate"
    background_icon_state = "bg_demon"
    overlay_icon_state = "bg_spell_border_active_red"
    ranged_mousepointer = 'icons/effects/mouse_pointers/blood_target.dmi'
    click_to_activate = TRUE
    unset_after_click = FALSE //We handle it ourselves since we transfer minds if we're successful.

/datum/action/cooldown/sentient_blood_subjugate/Activate(atom/target)
    . = ..()

    var/mob/living/basic/sentient_blood/user = owner
    var/mob/living/carbon/human/human_target = target

    if(!istype(user) || !istype(human_target) || !user.Adjacent(target) || !user.blood_antag)
        unset_click_ability(owner, refund_cooldown = TRUE)
        return FALSE
    if(IS_SUBJUGATED(human_target))
        to_chat(user, span_danger("[target] is already inhabited by one of your own."))
        return FALSE
    var/blood_id = human_target.get_blood_id()
    if((blood_id != /datum/reagent/blood && blood_id != /datum/reagent/blood/sentient) || HAS_TRAIT(target, TRAIT_NOBLOOD))
        to_chat(user, span_danger("[target]'s blood isn't compatible with you."))

    var/datum/wound/largest_wound = human_target.get_most_bleeding_wound()

    if(!largest_wound || !largest_wound.blood_flow) //We're pretty sure that it has some blood flow, but better safe than dividing by 0, yeah?
        unset_click_ability(owner, refund_cooldown = TRUE)
        return FALSE

    target.visible_message("\The [user] is trying to enter [target]!", "\The [user] is trying to enter \the [largest_wound] on your [largest_wound.limb]!")
    unset_click_ability(owner, refund_cooldown = TRUE)

    if(!do_after(user, 20 SECONDS / largest_wound.blood_flow)) //Weeping avulsions, by default, have a blood flow of 4. That means that if you land a melee, this only takes 5 seconds. On a conscious person this totals to 11 seconds.
        return FALSE
    if(!largest_wound) //Did someone heal the wound while we were trying to enter? Rude, but we can't enter what isn't there.
        return FALSE
    blood_id = human_target.get_blood_id()
    if((blood_id != /datum/reagent/blood && blood_id != /datum/reagent/blood/sentient) || HAS_TRAIT(target, TRAIT_NOBLOOD))
        to_chat(user, span_danger("[target]'s blood has somehow transformed while you were trying to enter. Curious."))
    if(IS_SUBJUGATED(human_target))
        to_chat(user, span_danger("You attempt to enter [target], but are met by another member of your species and evicted."))
        return FALSE

    target.visible_message("\The [user] enters [target]!", "You feel your consciousness fade as \the [user] enters your body...")
    human_target.emote("scream")
    return user.blood_antag.subjugate(human_target) //Finally, we turn them into our host.

/datum/action/innate/sentient_blood_emerge
    name = "Emerge"
    desc = "Tear your way out of your host."
    button_icon = 'icons/mob/actions/actions_sentient_blood.dmi'
    button_icon_state = "emerge"
    background_icon_state = "bg_demon"
    overlay_icon_state = "bg_spell_border_active_red"

/datum/action/innate/sentient_blood_emerge/Activate()
    var/mob/living/carbon/human/user = owner
    var/datum/antagonist/sentient_blood/blood_antag = user?.mind?.has_antag_datum(/datum/antagonist/sentient_blood)

    if(!user || !blood_antag)
        return FALSE

    blood_antag.release_host(wound = TRUE)

/datum/action/cooldown/sentient_blood_boost
    name = "Metabolic Boost"
    desc = "Accelerate your metabolism, draining blood in exchange for healing."
    button_icon = 'icons/mob/actions/actions_sentient_blood.dmi'
    button_icon_state = "boost"
    background_icon_state = "bg_demon"
    overlay_icon_state = "bg_spell_border_active_red"
    cooldown_rounding = 1
    cooldown_time = 5 MINUTES
    melee_cooldown_time = 0 SECONDS
    var/cost = 200

/datum/action/cooldown/sentient_blood_boost/update_button_status(atom/movable/screen/movable/action_button/button, force)
    ..()

    if(next_use_time > world.time)
        return

    button.maptext = MAPTEXT("<b>[cost]</b>")

/datum/action/cooldown/sentient_blood_boost/Activate()
    var/mob/living/carbon/human/user = owner
    var/datum/antagonist/sentient_blood/blood_antag = user?.mind?.has_antag_datum(/datum/antagonist/sentient_blood)

    if(!user || !blood_antag || user.health <= HEALTH_THRESHOLD_DEAD)
        return FALSE

    if(user.apply_status_effect(/datum/status_effect/sentient_blood_boost))
        blood_antag.change_blood(-cost)
        StartCooldown()

/datum/action/cooldown/sentient_blood_boost/IsAvailable(feedback = FALSE)
    var/mob/living/carbon/human/user = owner
    var/datum/antagonist/sentient_blood/blood_antag = user?.mind?.has_antag_datum(/datum/antagonist/sentient_blood)
    return ..() && blood_antag?.get_blood_amount() > cost
