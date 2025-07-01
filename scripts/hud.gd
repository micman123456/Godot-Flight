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

func _physics_process(delta: float) -> void:
	if aircraft:
		#lv_label.text = "Linear Velocity: " + str(aircraft.linear_velocity)
		#lift_label.text = "Local Velocity: " + str(aircraft.LocalVelocity)
		#lift_yaw_label.text = "Local AVelocity: " + str(aircraft.LocalAngularVelocity)
		#lift_yaw_label.text = "AOA: " + str(aircraft.AngleOfAttack)
		#drag_label.text = "Thr Setting: " + str(aircraft.throttle_setting)
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
