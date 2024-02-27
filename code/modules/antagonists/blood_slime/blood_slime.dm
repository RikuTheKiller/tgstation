/datum/job/bloodslime
	title = ROLE_BLOOD_SLIME_MIDROUND

// This antag datum is quite volatile. It does a LOT of datum manipulation.
// There's stuff here that can just *break* due to updates.
// And also some stuff that should be periodically checked on, mainly the lists.
// It should never outright stop working, though. That'd be impressive.

/datum/antagonist/blood_slime
	name = "\improper Blood Slime"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS // either biohazard or horror works, but biohazard is more applicable here
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE // somewhat stealthy, but not enough to be hidden from ghosts
	default_custom_objective = "Gather blood and grow stronger to wreak havoc on the station." // tiny reference to the rampage ability (fix this shit later)

	/// Our current state.
	var/current_state = -1 // Uninitialized

	/// The blood slime basic mob, if it exists. (stored in host contents)
	var/mob/living/basic/blood_slime/slime

	/// The current host, if we're inside of one.
	var/mob/living/carbon/human/current_host

	/// The current host's mind datum.
	var/datum/mind/host_mind

	/// The current host's antag datums.
	var/list/datum/antagonist/host_antags = list()

	/// The current host's brain traumas.
	var/list/datum/brain_trauma/host_traumas = list()

	/// Our extra antag datums, mostly for keeping track of conversion antags when transferring bodies.
	var/list/datum/antagonist/extra_antags = list()

	/// Antag datums that are allowed to coexist with us.
	var/list/datum/antagonist/allowed_antags_typecache = list(/datum/antagonist/cult)

	/// The current host's blacklisted quirks.
	var/list/datum/quirk/host_quirks = list()

	/// Quirks that for one reason or another, just can't be allowed to coexist with us. (should be as minimalistic as possible, but stuff like anemia and RDS just has to go)
	var/list/datum/quirk/disallowed_quirks_typecache = list()

	/// Traits given to our host during subjugation.
	var/static/list/subjugation_traits = list(
		TRAIT_BLOODSLIME_CONTROL,
		TRAIT_BLOODSLIME_SUBJUGATION,
		TRAIT_MUTE, // sadly slime language doesn't really translate too well
		TRAIT_MADNESS_IMMUNE, // ideally nothing "mental" should affect us similarly to our basic mob slime form (exceptionally hard to achieve without shitcode)
		TRAIT_SLEEPIMMUNE, // we don't have a brain, also encourages slugfest which is a primary goal of the antag
		TRAIT_NODEATH, // we handle "death" via marionette and bleeding out (this, alongside the crit traits, are the most insane traits of blood slime)
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER, // the host feeds us and we feed the host (can't carry food as a slime so it'd get annoying quick, especially if you took over a host and they turned out to be starved to uselessness)
		TRAIT_NOFAT, // we just eat the fat, slime moment (also it would be a problem without hunger, even if especially rare)
		TRAIT_STABLEHEART // we are the circulation
	)

	/// Traits given to our host during marionette.
	var/static/list/marionette_traits = list(
		TRAIT_BLOODSLIME_CONTROL,
		TRAIT_BLOODSLIME_MARIONETTE,
		TRAIT_MUTE,
		TRAIT_MADNESS_IMMUNE,
		TRAIT_ILLITERATE, // a slime on it's own isn't intelligent enough to read human language (also acts as a reason to subjugate instead of relying on marionette)
		TRAIT_DISCOORDINATED_TOOL_USER, // same goes for operating machinery (we really don't want blood slimes being able to use guns and stun weapons while being completely immune to stuns themselves)
		TRAIT_SLEEPIMMUNE,
		TRAIT_STUNIMMUNE, // slugfest, we can't stun and we can't be stunned
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER,
		TRAIT_NOFAT,
		TRAIT_STABLEHEART,
		TRAIT_NOBREATH, // dead people don't breathe (most things that don't process while dead shouldn't process during marionette, yet another difficult thing to do without shitcode)
		TRAIT_LIVERLESS_METABOLISM, // they also don't metabolize (mostly a downside since you can't use healing meds to make a corpse suitable for subjugation)
		TRAIT_FAKEDEATH // it's just a regular corpse, trust (mostly for aesthetics, though it can be used to fake death)
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
		TRAIT_NOHUNGER,
		TRAIT_NOFAT,
		TRAIT_STABLEHEART
	)

	var/static/list/state_actions = list(
		BLOOD_SLIME_STATE_SOLO = list(
			/datum/action/cooldown/blood_slime/enter
		),
		BLOOD_SLIME_STATE_DORMANT = list(
			/datum/action/cooldown/blood_slime/delayed/emerge,
			/datum/action/cooldown/blood_slime/regen,
			/datum/action/cooldown/blood_slime/delayed/subjugate
		),
		BLOOD_SLIME_STATE_SUBJUGATION = list(
			/datum/action/cooldown/blood_slime/delayed/emerge,
			/datum/action/cooldown/blood_slime/regen
		),
		BLOOD_SLIME_STATE_MARIONETTE = list(
			/datum/action/cooldown/blood_slime/delayed/emerge,
			/datum/action/cooldown/blood_slime/regen
		),
		BLOOD_SLIME_STATE_SYMBIOSIS = list(
			/datum/action/cooldown/blood_slime/delayed/emerge,
			/datum/action/cooldown/blood_slime/regen
		)
	)

	/// Associative list of initialized action datums sorted by state.
	var/list/initialized_actions

	/// The "eyes" of the blood slime. These can get damaged while in a host.
	var/obj/item/organ/internal/eyes/night_vision/blood_slime/eyes

	/// The "ears" of the blood slime. These can get damaged while in a host.
	var/obj/item/organ/internal/ears/blood_slime/ears

