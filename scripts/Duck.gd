extends Static_Enemy

enum{PREPARING = 4, ATTACKING}

var jump_force = 330

func _ready():
	lifes = 3
	has_gravity = true
	current_state = IDLE
	
func check_state(delta):
	check_sides()
	match current_state:
		DEAD:
			apply_gravity(delta, true)
		HITTED:
			movement.x = 0
			
		IDLE:
			movement.x = 0
			check_view()
			
		ATTACK:
			attack()
			
		ATTACKING:
			if $ground_check.is_colliding() and movement.y==0:
				if !check_view():
					change_side()
				current_state = IDLE
				$view_cooldown.start()
				
		PREPARING:
			movement.x = 0
			
	if has_gravity:
		apply_gravity(delta, true)
	
	movement = move_and_slide(movement)

func check_sides():
	match current_side:	
		Sides.LEFT:
			direction.x = -1
			$texture.flip_h = false
			$view_field.cast_to.x *= -1 if sign($view_field.cast_to.x)==1 else 1
			
		Sides.RIGHT:
			direction.x = 1
			$texture.flip_h = true	
			$view_field.cast_to.x *= -1 if sign($view_field.cast_to.x)==-1 else 1
	

func check_view():
	$view_field.force_raycast_update()
	if $view_field.is_colliding():
		current_state = PREPARING
		return true
	return false
	
func attack():
	movement = Vector2(direction.x*speed, -jump_force)
	$view_cooldown.stop()
	current_state = ATTACKING

func check_animations():
	var current = "idle"
	
	if movement.y>0:
		current = "fall"
	
	if current_state==ATTACKING:
		current = "attack"
	
	if current_state==HITTED:
		current = "hit"
	
	if current_state==PREPARING:
		current = "preparing"
	
	if current!=$animation.current_animation:
		$animation.play(current)
		
func _on_animation_animation_finished(anim_name):
	match anim_name:
		"hit":
			current_state = IDLE
		"preparing":
			current_state = ATTACK


func _on_view_cooldown_timeout():
	if current_state == IDLE:
		$view_cooldown.wait_time = rand_range(2,6)
		change_side()
