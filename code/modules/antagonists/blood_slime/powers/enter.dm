/datum/action/cooldown/blood_slime/enter
	name = "Enter Body"
	desc = "Enter the target's body, turning them into your host."
	click_to_activate = TRUE

/datum/action/cooldown/blood_slime/enter/IsAvailable(feedback = FALSE)
	return ..() && !blood_slime?.current_host

/datum/action/cooldown/blood_slime/enter/Activate(mob/living/carbon/human/target)
	. = ..()

	if (!istype(target))
		return

	if (!owner.Adjacent(target))
		target.balloon_alert(owner, "out of range!")
		return

	if (target.stat != DEAD)
		target.balloon_alert(owner, "not dead!")
		return

	if (target.dna.species.exotic_blood)
		target.balloon_alert(owner, "incompatible blood!")
		return

	if (blood_slime.get_host_max_blood(target) <= 0)
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
		self_message = span_notice("You begin to enter [target]'s body.")
	)

	target.do_jitter_animation(10) // fluff

	playsound(owner, 'sound/effects/blobattack.ogg', 50, TRUE)

	blood_slime.enter_host(target) // actually enter the host

