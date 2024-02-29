/datum/action/cooldown/hemoparasite/enter
	name = "Enter Body"
	desc = "Enter the target's body, turning them into your host."
	button_icon_state = "blood_enter"
	click_to_activate = TRUE

/datum/action/cooldown/hemoparasite/enter/IsAvailable(feedback = FALSE)
	return ..() && !hemoparasite?.host

/datum/action/cooldown/hemoparasite/enter/Activate(mob/living/carbon/human/target)
	. = ..()

	if (!istype(target))
		return

	if (!owner.Adjacent(target))
		target.balloon_alert(owner, "out of range!")
		return

	if (target.stat != DEAD)
		target.balloon_alert(owner, "not dead!")
		return

	if (hemoparasite.get_host_max_blood(target) <= 0)
		target.balloon_alert(owner, "bloodless!")
		return

	. = TRUE // accidentally smacking a viable host is bad

	owner.visible_message(
		message = span_danger("\The [owner] begins to enter [target]'s body!"),
		self_message = span_notice("You begin to enter [target]'s body.")
	)

	if (!do_after(owner, 2 SECONDS, target))
		return

	owner.visible_message(
		message = span_danger("\The [owner] enters [target]'s body!"),
		self_message = span_notice("You enter [target]'s body.")
	)

	target.do_jitter_animation(10) // fluff

	playsound(owner, 'sound/effects/blobattack.ogg', 50, TRUE)

	hemoparasite.enter_host(target) // actually enter the host

