/// Delete the organ if replaced
#define DELETE_IF_REPLACED (1<<0)
/// When deleting a brain, we don't delete the identity and the player can keep playing
#define NO_ID_TRANSFER (1<<1)
/// Used by /datum/component/cover_organ for determining whether it should automatically uncover the organ it's covering on removal, if any
#define UNCOVER_ORGAN (1<<2)
