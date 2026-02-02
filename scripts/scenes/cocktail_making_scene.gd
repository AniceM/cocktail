extends Node2D

# Visuals
@onready var camera: Camera2D = %Camera2D
@onready var glass_scene: Node2D = %GlassScene

# Data
var cocktail: Cocktail

# State Machine
var state_machine: CocktailMakingStateMachine

# Animation
var _glass_tween: Tween
var _menu_tween: Tween
var _camera_tween: Tween
var _chart_tween: Tween
const GLASS_BASE_SCALE := Vector2(0.3, 0.3) # Match scene default
const MENU_SLIDE_OFFSET := 200.0 # Pixels to slide from
const MENU_TRANSITION_DURATION := 0.35
const CAMERA_ZOOM_GLASS_SELECTION := Vector2(1.8, 1.8)
const CAMERA_ZOOM_LIQUOR_SELECTION := Vector2(2.0, 2.0)
const CAMERA_ZOOM_DURATION := 0.5

# UI
@onready var glass_selection_menu: Control = %GlassSelectionMenu
@onready var glass_selection_button: Button = %GlassSelectionButton
@onready var add_ingredients_menu: Control = %AddIngredientsMenu
@onready var flavor_profile_chart: Control = %FlavorProfileChart
@onready var reset_button: Button = %ResetButton
@onready var mix_button: Button = %MixButton
@onready var signature_badges: Control = %SignatureBadgesContainer

# Debug
@onready var debug_label: RichTextLabel = %DebugLabel

func _ready() -> void:
	# Hide the glass until one is selected
	glass_scene.visible = false
	# Hide buttons that shouldn't be visible at start
	glass_selection_button.visible = false
	reset_button.visible = false
	mix_button.visible = false
	# Hide flavor chart until liquor selection
	flavor_profile_chart.visible = false

	# Connect signals
	glass_scene.animation_started.connect(_on_glass_animation_started)
	glass_scene.animation_finished.connect(_on_glass_animation_finished)
	glass_selection_menu.glass_selected.connect(_on_glass_selected)
	glass_selection_button.pressed.connect(_on_glass_selection_button_pressed)
	add_ingredients_menu.add_liquor.connect(_on_add_liquor)
	reset_button.pressed.connect(_on_reset_button_pressed)
	mix_button.pressed.connect(_on_mix_button_pressed)

	# Create State Machine
	state_machine = CocktailMakingStateMachine.new(self)
	state_machine.state_changed.connect(_on_state_changed)

	# Start the flow
	state_machine.change_state(CocktailMakingStateMachine.StateName.GLASS_SELECTION)

	# Animate camera zoom from 1 to 2
	# var tween = create_tween()
	camera.zoom = Vector2(1, 1)
	# tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0)

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
		debug_label.text += "[color=#AAAAAA]Liquors Poured:[/color] [color=#FFFF00]%s[/color] / %s\n" % [cocktail.liquors_poured, cocktail.glass.capacity]
		debug_label.text += "[color=#AAAAAA]Layers:[/color] [color=#FFFF00]%s[/color]\n" % cocktail.layers.size()

		# Layer breakdown
		if cocktail.layers.size() > 0:
			debug_label.text += "\n[color=#AAAAAA]Layer Breakdown:[/color]\n"
			for i in range(cocktail.layers.size()):
				var layer = cocktail.layers[i]
				var dominant = layer.flavor_stats.get_dominant_flavor()
				var dominant_value = layer.flavor_stats.get_value(dominant) if dominant else 0
				var layer_color_hex = layer.color.to_html(false)
				var color_names_enums = ColorUtils.get_matching_color_names(layer.color)
				var color_names_str = "/".join(color_names_enums.map(func(e): return ColorUtils.ColorName.keys()[e]))

				debug_label.text += "  [bgcolor=#%s]   [/bgcolor] " % layer_color_hex
				debug_label.text += "[color=#CCCCCC]Layer %d:[/color] " % (i + 1)
				if dominant:
					debug_label.text += "[color=#00FF88]%s[/color] (%d) " % [dominant.name, dominant_value]
				debug_label.text += "[color=#888888]%s[/color]\n" % color_names_str

			# Layer colors sequence
			debug_label.text += "\n[color=#AAAAAA]Color Sequence:[/color] "
			for i in range(cocktail.layers.size()):
				var layer = cocktail.layers[i]
				var color_names_enums = ColorUtils.get_matching_color_names(layer.color)
				var color_names_str = "/".join(color_names_enums.map(func(e): return ColorUtils.ColorName.keys()[e]))
				var layer_color_hex = layer.color.to_html(false)
				debug_label.text += "[bgcolor=#%s][color=#000000] %s [/color][/bgcolor]" % [layer_color_hex, color_names_str]
				if i < cocktail.layers.size() - 1:
					debug_label.text += " → "
			debug_label.text += "\n"

		debug_label.text += "\n[color=#AAAAAA]Total Flavor Stats:[/color]\n"
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

