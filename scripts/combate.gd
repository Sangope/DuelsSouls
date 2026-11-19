class_name Combate
extends Node

## Sistema de combate cuerpo a cuerpo 2.5D para cada luchador.
## La HitboxAtaque (Area3D) sigue fisicamente el hueso 3D de la espada (Paladin)
## o del puno (Vampiro) en cada cuadro de la animacion y aplica el dano
## exactamente cuando la hoja/puno baja e impacta contra el cuerpo del rival.

@export_group("Ataque Principal")
@export var accion_ataque_1: String = "p1_ataque_1"
@export var anim_ataque_1: String = "attack"
@export var danio_1: int = 20
@export var alcance_1: float = 1.75
@export var duracion_1: float = 0.68
@export var momento_golpe_1: float = 0.31
@export var velocidad_anim_1: float = 1.85

@export_group("Defensa")
@export var accion_cubrirse: String = "p1_cubrirse"
@export var anim_cubrirse: String = "block"
@export var velocidad_anim_cubrirse: float = 1.6
@export var empuje_bloqueo: float = 0.45

@export_group("Tiempos")
@export var enfriamiento: float = 0.15
@export var duracion_aturdimiento: float = 0.28

var _pj: Node = null
var _salud: Node = null
var _atacando: bool = false
var _cubriendose: bool = false
var _aturdido: bool = false
var _muerto: bool = false
var _tiempo: float = 0.0
var _tiempo_aturdido: float = 0.0
var _enfriamiento_restante: float = 0.0
var _golpe_aplicado: bool = false
var _vida_anterior: int = 100

var _anim_actual: String = ""
var _danio_actual: int = 0
var _alcance_actual: float = 1.75
var _duracion_actual: float = 0.68
var _momento_actual: float = 0.31

var _hitbox: Area3D = null
var _hitbox_col: CollisionShape3D = null
var _skeleton: Skeleton3D = null
var _idx_mano: int = -1
var _idx_espada: int = -1


func _ready() -> void:
	_pj = get_parent()
	if _pj == null:
		return
	_sincronizar_controles()
	_hitbox = _pj.get_node_or_null("HitboxAtaque")
	if _hitbox:
		_hitbox_col = _hitbox.get_node_or_null("CollisionShape3D")
		if _hitbox_col:
			# En reposo y en el frame 0 la hitbox de la espada/puno empieza APAGADA
			_hitbox_col.disabled = true
	_configurar_seguimiento_arma()
	_salud = _pj.get_node_or_null("Salud")
	if _salud:
		_vida_anterior = int(_salud.get("vida"))
		if _salud.has_signal("cambio"):
			_salud.connect("cambio", Callable(self, "_al_cambiar_vida"))


func _configurar_seguimiento_arma() -> void:
	var modelo: Node = _pj.get_node_or_null("Modelo")
	if modelo == null:
		return
	_skeleton = _buscar_skeleton(modelo)
	if _skeleton:
		_idx_mano = _skeleton.find_bone("mixamorig_RightHand")
		_idx_espada = _skeleton.find_bone("mixamorig_Sword_joint")
		_actualizar_posicion_hitbox_arma()