/datum/antagonist/blood_slime/New()
	. = ..()
	allowed_antags_typecache = typecacheof(allowed_antags_typecache)
	disallowed_quirks_typecache = typecacheof(disallowed_quirks_typecache)

/datum/antagonist/blood_slime/proc/swap_state(state)
	if(current_state == state)
		return

	for(var/datum/action/cooldown/blood_slime/former in owner.current?.actions)
		former.Remove(owner.current)

	current_state = state
	var/list/actions = initialized_actions[current_state]

	for(var/datum/action/action as anything in actions)
		action.Grant(owner.current)

/datum/antagonist/blood_slime/on_gain()
	eyes = new()
	ears = new()
	if (isnull(initialized_actions))
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
		QDEL_NULL(initialized_actions_by_type)
	if (istype(owner.current, /mob/living/basic/blood_slime))
		slime = owner.current
		swap_state(BLOOD_SLIME_STATE_SOLO)
		eyes.forceMove(slime)
		ears.forceMove(slime)
	else if (istype(owner.current, /mob/living/carbon/human))
		slime = new(owner.current)
		if (!enter_host(owner.current, disable_animation = TRUE)) // check if entering the host was successful
			owner.remove_antag_datum(src.type)
			return ..()
		subjugate_host()
	else
		owner.remove_antag_datum(src.type)

	return ..()

/datum/antagonist/blood_slime/on_removal()
	if (current_host)
		for (var/datum/action/cooldown/blood_slime/former in current_host.actions)
			former.Remove(former)
	for (var/datum/action/cooldown/blood_slime/former in owner.current.actions)
		former.Remove(former)
	QDEL_LIST_ASSOC(initialized_actions)
	return ..()

/// Causes the slime to enter the target host with an animation. Returns whether or not entering was successful.
/datum/antagonist/blood_slime/proc/enter_host(mob/living/carbon/human/host, disable_animation = FALSE)
	if (!host)
		CRASH("[slime] ([owner]) attempted to enter a host that doesn't exist.")
	if (current_host)
		CRASH("[slime] ([owner]) attempted to enter a host while already in another host.")
	if (get_host_max_blood(host) <= 0)
		return FALSE

	slime.forceMove(host)
	swap_state(BLOOD_SLIME_STATE_DORMANT)

	current_host = host

	current_host.blood_volume = min(current_host.blood_volume + get_blood_amount(), get_host_max_blood())
	set_blood_amount(current_host.blood_volume)

	return TRUE

/datum/antagonist/blood_slime/proc/stop_host_control()
	if (isnull(current_host))
		CRASH("[slime] ([owner]) attempted to stop controlling a nonexistent host.")
	UnregisterSignal(current_host, COMSIG_LIVING_DEATH)
	swap_state(BLOOD_SLIME_STATE_DORMANT)
	REMOVE_TRAITS_IN(current_host, BLOODCONTROL_TRAIT)
	return_host_senses()
	if(current_host.mind != owner)
		return
	owner.transfer_to(slime)
	if(host_mind)
		host_mind.transfer_to(current_host)
		host_mind = null

