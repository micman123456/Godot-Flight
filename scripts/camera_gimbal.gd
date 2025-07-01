extends Node3D

@export var aircraft : Aircraft  
@export var acceleration_threshold: float = 15
@export var response_strength: float = 0.1
@export var max_zoom = 1.2
@export var min_zoom = 1.0
@export_range(0.05, 1.0) var zoom_speed = 0.01
@export var zoom:float = 1.0
@export var movement_threshold : float = 0.01

var velocity : float = 0
var reset : bool = true
var joystick_input : Vector2

func _physics_process(delta: float) -> void:
	
	rotate_from_joystick(joystick_input,delta)
	
	if is_reset():
		var pitch_movement = aircraft.effective_input.x
		var yaw_movement = aircraft.effective_input.y
		var roll_movement = aircraft.effective_input.z
		var current_forward_velocity = aircraft.forward_air_speed
		var acceleration = (current_forward_velocity - velocity) / delta
		velocity = current_forward_velocity
	
		var rotationVector = Vector3(yaw_movement,pitch_movement,roll_movement)
		zoom_with_speed(acceleration,delta)
		rotate_from_control_inputs(rotationVector*0.0075,delta)
		scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)


func rotate_from_joystick(v:Vector2, delta:float):
	
	var rotation_y_scaled = -v.x*180
	var rotation_x_scaled = -v.y*180
	
	rotation_degrees.y = lerp(rotation_degrees.y,rotation_y_scaled,delta*5)
	rotation_degrees.x = lerp(rotation_degrees.x,rotation_x_scaled,delta*5)

	
	
func rotate_from_control_inputs(v: Vector3, delta: float):
	var threshold = 0.01
	
	
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.z -= v.z
	
	
	
	if (abs(v.y) < threshold):
		rotation.x = lerp(rotation.x,0.0,delta*2)
	if (abs(v.x) < threshold):
		rotation.y = lerp(rotation.y,0.0,delta*2)
	if (abs(v.z) < threshold):
		rotation.z = lerp(rotation.z,0.0,delta*2)
func is_reset():
	if joystick_input.length() == 0:
		return true
	

func zoom_with_speed(acc:float, delta:float):
	if (acc>acceleration_threshold):
		zoom += zoom_speed
	else:
		zoom -= zoom_speed
	zoom = clamp(zoom, min_zoom, max_zoom)
