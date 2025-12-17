#define GET_TURF_LIQUID_HEIGHT(turf) (turf.liquid_group ? GET_GROUP_LIQUID_HEIGHT(turf.liquid_group) : 0)
#define GET_GROUP_LIQUID_HEIGHT(group) (group.reagents.total_volume / length(group.turfs))

#define LIQUID_HEIGHT_NONE 0
#define LIQUID_HEIGHT_SPREAD 20
#define LIQUID_HEIGHT_LOW 200
#define LIQUID_HEIGHT_MED 500
#define LIQUID_HEIGHT_HIGH 900
#define LIQUID_HEIGHT_FULL 1000
