SUBSYSTEM_DEF(liquids)
	name = "Liquids"
	wait = 0.2 SECONDS
	priority = FIRE_PRIORITY_LIQUIDS
	flags = SS_NO_INIT

	/// The index of the current liquid subsystem stage.
	var/stage = NONE

	/// List of all liquid groups.
	var/list/groups = list()

	/// List of all liquid groups in queue for the current stage.
	var/list/queue = list()

#define STAGE_SPREAD 1 // Spreading and receding
#define STAGE_REMOVE 2 // Removing turfs
#define STAGE_ADD 3 // Adding turfs and merging groups
#define STAGE_REAGENTS 4 // Reagent visuals
#define STAGE_SMOOTHING 5 // Icon smoothing

/datum/controller/subsystem/liquids/fire(resumed)
	if (stage == NONE)
		stage = STAGE_SPREAD
		queue.Cut()
		queue_spread()

	if (stage == STAGE_SPREAD)
		run_spread()
		if (state != SS_RUNNING)
			return
		stage = STAGE_REMOVE
		queue.Cut()
		queue_remove()

	if (stage == STAGE_REMOVE)
		run_remove()
		if (state != SS_RUNNING)
			return
		stage = STAGE_ADD
		queue.Cut()
		queue_add()

	if (stage == STAGE_ADD)
		run_add()
		if (state != SS_RUNNING)
			return
		stage = STAGE_REAGENTS
		queue.Cut()
		queue_reagents()

	if (stage == STAGE_REAGENTS)
		run_reagents()
		if (state != SS_RUNNING)
			return
		stage = STAGE_SMOOTHING
		queue.Cut()
		queue_smoothing()

	if (stage == STAGE_SMOOTHING)
		run_smoothing()
		stage = NONE
		queue.Cut()

#undef STAGE_SPREAD
#undef STAGE_REMOVE
#undef STAGE_ADD
#undef STAGE_REAGENTS
#undef STAGE_SMOOTHING

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
		if (GET_LIQUID_GROUP_HEIGHT(group) < LIQUID_HEIGHT_SPREAD)
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

		remove_turfs_from_group(group, group.to_remove)

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

			group.reagents.maximum_volume = length(group.turfs) * LIQUID_HEIGHT_FULL
			other.reagents.trans_to(group.reagents, other.reagents.total_volume, no_react = TRUE)
			group.needs_reagent_update = TRUE

			qdel(other)
		// Merging End

		if (length(add_queue))
			add_turfs_to_group(group, add_queue)

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

		var/color = GET_LIQUID_GROUP_COLOR(group)
		if (group.color != color)
			for (var/turf/open/turf as anything in group.turfs)
				turf.liquid_effect.color = color

		var/alpha = GET_LIQUID_GROUP_ALPHA(group)
		if (group.alpha != alpha)
			group.alpha = alpha
			for (var/turf/open/turf as anything in group.turfs)
				turf.liquid_effect.alpha = alpha

		var/smooth = GET_LIQUID_GROUP_SMOOTH(group)
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
				to_smooth.liquid_effect.icon_state = "[to_smooth.liquid_effect.base_icon_state]-[ALL_SMOOTHING_JUNCTIONS]"

		group.to_smooth.Cut()

/datum/controller/subsystem/liquids/proc/add_reagent_to_turf(turf/target, reagent_type, volume)
	return add_reagent_to_turfs(list(target), reagent_type, volume)

/datum/controller/subsystem/liquids/proc/add_reagent_to_turfs(list/turfs, reagent_type, volume)
	. = 0
	for (var/turf/open/target in turfs)
		if (!target.liquid_group)
			var/datum/liquid_group/group = new()
			add_turfs_to_group(group, list(target))

			. += group.reagents.add_reagent(reagent_type, volume, no_react = TRUE)
			group.needs_reagent_update = TRUE

			group.color = GET_LIQUID_GROUP_COLOR(group)
			group.alpha = GET_LIQUID_GROUP_ALPHA(group)
			group.smooth = GET_LIQUID_GROUP_SMOOTH(group)

			target.liquid_effect.color = group.color
			target.liquid_effect.alpha = group.alpha
			target.liquid_effect.icon_state = "[target.liquid_effect.base_icon_state]-[group.smooth ? NONE : ALL_SMOOTHING_JUNCTIONS]"
		else
			. += target.liquid_group.reagents.add_reagent(reagent_type, volume, no_react = TRUE)
			target.liquid_group.needs_reagent_update = TRUE

/datum/controller/subsystem/liquids/proc/remove_reagent_from_turf(turf/target, volume)
	return remove_reagents_from_turfs(list(target), volume)

/datum/controller/subsystem/liquids/proc/remove_reagents_from_turfs(list/turfs, volume)
	. = 0
	for (var/turf/open/target in turfs)
		if (!target.liquid_group)
			continue

		. += target.liquid_group.reagents.remove_all(volume)
		target.liquid_group.needs_reagent_update = TRUE

/datum/controller/subsystem/liquids/proc/add_turf_to_group(datum/liquid_group/group, turf/target)
	return add_turfs_to_group(group, list(target))

/datum/controller/subsystem/liquids/proc/add_turfs_to_group(datum/liquid_group/group, list/turfs)
	for (var/turf/open/to_add as anything in turfs)
		group.turfs[to_add] = TRUE
		group.to_smooth[to_add] = TRUE

		to_add.liquid_group = group
		to_add.liquid_effect = new(to_add)
		to_add.liquid_effect.color = group.color
		to_add.liquid_effect.alpha = group.alpha

		var/edge_dirs = NONE

		for (var/i in 1 to 8)
			var/turf/adjacent = get_step(to_add, GLOB.alldirs[i])

			if (group.turfs[adjacent])
				group.to_smooth[adjacent] = TRUE

				group.edges[adjacent] &= ~GLOB.reversed_junctions[i]
				if (!group.edges[adjacent])
					group.edges -= adjacent
			else
				edge_dirs |= GLOB.all_junctions[i]

		if (edge_dirs)
			group.edges[to_add] = edge_dirs

	group.reagents.maximum_volume = length(group.turfs) * LIQUID_HEIGHT_FULL
	group.needs_reagent_update = TRUE

/datum/controller/subsystem/liquids/proc/remove_turf_from_group(datum/liquid_group/group, turf/target)
	return remove_turfs_from_group(group, list(target))

/datum/controller/subsystem/liquids/proc/remove_turfs_from_group(datum/liquid_group/group, list/turfs)
	for (var/turf/open/to_remove as anything in turfs)
		group.turfs -= to_remove
		group.edges -= to_remove
		group.to_smooth -= to_remove

		to_remove.liquid_group = null
		QDEL_NULL(to_remove.liquid_effect)

		for (var/i in 1 to 8)
			var/turf/adjacent = get_step(to_remove, GLOB.alldirs[i])

			if (group.turfs[adjacent])
				group.to_smooth[adjacent] = TRUE
				group.edges[adjacent] |= GLOB.reversed_junctions[i]

	group.reagents.maximum_volume = length(group.turfs) * LIQUID_HEIGHT_FULL
	group.needs_reagent_update = TRUE

	if (!length(group.turfs))
		qdel(group)
