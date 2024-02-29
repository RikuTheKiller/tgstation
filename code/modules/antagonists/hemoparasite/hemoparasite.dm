/datum/job/bloodslime
	title = ROLE_HEMOPARASITE_MIDROUND

// This antag datum is quite volatile. It does a LOT of datum manipulation.
// There's stuff here that can just *break* due to updates.
// And also some stuff that should be periodically checked on, mainly the lists.
// It should never outright stop working, though. That'd be impressive.

/datum/antagonist/hemoparasite
	name = "\improper Hemoparasite" // blood slime real??
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS // either biohazard or horror works, but biohazard is more applicable here
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE // somewhat stealthy, but not enough to be hidden from ghosts

	/// Our current state.
	var/current_state = -1 // Uninitialized

	/// The hemoparasite basic mob.
	var/mob/living/basic/hemoparasite/body

	/// The current host of the hemoparasite, if in one.
	var/mob/living/carbon/human/host

	/// The current host's mind datum.
	var/datum/mind/host_mind

	/// The current host's antag datums.
	var/list/datum/antagonist/host_antags = list()

	/// The current host's brain traumas.
	var/list/datum/brain_trauma/host_traumas = list()

	/// For keeping track of coexisting antag datums when transferring bodies.
	var/list/datum/antagonist/extra_antags = list()

	/// Antag datums that are allowed to coexist with us.
	var/list/datum/antagonist/allowed_antags = list(/datum/antagonist/cult)

	/// The current host's blacklisted quirks.
	var/list/datum/quirk/host_quirks = list()

	/// Quirks that can't coexist with us. (should be as minimalistic as possible)
	var/list/datum/quirk/disallowed_quirks = list()

	/// Traits given to our host during subjugation.
	var/static/list/subjugation_traits = list(
		TRAIT_BLOODSLIME_CONTROL,
		TRAIT_BLOODSLIME_SUBJUGATION,
		TRAIT_MUTE,
		TRAIT_MADNESS_IMMUNE,
		TRAIT_SLEEPIMMUNE,
		TRAIT_NODEATH, // we handle death differently in a host
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_STABLEHEART, // we are the circulation
	)

	/// Traits given to our host during marionette.
	var/static/list/marionette_traits = list(
		TRAIT_BLOODSLIME_CONTROL,
		TRAIT_BLOODSLIME_MARIONETTE,
		TRAIT_MUTE,
		TRAIT_MADNESS_IMMUNE,
		TRAIT_SLEEPIMMUNE,
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_STABLEHEART,
		TRAIT_ILLITERATE, // we don't have a brain
		TRAIT_DISCOORDINATED_TOOL_USER, // we're brute forcing control over a corpse our dexterity is null and void
		TRAIT_FAKEDEATH, // it's just a regular corpse, trust
		TRAIT_STUNIMMUNE, // slugfest, we can't stun and we can't be stunned
	)

	/// Traits given to our host during symbiosis.
	var/static/list/symbiosis_traits = list(
		TRAIT_BLOODSLIME_CONTROL,
		TRAIT_BLOODSLIME_SYMBIOSIS,
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_STABLEHEART,
	)

	/// Associative typecache of states to lists of action types. Use initialized_actions for accessing them instead.
	var/static/list/state_actions = list(
		HEMOPARASITE_STATE_SOLO = list(
			/datum/action/cooldown/hemoparasite/enter
		),
		HEMOPARASITE_STATE_DORMANT = list(
			/datum/action/cooldown/hemoparasite/delayed/emerge,
			/datum/action/cooldown/hemoparasite/regen,
			/datum/action/cooldown/hemoparasite/delayed/subjugate
		),
		HEMOPARASITE_STATE_SUBJUGATION = list(
			/datum/action/cooldown/hemoparasite/delayed/emerge,
			/datum/action/cooldown/hemoparasite/regen
		),
		HEMOPARASITE_STATE_MARIONETTE = list(
			/datum/action/cooldown/hemoparasite/delayed/emerge,
			/datum/action/cooldown/hemoparasite/regen
		),
		HEMOPARASITE_STATE_SYMBIOSIS = list(
			/datum/action/cooldown/hemoparasite/delayed/emerge,
			/datum/action/cooldown/hemoparasite/regen
		)
	)

	/// Associative list of initialized action datums sorted by state.
	var/list/initialized_actions

	/// The "eyes" of the hemoparasite. These can get damaged while in a host.
	var/obj/item/organ/internal/eyes/night_vision/hemoparasite/eyes

	/// The "ears" of the hemoparasite. These can get damaged while in a host.
	var/obj/item/organ/internal/ears/hemoparasite/ears

/datum/antagonist/hemoparasite/New()
	. = ..()
	allowed_antags_typecache = typecacheof(allowed_antags_typecache)
	disallowed_quirks_typecache = typecacheof(disallowed_quirks_typecache)

