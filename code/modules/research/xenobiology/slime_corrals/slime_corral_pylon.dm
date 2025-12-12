/// The maximum number of pylons that a corral can have.
#define CORRAL_MAX_PYLONS 20
/// The maximum number of turfs that a pylon propagates when trying to create a corral.
/// A corral range of 4 lets you create a 5x5 corral without in-betweens.
#define CORRAL_MAX_RANGE 4

/obj/effect/overlay/slime_corral_pylon
	icon = 'icons/obj/science/slime_corral.dmi'
	icon_state = "pylon_active_overlay"
	vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_LAYER | VIS_INHERIT_PLANE | VIS_INHERIT_ID
	alpha = 0

/// Used for creating xenobiology slime corrals that can contain slimes within a perimeter.
/obj/machinery/slime_corral_pylon
	name = "slime corral pylon"
	desc = "A pylon for a slime corral. They can generate a shield wall around a perimeter, collectively known as a corral or a pen, which prevents slimes from getting in or out."

	icon = 'icons/obj/science/slime_corral.dmi'
	icon_state = "pylon"

	circuit = /obj/item/circuitboard/machine/slime_corral_pylon

	anchored = FALSE
	density = FALSE
	opacity = FALSE

	/// The power cell of this pylon, if any.
	var/obj/item/stock_parts/power_store/cell/cell = null

	/// A multiplier for the amount of corral health that this pylon contributes.
	var/corral_health_multiplier = 1
	/// The rate at which this pylon charges its internal cell in cell units per second.
	var/cell_charge_rate = 1000

	/// The direction from which this pylon accepts incoming walls.
	/// This is the direction towards which the propagation is going.
	var/in_dir = null
	/// The direction to which this pylon generates walls.
	var/out_dir = null

	/// The slime corral this pylon is a part of, if any.
	var/datum/slime_corral/corral = null

	var/obj/effect/overlay/slime_corral_pylon/active_overlay = null

	COOLDOWN_DECLARE(toggle_cooldown)

/obj/machinery/slime_corral_pylon/Initialize(mapload)
	. = ..()
	update_dir()

	active_overlay = new()
	vis_contents += active_overlay

/obj/machinery/slime_corral_pylon/Destroy(force)
	QDEL_NULL(active_overlay)
	return ..()

/obj/machinery/slime_corral_pylon/InitializedOn(atom/new_atom, mapload)
	. = ..()
	try_register_cell(new_atom)

/obj/machinery/slime_corral_pylon/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	try_register_cell(arrived)

/obj/machinery/slime_corral_pylon/Exited(atom/movable/gone, direction)
	. = ..()
	if (gone == cell)
		cell = null

/obj/machinery/slime_corral_pylon/proc/try_register_cell(atom/movable/potential_cell)
	if (potential_cell != cell && istype(potential_cell, /obj/item/stock_parts/power_store/cell))
		cell?.forceMove(drop_location())
		cell = potential_cell

/obj/machinery/slime_corral_pylon/setDir(newdir)
	. = ..()
	update_dir()

/obj/machinery/slime_corral_pylon/proc/update_dir()
	// The pylons use a clockwise propagation order.

	// [var/in_dir] should be the clockwise direction from which the pylon accepts incoming walls.
	// [var/out_dir] should be the clockwise direction towards which the pylon generates walls.

	// For straight segments [var/in_dir] and [var/out_dir] should be the same.
	// For corner segments [var/out_dir] should be a 90 degree clockwise turn from [var/in_dir].
	switch (dir)
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

/obj/machinery/slime_corral_pylon/examine(mob/user)
	. = ..()
	. += span_notice("It could be [anchored ? "unsecured" : "secured"] with a <b>wrench</b>.")
	if (panel_open)
		if (cell)
			. += span_notice("Its cell could be removed with a <b>screwdriver</b>.")
		else
			. += span_notice("It has an empty slot for a <b>power cell</b>.")
	if (!anchored)
		. += span_notice("It could be reoriented with an empty hand.")
	else
		. += span_notice("It could be [corral ? "deactivated" : "activated"] with an empty hand.")

/obj/machinery/slime_corral_pylon/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if (istype(tool, /obj/item/stock_parts/power_store/cell) && panel_open)
		if (cell)
			balloon_alert(user, "already has a cell!")
			return ITEM_INTERACT_BLOCKING
		balloon_alert(user, "cell inserted")
		tool.forceMove(src)
		return ITEM_INTERACT_SUCCESS

/obj/machinery/slime_corral_pylon/wrench_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING

	if (!tool.tool_start_check(user))
		return

	var/securing = !anchored

	user.visible_message(
		message = span_notice("\The [user] start[user.p_s()] [securing ? "securing" : "unsecuring"] \the [src]."),
		self_message = span_notice("You start [securing ? "securing" : "unsecuring"] \the [src]."),
		blind_message = span_hear("You hear wrenching."),
	)

	if (!tool.use_tool(src, user, 3 SECONDS, volume = 80))
		return
	if (securing == anchored)
		balloon_alert(user, "already [securing ? "secured" : "unsecured"]!")
		return

	user.visible_message(
		message = span_notice("\The [user] [securing ? "secure" : "unsecure"][user.p_s()] \the [src]."),
		self_message = span_notice("You [securing ? "secure" : "unsecure"] \the [src]."),
	)

	set_anchored(securing)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/slime_corral_pylon/screwdriver_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_BLOCKING

	if (!panel_open)
		balloon_alert(user, "open the panel first!")
		return
	if (!cell)
		balloon_alert(user, "no cell!")
		return
	if (!tool.use_tool(src, user, volume = 80))
		return

	user.put_in_hands(cell)
	balloon_alert(user, "cell removed")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/slime_corral_pylon/interact(mob/user)
	. = ..()
	if (. || !anchored)
		return
	. = TRUE

	if (!COOLDOWN_FINISHED(src, toggle_cooldown))
		balloon_alert(user, "on cooldown!")
		return

	if (corral)
		deactivate_corral(feedback = TRUE)
	else
		try_propagate_corral(feedback = TRUE)

	COOLDOWN_START(src, toggle_cooldown, 1 SECONDS)

