function recipes(ev) {
	ev.remove({output: "tempad:tempad"});

    // conflicts with copper nuggets
	ev.remove({output: "redstonebits:copper_button"});

    ev.shaped("redstonebits:copper_button", [
        "CC",
        "CC"
    ], {
        C: "#c:copper_ingots"
    });

	ev.shaped("tempad:tempad", [
		"GGG",
		"PCD",
		"GGG"
	], {
		G: "#c:gold_ingots",
		P: "modern_industrialization:processing_unit",
		C: "powah:ender_core",
		D: "techreborn:digital_display"
	});

	ev.shaped("tempad:he_who_remains_tempad", [
		"UTD",
		"NSN",
		"DRU"
	], {
		U: "dimdoors:unravelled_block", 
        N: "#c:netherite_ingots",
		D: "minecraft:deepslate",
		T: "tempad:tempad",
		R: "blockus:legacy_nether_reactor_core",
		S: "minecraft:nether_star"
	});
}

onEvent("recipes", recipes);
