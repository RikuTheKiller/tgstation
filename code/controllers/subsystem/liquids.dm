#define UPDATE_MAX_VOLUME(group) \
	group.reagents.maximum_volume = length(group.turfs) * LIQUID_HEIGHT_FULL; \
	group.needs_reagent_update = TRUE; \

#define ADD_TURFS_TO_GROUP(group, to_add_list) \
	for (var/turf/open/to_add as anything in to_add_list) { \
		group.turfs[to_add] = TRUE; \
		group.to_smooth[to_add] = TRUE; \
		to_add.liquid_group = group; \
		to_add.liquid_effect = new(to_add); \
		to_add.liquid_effect.color = group.color; \
		to_add.liquid_effect.alpha = group.alpha; \
		var/edge_dirs = NONE; \
		for (var/i in 1 to 8) { \
			var/turf/adjacent = get_step(to_add, GLOB.alldirs[i]); \
			if (group.turfs[adjacent]) { \
				group.to_smooth[adjacent] = TRUE; \
				group.edges[adjacent] &= ~GLOB.reversed_junctions[i]; \
				if (!group.edges[adjacent]) { \
					group.edges -= adjacent; \
				} \
			} else { \
				edge_dirs |= GLOB.all_junctions[i]; \
			} \
		} \
		if (edge_dirs) { \
			group.edges[to_add] = edge_dirs; \
		} \
	}; \
	UPDATE_MAX_VOLUME(group);

#define REMOVE_TURFS_FROM_GROUP(group, to_remove_list) \
	for (var/turf/open/to_remove as anything in to_remove_list) { \
		group.turfs -= to_remove; \
		group.edges -= to_remove; \
		group.to_smooth -= to_remove; \
		to_remove.liquid_group = null; \
		QDEL_NULL(to_remove.liquid_effect); \
		for (var/i in 1 to 8) { \
			var/turf/adjacent = get_step(to_remove, GLOB.alldirs[i]); \
			if (group.turfs[adjacent]) { \
				group.to_smooth[adjacent] = TRUE; \
				group.edges[adjacent] |= GLOB.reversed_junctions[i]; \
			} \
		} \
	}; \
	UPDATE_MAX_VOLUME(group); \
	if (!length(group.turfs)) { \
		qdel(group); \
	};

SUBSYSTEM_DEF(liquids)
	name = "Liquids"
	wait = 0.2 SECONDS
	priority = FIRE_PRIORITY_LIQUIDS
	flags = SS_NO_INIT

	/// The index of the current liquid subsystem stage.
	var/stage = 0

	/// List of all liquid groups.
	var/list/groups = list()

	/// List of all liquid groups in queue for the current stage.
	var/list/queue = list()

#define RUN_STAGE(index, name) \
	if (stage == index - 1) { \
		stage = index; \
		queue.Cut(); \
		queue_##name(); \
	}; \
	if (stage == index) { \
		if (MC_TICK_CHECK) { \
			return; \
		}; \
		run_##name(); \
		if (state != SS_RUNNING) { \
			return; \
		}; \
	};

/datum/controller/subsystem/liquids/fire(resumed)
	if (!resumed)
		stage = 0

	RUN_STAGE(1, spread) // Spreading and receding
	RUN_STAGE(2, remove) // Removing turfs
	RUN_STAGE(3, add) // Adding turfs and merging groups
	RUN_STAGE(4, reagents) // Reagent visuals, reactions and exposures
	RUN_STAGE(5, smoothing) // Icon smoothing

#undef RUN_STAGE

/datum/controller/subsystem/liquids/proc/queue_spread()
	queue += groups

/datum/controller/subsystem/liquids/proc/run_spread()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		// Spreading Start
		if (group.reagents.total_volume / (length(group.turfs) + length(group.edges) * 4) >= LIQUID_HEIGHT_SPREAD)
			var/list/candidates = list()

			for (var/turf/open/edge as anything in group.edges)
				for (var/spread_dir in GLOB.cardinals)
					if (!(group.edges[edge] & spread_dir))
						continue

					var/turf/open/spreading_to = get_step(edge, spread_dir)

					if (!isopenturf(spreading_to))
						continue
					if (spreading_to.liquid_group == group)
						continue
					if (!edge.atmos_adjacent_turfs?[spreading_to])
						continue

					candidates[spreading_to] = TRUE

			if (group.reagents.total_volume / (length(group.turfs) + length(candidates)) >= LIQUID_HEIGHT_SPREAD)
				for (var/turf/open/spreading_to as anything in candidates)
					group.to_add[spreading_to] = TRUE
		// Spreading End

		// Receding Start
		if (GET_GROUP_LIQUID_HEIGHT(group) < LIQUID_HEIGHT_SPREAD)
			for (var/turf/open/edge as anything in group.edges)
				if (group.edges[edge] & ALL_CARDINALS)
					group.to_remove[edge] = TRUE
		// Receding End

/datum/controller/subsystem/liquids/proc/queue_remove()
	for (var/datum/liquid_group/group as anything in groups)
		if (length(group.to_remove))
			queue += group

/datum/controller/subsystem/liquids/proc/run_remove()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		REMOVE_TURFS_FROM_GROUP(group, group.to_remove)

		group.to_remove.Cut()

/datum/controller/subsystem/liquids/proc/queue_add()
	for (var/datum/liquid_group/group as anything in groups)
		if (length(group.to_add))
			queue += group

