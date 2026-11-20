extends Control

## Interfaz de inicio del juego: muestra unicamente el boton PLAY
## para comenzar la partida al mejor de 3 rounds.

signal play_presionado

@onready var boton_play: Button = $Centro/BotonPlay


func _ready() -> void:
	if boton_play:
		boton_play.pressed.connect(_al_presionar_play)
		if visible:
			boton_play.grab_focus()


func mostrar_menu() -> void:
	visible = true
	if boton_play:
		boton_play.grab_focus()


func ocultar_menu() -> void:
	visible = false


func _al_presionar_play() -> void:
	ocultar_menu()
	play_presionado.emit()
	var partida := get_tree().get_first_node_in_group("partida")
	if partida and partida.has_method("iniciar_desde_menu"):
		partida.call("iniciar_desde_menu")
