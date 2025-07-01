class_name Aircraft
extends RigidBody3D

signal update_air_devices


@export var engine_thrust : float
@export var lift_power : float
@export var h_stabilizer_power : float
@export var v_stabilizer_power : float
@export var lift_power_flaps : float
@export var steering_power : float

@export var drag_coefficient : Vector3
@export var dragRight : float = 0
@export var dragLeft : float = 0
@export var dragTop : float = 0
@export var dragBottom : float = 0
@export var dragForward : float = 0
@export var dragBack : float = 0
@export var dragFlaps: float = 0
@export var dragAirbrake: float = 0

@export var turnAcceleration : Vector3
@export var turnDeflection : Vector3
@export var turnSpeed : Vector3

@export var LiftCurve : Curve
@export var SteeringCurve : Curve
@export var Induced_Drag : float = 0.1

@export var wing_offset : float 
@export var tail_offset : float
@export var aliron_offset : float
@export var max_speed : float = 600.0
@export var Power : Vector3

@export var air_res_curve : Curve
@export var angular_drag_coe : Vector3
@export var glimit : float
@export var glimit_down : float

@export var CameraGimble : Node3D

const AIR_DENSITY_RHO = 1.225

var LiftForce : Vector3 = Vector3.ZERO
var LiftForceYaw : Vector3 = Vector3.ZERO
var LiftForceHStabilator : Vector3 = Vector3.ZERO

var DragForce : Vector3 = Vector3.ZERO
var Current_Lift_Coe : float = 0
var Current_Drag_Coe : Vector3
var ThrustForce : Vector3 


var Velocity : Vector3 = Vector3.ZERO
var Acceleration : Vector3 = Vector3.ZERO
var LocalVelocity : Vector3 = Vector3.ZERO
var LastVelocity : Vector3 = Vector3.ZERO
var LocalAngularVelocity : Vector3 = Vector3.ZERO
var AngleOfAttack : float = 0
var AngleOfAttackYaw : float = 0
var LocalGForce : Vector3 = Vector3.ZERO
var forward_air_speed : float = 0.0
var throttle_setting : float = 0.5
var drag_intensity_vector : Vector3 = Vector3.ZERO
var control_input : Vector3
var aircraft_input : Vector3
var effective_input : Vector3
var camera_input_vec : Vector2

var flaps_deployed : bool = false
var airbrake_deployed : bool = false
var g_force : Vector3 


func _ready() -> void:
	linear_velocity = Vector3(0,0,-200)
	pass
	
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	Update_Throttle_Input(delta)
	Update_Flight_Control_Input(delta)
	Update_Air_Devices_Input()
	Calulate_state()
	Update_Drag()
	Update_Angular_Drag()
	Update_Lift_Adv()
	Update_Steering(delta)
	Update_Camera_Input(delta)
	Thrust(throttle_setting)
	
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

	
	aircraft_input.x = move_toward(aircraft_input.x,control_input.x,delta*turnDeflection.x)
	aircraft_input.y = move_toward(aircraft_input.y,control_input.y,delta*turnDeflection.y)
	aircraft_input.z = move_toward(aircraft_input.z,control_input.z,delta*turnDeflection.z)
	

func Update_Air_Devices_Input():
	if Input.is_action_just_pressed("toggle_flaps"):
		flaps_deployed = !flaps_deployed
		emit_signal("update_air_devices")
	if Input.is_action_just_pressed("toggle_airbrake"):
		airbrake_deployed = !airbrake_deployed
		emit_signal("update_air_devices")


func Calulate_state():
	LocalVelocity = global_transform.basis.inverse() * linear_velocity
	LocalAngularVelocity = global_transform.basis.inverse() * angular_velocity
	forward_air_speed = -LocalVelocity.z
	AngleOfAttack = rad_to_deg(atan2(-LocalVelocity.y, -LocalVelocity.z))
	AngleOfAttackYaw = rad_to_deg(atan2(LocalVelocity.x, -LocalVelocity.z))
		

func Thrust(current_power : float):
	var force_vector = -global_transform.basis.z * engine_thrust * current_power
	ThrustForce = force_vector
	apply_force(force_vector)

func Calculate_Drag():
	# drag = 1/2 v2 * Cd
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
	#print(drag_force*drag_direction)
	return drag_force*drag_direction

