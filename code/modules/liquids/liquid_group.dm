/datum/liquid_group
	/// Associative list of turfs in this group. (list[turf] = TRUE)
	var/list/turfs = list()

	/// Associative list of edge turfs in this group. (list[turf] = junction)
	/// The value is an 8-dir junction of directions from the turf that aren't part of this liquid group.
	var/list/edges = list()

	/// Associative list of turfs to add to this group. (list[turf] = TRUE)
	var/list/to_add = list()

	/// Associative list of turfs to remove from this group. (list[turf] = TRUE)
	var/list/to_remove = list()

	/// Associative list of turfs to smooth update in this group. (list[turf] = TRUE)
	var/list/to_smooth = list()

	/// Whether the liquid group needs a reagents update to recompute visual height and color.
	var/needs_reagent_update = FALSE

	/// The color of the reagent solution of this liquid group.
	var/color = "#FFFFFF"

	/// Whether this liquid group has icon smoothing enabled or not.
	var/smooth = TRUE

	/// The alpha of the liquid effects of this liquid group.
	var/alpha = 255

	/// The reagents holder of this group.
	var/datum/reagents/reagents = null

/datum/liquid_group/New()
	reagents = new(0)
	SSliquids.groups += src

/datum/liquid_group/Destroy(force)
	turfs.Cut()
	edges.Cut()
	to_add.Cut()
	to_remove.Cut()
	to_smooth.Cut()
	SSliquids.groups -= src
	SSliquids.queue -= src
	return ..()
