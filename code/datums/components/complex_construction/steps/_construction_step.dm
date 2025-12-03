// A verbose and modular implementation of construction steps.
// You can dynamically override or hook into any part of this.
// A basic setup is incredibly easy and usually sufficient.

// Basic setup:
// - Use the basic duration, req_x and result_x vars.
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

	/// An assoc list of the types of the result movables. Format is [type = amount]
	/// You can use [proc/get_result_types] to dynamically override the final value.
	/// Putting turf types here is fully supported.
	var/result_types = list()

	/// Construction flags, the default is always NONE.
	/// Defined in _DEFINES/complex_construction.dm
	var/construction_flags = NONE

	/// Target handling type, such as deletion, destruction or disassembly.
	/// Defined in _DEFINES/complex_construction.dm
	var/target_handling = NONE

	/// The text in the starting balloon alert for this step. (e.g. "adding plating...")
	var/starting_alert_text = null
	/// The text in the completion balloon alert for this step. (e.g. "added plating")
	/// Usually not necessary unless you need to communicate a specific result.
	var/completion_alert_text = null
	/// The volume of the sound made by the tool used.
	var/tool_use_volume = 100

/// Has the user attempt this step and returns whether they succeeded. Blocking.
/// For a non-blocking variant, use [proc/try_start_async] instead.
/datum/construction_step/proc/try_start(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	var/list/reqs = get_reqs(user, used_item, target, modifiers)

	if (!can_start(user, used_item, target, modifiers, reqs))
		return FALSE

	return try_complete(user, used_item, target, modifiers, reqs)

/// Has the user attempt this step and returns whether they were able to start. Non-blocking.
/// For a blocking variant, use [proc/try_start] instead.
/datum/construction_step/proc/try_start_async(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)
	SHOULD_NOT_SLEEP(TRUE)

	var/list/reqs = get_reqs(user, used_item, target, modifiers)

	if (!can_start(user, used_item, target, modifiers, reqs))
		return FALSE

	INVOKE_ASYNC(src, PROC_REF(try_complete), user, used_item, target, modifiers, reqs)
	return TRUE

/// Has the user attempt this step and returns whether they succeeded.
/// Don't call this directly, call [proc/try_start] or [proc/try_start_async] instead.
/datum/construction_step/proc/try_complete(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	PRIVATE_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	on_started(user, used_item, target, modifiers)

	var/duration = get_duration(user, used_item, target, modifiers)
	var/req_item_amount = reqs[CONSTRUCTION_REQ_ITEM_AMOUNT]
	var/extra_checks = CALLBACK(src, PROC_REF(can_complete), user, used_item, target, modifiers, reqs)

	if (!used_item.use_tool(target, user, duration, req_item_amount, tool_use_volume, extra_checks))
		return FALSE

	var/list/results = get_results(user, used_item, target, modifiers)

	on_completed(user, used_item, target, modifiers, results)

	return TRUE

/// Returns a list of requirements for this step.
/// List indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/get_reqs(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_CALL_PARENT(TRUE)

	return list(
		CONSTRUCTION_REQ_ITEM_TYPE = get_req_item_type(user, used_item, target, modifiers),
		CONSTRUCTION_REQ_ITEM_AMOUNT = get_req_item_amount(user, used_item, target, modifiers),
		CONSTRUCTION_REQ_TOOL_BEHAVIOUR = get_req_tool_behaviour(user, used_item, target, modifiers),
	)

/// Returns whether the user can start this step. Called only at the start of the step. Can be used for feedback.
/datum/construction_step/proc/can_start(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	SHOULD_CALL_PARENT(TRUE)

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
	SHOULD_CALL_PARENT(TRUE)

	if (!(construction_flags & CONSTRUCTION_NO_FINGERPRINTS))
		used_item.add_fingerprint(user)
		target.add_fingerprint(user)

/// Returns the list of result /atom/movable instances.
/// Post processing like fingerprints should be done in [proc/on_completed].
/// List indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/get_results(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	var/list/results = list()

	for (var/result_type in result_types)
		var/result_amount = result_types[result_type]
		if (result_amount)
			results += get_results_of_type(user, used_item, target, modifiers, result_type, result_amount)

	var/list/valid_results = list()
	for (var/atom/movable/result as anything in results)
		if (!QDELETED(result)) // Evil instant stack mergers, mainly.
			valid_results += result

	return valid_results

/// Returns a list of /atom/movable instances based on a result type and an amount.
/// You can override this to add custom getters for any specific types you want.
/datum/construction_step/proc/get_results_of_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, result_type, result_amount)
	if (ispath(result_type, /turf))
		return get_result_turfs_of_type(user, used_item, target, modifiers, result_type, result_amount)
	if (ispath(result_type, /obj/item/stack))
		return get_result_stacks_of_type(user, used_item, target, modifiers, result_type, result_amount)
	if (ispath(result_type, /atom/movable))
		return get_result_atoms_of_type(user, used_item, target, modifiers, result_type, result_amount)

	CRASH("Construction step of type \"[type]\" failed to create construction step result of type \"[result_type]\"")

/// Returns a list of result turfs based on a result type and an amount.
/datum/construction_step/proc/get_result_turfs_of_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, turf/result_type, result_amount)
	. = list()
	for (var/i in 1 to result_amount)
		var/turf/current_turf = get_turf(target)
		if (!current_turf)
			break
		. += current_turf.place_on_top(result_type)

/// Returns a list of result stacks based on a result type and an amount.
/datum/construction_step/proc/get_result_stacks_of_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, obj/item/stack/result_type, result_amount)
	. = list()
	var/max_amount = result_type::max_amount
	if (!max_amount)
		return

	while (result_amount > 0)
		var/drop_loc = target.drop_location()
		if (!drop_loc)
			break
		var/stack_amount = min(result_amount, max_amount)
		. += new result_type(drop_loc, stack_amount)
		result_amount -= stack_amount

/// Returns a list of result generic atoms based on a result type and an amount.
/datum/construction_step/proc/get_result_atoms_of_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, atom/movable/result_type, result_amount)
	. = list()
	for (var/i in 1 to result_amount)
		var/drop_loc = target.drop_location()
		if (!drop_loc)
			break
		. += new result_type(drop_loc)

/// Called after the step is completed. Can be used for feedback.
/// Passes in the reqs and results of the step, indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/on_completed(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/results)
	SHOULD_CALL_PARENT(TRUE)

	if (!(construction_flags & CONSTRUCTION_NO_FINGERPRINTS))
		for (var/atom/movable/result as anything in results)
			result.add_fingerprint(user)

	switch (target_handling)
		if (CONSTRUCTION_DELETE_TARGET)
			qdel(target)
		if (CONSTRUCTION_DESTROY_TARGET)
			astype(target, /obj)?.deconstruct(disassembled = FALSE)
		if (CONSTRUCTION_DISASSEMBLE_TARGET)
			astype(target, /obj)?.deconstruct(disassembled = TRUE)

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

/// Returns the final list of the result types.
/datum/construction_step/proc/get_result_types(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return result_types
