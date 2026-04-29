## Add this to a [Light3D] to automatically handle it fading in and out with fog.
class_name PsxFogLightFader extends Node

## If enabled, this will dim the light instead of using the traditional distance fade. Updates every frame.
@export var dim_only: bool = false


@onready var light: Light3D = get_parent()
@onready var light_energy := light.light_energy
var light_energy_prev: float


func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() is not Light3D:
		return ["Parent must be a Light3D."]
	return []


func _ready() -> void:
	Psx.inst.fog_changed.connect(refresh)
	refresh()


func _process(delta: float) -> void:
	if light.distance_fade_enabled: return

	light.light_energy = light_energy * clampf(remap(
		get_viewport().get_camera_3d().global_position.distance_to(light.global_position),
		Psx.fog_near, Psx.fog_far, 1.0, 1.0 - Psx.fog_color.a
	), 0.0, 1.0)

func refresh() -> void:
	if dim_only:
		light.distance_fade_enabled = false
	else:
		light.light_energy = light_energy
		light.distance_fade_enabled = Psx.fog_color.a >= 1.0
		light.distance_fade_begin = minf(Psx.fog_near, Psx.fog_far)
		light.distance_fade_length = absf(Psx.fog_far - light.distance_fade_begin)
