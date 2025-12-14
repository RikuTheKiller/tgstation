/datum/liquid_group
	/// Associative list of turfs in this group. (list[turf] = TRUE)
	var/list/turfs = list()

	/// Associative list of edge turfs in this group. (list[turf] = TRUE)
	var/list/edges = list()

	/// Associative list of turfs to add to this group. (list[turf] = TRUE)
	var/list/to_add = list()

	/// Associative list of turfs to remove from this group. (list[turf] = TRUE)
	var/list/to_remove = list()

	var/needs_edge_update = FALSE

	/// The reagents holder of this group.
	var/datum/reagents/reagents = null

/datum/liquid_group/New()
	reagents = new(INFINITY)
	SSliquids.groups += src

/datum/liquid_group/Destroy(force)
	turfs.Cut()
	edges.Cut()
	to_add.Cut()
	to_remove.Cut()
	SSliquids.groups -= src
	SSliquids.queue -= src
	return ..()
