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

/obj/item/bio_tank/proc/load_mob(mob/living/carbon/victim, mob/living/user)
	return

/obj/item/bio_tank/proc/expand_examine()
	return

/obj/item/bio_tank/examine(mob/user)
	. = ..()
	. += expand_examine()

/obj/item/bio_tank/slime
	name = "slime containment tank"
	desc = "A cylindrical tank that can keep a slime in stasis. Fits in a vacuum pack."
	var/mob/living/basic/slime/prisoner

/obj/item/bio_tank/slime/expand_examine()
	return prisoner ? "The tank contains \a [prisoner]." : "The tank is empty"

/obj/item/bio_tank/slime/load_mob(mob/living/carbon/victim, mob/living/user)

	if(prisoner)
		user.balloon_alert("tank full!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(!isslime(victim))
		user.balloon_alert("not slime!")
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

/obj/item/bio_tank/monkey/expand_examine()
	return "The tank contains [current_biomass] units of biomass, out of [max_biomass] units."

/obj/item/bio_tank/monkey/load_mob(mob/living/carbon/victim, mob/living/user)

	if(current_biomass >= max_biomass)
		user.balloon_alert("tank full!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(!ismonkey(victim))
		user.balloon_alert("not monkey!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	if(victim.stat != DEAD)
		user.balloon_alert("monkey alive!")
		playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
		return

	playsound(src, 'sound/items/pshoom/pshoom.ogg', 50, TRUE)
	qdel(victim)
	current_biomass = min(max_biomass, current_biomass + biomass_gain)

