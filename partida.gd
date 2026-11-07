extends Node

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 90.0
# false: al acabarse el tiempo se pierde. true: sobrevivir gana.
@export var gana_con_tiempo = false
# Cuántas metas hay que cumplir para ganar. 0 = no se cuentan.
@export var metas = 2

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0


func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite


func _physics_process(delta):
	if estado != Estado.JUGANDO:
		return
	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		resolver_tiempo()


func resolver_tiempo():
	var pj = get_tree().get_first_node_in_group("jugador")
	var rival = get_parent().get_node_or_null("Rival")
	var salud = pj.get_node_or_null("Salud") if pj != null else null
	if salud != null and rival != null and "vida" in rival and salud.vida != rival.vida:
		if salud.vida > rival.vida:
			terminar(Estado.GANO, "más vida al acabar el tiempo")
		else:
			perder("menos vida al acabar el tiempo")
		return
	if gana_con_tiempo:
		ganar()
	else:
		perder("se acabó el tiempo")


# La llaman los objetivos del juego: no saben qué pasa después.
func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	if metas > 0 and hechas >= metas:
		ganar()


func ganar():
	terminar(Estado.GANO, "ganó")


func perder(motivo):
	terminar(Estado.PERDIO, motivo)


# La guarda: la partida termina una sola vez.
func terminar(nuevo, motivo):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ")")
	get_tree().paused = true
