extends Node2D

func _ready():
	pass

func _physics_process(delta):
	if(!$dust.emitting):
		queue_free()
