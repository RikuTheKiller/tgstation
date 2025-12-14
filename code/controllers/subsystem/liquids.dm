#define ADD_TURF_TO_GROUP(group, turf) \
	group.turfs[turf] = TRUE; \
	group.edges[turf] = TRUE; \
	group.needs_edge_update = TRUE; \
	turf.liquid_group = group; \
	turf.liquid_effect = new(turf);

#define REMOVE_TURF_FROM_GROUP(group, turf) \
	group.turfs -= turf; \
	group.edges -= turf; \
	group.needs_edge_update = TRUE; \
	turf.liquid_group = null; \
	QDEL_NULL(turf.liquid_effect);

#define MERGE_GROUPS(to, from) \
	for (var/turf/open/turf as anything in from.turfs) { \
		to.turfs[turf] = TRUE; \
		turf.liquid_group = to; \
	}; \
	for (var/turf/open/turf as anything in from.edges) { \
		to.edges[turf] = TRUE; \
	}; \
	for (var/turf/open/turf as anything in from.to_add) { \
		to.to_add[turf] = TRUE; \
	}; \
	for (var/turf/open/turf as anything in from.to_remove) { \
		to.to_remove[turf] = TRUE; \
	}; \
	from.reagents.trans_to(to.reagents, from.reagents.total_volume, no_react = TRUE); \
	to.needs_edge_update = TRUE; \
	qdel(from);

SUBSYSTEM_DEF(liquids)
	name = "Liquids"
	wait = 0.2 SECONDS
	priority = FIRE_PRIORITY_LIQUIDS

	/// The index of the current liquid subsystem stage.
	var/stage = 0

	/// List of all liquid groups.
	var/list/groups = list()

	/// List of all liquid groups in queue for the current stage.
	var/list/queue = list()

/datum/controller/subsystem/liquids/Initialize()
	return SS_INIT_SUCCESS

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
	RUN_STAGE(4, edges)

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
				for (var/cardinal in GLOB.cardinals)
					var/turf/open/adjacent = get_step(edge, cardinal)

					if (!isopenturf(adjacent))
						continue
					if (adjacent.liquid_group == group)
						continue
					if (!edge.atmos_adjacent_turfs?[adjacent])
						continue

					group.to_add[adjacent] = TRUE
		// Spreading End

		// Receding Start
		if (group.reagents.total_volume / length(group.turfs) < LIQUIDS_TURF_MIN_VOLUME)
			for (var/turf/open/edge as anything in group.edges)
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

		while (length(group.to_add))
			var/turf/open/to_add = group.to_add[length(group.to_add)]
			group.to_add.Cut(length(group.to_add))

			var/datum/liquid_group/other_group = to_add.liquid_group

			if (other_group == group)
				continue
			if (other_group)
				MERGE_GROUPS(group, other_group)

			ADD_TURF_TO_GROUP(group, to_add)

/datum/controller/subsystem/liquids/proc/queue_edges()
	for (var/datum/liquid_group/group as anything in groups)
		if (group.needs_edge_update)
			queue += group

/datum/controller/subsystem/liquids/proc/run_edges()
	while (length(queue))
		if (MC_TICK_CHECK)
			return

		var/datum/liquid_group/group = queue[length(queue)]
		queue.Cut(length(queue))

		var/list/new_edges = list()
		for (var/turf/open/turf as anything in group.edges)
			var/is_edge = FALSE

			for (var/cardinal in GLOB.cardinals)
				var/turf/open/adjacent = get_step(turf, cardinal)

				if (!isopenturf(adjacent) || adjacent.liquid_group != group)
					is_edge = TRUE
					break

			if (is_edge)
				new_edges[turf] = TRUE

		group.edges.Cut()
		group.edges = new_edges
		group.needs_edge_update = FALSE

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
