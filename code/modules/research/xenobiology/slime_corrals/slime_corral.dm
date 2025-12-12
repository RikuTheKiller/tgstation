#define FADE_DURATION 1 SECONDS

/datum/slime_corral
	var/list/pylons = null
	var/list/walls = null

	var/deactivating = FALSE

/datum/slime_corral/New(list/pylons, list/walls)
	src.pylons = pylons
	src.walls = walls

	for (var/obj/machinery/slime_corral_pylon/pylon as anything in pylons)
		pylon.corral = src

	for (var/obj/structure/slime_corral_wall/wall as anything in walls)
		wall.corral = src

	for (var/obj/part as anything in pylons + walls)
		RegisterSignal(part, COMSIG_QDELETING, PROC_REF(delete))
		RegisterSignal(part, COMSIG_MOVABLE_SET_ANCHORED, PROC_REF(on_part_set_anchored))
		RegisterSignal(part, COMSIG_MOVABLE_MOVED, PROC_REF(on_part_moved))

	START_PROCESSING(SSmachines, src)

	fade(alpha = 255)

/datum/slime_corral/Destroy(force)
	for (var/obj/machinery/slime_corral_pylon/pylon as anything in pylons)
		pylon.corral = null
		pylon.active_overlay.alpha = 0

	for (var/obj/structure/slime_corral_wall/wall as anything in walls)
		wall.corral = null
		qdel(wall)

	for (var/obj/part as anything in pylons + walls)
		UnregisterSignal(part, list(COMSIG_QDELETING, COMSIG_MOVABLE_SET_ANCHORED, COMSIG_MOVABLE_MOVED, COMSIG_ATOM_POST_DIR_CHANGE))

	pylons = null
	walls = null

	STOP_PROCESSING(SSmachines, src)

	return ..()

/datum/slime_corral/process(seconds_per_tick)
	var/total_charge = 0
	for (var/obj/machinery/slime_corral_pylon/pylon as anything in pylons)
		total_charge += pylon.cell?.charge

	var/power_usage = length(pylons) * SLIME_CORRAL_POWER_PER_PYLON

	if (total_charge < power_usage)
		delete()
		return

/datum/slime_corral/proc/fade(alpha)
	for (var/obj/machinery/slime_corral_pylon/pylon as anything in pylons)
		animate(pylon.active_overlay, FADE_DURATION, alpha = alpha)

	for (var/obj/structure/slime_corral_wall/wall as anything in walls)
		animate(wall, FADE_DURATION, alpha = alpha)

/datum/slime_corral/proc/deactivate()
	if (deactivating)
		return
	deactivating = TRUE

	fade(alpha = 0)

	QDEL_IN_CLIENT_TIME(src, FADE_DURATION)

/datum/slime_corral/proc/delete()
	SIGNAL_HANDLER
	if (!QDELETED(src))
		qdel(src)

/datum/slime_corral/proc/on_part_set_anchored(obj/part, new_anchored)
	SIGNAL_HANDLER
	if (!new_anchored)
		delete()

/datum/slime_corral/proc/on_part_moved(obj/part, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	if (part.loc != old_loc)
		delete()

#undef FADE_DURATION
