import kubejs.events.server.RecipesEvent;

class Recipes {
    public static function onEvent(event:RecipesEvent) {
        event.shaped(
            "flight_rings:t_basic_ring_treasure",
            [
                "S", "W", "S",
                "W", "R", "W",
                "F", "W", "F",
            ],
            {
                S: "terramine:mana_crystal",
                W: "minecraft:feather",
                R: "botania:pixie_ring",
                F: "create:encased_fan",
            }
        );
    }
}
