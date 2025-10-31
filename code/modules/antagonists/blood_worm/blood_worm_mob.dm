/mob/living/basic/blood_worm
	mob_biotypes = MOB_ORGANIC | MOB_BUG
	basic_mob_flags = FLAMMABLE_MOB

	damage_coeff = list(BRUTE = 1, BURN = 1.5, TOX = 0, STAMINA = 0, OXY = 0)

	pressure_resistance = 200

	combat_mode = TRUE

	melee_attack_cooldown = CLICK_CD_MELEE

	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"

	minimum_survivable_temperature = 0
	maximum_survivable_temperature = T0C + 100

	habitable_atmos = null

	// TEMPORARY ICONS
	icon = 'icons/mob/simple/carp.dmi'
	icon_state = "base"
	icon_living = "base"
	icon_dead = "base_dead"
	// TEMPORARY ICONS

	/// Associative list of how much of each blood type the blood worm has consumed.
	/// The format of this list is "list[blood_type.id] = amount_consumed"
	/// This carries across growth stages.
	var/list/consumed_blood = list()

	/// The current host of the blood worm, if any.
	/// You can use this to check if the blood worm has a host.
	var/mob/living/carbon/human/host
	/// The backseat mob for the mind of the current host, if any.
	/// This mob is always dead as it's just a mind holder.
	var/mob/living/blood_worm_host/backseat

	/// The blood display on the left side of the screen, which is shown to the blood worm while in a host, if any.
	var/atom/movable/screen/blood_level/blood_display

	// Innate and shared actions

	/// Typed, please initialize with a proper action subtype. (empty = no action)
	var/datum/action/cooldown/mob_cooldown/blood_worm_spit/spit_action
	/// Typed, please initialize with a proper action subtype. (empty = no action)
	var/datum/action/cooldown/mob_cooldown/blood_worm_leech/leech_action
	/// Not typed, please leave empty.
	var/datum/action/cooldown/mob_cooldown/blood_worm_invade/invade_action
	/// Typed, please initialize with a proper action subtype. (empty = no action)
	var/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/cocoon_action

	// Host actions

	/// Typed, please initialize with a proper action subtype. (empty = no action)
	var/datum/action/cooldown/mob_cooldown/blood_worm_transfuse/transfuse_action
	/// Not typed, please leave empty.
	var/datum/action/blood_worm_eject/eject_action
	/// Not typed, please leave empty.
	var/datum/action/cooldown/mob_cooldown/blood_worm_revive/revive_action

	/// List of actions outside of a host.
	var/list/innate_actions = list()
	/// List of actions inside of a host.
	var/list/host_actions = list()

	/// Whether the blood worm has a host AND is currently in control of that host.
	var/is_possessing_host = FALSE

	/// The last amount of blood added to the host by blood dilution.
	var/last_added_blood = 0

	/// How quickly the blood worm regenerates, in health per second.
	var/regen_rate = 0

/mob/living/basic/blood_worm/Initialize(mapload)
	. = ..()

	// Innate and shared actions

	if (ispath(spit_action, /datum/action/cooldown/mob_cooldown/blood_worm_spit))
		spit_action = new spit_action(src)
		innate_actions += spit_action
		host_actions += spit_action

	if (ispath(leech_action, /datum/action/cooldown/mob_cooldown/blood_worm_leech))
		leech_action = new leech_action(src)
		innate_actions += leech_action

	invade_action = new(src)
	innate_actions += invade_action

	if (ispath(cocoon_action, /datum/action/cooldown/mob_cooldown/blood_worm_cocoon))
		cocoon_action = new cocoon_action(src)
		innate_actions += cocoon_action

	// Host actions

	if (ispath(transfuse_action, /datum/action/cooldown/mob_cooldown/blood_worm_transfuse))
		transfuse_action = new transfuse_action(src)
		host_actions += transfuse_action

	eject_action = new(src)
	host_actions += eject_action

	revive_action = new(src)
	host_actions += revive_action

	grant_actions(src, innate_actions)

/mob/living/basic/blood_worm/Destroy()
	. = ..()

	unregister_host()

/mob/living/basic/blood_worm/process(seconds_per_tick, times_fired)
	if (!host)
		return

	update_dilution()
	sync_health()

/mob/living/basic/blood_worm/Life(seconds_per_tick, times_fired)
	. = ..()

	if (!host)
		adjustBruteLoss(-regen_rate * seconds_per_tick)

/mob/living/basic/blood_worm/proc/ingest_blood(blood_amount, datum/blood_type/blood_type, should_heal = TRUE)
	if (!blood_type)
		return

	consumed_blood[blood_type.id] += blood_amount

	if (should_heal)
		adjustBruteLoss(-blood_amount * BLOOD_WORM_BLOOD_TO_HEALTH)

