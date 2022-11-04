extends KinematicBody2D

var died = false
var speed = Vector2(0,0)
var up = Vector2.UP
var stop = false;
var life = 4
var max_life = 3
onready var first_spawn = position
export var move_speed = 100
const body_gravity = 1200
var gravity = body_gravity
var jump_force = 720
var dir = 0
var jumps = 1
var last_dir = 1
var hitted = false
var last_ground = null
var let_dust = false
var freezed = false

onready var root = get_tree().get_root()
var dust_instance = preload("res://projectiles/dust.tscn")

signal change_life(life, max_life)

func _ready():
	if(Global.last_checkpoint!=null):
		position = Global.last_checkpoint
	connect("change_life", get_tree().get_root().get_node("Hud/main/life_holder"), "on_change_life")
	emit_signal("change_life", life, max_life)
	
func _physics_process(delta:float) -> void:
	set_animation()
	if !died:
		get_collisions()
		move_input()
	
		if !freezed:
			speed[0] = lerp(speed[0], move_speed*dir, 0.2)
		else:
			speed = Vector2.ZERO
	
	apply_gravity(delta)	
	speed = move_and_slide(speed, up)
	#print(speed)
	
func move_input():
	if(!stop):
		dir = (int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")))
		if dir!=0:
			last_dir = dir
	if Input.is_action_pressed("go_down") and Input.is_action_pressed("jump") and is_grounded():
		position.y +=2
		
func _input(event: InputEvent) -> void:
	if !died:
		if event.is_action_pressed("jump") and !Input.is_action_pressed("go_down"):
			if !in_wall():
				if is_grounded():
					speed[1] = -jump_force/2
					
				elif jumps>0:
					make_dust()
					speed[1] = -jump_force/2
					jumps-=1
			else:
				speed[0] -= 200*$Texture.scale.x
				speed[1] = -jump_force/2
			
func in_wall():

	if !is_grounded() and is_on_wall():
		jumps = 1
		speed[1]*=0.75
		return true
			
	return false
		
		
func set_animation():
	var current = "Idle"
	if dir!=0:
		current = "Run"
		$Texture.scale.x = dir
		
	if !is_grounded():
		current = "Jump"
		
		if speed.y>0:
			current = "Fall"
		elif jumps==0:
			current="Double_Jump"
		if in_wall():
			current = "wall_jump"
		
	if hitted:
		current = "Hit"
	
	if died:
		current = "dead"
	#update
	#print(current)
	
	if current == "Run" || current == "wall_jump":
		if let_dust:
			make_dust()	
			let_dust = false
	
	if $AnimationPlayer.assigned_animation!=current:
		$AnimationPlayer.play(current)
	
	
	
func is_grounded():
	if is_on_floor():
		jumps = 1
		return true
	return false
	
func apply_gravity(delta):
	if speed[1]<450:
		speed[1] += gravity*delta

func _on_hurtbox_body_entered(body):
	var specials = ["saw", "Fallzone", "spike_ball", "Railgun", "Spikes"]
	var immunity_frames = 1
	life-=1
	emit_signal("change_life", life, max_life)
	if life<=0:
		dies()
		if body.name!="Spikes":
			on_knockback(body)
		return false
	hitted = true
	if body.has_method("destroy"):
		body.destroy()
		
	if specials.has(body.name) and !is_grounded() and life>0:
		respawn_after_hit(body)
		immunity_frames = 2
	else: 
		if body.name!="Spikes":
			on_knockback(body)
	#immunity frames	
	get_node("hurtbox/shape").set_deferred("disabled", true)
	yield(get_tree().create_timer(immunity_frames),"timeout")
	get_node("hurtbox/shape").set_deferred("disabled", false)
	hitted = false
	
	
func on_knockback(colisor):
	
	if colisor.has_method("get_velocity"):
		var colisor_velocity = colisor.get_velocity()
		#converte a velocidade para positivo
		colisor_velocity.x*=-1 if(sign(colisor_velocity.x)==-1) else 1
		
		#Atualizar raycasts
		$sides_raycasts/left.force_raycast_update()
		$sides_raycasts/right.force_raycast_update()
		
		var direction = 0
		if $sides_raycasts/left.is_colliding():
			direction = 1
		elif $sides_raycasts/right.is_colliding():
			direction = -1
		else:
			direction = sign(colisor_velocity.x) if sign(colisor_velocity.x)!=0 else -last_dir
		
		
		if colisor_velocity.x == 0 || colisor_velocity.x<300:
			colisor_velocity.x = 300
		
		colisor_velocity.x*= direction	
		speed = colisor_velocity
		
		
		
	

func get_collisions():
	get_node("HitBox").set_deferred("disabled", false)
	for colliders in get_slide_count():	
		var collider_obj = get_slide_collision(colliders)
		#plataforma que cai
		
		if collider_obj!=null:
			if collider_obj.collider.has_method("collide_with"):
				collider_obj.collider.collide_with(collider_obj, self)
		
			if collider_obj.collider.name=="hurtbox":
					if collider_obj.collider.get_parent().has_method("take_hit"):
						collider_obj.collider.get_parent().take_hit()
					elif collider_obj.collider.get_parent().has_method("destroy"):
						collider_obj.collider.get_parent().destroy()
					speed[1]=-345
					jumps = 1
		
			
func dies():
	if !died:
		died = true
		#speed = Vector2.ZERO
		#speed[1] = -200
		emit_signal("change_life", 0, max_life)
		get_node("HitBox").set_deferred("disabled", true)
		yield(get_tree().create_timer(3),"timeout")
		Global._reset_current()
	
func respawn_after_hit(body):
	Transition.make_respawn_transition()
	get_node("hurtbox/shape").set_deferred("disabled", true)
	freezed = true
	yield(get_tree().create_timer(1.3), "timeout")
	freezed = false
	get_node("hurtbox/shape").set_deferred("disabled", false)
	if last_ground!=null:
		position = last_ground 
		
	elif Global.last_checkpoint!=null:
		position = Global.last_checkpoint
		
	else:
		position = first_spawn
		
func checkpoint_entered(new_pos):
	Global.last_checkpoint = new_pos
	
func make_dust():

	var dust = dust_instance.instance()
	dust.get_node("dust").emitting = true
	dust.position.x = position.x+$dust_origin.position.x*-dir
	dust.position.y = position.y+$dust_origin.position.y
	dust.scale.x = sign($Texture.scale.x)
	
	if in_wall():
		dust.rotation_degrees = 90
		dust.position.x = position.x+$dust_wall_origin.position.x*sign($Texture.scale.x)
		dust.position.y = position.y+$dust_wall_origin.position.y
	
	get_parent().add_child(dust)
	


func _on_dust_cooldown_timeout():
	let_dust = true
