extends Node
class_name CocktailMakingStateMachine

signal state_changed

enum StateName {
    START, # Initial state of the cocktail making scene (for animations & such)
    GLASS_SELECTION, # Select a glass to pour into
    LIQUOR_SELECTION, # Select liquors to pour
    SPECIAL_INGREDIENT_SELECTION, # Select special ingredients to add
    ADDING_INGREDIENT, # Adding ingredients (liquor or special ingredient)
    REVIEW, # Review the cocktail
    FINISHED # Finished making the cocktail
}

var current_state = StateName.START
var cocktail_making_scene: Node2D

func _init(scene: Node2D) -> void:
    self.cocktail_making_scene = scene

func change_state(new_state: StateName) -> void:
    if new_state == current_state:
        return
    # Remember the old state
    var old_state = current_state
    # Handle state change
    match new_state:
        StateName.START:
            pass
        StateName.GLASS_SELECTION:
            pass
        StateName.LIQUOR_SELECTION:
            pass
        StateName.SPECIAL_INGREDIENT_SELECTION:
            pass
        StateName.ADDING_INGREDIENT:
            # Disable input while adding ingredients
            pass
        StateName.REVIEW:
            pass
        StateName.FINISHED:
            pass
    # Update current state
    current_state = new_state    
    # Emit signal to notify change of state
    emit_signal("state_changed", old_state, new_state)

func handle_input(_event: InputEvent) -> void:
    match current_state:
        StateName.START:
            pass
        StateName.GLASS_SELECTION:
            pass
        StateName.LIQUOR_SELECTION:
            pass
        StateName.SPECIAL_INGREDIENT_SELECTION:
            pass
        StateName.REVIEW:
            pass
        StateName.FINISHED:
            pass