/mob/living/basic/blood_worm/proc/enter_host(mob/living/carbon/human/new_host)
	if (!mind || !key)
		return

	host = new_host

	RegisterSignal(host, COMSIG_QDELETING, PROC_REF(on_host_qdel))
	RegisterSignal(host, COMSIG_MOB_STATCHANGE, PROC_REF(on_host_stat_changed))
	RegisterSignal(host, COMSIG_HUMAN_ON_HANDLE_BLOOD, PROC_REF(on_host_handle_blood))
	RegisterSignal(host, COMSIG_LIVING_LIFE, PROC_REF(on_host_life))

	START_PROCESSING(SSfastprocess, src)

	become_blind(BLOOD_WORM_HOST_TRAIT)
	add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_MUTE, TRAIT_DEAF), BLOOD_WORM_HOST_TRAIT)

	// The worm handles basic blood oxygenation, circulation and filtration.
	// The controlled host still requires a liver to process chemicals and lungs to speak.
	host.add_traits(list(TRAIT_NOBREATH, TRAIT_STABLEHEART, TRAIT_STABLELIVER, TRAIT_NOCRITDAMAGE), BLOOD_WORM_HOST_TRAIT)

	remove_actions(src, innate_actions)
	grant_actions(src, host_actions)

	if (host.mind)
		backseat = new(host)
		backseat.death(gibbed = TRUE) // Same thing that the corpse mob spawners do to stop deathgasps and such.
		host.mind.transfer_to(backseat)

	start_dilution()
	sync_health()

	if (host.hud_used)
		create_host_hud(host)
	else
		RegisterSignal(host, COMSIG_MOB_HUD_CREATED, PROC_REF(create_host_hud))

	forceMove(host)

/mob/living/basic/blood_worm/proc/leave_host()
	if (!host)
		return

	forceMove(get_turf(host))

	unregister_host()

/mob/living/basic/blood_worm/proc/unregister_host()
	if (!host)
		return

	possess_worm()

	if (backseat)
		backseat.mind?.transfer_to(host)
		QDEL_NULL(backseat)

	UnregisterSignal(host, list(COMSIG_QDELETING, COMSIG_MOB_STATCHANGE, COMSIG_HUMAN_ON_HANDLE_BLOOD, COMSIG_LIVING_LIFE))

	STOP_PROCESSING(SSfastprocess, src)

	cure_blind(BLOOD_WORM_HOST_TRAIT)
	REMOVE_TRAITS_IN(src, BLOOD_WORM_HOST_TRAIT)
	REMOVE_TRAITS_IN(host, BLOOD_WORM_HOST_TRAIT)

	remove_actions(src, host_actions)
	grant_actions(src, innate_actions)

	ingest_blood(host.blood_volume, host.get_bloodtype(), should_heal = FALSE)

	update_dilution()
	sync_health()

	remove_host_hud()

	host.blood_volume = 0
	host.death() // I don't care if you have TRAIT_NODEATH, can't die from bloodloss normally, or whatever else. I just need you to die.

	host = null

/mob/living/basic/blood_worm/proc/possess_host()
	if (!host || is_possessing_host)
		return

	is_possessing_host = TRUE

	mind?.transfer_to(host)

	remove_actions(src, host_actions)
	grant_actions(host, host_actions)

/mob/living/basic/blood_worm/proc/possess_worm()
	if (!host || !is_possessing_host)
		return

	is_possessing_host = FALSE

	host.mind?.transfer_to(src)

	remove_actions(host, host_actions)
	grant_actions(src, host_actions)

/mob/living/basic/blood_worm/proc/on_host_qdel(datum/source, force)
	SIGNAL_HANDLER
	qdel(src)

/mob/living/basic/blood_worm/proc/on_host_stat_changed(datum/source, new_stat, old_stat)
	if (old_stat == DEAD && new_stat != DEAD)
		possess_host()
	else if (old_stat != DEAD && new_stat == DEAD)
		possess_worm()

/mob/living/basic/blood_worm/proc/on_host_handle_blood(datum/source, seconds_per_tick, times_fired)
	host.blood_volume += regen_rate * seconds_per_tick * BLOOD_WORM_HEALTH_TO_BLOOD
	return HANDLE_BLOOD_NO_OXYLOSS | HANDLE_BLOOD_NO_NUTRITION_DRAIN

