extends TileMapLayer

@export var fireball_scene = preload("res://Scenes/Prefabs/Fireball.tscn")

var fireballshooters : Array[Dictionary] = []
var fireballtimer : float = 0.0
var fireballinterval : float = 2.0


func _ready() -> void:
	find_fireball_shooters()


func _physics_process(delta: float) -> void:
	fireballtimer -= delta
	
	if fireballtimer <= 0:
		fireballtimer = fireballinterval
		shoot_fireballs()


func find_fireball_shooters() -> void:
	for cell in get_used_cells():
		var tiledata = get_cell_tile_data(cell)
		
		if tiledata == null:
			continue
		
		var tilename = tiledata.get_custom_data("Name")
		
		if tilename != "FireballShooter":
			continue
		
		var direction = tiledata.get_custom_data("Direction")
		
		fireballshooters.append({
			"position": cell,
			"direction": direction
		})


func shoot_fireballs() -> void:
	for shooter in fireballshooters:
		var fireball = fireball_scene.instantiate()
		
		var shooterposition = to_global(map_to_local(shooter["position"]))
		var direction = shooter["direction"]
		var directionvector = Vector2.ZERO
		
		if direction == "Right":
			directionvector = Vector2.RIGHT
		elif direction == "Left":
			directionvector = Vector2.LEFT
		elif direction == "Up":
			directionvector = Vector2.UP
		elif direction == "Down":
			directionvector = Vector2.DOWN
		
		fireball.global_position = shooterposition + directionvector * 32
		fireball.direction = directionvector
		
		get_tree().current_scene.add_child(fireball)
