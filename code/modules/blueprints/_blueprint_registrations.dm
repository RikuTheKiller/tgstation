/// Updates the current turf of the blueprint.
/// This is a private proc, don't call or override it from subtypes.
/obj/structure/blueprint/proc/update_current_turf()
	PRIVATE_PROC(TRUE)

	if (!isturf(loc))
		if (!QDELETED(src))
			qdel(src)
		return
	if (loc == current_turf)
		return

	unregister_current_turf()
	register_current_turf(loc)

/// Registers the given turf as the new current turf of the blueprint.
/// This is a private proc, don't call or override it from subtypes.
/obj/structure/blueprint/proc/register_current_turf(turf/new_turf)
	PRIVATE_PROC(TRUE)

	if (current_turf || QDELETED(src) || QDELETED(new_turf))
		return

	current_turf = new_turf
	RegisterSignals(current_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON), PROC_REF(on_current_turf_entered))

	find_new_object_to_work_on()

/// Unregisters the current turf of the blueprint.
/// This is a private proc, don't call or override it from subtypes.
/obj/structure/blueprint/proc/unregister_current_turf()
	PRIVATE_PROC(TRUE)

	if (!current_turf)
		return

	unregister_current_object()

	UnregisterSignal(current_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON))
	current_turf = null

// Note that this proc takes two signals that share the first two arguments.
/obj/structure/blueprint/proc/on_current_turf_entered(turf/our_turf, atom/movable/arrived)
	SIGNAL_HANDLER
	if (!current_object)
		try_work_on(arrived)

/// Unregisters the current object the blueprint is working on, and attempts to find a new one.
/obj/structure/blueprint/proc/find_new_object_to_work_on()
	if (QDELETED(src) || !current_turf)
		return

	base_unregister_current_object()

	for (var/obj/object in current_turf)
		if (try_work_on(object))
			break

/// Tries to register a new object for the blueprint to work on.
/// Returns whether the object can be worked on, but doesn't guarantee that current_object is set.
/obj/structure/blueprint/proc/try_work_on(atom/movable/atom_to_check)
	if (base_can_work_on(atom_to_check))
		base_register_current_object(atom_to_check)
		return TRUE

/// Call site for checking whether the blueprint can work on a given atom. Do not override.
/obj/structure/blueprint/proc/base_can_work_on(atom/movable/atom_to_check)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (QDELETED(atom_to_check))
		return FALSE
	if (!isobj(atom_to_check))
		return FALSE
	return can_work_on(atom_to_check)

/// Returns whether the blueprinter can work on the given object.
/// To check objects call [proc/base_can_work_on(atom_to_check)] instead.
/obj/structure/blueprint/proc/can_work_on(obj/object)
	return TRUE

/// Call site for the register current object chain. Do not override.
/obj/structure/blueprint/proc/base_register_current_object(obj/new_object)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (current_object || QDELETED(src) || QDELETED(new_object))
		return

	current_object = new_object

	RegisterSignal(current_object, COMSIG_QDELETING, PROC_REF(on_current_object_qdeleting))
	RegisterSignal(current_object, COMSIG_MOVABLE_MOVED, PROC_REF(on_current_object_moved))
	register_current_object()

/// Call site for the unregister current object chain. Do not override.
/obj/structure/blueprint/proc/base_unregister_current_object()
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!current_object)
		return

	UnregisterSignal(current_object, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED))
	unregister_current_object()

	current_object = null

/// Registers the current object that the blueprint is working on.
/// To register new objects call [proc/base_register_current_object(new_object)] instead.
/obj/structure/blueprint/proc/register_current_object()
	return

/// Unregisters the current object that the blueprint is working on.
/// To unregister the current object call [proc/base_unregister_current_object()] instead.
/obj/structure/blueprint/proc/unregister_current_object()
	return

/obj/structure/blueprint/proc/on_current_object_qdeleting(obj/object, force)
	SIGNAL_HANDLER
	find_new_object_to_work_on()

/obj/structure/blueprint/proc/on_current_object_moved(obj/object, turf/our_turf, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	find_new_object_to_work_on()
