extends Node2D

# Visuals
@onready var camera: Camera2D = %Camera2D
@onready var glass_scene: Node2D = %GlassScene

# Data
var cocktail: Cocktail

# State Machine
var state_machine: CocktailMakingStateMachine

# UI
@onready var add_ingredients_menu: Control = %AddIngredientsMenu
@onready var flavor_profile_chart: Control = %FlavorProfileChart
@onready var reset_button: Button = %ResetButton
@onready var mix_button: Button = %MixButton

# Debug
@onready var debug_label: RichTextLabel = %DebugLabel

func _ready() -> void:
	# Connect signals
	glass_scene.animation_started.connect(_on_glass_animation_started)
	glass_scene.animation_finished.connect(_on_glass_animation_finished)
	add_ingredients_menu.add_liquor.connect(_on_add_liquor)
	reset_button.pressed.connect(_on_reset_button_pressed)
	mix_button.pressed.connect(_on_mix_button_pressed)

	# Create State Machine
	state_machine = CocktailMakingStateMachine.new(self)
	# TODO: (temporary) Immediately switch to LIQUOR_SELECTION
	state_machine.change_state(CocktailMakingStateMachine.StateName.LIQUOR_SELECTION)

	# Create Cocktail object
	cocktail = Cocktail.new(GameDataRegistry.get_glass("Chronos Coupe"))

	# Animate camera zoom from 1 to 2
	var tween = create_tween()
	camera.zoom = Vector2(1, 1)
	tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0)

func _process(_delta: float) -> void:
	update_debug_info()

func update_debug_info() -> void:
	debug_label.text = ""
	if state_machine:
		debug_label.text += "[color=#00FFFF][b][u]State Machine[/u][/b][/color]\n"
		debug_label.text += "[color=#AAAAAA]State:[/color] %s\n" % CocktailMakingStateMachine.StateName.keys()[state_machine.current_state]
		debug_label.text += "\n"
	if cocktail:
		debug_label.text += "[color=#00FFFF][b][u]Cocktail[/u][/b][/color]\n"
		debug_label.text += "[color=#AAAAAA]Glass:[/color] %s\n" % cocktail.glass.name
		debug_label.text += "[color=#AAAAAA]Capacity:[/color] %s / %s\n" % [cocktail.get_total_liquor_count(), cocktail.glass.capacity]

		debug_label.text += "[color=#AAAAAA]Flavor Stats:[/color]\n"
		for flavor in cocktail.flavor_stats.stats:
			var value = cocktail.flavor_stats.get_value(flavor)
			if value != 0:
				var color = "#00FF00" if value > 0 else "#FF0000"
				debug_label.text += "  [color=%s]%s: %+d[/color]\n" % [color, flavor.name, value]

		debug_label.text += "\n[color=#AAAAAA]Secret Reveal Rates:[/color]\n"
		for secret_type in SecretTypeRegistry.get_all_secret_types():
			var reveal_rate = cocktail.get_reveal_rate(secret_type)
			if reveal_rate > 0:
				debug_label.text += "  [color=#FFAA00]%s: %.0f%%[/color]\n" % [secret_type.name, reveal_rate * 100]

		debug_label.text += "\n"
	if glass_scene:
		debug_label.text += "[color=#00FFFF][b][u]Glass Scene[/u][/b][/color]\n"
		debug_label.text += "[color=#AAAAAA]Liquid Amount:[/color] %s / %s\n" % [glass_scene.liquid_amount, glass_scene.glass_max_liquids]
		debug_label.text += "\n"

# Route unhandled input event to the state machine
# Probably not needed at first (control nodes will handle events themselves),
# But I might need this for controller support
func _unhandled_input(event: InputEvent) -> void:
	state_machine.handle_input(event)

# Block / Unlock interactivity while animations are running
func _on_glass_animation_started() -> void:
	state_machine.change_state(CocktailMakingStateMachine.StateName.ADDING_INGREDIENT)
	add_ingredients_menu.set_disabled(true)

func _on_glass_animation_finished() -> void:
	state_machine.change_state(CocktailMakingStateMachine.StateName.LIQUOR_SELECTION)
	add_ingredients_menu.set_disabled(false)

# Add a liquor to the cocktail
func _on_add_liquor(liquor: Liquor) -> void:
	var result = cocktail.add_liquor(liquor)
	var success = result[0]
	var is_new_layer = result[1]
	# Update data
	if success:
		# Update UI
		glass_scene.add_liquid(liquor.color, is_new_layer, true)
		flavor_profile_chart.update_flavor_profile(cocktail.flavor_stats, true)

func _on_reset_button_pressed() -> void:
	cocktail.reset()
	glass_scene.reset()
	flavor_profile_chart.reset()

func _on_mix_button_pressed() -> void:
	cocktail.mix()
	glass_scene.mix(true)
