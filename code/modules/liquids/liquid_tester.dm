/obj/effect/abstract/liquid_tester

/obj/effect/abstract/liquid_tester/New(loc, ...)
	SSliquids.add_reagent_to_turf(get_turf(src), /datum/reagent/iron, 1000)
	qdel(src)
