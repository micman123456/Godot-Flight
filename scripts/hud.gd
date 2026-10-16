extends Control

@export var aircraft : Aircraft
@export var camera : Camera3D

@onready var lv_label = $VBoxContainer/lv
@onready var lift_label = $VBoxContainer/lift
@onready var lift_yaw_label = $VBoxContainer/lift_yaw
@onready var drag_label = $VBoxContainer/drag
@onready var drag_coe_label = $VBoxContainer/drag_coe
@onready var lift_coe_label = $VBoxContainer/lift_coe
@onready var thurst_label = $VBoxContainer/thrust

@onready var boresight = $Boresight
@onready var velocity = $VelocityMarker
@onready var throttle_container = $ThrottleContainer
@onready var AltSpeedContainer = $AltSpeedContainer
@onready var Alt_Label = $AltSpeedContainer/Alt
@onready var Spd_Label = $AltSpeedContainer/Speed
@onready var throttle_meter = $ThrottleContainer/TickSmall
@onready var Auto_Throttle_Cont = $Auto_Throttle_Cont
@onready var Auto_Throttle_Label = $Auto_Throttle_Cont/Auto_Throttle_Label

@onready var Gear_Cont = $Gear_Cont
@onready var Gear_Cont_Label = $Gear_Cont/Gear_Label
@onready var Debug_Container = $Debug_Container

const debug_item_count = 12

func _ready() -> void:
	create_debug()

func _physics_process(delta: float) -> void:
	if aircraft:
		handle_hud_controls(delta)
		
		update_debug()
		Alt_Label.text = "%d" % int(aircraft.global_position.y)
		Spd_Label.text = "%d" % int(aircraft.forward_air_speed)
		
		
		project_2D_elemnt(boresight,250,Vector2.ZERO)
		project_2D_elemnt(throttle_container,150,Vector2.ZERO)
		project_2D_elemnt(AltSpeedContainer,150,Vector2(-190,-16))
		project_velocity(velocity)
		scale_throttle_meter(delta)


func project_2D_elemnt(element:Node,distance:float,offset:Vector2):
	if camera:
		var element_world_pos = aircraft.global_position + distance*aircraft.global_transform.basis.z
		var element_screen_pos = camera.unproject_position(element_world_pos)
		element.position = element_screen_pos + offset
		element.visible = camera.is_position_behind(element_world_pos)
	
		
func project_velocity(element:Node2D):
	if camera:
		var element_world_pos = aircraft.global_position + aircraft.linear_velocity
		var element_screen_pos = camera.unproject_position(element_world_pos)
		element.position = element_screen_pos
		element.visible = not camera.is_position_behind(element_world_pos)


func scale_throttle_meter(delta:float):
	var base_position = 119.5
	
	# for every 0.1 scale offset position 3 px
	var scaling_rate = 0.25
	var strength = 4.0
	var new_scale_y = clamp(aircraft.throttle_setting*strength, 0.0, 4.0)
	var new_position = base_position-base_position*new_scale_y*scaling_rate

	throttle_meter.scale.y = new_scale_y # lerp(throttle_meter.scale.y,new_scale,delta*2)
	throttle_meter.position.y = clamp(new_position,2,base_position)

func create_debug():
	if not Debug_Container:
		return

	for i in range(debug_item_count):
		var debug_label = Label.new()
		debug_label.text = "debug %d" % i
		Debug_Container.add_child(debug_label)

func update_debug():
	if not Debug_Container:
		return
	
	Debug_Container.get_child(0).text = "Linear Velocity: " + str(round(aircraft.linear_velocity))
	Debug_Container.get_child(1).text = "Local Velocity: " + str(round(aircraft.LocalVelocity))
	Debug_Container.get_child(2).text = "Local AVelocity: " + str(round(aircraft.LocalAngularVelocity))
	Debug_Container.get_child(3).text = "AOA: " + str(round(aircraft.AngleOfAttack))
	Debug_Container.get_child(4).text = "Drag " + str(round(aircraft.DragForce))
	Debug_Container.get_child(4).modulate = Color.RED
	Debug_Container.get_child(5).text = "Wing Lift " + str(round(aircraft.LiftForce))
	Debug_Container.get_child(6).text = "Yaw Lift " + str(round(aircraft.LiftForceYaw))
	Debug_Container.get_child(7).text = "Control Input: " + str(aircraft.control_input)
	Debug_Container.get_child(8).text = "Forward Airspeed: " + str(round(aircraft.forward_air_speed)) + " m/s"
	Debug_Container.get_child(9).text = "Sideslip: " + str(round(aircraft.AngleOfAttackYaw)) + " deg"
	Debug_Container.get_child(10).text = "Vertical Speed: " + str(round(aircraft.linear_velocity.y)) + " m/s"
	Debug_Container.get_child(11).text = "Throttle: " + str(round(aircraft.throttle_setting * 100.0)) + "%"
	Debug_Container.get_child(11).text = "torque: " + str(round(aircraft.torque))

func handle_hud_controls(delta:float):
	if Input.is_action_just_pressed("toggle_debug_info"):
		Debug_Container.visible = !Debug_Container.visible
		
