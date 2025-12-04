// A manager for a list of construction steps.
// Runs through steps in order and tries the first one the user can complete.

/datum/component/complex_construction
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	can_transfer = TRUE

	var/list/datum/construction_step/steps = list()

/datum/component/complex_construction/Initialize(list/step_types)
	if (!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	if (!length(step_types))
		return COMPONENT_REDUNDANT

	for (var/step_type in step_types)
		add_construction_step(step_type)

/datum/component/complex_construction/InheritComponent(/datum/component/complex_construction/new_component, original, list/step_types)
	for (var/step_type in step_types)
		add_construction_step(step_type)

/// Takes a construction step type path and adds its shared instance to the end of the component's list.
/// If the 'prepend' argument is set to TRUE, then adds it to the beginning of the component's list instead.
/datum/component/complex_construction/proc/add_construction_step(/datum/construction_step/step_type, prepend = FALSE)
	if (step_type::abstract_type == step_type)
		CRASH("Attempted to add abstract construction step of type \"[step_type]\" to a complex construction component.")

	for (var/datum/construction_step/existing_step in steps)
		if (existing_step.type == step_type)
			CRASH("Attempted to add an already existing construction step of type \"[step_type]\" to a complex construction component.")

	var/datum/step = GLOB.construction_steps[step_type]

	if (!step)
		CRASH("Attempted to add non-existent construction step of type \"[step_type]\" to a complex construction component.")

	steps += step

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