func Update_Drag():
	var drag_local = Calculate_Drag()
	var drag_global = global_transform.basis * drag_local
	apply_force(drag_global)
	
func Update_Angular_Drag():
	
	var speed_fraction = forward_air_speed/max_speed
	var av_coe = air_res_curve.sample(speed_fraction)*angular_drag_coe
	var av2 = LocalAngularVelocity.length_squared()
	var angular_drag_local = av_coe*av2*-LocalAngularVelocity.normalized()
	var angular_drag_global = global_transform.basis*angular_drag_local
	#angular_velocity+=angular_drag_global

func Calculate_Lift(angle_of_attack : float, lift_curve: Curve, lift_power : float):
	var forward_air_speed_squared = forward_air_speed*forward_air_speed
	angle_of_attack = clamp(angle_of_attack,-90,90)
	var cl = lift_curve.sample(angle_of_attack)
	var lift_force = cl * lift_power * AIR_DENSITY_RHO * ((AIR_DENSITY_RHO * forward_air_speed_squared)/2)
	return lift_force

func Calculate_Lift_Adv(relative_axis : Vector3,relative_aoa: float,aoa_curve:Curve,lift_power: float):
	# Lift = v^2 * lift_coefficient * lift_power

	var lift_velocity = Utils.project_on_plane(LocalVelocity,relative_axis)
	if lift_velocity.length_squared() < 0.0001 or Utils.has_nan(lift_velocity):
		return Vector3.ZERO
	
	var lift_velocity_squared = lift_velocity.length_squared()
	var lift_coefficient = aoa_curve.sample(relative_aoa)
	var lift_force = lift_velocity_squared*lift_coefficient*lift_power

	
	var liftDirection = -lift_velocity.normalized().cross(relative_axis)
	
	var lift = lift_force*liftDirection
	
	# induced drag from lift 
	var induced_drag_force = lift_coefficient*lift_coefficient*Induced_Drag
	var induced_drag_dir = -lift_velocity.normalized()
	var drag = induced_drag_dir*induced_drag_force*lift_velocity_squared
	
	return lift + drag
	
	
func Update_Lift():
	var up_vector = global_transform.basis.y # roof of plane on global frame
	var forward_vector = -global_transform.basis.z # nose of plane in global frame
	var right_vector = global_transform.basis.x # right wing of plane in global frame
	
	var flap_power = lift_power_flaps if flaps_deployed else 0
	
	var wing_lift_force = Calculate_Lift(AngleOfAttack,LiftCurve,lift_power+flap_power)
	var vstab_lift_force = Calculate_Lift(AngleOfAttackYaw,LiftCurve,v_stabilizer_power)
	var hstab_lift_force = Calculate_Lift(AngleOfAttack,LiftCurve,h_stabilizer_power)
	
	var wing_lift = up_vector*wing_lift_force
	var vstab_lift = right_vector*vstab_lift_force
	var hstab_lift = up_vector*hstab_lift_force
	
	apply_force(wing_lift,forward_vector * wing_offset)
	apply_force(vstab_lift,-forward_vector* tail_offset)
	apply_force(hstab_lift,-forward_vector* tail_offset)
	
	
func Update_Lift_Adv():
	if LocalVelocity.length() < 0.001:
		return
	
	var up_vector = global_transform.basis.y # roof of plane on global frame
	var forward_vector = -global_transform.basis.z # nose of plane in global frame
	var right_vector = global_transform.basis.x # right wing of plane in global frame
	
	var flap_power = lift_power_flaps if flaps_deployed else 0
	
	var wing_lift_force = Calculate_Lift_Adv(Vector3.RIGHT,AngleOfAttack,LiftCurve,lift_power+flap_power)
	var vstab_lift_force = Calculate_Lift_Adv(Vector3.UP,AngleOfAttackYaw,LiftCurve,v_stabilizer_power)
	var hstab_lift_force = Calculate_Lift_Adv(Vector3.RIGHT,AngleOfAttack,LiftCurve,h_stabilizer_power)
	
	var wing_lift = up_vector*wing_lift_force
	var vstab_lift = right_vector*vstab_lift_force
	var hstab_lift = up_vector*hstab_lift_force
	
	apply_force(wing_lift,forward_vector * wing_offset)
	apply_force(vstab_lift,-forward_vector* tail_offset)
	apply_force(hstab_lift,-forward_vector* tail_offset)
	