/**
 * Causes the slime to leave it's current host with an animation.
 *
 * Arguments:
 * * max_blood - The maximum amount of blood this can take. Setting it to BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM or above will empty the host. The actual amount of blood left for the slime is further limited by get_max_blood()
 * * silent - Disables the visible message.
 * * disable_animation - Disables the animation.
 */
/datum/antagonist/blood_slime/proc/leave_host(max_blood = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM, silent = FALSE, disable_animation = FALSE)
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to leave a host that doesn't exist.")

	set_blood_amount(min(get_host_blood_amount(), max_blood), ignore_host_sync = TRUE)

	set_host_blood_amount(get_host_blood_amount() - get_blood_amount(), ignore_slime_sync = TRUE)

	if (!disable_animation)
		flick("emerge", slime)

	stop_host_control()
	slime.forceMove(current_host.drop_location())

	if (!silent)
		slime.visible_message(
			span_danger("\The [src] emerges from [current_host]!"),
			span_notice("You emerge from your host."),
			span_hear("You hear a sudden gush of liquid!"),
			ignored_mobs = current_host
		)
		to_chat(current_host, span_userdanger("You feel a sudden rush of blood escape your body... you feel woozy..."))

	if (current_host.blood_volume < BLOOD_VOLUME_SURVIVE && !HAS_TRAIT(current_host, TRAIT_NODEATH))
		current_host.death()

	swap_state(BLOOD_SLIME_STATE_SOLO)

	current_host = null

/// Gets the maximum blood amount of the slime itself.
/datum/antagonist/blood_slime/proc/get_max_blood()
	. = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM

	if (current_state == BLOOD_SLIME_STATE_SPLIT)
		. *= 0.5

/// Gets the maximum blood amount of the host. Prosthetics and missing limbs can't contain blood. (prosthetics since they can't bleed and would be OP otherwise)
/datum/antagonist/blood_slime/proc/get_host_max_blood(mob/living/carbon/human/host_override = null)
	var/mob/living/carbon/human/host = host_override ? host_override : current_host

	if (!host)
		CRASH("[slime] ([owner]) tried to check the maximum blood amount of a nonexistent host.")

	if (HAS_TRAIT(host, TRAIT_NOBLOOD) || host.dna.species.exotic_blood) // no randomly turning into liquid electricity or going into a skeleton
		return 0

	. = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM

	if (current_state == BLOOD_SLIME_STATE_SPLIT)
		. *= 0.5

	var/suitable_limbs = 0

	for (var/obj/item/bodypart/limb in host.bodyparts)
		if (!IS_ROBOTIC_LIMB(limb))
			suitable_limbs += 1

	// preparing for the day that we get more limbs (we probably wont, but magic numbers aren't great either)
	. = min(., BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * suitable_limbs / (host.bodyparts.len + host.get_missing_limbs().len))

/// Returns how much blood the blood slime currently holds.
/datum/antagonist/blood_slime/proc/get_blood_amount()
	return slime.health * BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM / slime.maxHealth

/// Sets the blood amount of the blood slime to the given amount.
/datum/antagonist/blood_slime/proc/set_blood_amount(amount, ignore_host_sync)
	slime.setBruteLoss(slime.maxHealth - amount * slime.maxHealth / BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM) // it was bruteloss all along
	if (slime.loc == current_host && !ignore_host_sync)
		set_host_blood_amount(amount, ignore_slime_sync = TRUE)

/// Adjusts the blood amount of the blood slime by the given amount.
/datum/antagonist/blood_slime/proc/adjust_blood_amount(amount, ignore_host_sync)
	set_blood_amount(get_blood_amount() + amount, ignore_host_sync)

/// Returns how much blood the blood slime's host currently holds.
/datum/antagonist/blood_slime/proc/get_host_blood_amount()
	return current_host ? clamp(current_host.blood_volume, 0, get_host_max_blood()) : 0

/// Sets the blood amount of the blood slime's host to the given amount.
/datum/antagonist/blood_slime/proc/set_host_blood_amount(amount, ignore_slime_sync)
	if (!current_host)
		return
	current_host.blood_volume = clamp(amount, 0, get_host_max_blood())
	if (slime.loc == current_host && !ignore_slime_sync)
		set_blood_amount(amount, ignore_host_sync = TRUE)

/// Adjusts the blood amount of the blood slime's host by the given amount.
/datum/antagonist/blood_slime/proc/adjust_host_blood_amount(amount, ignore_slime_sync)
	set_host_blood_amount(get_host_blood_amount() + amount, ignore_slime_sync)

