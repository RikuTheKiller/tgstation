/obj/structure/girder
	icon = 'icons/obj/smooth_structures/girder.dmi'
	name = "girder"
	base_icon_state = "girder"
	icon_state = "girder-0"
	desc = "A large structural assembly made out of metal; It requires a layer of iron before it can be considered a wall."
	anchored = TRUE
	density = TRUE
	max_integrity = 200
	rad_insulation = RAD_VERY_LIGHT_INSULATION
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_GIRDER
	canSmoothWith = SMOOTH_GROUP_GIRDER + SMOOTH_GROUP_WALLS
	var/state = GIRDER_NORMAL
	var/girderpasschance = 20 // percentage chance that a projectile passes through the girder.
	var/can_displace = TRUE //If the girder can be moved around by wrenching it
	var/next_beep = 0 //Prevents spamming of the construction sound
	/// The material cost to construct something on the girder
	var/static/list/construction_cost = list(
		/obj/item/stack/sheet/iron = 2,
		/obj/item/stack/rods = 5,
		/obj/item/stack/sheet/plasteel = 2,
		/obj/item/stack/sheet/bronze = 2,
		/obj/item/stack/sheet/runed_metal = 1,
		/obj/item/stack/sheet/titaniumglass = 2,
		exotic_material = 2 // this needs to be refactored properly
	)

	var/static/list/construction_steps = list(
		/datum/construction_step/girder/slice_apart,
		/datum/construction_step/girder/reinforce_frame,
		/datum/construction_step/girder/make_wall/iron,
		/datum/construction_step/girder/make_wall/false/iron,
		/datum/construction_step/girder/make_wall/rods,
		/datum/construction_step/girder/make_wall/false/rods,
		/datum/construction_step/girder/make_wall/tram/titaniumglass,
		/datum/construction_step/girder/make_wall/plasteel,
		/datum/construction_step/girder/make_wall/false/plasteel,
		/datum/construction_step/girder/make_wall/plastitanium,
		/datum/construction_step/girder/make_wall/material/normal,
		/datum/construction_step/girder/make_wall/material/concat/false,
		/datum/construction_step/girder/make_wall/material/concat/tram,
	)

/obj/structure/girder/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/complex_construction, step_types = construction_steps)

/obj/structure/girder/examine(mob/user)
	. = ..()
	switch(state)
		if(GIRDER_REINF)
			. += span_notice("The support struts are <b>screwed</b> in place.")
		if(GIRDER_REINF_STRUTS)
			. += span_notice("The support struts are <i>unscrewed</i> and the inner <b>grille</b> is intact.")
		if(GIRDER_NORMAL)
			if(can_displace)
				. += span_notice("The bolts are <b>wrenched</b> in place.")
		if(GIRDER_DISPLACED)
			. += span_notice("The bolts are <i>loosened</i>, but the <b>screws</b> are holding [src] together.")
		if(GIRDER_DISASSEMBLED)
			. += span_notice("[src] is disassembled! You probably shouldn't be able to see this examine message.")
		if(GIRDER_TRAM)
			. += span_notice("[src] is designed for tram usage. Deconstructed with a screwdriver!")

/obj/structure/girder/attackby(obj/item/W, mob/user, list/modifiers, list/attack_modifiers)
	add_fingerprint(user)

	if(istype(W, /obj/item/pipe))
		var/obj/item/pipe/P = W
		if (P.pipe_type in list(0, 1, 5)) //simple pipes, simple bends, and simple manifolds.
			if(!user.transfer_item_to_turf(P, drop_location()))
				return
			balloon_alert(user, "inserted pipe")
		return

	return ..()

