extends Camera3D

@export var objetivo: Node3D # Jugador 1 
@export var objetivo2: Node3D # Jugador 2 
@export var altura_camara: float = 1.35 # Altura Y estilo 2.5D 
@export var distancia_base: float = 7.2 # Distancia Z a los luchadores
@export var inclinacion_grados: float = -3.5 # Ligera inclinación hacia abajo para anclar el suelo al borde inferior
@export var suavizado: float = 6.0
@export var limite_min = Vector2(-5.5, -10)
@export var limite_max = Vector2(5.5, 10)


func _ready():
	top_level = true
	_buscar_objetivos()
	var foco = calcular_foco()
	foco.x = clampf(foco.x, limite_min.x, limite_max.x)
	global_position = Vector3(foco.x, altura_camara, distancia_base)
	rotation_degrees = Vector3(inclinacion_grados, 0, 0)


func _buscar_objetivos():
	if objetivo == null or not is_instance_valid(objetivo):
		var jugadores = get_tree().get_nodes_in_group("jugador")
		if jugadores.size() > 0:
			objetivo = jugadores[0]
		else:
			objetivo = get_parent().get_node_or_null("Personaje")
	if objetivo2 == null or not is_instance_valid(objetivo2):
		var rivales = get_tree().get_nodes_in_group("rival")
		if rivales.size() > 0:
			objetivo2 = rivales[0]
		else:
			var luchadores = get_tree().get_nodes_in_group("luchador")
			for l in luchadores:
				if l != objetivo:
					objetivo2 = l
					break
		if objetivo2 == null:
			objetivo2 = get_parent().get_node_or_null("Rival")


func calcular_foco() -> Vector3:
	var v1_valido = objetivo != null and is_instance_valid(objetivo)
	var v2_valido = objetivo2 != null and is_instance_valid(objetivo2)

	if v1_valido and v2_valido:
		var p1 = objetivo.global_position
		var p2 = objetivo2.global_position
		return (p1 + p2) * 0.5
	elif v1_valido:
		return objetivo.global_position
	elif v2_valido:
		return objetivo2.global_position
	return global_position - Vector3(0, 0, distancia_base)


func _physics_process(delta):
	if objetivo == null or objetivo2 == null or not is_instance_valid(objetivo) or not is_instance_valid(objetivo2):
		_buscar_objetivos()

	var foco = calcular_foco()
	foco.x = clampf(foco.x, limite_min.x, limite_max.x)

	# Distancia dinámica tipo Mortal Kombat: amplía suavemente cuando se alejan
	var separacion = 4.0
	if objetivo != null and objetivo2 != null and is_instance_valid(objetivo) and is_instance_valid(objetivo2):
		separacion = absf(objetivo.global_position.x - objetivo2.global_position.x)
	var z_dinamico = clampf(distancia_base + (separacion - 4.0) * 0.22, 6.4, 8.4)

	var destino = Vector3(foco.x, altura_camara, z_dinamico)
	global_position = global_position.lerp(destino, suavizado * delta)
	rotation_degrees = Vector3(inclinacion_grados, 0, 0)
