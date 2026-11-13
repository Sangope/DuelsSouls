class_name Combate
extends Node

## Sistema de combate cuerpo a cuerpo 2.5D para cada luchador.
## Maneja dos ataques independientes (principal y patada baja), aturdimiento
## por impacto, muerte y sincronizacion de controles segun el jugador.

@export_group("Ataque Principal")
@export var accion_ataque_1: String = "p1_ataque_1"
@export var anim_ataque_1: String = "attack"
@export var danio_1: int = 18
@export var alcance_1: float = 1.75
@export var duracion_1: float = 0.55
@export var momento_golpe_1: float = 0.22
@export var velocidad_anim_1: float = 1.8
@export var es_bajo_1: bool = false

@export_group("Patada Baja")
@export var accion_ataque_2: String = "p1_ataque_2"
@export var anim_ataque_2: String = "kick"
@export var danio_2: int = 10
@export var alcance_2: float = 1.50
@export var duracion_2: float = 0.42
@export var momento_golpe_2: float = 0.16
@export var velocidad_anim_2: float = 1.5
@export var es_bajo_2: bool = true

@export_group("Tiempos")
@export var enfriamiento: float = 0.15
@export var duracion_aturdimiento: float = 0.28

var _pj: Node = null
var _salud: Node = null
var _atacando: bool = false
var _aturdido: bool = false
var _muerto: bool = false
var _tiempo: float = 0.0
var _tiempo_aturdido: float = 0.0
var _enfriamiento_restante: float = 0.0
var _golpe_aplicado: bool = false
var _vida_anterior: int = 100

var _anim_actual: String = ""
var _danio_actual: int = 0
var _alcance_actual: float = 1.5
var _duracion_actual: float = 0.5
var _momento_actual: float = 0.2
var _es_bajo_actual: bool = false


func _ready() -> void:
	_pj = get_parent()
	if _pj == null:
		return
	_sincronizar_controles()
	_salud = _pj.get_node_or_null("Salud")
	if _salud:
		_vida_anterior = int(_salud.get("vida"))
		if _salud.has_signal("cambio"):
			_salud.connect("cambio", Callable(self, "_al_cambiar_vida"))


func _sincronizar_controles() -> void:
	var jid: Variant = _pj.get("jugador_id")
	var es_p2: bool = typeof(jid) == TYPE_INT and jid == 2
	if es_p2:
		if accion_ataque_1 == "p1_ataque_1" or accion_ataque_1 == "":
			accion_ataque_1 = "p2_ataque_1"
		if accion_ataque_2 == "p1_ataque_2" or accion_ataque_2 == "":
			accion_ataque_2 = "p2_ataque_2"
	else:
		if accion_ataque_1 == "":
			accion_ataque_1 = "p1_ataque_1"
		if accion_ataque_2 == "":
			accion_ataque_2 = "p1_ataque_2"

	# Sincronizar tecla de pocion con el jugador luego de personaje._ready()
	var poc: Node = _pj.get_node_or_null("Pocion")
	if poc:
		poc.set("tecla", "p2_pocion" if es_p2 else "p1_pocion")


func esta_atacando() -> bool:
	return _atacando


func _physics_process(delta: float) -> void:
	if _enfriamiento_restante > 0.0:
		_enfriamiento_restante = maxf(0.0, _enfriamiento_restante - delta)

	if _muerto:
		return

	if _aturdido:
		_tiempo_aturdido -= delta
		if _tiempo_aturdido <= 0.0:
			_aturdido = false
			if _pj and _pj.get("accion") == "impact":
				_limpiar_accion_pj()
		return

	if _atacando:
		_actualizar_ataque(delta)
		return

	if not _puede_atacar():
		return

	if InputMap.has_action(accion_ataque_1) and Input.is_action_just_pressed(accion_ataque_1):
		_iniciar_ataque(
			anim_ataque_1,
			danio_1,
			alcance_1,
			duracion_1,
			momento_golpe_1,
			velocidad_anim_1,
			es_bajo_1
		)
	elif InputMap.has_action(accion_ataque_2) and Input.is_action_just_pressed(accion_ataque_2):
		_iniciar_ataque(
			anim_ataque_2,
			danio_2,
			alcance_2,
			duracion_2,
			momento_golpe_2,
			velocidad_anim_2,
			es_bajo_2
		)


