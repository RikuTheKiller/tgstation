#define UPDATE_EDGE(group, edge) \
	var/edge_dirs = NONE; \
	for (var/i in 1 to length(GLOB.alldirs)) { \
		var/turf/adjacent = get_step(edge, GLOB.alldirs[i]); \
		if (!group.turfs[adjacent]) { \
			edge_dirs |= GLOB.all_junctions[i]; \
		} \
	} \
	if (edge_dirs) { \
		group.edges[edge] = edge_dirs; \
	} else if (group.edges[edge]) { \
		group.edges -= edge; \
	}

#define ADD_TURF_TO_GROUP(group, to_add) \
	group.turfs[to_add] = TRUE; \
	to_add.liquid_group = group; \
	to_add.liquid_effect = new(to_add); \
	for (var/turf/updating as anything in RANGE_TURFS(1, to_add)) { \
		if (group.turfs[updating]) { \
			group.to_smooth[updating] = TRUE; \
			UPDATE_EDGE(group, updating); \
		} \
	};

#define REMOVE_TURF_FROM_GROUP(group, to_remove) \
	group.turfs -= to_remove; \
	group.edges -= to_remove; \
	group.to_smooth -= to_remove; \
	to_remove.liquid_group = null; \
	QDEL_NULL(to_remove.liquid_effect); \
	for (var/dir in GLOB.alldirs) { \
		var/turf/updating = get_step(to_remove, dir); \
		if (group.turfs[updating]) { \
			group.to_smooth[updating] = TRUE; \
			UPDATE_EDGE(group, updating); \
		} \
	};

#define MERGE_GROUPS(to, from) \
	for (var/turf/open/turf as anything in from.turfs) { \
		to.turfs[turf] = TRUE; \
		turf.liquid_group = to; \
	}; \
	for (var/turf/open/turf as anything in from.edges) { \
		to.edges[turf] = from.edges[turf]; \
	}; \
	for (var/turf/open/turf as anything in from.to_add) { \
		to.to_add[turf] = TRUE; \
	}; \
	for (var/turf/open/turf as anything in from.to_remove) { \
		to.to_remove[turf] = TRUE; \
	}; \
	for (var/turf/open/turf as anything in from.to_smooth) { \
		to.to_smooth[turf] = TRUE; \
	}; \
	from.reagents.trans_to(to.reagents, from.reagents.total_volume, no_react = TRUE); \
	qdel(from);

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

	RUN_STAGE(1, spread)
	RUN_STAGE(2, remove)
	RUN_STAGE(3, add)
	RUN_STAGE(4, smooth)

#undef RUN_STAGE

/datum/controller/subsystem/liquids/proc/queue_spread()
	queue = groups.Copy()

/datum/controller/subsystem/liquids/proc/run_spread()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		// Spreading Start
		if (group.reagents.total_volume / (length(group.turfs) + length(group.edges) * 4) >= LIQUIDS_TURF_MIN_VOLUME)
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

					group.to_add[spreading_to] = TRUE
		// Spreading End

		// Receding Start
		if (group.reagents.total_volume / length(group.turfs) < LIQUIDS_TURF_MIN_VOLUME)
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

		for (var/turf/open/to_remove as anything in group.to_remove)
			REMOVE_TURF_FROM_GROUP(group, to_remove)

		group.to_remove.Cut()

		if (!length(group.turfs))
			qdel(group)

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

		var/list/add_queue = list()

		// Merging Start
		while (length(group.to_add))
			var/turf/open/to_add = group.to_add[length(group.to_add)]
			group.to_add.Cut(length(group.to_add))
			add_queue += to_add

			var/datum/liquid_group/other_group = to_add.liquid_group

			if (other_group && other_group != group)
				MERGE_GROUPS(group, other_group)
		// Merging End

		// Adding Start
		for (var/turf/open/to_add as anything in add_queue)
			ADD_TURF_TO_GROUP(group, to_add)
		// Adding End

/datum/controller/subsystem/liquids/proc/queue_smooth()
	for (var/datum/liquid_group/group as anything in groups)
		if (length(group.to_smooth))
			queue += group

/datum/controller/subsystem/liquids/proc/run_smooth()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		for (var/turf/open/to_smooth as anything in group.to_smooth)
			var/icon_index = group.edges[to_smooth] ^ ALL_SMOOTHING_JUNCTIONS // 255 possible states

			for (var/i in 1 to length(GLOB.diagonals))
				if ((icon_index & GLOB.diagonals[i]) != GLOB.diagonals[i]) // 255 -> 47 possible states, as we only accept diagonal junctions for smoothing if they're adjacent to 2 cardinal junctions
					icon_index &= ~GLOB.diagonal_junctions[i]

			to_smooth.liquid_effect.icon_state = "[to_smooth.liquid_effect.base_icon_state]-[icon_index]"

		group.to_smooth.Cut()

/datum/controller/subsystem/liquids/proc/ensure_has_group(turf/open/target)
	PRIVATE_PROC(TRUE)
	if (target.liquid_group)
		return TRUE

	var/datum/liquid_group/group = new()
	ADD_TURF_TO_GROUP(group, target)
	return TRUE

/datum/controller/subsystem/liquids/proc/add_reagent_to_turf(turf/open/target, reagent_type, volume)
	return ensure_has_group(target) ? add_reagent_to_group(target.liquid_group, reagent_type, volume) : 0

/datum/controller/subsystem/liquids/proc/add_reagent_to_group(datum/liquid_group/group, reagent_type, volume)
	return group.reagents.add_reagent(reagent_type, volume, no_react = TRUE)

#undef ADD_TURF_TO_GROUP
#undef REMOVE_TURF_FROM_GROUP
#undef MERGE_GROUPS
