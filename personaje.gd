extends CharacterBody3D

enum Estado { QUIETO, CAMINAR, AIRE, CURANDO }
const RAPIDEZ_MAX = [0.0, 3.5, 3.5, 0.0] # rapidez máxima en m/s, en el orden del enum

@export_group("Luchador")
@export var jugador_id: int = 1
@export var speed_frente: float = 3.5
@export var speed_atras: float = 2.4
@export var tiempo_arranque: float = 0.2
@export var gravedad: float = 28.0
@export var altura_salto: float = 1.4
@export var limite_x_min: float = -13.5
@export var limite_x_max: float = 13.5
@export var rival: Node3D

@export_group("Controles")
@export var accion_izquierda: String = ""
@export var accion_derecha: String = ""
@export var accion_saltar: String = ""
@export var accion_pocion: String = ""

@onready var anim: AnimationPlayer = $Modelo/AnimationPlayer

# Enchufes: otros scripts (las acciones del juego) cambian estas tres variables.
var multiplicador: float = 1.0     # 1 = rapidez normal, 0.5 = la mitad, 0 = quieto
var empuje: Vector3 = Vector3.ZERO   # velocidad extra en m/s (dash, retroceso)
var accion: String = ""             # animación de la acción; "" = ninguna
var avance: float = 0.0            # la parte de la velocidad que dan las teclas
var estado: Estado = Estado.QUIETO
var rapidez_max: float = 0.0

# Propiedad para interoperabilidad con partida.gd y sistemas de combate
var vida: int:
	get:
		var s = get_node_or_null("Salud")
		if s != null and "vida" in s:
			return s.vida
		return 100


func _ready():
	_configurar_controles()
	_buscar_rival()
	global_position.z = 0.0


func _configurar_controles():
	if accion_izquierda == "":
		accion_izquierda = "p1_move_left" if jugador_id == 1 else "p2_move_left"
	if accion_derecha == "":
		accion_derecha = "p1_move_right" if jugador_id == 1 else "p2_move_right"
	if accion_saltar == "":
		accion_saltar = "p1_saltar" if jugador_id == 1 else "p2_saltar"
	if accion_pocion == "":
		accion_pocion = "p1_pocion" if jugador_id == 1 else "p2_pocion"

	# Fallbacks por compatibilidad con acciones genéricas
	if not InputMap.has_action(accion_izquierda):
		accion_izquierda = "move_left"
	if not InputMap.has_action(accion_derecha):
		accion_derecha = "move_right"
	if not InputMap.has_action(accion_saltar):
		accion_saltar = "saltar"
	if not InputMap.has_action(accion_pocion):
		accion_pocion = "pocion"


func _buscar_rival():
	if rival != null and is_instance_valid(rival):
		return
	for nodo in get_tree().get_nodes_in_group("luchador"):
		if nodo != self:
			rival = nodo
			return
	if jugador_id == 1:
		rival = get_parent().get_node_or_null("Rival")
	else:
		rival = get_parent().get_node_or_null("Personaje")


func _physics_process(delta):
	if rival == null or not is_instance_valid(rival):
		_buscar_rival()

	if not is_on_floor():
		velocity.y -= gravedad * delta
	elif Input.is_action_just_pressed(accion_saltar):
		velocity.y = sqrt(2 * gravedad * altura_salto)

	var lado = Input.get_axis(accion_izquierda, accion_derecha)
	var curando = is_on_floor() and Input.is_action_pressed(accion_pocion)

	# Orientación: mirar SIEMPRE al contrincante (no depende de la tecla)
	var hacia_rival_x = 1.0
	if rival != null and is_instance_valid(rival):
		hacia_rival_x = 1.0 if rival.global_position.x >= global_position.x else -1.0

	rotation.y = -PI / 2 if hacia_rival_x > 0 else PI / 2

	# Velocidad diferenciada: hacia el frente (3.5 m/s) o hacia atrás (2.4 m/s) sin darle la espalda
	var vel_tope = speed_frente
	if lado != 0:
		var se_mueve_al_frente = (sign(lado) == hacia_rival_x)
		vel_tope = speed_frente if se_mueve_al_frente else speed_atras

	var tope = 0.0 if curando else vel_tope
	var paso = vel_tope / tiempo_arranque * delta
	avance = move_toward(avance, lado * tope * multiplicador, paso)
	velocity.x = avance + empuje.x
	velocity.z = 0.0

	move_and_slide()

	# Limitar la posición X por código (clamp) por seguridad y asegurar Z = 0
	global_position.x = clampf(global_position.x, limite_x_min, limite_x_max)
	global_position.z = 0.0

	var antes = estado
	estado = elegir_estado()
	rapidez_max = RAPIDEZ_MAX[estado]
	if estado != antes:
		print(name, ": estado ", Estado.keys()[estado], " · rapidez_max ", rapidez_max, " m/s")
	animar()
	_prueba()


func elegir_estado():
	if not is_on_floor():
		return Estado.AIRE
	if Input.is_action_pressed(accion_pocion):
		return Estado.CURANDO
	var rapidez = absf(velocity.x)
	if rapidez < 0.1:
		return Estado.QUIETO
	return Estado.CAMINAR


