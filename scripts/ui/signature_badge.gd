extends Control

# ============================================================================
# Visuals & References
# ============================================================================
@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = %Label

# ============================================================================
# Badge State
# ============================================================================
@export var signature: Signature # The signature resource this badge represents
@export var locked_texture: Texture2D = preload("res://assets/ui/signature_badges/signature_badge_gray.png")
@export var unlocked_texture: Texture2D = preload("res://assets/ui/signature_badges/signature_badge_gold.png")

var is_unlocked: bool = false

# ============================================================================
# Animation State
# ============================================================================
var unlock_tween: Tween
var hover_tween: Tween
var original_scale: Vector2

# ============================================================================
# Lifecycle
# ============================================================================

func _ready() -> void:
	# Store original scale from scene
	original_scale = texture_rect.scale

	# Set pivot to center for hover scaling
	var texture_size = texture_rect.texture.get_size()
	texture_rect.pivot_offset = texture_size / 2.0

	# Connect mouse signals for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update UI based on current signature and player progression
	_update_ui()


func set_signature(sig: Signature) -> void:
	"""Set the signature resource for this badge."""
	signature = sig
	if not signature:
		push_error("SignatureBadge: set_signature called with null signature resource")
		return

	# Update UI to reflect the new signature's unlock state
	_update_ui()


# ============================================================================
# UI Update
# ============================================================================

func _update_ui() -> void:
	"""Update the badge appearance based on signature unlock status."""
	label.hide()

	# This case should not happen, but just in case
	if not signature:
		_set_locked()
		label.text = "???"
		return

	# Make label settings unique, else they will all have the color
	# TODO: Save the 2 Label Settings needed as resource, and load them
	label.label_settings = label.label_settings.duplicate()

	# Check if this signature has been unlocked by the player
	if PlayerProgression.is_signature_unlocked(signature):
		_set_unlocked()
		label.label_settings.font_color = "#f9c040"
		label.text = signature.name
	else:
		_set_locked()
		label.label_settings.font_color = "#42a3c3"
		label.text = "???"


# ============================================================================
# Internal State Setters
# ============================================================================

func _set_locked() -> void:
	"""Set the badge to locked state (gray) without animation."""
	is_unlocked = false
	texture_rect.texture = locked_texture


func _set_unlocked() -> void:
	"""Set the badge to unlocked state (gold) without animation."""
	is_unlocked = true
	texture_rect.texture = unlocked_texture


# ============================================================================
# Public API - For manual unlock animations (e.g., when unlocked during gameplay)
# ============================================================================

func unlock_with_animation() -> void:
	"""Unlock the badge with animation. Call this when the signature is unlocked during gameplay."""
	if is_unlocked:
		return # Already unlocked

	is_unlocked = true
	_animate_unlock()


# ============================================================================
# Animation
# ============================================================================

func _animate_unlock() -> void:
	"""Animate the transition from locked to unlocked state."""
	# Kill any existing unlock animation
	if unlock_tween:
		unlock_tween.kill()

	# Switch texture immediately
	texture_rect.texture = unlocked_texture

	# Create animation sequence
	unlock_tween = create_tween()

	# Pulse effect: scale up slightly then back to normal
	unlock_tween.tween_property(texture_rect, "scale", original_scale * 1.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	unlock_tween.tween_property(texture_rect, "scale", original_scale, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Optional: Add a brief glow or rotation effect here
	# unlock_tween.parallel().tween_property(texture_rect, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	# unlock_tween.tween_property(texture_rect, "modulate", Color.WHITE, 0.25)


func play_glow(_is_unlocked_glow: bool) -> void:
	"""Play glow effect after badge entrance. Shader implementation pending."""
	# TODO: Implement glow shader
	# is_unlocked_glow = true: gold/warm glow for unlocked badges
	# is_unlocked_glow = false: blue/mysterious glow for locked badges
	pass


# ============================================================================
# Hover Effects
# ============================================================================

func _on_mouse_entered() -> void:
	"""Scale up the badge on hover."""
	z_index = 1 # Draw on top of other badges
	label.show()
	label.modulate.a = 0
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_parallel()
	hover_tween.tween_property(texture_rect, "scale", original_scale * 1.2, 0.2) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(label, "modulate:a", 1.0, 0.2) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	"""Return badge to normal scale."""
	z_index = 0
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween().set_parallel()
	hover_tween.tween_property(texture_rect, "scale", original_scale, 0.1) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	hover_tween.tween_property(label, "modulate:a", 0.0, 0.1) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	hover_tween.finished.connect(func():
		label.hide()
	)
