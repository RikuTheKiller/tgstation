/obj/structure/blueprint
	abstract_type = /obj/structure/blueprint

	name = "blueprint"
	desc = "A holographic blueprint for guiding and speeding up construction."

	icon = 'icons/obj/smooth_structures/girder.dmi'
	icon_state = "girder-0"

	layer = ABOVE_MOB_LAYER

	anchored = TRUE
	density = FALSE
	opacity = FALSE

	max_integrity = 10

	/// The name of the blueprint type in plural, e.g. "walls"
	var/type_name_plural = ""

	/// The path of the object that the blueprint will try to make if you use a sheet stack on it.
	/// Only supports objects for now. The code will complain if it's not an object path.
	var/sheet_stack_build_path = null

	/// A multiplier that dictates how much the blueprint speeds up construction.
	var/build_speed_multiplier = 2

	/// The current turf this blueprint is registered to.
	/// Changes if the blueprint is moved.
	var/turf/current_turf = null
	/// The current construction object this blueprint is working on, if any.
	/// Changes if the old one is moved or destroyed.
	var/obj/current_object = null

/obj/structure/blueprint/Initialize(mapload)
	. = ..()
	update_current_turf()
	update_appearance(UPDATE_DESC)

/obj/structure/blueprint/Destroy(force)
	unregister_current_turf()
	return ..()

/obj/structure/blueprint/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	update_current_turf()

/obj/structure/blueprint/update_desc(updates)
	desc = "[initial(desc)] This one is meant for constructing [type_name_plural]."
	return ..()
