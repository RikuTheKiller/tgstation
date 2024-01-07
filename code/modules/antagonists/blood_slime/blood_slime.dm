/datum/antagonist/blood_slime
    name = "\improper Blood Slime"
    antagpanel_category = ANTAG_GROUP_BIOHAZARDS // either biohazard or horror works, but biohazard is more applicable here
    show_name_in_check_antagonists = TRUE
    show_to_ghosts = TRUE // somewhat stealthy, but not enough to be hidden from ghosts
    default_custom_objective = "Gather blood and grow stronger to wreak havoc on the station." // tiny reference to the rampage ability (fix this shit later)

    /// How much blood the slime currently holds, only used when outside of a host. Use get_blood_amount() for abilities and such.
    var/blood_amount

    /// The current host, if we're inside of one.
    var/mob/living/carbon/human/current_host

    /// The current hosts mind datum.
    var/datum/mind/host_mind

    /// The current hosts antag datums.
    var/list/datum/antagonist/host_antags

    /// Our extra antag datums, mostly for keeping track of conversion antags when transferring bodies.
    var/list/datum/antagonist/extra_antags

    /// Antag datums that are allowed to coexist with us.
    var/list/datum/antagonist/allowed_antags = list(/datum/antagonist/cult)

    /// Traits given to our host during subjugation.
    var/list/subjugation_traits = list(
        TRAIT_MUTE,
        TRAIT_SLEEPIMMUNE,
        TRAIT_STUNIMMUNE,
        TRAIT_NODEATH,
        TRAIT_NOCRITDAMAGE,
        TRAIT_NOCRITOVERLAY,
        TRAIT_NOSOFTCRIT,
        TRAIT_NOHARDCRIT,
        TRAIT_NOHUNGER,
        TRAIT_NOFAT
    )

    /// Traits given to our host during marionette.
    var/list/marionette_traits = list(
        TRAIT_MUTE,
        TRAIT_ILLITERATE,
        TRAIT_SLEEPIMMUNE,
        TRAIT_STUNIMMUNE,
        TRAIT_NODEATH,
        TRAIT_NOCRITDAMAGE,
        TRAIT_NOCRITOVERLAY,
        TRAIT_NOSOFTCRIT,
        TRAIT_NOHARDCRIT,
        TRAIT_NOHUNGER,
        TRAIT_NOFAT,
        TRAIT_LIVERLESS_METABOLISM
    )

    /// Traits given to our host during symbiosis.
    var/list/symbiosis_traits = list(
        TRAIT_NODEATH,
        TRAIT_NOCRITDAMAGE,
        TRAIT_NOCRITOVERLAY,
        TRAIT_NOSOFTCRIT,
        TRAIT_NOHARDCRIT
    )
