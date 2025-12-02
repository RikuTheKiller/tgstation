/obj/structure/blueprint/wall
	name = "wall blueprint"
	type_name_plural = "walls"

	sheet_stack_build_path = /obj/structure/girder

/obj/structure/blueprint/wall/can_work_on(obj/object)
	return istype(object, /obj/structure/girder)
