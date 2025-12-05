/datum/construction_controller/grille

/datum/construction_controller/grille/run_controller(mob/living/user, obj/item/used_item, obj/structure/grille/grille, list/modifiers)


/datum/construction_step/grille

/datum/construction_step/grille/make_window
	req_item_amount = 2
	starting_alert_text = "placing window..."

/datum/construction_step/grille/make_window/get_results_of_type(mob/living/user, obj/item/used_item, obj/structure/grille/grille, list/modifiers, result_type, result_amount)
	if (ispath(result_type, /obj/structure/window))
		return list(get_result_window_of_type(grille, result_type))
	return ..()

/datum/construction_step/grille/make_window/proc/get_result_window_of_type(obj/structure/grille/grille, window_type)
	var/obj/structure/window/window = new window_type(grille.drop_location())
	window.setDir(SOUTHWEST)
	window.set_anchored(FALSE)
	window.state = 0
	return window

/datum/construction_step/grille/make_window/plasmarglass
	result_types = list(/obj/structure/window/reinforced/plasma/fulltile = 1)
