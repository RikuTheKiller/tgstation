/// The maximum number of pylons that a corral can have.
#define CORRAL_MAX_PYLONS 20
/// The maximum number of turfs that a pylon propagates when trying to create a corral.
/// A corral range of 4 lets you create a 5x5 corral without in-betweens.
#define CORRAL_MAX_RANGE 4

/// Used for creating xenobiology slime corrals that can contain slimes within a perimeter.
/obj/machinery/slime_corral_pylon
	name = "slime corral pylon"
	desc = "A pylon for a slime corral. They can generate a shield wall around a perimeter, collectively known as a corral or a pen, which prevents slimes from getting in or out."

	icon = 'icons/obj/science/slime_corral.dmi'
	icon_state = "pylon"

	circuit = /obj/item/circuitboard/machine/slime_corral_pylon

	/// The power cell of this pylon, if any.
	var/obj/item/stock_parts/power_store/cell/cell = null

	/// A multiplier for the amount of corral health that this pylon contributes.
	var/corral_health_multiplier = 1
	/// The rate at which this pylon charges its internal cell in cell units per second.
	var/cell_charge_rate = 1000

	/// The direction from which this pylon accepts incoming walls.
	/// This is the direction towards which the propagation is going.
	var/in_dir = WEST
	/// The direction to which this pylon generates walls.
	var/out_dir = WEST

/obj/machinery/slime_corral_pylon/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if (istype(arrived, /obj/item/stock_parts/power_store/cell))
		cell?.forceMove(drop_location())
		cell = arrived

/obj/machinery/slime_corral_pylon/Exited(atom/movable/gone, direction)
	. = ..()
	if (gone == cell)
		cell = null

/obj/machinery/slime_corral_pylon/setDir(newdir)
	. = ..()
	// The pylons use a clockwise propagation order.

	// [var/in_dir] should be the clockwise direction from which the pylon accepts incoming walls.
	// [var/out_dir] should be the clockwise direction towards which the pylon generates walls.

	// For straight segments [var/in_dir] and [var/out_dir] should be the same.
	// For corner segments [var/out_dir] should be a 90 degree clockwise turn from [var/in_dir].
	switch (newdir)
		if (SOUTH)
			in_dir = WEST
			out_dir = WEST
		if (NORTH)
			in_dir = EAST
			out_dir = EAST
		if (EAST)
			in_dir = SOUTH
			out_dir = SOUTH
		if (WEST)
			in_dir = NORTH
			out_dir = NORTH
		if (SOUTHEAST)
			in_dir = SOUTH
			out_dir = WEST
		if (SOUTHWEST)
			in_dir = WEST
			out_dir = NORTH
		if (NORTHEAST)
			in_dir = EAST
			out_dir = SOUTH
		if (NORTHWEST)
			in_dir = NORTH
			out_dir = EAST

/obj/machinery/slime_corral_pylon/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (istype(tool, /obj/item/stock_parts/power_store/cell) && panel_open)
		if (cell)
			balloon_alert(user, "already has a cell!")
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "cell inserted")
		tool.forceMove(src)
		return ITEM_INTERACT_SUCCESS

/obj/machinery/slime_corral_pylon/interact(mob/user)
	. = ..()
	if (. || panel_open)
		return
	. = TRUE
	try_create_corral(user)

/obj/machinery/slime_corral_pylon/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if (. || !panel_open)
		return
	. = TRUE
	if (!cell)
		balloon_alert(user, "no cell!")
		return
	user.put_in_hands(cell)
	balloon_alert(user, "cell removed")

/obj/machinery/slime_corral_pylon/RefreshParts()
	. = ..()

	cell_charge_rate = 0
	for (var/obj/item/stock_parts/capacitor/capacitor in component_parts)
		cell_charge_rate += initial(cell_charge_rate) * (1 + (capacitor.rating - 1) / 3)

	corral_health_multiplier = 0
	for (var/obj/item/stock_parts/micro_laser/micro_laser in component_parts)
		corral_health_multiplier += 1 + (micro_laser.rating - 1) / 3

/obj/machinery/slime_corral_pylon/process()
	if (cell)
		charge_cell(cell_charge_rate, cell)

/obj/machinery/slime_corral_pylon/proc/try_create_corral(silent = FALSE)
	var/list/pylons = list()
	var/list/wall_turfs = list()

	var/obj/machinery/slime_corral_pylon/current_pylon = src
	var/turf/current_turf = get_turf(current_pylon)

	for (var/i in 1 to CORRAL_MAX_PYLONS)
		if (!current_pylon.anchored)
			if (!silent)
				say("ERROR: All pylons must be secured.")
			return FALSE
		if (!isfloorturf(current_turf))
			if (!silent)
				say("ERROR: All pylons require a floor.")
			return FALSE
		if (current_pylon in pylons)
			if (current_pylon == src)
				if (!silent)
					say("Generating perimeter shield...")
				return TRUE
			else
				if (!silent)
					say("ERROR: The perimeter closes at a different pylon.")
				return FALSE

		pylons += current_pylon

		var/obj/machinery/slime_corral_pylon/next_pylon = null

		for (var/i in 1 to CORRAL_MAX_RANGE)
			current_turf = get_step(current_turf, current_pylon.out_dir)
			if (!isopenturf(current_turf))
				if (!silent)
					say("ERROR: The perimeter is blocked.")
				return FALSE
			for (var/obj/machinery/slime_corral_pylon/candidate_pylon in current_turf)
				if (candidate_pylon.in_dir == current_pylon.out_dir)
					next_pylon = candidate_pylon
					break
			if (next_pylon)
				break

			wall_turfs += current_turf

		if (!next_pylon)
			if (!silent)
				say("ERROR: The perimeter is not contiguous.")
			return FALSE

		current_pylon = next_pylon

/// A subtype of the slime corral pylon that spawns loaded with a power cell for mapping and admin purposes.
/obj/machinery/slime_corral_pylon/loaded

/obj/machinery/slime_corral_pylon/loaded/Initialize(mapload)
	. = ..()
	new /obj/item/stock_parts/power_store/cell/high(src)

/// A subtype of the slime corral pylon that tries to create a corral upon spawning for mapping and admin purposes.
/obj/machinery/slime_corral_pylon/loaded/propagator

/obj/machinery/slime_corral_pylon/loaded/propagator/post_machine_initialize()
	. = ..()
	try_create_corral(silent = TRUE)

#undef CORRAL_MAX_PYLONS
#undef CORRAL_MAX_RANGE
