/// Component for organs that cover other organs. For when you want to "override" organ function temporarily.
/datum/component/cover_organ
	/// The organ being covered, if any.
	var/obj/item/organ/covered
	/// Whether the covered organ can be extracted using a sharp object.
	var/can_be_extracted
	/// Whether this should add an examine message to the cover organ about the covered one, if present.
	var/show_on_examine

/datum/component/cover_organ/Initialize(can_be_extracted, show_on_examine)
	. = ..()

	if (!istype(parent, /obj/item/organ))
		return COMPONENT_INCOMPATIBLE

/datum/component/cover_organ/Destroy(force)
	. = ..()

	QDEL_NULL(covered)

/datum/component/cover_organ/proc/clear_covered()
	SIGNAL_HANDLER

	covered = null

/datum/component/cover_organ/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ORGAN_INSERT, PROC_REF(on_insert))
	RegisterSignal(parent, COMSIG_ORGAN_REMOVE, PROC_REF(on_remove))
	RegisterSignal(parent, COMSIG_ATOM_ATTACKBY, PROC_REF(on_attackby))
	if (show_on_examine)
		RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/cover_organ/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(
		COMSIG_ORGAN_INSERT,
		COMSIG_ORGAN_REMOVE,
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_EXAMINE,
	))

/datum/component/cover_organ/proc/on_insert(datum/source, mob/living/carbon/receiver, special, movement_flags)
	SIGNAL_HANDLER

	var/obj/item/organ/cover = parent

	covered = receiver.get_organ_slot(cover.slot)

	if (!covered)
		return

	covered.Remove(receiver, special = TRUE)
	covered.forceMove(cover)
	RegisterSignal(covered, COMSIG_QDELETING, PROC_REF(clear_covered))

/datum/component/cover_organ/proc/on_remove(datum/source, mob/living/carbon/organ_owner, special, movement_flags)
	SIGNAL_HANDLER

	if ((movement_flags & DELETE_IF_REPLACED) || !(movement_flags & UNCOVER_ORGAN))
		return

	covered.Insert(organ_owner, special = TRUE)
	covered.organ_flags |= ORGAN_FROZEN

	return COMPONENT_ORGAN_CANCEL_REMOVE // inserting the covered organ removes us, so this would be removing something that isn't even inside the mob anymore

/datum/component/cover_organ/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER

	if (!(item.sharpness & SHARP_EDGED) && item.tool_behaviour != TOOL_WIRECUTTER)
		return
	if (!covered)
		return

	INVOKE_ASYNC(src, PROC_REF(cut_open), item, user, params)
	return COMPONENT_NO_AFTERATTACK

/datum/component/cover_organ/proc/cut_open(datum/source, obj/item/item, mob/living/user, params)
	user.visible_message(
		message = span_notice("[user] begins cutting \the [src] apart."),
		self_message = span_notice("You begin cutting \the [src] apart with \the [item]."),
		blind_message = span_hear("You hear cutting.")
	)

	if (!do_after(user, 2 SECONDS, src))
		user.balloon_alert(user, "canceled!")
		return

	user.visible_message(
		message = span_notice("[user] finishes cutting \the [src] apart."),
		self_message = span_notice("You finish cutting \the [src] apart and \a [covered] fall[covered.p_s()] out."),
		blind_message = span_hear("You hear a splat.")
	)

	user.put_in_hands(covered)
	covered.organ_flags &= ~ORGAN_FROZEN
	UnregisterSignal(covered, COMSIG_QDELETING)

/datum/component/cover_organ/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("You can see \a [covered] buried deep within.[can_be_extracted ? " Maybe you could extract [covered.p_them()] with something sharp?" : ""]")
