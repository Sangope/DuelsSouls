extends Camera3D

@export var objetivo: Node3D
@export var distancia = Vector3(0, 2.2, 12)
@export var suavizado = 5.0
@export var limite_min = Vector2(-2, -10) # x y z mínimas
@export var limite_max = Vector2(2, 10) # x y z máximas


func _ready():
	top_level = true
	# Se orienta UNA vez, mirando al objetivo.
	look_at_from_position(objetivo.global_position + distancia,
		objetivo.global_position)


func _physics_process(delta):
	var foco = objetivo.global_position
	foco.x = clamp(foco.x, limite_min.x, limite_max.x)
	foco.z = clamp(foco.z, limite_min.y, limite_max.y)
	var destino = foco + distancia
	global_position = global_position.lerp(destino, suavizado * delta)
