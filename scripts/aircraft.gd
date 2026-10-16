class_name Aircraft
extends RigidBody3D

signal update_air_devices
signal toggle_gear


@export var engine_thrust : float
@export var lift_power : float
@export var induced_drag_power : float
@export var h_stabilizer_power : float
@export var v_stabilizer_power : float
@export var lift_power_flaps : float
@export var steering_power : float


@export var dragRight : float = 0
@export var dragLeft : float = 0
@export var dragTop : float = 0
@export var dragBottom : float = 0
@export var dragForward : float = 0
@export var dragBack : float = 0
@export var dragFlaps: float = 0
@export var dragAirbrake: float = 0


@export var glimit : float = 8
@export var glimit_down : float = -4

@export var deflectionRate : Vector3
@export var turnSpeed : Vector3
@export var turnRate : Vector3

@export var LiftCurve : Curve
@export var SteeringCurve : Curve
@export var Induced_Drag : float = 0.1

@export var wing_offset : float
@export var tail_offset : float
@export var aliron_offset : float
@export var max_speed : float = 600.0
@export var Power : Vector3


@export var CameraGimble : Node3D

const AIR_DENSITY_RHO = 1.225
const STANDARD_GRAVITY = 9.81

var LiftForce : Vector3 = Vector3.ZERO
var LiftForceYaw : Vector3 = Vector3.ZERO

var DragForce : Vector3 = Vector3.ZERO
var ThrustForce : Vector3

var torque : Vector3 = Vector3.ZERO
var LocalVelocity : Vector3 = Vector3.ZERO
var LastVelocity : Vector3 = Vector3.ZERO
var LocalAngularVelocity : Vector3 = Vector3.ZERO
var AngleOfAttack : float = 0
var AngleOfAttackYaw : float = 0
# Felt G force in the aircraft's local axes, in units of g.
# x = right, y = up (positive when pulling up), z = back.
var LocalGForce : Vector3 = Vector3.ZERO
var forward_air_speed : float = 0.0
var throttle_setting : float = 0.0
var control_input : Vector3
var aircraft_input : Vector3
var camera_input_vec : Vector2

var flaps_deployed : bool = false
var airbrake_deployed : bool = false


func _ready() -> void:
	linear_damp = 0.0
	linear_velocity = Vector3(0,0,-200)

func _physics_process(delta: float) -> void:
	Update_Camera_Input(delta)
	Update_Throttle_Input(delta)
	Update_Flight_Control_Input(delta)
	Update_Air_Devices_Input()

	Calulate_state(delta)

	Thrust(throttle_setting)
	Update_Drag()
	Update_Lift()
	Update_Torque(delta)


func Update_Camera_Input(delta:float):
	var x_input = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var y_input = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	var deadzone = 0.1

	if abs(x_input) < deadzone:
		x_input = 0.0
	if abs(y_input) < deadzone:
		y_input = 0.0

	camera_input_vec.x = move_toward(camera_input_vec.x,x_input,delta*2)
	camera_input_vec.y = move_toward(camera_input_vec.y,y_input,delta*2)

	if CameraGimble:
		CameraGimble.joystick_input = camera_input_vec



func Update_Throttle_Input(delta):

	if Input.is_action_pressed("throttle_down"):
		throttle_setting = move_toward(throttle_setting,0,delta*0.5)

	if Input.is_action_pressed("throttle_up"):
		throttle_setting = move_toward(throttle_setting,1,delta*0.5)

func Update_Flight_Control_Input(delta):
	var roll = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var pitch = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var yaw = 0
	var deadzone = 0.1

	if abs(roll) < deadzone:
		roll = 0.0
	if abs(pitch) < deadzone:
		pitch = 0.0

	if Input.is_action_pressed("yaw_left"):
		yaw = 1.0
	if Input.is_action_pressed("yaw_right"):
		yaw = -1.0


	control_input = Vector3(pitch,yaw,-roll)
	if control_input.length() < 0.1:
		control_input = Vector3.ZERO


	aircraft_input.x = move_toward(aircraft_input.x,control_input.x,delta*deflectionRate.x)
	aircraft_input.y = move_toward(aircraft_input.y,control_input.y,delta*deflectionRate.y)
	aircraft_input.z = move_toward(aircraft_input.z,control_input.z,delta*deflectionRate.z)


func Update_Air_Devices_Input():
	if Input.is_action_just_pressed("toggle_flaps"):
		flaps_deployed = !flaps_deployed
		emit_signal("update_air_devices")
	if Input.is_action_just_pressed("toggle_airbrake"):
		airbrake_deployed = !airbrake_deployed
		emit_signal("update_air_devices")


func Calulate_state(delta: float) -> void:
	var inverse_basis := global_transform.basis.orthonormalized().inverse()
	LocalVelocity = inverse_basis * linear_velocity
	LocalAngularVelocity = inverse_basis * angular_velocity
	forward_air_speed = -LocalVelocity.z
	AngleOfAttack = rad_to_deg(atan2(-LocalVelocity.y, -LocalVelocity.z))
	AngleOfAttackYaw = rad_to_deg(atan2(
		LocalVelocity.x,
		Vector2(LocalVelocity.y, LocalVelocity.z).length()
	))

	if delta > 0.0:
		var acceleration := (linear_velocity - LastVelocity) / delta
		# Felt (proper) acceleration is the measured acceleration minus gravity,
		# so level flight reads +1 g on the local up axis.
		var gravity_vector : Vector3 = (
			ProjectSettings.get_setting("physics/3d/default_gravity_vector")
			* ProjectSettings.get_setting("physics/3d/default_gravity")
			* gravity_scale
		)
		LocalGForce = inverse_basis * (acceleration - gravity_vector) / STANDARD_GRAVITY

	LastVelocity = linear_velocity

