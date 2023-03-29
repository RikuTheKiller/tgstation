/datum/antagonist/sentient_blood
    name = "Sentient Blood"
    antagpanel_category = ANTAG_GROUP_BIOHAZARDS
    show_to_ghosts = TRUE

    var/subjugations = 0
    var/main_body //Stores the original body of the sentient blood while it's in a host.

/datum/antagonist/sentient_blood/on_gain()
    . = ..()
    owner.set_assigned_role(SSjob.GetJobType(/datum/job/sentient_blood))
    owner.special_role = ROLE_SENTIENT_BLOOD
    var/datum/objective/objective = new /datum/objective/subjugate_hosts()
    objective.owner = owner
    objectives += objective
    objective = new /datum/objective/survive()
    objective.owner = owner
    objectives += objective
    var/mob/living/basic/sentient_blood/blood_mob = new(src)
    owner.transfer_to(blood_mob, TRUE)

/datum/antagonist/sentient_blood/greet()
	. = ..()
	to_chat(owner.current, span_notice("Slither your way around the station and invade the crews bloodstreams."))
	owner.announce_objectives()

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
