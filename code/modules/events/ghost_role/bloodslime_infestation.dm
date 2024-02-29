/datum/round_event_control/bloodslime_infestation
	name = "Hemoparasite Infection"
	typepath = /datum/round_event/ghost_role/bloodslime_infestation
	max_occurrences = 1
	min_players = 20
	category = EVENT_CATEGORY_ENTITIES
	description = "Spawns a Hemoparasite inside a random dead person."
	min_wizard_trigger_potency = 5
	max_wizard_trigger_potency = 7

/datum/round_event/ghost_role/bloodslime_infestation
	fakeable = FALSE
	minimum_required = 1
	role_name = "hemoparasite"

/datum/round_event/ghost_role/bloodslime_infestation/spawn_role()
	var/mob/host
	for(var/mob/living/carbon/human/victim as anything in shuffle(GLOB.dead_mob_list))
		if(!istype(victim))
			continue
		var/turf/victim_turf = get_turf(victim) //may be in locker
		if(!is_station_level(victim_turf.z))
			continue
		if(HAS_TRAIT(victim, TRAIT_NOBLOOD) || victim.dna?.species.exotic_blood)
			continue
		if(victim.blood_volume < BLOOD_VOLUME_OKAY)
			continue
		host = victim
		break
	if(isnull(host))
		return NOT_ENOUGH_PLAYERS
	var/list/candidates = SSpolling.poll_ghost_candidates(check_jobban = ROLE_SENTIENCE, role = ROLE_SENTIENCE, pic_source = /mob/living/basic/hemoparasite, role_name_text = "Hemoparasite")
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS
	var/mob/candidate = pick(candidates)
	var/datum/mind/player_mind = new /datum/mind(candidate.key)
	player_mind.active = TRUE

	var/mob/living/basic/hemoparasite/slime = new(host)
	player_mind.transfer_to(slime)
	player_mind.set_assigned_role(SSjob.GetJobType(/datum/job/bloodslime))
	player_mind.special_role = ROLE_HEMOPARASITE_MIDROUND
	player_mind.add_antag_datum(/datum/antagonist/hemoparasite)

	var/datum/antagonist/hemoparasite/antag = player_mind.has_antag_datum(/datum/antagonist/hemoparasite)
	antag.enter_host(host, disable_animation = TRUE)

	message_admins("[ADMIN_LOOKUPFLW(slime)]has been made into a Hemoparasite by an event.")
	slime.log_message("was spawned as a Hemoparasite inside [host.real_name] by an event.", LOG_GAME)
	spawned_mobs += slime
	return SUCCESSFUL_SPAWN
