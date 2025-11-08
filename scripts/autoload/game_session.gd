extends Node
## Manages ephemeral session state during gameplay
## This holds temporary data that exists between scenes but is not saved

# Current session state (not saved, resets on game restart)
var current_cocktail: Cocktail = null
var current_character = null  # TODO: Type this when Character class exists
var current_chapter = null  # TODO: Type this when Chapter class exists

# Helper to reset session (called when starting new game or returning to menu)
func reset_session() -> void:
	current_cocktail = null
	current_character = null
	current_chapter = null
