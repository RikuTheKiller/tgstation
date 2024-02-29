/datum/action/cooldown/blood_slime/blood_barrage
	name = "Blood Barrage"
	desc = "Fire a continuous barrage of blood."
	cooldown_time = 10 SECONDS

	/// The barrage component this uses to make the blood slime able to shoot. Saved for later deletion.
	var/datum/component/ranged_mob_full_auto/blood_barrage/barrage

/datum/action/cooldown/blood_slime/blood_barrage/New(Target, original)
	barrage = new()

/datum/action/cooldown/blood_slime/blood_barrage/Grant(mob/grant_to, datum/antagonist/blood_slime/antag_override)
	. = ..()
	if (!.)
		return

	owner.AddComponent(
		/datum/component/ranged_attacks,
		projectile_type = /obj/projectile/blood_slime,
		projectile_sound = projectilesound,
		cooldown_time = ranged_cooldown,
		burst_shots = burst_shots
	)
	owner.AddComponent(/datum/component/ranged_mob_full_auto/blood_barrage, 0.2, src)

/datum/action/cooldown/blood_slime/blood_barrage/Remove(mob/removed_from)
	. = ..()

	QDEL_NULL(barrage)

/datum/component/ranged_mob_full_auto/blood_barrage

	/// The barrage action this is firing for. Used to keep track of cooldowns and give feedback to the player.
	var/datum/action/cooldown/blood_slime/blood_barrage/barrage

/datum/component/ranged_mob_full_auto/blood_barrage/Initialize(autofire_shot_delay, datum/action/cooldown/blood_slime/blood_barrage/barrage)
	. = ..()
	src.barrage = barrage

/datum/component/ranged_mob_full_auto/blood_barrage/on_mouse_down(client/source, atom/target, turf/location, control, params)
	var/mob/living/owner = barrage?.owner

	if (!istype(owner))
		return
	if (!barrage.IsAvailable(feedback = TRUE))
		return

	return ..()

/datum/component/ranged_mob_full_auto/blood_barrage/stop_firing()
	. = ..()
	barrage.StartCooldown()
