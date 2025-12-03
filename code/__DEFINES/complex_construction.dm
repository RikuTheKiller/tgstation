// Construction step reqs list indices
#define CONSTRUCTION_REQ_ITEM_TYPE "required item type"
#define CONSTRUCTION_REQ_ITEM_AMOUNT "required item amount"
#define CONSTRUCTION_REQ_TOOL_BEHAVIOUR "required tool behaviour"

// Construction flags
// If it's implicit (e.g. fingerprints) then the flag should negate it, and vice versa

/// This step doesn't leave fingerprints on the target, tool or results
#define CONSTRUCTION_NO_FINGERPRINTS (1 << 0)
/// This step can be modified by construction speed modifiers.
/// This is for things that progress towards a structure of some kind. (e.g. plating a girder)
#define CONSTRUCTION_APPLY_SPEED_MODS (1 << 1)

// Mutually exclusive target handling types

/// Target handling type.
/// This step deletes the target. (e.g. wall creation)
/// This usually doesn't drop anything.
#define CONSTRUCTION_DELETE_TARGET 1
/// Target handling type.
/// This step roughly destroys the target. (e.g. bashing with a hammer)
/// This usually drops stuff like shards for windows.
#define CONSTRUCTION_DESTROY_TARGET 2
/// Target handling type.
/// This step cleanly disassembles the target. (e.g. using a screwdriver)
/// This usually drops the original item or its components.
#define CONSTRUCTION_DISASSEMBLE_TARGET 3
