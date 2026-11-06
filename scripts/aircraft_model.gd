extends Node3D

@export var aircraft : Aircraft

@export var EngineSoundLoop: AudioStream
@export var EngineSoundAferburner: AudioStream

# Toggled by the gear_up / gear_down animations in the AnimationPlayer.
var gear_down : bool = false
var gear_moving : bool = false

var elevator_min = 65
var elevator_max = 115
var elevator_center = 90
var elevator_range: int = 35

var ailerons_center = 90
var ailerons_range: int = 25

# F-15 and Components
@onready var LeftElevator = $LeftElevator
@onready var RightElevator = $RightElevator

@onready var LeftFlap = $LeftFlap
@onready var RightFlap = $RightFlap

@onready var LeftRudder = $LeftRudder
@onready var RightRudder = $RightRudder

@onready var LeftAileron = $LeftAileron
@onready var RightAileron = $RightAileron

@onready var Airbrake = $Airbrake
@onready var EngineAudio = $EngineAudio
@onready var AfterburnerAudio = $AfterburnerAudio

@onready var Exhaust_Left = $ExhaustHeatLeft
@onready var Exhaust_Right = $ExhaustHeatRight

@onready var Afterburner1 = $Afterburner1
@onready var Afterburner2 = $Afterburner2
@onready var Animation_Player = $AnimationPlayer

# Moving states for Components
var FlapsMoving: bool = false
var LeftElevatorMoving: bool = false
var RightElevatorMoving: bool = false
var RudderMoving: bool = false

# Angle states and speed for Components
var current_flap_angle: float = 90
var target_flap_angle: float = 90
var flap_speed: float = 5.0

var l_elevator_current_angle: float = 90
var r_elevator_current_angle: float = 90
var target_l_elevator: float = 90
var target_r_elevator: float = 90
var l_elevator_speed: float = 5.0
var r_elevator_speed: float = 5.0

var rudder_current_angle: float = 0
var target_rudder_angle: float = 0
var rudder_speed: float = 3.0

var L_ailerons_current_angle: float = 90
var L_target_ailerons_angle: float = 0
var L_ailerons_speed: float = 15.0
var L_AileronsMoving: bool = false

var R_ailerons_current_angle: float = 90
var R_target_ailerons_angle: float = 0
var R_ailerons_speed: float = 15.0
var R_AileronsMoving: bool = false

var Airbrake_Current_angle: float = 90
var Airbrake_target_angle: float = 70
var Airbrake_Speed = 15.0
var AirbrakeMoving : bool = false


func _ready():
	aircraft.connect("update_air_devices", Callable(self, "update_air_devices"))
	aircraft.connect("toggle_gear", Callable(self, "toggle_gear"))
	
	## Set gear's inital position
	if (gear_down):
		Animation_Player.play("RESET")
	else:
		Animation_Player.play("RESET_UP")	
	

	if EngineAudio and EngineSoundLoop:
		EngineAudio.stream = EngineSoundLoop
		EngineAudio.volume_db = 10
	if AfterburnerAudio and EngineSoundAferburner:
		AfterburnerAudio.stream = EngineSoundAferburner
		AfterburnerAudio.volume_db = 0


func _process(delta: float) -> void:
	if aircraft:
		update_control_input(aircraft.aircraft_input)
		handle_engine_audio()
		handle_engine_animation()

	# Update movements
	if FlapsMoving:
		MoveFlaps(delta)
	if AirbrakeMoving:
		MoveAirbrake(delta)
	if LeftElevatorMoving && RightElevatorMoving:
		MoveLeftElevator(delta)
		MoveRightElevator(delta)
	else:
		setElevatorPosition(90)
	if RudderMoving:
		MoveRudder(delta)
	else:
		setRudderPosition(0)
	if L_AileronsMoving && R_AileronsMoving:
		MoveLeftAileron(delta)
		MoveRightAileron(delta)
	else:
		resetRoll()


func update_control_input(input: Vector3):
	setElevatorPosition(-input.x)
	Roll(-input.z)
	setRudderPosition(remap(-input.y, -1, 1, -30, 30))


func update_air_devices():
	setFlaps(aircraft.flaps_deployed)
	setAirbrake(aircraft.airbrake_deployed)


func resetRoll():
	# Neutralize the ailerons
	L_target_ailerons_angle = 90
	R_target_ailerons_angle = 90
	L_AileronsMoving = true
	R_AileronsMoving = true


# Flap Functions #
func setFlaps(input: bool):
	if input:
		target_flap_angle = flaps_range_max()
	else:
		target_flap_angle = flaps_range_min()

	FlapsMoving = true


func MoveFlaps(delta: float):
	# Smoothly interpolate the current flap angle toward the target angle
	current_flap_angle = lerp(current_flap_angle, target_flap_angle, flap_speed * delta)

	if abs(current_flap_angle - target_flap_angle) < 0.1:
		current_flap_angle = target_flap_angle
		FlapsMoving = false

	LeftFlap.rotation_degrees.x = current_flap_angle
	RightFlap.rotation_degrees.x = current_flap_angle


