/// A manager for [datum/construction_step] that lets you manually configure their execution order.
/// You can use [/datum/construction_controller/simple] if your steps are basic enough.
/datum/construction_controller
	// These vars here are used by [proc/run_step] to abstract away passing the args.
	// This results in a lot less boilerplate for controllers that have a lot of steps.
	var/mob/living/user = null
	var/obj/item/used_item = null
	var/atom/movable/target = null
	var/list/modifiers = null

/// Sets the context of the controller prior to it running, such that it knows the user, used item, target and modifiers.
/datum/construction_controller/proc/set_context(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	src.user = user
	src.used_item = used_item
	src.target = target
	src.modifiers = modifiers

/// Clears the context of the controller after it's been run.
/datum/construction_controller/proc/clear_context()
	SHOULD_NOT_OVERRIDE(TRUE)

	user = null
	used_item = null
	target = null
	modifiers = null

/// Called by the complex construction component after context has been set. The return value of this is an ITEM_INTERACT_X define.
/// The args are passed here such that you can freely make assumptions about what you're working with by overriding their type.
/// Feedback for construction steps should be handled here instead of in the steps themselves.
/datum/construction_controller/proc/run_controller(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	SHOULD_NOT_SLEEP(TRUE)

/**
 * Runs a list of construction steps, and returns ITEM_INTERACT_X flags on what happened.
 *
 * Possible return values:
 * 1. NONE/FALSE/0 - The step is invalid and has failed.
 * 2. ITEM_INTERACT_BLOCKING - The step is valid, but has failed for other reasons.
 * 3. ITEM_INTERACT_SUCCESS - The step is valid and was able to start successfully.
 */
/// Runs a list of construction steps, and returns ITEM_INTERACT_X flags on what happened.
/// A return of NONE implies the step is invalid, ITEM_INTERACT_BLOCKING implies it's valid but failed, ITEM_INTERACT_SUCCESS implies it was started successfully.
/datum/construction_controller/proc/run_steps(list/step_types)
	SHOULD_NOT_OVERRIDE(TRUE)

	for (var/step_type in step_types)
		. |= run_step(step_type)
		if (. & ITEM_INTERACT_SUCCESS)
			return // The step was able to start, so we stop here.

/**
 * Runs a construction step, and returns ITEM_INTERACT_X flags on what happened.
 *
 * Possible return values:
 * 1. NONE/FALSE/0 - The step is invalid and has failed.
 * 2. ITEM_INTERACT_BLOCKING - The step is valid, but has failed for other reasons.
 * 3. ITEM_INTERACT_SUCCESS - The step is valid and was able to start successfully.
 */
/datum/construction_controller/proc/run_step(step_type)
	SHOULD_NOT_OVERRIDE(TRUE)

	var/datum/construction_step/step = GLOB.construction_steps[step_type]

	if (!step)
		CRASH("A construction controller of type \"[type]\" attempted to run a non-existent construction step of type \"[step_type]\".")

	var/list/reqs = step.get_reqs(user, used_item, target, modifiers)

	. = step.check_interaction(user, used_item, target, modifiers, reqs)

	if (. & ITEM_INTERACT_SUCCESS)
		// The step can be started, so let's do that.
		INVOKE_ASYNC(step, TYPE_PROC_REF(/datum/construction_step, try_complete), user, used_item, target, modifiers, reqs)

/// A construction controller that takes an ordered list of steps and runs through them. It's indeed very simple.
/datum/construction_controller/simple
	var/list/step_types = list()

/datum/construction_controller/simple/New(list/step_types)
	src.step_types = step_types

/datum/construction_controller/simple/run_controller(mob/living/user, obj/item/used_item, atom/movable/target, list/modifiers)
	return run_steps(step_types)
