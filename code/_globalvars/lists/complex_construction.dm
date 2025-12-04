/// A global associative list of all construction step types to their instances.
GLOBAL_ALIST_INIT(construction_steps, init_construction_steps())

/proc/init_construction_steps()
	. = alist()
	for (var/datum/construction_step/step_type as anything in typesof(/datum/construction_step))
		if (step_type::abstract_type != step_type)
			.[step_type] = new step_type()
