// A verbose and modular implementation of construction steps.
// You can dynamically override or hook into any part of this.
// A basic setup is incredibly easy and usually sufficient.

// Basic setup:
// - Use the basic duration, req_x and result_x vars.
// - Put feedback in on_started and on_completed.
// - Congrats, you have a construction step.

/// A construction step, these can do basically any construction action you need.
/// Simply check _construction_step.dm for all the different vars and such that you can tweak.
/// A basic construction step setup is incredibly simple, but this supports highly advanced stuff too.
/// Properly setting [var/abstract_type] for parent types is recommended so they aren't initialized.
/datum/construction_step
	// Setting this for abstract parents isn't absolutely necessary, but doing so enables a failsafe and prevents them from being initialized.
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
	/// Putting turf and stack types here is fully supported.
	var/result_types = list()

	/// The type the target is replaced with when the step succeeds.
	/// You can use [proc/get_replacement_type] to dynamically override the final value.
	/// Putting turf types here is fully supported, but stacks or multiple items are not.
	/// A non-null value implies a default [var/target_handling] of CONSTRUCTION_DELETE_TARGET.
	/// If [var/target_handling] is set to something other than NONE, then that will overtake this.
	var/replacement_type = null

	/// Construction flags, the default is always NONE.
	/// Defined in _DEFINES/complex_construction.dm
	var/construction_flags = NONE

	/// Target handling type, such as deletion, destruction or disassembly.
	/// You can use [proc/get_target_handling] to dynamically override the final value.
	/// Defined in _DEFINES/complex_construction.dm
	var/target_handling = NONE

	/// The text in the starting balloon alert for this step. (e.g. "adding plating...")
	var/starting_alert_text = null
	/// The text in the completion balloon alert for this step. (e.g. "added plating")
	/// Usually not necessary unless you need to communicate a specific result.
	var/completion_alert_text = null
	/// The volume of the sound made by the tool used.
	var/tool_use_volume = 100

/// Has the user attempt this step and returns whether they succeeded.
/// Handle the return value of [proc/check_interaction] first.
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

	var/replacement_type = get_replacement_type(user, used_item, target, modifiers)

	if (replacement_type)
		var/atom/replacement = get_replacement_of_type(user, used_item, target, modifiers, replacement_type)
		if (!QDELETED(replacement))
			target.transfer_fingerprints_to(replacement)
			results += replacement // Such that the replacement still gets [proc/on_completed] post-processing done to it.

	on_completed(user, used_item, target, modifiers, reqs, results)

	var/target_handling = get_target_handling(user, used_item, target, modifiers, replacement_type)

	switch (target_handling)
		if (CONSTRUCTION_DELETE_TARGET)
			qdel(target)
		if (CONSTRUCTION_DESTROY_TARGET)
			astype(target, /obj)?.deconstruct(disassembled = FALSE)
		if (CONSTRUCTION_DISASSEMBLE_TARGET)
			astype(target, /obj)?.deconstruct(disassembled = TRUE)

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

/// Returns item interaction flags define, as a composite of [proc/check_is_valid_item], [proc/can_start] and [proc/can_complete].
/// If this returns blocking, then that means the used item was valid but the step couldn't start, meaning the user shouldn't whack the target.
/// If this returns success, then that means the construction step can start, and the user shouldn't attempt to run any other construction steps.
/datum/construction_step/proc/check_interaction(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!check_is_valid(user, used_item, target, modifiers, reqs))
		return NONE
	if (!can_start(user, used_item, target, modifiers, reqs) || !can_complete(user, used_item, target, modifiers, reqs))
		return ITEM_INTERACT_BLOCKING
	return ITEM_INTERACT_SUCCESS

