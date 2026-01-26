extends Control

# ============================================================================
# Constants
# ============================================================================
const BADGE_SCENE = preload("uid://ck5xwpk0y67nc") # SignatureBadge
const STAGGER_DELAY: float = 0.1 # Delay between each badge entrance
const ENTRANCE_DURATION: float = 0.25
const SETTLE_DURATION: float = 0.75
const DROP_DISTANCE: float = 10.0

# ============================================================================
# References
# ============================================================================
@onready var grid_container: GridContainer = $CenterContainer/GridContainer

# ============================================================================
# State
# ============================================================================
var active_badges: Array[Control] = []

# ============================================================================
# Lifecycle
# ============================================================================

func _ready() -> void:
	# Clear any pre-existing children from the GridContainer (used for visual testing in editor)
	for child in grid_container.get_children():
		child.queue_free()

# ============================================================================
# Public API
# ============================================================================

func show_signatures(signatures: Array[Signature]) -> void:
	"""Display badges for the given signatures with staggered entrance animation."""
	# Clear any existing badges
	_clear_badges()

	if signatures.is_empty():
		return

	# Sort signatures: unlocked first, then locked
	var sorted_signatures = signatures.duplicate()
	sorted_signatures.sort_custom(_sort_unlocked_first)

	# Create and animate badges
	for i in range(sorted_signatures.size()):
		var signature = sorted_signatures[i]
		var badge = _create_badge(signature)
		var is_unlocked = PlayerProgression.is_signature_unlocked(signature)
		_animate_badge_entrance(badge, i, is_unlocked)


func hide_signatures() -> void:
	"""Hide and clear all badges."""
	# If no badges, just clear directly
	if active_badges.is_empty():
		_clear_badges()
		return

	# Animate out then clear
	var hide_tween = create_tween().set_parallel(true)

	for badge in active_badges:
		hide_tween.tween_property(badge, "modulate:a", 0.0, 0.15)
		hide_tween.tween_property(badge, "scale", Vector2(0.5, 0.5), 0.15)

	hide_tween.chain().tween_callback(_clear_badges)


# ============================================================================
# Internal Helpers
# ============================================================================

func _create_badge(signature: Signature) -> Control:
	"""Instantiate a badge for the given signature."""
	var badge = BADGE_SCENE.instantiate()
	badge.signature = signature
	grid_container.add_child(badge)
	active_badges.append(badge)

	# Initialize in hidden state for animation
	badge.modulate.a = 0

	return badge


func _animate_badge_entrance(badge: Control, index: int, is_unlocked: bool) -> void:
	"""Animate a single badge entrance with staggered delay."""
	var delay = index * STAGGER_DELAY
	var texture_rect = badge.texture_rect
	var original_scale = badge.original_scale

	# Store original texture position for drop animation
	var original_texture_pos = texture_rect.position

	# Initialize texture in scaled-down state
	texture_rect.scale = original_scale * 0.5

	# Displace texture upward
	texture_rect.position.y -= DROP_DISTANCE

	# Animate
	var tween = create_tween()

	# Fade in and scale up
	tween.tween_property(badge, "modulate:a", 1.0, ENTRANCE_DURATION).set_delay(delay)

	tween.parallel().tween_property(texture_rect, "scale", original_scale * 1.2, ENTRANCE_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT) \
		.set_delay(delay)

	# Drop texture down and scale back with elastic
	tween.tween_property(texture_rect, "position:y", original_texture_pos.y, SETTLE_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT) \
		.set_delay(delay)

	tween.parallel().tween_property(texture_rect, "scale", original_scale, SETTLE_DURATION) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT) \
		.set_delay(delay)

	# Trigger glow effect after entrance
	tween.tween_callback(func(): badge.play_glow(is_unlocked))


func _clear_badges() -> void:
	"""Remove all badge instances."""
	for badge in active_badges:
		badge.queue_free()
	active_badges.clear()


func _sort_unlocked_first(a: Signature, b: Signature) -> bool:
	"""Sort comparator: unlocked signatures come before locked ones."""
	var a_unlocked = PlayerProgression.is_signature_unlocked(a)
	var b_unlocked = PlayerProgression.is_signature_unlocked(b)

	# Unlocked (true) should come before locked (false)
	if a_unlocked and not b_unlocked:
		return true
	elif not a_unlocked and b_unlocked:
		return false
	else:
		# Same unlock status - maintain original order
		return false
