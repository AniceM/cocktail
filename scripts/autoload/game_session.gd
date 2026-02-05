extends Node
## Manages ephemeral session state during gameplay
## This holds temporary data that exists between scenes but is not saved

# Current session state (not saved, resets on game restart)
signal current_cocktail_changed(cocktail: Cocktail)
signal current_cocktail_updated(cocktail: Cocktail)

var current_cocktail: Cocktail = null
var current_character = null  # TODO: Type this when Character class exists
var current_chapter = null  # TODO: Type this when Chapter class exists

func set_current_cocktail(cocktail: Cocktail) -> void:
	if cocktail == current_cocktail:
		return
	current_cocktail = cocktail
	current_cocktail_changed.emit(current_cocktail)


func clear_current_cocktail() -> void:
	set_current_cocktail(null)


func notify_cocktail_updated() -> void:
	if current_cocktail == null:
		return
	current_cocktail_updated.emit(current_cocktail)


# Helper to reset session (called when starting new game or returning to menu)
func reset_session() -> void:
	clear_current_cocktail()
	current_character = null
	current_chapter = null
