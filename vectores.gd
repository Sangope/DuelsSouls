class_name Vectores


static func longitud(v: Vector3) -> float:
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z)


static func normalizar(v: Vector3) -> Vector3:
	var largo := longitud(v)
	if largo == 0.0:
		return Vector3.ZERO
	return v / largo
