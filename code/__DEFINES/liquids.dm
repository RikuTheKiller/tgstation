#define LIQUID_HEIGHT_NONE 0
#define LIQUID_HEIGHT_SPREAD 20
#define LIQUID_HEIGHT_LOW 200
#define LIQUID_HEIGHT_MED 500
#define LIQUID_HEIGHT_HIGH 900
#define LIQUID_HEIGHT_FULL 1000

#define GET_LIQUID_GROUP_HEIGHT(group) (group.reagents.total_volume / length(group.turfs))
#define GET_LIQUID_GROUP_COLOR(group) mix_color_from_reagents(group.reagents.reagent_list)
#define GET_LIQUID_GROUP_ALPHA(group) min(round((255 * 0.4) + GET_LIQUID_GROUP_HEIGHT(group) / LIQUID_HEIGHT_HIGH * (255 * 0.5), 1), 230) // alpha 102-230 from height 0-900
#define GET_LIQUID_GROUP_SMOOTH(group) GET_LIQUID_GROUP_HEIGHT(group) < LIQUID_HEIGHT_LOW

#define GET_TURF_LIQUID_HEIGHT(turf) (turf.liquid_group ? GET_LIQUID_GROUP_HEIGHT(turf.liquid_group) : 0)