func flaps_range_min() -> float:
	return 90


func flaps_range_max() -> float:
	return 125


# Airbrake Functions #
func setAirbrake(input: bool):
	if input:
		Airbrake_target_angle = ab_range_min()
	else:
		Airbrake_target_angle = ab_range_max()

	AirbrakeMoving = true


func MoveAirbrake(delta: float):
	Airbrake_Current_angle = lerp(Airbrake_Current_angle, Airbrake_target_angle, delta * Airbrake_Speed)
	if abs(Airbrake_Current_angle - Airbrake_target_angle) < 0.1:
		Airbrake_Current_angle = Airbrake_target_angle
		AirbrakeMoving = false

	Airbrake.rotation_degrees.x = Airbrake_Current_angle


func ab_range_min() -> float:
	return 60


func ab_range_max() -> float:
	return 90


# Elevator Functions #
func setElevatorPosition(input: float):
	var target = elevator_center + elevator_range * input
	target = clamp(target, elevator_min, elevator_max)

	target_l_elevator = target
	target_r_elevator = target
	LeftElevatorMoving = true
	RightElevatorMoving = true


func MoveLeftElevator(delta: float):
	l_elevator_current_angle = lerp(l_elevator_current_angle, target_l_elevator, l_elevator_speed * delta)
	LeftElevator.rotation_degrees.x = l_elevator_current_angle

	if abs(l_elevator_current_angle - target_l_elevator) < 0.1:
		l_elevator_current_angle = target_l_elevator
		LeftElevatorMoving = false


func MoveRightElevator(delta: float):
	r_elevator_current_angle = lerp(r_elevator_current_angle, target_r_elevator, r_elevator_speed * delta)
	RightElevator.rotation_degrees.x = r_elevator_current_angle

	if abs(r_elevator_current_angle - target_r_elevator) < 0.1:
		r_elevator_current_angle = target_r_elevator
		RightElevatorMoving = false


# Rudder Functions #
func setRudderPosition(input: float):
	target_rudder_angle = input
	RudderMoving = true


func MoveRudder(delta: float):
	rudder_current_angle = lerp(rudder_current_angle, target_rudder_angle, rudder_speed * delta)

	LeftRudder.rotation_degrees.y = rudder_current_angle
	RightRudder.rotation_degrees.y = rudder_current_angle

	if abs(rudder_current_angle - target_rudder_angle) < 0.1:
		rudder_current_angle = target_rudder_angle
		RudderMoving = false


# Aileron Functions #
func Roll(input: float):
	L_target_ailerons_angle = ailerons_center + ailerons_range * input
	R_target_ailerons_angle = ailerons_center - ailerons_range * input
	L_AileronsMoving = true
	R_AileronsMoving = true


func MoveLeftAileron(delta: float):
	L_ailerons_current_angle = lerp(L_ailerons_current_angle, L_target_ailerons_angle, L_ailerons_speed * delta)
	LeftAileron.rotation_degrees.x = L_ailerons_current_angle

	if abs(L_ailerons_current_angle - L_target_ailerons_angle) < 0.1:
		L_ailerons_current_angle = L_target_ailerons_angle
		L_AileronsMoving = false


func MoveRightAileron(delta: float):
	R_ailerons_current_angle = lerp(R_ailerons_current_angle, R_target_ailerons_angle, R_ailerons_speed * delta)
	RightAileron.rotation_degrees.x = R_ailerons_current_angle

	if abs(R_ailerons_current_angle - R_target_ailerons_angle) < 0.1:
		R_ailerons_current_angle = R_target_ailerons_angle
		R_AileronsMoving = false


# Engine #
func handle_engine_audio():
	if not EngineAudio.is_playing():
		EngineAudio.play()
	EngineAudio.pitch_scale = power_to_pitch(aircraft.throttle_setting)
	if aircraft.throttle_setting >= 0.85:
		if not AfterburnerAudio.is_playing():
			AfterburnerAudio.play()
		AfterburnerAudio.volume_db = 20 * aircraft.throttle_setting
	else:
		AfterburnerAudio.stop()


func handle_engine_animation():
	var afterburner_on = aircraft.throttle_setting >= 0.85
	Afterburner1.visible = afterburner_on
	Afterburner2.visible = afterburner_on
	Exhaust_Left.visible = not afterburner_on
	Exhaust_Right.visible = not afterburner_on


func power_to_pitch(value: float) -> float:
	return 0.2 + value * 0.8


# Landing Gear #
func toggle_gear():
	if gear_down:
		Animation_Player.play("gear_up")
	else:
		Animation_Player.play("gear_down")
		
# Landing Gear #
func reset_gear(down: bool) -> void:
	if down:
		Animation_Player.play("RESET")
	else:
		Animation_Player.play("RESET_UP")		