func animar():
	if accion != "":
		if anim.has_animation(accion):
			anim.play(accion)
		elif anim.has_animation("attack"):
			anim.play("attack")
		return
	match estado:
		Estado.QUIETO:
			if anim.has_animation("idle"):
				anim.play("idle")
		Estado.CAMINAR:
			var hacia_rival_x = 1.0
			if rival != null and is_instance_valid(rival):
				hacia_rival_x = 1.0 if rival.global_position.x >= global_position.x else -1.0
			var retrocediendo = (sign(velocity.x) != 0 and sign(velocity.x) != hacia_rival_x)
			if retrocediendo:
				anim.play("walk", -1, -0.8)
			else:
				anim.play("walk", -1, 1.0)
		Estado.AIRE:
			if anim.has_animation("fall") and velocity.y <= 0:
				anim.play("fall")
			elif anim.has_animation("jump"):
				anim.play("jump")
		Estado.CURANDO:
			if anim.has_animation("pick-up"):
				anim.play("pick-up")


func recibir_golpe(danio):
	var salud = get_node_or_null("Salud")
	if salud != null and salud.has_method("recibir_golpe"):
		salud.recibir_golpe(danio)


# ---------------------------------------------------------------------------
# PRUEBAS AUTOMÁTICAS. En el Inspector del Personaje la opción "Prueba" queda
# en "Ninguna" (0) según el cronograma.
# ---------------------------------------------------------------------------
@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar 60 y soltar", "Avanzar y la acción desde el cuadro 30", "Mantener la acción 2 s", "Avanzar con la acción 60 cuadros", "Diagonal W+D 60 cuadros") var prueba = 0
@export var accion_prueba = ""
var _cuadro = 0
var _termino = false
var _y_max = 0.0
var _cuadro_max = 0


func _prueba():
	if prueba == 0 or _termino:
		return
	_cuadro += 1
	var avanzar = accion_derecha if accion_derecha != "" else "move_right"
	var lado = "move_up"
	if _cuadro == 1:
		if prueba <= 3 or prueba == 5:
			_apretar(avanzar)
		if prueba == 4 or prueba == 5:
			_apretar(accion_prueba)
		if prueba == 6:
			_apretar(avanzar)
			_apretar(lado)
		return
	var n = _cuadro - 1
	if prueba == 3 and n == 30:
		_apretar(accion_prueba)
	if prueba == 2 and n == 60:
		Input.action_release(avanzar)
	var marcas = []
	if prueba == 1 or prueba == 5:
		marcas = [1, 2, 3, 5, 10, 15, 20, 30, 60]
	elif prueba == 2:
		marcas = [59, 60, 61, 62, 63, 65, 70, 80, 90]
	elif prueba == 3:
		marcas = [29, 30, 31, 32, 33, 35, 40, 45, 50, 60, 75, 90]
	elif prueba == 6:
		marcas = [1, 30, 60]
	else:
		marcas = [1, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150]
	if n in marcas:
		print("[prueba] cuadro ", n, ": ", _resumen())
	_cambios(n)
	if global_position.y > _y_max + 0.0001:
		_y_max = global_position.y
		_cuadro_max = n
	if n == marcas[-1]:
		Input.action_release(avanzar)
		Input.action_release(lado)
		_soltar(accion_prueba)
		_termino = true
		if _y_max > 0.01:
			print("[prueba] altura máxima ", snappedf(_y_max, 0.01), " en el cuadro ", _cuadro_max)


func _resumen():
	var t = "posición " + str(global_position.snappedf(0.01))
	t += " · rapidez " + str(snappedf(absf(velocity.x), 0.01))
	t += " · y " + str(snappedf(global_position.y, 0.01))
	t += " · animación " + str(anim.current_animation)
	for nodo in _con_estado():
		t += " · " + str(nodo.name) + ".estado " + _nombre(nodo)
	return t


var _antes = {}


func _cambios(n):
	for nodo in _con_estado():
		var e = _nombre(nodo)
		if _antes.has(nodo) and _antes[nodo] != e:
			print("[prueba] cuadro ", n, ": ", nodo.name, ".estado cambia a ", e)
		_antes[nodo] = e


func _con_estado():
	var lista = []
	for nodo in [self] + get_children() + get_tree().get_nodes_in_group("probar"):
		if nodo.get_script() != null and "estado" in nodo:
			lista.append(nodo)
	return lista


func _nombre(nodo):
	var nombres = nodo.get_script().get_script_constant_map().get("Estado", {})
	for k in nombres:
		if nombres[k] == nodo.estado:
			return k
	return str(nodo.estado)


func _apretar(a):
	if a == "":
		print("[prueba] escriban el nombre de la acción en 'Accion Prueba'")
	elif not InputMap.has_action(a):
		print("[prueba] falta la acción '", a, "' en el Input Map")
	else:
		Input.action_press(a)


func _soltar(a):
	if a != "" and InputMap.has_action(a):
		Input.action_release(a)