func _buscar_skeleton(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_skeleton(hijo)
		if encontrado:
			return encontrado
	return null


func _actualizar_posicion_hitbox_arma() -> void:
	if _hitbox == null or _skeleton == null or not is_inside_tree() or not _skeleton.is_inside_tree():
		return

	if _idx_espada >= 0 and _idx_mano >= 0:
		# Paladin: la Hitbox sigue la hoja 3D de la espada desde la empuñadura hasta la punta
		var pose_mano := _skeleton.get_bone_global_pose(_idx_mano)
		var pose_espada := _skeleton.get_bone_global_pose(_idx_espada)
		var pos_mano: Vector3 = _skeleton.global_transform * pose_mano.origin
		var pos_espada: Vector3 = _skeleton.global_transform * pose_espada.origin
		var dir_hoja: Vector3 = pos_espada - pos_mano
		if dir_hoja.length_squared() > 0.0001:
			dir_hoja = dir_hoja.normalized()
		else:
			dir_hoja = (-_pj.global_basis.z).normalized()
		var centro_hoja: Vector3 = pos_mano + dir_hoja * 0.48
		_hitbox.global_position = centro_hoja
		var arriba := Vector3.UP if absf(dir_hoja.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
		_hitbox.look_at(centro_hoja + dir_hoja, arriba)
	elif _idx_mano >= 0:
		# Vampiro: la Hitbox sigue el hueso 3D del puno derecho
		var pose_mano := _skeleton.get_bone_global_pose(_idx_mano)
		var pos_mano: Vector3 = _skeleton.global_transform * pose_mano.origin
		var frente: Vector3 = (-_pj.global_basis.z).normalized()
		var centro_puno: Vector3 = pos_mano + frente * 0.24
		_hitbox.global_position = centro_puno
		_hitbox.look_at(centro_puno + frente, Vector3.UP)


func _sincronizar_controles() -> void:
	var jid: Variant = _pj.get("jugador_id")
	var es_p2: bool = typeof(jid) == TYPE_INT and jid == 2
	if es_p2:
		if accion_ataque_1 == "p1_ataque_1" or accion_ataque_1 == "":
			accion_ataque_1 = "p2_ataque_1"
		if accion_cubrirse == "p1_cubrirse" or accion_cubrirse == "":
			accion_cubrirse = "p2_cubrirse"
	else:
		if accion_ataque_1 == "":
			accion_ataque_1 = "p1_ataque_1"
		if accion_cubrirse == "":
			accion_cubrirse = "p1_cubrirse"

	var poc: Node = _pj.get_node_or_null("Pocion")
	if poc:
		poc.set("tecla", "p2_pocion" if es_p2 else "p1_pocion")


func esta_atacando() -> bool:
	return _atacando


func esta_cubriendose() -> bool:
	return _cubriendose


func _etiqueta_jugador(nodo: Node) -> String:
	if nodo == null:
		return "Luchador"
	var jid: Variant = nodo.get("jugador_id")
	if typeof(jid) == TYPE_INT:
		return "Jugador %d" % jid
	return str(nodo.name)


func _physics_process(delta: float) -> void:
	_actualizar_posicion_hitbox_arma()

	if _enfriamiento_restante > 0.0:
		_enfriamiento_restante = maxf(0.0, _enfriamiento_restante - delta)

	if _muerto:
		if _cubriendose:
			_dejar_de_cubrirse(false)
		return

	if _aturdido:
		if _cubriendose:
			_dejar_de_cubrirse(false)
		_tiempo_aturdido -= delta
		if _tiempo_aturdido <= 0.0:
			_aturdido = false
			if _pj and _pj.get("accion") == "impact":
				_limpiar_accion_pj()
		return

	if _atacando:
		_actualizar_ataque(delta)
		return

	_actualizar_bloqueo()
	if _cubriendose:
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
			velocidad_anim_1
		)


func _actualizar_bloqueo() -> void:
	var quiere_cubrirse: bool = (
		_puede_cubrirse()
		and InputMap.has_action(accion_cubrirse)
		and Input.is_action_pressed(accion_cubrirse)
	)
	if quiere_cubrirse:
		if not _cubriendose:
			_empezar_a_cubrirse()
	elif _cubriendose:
		_dejar_de_cubrirse(true)


func _puede_cubrirse() -> bool:
	if _pj == null:
		return false
	if _salud and int(_salud.get("vida")) <= 0:
		return false
	if _pj.has_method("is_on_floor") and not _pj.call("is_on_floor"):
		return false
	var accion_pj: Variant = _pj.get("accion")
	if typeof(accion_pj) == TYPE_STRING and accion_pj != "" and accion_pj != anim_cubrirse:
		return false
	return true


func _empezar_a_cubrirse() -> void:
	_cubriendose = true
	_pj.set("multiplicador", 0.0)
	_asignar_accion_pj(anim_cubrirse, velocidad_anim_cubrirse)
	print("%s se está cubriendo" % _etiqueta_jugador(_pj))


func _dejar_de_cubrirse(reportar: bool) -> void:
	_cubriendose = false
	if _pj:
		if _pj.get("accion") == anim_cubrirse:
			_limpiar_accion_pj()
		if _pj.get("accion") != "pick-up":
			_pj.set("multiplicador", 1.0)
		if reportar:
			print("%s dejó de cubrirse" % _etiqueta_jugador(_pj))


func _puede_atacar() -> bool:
	if _pj == null or _enfriamiento_restante > 0.0 or _cubriendose:
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
	velocidad: float
) -> void:
	# FASE 1 (Frame 0 - Preparacion):
	# El personaje levanta la espada o arma el puno, pero la Hitbox sigue APAGADA.
	_atacando = true
	_tiempo = 0.0
	_golpe_aplicado = false
	_anim_actual = nombre_anim
	_danio_actual = danio
	_alcance_actual = alcance
	_duracion_actual = duracion
	_momento_actual = momento
	if _hitbox_col:
		_hitbox_col.disabled = true
	_asignar_accion_pj(nombre_anim, velocidad)
	var tipo_golpe: String = "golpe de puño" if nombre_anim == "punch" else "golpe con espada"
	print("%s lanzó %s" % [_etiqueta_jugador(_pj), tipo_golpe])


