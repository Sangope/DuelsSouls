extends Node

## Controlador de partida al Mejor de 3 Rounds (3 rounds maximos, gana quien llegue a 2)
## e integracion con la interfaz de inicio (boton PLAY).

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite: float = 90.0
@export var gana_con_tiempo: bool = false
@export var metas: int = 2
@export var espera_reinicio: float = 2.0
@export var max_rounds: int = 3
@export var rounds_para_ganar: int = 2
@export var iniciar_con_menu: bool = true

static var intentos: int = 1
static var mejor: float = 0.0
static var rondas_ganadas: int = 0
static var fervor: int = 0

var estado: int = Estado.JUGANDO
var en_menu: bool = true
var tiempo: float = 90.0
var hechas: int = 0
var reloj: float = 0.0

var round_actual: int = 1
var victorias_j1: int = 0
var victorias_j2: int = 0
var ganador_round: int = 0
var campeon_partida: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite
	round_actual = 1
	victorias_j1 = 0
	victorias_j2 = 0
	ganador_round = 0
	campeon_partida = 0
	en_menu = iniciar_con_menu
	if en_menu:
		print("=== Interfaz lista: presiona PLAY para iniciar partida (Mejor de 3) ===")
	else:
		_anunciar_inicio_round()


func iniciar_desde_menu() -> void:
	en_menu = false
	round_actual = 1
	victorias_j1 = 0
	victorias_j2 = 0
	ganador_round = 0
	campeon_partida = 0
	_restaurar_luchadores_para_round()
	tiempo = tiempo_limite
	estado = Estado.JUGANDO
	_anunciar_inicio_round()


func _anunciar_inicio_round() -> void:
	print("=== Combate iniciado · ROUND %d/%d (Mejor de 3) | Marcador: J1 [%d] - [%d] J2 ===" % [
		round_actual,
		max_rounds,
		victorias_j1,
		victorias_j2
	])


func _physics_process(delta: float) -> void:
	if en_menu:
		return

	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			_avanzar_tras_fin_de_round()
		return

	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		resolver_tiempo()


func resolver_tiempo() -> void:
	var pj := get_tree().get_first_node_in_group("jugador")
	var rival := get_parent().get_node_or_null("Rival") if get_parent() else null
	var salud := pj.get_node_or_null("Salud") if pj != null else null
	if salud != null and rival != null and "vida" in rival and salud.vida != rival.vida:
		if salud.vida > rival.vida:
			declarar_ganador(1, "por más vida al acabar el tiempo")
		else:
			declarar_ganador(2, "por más vida al acabar el tiempo")
		return
	if gana_con_tiempo:
		declarar_ganador(1, "sobrevivió el tiempo límite")
	else:
		ganador_round = 0
		terminar(Estado.PERDIO, "Empate en el Round %d al acabarse el tiempo" % round_actual)


func avisar_meta() -> void:
	if estado != Estado.JUGANDO or en_menu:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	if metas > 0 and hechas >= metas:
		ganar()


func declarar_ganador(ganador_id: int, motivo: String = "por KO") -> void:
	if estado != Estado.JUGANDO or en_menu:
		return
	ganador_round = ganador_id
	if ganador_id == 1:
		victorias_j1 += 1
	elif ganador_id == 2:
		victorias_j2 += 1

	# Determinar si ya hay campeon al Mejor de 3 (2 victorias, o tras el 3er round)
	if victorias_j1 >= rounds_para_ganar:
		campeon_partida = 1
	elif victorias_j2 >= rounds_para_ganar:
		campeon_partida = 2
	elif round_actual >= max_rounds and victorias_j1 != victorias_j2:
		campeon_partida = 1 if victorias_j1 > victorias_j2 else 2
	else:
		campeon_partida = 0

	var estado_final := Estado.GANO if ganador_id == 1 else Estado.PERDIO
	var msg_round := "ROUND %d/%d -> GANÓ EL JUGADOR %d (%s) | Marcador: J1 [%d] - [%d] J2" % [
		round_actual,
		max_rounds,
		ganador_id,
		motivo,
		victorias_j1,
		victorias_j2
	]
	terminar(estado_final, msg_round)
	if campeon_partida > 0:
		print("=== ¡FIN DE LA PARTIDA (MEJOR DE 3)! CAMPEÓN: JUGADOR %d (Marcador final: %d - %d) ===" % [
			campeon_partida,
			victorias_j1,
			victorias_j2
		])


