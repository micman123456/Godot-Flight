extends Node

static func scale6(
	value: Vector3,
	pos_x: float, neg_x: float,
	pos_y: float, neg_y: float,
	pos_z: float, neg_z: float
) -> Vector3:
	var result = value

	if result.x > 0.0:
		result.x *= pos_x
	elif result.x < 0.0:
		result.x *= neg_x

	if result.y > 0.0:
		result.y *= pos_y
	elif result.y < 0.0:
		result.y *= neg_y

	if result.z > 0.0:
		result.z *= pos_z
	elif result.z < 0.0:
		result.z *= neg_z

	return result
	
static func project_on_plane(vector: Vector3, surface_normal: Vector3) -> Vector3:
	var axis1 = vector.cross(surface_normal).normalized()
	var axis2 = axis1.cross(-surface_normal).normalized()
	
	return vector.project(axis1) + vector.project(axis2)

static func has_nan(vec:Vector3):
	if is_nan(vec.x):
		return true
	elif is_nan(vec.y):
		return true
	elif is_nan(vec.z):
		return true
	return false
	
