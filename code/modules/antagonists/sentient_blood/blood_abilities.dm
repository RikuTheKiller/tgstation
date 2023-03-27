/datum/action/innate/sentient_blood_subjugate
    name = "Subjugate"
    desc = "Attempt to enter the bloodstream of a target to subjugate them."
    click_action = TRUE
    enable_text = "You start looking around for targets to subjugate. Click on a nearby wounded target to proceed."
    disable_text = "You resist your hunger for blood."
    ranged_mousepointer = 'icons/effects/mouse_pointers/blood_target.dmi'

/datum/action/innate/sentient_blood_subjugate/do_ability(mob/living/caller, atom/clicked_on)
    var/mob/living/basic/sentient_blood/user = caller
    var/mob/living/carbon/human/target = clicked_on

    if(!istype(user) || !istype(target))
        return FALSE
    if(!user.Adjacent(target))
        return FALSE
    var/datum/wound/largest_wound = get_most_bleeding_wound(target)
    if(!largest_wound || !largest_wound.blood_flow) //We're pretty sure that it has some blood flow, but better safe than dividing by 0, yeah?
        return FALSE
    if(!do_after(user, 20 SECONDS / largest_wound.blood_flow)) //Weeping avulsions, by default, have a bloow flow of 4. That means that if you land a melee, this only takes 5 seconds. On a conscious person this totals to 11 seconds.
        return FALSE

    user.subjugate(target) //Finally, we turn them into our host.
    return TRUE

///Gets the wound that is bleeding the most on the target.
/proc/get_most_bleeding_wound(mob/living/carbon/human/target)
    var/datum/wound/largest
    for(var/datum/wound/wound in target.all_wounds)
        if(wound.wound_type != WOUND_SLASH && wound.wound_type != WOUND_PIERCE)
            continue
        if(!largest || largest.blood_flow < wound.blood_flow)
            largest = wound
    if(!largest)
        return FALSE
    return largest