func ganar() -> void:
	declarar_ganador(1, "victoria")


func ganar_por_ko(motivo: String = "por KO") -> void:
	declarar_ganador(1, motivo)


func perder(motivo: String) -> void:
	terminar(Estado.PERDIO, motivo)


func terminar(nuevo: int, motivo: String) -> void:
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("=== FIN DEL COMBATE: %s ===" % motivo)
	reloj = espera_reinicio
	var usado := tiempo_limite - tiempo
	if estado == Estado.GANO:
		rondas_ganadas += 1
		fervor = mini(fervor + 25, 100)
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado


func _avanzar_tras_fin_de_round() -> void:
	# Si aun no hay campeon de la serie al mejor de 3 y quedan rounds por jugar, pasar al siguiente round
	if campeon_partida == 0 and round_actual < max_rounds:
		round_actual += 1
		ganador_round = 0
		_restaurar_luchadores_para_round()
		tiempo = tiempo_limite
		estado = Estado.JUGANDO
		_anunciar_inicio_round()
		return

	# Si ya hubo campeon al Mejor de 3 (o se completaron los 3 rounds), volver al menu PLAY
	intentos += 1
	round_actual = 1
	victorias_j1 = 0
	victorias_j2 = 0
	ganador_round = 0
	campeon_partida = 0
	_restaurar_luchadores_para_round()
	tiempo = tiempo_limite
	estado = Estado.JUGANDO
	en_menu = true
	var hud := get_parent().get_node_or_null("HUD") if get_parent() else null
	if hud and hud.has_method("mostrar_menu_play"):
		hud.call("mostrar_menu_play")
	print("=== Partida finalizada: presiona PLAY para iniciar una nueva partida (Mejor de 3) ===")


func _restaurar_luchadores_para_round() -> void:
	var raiz := get_parent()
	if raiz == null:
		return
	var p1: Node3D = raiz.get_node_or_null("Personaje")
	var p2: Node3D = raiz.get_node_or_null("Rival")
	_restaurar_luchador(p1, Vector3(-1.85, 0.0, 0.0))
	_restaurar_luchador(p2, Vector3(1.85, 0.0, 0.0))


func _restaurar_luchador(pj: Node3D, pos_inicial: Vector3) -> void:
	if pj == null:
		return
	pj.global_position = pos_inicial
	if pj is CharacterBody3D:
		(pj as CharacterBody3D).velocity = Vector3.ZERO
	pj.set("empuje", Vector3.ZERO)
	pj.set("avance", 0.0)
	pj.set("multiplicador", 1.0)
	if pj.has_method("terminar_accion"):
		pj.call("terminar_accion")

	var salud := pj.get_node_or_null("Salud")
	if salud:
		var v_ini: int = int(salud.get("vida_inicial")) if int(salud.get("vida_inicial")) > 0 else 100
		salud.set("reloj", 0.0)
		salud.set("vida", v_ini)
		if salud.has_signal("cambio"):
			salud.emit_signal("cambio", v_ini)

	var combate := pj.get_node_or_null("Combate")
	if combate and combate.has_method("reiniciar_para_round"):
		combate.call("reiniciar_para_round")

	var pocion := pj.get_node_or_null("Pocion")
	if pocion:
		pocion.set("pociones", 2)
		pocion.set("estado", 0)
		pocion.set("tiempo", 0.0)
