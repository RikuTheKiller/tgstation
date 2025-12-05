/// A global associative list of all construction step types to their instances.
GLOBAL_ALIST_INIT(construction_steps, init_construction_steps())

/proc/init_construction_steps()
	. = alist()
	for (var/step_type in valid_typesof(/datum/construction_step))
		.[step_type] = new step_type()