# Route unhandled input event to the state machine
# Probably not needed at first (control nodes will handle events themselves),
# But I might need this for controller support
func _unhandled_input(event: InputEvent) -> void:
	state_machine.handle_input(event)

# Block / Unlock interactivity while animations are running
func _on_glass_animation_started() -> void:
	state_machine.change_state(CocktailMakingStateMachine.StateName.ADDING_INGREDIENT)

func _on_glass_animation_finished() -> void:
	state_machine.change_state(CocktailMakingStateMachine.StateName.LIQUOR_SELECTION)

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
		_update_mix_button()

		# Check if glass is full - detect and show signatures
		if cocktail.liquors_poured == cocktail.glass.capacity:
			cocktail.detect_signatures()
			signature_badges.show_signatures(cocktail.signatures)

func _on_reset_button_pressed() -> void:
	cocktail.reset()
	glass_scene.reset()
	flavor_profile_chart.reset()
	signature_badges.hide_signatures()
	_update_mix_button()

func _on_mix_button_pressed() -> void:
	var success = cocktail.mix()

	if success:
		# Update UI
		glass_scene.mix(true)
		_update_mix_button()

		# Re-detect signatures if glass is full (mixing changes layer structure)
		if cocktail.liquors_poured == cocktail.glass.capacity:
			cocktail.detect_signatures()
			signature_badges.show_signatures(cocktail.signatures)


func _update_mix_button() -> void:
	mix_button.disabled = cocktail == null or cocktail.layers.size() <= 1


func _on_glass_selected(glass: GlassType) -> void:
	# Create Cocktail object with selected glass
	cocktail = Cocktail.new(glass)
	glass_scene.set_glass(glass)
	# Animate glass appearing
	_animate_glass_in()
	# Transition to liquor selection
	state_machine.change_state(CocktailMakingStateMachine.StateName.LIQUOR_SELECTION)


func _on_glass_selection_button_pressed() -> void:
	# Reset current cocktail
	cocktail = null
	GameSession.current_cocktail = null
	# Reset visuals
	flavor_profile_chart.reset()
	signature_badges.hide_signatures()
	# Animate glass disappearing, then reset and return to glass selection
	_animate_glass_out(func():
		glass_scene.reset()
		state_machine.change_state(CocktailMakingStateMachine.StateName.GLASS_SELECTION)
	)


