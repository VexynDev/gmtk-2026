extends CharacterBody2D

@onready var tilemap = $"../World"
@onready var sprite = $PlayerSprite
@onready var gravcooldown : Timer = $GravCooldown

var tiledata
var tileposition
var collisionposition
var collision
var tilename
var direction
var normal
var side
var bounceforce = 0
var friction = 100
var gravitydirection : int = 1
var gravblockcallable = true
var speed = 350
var jumpgrav = 5000
var fallgrav = 7000
var slidegrav = 3000
var jumpforce = 1300
var walljumpforce = Vector2(600,800)
var acceleration = 200
var state = states.idle
var coyotetime = 0.35
var coyotetimer = 0.0
var jumpbuffertime = 0.35
var jumpbuffertimer = 0.0
var normal_scale = Vector2(1,1)
var jump_scale = Vector2(0.85,1.15)
var land_scale = Vector2(1.3,0.7)
var squish_speed = 12
var was_on_ground = false
var walljumping = false
var dashforce = 2500

enum states {
	walk,
	jump,
	wallslide,
	walljump,
	fall,
	idle
}

func _physics_process(delta: float) -> void:
	if sprite.flip_h == true:
		sprite.offset.x = -9.6
	else:
		sprite.offset.x = 0
	
	if sprite.flip_v == true:
		sprite.offset.y = 2
	else:
		sprite.offset.y = 0
	
	if coyotetimer > 0:
		coyotetimer -= delta
	
	if jumpbuffertimer > 0:
		jumpbuffertimer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jumpbuffertimer = jumpbuffertime
	
	match state:
		states.walk:
			walk()
		states.idle:
			idle()
		states.fall:
			fall(delta)
		states.jump:
			jump(delta)
		states.wallslide:
			wallslide(delta)
		states.walljump:
			walljump(delta)
	
	move_and_slide()
	
	check_tile_collisions()
	
	if is_on_floor() and gravitydirection == 1:
		coyotetimer = coyotetime
	elif is_on_ceiling() and gravitydirection == -1:
		coyotetimer = coyotetime
	
	if !was_on_ground:
		if (is_on_floor() and gravitydirection == 1) or (is_on_ceiling() and gravitydirection == -1):
			sprite.scale = land_scale
	
	was_on_ground = (is_on_floor() and gravitydirection == 1) or (is_on_ceiling() and gravitydirection == -1)
	
	sprite.scale = sprite.scale.lerp(normal_scale, squish_speed * delta)


func walk():
	sprite.play("Walk")
	
	if is_on_floor() and gravitydirection == 1:
		if Input.is_action_pressed("left"):
			velocity.x = move_toward(velocity.x, -speed, speed)
			sprite.flip_h = false
		elif Input.is_action_pressed("right"):
			velocity.x = move_toward(velocity.x, speed, speed)
			sprite.flip_h = true
	
	if is_on_ceiling() and gravitydirection == -1:
		if Input.is_action_pressed("left"):
			velocity.x = move_toward(velocity.x, -speed, speed)
			sprite.flip_h = false
		elif Input.is_action_pressed("right"):
			velocity.x = move_toward(velocity.x, speed, speed)
			sprite.flip_h = true
	
	if Input.is_action_just_released("left") or Input.is_action_just_released("right"):
		state = states.idle
	
	if jumpbuffertimer > 0 and coyotetimer > 0:
		jumpbuffertimer = 0
		coyotetimer = 0
		state = states.jump
	
	if !is_on_floor() and gravitydirection == 1:
		state = states.fall
	elif !is_on_ceiling() and gravitydirection == -1:
		state = states.fall


func idle():
	sprite.play("Idle")
	velocity.x = move_toward(velocity.x, 0, friction)
	
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		state = states.walk
	
	if jumpbuffertimer > 0 and coyotetimer > 0:
		jumpbuffertimer = 0
		coyotetimer = 0
		state = states.jump
	
	if !is_on_floor() and gravitydirection == 1:
		state = states.fall
	elif !is_on_ceiling() and gravitydirection == -1:
		state = states.fall


