/datum/antagonist/sentient_blood
    name = "Sentient Blood"
    antagpanel_category = ANTAG_GROUP_BIOHAZARDS
    show_to_ghosts = TRUE

    var/subjugations = 0

    var/mob/living/basic/sentient_blood/main_body //Stores the original body of the sentient blood.
    var/mob/living/carbon/human/host //Stores the host while we're subjugating them.
    var/datum/mind/host_mind //Stores the original mind of a host while we're subjugating them.

    var/datum/reagents/blood_holder //Used to gauge how much blood we have when we are NOT in a host. Use get_blood_amount() instead of reading it from this directly.

    var/static/list/host_traits = list( //One hell of a cocktail.
        TRAIT_NODEATH,
        TRAIT_NOHARDCRIT,
        TRAIT_NOSOFTCRIT,
        TRAIT_NOCRITOVERLAY,
        TRAIT_IGNOREDAMAGESLOWDOWN,
        TRAIT_MUTE,
        TRAIT_SLEEPIMMUNE,
        TRAIT_NOPASSOUT,
        TRAIT_NOFLASH,
        TRAIT_NOBANG,
        TRAIT_NOBLIND,
        TRAIT_NODEAF,
        TRAIT_NOHUNGER,
        TRAIT_NOEYEBLUR,
        TRAIT_NEARSIGHTED_CORRECTED,
        TRAIT_NOLIMBDISABLE,
        TRAIT_STABLEHEART,
    )
    var/static/list/host_dead_traits = list(
        TRAIT_FAKEDEATH,
        TRAIT_NOMETABOLISM,
    )

    var/datum/action/innate/sentient_blood_emerge/emerge

/datum/antagonist/sentient_blood/on_gain()
    . = ..()

    blood_holder = new(BLOOD_VOLUME_NORMAL)
    blood_holder.add_reagent(/datum/reagent/blood/sentient, BLOOD_VOLUME_NORMAL)

    var/mob/living/basic/sentient_blood/blood_mob = new(src)
    blood_mob.forceMove(owner.current.drop_location())
    owner.transfer_to(blood_mob, TRUE)
    main_body = blood_mob

    owner.set_assigned_role(SSjob.GetJobType(/datum/job/sentient_blood))
    owner.special_role = ROLE_SENTIENT_BLOOD

    var/datum/objective/objective = new /datum/objective/subjugate_hosts()
    objective.owner = owner
    objectives += objective
    objective = new /datum/objective/survive()
    objective.owner = owner
    objectives += objective

    emerge = new()

/datum/antagonist/sentient_blood/greet()
	. = ..()

	to_chat(owner.current, span_notice("Slither your way around the station while feeding off the crew's blood."))
	owner.announce_objectives()

///Actually subjugate a target. Returns whether or not it was successful.
/datum/antagonist/sentient_blood/proc/subjugate(mob/living/carbon/human/target)
    if(!target)
        return FALSE

    var/blood_id = target.get_blood_id()
    if((blood_id != /datum/reagent/blood && blood_id != /datum/reagent/blood/sentient) || HAS_TRAIT(target, TRAIT_NOBLOOD))
        return FALSE

    host = target
    host_mind = target.mind
    owner.transfer_to(host, force_key_move = TRUE)

    main_body.pause_life_updates = TRUE //We don't want to lose blood over time while inside.
    main_body.forceMove(host) //Moving the mob into the host to await it's reawakening.

    emerge.Grant(host)

    host.add_traits(host_traits, src)
    if(host.stat == DEAD)
        host.add_traits(host_dead_traits, src)
    host.set_stat(CONSCIOUS)
    host.updatehealth()
    host.update_sight()
    host.SetAllImmobility(0)
    blood_holder.trans_to(host.reagents, max(BLOOD_VOLUME_NORMAL - host.blood_volume, 0), methods = INJECT)
    blood_holder.clear_reagents()

    REMOVE_TRAIT(host, TRAIT_KNOCKEDOUT, STAT_TRAIT)

    RegisterSignal(main_body, COMSIG_MOVABLE_MOVED, PROC_REF(release_host))
    RegisterSignal(host, COMSIG_LIVING_LIFE, PROC_REF(on_life))

    if(host_mind)
        if(host_mind.active)
            subjugations += 1 //WOOOOO you took a sentient person over... on second thought that's pretty horrible. What have I made?
        var/list/antag_datums = host_mind.antag_datums
        for(var/datum/antagonist/antag_datum in antag_datums) //This only works because the body doesn't change and who owns the datum doesn't matter.
            host_mind.antag_datums.Remove(antag_datum)
            antag_datum.owner = owner
            var/datum/team/antag_team = antag_datum.get_team()
            antag_team.remove_member(host_mind)
            antag_team.add_member(owner)

    return TRUE

/datum/antagonist/sentient_blood/proc/release_host(death = FALSE, wound = FALSE)
    if(main_body && !death)
        owner.transfer_to(main_body, force_key_move = TRUE)
        main_body.pause_life_updates = FALSE
        if(host)
            main_body.forceMove(host.drop_location())
    else if(host)
        owner.current.ghostize(FALSE)

    if(!host)
        return

    emerge.Remove(host)

    host.remove_traits(host_traits + host_dead_traits, src)
    host.dna.species.exotic_blood = null
    blood_holder.add_reagent(/datum/reagent/blood/sentient, host.blood_volume)
    host.bleed(host.blood_volume)

    UnregisterSignal(host, COMSIG_LIVING_LIFE)

    if(wound)
        var/obj/item/bodypart/chest = host.get_bodypart(BODY_ZONE_CHEST)
        var/datum/wound/wound_to_replace
        for(var/datum/wound/existing_wound in chest.wounds)
            if(existing_wound.wound_type == WOUND_SLASH)
                wound_to_replace = existing_wound
                break
        var/datum/wound/slash/critical/wound_to_add = new()
        wound_to_add.apply_wound(chest, old_wound = wound_to_replace)

    if(!host_mind)
        host.mind = null
        host = null
        return

    host_mind.transfer_to(host, force_key_move = TRUE)

    for(var/datum/antagonist/antag_datum in owner.antag_datums)
        if(antag_datum == src)
            continue
        owner.antag_datums.Remove(antag_datum)
        antag_datum.owner = host_mind
        var/datum/team/antag_team = antag_datum.get_team()
        antag_team.remove_member(owner)
        antag_team.add_member(host_mind)

    host = null

