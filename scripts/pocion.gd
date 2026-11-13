extends Node

enum Estado { LISTA, ACTIVA, RECARGA }

@export var tecla = "pocion"
@export var duracion = 0.8
@export var recarga = 1.2
@export var curacion = 30
@onready var pj = get_parent()

var estado = Estado.LISTA
var tiempo = 0.0
var pociones = 2


func _etiqueta_jugador() -> String:
	if pj == null:
		return "Jugador"
	var jid: Variant = pj.get("jugador_id")
	if typeof(jid) == TYPE_INT:
		return "Jugador %d" % jid
	return str(pj.name)


func _physics_process(delta):
	tiempo -= delta
	match estado:
		Estado.LISTA:
			if InputMap.has_action(tecla) and Input.is_action_just_pressed(tecla):
				if puede():
					empezar()
				elif pociones <= 0 and pj != null and pj.is_on_floor():
					var salud = pj.get_node_or_null("Salud")
					if salud != null and int(salud.get("vida")) > 0:
						print("%s intentó usar poción, pero no le quedan" % _etiqueta_jugador())
		Estado.ACTIVA:
			if tiempo <= 0.001:   # 0.001 y no 0: restar 1/60 no da exacto
				terminar()
		Estado.RECARGA:
			if tiempo <= 0.001:
				estado = Estado.LISTA


func puede():
	if pociones <= 0 or pj == null:
		return false
	if pj.has_method("is_on_floor") and not pj.is_on_floor():
		return false
	var accion_pj = pj.get("accion")
	if typeof(accion_pj) == TYPE_STRING and accion_pj != "":
		return false
	var salud = pj.get_node_or_null("Salud")
	if salud != null and int(salud.get("vida")) <= 0:
		return false
	return true


func empezar():
	estado = Estado.ACTIVA
	tiempo = duracion
	pociones -= 1
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 0.0
	pj.accion = "pick-up"
	var salud = pj.get_node_or_null("Salud")
	var curado: int = 0
	if salud != null:
		var vida_antes: int = int(salud.vida)
		var vida_max: int = int(salud.vida_inicial) if int(salud.vida_inicial) > 0 else 100
		curado = mini(vida_antes + curacion, vida_max) - vida_antes
	print("%s usó poción -> +%d de vida (quedan %d)" % [_etiqueta_jugador(), curado, pociones])
	if salud != null and salud.has_method("curar"):
		salud.curar(curacion)


func terminar():
	estado = Estado.RECARGA
	tiempo = recarga
	pj.empuje = Vector3.ZERO
	pj.multiplicador = 1.0
	pj.accion = ""
	print("%s terminó de curarse" % _etiqueta_jugador())
