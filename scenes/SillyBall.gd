@tool extends RigidBody3D

@export var material: Material:
	set(value):
		material = value
		if not is_node_ready(): return

		$mesh.material_override = value

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


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return

	var direction := Myth.flatten(target_position - global_position, true)
	direction = direction.rotated(Vector3.UP, current_angle)
	apply_central_force(direction * current_speed * mass)


func _change_speed() -> void:
	timer.wait_time = randf_range(change_interval.x, change_interval.y)
	current_speed = randf_range(speed_range.x, speed_range.y) if current_speed == 0.0 else 0.0
	current_angle = deg_to_rad(randf_range(-5, 5))
