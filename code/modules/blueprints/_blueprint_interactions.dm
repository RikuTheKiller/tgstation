/obj/structure/blueprint/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	return interact_with(user, tool, modifiers)

/obj/structure/blueprint/item_interaction_secondary(mob/living/user, obj/item/tool, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	return interact_with(user, tool, modifiers)

/obj/structure/blueprint/proc/interact_with(mob/living/user, obj/item/tool, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (user.combat_mode)
		return NONE

	if (current_object)
		interact_with_current_object(user, tool, modifiers)
	else
		try_build_on(user, tool, modifiers)

	return ITEM_INTERACT_BLOCKING

/// Called when an user interacts with the blueprint while the blueprint is working on an existing object.
/// Intended for things like plating a girder with metal for a wall blueprint.
/obj/structure/blueprint/proc/interact_with_current_object(mob/living/user, obj/item/tool, list/modifiers)
	tool.melee_attack_chain(user, current_object, modifiers)

/// Called when an user interacts with the blueprint while the blueprint isn't working on any existing objects.
/// Intended for things like creating a girder from metal for a wall blueprint. Do not override.
/obj/structure/blueprint/proc/try_build_on(mob/living/user, obj/item/tool, list/modifiers)
	// If you need to add more checks here, then implement a proper [proc/can_build_on] chain or similar.
	// If you instead have a really good reason to override this directly, then remove this.
	SHOULD_NOT_OVERRIDE(TRUE)

	if (!sheet_stack_build_path)
		return
	if (!ispath(sheet_stack_build_path, /obj))
		CRASH("Attempted to build a non-object sheet stack recipe ([sheet_stack_build_path]) on a blueprint.")
	if (ispath(sheet_stack_build_path, /obj/item))
		CRASH("Attempted to build an item sheet stack recipe ([sheet_stack_build_path]) on a blueprint.")
	if (!istype(tool, /obj/item/stack/sheet))
		balloon_alert(user, "needs material sheets!")
		return

	var/obj/item/stack/sheet/sheet_stack = tool
	var/datum/stack_recipe/recipe = null

	for (var/datum/stack_recipe/candidate_recipe in sheet_stack.recipes)
		if (ispath(candidate_recipe.result_type, sheet_stack_build_path))
			recipe = candidate_recipe
			break

	if (!recipe)
		balloon_alert(user, "can't use this material!")
		return
	if (!can_build_recipe_on(user, sheet_stack, recipe))
		return

	if (recipe.time > 0)
		user.visible_message(
			message = span_notice("\The [user] start[user.p_s()] building \a [recipe.title] on \the [src]..."),
			self_message = span_notice("You start building \a [recipe.title] on \the [src]..."),
		)

		if (!do_after(user, recipe.time / build_speed_multiplier, src, extra_checks = CALLBACK(src, PROC_REF(can_build_recipe_on), user, sheet_stack, recipe)))
			return

	user.visible_message(
		message = span_notice("\The [user] build[user.p_s()] \a [recipe.title] on \the [src]."),
		self_message = span_notice("You build \a [recipe.title] on \the [src]."),
		blind_message = span_hear("You hear construction."),
	)

	var/obj/built_object = new sheet_stack_build_path(current_turf)

	var/obj/item/stack/sheet/used_stack = sheet_stack.split_stack(recipe.req_amount)

	built_object.setDir(user.dir)
	built_object.on_craft_completion(list(used_stack), null, user)
	built_object.add_fingerprint(user)

	if((recipe.crafting_flags & CRAFT_APPLIES_MATS) && LAZYLEN(sheet_stack.mats_per_unit))
		built_object.set_custom_materials(sheet_stack.mats_per_unit, recipe.req_amount)

	qdel(used_stack)

	user.investigate_log("crafted [recipe.title]", INVESTIGATE_CRAFTING)

/// Returns whether the given user can build the given recipe on the blueprint. This has feedback.
/obj/structure/blueprint/proc/can_build_recipe_on(mob/living/user, obj/item/stack/sheet/sheet_stack, datum/stack_recipe/recipe)
	if (current_object)
		balloon_alert(user, "already has an object!")
		return FALSE
	if (!sheet_stack.building_checks(user, recipe, multiplier = 1, turf_override = current_turf))
		return FALSE
	return TRUE
