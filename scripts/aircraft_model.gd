extends Node3D



@export var aircraft : Aircraft 


var flap_step: int = 10

var elevator_min = 65
var elevator_max = 115
var elevator_center = 90
var elevator_range: int = 25

var ailerons_min = 75
var ailerons_max = 105
var ailerons_center = 90
var ailerons_range: int = 25

@export var LiftFactorFlap1: float = 0.0005
@export var LiftFactorFlap2: float = 0.001

@export var DragFactorFlap1: float = 0.005
@export var DragFactorFlap2: float = 0.01

@export var EngineSoundLoop: AudioStream

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



# Moving states for Components
var FlapsMoving: bool = false
var LeftElevatorMoving: bool = false
var RightElevatorMoving: bool = false
var RudderMoving: bool = false


# Angle states and speed for Components
var current_flap_angle: float = 90  # Current angle of the flaps
var target_flap_angle: float = 90  # Target angle for the flaps
var flap_speed: float = 5.0  # Speed of the flap movement

var l_elevator_current_angle: float = 90  # Current angle of the left elevator
var r_elevator_current_angle: float = 90  # Current angle of the right elevator
var target_l_elevator: float = 90  # Target angle for the left elevator
var target_r_elevator: float = 90  # Target angle for the right elevator
var l_elevator_speed: float = 30.0  # Speed of the left elevator
var r_elevator_speed: float = 30.0  # Speed of the right elevator

var rudder_current_angle: float = 0  # Current angle of the rudder
var target_rudder_angle: float = 0  # Target angle for the rudder
var rudder_speed: float = 30.0  # Speed of the rudder movement

var L_ailerons_current_angle: float = 90  # Current angle of the ailerons
var L_target_ailerons_angle: float = 0  # Target angle for the ailerons
var L_ailerons_speed: float = 30.0  # Speed of the ailerons movement
var L_AileronsMoving: bool = false

var R_ailerons_current_angle: float = 90  # Current angle of the ailerons
var R_target_ailerons_angle: float = 0  # Target angle for the ailerons
var R_ailerons_speed: float = 30.0  # Speed of the ailerons movement
var R_AileronsMoving: bool = false

var Airbrake_Current_angle: float = 90
var Airbrake_target_angle: float = 70
var Airbrake_Speed = 15.0
var AirbrakeMoving : bool = false
var AirbrakeDeployed : bool = false

func _ready():
	aircraft.connect("update_air_devices", Callable(self, "update_air_devices"))
	if EngineAudio and EngineSoundLoop:
		EngineAudio.stream = EngineSoundLoop
		EngineAudio.volume_db = 10


func _on_control_surface_update(axis: String, value: float):
	if axis == "elevator":
		var input = elevator_center + elevator_range*value
		setElevatorPosition(input) 
	elif axis == "aileron":
		Roll(value)
	elif axis == "rudder":
		setRudderPosition(remap(value, -1, 1, -30, 30)) 

func update_control_input(input:Vector3):
	setElevatorPosition(-input.x)
	Roll(-input.z)
	setRudderPosition(remap(-input.y, -1, 1, -30, 30))

func update_air_devices():
	setFlaps(aircraft.flaps_deployed)
	setAirbrake(aircraft.airbrake_deployed)
	


func _process(delta: float) -> void:
	if aircraft:
		update_control_input(aircraft.effective_input)
		handle_engine_audio()
	
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
		


func resetRoll():
	# Neutralize the ailerons
	L_target_ailerons_angle = 90
	R_target_ailerons_angle = 90
	L_AileronsMoving = true
	R_AileronsMoving = true

# Flap Functions #
func setFlaps(input:bool):
	if input:
		target_flap_angle = flaps_range_max()
	else:
		target_flap_angle = flaps_range_min()
	
	FlapsMoving = true

func setAirbrake(input:bool):
	if input:
		Airbrake_target_angle = ab_range_min()
	else:
		Airbrake_target_angle = ab_range_max()
	
	AirbrakeMoving = true
	
	

func MoveFlaps(delta: float):
	# Smoothly interpolate the current flap angle toward the target angle
	current_flap_angle = lerp(current_flap_angle, target_flap_angle, flap_speed * delta)
	
	if abs(current_flap_angle - target_flap_angle) < 0.1:
		current_flap_angle = target_flap_angle
		FlapsMoving = false
	
	# Apply the rotation to the flaps
	LeftFlap.rotation_degrees.x = current_flap_angle
	RightFlap.rotation_degrees.x = current_flap_angle
		
	# Check if the flaps have reached the target position


