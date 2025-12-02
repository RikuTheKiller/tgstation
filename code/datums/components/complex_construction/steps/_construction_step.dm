// A verbose and modular implementation of construction steps.
// You can dynamically override or hook into any part of this.
// A basic setup is incredibly easy and usually sufficient.

// Basic setup:
// - Use the basic duration, req_x and resulting_x vars.
// - Put feedback in on_started and on_completed.
// - Congrats, you have a construction step.

/datum/construction_step
	abstract_type = /datum/construction_step

	/// The base duration of the construction step in deciseconds.
	/// Use [proc/get_duration] to get/override the final duration.
	var/duration = 0 SECONDS

	/// The type of the item required. Can be unspecified.
	/// You can use [proc/get_req_item_type] to dynamically override the final value.
	var/req_item_type = null
	/// The amount of item required. Used for stacks/fuel/charge/etc.
	/// You can use [proc/get_req_item_amount] to dynamically override the final value.
	var/req_item_amount = 0
	/// The item tool behaviour required.
	/// You can use [proc/get_req_tool_behaviour] to dynamically override the final value.
	var/req_tool_behaviour = null

	/// An assoc list of the types of the resulting atoms. Format is [type = amount]
	/// You can use [proc/get_resulting_atom_types] to dynamically override the final value.
	var/resulting_atom_types = list()
	/// The type of the resulting turf, if any.
	/// You can use [proc/get_resulting_turf_type] to dynamically override the final value.
	var/resulting_turf_type = null

	/// Construction flags, as defined in _DEFINES/complex_construction.dm
	var/construction_flags = CONSTRUCTION_APPLY_FINGERPRINTS

	/// The volume of the sound made by the tool used.
	var/tool_use_volume = 100

/// Has the user attempt this step and returns whether they succeeded. Blocking.
/// For a non-blocking variant, use [proc/try_start_async] instead.
/datum/construction_step/proc/try_start(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	var/list/reqs = get_reqs(user, used_item, target, modifiers)

	if (!can_start(user, used_item, target, modifiers, reqs))
		return FALSE

	return try_complete(user, used_item, target, modifiers, reqs)

/// Has the user attempt this step and returns whether they were able to start. Non-blocking.
/// For a blocking variant, use [proc/try_start] instead.
/datum/construction_step/proc/try_start_async(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	var/list/reqs = get_reqs(user, used_item, target, modifiers)

	if (!can_start(user, used_item, target, modifiers, reqs))
		return FALSE

	INVOKE_ASYNC(src, PROC_REF(try_complete), user, used_item, target, modifiers, reqs)
	return TRUE

/// Has the user attempt this step and returns whether they succeeded.
/// Don't call this directly, call [proc/try_start] or [proc/try_start_async] instead.
/datum/construction_step/proc/try_complete(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	PRIVATE_PROC(TRUE)

	on_started(user, used_item, target, modifiers)

	var/duration = get_duration(user, used_item, target, modifiers)
	var/req_item_amount = reqs[CONSTRUCTION_REQ_ITEM_AMOUNT]
	var/extra_checks = CALLBACK(src, PROC_REF(can_complete), user, used_item, target, modifiers, reqs)

	if (!used_item.use_tool(target, user, duration, req_item_amount, tool_use_volume, extra_checks))
		return FALSE

	var/list/results = get_results(user, used_item, target, modifiers)

	on_completed(user, used_item, target, modifiers, reqs, results)

	return TRUE

/// Returns a list of requirements for this step.
/// List indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/get_reqs(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return list(
		CONSTRUCTION_REQ_ITEM_TYPE = get_req_item_type(user, used_item, target, modifiers),
		CONSTRUCTION_REQ_ITEM_AMOUNT = get_req_item_amount(user, used_item, target, modifiers),
		CONSTRUCTION_REQ_TOOL_BEHAVIOUR = get_req_tool_behaviour(user, used_item, target, modifiers),
	)

/// Returns whether the user can start this step. Called only at the start of the step. Can be used for feedback.
/datum/construction_step/proc/can_start(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	var/req_item_type = reqs[CONSTRUCTION_REQ_ITEM_TYPE]
	if (req_item_type && !istype(used_item, req_item_type))
		return FALSE

	var/req_item_amount = reqs[CONSTRUCTION_REQ_ITEM_AMOUNT]
	if (!used_item.tool_start_check(user, req_item_amount))
		return FALSE

	var/req_tool_behaviour = reqs[CONSTRUCTION_REQ_TOOL_BEHAVIOUR]
	if (req_tool_behaviour && used_item.tool_behaviour != req_tool_behaviour)
		return FALSE

	return can_complete(user, used_item, target, modifiers, reqs)

/// Returns whether the user can do this step. Called every tick during the step. Can be used for feedback.
/datum/construction_step/proc/can_complete(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	return TRUE

/// Called when the step is started. Can be used for feedback.
/datum/construction_step/proc/on_started(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return

/// Returns the list of results.
/// List indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/get_results(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return list(
		CONSTRUCTION_RESULTING_ATOMS = get_resulting_atoms(user, used_item, target, modifiers),
		CONSTRUCTION_RESULTING_TURF = get_resulting_turf(user, used_item, target, modifiers),
	)

/// Returns the list of resulting atom instances.
/datum/construction_step/proc/get_resulting_atoms(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	var/list/resulting_atoms = list()

	var/list/resulting_atom_types = get_resulting_atom_types(user, used_item, target, modifiers)
	for (var/atom_type in resulting_atom_types)
		var/atom/new_atom = new atom_type(target.loc)
		if (!QDELETED(new_atom)) // Stack mergers, mainly.
			resulting_atoms += new_atom

	if (construction_flags & CONSTRUCTION_APPLY_FINGERPRINTS)
		for (var/atom/atom as anything in resulting_atoms)
			atom.add_fingerprint(user)

/// Returns the resulting turf instance.
/datum/construction_step/proc/get_resulting_turf(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	var/turf/target_turf = get_turf(target)
	if (!target_turf)
		return null

	var/resulting_turf_type = get_resulting_turf_type(user, used_item, target, modifiers)
	if (!resulting_turf_type)
		return null

	var/turf/resulting_turf = target_turf.place_on_top(resulting_turf_type)

	if (construction_flags & CONSTRUCTION_APPLY_FINGERPRINTS)
		resulting_turf.add_fingerprint(user)

	return resulting_turf

/// Called after the step is completed. Can be used for feedback.
/// Passes in the reqs and results of the step, indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/on_completed(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs, list/results)
	return

/// Returns the final duration.
/datum/construction_step/proc/get_duration(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return duration

/// Returns the final required item type.
/datum/construction_step/proc/get_req_item_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return req_item_type

/// Returns the final required item amount.
/datum/construction_step/proc/get_req_item_amount(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return req_item_amount

/// Returns the final required tool behavior.
/datum/construction_step/proc/get_req_tool_behaviour(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return req_tool_behaviour

/// Returns the final list of the resulting atom types.
/datum/construction_step/proc/get_resulting_atom_types(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return resulting_atom_types

/// Returns the final resulting turf type.
/datum/construction_step/proc/get_resulting_turf_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return resulting_turf_type
