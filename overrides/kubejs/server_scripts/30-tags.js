/// IDs of all waystones.
const waystones = [
    "waystones:waystone",
    "waystones:desert_waystone",
    "waystones:red_desert_waystone",
    "waystones:stone_brick_waystone",
    "waystones:nether_brick_waystone",
    "waystones:red_nether_brick_waystone",
    "waystones:end_stone_brick_waystone",
    "waystones:deepslate_brick_waystone",
    "waystones:blackstone_brick_waystone",
];

function blockTags(ev) {
    // this allows players to activate other people's waystones
    ev.add("ftbchunks:interact_whitelist", waystones);
}

function addNuggetTags(ev, material, item) {
    ev.add(`c:${material}_nuggets`, item);
    ev.add(`c:nuggets/${material}`, item);
}

function itemTags(ev) {
    // ConsistencyPlus actually doesn't know how tags work
    addNuggetTags(ev, "copper", "consistency_plus:copper_nugget");
    addNuggetTags(ev, "netherite", "consistency_plus:netherite_nugget");
}

onEvent("tags.blocks", blockTags);
onEvent("tags.items", itemTags);