func _puede_atacar() -> bool:
	if _pj == null or _enfriamiento_restante > 0.0:
		return false
	if _salud and int(_salud.get("vida")) <= 0:
		return false
	var accion_pj: Variant = _pj.get("accion")
	if typeof(accion_pj) == TYPE_STRING and accion_pj != "":
		return false
	return true


func _iniciar_ataque(
	nombre_anim: String,
	danio: int,
	alcance: float,
	duracion: float,
	momento: float,
	velocidad: float,
	es_bajo: bool
) -> void:
	_atacando = true
	_tiempo = 0.0
	_golpe_aplicado = false
	_anim_actual = nombre_anim
	_danio_actual = danio
	_alcance_actual = alcance
	_duracion_actual = duracion
	_momento_actual = momento
	_es_bajo_actual = es_bajo
	_asignar_accion_pj(nombre_anim, velocidad)


func _actualizar_ataque(delta: float) -> void:
	if _pj == null or _pj.get("accion") != _anim_actual:
		_atacando = false
		return

	_tiempo += delta
	if not _golpe_aplicado and _tiempo >= _momento_actual:
		_golpe_aplicado = true
		_aplicar_golpe()

	if _tiempo >= _duracion_actual:
		_terminar_ataque()


func _terminar_ataque() -> void:
	_atacando = false
	_enfriamiento_restante = enfriamiento
	if _pj and _pj.get("accion") == _anim_actual:
		_limpiar_accion_pj()


func _aplicar_golpe() -> void:
	var objetivo: Node3D = _buscar_objetivo()
	if objetivo == null:
		return

	var s_obj: Node = objetivo.get_node_or_null("Salud")
	if s_obj and int(s_obj.get("vida")) <= 0:
		return

	var dx: float = objetivo.global_position.x - _pj.global_position.x
	var mirando_x: float = -_pj.global_basis.z.x
	var distancia_x: float = absf(dx)
	if distancia_x > _alcance_actual:
		return

	if distancia_x > 0.35 and signf(dx) != signf(mirando_x):
		return

	var dy: float = objetivo.global_position.y - _pj.global_position.y
	if _es_bajo_actual:
		if dy < -0.35 or dy > 0.60:
			return
	else:
		if dy < -0.55 or dy > 1.45:
			return

	if objetivo.has_method("recibir_golpe"):
		objetivo.call("recibir_golpe", _danio_actual)
	var dir_empuje: float = signf(dx) if absf(dx) > 0.05 else signf(mirando_x)
	objetivo.set("empuje", Vector3(dir_empuje * (0.28 if _es_bajo_actual else 0.35), 0.0, 0.0))


func _al_cambiar_vida(nueva_vida: int) -> void:
	var dano_recibido: bool = nueva_vida < _vida_anterior
	_vida_anterior = nueva_vida

	if nueva_vida > 0 and _muerto:
		_muerto = false
		_aturdido = false
		_limpiar_accion_pj()
		return

	if not dano_recibido or _pj == null:
		return

	_atacando = false
	if nueva_vida <= 0:
		_muerto = true
		_aturdido = false
		_asignar_accion_pj("die", 1.0)
	else:
		_aturdido = true
		_tiempo_aturdido = duracion_aturdimiento
		_asignar_accion_pj("impact", 1.35)


func _asignar_accion_pj(nombre: String, velocidad: float) -> void:
	if _pj.has_method("reproducir_accion"):
		_pj.call("reproducir_accion", nombre, velocidad)
	else:
		_pj.set("accion", nombre)


func _limpiar_accion_pj() -> void:
	if _pj.has_method("terminar_accion"):
		_pj.call("terminar_accion")
	else:
		_pj.set("accion", "")


func _buscar_objetivo() -> Node3D:
	var rival_ref: Variant = _pj.get("rival")
	if rival_ref is Node3D and is_instance_valid(rival_ref):
		return rival_ref
	for candidato in get_tree().get_nodes_in_group("luchador"):
		if candidato != _pj and candidato is Node3D:
			return candidato
	return null
