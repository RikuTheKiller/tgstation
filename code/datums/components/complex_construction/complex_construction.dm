// A dispatcher for [datum/construction_controller]

/datum/component/complex_construction
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	can_transfer = TRUE

	var/datum/construction_controller/controller = null

/datum/component/complex_construction/Initialize(controller)
	if (!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

	set_controller(controller)

/datum/component/complex_construction/InheritComponent(datum/component/complex_construction/new_component, original, controller)
	set_controller(controller)

/datum/component/complex_construction/proc/set_controller(controller_or_type)
	if (ispath(controller_or_type, /datum/construction_controller))
		src.controller = new controller_or_type()
	else if (istype(controller_or_type, /datum/construction_controller))
		src.controller = controller_or_type
	else
		CRASH("Attempted to set the construction controller of a complex construction controller to invalid type or instance \"[controller_or_type]\".")

/datum/component/complex_construction/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interaction))

/datum/component/complex_construction/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_ITEM_INTERACTION)

/datum/component/complex_construction/proc/on_item_interaction(atom/movable/target, mob/living/user, obj/item/used_item, list/modifiers)
	SIGNAL_HANDLER

	if (user.combat_mode)
		return

	controller.set_context(user, used_item, target, modifiers)
	. = controller.run_controller(user, used_item, target, modifiers)
	controller.clear_context()
