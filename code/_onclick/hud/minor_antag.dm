/atom/movable/screen/hemoparasite
	icon = 'icons/hud/screen_minorantag.dmi'

/atom/movable/screen/hemoparasite/blood //todo implement progressbar sprites
	name = "blood status"
	icon_state = "bloodmeter"
	screen_loc = ui_lingchemdisplay
	maptext_width = 64
	/// The overlay for the progress bar esque thingamabob. Handled by the antag datum
	var/mutable_appearance/progress_overlay

/atom/movable/screen/hemoparasite/blood/Destroy()
	. = ..()
	QDEL_NULL(progress_overlay)