func MoveAirbrake(delta : float):
	Airbrake_Current_angle = lerp(Airbrake_Current_angle,Airbrake_target_angle,delta*Airbrake_Speed)
	if abs(Airbrake_Current_angle - Airbrake_target_angle) < 0.1:
		Airbrake_Current_angle = Airbrake_target_angle
		AirbrakeMoving = false
	
	Airbrake.rotation_degrees.x = Airbrake_Current_angle
	


func flaps_range_min() -> float:
	return 90

func flaps_range_max() -> float:
	return 125

func ab_range_min() -> float:
	return 60

func ab_range_max() -> float:
	return 90
	
# Elevator Functions 

func setElevatorPosition(input: float):
	var target = elevator_center + elevator_range*input
	target = clamp(target,elevator_min,elevator_max)
	
	target_l_elevator = target
	target_r_elevator = target
	LeftElevatorMoving = true
	RightElevatorMoving = true
	
	

func MoveLeftElevator(delta: float):
	# Smoothly interpolate the current left elevator angle toward the target angle
	l_elevator_current_angle = lerp(l_elevator_current_angle, target_l_elevator, l_elevator_speed * delta)

	# Apply the rotation to the left elevator
	LeftElevator.rotation_degrees.x = l_elevator_current_angle

	# Check if the left elevator has reached the target position
	if abs(l_elevator_current_angle - target_l_elevator) < 0.1:
		l_elevator_current_angle = target_l_elevator
		LeftElevatorMoving = false

func MoveRightElevator(delta: float):
	# Smoothly interpolate the current right elevator angle toward the target angle
	r_elevator_current_angle = lerp(r_elevator_current_angle, target_r_elevator, r_elevator_speed * delta)

	# Apply the rotation to the right elevator
	RightElevator.rotation_degrees.x = r_elevator_current_angle

	# Check if the right elevator has reached the target position
	if abs(r_elevator_current_angle - target_r_elevator) < 0.1:
		r_elevator_current_angle = target_r_elevator
		RightElevatorMoving = false

func MoveBothElevators(delta: float):
	# Move both elevators simultaneously
	MoveLeftElevator(delta)
	MoveRightElevator(delta)
	

# Rudder functions

func setRudderPosition(input: float):
	target_rudder_angle = input
	RudderMoving = true

func MoveRudder(delta: float):
	# Smoothly interpolate the current rudder angle toward the target angle
	rudder_current_angle = lerp(rudder_current_angle, target_rudder_angle, rudder_speed * delta)

	# Apply the rotation to the rudder
	LeftRudder.rotation_degrees.y = rudder_current_angle
	RightRudder.rotation_degrees.y = rudder_current_angle

	# Check if the rudder has reached the target position
	if abs(rudder_current_angle - target_rudder_angle) < 0.1:
		rudder_current_angle = target_rudder_angle
		RudderMoving = false

# Aileron Functions

func Roll(input: float):
	
	L_target_ailerons_angle = ailerons_center + ailerons_range*input
	R_target_ailerons_angle = ailerons_center - ailerons_range*input
	L_AileronsMoving = true
	R_AileronsMoving = true

func MoveLeftAileron(delta: float):
	# Smoothly interpolate the current left elevator angle toward the target angle
	L_ailerons_current_angle = lerp(L_ailerons_current_angle, L_target_ailerons_angle, L_ailerons_speed * delta)

	# Apply the rotation to the left elevator
	LeftAileron.rotation_degrees.x = L_ailerons_current_angle

	# Check if the left elevator has reached the target position
	if abs(L_ailerons_current_angle - L_target_ailerons_angle) < 0.1:
		L_ailerons_current_angle = L_target_ailerons_angle
		L_AileronsMoving = false

func MoveRightAileron(delta: float):
	# Smoothly interpolate the current left elevator angle toward the target angle
	R_ailerons_current_angle = lerp(R_ailerons_current_angle, R_target_ailerons_angle, R_ailerons_speed * delta)
	

	# Apply the rotation to the left elevator
	RightAileron.rotation_degrees.x = R_ailerons_current_angle

	# Check if the left elevator has reached the target position
	if abs(R_ailerons_current_angle - R_target_ailerons_angle) < 0.1:
		R_ailerons_current_angle = R_target_ailerons_angle
		R_AileronsMoving = false

func handle_engine_audio():
	if not EngineAudio.is_playing():
		EngineAudio.play()
	EngineAudio.pitch_scale = power_to_pitch(aircraft.throttle_setting)
		


func power_to_pitch(value: float) -> float:
	return 0.2 + value*0.8


	