/datum/antagonist/hemoparasite/proc/swap_state(state)
	if(current_state == state)
		return

	for(var/datum/action/cooldown/hemoparasite/former in owner.current.actions)
		former.Remove(owner.current)

	current_state = state
	var/list/actions = initialized_actions[current_state]

	for(var/datum/action/action as anything in actions)
		action.Grant(owner.current)

/datum/antagonist/hemoparasite/on_gain()
	eyes = new()
	ears = new()
	if (isnull(initialized_actions))
		init_actions()
	if (istype(owner.current, /mob/living/basic/hemoparasite))
		slime = owner.current
		swap_state(HEMOPARASITE_STATE_SOLO)
		eyes.forceMove(slime)
		ears.forceMove(slime)
	else if (istype(owner.current, /mob/living/carbon/human))
		slime = new(owner.current)
		if (!enter_host(owner.current, silent = TRUE, disable_animation = TRUE)) // check if entering the host was successful in case they have incompatible blood or something
			owner.remove_antag_datum(src.type)
			return ..()
		subjugate_host()
	else
		owner.remove_antag_datum(src.type)

	return ..()

/datum/antagonist/hemoparasite/proc/init_actions()
	var/list/initialized_actions_by_type = list()
		initialized_actions = state_actions.Copy()
		for (var/state_key in initialized_actions)
			for (var/path in initialized_actions[state_key])
				initialized_actions[state_key] -= path
				var/action = initialized_actions_by_type[path]
				if (!action)
					action = new path(owner)
					initialized_actions_by_type[path] = action
				initialized_actions[state_key] += action

/datum/antagonist/hemoparasite/on_removal()
	if (host)
		for (var/datum/action/cooldown/hemoparasite/former in host.actions)
			former.Remove(former)
	for (var/datum/action/cooldown/hemoparasite/former in owner.current.actions)
		former.Remove(former)
	QDEL_LIST_ASSOC(initialized_actions)
	return ..()

/// Returns whether or not the hemoparasite is actually *in* a host. Having a host doesn't mean you're inside them.
/datum/antagonist/hemoparasite/proc/is_in_host()
	return host && slime?.loc == host

/**
 * Causes the slime to enter the target with an animation.
 *
 * Arguments:
 * * target - The target to enter.
 * * silent - Disables the visible message.
 * * disable_animation - Disables the animation.
 */
/datum/antagonist/hemoparasite/proc/enter_host(mob/living/carbon/human/target, silent, disable_animation)
	if (!target)
		CRASH("[slime] ([owner]) attempted to enter a host that doesn't exist.")
	if (host)
		CRASH("[slime] ([owner]) attempted to enter a host while already in another host.")
	if (get_host_max_blood(target) <= 0)
		return FALSE

	if (!silent)
		slime.visible_message(
			message = span_danger("\The [slime] enters [target]'s body!"),
			self_message = span_notice("You enter [target]'s body."),
			blind_message = span_hear("You hear a splash."),
		)

	slime.forceMove(target)
	swap_state(HEMOPARASITE_STATE_DORMANT)

	host = target

	set_host_blood_amount(get_host_blood_amount() + get_blood_amount())

	return TRUE

/datum/antagonist/hemoparasite/proc/stop_host_control()
	if (isnull(host))
		CRASH("[slime] ([owner]) attempted to stop controlling a nonexistent host.")
	UnregisterSignal(host, COMSIG_LIVING_DEATH)
	swap_state(HEMOPARASITE_STATE_DORMANT)
	REMOVE_TRAITS_IN(host, BLOODCONTROL_TRAIT)
	return_host_senses()
	if(host.mind != owner)
		return
	owner.transfer_to(slime)
	if(host_mind)
		host_mind.transfer_to(host)
		host_mind = null

/**
 * Causes the slime to leave it's current host with an animation.
 *
 * Arguments:
 * * max_blood - The maximum amount of blood this can take. Setting it to BLOOD_VOLUME_HEMOPARASITE_MAXIMUM or above will empty the host. The actual amount of blood left for the slime is further limited by get_host_max_blood()
 * * silent - Disables the visible message.
 * * disable_animation - Disables the animation.
 */
/datum/antagonist/hemoparasite/proc/leave_host(max_blood = BLOOD_VOLUME_HEMOPARASITE_MAXIMUM, silent = FALSE, disable_animation = FALSE)
	if (!host)
		CRASH("[slime] ([owner]) attempted to leave a host that doesn't exist.")

	set_host_blood_amount(min(get_host_blood_amount(), max_blood))

	if (!disable_animation)
		flick("emerge", slime)

	stop_host_control()
	slime.forceMove(host.drop_location())

	if (!silent)
		slime.visible_message(
			span_danger("\The [slime] emerges from [host]!"),
			span_notice("You emerge from your host."),
			span_hear("You hear a sudden gush of liquid!"),
			ignored_mobs = host
		)
		to_chat(host, span_userdanger("You feel your hemoparasite escape your body... you feel woozy..."))

	if (host.blood_volume < BLOOD_VOLUME_SURVIVE && !HAS_TRAIT(host, TRAIT_NODEATH))
		host.death()

	swap_state(HEMOPARASITE_STATE_SOLO)

	host = null

