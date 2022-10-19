extends Control

var life_size = 32
var initial_scale = Vector2(0.7,0.7)
var current_scale = Vector2(0.7,0.7)
var tween
onready var lifes_fig = get_node("life_box/lifes")

func _ready():
	tween = get_node("animation")
	
func _process(delta):
	lifes_fig.rect_scale = current_scale
	
func on_change_life(player_health, max_health):
	yield(VisualServer, "frame_post_draw")
	lifes_fig.rect_size.x = player_health*life_size
	
	if player_health<=0:
		animate()
		yield(tween,"tween_all_completed")
		lifes_fig.visible = false
		
	elif player_health!=max_health:
		animate()
	

func animate():
	tween.remove_all()
	tween.interpolate_property(self, "current_scale", initial_scale, Vector2(0.8,0.8), 0.2, tween.TRANS_BOUNCE, tween.EASE_OUT, 0)
	tween.interpolate_property(self, "current_scale", Vector2(0.8,0.8), initial_scale, 0.2, tween.TRANS_BOUNCE, tween.EASE_OUT, 0.2)
	tween.start()

func _reset_scale():
	lifes_fig.visible = true
	lifes_fig.rect_scale = current_scale
