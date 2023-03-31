/mob/living/carbon/human/register_init_signals()
	. = ..()

	RegisterSignals(src, list(SIGNAL_ADDTRAIT(TRAIT_UNKNOWN), SIGNAL_REMOVETRAIT(TRAIT_UNKNOWN)), PROC_REF(on_unknown_trait))
	RegisterSignals(src, list(SIGNAL_ADDTRAIT(TRAIT_DWARF), SIGNAL_REMOVETRAIT(TRAIT_DWARF)), PROC_REF(on_dwarf_trait))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_NOPASSOUT), PROC_REF(on_nopassout_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_NOPASSOUT), PROC_REF(on_nopassout_trait_loss))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_NOHARDCRIT), PROC_REF(on_nohardcrit_trait_gain))

/// Gaining or losing [TRAIT_UNKNOWN] updates our name and our sechud
/mob/living/carbon/human/proc/on_unknown_trait(datum/source)
	SIGNAL_HANDLER

	name = get_visible_name()
	sec_hud_set_ID()

/// Gaining or losing [TRAIT_DWARF] updates our height
/mob/living/carbon/human/proc/on_dwarf_trait(datum/source)
	SIGNAL_HANDLER

	// We need to regenerate everything for height
	regenerate_icons()
	// Toggle passtable
	if(HAS_TRAIT(src, TRAIT_DWARF))
		passtable_on(src, TRAIT_DWARF)
	else
		passtable_off(src, TRAIT_DWARF)

/mob/living/carbon/human/proc/on_nopassout_trait_gain(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/mob/living/carbon/human/proc/on_nopassout_trait_loss(datum/source)
	SIGNAL_HANDLER
	check_passout(oxyloss)

/mob/living/carbon/human/proc/on_nohardcrit_trait_gain(datum/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)
