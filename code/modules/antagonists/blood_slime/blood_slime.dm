/datum/antagonist/blood_slime
	name = "\improper Blood Slime"
	antagpanel_category = ANTAG_GROUP_BIOHAZARDS // either biohazard or horror works, but biohazard is more applicable here
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE // somewhat stealthy, but not enough to be hidden from ghosts
	default_custom_objective = "Gather blood and grow stronger to wreak havoc on the station." // tiny reference to the rampage ability (fix this shit later)

	/// The blood slime basic mob, if it exists. (stored in host contents)
	var/mob/living/basic/blood_slime/slime

	/// How much blood the slime currently holds, only used when outside of a host. Use get_blood_amount() for abilities and such.
	var/blood_amount

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
		TRAIT_RDS_SUPPRESSED, // our host being crazy doesn't make us crazy
		TRAIT_MADNESS_IMMUNE,
		TRAIT_SLEEPIMMUNE, // we don't have a brain
		TRAIT_NODEATH, // we handle "death" via marionette and bleeding out
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER, // the host feeds us and we feed the host (can't carry food as a slime so it'd get annoying quick)
		TRAIT_NOFAT // we just eat the fat, slime moment (also it would be a problem without hunger)
	)

	/// Traits given to our host during marionette.
	var/list/marionette_traits = list(
		TRAIT_BLOODSLIME_MARIONETTE,
		TRAIT_MUTE,
		TRAIT_RDS_SUPPRESSED,
		TRAIT_MADNESS_IMMUNE,
		TRAIT_ILLITERATE, // a slime on it's own isn't intelligent enough to read human language
		TRAIT_DISCOORDINATED_TOOL_USER, // same goes for operating machinery (also corpses lack dexterity)
		TRAIT_SLEEPIMMUNE,
		TRAIT_STUNIMMUNE, // slugfest, we can't stun and we can't be stunned
		TRAIT_NODEATH,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOCRITOVERLAY,
		TRAIT_NOSOFTCRIT,
		TRAIT_NOHARDCRIT,
		TRAIT_NOHUNGER,
		TRAIT_NOFAT,
		TRAIT_NOBREATH, // dead people don't breathe
		TRAIT_LIVERLESS_METABOLISM, // they also don't metabolize
		TRAIT_FAKEDEATH // it's just a regular corpse, trust
	)

	/// Traits given to our host during symbiosis.
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
/datum/antagonist/blood_slime/proc/leave_host()
	if (!current_host)
		CRASH("[slime] ([owner]) attempted to leave a host that doesn't exist.") // REALLY shouldn't happen outside of admin shenanigans

	flick("emerge", slime)

	slime.forceMove(current_host.drop_location())

	slime.visible_message(span_danger("\The [src] gushes out of [current_host]!"), span_notice("You emerge from [current_host]."), span_hear("You hear a sudden gush of liquid!"), ignored_mobs = list(current_host))

	current_host = null