func jump(delta):
	sprite.play("Jump")
	sprite.scale = sprite.scale.lerp(jump_scale, squish_speed * delta)
	
	if !walljumping:
		if gravitydirection == 1 and (is_on_floor() or coyotetimer > 0):
			velocity.y = -jumpforce
			coyotetimer = 0
			jumpbuffertimer = 0
		
		elif gravitydirection == -1 and (is_on_ceiling() or coyotetimer > 0):
			velocity.y = jumpforce
			coyotetimer = 0
			jumpbuffertimer = 0
	
	else:
		walljumping = false
	
	if Input.is_action_just_released("jump"):
		velocity.y *= 0.4
	
	velocity.y += jumpgrav * delta * gravitydirection
	
	if Input.is_action_pressed("left") and velocity.y <= 0:
		velocity.x = move_toward(velocity.x, -speed * 0.8, acceleration)
		sprite.flip_h = false
	elif Input.is_action_pressed("right") and velocity.y <= 0:
		velocity.x = move_toward(velocity.x, speed * 0.8, acceleration)
		sprite.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, 10)
	
	if tilename == "Block" and (side == "left" or side == "right"):
		if is_on_wall() and !is_on_floor() and !is_on_ceiling():
			state = states.wallslide
	
	if velocity.y >= 0 and !is_on_floor() and gravitydirection == 1:
		state = states.fall
	elif velocity.y <= 0 and !is_on_ceiling() and gravitydirection == -1:
		state = states.fall


func fall(delta):
	sprite.play("Fall")
	velocity.y += fallgrav * delta * gravitydirection
	
	if Input.is_action_pressed("left") and velocity.y <= 0:
		velocity.x = move_toward(velocity.x, -speed * 0.6, acceleration)
		sprite.flip_h = false
	elif Input.is_action_pressed("right") and velocity.y <= 0:
		velocity.x = move_toward(velocity.x, speed * 0.6, acceleration)
		sprite.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, 10)
	
	if tilename == "Block" and (side == "left" or side == "right"):
		if is_on_wall() and !is_on_floor() and !is_on_ceiling():
			state = states.wallslide
	
	if jumpbuffertimer > 0 and coyotetimer > 0:
		jumpbuffertimer = 0
		coyotetimer = 0
		state = states.jump
	
	if is_on_floor() and gravitydirection == 1:
		state = states.idle
	
	if is_on_ceiling() and gravitydirection == -1:
		state = states.idle


func wallslide(delta):
	if tilename != "Block" or (side != "left" and side != "right"):
		state = states.idle
		return
	
	if !is_on_wall():
		state = states.fall
		return
	
	if is_on_floor() and gravitydirection == 1:
		state = states.idle
		return
	
	if is_on_ceiling() and gravitydirection == -1:
		state = states.idle
		return
	
	sprite.play("WallHold")
	velocity.y += slidegrav * delta * gravitydirection
	
	if Input.is_action_just_pressed("jump"):
		state = states.walljump


func walljump(delta):
	sprite.play("WallJump")
	
	if side == "left":
		velocity.x = walljumpforce.x
		sprite.flip_h = true
	elif side == "right":
		velocity.x = -walljumpforce.x
		sprite.flip_h = false
	
	velocity.y = -walljumpforce.y * gravitydirection
	
	sprite.scale = jump_scale
	
	await get_tree().process_frame
	
	walljumping = true
	state = states.jump


func check_tile_collisions():
	for i in get_slide_collision_count():
		collision = get_slide_collision(i)
		normal = collision.get_normal()
		collisionposition = collision.get_position()
		
		var tile_lookup_position = collisionposition - normal * 1
		
		tileposition = tilemap.local_to_map(
			tilemap.to_local(tile_lookup_position)
		)
		
		tiledata = tilemap.get_cell_tile_data(tileposition)
		
		if tiledata == null:
			continue
		
		bounceforce = tiledata.get_custom_data("BounceForce")
		tilename = tiledata.get_custom_data("Name")
		direction = tiledata.get_custom_data("Direction")
		friction = tiledata.get_custom_data("Friction")
		
		if normal.x >= 0.5:
			side = "left"
			velocity.x = -bounceforce
		
		elif normal.x <= -0.5:
			side = "right"
			velocity.x = bounceforce
		
		elif normal.y >= 0.5:
			side = "top"
			velocity.y = -bounceforce * 1.5
		
		elif normal.y <= -0.5:
			side = "bottom"
			velocity.y = bounceforce * 1.5
		
		if tilename == "DashBlock":
			var dash_direction = Vector2.ZERO
			
			if direction == "Right":
				dash_direction = Vector2.RIGHT
			elif direction == "Left":
				dash_direction = Vector2.LEFT
			elif direction == "Up":
				dash_direction = Vector2.UP
			elif direction == "Down":
				dash_direction = Vector2.DOWN
			
			if dash_direction != Vector2.ZERO:
				var collision_dot = normal.dot(dash_direction)
				
				if collision_dot >= 0:
					velocity = dash_direction * dashforce
		
		if tilename == "Spike":
			get_tree().reload_current_scene()
			return
		
		if tilename == "GravityBlock":
			if gravblockcallable == true:
				gravcooldown.start(1)
				gravblockcallable = false
				gravitydirection = gravitydirection * -1
				sprite.flip_v = !sprite.flip_v


func grav_cooldown_timeout() -> void:
	gravblockcallable = true
