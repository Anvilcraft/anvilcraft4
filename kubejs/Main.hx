package;

import kubejs.Events;
import kubejs.Settings;

class Main {
    static function main() {
        Settings.logAddedRecipes = true;
        Settings.logErroringRecipes = true;
        Settings.logRemovedRecipes = true;
        Settings.logSkippedRecipes = false;

        Events.onEvent(EventType.RecipesEventType, Recipes.onEvent);
    }
}