/obj/machinery/slime_corral_pylon/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if (. || anchored)
		return
	. = TRUE

	var/picked_dir_string = show_radial_menu(user, src, GLOB.all_radial_directions, require_near = TRUE)

	if (!isnull(picked_dir_string))
		setDir(text2dir(picked_dir_string))

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

#define CORRAL_ERROR(message) if (feedback) { say("ERROR: [message]"); playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', vol = 50, vary = TRUE); }; return FALSE;

/obj/machinery/slime_corral_pylon/proc/try_propagate_corral(feedback = FALSE)
	// List of all pylons that make up the corral.
	var/list/pylons = list()

	// Associative list of all wall turfs to their wall object directions. Format is "wall_turfs[turf] = dir"
	var/list/wall_turfs = list()

	var/obj/machinery/slime_corral_pylon/current_pylon = src
	var/turf/current_turf = get_turf(current_pylon)

	for (var/pylon_index in 1 to CORRAL_MAX_PYLONS)
		if (current_pylon.corral)
			CORRAL_ERROR("The perimeter intersects with an active corral.")
		if (!current_pylon.anchored)
			CORRAL_ERROR("All pylons must be secured.")
		if (!isfloorturf(current_turf))
			CORRAL_ERROR("All pylons require a floor.")
		if (current_pylon in pylons)
			if (current_pylon == src)
				return try_create_corral(pylons, wall_turfs, feedback)
			else
				CORRAL_ERROR("The perimeter closes at a different pylon.")

		pylons += current_pylon

		var/obj/machinery/slime_corral_pylon/next_pylon = null

		for (var/turf_index in 1 to CORRAL_MAX_RANGE)
			current_turf = get_step(current_turf, current_pylon.out_dir)
			if (!isopenturf(current_turf))
				CORRAL_ERROR("The perimeter is blocked.")
			if (locate(/obj/structure/slime_corral_wall) in current_turf)
				CORRAL_ERROR("The perimeter intersects with an active corral.")
			for (var/obj/machinery/slime_corral_pylon/candidate_pylon in current_turf)
				if (candidate_pylon.in_dir == current_pylon.out_dir)
					next_pylon = candidate_pylon
					break
			if (next_pylon)
				break

			// The direction of the wall object is 90 degrees counter-clockwise from the direction of the propagation.
			wall_turfs[current_turf] = turn(current_pylon.out_dir, 90)

		if (!next_pylon)
			CORRAL_ERROR("The perimeter is not contiguous.")

		current_pylon = next_pylon

	CORRAL_ERROR("The perimeter may only consist of up to [CORRAL_MAX_PYLONS] pylons.")

/obj/machinery/slime_corral_pylon/proc/try_create_corral(list/pylons, list/wall_turfs, feedback)
	var/total_charge = 0
	for (var/obj/machinery/slime_corral_pylon/pylon as anything in pylons)
		total_charge += pylon.cell?.charge

	if (total_charge < length(pylons) * SLIME_CORRAL_POWER_PER_PYLON)
		CORRAL_ERROR("Not enough power.")

	if (feedback)
		say("Generating perimeter shield wall...")
		// add playsound here later

	var/list/walls = list()
	for (var/turf/wall_turf as anything in wall_turfs)
		var/obj/structure/slime_corral_wall/wall = new(wall_turf)
		wall.setDir(wall_turfs[wall_turf])
		walls += wall

	return new /datum/slime_corral(pylons, walls)

#undef CORRAL_ERROR

/obj/machinery/slime_corral_pylon/proc/deactivate_corral(feedback = FALSE)
	if (!corral)
		return

	if (feedback)
		say("Deactivating perimeter shield wall...")
	corral.deactivate()

/// A subtype of the slime corral pylon that spawns anchored and loaded with a power cell for mapping and admin purposes.
/obj/machinery/slime_corral_pylon/loaded
	anchored = TRUE

/obj/machinery/slime_corral_pylon/loaded/Initialize(mapload)
	. = ..()
	new /obj/item/stock_parts/power_store/cell/high(src)

/// A subtype of the slime corral pylon that tries to create a corral upon spawning for mapping and admin purposes.
/obj/machinery/slime_corral_pylon/loaded/propagator

/obj/machinery/slime_corral_pylon/loaded/propagator/post_machine_initialize()
	. = ..()
	try_propagate_corral()

#undef CORRAL_MAX_PYLONS
#undef CORRAL_MAX_RANGE

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/slime_corral_pylon, 0)
MAPPING_DIAGONAL_HELPERS(/obj/machinery/slime_corral_pylon, 0)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/slime_corral_pylon/loaded, 0)
MAPPING_DIAGONAL_HELPERS(/obj/machinery/slime_corral_pylon/loaded, 0)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/slime_corral_pylon/loaded/propagator, 0)
MAPPING_DIAGONAL_HELPERS(/obj/machinery/slime_corral_pylon/loaded/propagator, 0)
