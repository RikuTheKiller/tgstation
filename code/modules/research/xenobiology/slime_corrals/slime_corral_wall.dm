/obj/structure/slime_corral_wall
	name = "slime corral wall"
	desc = "A shield wall for a slime corral. Prevents slimes from getting in or out."

	icon = 'icons/obj/science/slime_corral.dmi'
	icon_state = "wall"

	anchored = TRUE
	can_atmos_pass = ATMOS_PASS_PROC
	density = FALSE
	opacity = FALSE
	flags_1 = ON_BORDER_1

	alpha = 0

	/// The slime corral this wall is a part of.
	var/datum/slime_corral/corral = null

/obj/structure/slime_corral_wall/Initialize(mapload, dir)
	. = ..()
	setDir(dir)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = PROC_REF(on_exit),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	air_update_turf(TRUE, TRUE)

/obj/structure/slime_corral_wall/Destroy()
	air_update_turf(TRUE, FALSE)
	return ..()

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

/obj/structure/slime_corral_wall/CanPass(atom/movable/mover, border_dir)
	return !((border_dir == dir) && (ismonkey(mover) || isslime(mover))) ? ..() : TRUE

/obj/structure/slime_corral_wall/can_atmos_pass(turf/T, vertical = FALSE)
	if(QDELING(src))
		return TRUE

	return !(dir == get_dir(loc, T))