func _actualizar_ataque(delta: float) -> void:
	if _pj == null or _pj.get("accion") != _anim_actual:
		_atacando = false
		if _hitbox_col:
			_hitbox_col.disabled = true
		return

	_tiempo += delta

	# FASE 2 (Tajo / Golpe Activo):
	# Cuando la espada baja hacia el frente (momento_golpe_1 = 0.31 s en Paladin,
	# que corresponde a ~0.58 s de la animacion cuando la hoja ya bajo frente al rival),
	# se ENCIENDE la Hitbox que viaja con la espada y aplica el impacto.
	if not _golpe_aplicado and _tiempo >= _momento_actual:
		_golpe_aplicado = true
		if _hitbox_col:
			_hitbox_col.disabled = false
		_actualizar_posicion_hitbox_arma()
		_aplicar_golpe()

	# FASE 3 (Recuperacion):
	# Terminado el tajo activo (+0.14 s), se vuelve a APAGAR la Hitbox de la espada/puno.
	if _golpe_aplicado and _hitbox_col and not _hitbox_col.disabled and _tiempo >= _momento_actual + 0.14:
		_hitbox_col.disabled = true

	if _tiempo >= _duracion_actual:
		_terminar_ataque()


func _terminar_ataque() -> void:
	_atacando = false
	_enfriamiento_restante = enfriamiento
	if _hitbox_col:
		_hitbox_col.disabled = true
	if _pj and _pj.get("accion") == _anim_actual:
		_limpiar_accion_pj()