/// Returns whether the used item and target are valid for this step. If this returns true, whacking the target is blocked.
/datum/construction_step/proc/check_is_valid(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	var/req_item_type = reqs[CONSTRUCTION_REQ_ITEM_TYPE]
	if (req_item_type && !istype(used_item, req_item_type))
		return FALSE

	var/req_tool_behaviour = reqs[CONSTRUCTION_REQ_TOOL_BEHAVIOUR]
	if (req_tool_behaviour && used_item.tool_behaviour != req_tool_behaviour)
		return FALSE

	return TRUE

/// Returns whether the user can start this step. By this point, the used item is known to be valid. This is for stuff that's independent of the item type.
/// You can put failure feedback in here as long as there are no other construction steps on the same target with conflicting valid items.
/// To solve such conflicts, use a [datum/construction_controller] type.
/datum/construction_step/proc/can_start(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	SHOULD_CALL_PARENT(TRUE)

	if (DOING_INTERACTION_WITH_TARGET(user, target))
		return FALSE

	var/req_item_amount = reqs[CONSTRUCTION_REQ_ITEM_AMOUNT]
	if (!used_item.tool_start_check(user, req_item_amount))
		return FALSE

	return TRUE

/// Returns whether the user can do this step. Called every tick during the step. Be careful with feedback. Base checks should always come first.
/// You can put failure feedback in here as long as there are no other construction steps on the same target with conflicting valid items.
/// To solve such conflicts, use a [datum/construction_controller] type.
/datum/construction_step/proc/can_complete(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs)
	SHOULD_CALL_PARENT(TRUE)

	return TRUE

/// Called when the step is started. Can be used for feedback.
/datum/construction_step/proc/on_started(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_CALL_PARENT(TRUE)

	if (starting_alert_text)
		target.balloon_alert(user, starting_alert_text)

	if (!(construction_flags & CONSTRUCTION_NO_FINGERPRINTS))
		used_item.add_fingerprint(user)
		target.add_fingerprint(user)

/// Returns the list of result /atom/movable instances.
/// Post processing like fingerprints should be done in [proc/on_completed].
/datum/construction_step/proc/get_results(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	var/list/results = list()

	var/list/result_types = get_result_types(user, used_item, target, modifiers)
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

/// Returns the replacement instance of the given type, if any.
/// Can be overridden for custom replacement logic.
/datum/construction_step/proc/get_replacement_of_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, replacement_type)
	if (ispath(replacement_type, /turf))
		return astype(get_turf(target), /turf)?.place_on_top(replacement_type)
	if (ispath(replacement_type, /atom/movable))
		return !target.loc ? null : new replacement_type(target.loc)

	CRASH("Construction step of type \"[type]\" failed to create replacement of type \"[replacement_type]\".")

/// Called after the step is completed. Can be used for feedback.
/// Passes in the reqs and results of the step, indices are defined in _DEFINES/complex_construction.dm
/datum/construction_step/proc/on_completed(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs, list/results)
	SHOULD_CALL_PARENT(TRUE)

	if (completion_alert_text)
		target.balloon_alert(user, completion_alert_text)

	if (!(construction_flags & CONSTRUCTION_NO_FINGERPRINTS))
		for (var/atom/movable/result as anything in results)
			result.add_fingerprint(user)

	if (construction_flags & CONSTRUCTION_APPLY_MATS)
		apply_mats_to_results(user, used_item, target, modifiers, reqs, results)

/// Applies the materials of the used item to the results. Used if CONSTRUCTION_APPLY_MATS is set.
/datum/construction_step/proc/apply_mats_to_results(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, list/reqs, list/results)
	if (!istype(used_item, /obj/item/stack/sheet))
		return
	if (!length(results))
		return

	var/total_material_users = 0
	for (var/atom/movable/result as anything in results)
		total_material_users += astype(result, /obj/item/stack)?.get_amount() || 1

	if (!total_material_users)
		return

	var/obj/item/stack/sheet/used_sheets = used_item

	var/materials = used_sheets.mats_per_unit
	var/multiplier = 1 / total_material_users * reqs[CONSTRUCTION_REQ_ITEM_AMOUNT]

	for (var/atom/movable/result as anything in results)
		result.set_custom_materials(materials, multiplier * (astype(result, /obj/item/stack)?.get_amount() || 1))

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

/// Returns the final replacement type.
/datum/construction_step/proc/get_replacement_type(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return replacement_type

/// Returns the final target handling.
/datum/construction_step/proc/get_target_handling(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers, replacement_type)
	if (!target_handling && replacement_type)
		return CONSTRUCTION_DELETE_TARGET // We're replacing it, so delete it at the very least.
	return target_handling
