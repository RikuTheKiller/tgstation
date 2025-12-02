// A manager for a list of construction steps.
// Runs through steps in order and tries the first one the user can complete.

/datum/component/complex_construction
	can_transfer = TRUE

	var/list/datum/construction_step/steps = list()

/datum/component/complex_construction/Initialize(step_types)
	if (!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	if (!length(step_types))
		return COMPONENT_REDUNDANT

	for (var/step_type in step_types)
		steps += new step_type()

/datum/component/complex_construction/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interaction))

/datum/component/complex_construction/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_ITEM_INTERACTION)

/datum/component/complex_construction/proc/on_item_interaction(atom/movable/target, mob/living/user, obj/item/used_item, list/modifiers)
	SIGNAL_HANDLER

	if (user.combat_mode)
		return

	for (var/datum/construction_step/step as anything in steps)
		if (step.try_start_async(user, used_item, target, modifiers))
			break

	return ITEM_INTERACT_BLOCKING
