/obj/structure/slime_corral_wall
	name = "slime corral wall"
	desc = "A shield wall for a slime corral. Prevents slimes from getting in or out."

	icon = 'icons/obj/science/slime_corral.dmi'
	icon_state = "wall"

	anchored = TRUE
	density = FALSE
	opacity = FALSE

	alpha = 0

	/// The slime corral this wall is a part of.
	var/datum/slime_corral/corral = null

/obj/structure/slime_corral_wall/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = PROC_REF(on_exit),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/slime_corral_wall/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if((border_dir == dir) && (ismonkey(mover) || isslime(mover)) && !mover.throwing)
		return FALSE
	return .

/obj/structure/slime_corral_wall/proc/on_exit(datum/source, atom/movable/leaving, direction)
	SIGNAL_HANDLER

	if(leaving == src)
		return

	if((direction == dir) && (ismonkey(leaving) || isslime(leaving)) && !leaving.throwing)
		leaving.Bump(src)
		return COMPONENT_ATOM_BLOCK_EXIT
