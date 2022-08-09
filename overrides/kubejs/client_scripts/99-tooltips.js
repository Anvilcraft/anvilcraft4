function itemTooltips(ev) {
    ev.add("ae2:spatial_anchor", Text.of("Broken on Fabric!").red());
}

onEvent("item.tooltip", itemTooltips);