/datum/controller/subsystem/liquids/proc/run_add()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		var/list/merge_queue = list()
		var/list/add_queue = list()

		// Queuing Start
		while (length(group.to_add))
			var/turf/open/to_add = group.to_add[length(group.to_add)]
			group.to_add.Cut(length(group.to_add))

			if (QDELETED(to_add))
				continue
			if (to_add.liquid_group == group)
				continue

			if (!to_add.liquid_group)
				add_queue[to_add] = TRUE
			else if (!merge_queue[to_add.liquid_group])
				for (var/turf/open/turf as anything in to_add.liquid_group.to_add)
					group.to_add[turf] = TRUE

				merge_queue[to_add.liquid_group] = TRUE
		// Queuing End

		// Merging Start
		for (var/datum/liquid_group/other as anything in merge_queue)
			for (var/turf/open/turf as anything in other.turfs)
				group.turfs[turf] = TRUE
				group.to_smooth[turf] = TRUE
				turf.liquid_group = group

			for (var/turf/open/turf as anything in other.edges)
				for (var/i in 1 to 8)
					if (!(other.edges[turf] & GLOB.all_junctions[i]))
						continue
					var/turf/adjacent = get_step(turf, GLOB.alldirs[i])
					if (!group.edges[adjacent])
						continue
					group.to_smooth[adjacent] = TRUE
					group.edges[adjacent] &= ~GLOB.reversed_junctions[i]
					other.edges[turf] &= ~GLOB.all_junctions[i]
					if (!group.edges[adjacent])
						group.edges -= adjacent
					if (!other.edges[turf])
						other.edges -= turf

			for (var/turf/open/turf as anything in other.edges)
				group.edges[turf] = other.edges[turf]

			for (var/turf/open/turf as anything in other.to_remove)
				group.to_remove[turf] = TRUE

			if (group.color != other.color)
				for (var/turf/open/turf as anything in other.turfs)
					turf.liquid_effect.color = group.color

			if (group.alpha != other.alpha)
				for (var/turf/open/turf as anything in other.turfs)
					turf.liquid_effect.alpha = group.alpha

			UPDATE_MAX_VOLUME(group) // Do this prior to transfer so that the group has enough space.
			other.reagents.trans_to(group.reagents, other.reagents.total_volume, no_react = TRUE)
			qdel(other)
		// Merging End

		ADD_TURFS_TO_GROUP(group, add_queue)

/datum/controller/subsystem/liquids/proc/queue_reagents()
	for (var/datum/liquid_group/group as anything in groups)
		if (group.needs_reagent_update)
			queue += group

/datum/controller/subsystem/liquids/proc/run_reagents()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		group.needs_reagent_update = FALSE

		var/color = mix_color_from_reagents(group.reagents.reagent_list)
		if (group.color != color)
			for (var/turf/open/turf as anything in group.turfs)
				turf.liquid_effect.color = color

		// alpha 102-230 from height 0-900
		var/alpha = min(round((255 * 0.4) + GET_GROUP_LIQUID_HEIGHT(group) / LIQUID_HEIGHT_HIGH * (255 * 0.5), 1), 230)
		if (group.alpha != alpha)
			group.alpha = alpha
			for (var/turf/open/turf as anything in group.turfs)
				turf.liquid_effect.alpha = alpha

		var/smooth = GET_GROUP_LIQUID_HEIGHT(group) < LIQUID_HEIGHT_LOW
		if (group.smooth != smooth)
			group.smooth = smooth
			for (var/turf/open/turf as anything in group.turfs)
				group.to_smooth[turf] = TRUE

/datum/controller/subsystem/liquids/proc/queue_smoothing()
	for (var/datum/liquid_group/group as anything in groups)
		if (length(group.to_smooth))
			queue += group

/datum/controller/subsystem/liquids/proc/run_smoothing()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		if (group.smooth)
			// Regular smoothing
			for (var/turf/open/to_smooth as anything in group.to_smooth)
				var/icon_index = group.edges[to_smooth] ^ ALL_SMOOTHING_JUNCTIONS // 255 possible states

				for (var/i in 1 to length(GLOB.diagonals))
					if ((icon_index & GLOB.diagonals[i]) != GLOB.diagonals[i]) // 255 -> 47 possible states, as we only accept diagonal junctions for smoothing if they're adjacent to 2 cardinal junctions
						icon_index &= ~GLOB.diagonal_junctions[i]

				to_smooth.liquid_effect.icon_state = "[to_smooth.liquid_effect.base_icon_state]-[icon_index]"
		else
			// Fulltile smoothing
			for (var/turf/open/to_smooth as anything in group.to_smooth)
				to_smooth.liquid_effect.icon_state = "[to_smooth.liquid_effect.base_icon_state]-255"

		group.to_smooth.Cut()

/datum/controller/subsystem/liquids/proc/ensure_has_group(turf/open/target)
	PRIVATE_PROC(TRUE)
	if (target.liquid_group)
		return TRUE

	var/datum/liquid_group/group = new()
	ADD_TURFS_TO_GROUP(group, list(target))
	return TRUE

/datum/controller/subsystem/liquids/proc/add_reagent_to_turf(turf/open/target, reagent_type, volume)
	return ensure_has_group(target) ? add_reagent_to_group(target.liquid_group, reagent_type, volume) : 0

/datum/controller/subsystem/liquids/proc/add_reagent_to_group(datum/liquid_group/group, reagent_type, volume)
	group.needs_reagent_update = TRUE
	return group.reagents.add_reagent(reagent_type, volume, no_react = TRUE)

#undef UPDATE_MAX_VOLUME
#undef ADD_TURFS_TO_GROUP
#undef REMOVE_TURFS_FROM_GROUP