func _animate_glass_in() -> void:
	if _glass_tween:
		_glass_tween.kill()
	glass_scene.scale = Vector2.ZERO
	glass_scene.visible = true
	_glass_tween = create_tween()
	_glass_tween.tween_property(glass_scene, "scale", GLASS_BASE_SCALE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _animate_glass_out(on_complete: Callable = Callable()) -> void:
	if _glass_tween:
		_glass_tween.kill()
	_glass_tween = create_tween()
	_glass_tween.tween_property(glass_scene, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_glass_tween.tween_callback(func():
		glass_scene.visible = false
		glass_scene.scale = GLASS_BASE_SCALE
		if on_complete.is_valid():
			on_complete.call()
	)


func _on_state_changed(old_state: CocktailMakingStateMachine.StateName, new_state: CocktailMakingStateMachine.StateName) -> void:
	# Update UI visibility based on state
	match new_state:
		CocktailMakingStateMachine.StateName.GLASS_SELECTION:
			glass_selection_button.visible = false
			reset_button.visible = false
			mix_button.visible = false
			_animate_camera_zoom(CAMERA_ZOOM_GLASS_SELECTION)
			if old_state != CocktailMakingStateMachine.StateName.START:
				_transition_menus(glass_selection_menu, add_ingredients_menu)
				_animate_chart_out()
			else:
				_transition_menus(glass_selection_menu, null)
			# Defer to ensure buttons are populated on first run
			glass_selection_menu.animate_buttons_in.call_deferred()
		CocktailMakingStateMachine.StateName.LIQUOR_SELECTION:
			glass_selection_button.visible = true
			reset_button.visible = true
			mix_button.visible = true
			_animate_camera_zoom(CAMERA_ZOOM_LIQUOR_SELECTION)
			# Only transition menus when coming from glass selection, not from adding ingredient
			if old_state == CocktailMakingStateMachine.StateName.GLASS_SELECTION:
				_transition_menus(add_ingredients_menu, glass_selection_menu)
				_animate_chart_in()
			elif old_state == CocktailMakingStateMachine.StateName.ADDING_INGREDIENT:
				add_ingredients_menu.set_disabled(false)
		CocktailMakingStateMachine.StateName.ADDING_INGREDIENT:
			add_ingredients_menu.set_disabled(true)


func _animate_camera_zoom(target_zoom: Vector2) -> void:
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "zoom", target_zoom, CAMERA_ZOOM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _animate_chart_in() -> void:
	if _chart_tween:
		_chart_tween.kill()
	var base_x := flavor_profile_chart.position.x
	flavor_profile_chart.position.x = base_x - MENU_SLIDE_OFFSET
	flavor_profile_chart.modulate.a = 0.0
	flavor_profile_chart.visible = true
	_chart_tween = create_tween()
	_chart_tween.set_parallel(true)
	_chart_tween.tween_property(flavor_profile_chart, "position:x", base_x, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_chart_tween.tween_property(flavor_profile_chart, "modulate:a", 1.0, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _animate_chart_out() -> void:
	if _chart_tween:
		_chart_tween.kill()
	var base_x := flavor_profile_chart.position.x
	var target_x := base_x - MENU_SLIDE_OFFSET
	_chart_tween = create_tween()
	_chart_tween.set_parallel(true)
	_chart_tween.tween_property(flavor_profile_chart, "position:x", target_x, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_chart_tween.tween_property(flavor_profile_chart, "modulate:a", 0.0, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_chart_tween.chain().tween_callback(func():
		flavor_profile_chart.visible = false
		flavor_profile_chart.position.x = base_x
		flavor_profile_chart.modulate.a = 1.0
	)


func _transition_menus(menu_in: Control, menu_out: Control) -> void:
	if _menu_tween:
		_menu_tween.kill()
	_menu_tween = create_tween()
	_menu_tween.set_parallel(true)

	# Animate menu out (slide right + fade out)
	if menu_out and menu_out.visible:
		if menu_out.has_method("set_disabled"):
			menu_out.set_disabled(true)
		var out_target_x := menu_out.position.x + MENU_SLIDE_OFFSET
		_menu_tween.tween_property(menu_out, "position:x", out_target_x, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_menu_tween.tween_property(menu_out, "modulate:a", 0.0, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Animate menu in (slide from right + fade in)
	if menu_in:
		if menu_in.has_method("set_disabled"):
			menu_in.set_disabled(true)
		if menu_in.has_method("reset_scroll"):
			menu_in.reset_scroll()
		var in_base_x := menu_in.position.x
		menu_in.position.x = in_base_x + MENU_SLIDE_OFFSET
		menu_in.modulate.a = 0.0
		menu_in.visible = true
		_menu_tween.tween_property(menu_in, "position:x", in_base_x, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_menu_tween.tween_property(menu_in, "modulate:a", 1.0, MENU_TRANSITION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# After animation completes: hide menu_out, restore input on menu_in
	_menu_tween.chain().tween_callback(func():
		if menu_out:
			menu_out.visible = false
			menu_out.position.x -= MENU_SLIDE_OFFSET
			menu_out.modulate.a = 1.0
		if menu_in and menu_in.has_method("set_disabled"):
			menu_in.set_disabled(false)
	)