func Thrust(current_power : float):
	var force_vector = -global_transform.basis.z * engine_thrust * current_power
	ThrustForce = force_vector
	apply_force(force_vector)

func Calculate_Drag():
	# drag = 1/2 * AIR_DENSITY_RHO * v2 * Cd
	var forward_drag = dragForward
	if flaps_deployed:
		forward_drag+=dragFlaps
	if airbrake_deployed:
		forward_drag+=dragAirbrake

	var drag_coefficient = Utils.scale6(LocalVelocity.normalized(),dragRight, dragLeft,
		dragTop, dragBottom,
		dragBack, forward_drag)
	var velocity_squared = LocalVelocity.length_squared()
	var drag_force = 0.5 * AIR_DENSITY_RHO * velocity_squared * drag_coefficient.length()

	var drag_direction = -LocalVelocity.normalized()

	return drag_force*drag_direction


func Update_Drag():
	var drag_local = Calculate_Drag()
	DragForce = drag_local
	var drag_global = global_transform.basis * drag_local
	apply_force(drag_global)

func Calculate_Lift(
		angle_of_attack: float,
		right_axis: Vector3,
		lift_power: float,
		induced_drag_power: float,
		aoa_curve: Curve
) -> Vector3:
	# Remove the velocity component along the surface's span axis.
	var lift_velocity := LocalVelocity - right_axis * LocalVelocity.dot(right_axis)
	var speed_squared := lift_velocity.length_squared()

	var lift_coefficient := aoa_curve.sample(angle_of_attack)
	var lift_magnitude := lift_coefficient * lift_power * speed_squared

	# Span crossed with airflow points up for a wing in forward (-Z) flight.
	var lift_direction := right_axis.cross(lift_velocity.normalized())
	var lift := lift_direction * lift_magnitude

	var drag_force := lift_coefficient * lift_coefficient * induced_drag_power
	var drag_direction := -lift_velocity.normalized()
	var induced_drag := drag_direction * speed_squared * drag_force

	return lift + induced_drag


func Update_Lift():
	var forward_vector := -global_transform.basis.z

	var flap_power = lift_power_flaps if flaps_deployed else 0

	var wing_lift_force = Calculate_Lift(
		AngleOfAttack,
		Vector3.RIGHT,
		lift_power+flap_power,
		induced_drag_power,
		LiftCurve
		)
	var vertical_stabilizer_force = Calculate_Lift(
		AngleOfAttackYaw,
		Vector3.UP,
		v_stabilizer_power,
		induced_drag_power,
		LiftCurve
	)

	LiftForce = wing_lift_force
	LiftForceYaw = vertical_stabilizer_force
	var global_wing_force = global_transform.basis * wing_lift_force
	var global_vertical_stabilizer_force = global_transform.basis * vertical_stabilizer_force

	apply_force(global_wing_force,forward_vector * wing_offset)
	apply_force(global_vertical_stabilizer_force,forward_vector * tail_offset)


# Calculates rotation for a single axis
# av - angular velocity
# target_av - the target angular velocity
# acc - turn accleration for the axis
func Calculate_Steering_On_Axis(delta:float,av:float,target_av:float,acc:float):
	var error = target_av - av
	var acceleration = acc*delta
	return clamp(error,-acceleration,acceleration)

func Update_Torque(delta : float):
	if delta <= 0.0:
		return

	var speed_ratio := clampf(forward_air_speed / max_speed, 0.0, 1.0)
	var steering_power := SteeringCurve.sample(speed_ratio)
	var target_av = control_input * (turnSpeed * steering_power)
	var glimiter = glimter_scale((0.0174533*turnSpeed)*steering_power)

	var angular_velocity_change := Vector3(
		Calculate_Steering_On_Axis(delta, LocalAngularVelocity.x, target_av.x, turnRate.x*steering_power*glimiter),
		Calculate_Steering_On_Axis(delta, LocalAngularVelocity.y, target_av.y, turnRate.y*steering_power*glimiter),
		Calculate_Steering_On_Axis(delta, LocalAngularVelocity.z, target_av.z, turnRate.z*steering_power*glimiter)
	)
	var local_angular_acceleration := angular_velocity_change / delta
	var global_angular_acceleration := global_transform.basis * local_angular_acceleration
	var calculated_torque := get_inverse_inertia_tensor().inverse() * global_angular_acceleration
	torque = calculated_torque

	apply_torque(calculated_torque)


func calculate_g_force(av: Vector3, velocity: Vector3) -> Vector3:
	# Estimate G Force from angular velocity and velocity
	# G = V cross A
	return av.cross(velocity)

func caluclate_g_limit(input:Vector3):
	return Utils.scale6(input,glimit,glimit_down,glimit,glimit,glimit,glimit) * 9.81;

func glimter_scale(max_av: Vector3):
	var max_input = aircraft_input.normalized()

	var limit = caluclate_g_limit(max_input)
	var max_g = calculate_g_force(max_av*max_input, LocalVelocity)

	if (max_g.length() > limit.length()):
		return limit.length()/max_g.length()
		print("G limit exceeded")

	return 1.0
