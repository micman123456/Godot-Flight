class_name Airfoil
extends Node3D

@export var lift_power : float
@export var axis : Vector3 
@export var surface_area : float
@export var lift_curve : Curve
@export var Induced_Drag:float

const AIR_DENSITY_RHO = 1.225

func calulate_lift(air_velocity:Vector3,lift_direction:Vector3,angle_of_attack:float):
	angle_of_attack = clamp(angle_of_attack,-90,90)
	var air_velocity_sq = air_velocity.length_squared()
	var lift_coefficient = lift_curve.sample(angle_of_attack)
	var lift_force = lift_coefficient*lift_power*surface_area*((air_velocity_sq*AIR_DENSITY_RHO)/2)
	var lift = lift_force*lift_direction

	var induced_drag_force = lift_coefficient*lift_coefficient*Induced_Drag
	var induced_drag_dir = -lift_direction
	var drag = induced_drag_dir*induced_drag_force*air_velocity_sq
	
	return lift + drag
	
	
	
