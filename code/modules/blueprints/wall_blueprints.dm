/obj/structure/blueprint/wall
	name = "wall blueprint"
	type_name_plural = "walls"

/obj/structure/blueprint/wall/can_work_on(obj/object)
	return istype(object, /obj/structure/girder)

/obj/structure/blueprint/wall/interact_with_blueprint(mob/living/user, obj/item/stack/sheet/iron/iron_stack, list/modifiers)
	if (!istype(iron_stack))
		balloon_alert(user, "needs iron!")
		return ITEM_INTERACT_BLOCKING
	if (!iron_stack.tool_use_check(user, 2))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(
		message = span_notice("\The [user] start[user.p_s()] building a girder on \the [src]."),
		self_message = span_notice("You start building a girder on \the [src]."),
		blind_message = span_hear("You hear metalworking."),
	)

	if (!do_after(user, 2 SECONDS, src, extra_checks = CALLBACK(src, PROC_REF(can_keep_building))))
		return ITEM_INTERACT_BLOCKING

	new /obj/structure/girder(current_turf)
	return ITEM_INTERACT_SUCCESS

/obj/structure/blueprint/wall/proc/can_keep_building()
	return !current_object
