/datum/action/cooldown/mob_cooldown/blood_worm_cocoon
	cooldown_time = 30 SECONDS
	shared_cooldown = NONE

	click_to_activate = FALSE

	var/cocoon_type = null
	var/obj/structure/blood_worm_cocoon/cocoon = null

	var/total_blood_required = 0

	var/curve_max_point = BLOOD_VOLUME_NORMAL * 2
	var/curve_half_point = BLOOD_VOLUME_NORMAL

	var/timer_id = null

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/Grant(mob/granted_to)
	. = ..()
	if (!owner)
		return

	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_worm_stat_changed), override = TRUE)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/IsAvailable(feedback)
	if (!istype(owner, /mob/living/basic/blood_worm))
		return FALSE
	if (!ispath(cocoon_type, /obj/structure/blood_worm_cocoon))
		return FALSE
	if (!check_consumed_blood(feedback))
		return FALSE
	if (cocoon != null)
		return FALSE
	return ..()

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/Activate(atom/target)
	var/mob/living/basic/blood_worm/worm = owner

	worm.visible_message(
		message = span_danger("\The [worm] start[worm.p_s()] growing a cocoon!"),
		self_message = span_danger("You start growing a cocoon."),
		blind_message = span_hear("You start hearing fleshy knitting!")
	)

	if (!do_after(worm, 5 SECONDS, extra_checks = CALLBACK(src, PROC_REF(check_consumed_blood))))
		worm.balloon_alert(worm, "interrupted!")
		return FALSE

	worm.visible_message(
		message = span_danger("\The [worm] enter[worm.p_s()] a cocoon!"),
		self_message = span_green("You enter your freshly grown cocoon!"),
		blind_message = span_hear("You stop hearing fleshy knitting!")
	)

	cocoon = new cocoon_type(get_turf(worm))

	// If you're doing this in maints, nobody outside of those maints should hear it.
	playsound(cocoon, 'sound/effects/blob/blobattack.ogg', vol = 60, vary = TRUE, ignore_walls = FALSE)

	worm.forceMove(cocoon)

	worm.become_blind(REF(src))
	worm.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_DEAF, TRAIT_MUTE), REF(src))

	RegisterSignal(worm, COMSIG_MOVABLE_MOVED, PROC_REF(on_worm_moved))
	RegisterSignal(cocoon, COMSIG_QDELETING, PROC_REF(on_cocoon_qdel))

	timer_id = addtimer(CALLBACK(src, PROC_REF(finalize), worm), 30 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/finalize(mob/living/basic/blood_worm/worm)
	for (var/mob/living/unfortunate_observer in range(3, cocoon))
		if (istype(unfortunate_observer, /mob/living/basic/blood_worm))
			continue // Don't harm our siblings.

		unfortunate_observer.visible_message(
			message = span_danger("\The [unfortunate_observer] is splashed with a wave of corrosive blood!"),
			self_message = span_userdanger("You're splashed with a wave of corrosive blood! YEOWCH!"),
			blind_message = span_hear("You hear sizzling!")
		)

		unfortunate_observer.adjustFireLoss(rand(30, 50))

		var/range = 4 - get_dist(worm, unfortunate_observer)
		unfortunate_observer.throw_at(get_ranged_target_turf_direct(worm, unfortunate_observer, range), range = range, speed = 2)

	for (var/turf/turf as anything in RANGE_TURFS(3, cocoon))
		if (prob(100 - get_dist(cocoon, turf) * 20))
			new /obj/effect/decal/cleanable/blood(turf)

	// If you're doing this in maints, nobody outside of those maints should hear it.
	playsound(cocoon, 'sound/effects/splat.ogg', vol = 100, vary = TRUE, ignore_walls = FALSE)

	shared_unregister_cocoon(worm)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/cancel(mob/living/basic/blood_worm/worm)
	cocoon.visible_message(
		message = span_danger("\The [cocoon] fall[cocoon.p_s()] apart, expelling \the [worm] within."),
		blind_message = span_danger("You hear a splat!"),
		ignored_mobs = worm
	)

	if (worm.stat != DEAD)
		to_chat(worm, span_userdanger("Your cocoon falls apart!"))

	// If you're doing this in maints, nobody outside of those maints should hear it.
	playsound(cocoon, 'sound/effects/splat.ogg', vol = 60, vary = TRUE, ignore_walls = FALSE)

	StartCooldown()

	shared_unregister_cocoon(worm)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/shared_unregister_cocoon(mob/living/basic/blood_worm/worm)
	UnregisterSignal(worm, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(cocoon, COMSIG_QDELETING)

	worm.cure_blind(REF(src))
	worm.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_DEAF, TRAIT_MUTE), REF(src))

	if (!QDELETED(worm))
		worm.forceMove(get_turf(cocoon))

	QDEL_NULL(cocoon)

	if (timer_id)
		deltimer(timer_id)
		timer_id = null

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/on_worm_stat_changed(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if (cocoon && old_stat != DEAD && new_stat == DEAD) // Alive -> Dead
		cancel(owner)
	update_status_on_signal(source, new_stat, old_stat)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/on_worm_moved(datum/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	cancel(owner)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/on_cocoon_qdel(datum/source)
	SIGNAL_HANDLER
	cancel(owner)

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/check_consumed_blood(feedback = FALSE)
	var/total_consumed_blood = get_total_consumed_blood()
	if (total_consumed_blood < total_blood_required)
		if (feedback)
			owner.balloon_alert(owner, "only at [FLOOR(total_consumed_blood / total_blood_required * 100, 1)]% of required growth!")
		return FALSE
	return TRUE

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/get_total_consumed_blood()
	var/mob/living/basic/blood_worm/worm = owner

	var/total_consumed_blood = 0

	for (var/blood_type as anything in worm.consumed_blood)
		var/base_amount = worm.consumed_blood[blood_type]

		// Michaelis-Menten curve. Output increases rapidly and then begins to fall off after reaching the half point.
		total_consumed_blood += (curve_max_point * base_amount) / (curve_half_point + base_amount)

	return total_consumed_blood

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/proc/transfer(mob/living/basic/blood_worm/old_worm, mob/living/basic/blood_worm/new_worm)
	old_worm.mind?.transfer_to(new_worm)

	new_worm.consumed_blood = old_worm.consumed_blood

	new_worm.spit_action?.full_key = old_worm.spit_action?.full_key
	new_worm.leech_action?.full_key = old_worm.leech_action?.full_key
	new_worm.invade_action?.full_key = old_worm.invade_action?.full_key
	new_worm.cocoon_action?.full_key = old_worm.cocoon_action?.full_key

	new_worm.transfuse_action?.full_key = old_worm.transfuse_action?.full_key
	new_worm.eject_action?.full_key = old_worm.eject_action?.full_key
	new_worm.revive_action?.full_key = old_worm.revive_action?.full_key

	new_worm.cocoon_action?.StartCooldown()

	qdel(old_worm)

/obj/structure/blood_worm_cocoon
	density = TRUE
	anchored = TRUE

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/hatchling
	name = "Mature"
	desc = "Enter incubation in a cocoon, emerging as a juvenile blood worm."
	cocoon_type = /obj/structure/blood_worm_cocoon/hatchling
	total_blood_required = 1000

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/hatchling/finalize(mob/living/basic/blood_worm/worm)
	var/mob/living/basic/blood_worm/juvenile/new_worm = new(get_turf(worm))
	transfer(worm, new_worm)

	return ..()

/obj/structure/blood_worm_cocoon/hatchling
	name = "small blood cocoon"
	desc = "The incubation cocoon of a hatchling blood worm. Its surface is slowly shifting."

	max_integrity = 100
	damage_deflection = 10

/obj/structure/blood_worm_cocoon/hatchling/examine(mob/user)
	return ..() + span_warning("It can be broken to prevent the blood worm from maturing.")

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/juvenile
	name = "Mature"
	desc = "Enter incubation in a cocoon, emerging as an adult blood worm."
	cocoon_type = /obj/structure/blood_worm_cocoon/juvenile
	total_blood_required = 2500

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/juvenile/finalize(mob/living/basic/blood_worm/worm)
	var/mob/living/basic/blood_worm/adult/new_worm = new(get_turf(worm))
	transfer(worm, new_worm)

	return ..()

/obj/structure/blood_worm_cocoon/juvenile
	name = "blood cocoon"
	desc = "The incubation cocoon of a juvenile blood worm. Its surface is slowly shifting."

	max_integrity = 150
	damage_deflection = 15

/obj/structure/blood_worm_cocoon/juvenile/examine(mob/user)
	return ..() + span_warning("It can be broken to prevent the blood worm from maturing, but it looks rather tough.")

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/adult
	name = "Reproduce"
	desc = "Enter incubation in a cocoon, sacrificing your adult form to create 4 - 6 new hatchlings, including yourself."
	cocoon_type = /obj/structure/blood_worm_cocoon/juvenile
	total_blood_required = 2500

/datum/action/cooldown/mob_cooldown/blood_worm_cocoon/adult/finalize(mob/living/basic/blood_worm/worm)
	var/mob/living/basic/blood_worm/hatchling/new_worm = new(get_turf(worm))
	transfer(worm, new_worm)

	return ..()

/obj/structure/blood_worm_cocoon/adult
	name = "large blood cocoon"
	desc = "The incubation cocoon of an adult blood worm. You can see many faint shadows within."

	max_integrity = 200
	damage_deflection = 20

/obj/structure/blood_worm_cocoon/adult/examine(mob/user)
	return ..() + span_warning("It can be broken to prevent the blood worm from reproducing, but it looks extremely tough.")
