extends Control

@onready var values: ColorRect = %Values

@export var animation_duration: float = 0.25

var flavor_index: Dictionary[Flavor, int] = {
	FlavorRegistry.ABYSS: 0,
	FlavorRegistry.DRIFT: 1,
	FlavorRegistry.VOLATILE: 2,
	FlavorRegistry.CAUSTIC: 3,
	FlavorRegistry.RESONANT: 4,
	FlavorRegistry.TEMPORAL: 5
}

var values_shader: ShaderMaterial = null
var tween: Tween

func _ready() -> void:
	values_shader = values.material
	# Set the colors to the flavors' ones
	for flavor in FlavorRegistry.get_all_flavors():
		var color = flavor.color
		var index = flavor_index[flavor]
		values_shader.set_shader_parameter("vertex_color_%d" % index, color)
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
