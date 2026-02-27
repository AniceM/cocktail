extends Camera2D

var _transition_tween: Tween
var _pulse_tween: Tween


func transition_to(
	target_position: Vector2,
	target_zoom: Vector2,
	duration: float = 0.5,
	ease_type: Tween.EaseType = Tween.EASE_OUT,
	trans_type: Tween.TransitionType = Tween.TRANS_QUAD
) -> void:
	if _transition_tween:
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(self, "position", target_position, duration).set_ease(ease_type).set_trans(trans_type)
	_transition_tween.tween_property(self, "zoom", target_zoom, duration).set_ease(ease_type).set_trans(trans_type)


func pulse_zoom(intensity: float = 0.03, duration_in: float = 0.3, duration_out: float = 0.3) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	var base_zoom := zoom
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "zoom", base_zoom + Vector2(intensity, intensity), duration_in).set_ease(Tween.EASE_IN)
	_pulse_tween.tween_property(self, "zoom", base_zoom, duration_out).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