// Screwdriver behavior for girders
/obj/structure/girder/screwdriver_act(mob/user, obj/item/tool)
	if(..())
		return TRUE

	. = FALSE
	if(state == GIRDER_TRAM)
		balloon_alert(user, "disassembling frame...")
		if(tool.use_tool(src, user, 4 SECONDS, volume=100))
			if(state != GIRDER_TRAM)
				return
			state = GIRDER_DISASSEMBLED
			var/obj/item/stack/sheet/mineral/titanium/material = new (user.loc, 2)
			if (!QDELETED(material))
				material.add_fingerprint(user)
			qdel(src)
		return TRUE

	if(state == GIRDER_DISPLACED)
		balloon_alert(user, "disassembling frame...")
		if(tool.use_tool(src, user, 40, volume=100))
			if(state != GIRDER_DISPLACED)
				return
			state = GIRDER_DISASSEMBLED
			var/obj/item/stack/sheet/iron/M = new (loc, 2)
			if (!QDELETED(M))
				M.add_fingerprint(user)
			qdel(src)
		return TRUE

	else if(state == GIRDER_REINF)
		balloon_alert(user, "unsecuring support struts...")
		if(tool.use_tool(src, user, 40, volume=100))
			if(state != GIRDER_REINF)
				return
			state = GIRDER_REINF_STRUTS
		return TRUE

	else if(state == GIRDER_REINF_STRUTS)
		balloon_alert(user, "securing support struts...")
		if(tool.use_tool(src, user, 40, volume=100))
			if(state != GIRDER_REINF_STRUTS)
				return
			state = GIRDER_REINF
		return TRUE

// Wirecutter behavior for girders
/obj/structure/girder/wirecutter_act(mob/user, obj/item/tool)
	. = ..()
	if(state == GIRDER_REINF_STRUTS)
		balloon_alert(user, "removing inner grille...")
		if(tool.use_tool(src, user, 40, volume=100))
			new /obj/item/stack/sheet/plasteel(get_turf(src))
			var/obj/structure/girder/G = new (loc)
			transfer_fingerprints_to(G)
			qdel(src)
		return TRUE

/obj/structure/girder/wrench_act(mob/user, obj/item/tool)
	. = ..()
	if(state == GIRDER_DISPLACED)
		if(!isfloorturf(loc))
			balloon_alert(user, "needs floor!")

		balloon_alert(user, "securing frame...")
		if(tool.use_tool(src, user, 40, volume=100))
			var/obj/structure/girder/G = new (loc)
			transfer_fingerprints_to(G)
			qdel(src)
		return TRUE
	else if(state == GIRDER_NORMAL && can_displace)
		balloon_alert(user, "unsecuring frame...")
		if(tool.use_tool(src, user, 40, volume=100))
			var/obj/structure/girder/displaced/D = new (loc)
			transfer_fingerprints_to(D)
			qdel(src)
		return TRUE

/obj/structure/girder/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if((mover.pass_flags & PASSGRILLE) || isprojectile(mover))
		return prob(girderpasschance)

/obj/structure/girder/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	if(!density)
		return TRUE
	if(pass_info.pass_flags & PASSGRILLE)
		return TRUE
	return FALSE

/obj/structure/girder/atom_deconstruct(disassembled = TRUE)
	var/sheet_type = state == GIRDER_TRAM ? /obj/item/stack/sheet/mineral/titanium : /obj/item/stack/sheet/iron

	if (disassembled)
		new sheet_type(loc, 2)
	else
		var/remains = pick(/obj/item/stack/rods, sheet_type)
		new remains(loc)

/obj/structure/girder/narsie_act()
	new /obj/structure/girder/cult(loc)
	qdel(src)

/obj/structure/girder/displaced
	name = "displaced girder"
	icon = 'icons/obj/structures.dmi'
	icon_state = "displaced"
	anchored = FALSE
	state = GIRDER_DISPLACED
	girderpasschance = 25
	max_integrity = 120
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null

/obj/structure/girder/reinforced
	name = "reinforced girder"
	icon = 'icons/obj/smooth_structures/reinforced_girder.dmi'
	icon_state = "reinforced-0"
	base_icon_state = "reinforced"
	state = GIRDER_REINF
	girderpasschance = 0
	max_integrity = 350

/obj/structure/girder/tram
	name = "tram girder"
	desc = "Titanium framework to construct tram walls. Can be plated with <b>titanium glass</b> or other wall materials."
	icon = 'icons/obj/structures.dmi'
	icon_state = "tram"
	state = GIRDER_TRAM
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null

/obj/structure/girder/tram/corner
	name = "tram frame corner"

