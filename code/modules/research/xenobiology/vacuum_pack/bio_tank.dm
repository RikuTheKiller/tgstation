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

/obj/item/bio_tank/slime
	name = "slime containment tank"
	desc = "A cylindrical tank that can keep a slime in stasis. Fits in a vacuum pack."

/obj/item/bio_tank/monkey
	name = "bio-cube tank"
	desc = "A cylindrical tank that can store and dispense dehydrated lifeforms. Fits in a vacuum pack."
	icon_state = "oxygen"
	inhand_icon_state = "oxygen_tank"
