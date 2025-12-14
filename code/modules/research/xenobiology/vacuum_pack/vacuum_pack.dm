/obj/item/vacuum_pack
	name = "vacuum pack"
	desc = "This backpack can hold pressurized bio-tanks, and manipulate its contents using the attached hose."

	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "waterbackpack"
	inhand_icon_state = "waterbackpack"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'

	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	armor_type = /datum/armor/item_vacuum_pack
	resistance_flags = ACID_PROOF
	actions_types = list(/datum/action/item_action/toggle_hose)

	var/obj/item/bio_tank/loaded_tank
	var/obj/item/vacuum_hose/hose

/datum/armor/item_vacuum_pack
	fire = 50
	acid = 100

/obj/item/vacuum_pack/Initialize(mapload)
	. = ..()
	hose = new /obj/item/vacuum_hose(src)
	RegisterSignal(hose, COMSIG_MOVABLE_MOVED, PROC_REF(hose_moved))
	AddElement(/datum/element/drag_pickup)
	register_context()

/obj/item/vacuum_pack/Destroy()
	QDEL_NULL(hose)
	QDEL_NULL(loaded_tank)
	return ..()

/obj/item/vacuum_pack/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(!loaded_tank)
		return NONE

	context[SCREENTIP_CONTEXT_RMB] = "Remove tank"

	return CONTEXTUAL_SCREENTIP_SET

/obj/item/vacuum_pack/atom_break()
	if(loaded_tank)
		loaded_tank.forceMove(get_turf(src))
	return ..()

/obj/item/vacuum_pack/attack_hand(mob/user, list/modifiers)
	if (user.get_item_by_slot(user.getBackSlot()) == src)
		toggle_hose(user)
	else
		return ..()

/obj/item/vacuum_pack/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/bio_tank) && !loaded_tank)
		loaded_tank = attacking_item
		attacking_item.forceMove(src)
		playsound(loc, 'sound/effects/spray.ogg', 10, TRUE, -3)
		return TRUE

	if(attacking_item == hose)
		remove_hose()
		return TRUE
	else
		return ..()

/obj/item/vacuum_pack/dropped(mob/user)
	..()
	remove_hose()

/obj/item/vacuum_pack/equipped(mob/user, slot)
	..()
	if(!(slot & ITEM_SLOT_BACK))
		remove_hose()

/obj/item/vacuum_pack/examine(mob/user)
	. = ..()

	if(loaded_tank)
		. += "It is holding \a [loaded_tank]."
		. += loaded_tank.expand_examine()

/obj/item/vacuum_pack/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)

	if(loaded_tank && loaded_tank.attackby(attacking_item, user, modifiers, attack_modifiers))
		return

	return ..()

/obj/item/vacuum_pack/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || !loaded_tank)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(!user.put_in_hands(loaded_tank))
		loaded_tank.forceMove(get_turf(src))

	loaded_tank = null
	playsound(loc, 'sound/effects/spray.ogg', 10, TRUE, -3)

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/vacuum_pack/ui_action_click(mob/user)
	toggle_hose(user)

/obj/item/vacuum_pack/proc/hose_moved(atom/movable/mover, atom/oldloc, direction)
	if(mover.loc == src || mover.loc == loc)
		return
	balloon_alert(loc, "hose snaps back")
	mover.forceMove(src)

/obj/item/vacuum_pack/proc/remove_hose()
	if(!QDELETED(hose))
		if(ismob(hose.loc))
			var/mob/holder = hose.loc
			holder.temporarilyRemoveItemFromInventory(hose, TRUE)
		hose.forceMove(src)

/obj/item/vacuum_pack/proc/toggle_hose(mob/living/user)
	if(!istype(user))
		return
	if(user.get_item_by_slot(user.getBackSlot()) != src)
		to_chat(user, span_warning("The vacuum pack must be worn properly to use!"))
		return
	if(user.incapacitated)
		return

	if(QDELETED(hose))
		hose = new /obj/item/vacuum_hose(src)
		RegisterSignal(hose, COMSIG_MOVABLE_MOVED, PROC_REF(hose_moved))
	if(hose in src)
		if(!user.put_in_hands(hose))
			to_chat(user, span_warning("You need a free hand to hold the hose!"))
			return
	else
		remove_hose()

/obj/item/vacuum_pack/verb/toggle_hose_verb()
	set name = "Toggle Hose"
	set category = "Object"
	toggle_hose(usr)