/// Handles blood processing in a host, called from /mob/living/carbon/human/handle_blood() after a check for TRAIT_BLOODSLIME_CONTROL
/datum/antagonist/blood_slime/proc/handle_blood(seconds_per_tick, times_fired)
	if (!current_host)
		CRASH("[slime] ([owner]) is somehow processing blood in a host while it doesn't even have a reference to them. Something has gone hilariously wrong.")

	adjust_host_blood_amount(BLOOD_SLIME_REGEN_FACTOR * seconds_per_tick, ignore_slime_sync = TRUE) // regen blood, desyncs blood_volume from the slimes bruteloss

	current_host.handle_bleeding(seconds_per_tick, times_fired) // handle bleeding

	set_blood_amount(current_host.blood_volume, ignore_host_sync = TRUE) // resync

/// Makes the blood slime subjugate its host.
/datum/antagonist/blood_slime/proc/subjugate_host()
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to subjugate a host that doesn't exist.")

	if(current_host.stat != DEAD || current_host.health <= HEALTH_THRESHOLD_DEAD)
		return

	for(var/trait in subjugation_traits)
		ADD_TRAIT(current_host, trait, BLOODCONTROL_TRAIT)

	control_host()

	swap_state(BLOOD_SLIME_STATE_SUBJUGATION)

/// Makes the blood slime marionette its host.
/datum/antagonist/blood_slime/proc/marionette_host()
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to marionette a host that doesn't exist.")

	if(current_host.stat != DEAD)
		return

	for(var/trait in marionette_traits)
		ADD_TRAIT(current_host, trait, BLOODCONTROL_TRAIT)

	control_host()

	swap_state(BLOOD_SLIME_STATE_MARIONETTE)

/// Makes the blood slime control its host. Not sanity checked.
/datum/antagonist/blood_slime/proc/control_host()
	if(current_host.mind)
		host_mind = current_host.mind

	current_host.revive()
	owner.transfer_to(current_host)

	replace_host_senses()

/datum/antagonist/blood_slime/proc/host_is_kil(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(gibbed)
		leave_host(silent = TRUE, disable_animation = TRUE)
		return
	stop_host_control()

/// Replaces the current host's senses with our own.
/datum/antagonist/blood_slime/proc/replace_host_senses()
	if (!current_host)
		return

	if (eyes?.loc != slime && (!eyes?.owner || eyes.owner != current_host))
		eyes = new()
		eyes.apply_organ_damage(eyes.maxHealth) // start out really damaged so you can't rip failing ones out to grow functioning ones
		eyes.Insert(current_host, special = TRUE)
		current_host.visible_message(
			message = span_bolddanger("[current_host] suddenly grows a pair of membranes in place of their eyes!"),
			self_message = current_host == owner.current ? null : span_boldnotice("You feel something growing in place of your eyes."),
			blind_message = span_hear("You hear a loud and wet crunch."),
			ignored_mobs = owner.current
		)
		to_chat(owner.current, span_warning("You grow a pair of unfinished visual membranes in place of the ones you lost."))
	if (eyes?.loc != slime && (!ears?.owner || ears.owner != current_host))
		ears = new()
		ears.apply_organ_damage(ears.maxHealth) // start out really damaged so you can't rip failing ones out to grow functioning ones
		ears.Insert(current_host, special = TRUE)
		current_host.visible_message(
			message = span_bolddanger("[current_host] suddenly grows a pair of membranes in place of their ears!"),
			self_message = current_host == owner.current ? null : span_boldnotice("You feel something growing in place of your ears."),
			blind_message = span_hear("You hear a loud and wet crunch."),
			ignored_mobs = owner.current
		)
		to_chat(owner.current, span_warning("You grow a pair of unfinished acoustic membranes in place of the ones you lost."))

	eyes.Insert(current_host, special = TRUE)
	ears.Insert(current_host, special = TRUE)

/// Returns the current host's senses back to their own.
/datum/antagonist/blood_slime/proc/return_host_senses()
	if (!eyes)
		eyes = new()
	if (!ears)
		ears = new()
	if (current_host)
		if (eyes.owner == current_host)
			eyes.Remove(current_host, special = TRUE)
			eyes.covered.Insert(current_host, special = TRUE)
			eyes.covered.organ_flags &= ~ORGAN_FROZEN
		if (eyes.owner == current_host)
			ears.Remove(current_host, special = TRUE)
			ears.covered.Insert(current_host, special = TRUE)
			ears.covered.organ_flags &= ~ORGAN_FROZEN
	eyes.forceMove(slime)
	ears.forceMove(slime)
