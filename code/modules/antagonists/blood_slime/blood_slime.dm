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

	/// How much blood the slime currently holds, only used when outside of a host. Use get_blood_amount() for abilities and such.
	var/blood_amount = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM

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
	var/list/subjugation_traits = list(
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
		TRAIT_NOFAT // we just eat the fat, slime moment (also it would be a problem without hunger, even if especially rare)
	)

	/// Traits given to our host during marionette.
	var/list/marionette_traits = list(
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
		TRAIT_NOBREATH, // dead people don't breathe (most things that don't process while dead shouldn't process during marionette, yet another difficult thing to do without shitcode)
		TRAIT_LIVERLESS_METABOLISM, // they also don't metabolize (mostly a downside since you can't use healing meds to make a corpse suitable for subjugation)
		TRAIT_FAKEDEATH // it's just a regular corpse, trust (mostly for aesthetics, though it can be used to fake death)
	)

	/// Traits given to our host during symbiosis. (symbiosis has a lot of downsides, however it has a couple unique benefits)
	var/list/symbiosis_traits = list(
		TRAIT_BLOODSLIME_SYMBIOSIS, // grants the host immunity to the side effects of blood slime conversion
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER,
		TRAIT_NOFAT
	)

	/// Action used to leave our current host. (emerge)
	var/datum/action/bloodslime/delayed_host_action/leave_host/leave_host

	/// Action used to subjugate a corpse.
	var/datum/action/bloodslime/delayed_host_action/subjugate/leave_host

/datum/antagonist/blood_slime/New()
	. = ..()
	allowed_antags_typecache = typecacheof(allowed_antags_typecache)
	disallowed_quirks_typecache = typecacheof(disallowed_quirks_typecache)

/datum/antagonist/blood_slime/on_gain()
	return ..()

/// Causes the slime to enter the target host with an animation.
/datum/antagonist/blood_slime/proc/enter_host(mob/living/carbon/human/host, silent = FALSE)
	if (!host)
		CRASH("[slime] ([owner]) attempted to enter a host that doesn't exist.")
	if (current_host)
		CRASH("[slime] ([owner]) attempted to enter a host while already in another host.")

	slime.forceMove(host)

	current_host = host
	current_host.blood_volume = min(current_host.blood_volume + blood_amount, BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM)

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

	blood_amount = min(current_host.blood_volume, max_blood, get_max_blood()) // just in case the host's blood_volume is somehow above get_max_blood() even though that should never happen

	current_host.blood_volume = max_blood < BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM ? max(current_host.blood_volume - blood_amount, 0) : 0

	if (!disable_animation)
		flick("emerge", slime)

	slime.forceMove(current_host.drop_location())

	if (!silent)
		slime.visible_message(span_danger("\The [src] gushes out of [current_host]!"), span_notice("You emerge from [current_host]."), span_hear("You hear a sudden gush of liquid!"), ignored_mobs = list(current_host))

	if (current_host.blood_volume < BLOOD_VOLUME_SURVIVE)


	current_host = null

/// Gets the maximum blood amount of the slime. Prosthetics and missing limbs on a host can't contain blood. (prosthetics since they can't bleed and would be OP otherwise)
/datum/antagonist/blood_slime/proc/get_max_blood()
	if (!current_host)
		return BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM

	var/suitable_limbs = 0

	for (var/obj/item/bodypart/limb in current_host.bodyparts)
		if (!IS_ROBOTIC_LIMB(limb))
			suitable_limbs += 1

	return BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM * suitable_limbs / (current_host.bodyparts.len + current_host.get_missing_limbs().len) // preparing for the day that we get more limbs (we probably wont, but magic numbers aren't great either)

/// Handles blood processing in a host, called from /mob/living/carbon/human/handle_blood() after a check for TRAIT_BLOODSLIME_CONTROL
/datum/antagonist/blood_slime/proc/handle_blood(seconds_per_tick, times_fired)
	if (!current_host)
		CRASH("[slime] ([owner]) is somehow processing blood in a host while it doesn't even have a reference to them. Something has gone hilariously wrong.")

	current_host.blood_volume += BLOOD_SLIME_REGEN_FACTOR * seconds_per_tick

	current_host.blood_volume = min(current_host.blood_volume, get_max_blood()) // limit blood volume to max

/datum/antagonist/blood_slime/proc/subjugate_host()
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to subjugate a host that doesn't exist.")
