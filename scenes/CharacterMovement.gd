extends CharacterBody3D

@export var friction: float = 0.1
@export var move_speed: float = 1.0
@export var turn_speed: float = 1.0
@export var turn_speed_mouse: float = 1.0

var turn_mouse_axis: float

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var move_vector := Input.get_vector(&"ghost_move_left", &"ghost_move_right", &"ghost_move_forward", &"ghost_move_back")

	velocity -= velocity * (Vector3.ONE - up_direction) * friction
	velocity += global_basis * Vector3(move_vector.x, 0.0, move_vector.y) * move_speed * (2.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	var turn_axis := Input.get_axis(&"ghost_camera_left", &"ghost_camera_right")

	rotation.y -= turn_mouse_axis * turn_speed_mouse * delta
	rotation.y += turn_axis * turn_speed * delta

	turn_mouse_axis = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion:
		turn_mouse_axis = event.screen_relative.x
