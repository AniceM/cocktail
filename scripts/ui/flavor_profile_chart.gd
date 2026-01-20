extends Control

@onready var values: ColorRect = %Values
@onready var void_label: Label = %VoidLabel
@onready var drift_label: Label = %DriftLabel
@onready var volatile_label: Label = %VolatileLabel
@onready var caustic_label: Label = %CausticLabel
@onready var resonant_label: Label = %ResonantLabel
@onready var temporal_label: Label = %TemporalLabel

@export var animation_duration: float = 0.25

var flavor_index: Dictionary[Flavor, int] = {
	FlavorRegistry.ABYSS: 0,
	FlavorRegistry.DRIFT: 1,
	FlavorRegistry.VOLATILE: 2,
	FlavorRegistry.CAUSTIC: 3,
	FlavorRegistry.RESONANT: 4,
	FlavorRegistry.TEMPORAL: 5
}

var flavor_labels: Dictionary[Flavor, Label] = {}

var values_shader: ShaderMaterial = null
var tween: Tween
var _previous_values: Dictionary[Flavor, float] = {}

const LABEL_PULSE_SCALE := 1.15
const LABEL_PULSE_DURATION := 0.12

func _ready() -> void:
	values_shader = values.material
	# Map flavors to their labels
	flavor_labels = {
		FlavorRegistry.ABYSS: void_label,
		FlavorRegistry.DRIFT: drift_label,
		FlavorRegistry.VOLATILE: volatile_label,
		FlavorRegistry.CAUSTIC: caustic_label,
		FlavorRegistry.RESONANT: resonant_label,
		FlavorRegistry.TEMPORAL: temporal_label
	}
	# Set the colors to the flavors' ones
	for flavor in FlavorRegistry.get_all_flavors():
		var color = flavor.color
		var index = flavor_index[flavor]
		values_shader.set_shader_parameter("vertex_color_%d" % index, color)
		# Initialize previous values
		_previous_values[flavor] = 0.0
	# Reset the chart
	reset()

func reset() -> void:
	update_flavor_profile(FlavorStats.new(), true)

func update_flavor_profile(flavor_values: FlavorStats, animate: bool = false) -> void:
	# Create a tween to animate the change (if needed)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)

	# Update each flavor
	for flavor in FlavorRegistry.get_all_flavors():
		# Get index (to know what shader parameter we need to set)
		var index = flavor_index[flavor]
		# Get the value of the flavor
		var new_value = flavor_values.get_value(flavor)
		# Normalize the value
		# A flavor stat can be negative, but it has the same effect as the stat being 0
		# Plus the shader needs values between 0 and 1
		new_value = clamp(new_value / 10.0, 0, 1)
		# Set the shader parameter
		if !animate:
			values_shader.set_shader_parameter("stat_%d" % index, new_value)
		else:
			var current_value = values_shader.get_shader_parameter("stat_%d" % index)
			tween.tween_method(func(v): values_shader.set_shader_parameter("stat_%d" % index, v), current_value, new_value, animation_duration)
			# Pulse the label if value changed
			var raw_value = flavor_values.get_value(flavor)
			if raw_value != _previous_values[flavor]:
				_pulse_label(flavor_labels[flavor])
				_previous_values[flavor] = raw_value


func _pulse_label(label: Label) -> void:
	var pulse_tween := create_tween()
	label.pivot_offset = label.size / 2.0
	pulse_tween.tween_property(label, "scale", Vector2.ONE * LABEL_PULSE_SCALE, LABEL_PULSE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	pulse_tween.tween_property(label, "scale", Vector2.ONE, LABEL_PULSE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
