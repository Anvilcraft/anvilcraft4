function recipes(ev) {
    ev.remove({output: "tempad:tempad"});

    // conflicts with copper nuggets
    ev.remove({output: "redstonebits:copper_button"});

    // this recipe makes alectrum out of copper. wtf.
    ev.remove({
        type: "create:mixing",
        output: "techreborn:electrum_ingot",
    });

    ev.custom({
        type: "create:mixing",
        ingredients: [
            Ingredient.of("#c:silver_ingots").toJson(),
            Ingredient.of("#c:gold_ingots").toJson(),
        ],
        results: [
            Item.of("techreborn:electrum_ingot", 2).toResultJson(),
        ],
        heatRequirement: "heated",
    });

    ev.shaped("redstonebits:copper_button", [
        "CC",
        "CC",
    ], {
        C: "#c:copper_ingots",
    });

    ev.shaped("tempad:tempad", [
        "GGG",
        "PCD",
        "GGG",
    ], {
        G: "#c:gold_ingots",
        P: "techreborn:data_storage_chip",
        C: "powah:ender_core",
        D: "techreborn:digital_display",
    });

    ev.shaped("tempad:he_who_remains_tempad", [
        "ITF",
        "NSN",
        "FRI",
    ], {
        N: "#c:netherite_ingots",
        T: "tempad:tempad",
        R: "blockus:legacy_nether_reactor_core",
        S: "minecraft:nether_star",
        I: "dimdoors:infrangible_fiber",
        F: "dimdoors:frayed_filament",
    });
}

onEvent("recipes", recipes);
