// This is the base datum for material crafting recipes. Using CRAFT_APPLIES_MATS is expected, but technically not required.
// It's really simple, it just takes a valid material category and a number for how many of any valid sheet type it needs.

/datum/crafting_recipe/material
	abstract_type = /datum/crafting_recipe/material

	steps = list("Use different materials in hand to make an item of that material")

	/// How many sheets are required to make this.
	var/req_sheet_count = 0
	/// What category the material of a sheet must have to make this.
	/// Should be a [MAT_CATEGORY_X] define, and defaults to [MAT_CATEGORY_BASE_RECIPES].
	var/req_material_category = MAT_CATEGORY_BASE_RECIPES

/datum/crafting_recipe/material/New()
	reqs = list(/obj/item/stack/sheet = req_sheet_count)
	return ..()

/datum/crafting_recipe/material/filter_req_item_type(item_path, obj/item/stack/sheet/req_path)
	. = ..()
	if (!.)
		return

	var/material_type = req_path::material_type

	if (!material_type)
		return

	var/datum/material/material = GET_MATERIAL_REF(material_type)

	return material.categories[req_material_category]