/mob/living/basic/blood_worm/proc/on_host_life(datum/source, seconds_per_tick, times_fired)
	if (!HAS_TRAIT(host, TRAIT_STASIS))
		host.handle_blood(seconds_per_tick, times_fired)

/mob/living/basic/blood_worm/proc/create_host_hud(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(host, COMSIG_MOB_HUD_CREATED)

	var/datum/hud/hud = host.hud_used
	blood_display = new(null, hud)
	hud.infodisplay += blood_display
	hud.show_hud(hud.hud_version)

/mob/living/basic/blood_worm/proc/remove_host_hud()
	var/datum/hud/hud = host.hud_used

	if (!hud)
		QDEL_NULL(blood_display)
		return

	hud.infodisplay -= blood_display
	QDEL_NULL(blood_display)

/mob/living/basic/blood_worm/proc/grant_actions(mob/target, list/actions)
	for (var/datum/action/action as anything in actions)
		action.Grant(target)

/mob/living/basic/blood_worm/proc/remove_actions(mob/target, list/actions)
	for (var/datum/action/action as anything in actions)
		action.Remove(target)

/mob/living/basic/blood_worm/proc/start_dilution()
	var/health_as_blood = health * BLOOD_WORM_HEALTH_TO_BLOOD
	var/dilution_multiplier = get_dilution_multiplier()

	var/base_blood_volume = clamp(host.blood_volume + health_as_blood, 0, BLOOD_VOLUME_NORMAL / dilution_multiplier)
	var/diluted_blood_volume = base_blood_volume * dilution_multiplier

	last_added_blood = diluted_blood_volume - base_blood_volume
	host.blood_volume = diluted_blood_volume

/mob/living/basic/blood_worm/proc/update_dilution()
	var/dilution_multiplier = get_dilution_multiplier()

	var/base_blood_volume = clamp(host.blood_volume - last_added_blood, 0, BLOOD_VOLUME_NORMAL / dilution_multiplier)
	var/diluted_blood_volume = base_blood_volume * dilution_multiplier

	last_added_blood = diluted_blood_volume - base_blood_volume
	host.blood_volume = diluted_blood_volume

/mob/living/basic/blood_worm/proc/sync_health()
	if (!host)
		return

	setBruteLoss(maxHealth * (1 - host.blood_volume / BLOOD_VOLUME_NORMAL))

/mob/living/basic/blood_worm/proc/get_dilution_multiplier()
	return BLOOD_VOLUME_NORMAL / (maxHealth * BLOOD_WORM_HEALTH_TO_BLOOD)

/mob/living/basic/blood_worm/hatchling
	name = "hatchling blood worm"
	desc = "A freshly hatched blood worm. It looks hungry and somewhat weak, requiring blood to grow further."

	maxHealth = 50
	health = 50

	obj_damage = 10
	melee_damage_lower = 8
	melee_damage_upper = 12

	speed = 0

	leech_action = /datum/action/cooldown/mob_cooldown/blood_worm_leech/hatchling
	cocoon_action = /datum/action/cooldown/mob_cooldown/blood_worm_cocoon/hatchling

	transfuse_action = /datum/action/cooldown/mob_cooldown/blood_worm_transfuse/hatchling

	regen_rate = 0.2 // 250 seconds to recover from 0 to 50, or a little over 4 minutes

/mob/living/basic/blood_worm/hatchling/Initialize(mapload)
	. = ..()

	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/basic/blood_worm/juvenile
	name = "juvenile blood worm"
	desc = "A mid-sized blood worm. It looks bloodthirsty and has numerous long and extremely sharp teeth."

	maxHealth = 100 // Note that the juveniles are bigger and slower than hatchlings, making them far easier to hit by comparison.
	health = 100

	obj_damage = 25 // Able to break most obstacles, such as airlocks. This is mandatory since they can't ventcrawl anymore.
	melee_damage_lower = 15
	melee_damage_upper = 20

	wound_bonus = 0// Juveniles can afford to heal wounds on their hosts, unlike hatchlings. Note that this can't cause critical wounds. (at least it didn't in testing)
	sharpness = SHARP_POINTY

	speed = 0.5

	spit_action = /datum/action/cooldown/mob_cooldown/blood_worm_spit/juvenile
	leech_action = /datum/action/cooldown/mob_cooldown/blood_worm_leech/juvenile
	cocoon_action = /datum/action/cooldown/mob_cooldown/blood_worm_cocoon/juvenile

	transfuse_action = /datum/action/cooldown/mob_cooldown/blood_worm_transfuse/juvenile

	regen_rate = 0.3 // 333 seconds to recover from 0 to 100, or a little over 5 and a half minutes

/mob/living/basic/blood_worm/adult
