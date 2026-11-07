extends Node
 
enum Accion { ATACAR, CARGAR, DEFENDER, GOLPE_FUERTE, CURARSE }
 
@export var ritmo = 0.8
@export var danio = 10
@export var cuantos_turnos = 8
@export var patron: Array[int] = [0, 0, 2, 1]
@export var vida = 100
@export var vida_baja = 40
@export var curas = 2
@export var cura = 30
# De cada 100 turnos normales, cuántos va a cada acción.
@export var pesos: Array[int] = [60, 20, 20]
@export var semilla = 7
@export var factor_acelera = 0.75
 
var rng = RandomNumberGenerator.new()
var veces = [0, 0, 0]
var indice = 0
var turno_numero = 0
var reloj = 0.0
var cargado = false
 
func _ready():
	rng.seed = semilla
	reloj = ritmo
 
func _physics_process(delta):
	if turno_numero >= cuantos_turnos:
		return
	reloj -= delta
	if reloj <= 0.001:
		reloj = ritmo
		jugar_turno()
 
func jugar_turno():
	turno_numero += 1
	var accion = decidir()
	print("turno ", turno_numero, ": ", Accion.keys()[accion],
		" (vida ", vida, ")")
	match accion:
		Accion.ATACAR:
			print("  ataca: ", danio, " de daño")
		Accion.CARGAR:
			cargado = true
			print("  carga fuerzas")
		Accion.DEFENDER:
			print("  se defiende")
		Accion.GOLPE_FUERTE:
			cargado = false
			print("  golpe fuerte: ", danio * 2, " de daño")
		Accion.CURARSE:
			curas -= 1
			vida += cura
			print("  se cura: vida ", vida)
	if turno_numero == cuantos_turnos:
		print("veces: ", veces)
 
func decidir():
	if cargado:
		return Accion.GOLPE_FUERTE
	if vida <= vida_baja and curas > 0:
		return Accion.CURARSE
	var a = elegir_por_peso()
	veces[a] += 1
	return a
 
# Saca un número de 1 a la suma de los pesos y ve en qué tramo cayó.
func elegir_por_peso():
	var total = 0
	for p in pesos:
		total += p
	var sale = rng.randi_range(1, total)
	var acumulado = 0
	for i in range(pesos.size()):
		acumulado += pesos[i]
		if sale <= acumulado:
			return i
	return 0
 
# Cuando el jugador falla la pregunta, el enemigo se acelera.
func jugador_fallo():
	ritmo *= factor_acelera
	print("  falló: el turno ahora dura ", snappedf(ritmo, 0.01), " s")
 
func recibir_golpe(cuanto):
	vida -= cuanto
	print("  el enemigo recibe ", cuanto, ": vida ", vida)
 