/// Handles blood processing in a host, called from /mob/living/carbon/human/handle_blood() after a check for TRAIT_BLOODSLIME_CONTROL
/datum/antagonist/hemoparasite/proc/handle_blood(seconds_per_tick, times_fired)
	if (!host)
		CRASH("[slime] ([owner]) is somehow processing blood in a host while it doesn't even have a reference to them. Something has gone hilariously wrong.")

	adjust_host_blood_amount(HEMOPARASITE_REGEN_FACTOR * seconds_per_tick, ignore_sync = TRUE) // regen blood, desyncs blood_volume from the basic mob's health

	host.handle_bleeding(seconds_per_tick, times_fired) // handle bleeding

	set_blood_amount(host.blood_volume, ignore_sync = TRUE) // resync

/// Makes the hemoparasite subjugate its host.
/datum/antagonist/hemoparasite/proc/subjugate_host()
	if (!host)
		CRASH("[slime] ([owner]) attempted to subjugate a host that doesn't exist.")

	if(host.health <= HEALTH_THRESHOLD_DEAD)
		return

	for(var/trait in subjugation_traits)
		ADD_TRAIT(host, trait, BLOODCONTROL_TRAIT)

	control_host()

	swap_state(HEMOPARASITE_STATE_SUBJUGATION)

/// Makes the hemoparasite marionette its host.
/datum/antagonist/hemoparasite/proc/marionette_host()
	if (!host)
		CRASH("[slime] ([owner]) attempted to marionette a host that doesn't exist.")

	for(var/trait in marionette_traits)
		ADD_TRAIT(host, trait, BLOODCONTROL_TRAIT)

	control_host()

	swap_state(HEMOPARASITE_STATE_MARIONETTE)

/// Makes the hemoparasite control its host. Not sanity checked.
/datum/antagonist/hemoparasite/proc/control_host()
	if(host.mind)
		host_mind = host.mind

	host.revive()
	owner.transfer_to(host)

	replace_host_senses()

/datum/antagonist/hemoparasite/proc/on_host_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(gibbed)
		leave_host(silent = TRUE, disable_animation = TRUE)
		return
	stop_host_control()

/// Replaces the current host's senses with our own. Grows new (unfinished/damaged) ones if they're somehow removed.
/datum/antagonist/hemoparasite/proc/replace_host_senses()
	if (!host)
		return

	if (eyes?.loc != slime && (!eyes?.owner || eyes.owner != host))
		eyes = new()
		eyes.apply_organ_damage(eyes.maxHealth) // start out really damaged so you can't rip failing ones out to grow functioning ones
		eyes.Insert(host, special = TRUE)
		host.visible_message(
			message = span_bolddanger("[host] suddenly grows a pair of [eyes] in place of their eyes!"),
			self_message = host == owner.current ? null : span_boldnotice("You feel something growing in place of your eyes."),
			blind_message = span_hear("You hear a loud and wet crunch."),
			ignored_mobs = owner.current
		)
		to_chat(owner.current, span_warning("You grow a pair of unfinished [eyes] in place of the ones you lost."))
	if (eyes?.loc != slime && (!ears?.owner || ears.owner != host))
		ears = new()
		ears.apply_organ_damage(ears.maxHealth) // start out really damaged so you can't rip failing ones out to grow functioning ones
		ears.Insert(host, special = TRUE)
		host.visible_message(
			message = span_bolddanger("[host] suddenly grows a pair of [ears] in place of their ears!"),
			self_message = host == owner.current ? null : span_boldnotice("You feel something growing in place of your ears."),
			blind_message = span_hear("You hear a loud and wet crunch."),
			ignored_mobs = owner.current
		)
		to_chat(owner.current, span_warning("You grow a pair of unfinished [ears] in place of the ones you lost."))

	eyes.Insert(host, special = TRUE)
	ears.Insert(host, special = TRUE)

/// Returns the current host's senses back to their own.
/datum/antagonist/hemoparasite/proc/return_host_senses()
	if (!eyes)
		eyes = new()
	if (!ears)
		ears = new()
	if (host)
		if (eyes.owner == host)
			eyes.Remove(host, special = TRUE)
			eyes.covered.Insert(host, special = TRUE)
			eyes.covered.organ_flags &= ~ORGAN_FROZEN
		if (eyes.owner == host)
			ears.Remove(host, special = TRUE)
			ears.covered.Insert(host, special = TRUE)
			ears.covered.organ_flags &= ~ORGAN_FROZEN
	eyes.forceMove(slime)
	ears.forceMove(slime)
