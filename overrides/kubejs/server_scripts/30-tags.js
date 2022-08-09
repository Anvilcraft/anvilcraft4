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

const ores_with_missing_tags = {
    iron: ["archon:cloud_iron"],
    quartz: [
        "byg:blue_nether_quartz_ore",
        "byg:brimstone_nether_quartz_ore",
    ],
    lapis: ["betternether:nether_lapis_ore"],
    redstone: ["betternether:nether_redstone_ore"],
};

function blockTags(ev) {
    // this allows players to activate other people's waystones
    ev.add("ftbchunks:interact_whitelist", waystones);

    for (let [tag, ores] of Object.entries(ores_with_missing_tags)) {
        for (ore of ores) {
            ev.add(`c:${tag}_ores`, ore);
            ev.add(`c:ores/${tag}`, ore);
        }
    }
}

function addNuggetTags(ev, material, item) {
    ev.add(`c:${material}_nuggets`, item);
    ev.add(`c:nuggets/${material}`, item);
}

function itemTags(ev) {
    // ConsistencyPlus actually doesn't know how tags work
    addNuggetTags(ev, "copper", "consistency_plus:copper_nugget");
    addNuggetTags(ev, "netherite", "consistency_plus:netherite_nugget");

    for (let [tag, ores] of Object.entries(ores_with_missing_tags)) {
        for (ore of ores) {
            ev.add(`c:${tag}_ores`, ore);
            ev.add(`c:ores/${tag}`, ore);
        }
    }
}

onEvent("tags.blocks", blockTags);
onEvent("tags.items", itemTags);
