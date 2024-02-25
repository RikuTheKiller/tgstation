/datum/action/cooldown/blood_slime/enter
	name = "Enter Host"
	desc = "Enter the target corpse, turning them into your host."
	click_to_activate = TRUE

/datum/action/cooldown/blood_slime/enter/IsAvailable(feedback = FALSE)
	return ..() && !blood_slime?.current_host

/datum/action/cooldown/blood_slime/enter/Activate(mob/living/carbon/human/target)
	. = ..()

	if (!istype(target))
		return

	if (target.stat != DEAD)
		target.balloon_alert(owner, "not dead!")
		return

	if (blood_slime.get_host_max_blood(target) <= 0)
		target.balloon_alert(owner, "bloodless!")
		return

	. = TRUE // accidentally smacking a viable host is bad

	owner.visible_message(
		message = span_danger("\The [owner] begins to enter [target]!"),
		self_message = span_notice("You begin to enter [target]."),
	)

	if (!do_after(owner, 2 SECONDS, target))
		return

	target.do_jitter_animation(10) // fluff

	blood_slime.enter_host(target) // actually enter the host