///Gets the amount of blood we have. Takes into account if we're in a host. Use this instead of reading it directly.
/datum/antagonist/sentient_blood/proc/get_blood_amount()
    if(host)
        return host.blood_volume
    return blood_holder.get_reagent_amount(/datum/reagent/blood/sentient)

///Changes the amount of sentient blood by the given amount. Max only applies while in a host.
/datum/antagonist/sentient_blood/proc/change_blood(amount, max = BLOOD_VOLUME_NORMAL)
    if(host)
        host.blood_volume += clamp(amount, -host.blood_volume, max(max - host.blood_volume, 0))
    else
        if(amount > 0)
            blood_holder.add_reagent(/datum/reagent/blood/sentient, amount)
        else
            blood_holder.remove_reagent(/datum/reagent/blood/sentient, amount)

///Sets the amount of sentient blood to the given amount. Max only applies while in a host.
/datum/antagonist/sentient_blood/proc/set_blood(amount, max = BLOOD_VOLUME_NORMAL)
    if(host)
        host.blood_volume = clamp(amount, 0, min(host.blood_volume, max))
    else
        if(get_blood_amount() <= amount)
            blood_holder.add_reagent(/datum/reagent/blood/sentient, amount - get_blood_amount())
        else
            blood_holder.remove_reagent(/datum/reagent/blood/sentient, get_blood_amount() - amount)

/datum/antagonist/sentient_blood/proc/on_life(datum/source, delta_time, times_fired)
    SIGNAL_HANDLER

    if(!host)
        return

    if(get_blood_amount() <= 0)
        release_host(death = TRUE)

    if(host.stat == DEAD) //Oh no!
        host.set_stat(CONSCIOUS) //Anyways...
        host.grab_ghost(force = TRUE)
        host.updatehealth()
        host.update_sight()
        host.SetAllImmobility(0)
        REMOVE_TRAIT(host, TRAIT_KNOCKEDOUT, STAT_TRAIT)

    if(host.health > HEALTH_THRESHOLD_DEAD)
        host.remove_traits(host_dead_traits, src)
        if(get_blood_amount() < BLOOD_VOLUME_NORMAL)
            change_blood(BLOOD_VOLUME_NORMAL * 0.01 * delta_time) //You regenerate 1% of your maximum blood per second. Normal blood regeneration is disabled.
        else
            host.adjustBruteLoss(-1 * delta_time) //You heal your host slowly if your blood is full.
            host.adjustFireLoss(-1 * delta_time)
            host.adjustToxLoss(-1 * delta_time)
    else
        host.add_traits(host_dead_traits, src)

/datum/objective/subjugate_hosts
    name = "subjugate"

/datum/objective/subjugate_hosts/New(text)
    target_amount = rand(1, 5)
    update_explanation_text()

/datum/objective/subjugate_hosts/update_explanation_text()
    . = ..()
    explanation_text = "Subjugate at least [target_amount] sentient hosts."

/datum/objective/subjugate_hosts/check_completion()
    var/subjugations = 0
    for(var/datum/mind/owner in get_owners())
        var/datum/antagonist/sentient_blood/sentient_blood = owner.has_antag_datum(/datum/antagonist/sentient_blood)
        if(istype(sentient_blood))
            subjugations += sentient_blood.subjugations
    if(subjugations >= target_amount)
        return TRUE
    return FALSE

/datum/job/sentient_blood
    title = ROLE_SENTIENT_BLOOD

/datum/status_effect/sentient_blood_conversion
    status_type = STATUS_EFFECT_UNIQUE
    tick_interval = 0.5 SECONDS
    alert_type = null

    var/mob/living/carbon/human/human_owner
    var/last_blood_volume = BLOOD_VOLUME_NORMAL
    var/converted = 0 //How much of the owner's blood has been converted in units.

/datum/status_effect/sentient_blood_conversion/on_apply()
    human_owner = owner

    if(!istype(human_owner))
        return FALSE
    if(human_owner.get_blood_id() != /datum/reagent/blood || HAS_TRAIT(human_owner, TRAIT_NOBLOOD))
        return FALSE

    human_owner.dna.species.exotic_blood = /datum/reagent/blood/sentient
    last_blood_volume = human_owner.blood_volume
    return TRUE

/datum/status_effect/sentient_blood_conversion/on_remove()
    human_owner.dna.species.exotic_blood = null

/datum/status_effect/sentient_blood_conversion/tick(delta_time, times_fired)
    if(human_owner.stat != DEAD)
        converted += human_owner.blood_volume / 300 * delta_time //5 minutes for full conversion.
    else
        converted -= human_owner.blood_volume / 1200 * delta_time //20 minutes for full deconversion.

    update_blood()

/datum/status_effect/sentient_blood_conversion/proc/update_blood()
    converted -= max(last_blood_volume - human_owner.blood_volume, 0)
    last_blood_volume = human_owner.blood_volume

    if(converted <= 0)
        qdel(src)
        return
