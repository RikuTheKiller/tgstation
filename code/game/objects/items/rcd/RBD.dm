/obj/item/blueprinter
	name = "rapid-blueprinting-device (RBD)"
	desc = "A device for creating blueprints that guide and speed up construction. It has an integrated uplink for pulling the latest engineering schematics from the R&D network."

	icon = 'icons/obj/tools.dmi'
	icon_state = "rcd"

/obj/item/blueprinter/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if (!try_to_create_blueprint(get_turf(interacting_with)))
		return FALSE

/// Attempts to have the given user use the RBD to create the currently selected blueprint on the given turf.
/// Returns whether the action was successful.
/obj/item/blueprinter/proc/try_to_create_blueprint(turf/target_turf, mob/living/user, list/modifiers)
	if (!can_create_blueprint(target_turf))
		return FALSE

/// Returns whether the RBD can create the currently selected blueprint on the given turf.
/obj/item/blueprinter/proc/can_create_blueprint(turf/target_turf, mob/living/user, list/modifiers)
	if (!target_turf)
		return FALSE
	return TRUE

/// Creates the currently selected blueprint on the given turf.
/obj/item/blueprinter/proc/create_blueprint(turf/target_turf)
	return
