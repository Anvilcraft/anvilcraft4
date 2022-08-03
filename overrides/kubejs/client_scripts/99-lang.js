function lang(ev) {
    const addAll = langs => {
        for (kv of langs) {
            ev.addLang(kv[0], kv[1]);
        }
    };

    // Alectrolyzer
    addAll([
        [
            "advancements.modern_industrialization.electrolyzer.description",
            "Craft an Alectrolyzer",
        ],
        [
            "block.modern_industrialization.electrolyzer",
            "Alectrolyzer",
        ],
        [
            "block.techreborn.industrial_electrolyzer",
            "Industrial Alectrolyzer",
        ],
    ]);

    // Alectronic Circuit
    addAll([
        [
            "advancements.modern_industrialization.electronic_circuit.description",
            "Craft an Alectronic Circuit",
        ],
        [
            "item.modern_industrialization.electronic_circuit",
            "Alectronic Circuit",
        ],
        [
            "item.modern_industrialization.electronic_circuit_board",
            "Alectronic Circuit Board",
        ],
        [
            "item.techreborn.electronic_circuit",
            "Electronic Circuit",
        ],
    ]);

    // Alectrum
    addAll([
        // Modern Industrialization
        ["item.modern_industrialization.electrum_cable", "Alectrum Cable"],
        ["item.modern_industrialization.electrum_double_ingot", "Alectrum Double Ingot"],
        ["item.modern_industrialization.electrum_dust", "Alectrum Dust"],
        ["item.modern_industrialization.electrum_fine_wire", "Alectrum Fine Wire"],
        ["item.modern_industrialization.electrum_ingot", "Alectrum Ingot"],
        ["item.modern_industrialization.electrum_nugget", "Alectrum Nugget"],
        ["item.modern_industrialization.electrum_plate", "Alectrum Plate"],
        ["item.modern_industrialization.electrum_tiny_dust", "Alectrum Tiny Dust"],
        ["item.modern_industrialization.electrum_wire", "Alectrum Wire"],

        // Industrial Revolution
        ["block.indrev.electrum_block", "Block of Alectrum"],
        ["item.indrev.electrum_ingot", "Alectrum Ingot"],
        ["item.indrev.electrum_dust", "Alectrum Dust"],
        ["item.indrev.electrum_plate", "Alectrum Plate"],
        ["item.indrev.electrum_gear", "Alectrum Gear"],
        ["item.indrev.electrum_nugget", "Alectrum Nugget"],

        // Tech Reborn
        ["block.techreborn.electrum_storage_block", "Block of Alectrum"],
        ["block.techreborn.electrum_storage_block_stairs", "Alectrum Stairs"],
        ["block.techreborn.electrum_storage_block_slab", "Alectrum Slab"],
        ["block.techreborn.electrum_storage_block_wall", "Alectrum Wall"],
        ["item.techreborn.electrum_dust", "Alectrum Dust"],
        ["item.techreborn.electrum_small_dust", "Small Pile of Alectrum Dust"],
        ["item.techreborn.electrum_ingot", "Alectrum Ingot"],
        ["item.techreborn.electrum_nugget", "Alectrum Nugget"],
        ["item.techreborn.electrum_plate", "Alectrum Plate"],
    ]);

    // Alectrolytic Separator
    addAll([
        ["block.indrev.electrolytic_separator", "Alectrolytic Separator"],
        ["block.indrev.electrolytic_separator_mk1", "Alectrolytic Separator MK1"],
        ["block.indrev.electrolytic_separator_mk2", "Alectrolytic Separator MK2"],
        ["block.indrev.electrolytic_separator_mk3", "Alectrolytic Separator MK3"],
        ["block.indrev.electrolytic_separator_mk4", "Alectrolytic Separator MK4"],
        ["block.indrev.electrolytic_separator_creative", "Alectrolytic Separator Creative"],
    ]);

    // Alectric Furnace
    addAll([
        // Tech Reborn
        ["block.techreborn.electric_furnace", "Alectric Furnace"],

        // Industrial Revolution
        ["block.indrev.electric_furnace", "Alectric Furnace"],
        ["block.indrev.electric_furnace_mk1", "Alectric Furnace MK1"],
        ["block.indrev.electric_furnace_mk2", "Alectric Furnace MK2"],
        ["block.indrev.electric_furnace_mk3", "Alectric Furnace MK3"],
        ["block.indrev.electric_furnace_mk4", "Alectric Furnace MK4"],
        ["block.indrev.electric_furnace_creative", "Alectric Furnace Creative"],
        ["block.indrev.electric_furnace_factory", "Alectric Furnace Factory"],
        ["block.indrev.electric_furnace_factory_mk4", "Alectric Furnace Factory MK4"],
    ]);
}

onEvent("client.generate_assets", lang);