func Calculate_Steering(delta:float,av:float,target_av:float,acc:float):
	var error = target_av - av
	var acceleration = acc*delta
	return clamp(error,-acceleration,acceleration)
	
func Update_Steering_FBW(delta:float):
	
	if (LocalVelocity.length()<10.0):
		return

	var speed_fraction = forward_air_speed/max_speed
	var sp = SteeringCurve.sample(speed_fraction)*steering_power
	var av = LocalAngularVelocity
	var target_av = aircraft_input * (turnSpeed*steering_power)
			
		
	var correction_local = Vector3(
		Calculate_Steering(delta, av.x, target_av.x, turnAcceleration.x * steering_power),
		Calculate_Steering(delta, av.y, target_av.y, turnAcceleration.y * steering_power),
		Calculate_Steering(delta, av.z, target_av.z, turnAcceleration.z * steering_power)
	)
		
	
	var correction_global = global_transform.basis * correction_local
	
	angular_velocity += correction_global
	 
	var correction_input = Vector3(
		clamp((target_av.x-av.x)/turnAcceleration.x,-1,1),
		clamp((target_av.y-av.y)/turnAcceleration.y,-1,1),
		clamp((target_av.z-av.z)/turnAcceleration.z,-1,1)
	)
	
	
	
	var ei = correction_input+correction_local
	effective_input.x = move_toward(effective_input.x,ei.x,delta*10)
	effective_input.y = move_toward(effective_input.y,ei.y,delta*10)
	effective_input.z = move_toward(effective_input.z,ei.z,delta*10)

	
	
func Update_Steering(delta:float):
	if aircraft_input.length() < 0.1:
		Update_Steering_FBW(delta)
		return
		
	apply_control_surface_forces(control_input)
	effective_input = aircraft_input
	
func apply_control_surface_forces(control_input: Vector3):
	
	var forward_vector = -global_transform.basis.z
	var right_vector = global_transform.basis.x
	
	var airspeed = forward_air_speed
	var air_density = AIR_DENSITY_RHO
	var airflow = airspeed * air_density
	var g_scale = UpdateGLimiter(control_input)
	control_input = control_input*g_scale
	
	
	# === Elevator (Pitch) ===
	if control_input.x != 0.0:
		var force_up = -global_transform.basis.y * control_input.x * airflow * Power.x
		var force_down = global_transform.basis.y * control_input.x * airflow * Power.x

		apply_force(force_up,-forward_vector*tail_offset)
		#apply_force(force_down,-forward_vector*tail_offset)
		
	# === Rudder (Yaw) ===
	if control_input.y != 0.0:
		var force_rd_left = -global_transform.basis.x * control_input.y * airflow * 0.5 * Power.y
		var force_rd_right = global_transform.basis.x * control_input.y * airflow * 0.5 * Power.y
		#apply_force(force_rd_left, -forward_vector*tail_offset)
		apply_force(force_rd_right, -forward_vector*tail_offset)

	# === Ailerons (Roll) ===
	if control_input.z != 0.0:
		var force_left = -global_transform.basis.y * control_input.z * airflow * 0.5 * Power.z
		var force_right = global_transform.basis.y * control_input.z * airflow * 0.5 * Power.z
		var aileron_left = -right_vector * aliron_offset
		var aileron_right = right_vector * aliron_offset
		apply_force(force_left, aileron_left)
		apply_force(force_right, aileron_right)
		
func calculate_g_force(av: Vector3, velocity: Vector3) -> Vector3:
	# Estimate G Force from angular velocity and velocity
	# G = V cross A
	return av.cross(velocity)

func caluclate_g_limit(input:Vector3):
	return Utils.scale6(input,glimit,glimit_down,glimit,glimit,glimit,glimit)
	
func UpdateGLimiter(input:Vector3):
	var limit = caluclate_g_limit(input.normalized())
	var actual = calculate_g_force(angular_velocity,linear_velocity)/9.81
	
	if limit.length() < actual.length():
		
		return limit.length() / actual.length()
	else:
		return 1.0