//////////////////////////////////////////// cult girder //////////////////////////////////////////////

/obj/structure/girder/cult
	name = "runed girder"
	desc = "Framework made of a strange and shockingly cold metal. It doesn't seem to have any bolts."
	icon = 'icons/obj/antags/cult/structures.dmi'
	icon_state= "cultgirder"
	can_displace = FALSE
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	construction_steps = parent_type::construction_steps + /datum/construction_step/girder/make_wall/runed_metal

/obj/structure/girder/cult/attackby(obj/item/W, mob/user, list/modifiers, list/attack_modifiers)
	add_fingerprint(user)
	if(W.tool_behaviour == TOOL_WELDER)
		if(!W.tool_start_check(user, amount=1))
			return

		balloon_alert(user, "slicing apart...")
		if(W.use_tool(src, user, 40, volume=50))
			var/obj/item/stack/sheet/runed_metal/R = new(drop_location(), 1)
			transfer_fingerprints_to(R)
			qdel(src)

	else if(istype(W, /obj/item/stack/sheet/runed_metal))
		var/obj/item/stack/sheet/runed_metal/R = W
		var/amount = construction_cost[R.type]
		if(R.get_amount() < amount)
			balloon_alert(user, "need [amount] sheet!")
			return
		balloon_alert(user, "adding plating...")
		if(do_after(user, 5 SECONDS, target = src))
			if(R.get_amount() < amount)
				return
			R.use(amount)
			var/turf/T = get_turf(src)
			T.place_on_top(/turf/closed/wall/mineral/cult)
			qdel(src)

	else
		return ..()

/obj/structure/girder/cult/narsie_act()
	return

/obj/structure/girder/cult/atom_deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/runed_metal(drop_location())

/obj/structure/girder/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	switch(the_rcd.mode)
		if(RCD_TURF)
			if(the_rcd.rcd_design_path != /turf/open/floor/plating/rcd)
				return FALSE

			return rcd_result_with_memory(
				list("delay" = 2 SECONDS, "cost" = 8),
				get_turf(src), RCD_MEMORY_WALL,
			)
		if(RCD_DECONSTRUCT)
			return list("delay" = 2 SECONDS, "cost" = 13)
	return FALSE

/obj/structure/girder/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, list/rcd_data)
	switch(rcd_data["[RCD_DESIGN_MODE]"])
		if(RCD_TURF)
			if(the_rcd.rcd_design_path != /turf/open/floor/plating/rcd)
				return FALSE

			var/turf/T = get_turf(src)
			T.place_on_top(/turf/closed/wall)
			qdel(src)
			return TRUE
		if(RCD_DECONSTRUCT)
			qdel(src)
			return TRUE
	return FALSE

/obj/structure/girder/bronze
	name = "wall gear"
	desc = "A girder made out of sturdy bronze, made to resemble a gear."
	icon = 'icons/obj/structures.dmi'
	icon_state = "wall_gear"
	can_displace = FALSE
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null

/obj/structure/girder/bronze/attackby(obj/item/W, mob/living/user, list/modifiers, list/attack_modifiers)
	add_fingerprint(user)
	if(W.tool_behaviour == TOOL_WELDER)
		if(!W.tool_start_check(user, amount = 0, heat_required = HIGH_TEMPERATURE_REQUIRED))
			return
		balloon_alert(user, "slicing apart...")
		if(W.use_tool(src, user, 40, volume=50))
			var/obj/item/stack/sheet/bronze/B = new(drop_location(), 2)
			transfer_fingerprints_to(B)
			qdel(src)

	else if(istype(W, /obj/item/stack/sheet/bronze))
		var/obj/item/stack/sheet/bronze/B = W
		var/amount = construction_cost[B.type]
		if(B.get_amount() < amount)
			balloon_alert(user, "need [amount] sheets!")
			return
		balloon_alert(user, "adding plating...")
		if(do_after(user, 5 SECONDS, target = src))
			if(B.get_amount() < amount)
				return
			B.use(amount)
			var/turf/T = get_turf(src)
			T.place_on_top(/turf/closed/wall/mineral/bronze)
			qdel(src)

	else
		return ..()
