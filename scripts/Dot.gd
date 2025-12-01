extends Node2D

# Este nodo dibuja un pequeño cuadrado cuando aparece
func _draw():
	var size := 8  # tamaño del cuadrado (pixeles)
	var rect := Rect2(-size / 2, -size / 2, size, size)
	draw_rect(rect, Color("a3a3a3ff"), true)  
	# true = relleno

func _ready():
	queue_redraw()  # Asegura que se dibuje inmediatamente
