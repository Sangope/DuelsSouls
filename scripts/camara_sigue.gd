extends Camera3D

@export var objetivo: Node3D # Jugador 1
@export var objetivo2: Node3D # Jugador 2
@export var altura_camara: float = 1.18 # Altura Y cercana estilo Mortal Kombat 2.5D
@export var distancia_base: float = 5.0 # Distancia Z cercana a los luchadores
@export var inclinacion_grados: float = -2.8 # Inclinacion para anclar el suelo al borde inferior
@export var suavizado: float = 6.5
@export var limite_min = Vector2(-2.1, -10)
@export var limite_max = Vector2(2.1, 10)

var _tiempo_sacudida: float = 0.0
var _duracion_sacudida: float = 0.0
var _intensidad_sacudida: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready():
	top_level = true
	_rng.randomize()
	_buscar_objetivos()
	var foco = calcular_foco()
	foco.x = clampf(foco.x, limite_min.x, limite_max.x)
	global_position = Vector3(foco.x, altura_camara, distancia_base)
	rotation_degrees = Vector3(inclinacion_grados, 0, 0)


func sacudir(intensidad: float = 0.075, duracion: float = 0.13) -> void:
	_intensidad_sacudida = maxf(_intensidad_sacudida, intensidad)
	_duracion_sacudida = maxf(0.01, duracion)
	_tiempo_sacudida = _duracion_sacudida


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

	# Encuadre cercano tipo Mortal Kombat: se acerca en combate corto y abre si se alejan a los pilares
	var separacion = 3.4
	if objetivo != null and objetivo2 != null and is_instance_valid(objetivo) and is_instance_valid(objetivo2):
		separacion = absf(objetivo.global_position.x - objetivo2.global_position.x)
	var z_dinamico = clampf(distancia_base + (separacion - 3.4) * 0.28, 4.55, 6.2)

	var offset_sacudida := Vector3.ZERO
	if _tiempo_sacudida > 0.0:
		_tiempo_sacudida = maxf(0.0, _tiempo_sacudida - delta)
		var factor := _tiempo_sacudida / _duracion_sacudida
		offset_sacudida = Vector3(
			_rng.randf_range(-1.0, 1.0) * _intensidad_sacudida * factor,
			_rng.randf_range(-0.7, 0.7) * _intensidad_sacudida * factor,
			0.0
		)
		if _tiempo_sacudida <= 0.0:
			_intensidad_sacudida = 0.0

	var destino = Vector3(foco.x, altura_camara, z_dinamico)
	global_position = global_position.lerp(destino, suavizado * delta) + offset_sacudida
	rotation_degrees = Vector3(inclinacion_grados, 0, 0)
