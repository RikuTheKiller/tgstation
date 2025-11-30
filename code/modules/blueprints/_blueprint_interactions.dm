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

	return current_object \
		? interact_with_current_object(user, tool, modifiers) \
		: interact_with_blueprint(user, tool, modifiers)

/// Called when an user interacts with the blueprint while the blueprint is working on an existing object.
/// Intended for things like plating a girder with metal for a wall blueprint.
/obj/structure/blueprint/proc/interact_with_current_object(mob/living/user, obj/item/tool, list/modifiers)
	return tool.melee_attack_chain(user, current_object, modifiers)

/// Called when an user interacts with the blueprint while the blueprint isn't working on any existing objects.
/// Intended for things like creating a girder from metal for a wall blueprint.
/obj/structure/blueprint/proc/interact_with_blueprint(mob/living/user, obj/item/tool, list/modifiers)
	return ITEM_INTERACT_BLOCKING

/// Entry point into the blueprint interaction check chain. Do not override.
/obj/structure/blueprint/proc/base_can_interact_with_blueprint(mob/living/user, obj/item/tool, list/modifiers)
	SHOULD_NOT_OVERRIDE(TRUE)

	if (current_object)
		return FALSE

	return can_interact_with_blueprint(user, tool, modifiers)

/// Checks whether the user can build on this blueprint with the given tool.
/// Has a bunch of base checks that you can configure with [var/build_flags].
/// For checks, call [proc/base_can_interact_with_blueprint] instead.
/obj/structure/blueprint/proc/can_interact_with_blueprint(mob/living/user, obj/item/tool, list/modifiers)
	return TRUE
