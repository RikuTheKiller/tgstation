/datum/action/cooldown/blood_slime/enter
	name = "Enter Host"
	desc = "Choose something that you wish to blend into the environment as. Click on yourself to reset your appearance."
	button_icon_state = "sniper_zoom"
	check_flags = AB_CHECK_CONSCIOUS
	click_to_activate = TRUE

/datum/action/cooldown/blood_slime/enter/Activate(mob/living/carbon/target)
	. = ..()
	if(!istype(target))
		return
	if(target.stat != DEAD)
		target.balloon_alert(owner, "not dead!")
		return
	if(!do_after(owner, 2.5 SECONDS, target))
		return
	target.do_jitter_animation(1 SECONDS)
	blood_slime.enter_host(target)

