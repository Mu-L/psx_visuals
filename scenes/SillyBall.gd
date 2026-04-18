@tool extends RigidBody3D

@export var material: Material:
	set(value):
		material = value
		if not is_node_ready(): return

		$mesh.material_override = value

@export var precision_uv: float = 1.0:
	set(value):
		precision_uv = value
		if not is_node_ready(): return

		$mesh.set_instance_shader_parameter(&"i_precision_uv", precision_uv)

@export var precision_xy: float = 1.0:
	set(value):
		precision_xy = value
		if not is_node_ready(): return

		$mesh.set_instance_shader_parameter(&"i_precision_xy", precision_xy)

@export var precision_z: float = 1.0:
	set(value):
		precision_z = value
		if not is_node_ready(): return

		$mesh.set_instance_shader_parameter(&"i_precision_z", precision_z)

@export var precision_all: float = 1.0:
	set(value):
		precision_all = value
		precision_uv = value
		precision_xy = value
		precision_z = value

@export var target_position: Vector3
@export var change_interval := Vector2(0.5, 2.0)
@export var speed_range := Vector2(0.5, 2.0)

var current_speed: float
var current_angle: float

var timer: Timer

func _init() -> void:
	if Engine.is_editor_hint(): return

	timer = Timer.new()
	timer.wait_time = change_interval.x
	timer.timeout.connect(_change_speed)
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)


func _ready() -> void:
	$mesh.material_override = material
	$mesh.set_instance_shader_parameter(&"i_precision_xy", precision_xy)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return

	var direction := ((target_position - global_position) * (Vector3.ONE - Vector3.UP)).normalized()
	direction = direction.rotated(Vector3.UP, current_angle)
	apply_central_force(direction * current_speed * mass)


func _change_speed() -> void:
	timer.wait_time = randf_range(change_interval.x, change_interval.y)
	current_speed = minf(global_position.distance_to(target_position), speed_range.y) * randf_range(speed_range.x, speed_range.y) if current_speed == 0.0 else 0.0
	current_angle = deg_to_rad(randf_range(-5, 5))
