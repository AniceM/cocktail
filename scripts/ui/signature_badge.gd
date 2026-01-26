extends Control

# ============================================================================
# Visuals & References
# ============================================================================
@onready var texture_rect: TextureRect = %TextureRect
@onready var label: Label = %Label

# Badge glow shader
var base_shader: ShaderMaterial # Cached shader material for direct access

# Default shader parameters
const GLOW_INTENSITY: float = 1.5
const INNER_GLOW_INTENSITY: float = 0.2
const PULSE_AMOUNT: float = 0.9
const ENABLE_SHIMMER: bool = false

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
var focus_tween: Tween
const FOCUS_TWEEN_DURATION: float = 0.2
const UNFOCUS_TWEEN_DURATION: float = 0.15
var original_scale: Vector2

# ============================================================================
# Lifecycle
# ============================================================================

func _ready() -> void:
	# Validate shader exists
	base_shader = texture_rect.material as ShaderMaterial
	if not base_shader:
		push_error("SignatureBadge's TextureRect does not have a ShaderMaterial!")
		return

	# Duplicate the shader material so changes don't affect other badges
	base_shader = base_shader.duplicate()
	texture_rect.material = base_shader

	# Reset shader to default values
	reset_shader()

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

func reset_shader() -> void:
	"""Reset the shader to default values."""
	base_shader.set_shader_parameter("glow_intensity", GLOW_INTENSITY)
	base_shader.set_shader_parameter("inner_glow_intensity", INNER_GLOW_INTENSITY)
	base_shader.set_shader_parameter("pulse_amount", PULSE_AMOUNT)
	base_shader.set_shader_parameter("enable_shimmer", ENABLE_SHIMMER)

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
		# Update label
		label.label_settings.font_color = "#fadb41"
		label.text = signature.name
		# Update shader
		base_shader.set_shader_parameter("glow_color", signature.get_glow_color())
	else:
		_set_locked()
		# Update label
		label.label_settings.font_color = "#42a3c3"
		label.text = "???"
		# Update shader
		base_shader.set_shader_parameter("glow_color", Color.BLUE_VIOLET)

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


# ============================================================================
# Hover Effects
# ============================================================================

func _on_mouse_entered() -> void:
	"""Scale up the badge on hover."""
	# Draw on top of other badges
	z_index = 1
	# Show label
	label.show()
	label.modulate.a = 0
	# Enable shimmer immediately (boolean, can't tween)
	base_shader.set_shader_parameter("enable_shimmer", true)

	if focus_tween:
		focus_tween.kill()
	focus_tween = create_tween().set_parallel()

	# Scale up and fade in label
	focus_tween.tween_property(texture_rect, "scale", original_scale * 1.2, FOCUS_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	focus_tween.tween_property(label, "modulate:a", 1.0, FOCUS_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	# Tween shader parameters for smooth glow transition
	focus_tween.tween_method(func(v): _set_shader_parameter("glow_intensity", v), GLOW_INTENSITY, 3.5, FOCUS_TWEEN_DURATION / 2)
	focus_tween.tween_method(func(v): _set_shader_parameter("inner_glow_intensity", v), INNER_GLOW_INTENSITY, 0.3, FOCUS_TWEEN_DURATION / 2)
	focus_tween.tween_method(func(v): _set_shader_parameter("pulse_amount", v), PULSE_AMOUNT, 0.0, FOCUS_TWEEN_DURATION / 2)


func _on_mouse_exited() -> void:
	"""Return badge to normal scale."""
	# Reset z-index
	z_index = 0

	if focus_tween:
		focus_tween.kill()
	focus_tween = create_tween().set_parallel()

	# Scale down and fade out label
	focus_tween.tween_property(texture_rect, "scale", original_scale, UNFOCUS_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	focus_tween.tween_property(label, "modulate:a", 0.0, UNFOCUS_TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)

	# Tween shader parameters back to defaults
	var current_glow := base_shader.get_shader_parameter("glow_intensity") as float
	var current_inner := base_shader.get_shader_parameter("inner_glow_intensity") as float
	var current_pulse := base_shader.get_shader_parameter("pulse_amount") as float
	focus_tween.tween_method(func(v): _set_shader_parameter("glow_intensity", v), current_glow, GLOW_INTENSITY, UNFOCUS_TWEEN_DURATION)
	focus_tween.tween_method(func(v): _set_shader_parameter("inner_glow_intensity", v), current_inner, INNER_GLOW_INTENSITY, UNFOCUS_TWEEN_DURATION)
	focus_tween.tween_method(func(v): _set_shader_parameter("pulse_amount", v), current_pulse, PULSE_AMOUNT, UNFOCUS_TWEEN_DURATION)

	# Disable shimmer after tween completes
	focus_tween.finished.connect(func():
		base_shader.set_shader_parameter("enable_shimmer", ENABLE_SHIMMER)
		label.hide()
	, CONNECT_ONE_SHOT)


func _set_shader_parameter(param: String, value: Variant) -> void:
	base_shader.set_shader_parameter(param, value)
