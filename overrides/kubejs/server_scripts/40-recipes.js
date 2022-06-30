function recipes(ev) {
    ev.shaped(
        "flight_rings:t_basic_ring_treasure",
        [
            "SWS",
            "WRW",
            "FWF",
        ],
        {
            S: "terramine:mana_crystal",
            W: "minecraft:feather",
            R: "botania:pixie_ring",
            F: "create:encased_fan",
        }
    );
}

onEvent("recipes", recipes);
