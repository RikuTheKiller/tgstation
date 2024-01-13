/datum/antagonist/blood_slime
	name = "\improper Blood Slime"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS // either biohazard or horror works, but biohazard is more applicable here
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE // somewhat stealthy, but not enough to be hidden from ghosts
	default_custom_objective = "Gather blood and grow stronger to wreak havoc on the station." // tiny reference to the rampage ability (fix this shit later)

	/// The blood slime basic mob, if it exists. (stored in host contents)
	var/mob/living/basic/blood_slime/slime

	/// How much blood the slime currently holds, only used when outside of a host. Use get_blood_amount() for abilities and such.
	var/blood_amount = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM

	/// The current host, if we're inside of one.
	var/mob/living/carbon/human/current_host

	/// The current hosts mind datum.
	var/datum/mind/host_mind

	/// The current hosts antag datums.
	var/list/datum/antagonist/host_antags = list()

	/// The current hosts brain traumas.
	var/list/datum/brain_trauma/host_traumas = list()

	/// Our extra antag datums, mostly for keeping track of conversion antags when transferring bodies.
	var/list/datum/antagonist/extra_antags = list()

	/// Antag datums that are allowed to coexist with us.
	var/list/datum/antagonist/allowed_antags = list(/datum/antagonist/cult)

	/// Traits given to our host during subjugation.
	var/list/subjugation_traits = list(
		TRAIT_BLOODSLIME_SUBJUGATION,
		TRAIT_MUTE, // sadly slime language doesn't really translate too well
		TRAIT_RDS_SUPPRESSED, // our host being crazy doesn't make us crazy (also having to deal with mental host quirks would be annoying, though we can't/shouldn't do anything about most of them)
		TRAIT_MADNESS_IMMUNE, // ideally nothing "mental" should affect us similarly to our basic mob slime form (exceptionally hard to achieve without shitcode)
		TRAIT_SLEEPIMMUNE, // we don't have a brain, also encourages slugfest which is a primary goal of the antag
		TRAIT_NODEATH, // we handle "death" via marionette and bleeding out (this, alongside the crit traits, are the most insane traits of blood slime)
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER, // the host feeds us and we feed the host (can't carry food as a slime so it'd get annoying quick, especially if you took over a host and they turned out to be starved to uselessness)
		TRAIT_NOFAT // we just eat the fat, slime moment (also it would be a problem without hunger)
	)

	/// Traits given to our host during marionette.
	var/list/marionette_traits = list(
		TRAIT_BLOODSLIME_MARIONETTE,
		TRAIT_MUTE,
		TRAIT_RDS_SUPPRESSED,
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
		TRAIT_LIVERLESS_METABOLISM, // they also don't metabolize (mostly a downside since you can't use ez healing meds to make a corpse suitable for subjugation)
		TRAIT_FAKEDEATH // it's just a regular corpse, trust (mostly for aesthetics, though it can be used to fake death)
	)

	/// Traits given to our host during symbiosis. (symbiosis has a lot of downsides, however it has a couple unique benefits)
	var/list/symbiosis_traits = list(
		TRAIT_BLOODSLIME_SYMBIOSIS,
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER,
		TRAIT_NOFAT
	)

	/// Action used to leave our current host.
	var/datum/action/leave_host

/// Causes the slime to enter the target host with an animation.
/datum/antagonist/blood_slime/proc/enter_host(/mob/living/carbon/human/host)
	slime.forceMove(host)
	current_host = host

/// Causes the slime to leave it's current host with an animation.
/// Setting max_blood will limit the amount of blood this takes from the host.
/datum/antagonist/blood_slime/proc/leave_host(var/max_blood = BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM)
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to leave a host that doesn't exist.") // REALLY shouldn't happen outside of admin shenanigans

	blood_amount = min(current_host.blood_volume, max_blood)
	current_host.blood_volume = max(current_host.blood_volume - blood_amount, 0) // host blood is limited to BLOOD_VOLUME_BLOOD_SLIME_MAXIMUM when inhabited by a blood slime

	flick("emerge", slime)

	slime.forceMove(current_host.drop_location())

	slime.visible_message(span_danger("\The [src] gushes out of [current_host]!"), span_notice("You emerge from [current_host]."), span_hear("You hear a sudden gush of liquid!"), ignored_mobs = list(current_host))

	current_host = null
