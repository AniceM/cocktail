extends Control

signal add_liquor(liquor: Liquor)
signal add_special_ingredient(ingredient: SpecialIngredient)
signal next_pressed
signal complete_pressed

const AddIngredientButtonScene = preload("uid://33qrbtnnfjbg")

@onready var _add_ingredient_list: VBoxContainer = %AddIngredientList
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _next_button: Button = %NextButton
@onready var _panel_title: Label = %PanelTitle

enum Mode {LIQUORS, SPECIAL_INGREDIENTS}

var mode: Mode = Mode.LIQUORS:
	set(value):
		# If the mode doesn't change, don't repopulate
		if value == mode:
			return
		mode = value
		if is_node_ready():
			match mode:
				Mode.LIQUORS:
					_populate_liquors()
				Mode.SPECIAL_INGREDIENTS:
					_populate_special_ingredients()

var _special_ingredient_group: ButtonGroup


func _ready() -> void:
	_next_button.pressed.connect(_on_next_button_pressed)
	_populate_liquors()


# --- Population ---

func _populate_liquors() -> void:
	Log.msg(self, "Populating liquors")
	_panel_title.text = "Liquors"
	_next_button.text = "Next"
	_next_button.disabled = true
	_special_ingredient_group = null
	_clear_list()

	for liquor in PlayerProgression.get_liquors():
		var button = AddIngredientButtonScene.instantiate()
		button.liquor = liquor
		button.pressed.connect(_on_add_liquor_button_pressed.bind(liquor))
		_add_ingredient_list.add_child(button)


func _populate_special_ingredients() -> void:
	Log.msg(self, "Populating special ingredients")
	_panel_title.text = "Special Ingredients"
	_next_button.text = "Complete"
	# Note: Button state is managed by parent scene based on conditions
	_clear_list()

	_special_ingredient_group = ButtonGroup.new()
	_special_ingredient_group.allow_unpress = true
	_special_ingredient_group.pressed.connect(_on_special_ingredient_group_pressed)

	for ingredient in PlayerProgression.get_special_ingredients():
		var button = AddIngredientButtonScene.instantiate()
		button.special_ingredient = ingredient
		button.toggle_mode = true
		button.button_group = _special_ingredient_group
		_add_ingredient_list.add_child(button)


func _clear_list() -> void:
	for child in _add_ingredient_list.get_children():
		child.queue_free()


# --- State ---

func set_next_button_enabled(enabled: bool) -> void:
	_next_button.disabled = !enabled


func set_disabled(disabled: bool = true) -> void:
	for child in _add_ingredient_list.get_children():
		if child is Button:
			child.disabled = disabled


func reset_scroll() -> void:
	_scroll_container.scroll_vertical = 0
	_scroll_container.scroll_horizontal = 0


# --- Callbacks ---

func _on_add_liquor_button_pressed(liquor: Liquor) -> void:
	add_liquor.emit(liquor)


func _on_special_ingredient_group_pressed(button: BaseButton) -> void:
	if button.button_pressed:
		add_special_ingredient.emit(button.special_ingredient)
	else:
		add_special_ingredient.emit(null)


func _on_next_button_pressed() -> void:
	match mode:
		Mode.LIQUORS:
			next_pressed.emit()
		Mode.SPECIAL_INGREDIENTS:
			complete_pressed.emit()