func _obtener_alcance_hitbox() -> float:
	if _hitbox_col and _hitbox_col.shape is BoxShape3D:
		var box := _hitbox_col.shape as BoxShape3D
		# Si el usuario escala el largo (size.z) de la caja en el editor, escala proporcionalmente el alcance
		var base_z: float = 0.95 if _idx_espada >= 0 else 0.65
		return _alcance_actual * (box.size.z / base_z)
	return _alcance_actual


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
	var alcance_efectivo: float = _obtener_alcance_hitbox()

	# Comprobar superposicion fisica de la Hitbox del arma o alcance de la hoja
	var toca_por_area: bool = false
	if _hitbox and _hitbox.monitoring and objetivo is PhysicsBody3D:
		toca_por_area = _hitbox.overlaps_body(objetivo)

	if not toca_por_area and distancia_x > alcance_efectivo:
		print("%s falló el golpe (fuera de alcance)" % _etiqueta_jugador(_pj))
		return

	if distancia_x > 0.35 and signf(dx) != signf(mirando_x):
		print("%s falló el golpe (fuera de alcance)" % _etiqueta_jugador(_pj))
		return

	var dy: float = objetivo.global_position.y - _pj.global_position.y
	if dy < -0.55 or dy > 1.45:
		print("%s falló el golpe (%s lo esquivó en el aire)" % [_etiqueta_jugador(_pj), _etiqueta_jugador(objetivo)])
		return

	var dir_empuje: float = signf(dx) if absf(dx) > 0.05 else signf(mirando_x)

	# Punto de impacto real donde la hoja de la espada / puno toca al rival
	var altura_arma: float = clampf(
		(_hitbox.global_position.y - objetivo.global_position.y) if _hitbox else 1.0,
		0.75,
		1.25
	)
	var pos_impacto := Vector3(
		objetivo.global_position.x - dir_empuje * 0.22,
		objetivo.global_position.y + altura_arma,
		0.12
	)
	var escena_raiz: Node = _pj.get_parent() if _pj else null

	# Si el rival está cubriéndose de frente, bloquea todo el daño
	var c_obj: Node = objetivo.get_node_or_null("Combate")
	var mirando_obj: float = -objetivo.global_basis.z.x
	var bloquea_de_frente: bool = (absf(dx) <= 0.35) or (signf(-dx) == signf(mirando_obj))
	if c_obj and c_obj.has_method("esta_cubriendose") and c_obj.call("esta_cubriendose") and bloquea_de_frente:
		objetivo.set("empuje", Vector3(dir_empuje * empuje_bloqueo, 0.0, 0.0))
		EfectoSangre.crear_chispa_bloqueo(escena_raiz, pos_impacto, dir_empuje)
		print("%s dio golpe -> %s se cubrió (0 de daño)" % [_etiqueta_jugador(_pj), _etiqueta_jugador(objetivo)])
		return

	var vida_antes: int = int(s_obj.get("vida")) if s_obj else 0
	var puede_recibir: bool = true
	if s_obj and s_obj.has_method("puede_recibir_golpe"):
		puede_recibir = bool(s_obj.call("puede_recibir_golpe"))
	if puede_recibir and s_obj:
		var dano_aplicado: int = mini(_danio_actual, vida_antes)
		print("%s dio golpe -> %s -%d de vida" % [_etiqueta_jugador(_pj), _etiqueta_jugador(objetivo), dano_aplicado])
		EfectoSangre.crear_impacto_sangre(escena_raiz, pos_impacto, dir_empuje, 0.0)
	elif s_obj:
		print("%s atacó a %s, pero aún está invulnerable" % [_etiqueta_jugador(_pj), _etiqueta_jugador(objetivo)])

	if objetivo.has_method("recibir_golpe"):
		objetivo.call("recibir_golpe", _danio_actual)
	objetivo.set("empuje", Vector3(dir_empuje * 0.45, 0.0, 0.0))


func _al_cambiar_vida(nueva_vida: int) -> void:
	var dano_recibido: bool = nueva_vida < _vida_anterior
	_vida_anterior = nueva_vida

	if nueva_vida > 0 and _muerto:
		_muerto = false
		_aturdido = false
		_cubriendose = false
		if _pj:
			_pj.set("multiplicador", 1.0)
		_limpiar_accion_pj()
		return

	if not dano_recibido or _pj == null:
		return

	_atacando = false
	if _hitbox_col:
		_hitbox_col.disabled = true
	if _cubriendose:
		_dejar_de_cubrirse(false)

	if nueva_vida <= 0:
		_muerto = true
		_aturdido = false
		_pj.set("multiplicador", 0.0)
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
