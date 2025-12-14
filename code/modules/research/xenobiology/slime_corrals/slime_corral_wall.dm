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

/obj/structure/slime_corral_wall/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if((ismonkey(mover) || isslime(mover)) && !mover.throwing)
		return FALSE
	return .
