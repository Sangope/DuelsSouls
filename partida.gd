extends Node

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 90.0
# false: al acabarse el tiempo se pierde. true: sobrevivir gana.
@export var gana_con_tiempo = false
# Cuántas metas hay que cumplir para ganar. 0 = no se cuentan.
@export var metas = 2
@export var espera_reinicio = 2.0

# static: es del script, no del nodo. Sobrevive a recargar la escena.
static var intentos = 1
static var mejor = 0.0
static var rondas_ganadas = 0
static var fervor = 0

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0
var reloj = 0.0


func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite
	print("intento ", intentos, " · mejor tiempo ", snappedf(mejor, 0.01), " · rondas ", rondas_ganadas, " · fervor ", fervor)


func _physics_process(delta):
	if estado != Estado.JUGANDO:
		reloj -= delta
		if reloj <= 0.001:
			reiniciar()
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
	reloj = espera_reinicio
	var usado = tiempo_limite - tiempo
	if estado == Estado.GANO:
		rondas_ganadas += 1
		fervor = mini(fervor + 25, 100)
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado


func reiniciar():
	intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
