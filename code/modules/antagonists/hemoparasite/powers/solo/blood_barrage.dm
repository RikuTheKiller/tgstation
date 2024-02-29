/datum/action/cooldown/hemoparasite/blood_barrage
	name = "Blood Barrage"
	desc = "Continuously turn yourself into infectious payloads to hurl at your (unfortunate) target."
	cooldown_time = 10 SECONDS

	/// The ranged attack component used alongside the autofire component. Saved for later deletion.
	var/datum/component/ranged_attacks/attack

	/// The autofire component this uses to make the hemoparasite able to shoot. Saved for later deletion.
	var/datum/component/ranged_mob_full_auto/blood_barrage/autofire

/datum/action/cooldown/hemoparasite/blood_barrage/New(Target, original)
	barrage = new()

/datum/action/cooldown/hemoparasite/blood_barrage/Grant(mob/grant_to, datum/antagonist/hemoparasite/antag_override)
	. = ..()
	if (!.)
		return

	owner.AddComponent(
		/datum/component/ranged_attacks,
		projectile_type = /obj/projectile/hemoparasite,
		projectile_sound = projectilesound,
		cooldown_time = ranged_cooldown,
		burst_shots = burst_shots
	)
	autofire = owner.AddComponent(/datum/component/ranged_mob_full_auto/blood_barrage, 0.2, src)

/datum/action/cooldown/hemoparasite/blood_barrage/Remove(mob/removed_from)
	. = ..()

	qdel(autofire)

/datum/component/ranged_mob_full_auto/blood_barrage

	/// The barrage action this is firing for. Used to keep track of cooldowns and give feedback to the player.
	var/datum/action/cooldown/hemoparasite/blood_barrage/barrage

/datum/component/ranged_mob_full_auto/blood_barrage/Initialize(autofire_shot_delay, datum/action/cooldown/hemoparasite/blood_barrage/barrage)
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
