extends Control

const SlotScene := preload("uid://c3a3kdlv05adm")

@onready var _slot_container: HBoxContainer = %HBoxContainer


func _ready() -> void:
	GameSession.current_cocktail_changed.connect(_on_cocktail_changed)
	GameSession.current_cocktail_updated.connect(_on_cocktail_updated)


func _on_cocktail_changed(cocktail: Cocktail) -> void:
	_clear_slots()
	if cocktail == null:
		return
	for i in cocktail.glass.capacity:
		var slot := SlotScene.instantiate()
		_slot_container.add_child(slot)


func _on_cocktail_updated(cocktail: Cocktail) -> void:
	if cocktail == null:
		return
	var slot_colors: Array[Color] = []
	for layer in cocktail.layers:
		for liquor in layer.liquors:
			slot_colors.append(layer.color)
	var slots := _slot_container.get_children()
	for i in slots.size():
		if i < slot_colors.size():
			if slots[i].current_color != slot_colors[i]:
				slots[i].set_slot_color(slot_colors[i])
		else:
			if slots[i].current_color != slots[i].DEFAULT_COLOR:
				slots[i].reset_slot()


func _clear_slots() -> void:
	for child in _slot_container.get_children():
		child.queue_free()
