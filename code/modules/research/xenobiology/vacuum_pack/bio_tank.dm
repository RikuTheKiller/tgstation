/obj/item/bio_tank
	abstract_type = /obj/item/bio_tank
	icon = 'icons/obj/canisters.dmi'
	icon_state = "generic"
	inhand_icon_state = "generic_tank"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/equipment/tanks_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tanks_righthand.dmi'

/obj/item/bio_tank/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands = TRUE)

/obj/item/bio_tank/proc/expand_examine()
	return

/obj/item/bio_tank/proc/fire_content(mob/user)
	return

/obj/item/bio_tank/proc/load_mob(mob/living/carbon/victim, mob/living/user)
	return

/obj/item/bio_tank/examine(mob/user)
	. = ..()
	. += expand_examine()

/obj/item/bio_tank/slime
	name = "slime containment tank"
	desc = "A cylindrical tank that can keep a slime in stasis. Fits in a vacuum pack."
	var/mob/living/basic/slime/prisoner

/obj/item/bio_tank/slime/Destroy()
	QDEL_NULL(prisoner)
	return ..()

/obj/item/bio_tank/slime/atom_break()
	if(prisoner)
		prisoner.forceMove(get_turf(src))
	return ..()

/obj/item/bio_tank/slime/expand_examine()
	return prisoner ? "The tank contains \a [prisoner]." : "The tank is empty"

/obj/item/bio_tank/slime/fire_content(mob/user)
	if(!prisoner)
		balloon_alert(user, "no slime!")
		return

	var/free_slime = prisoner
	prisoner.forceMove(get_turf(src))
	prisoner = null
	return free_slime

/obj/item/bio_tank/slime/load_mob(mob/living/carbon/victim, mob/living/user)
	if(prisoner)
		balloon_alert(user, "tank full!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(!isslime(victim))
		balloon_alert(user, "not slime!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	prisoner = victim
	victim.forceMove(src)
	victim.say(pick("Noooo","Where are we going","Oh!"), forced = "slimecapture")

/obj/item/bio_tank/monkey
	name = "bio-cube tank"
	desc = "A cylindrical tank that can store biomass and convert it into living monkeys. Monkey cubes worth more than dead monkeys. Fits in a vacuum pack."
	icon_state = "oxygen"
	inhand_icon_state = "oxygen_tank"
	///current amount of biomass in the tank
	var/current_biomass = 5
	///max amount of biomass that the tank can take, in monkey cube form
	var/max_biomass = 10
	///biomass gain per monkey
	var/biomass_gain = 0.25
	///cost for spawning a monkey
	var/monkey_cost = 1

/obj/item/bio_tank/monkey/expand_examine()
	return "The tank contains [current_biomass] units of biomass, out of [max_biomass] units."

/obj/item/bio_tank/monkey/load_mob(mob/living/carbon/victim, mob/living/user)

	if(current_biomass >= max_biomass)
		balloon_alert(user, "tank full!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(!ismonkey(victim))
		balloon_alert(user, "not monkey!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(victim.stat != DEAD)
		balloon_alert(user, "monkey alive!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	playsound(src, 'sound/items/pshoom/pshoom.ogg', 50, TRUE)
	qdel(victim)
	current_biomass = min(max_biomass, current_biomass + biomass_gain)

/obj/item/bio_tank/monkey/fire_content(mob/user)
	if(current_biomass < monkey_cost)
		balloon_alert(user, "not enough biomass!")
		return

	current_biomass -= monkey_cost
	var/mob/living/monkey_to_fire = new /mob/living/carbon/human/species/monkey(get_turf(src), TRUE, user)
	if(QDELETED(monkey_to_fire))
		return

	ADD_TRAIT(monkey_to_fire, TRAIT_SPAWNED_MOB, INNATE_TRAIT)
	monkey_to_fire.apply_status_effect(/datum/status_effect/slime_food, user)
	return monkey_to_fire
