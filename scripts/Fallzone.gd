extends Area2D



func _ready():
	pass 


func _on_Fallzone_body_entered(body):
	if body.name == "Player":
		body._on_hurtbox_body_entered(self)
	else:
		body.queue_free()
		
	



