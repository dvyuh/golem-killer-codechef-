extends Area2D
 
 
var direction = Vector2.RIGHT
var speed = 300

func _ready():
	add_to_group("player_bullet")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta
 
func _on_area_entered(area):
	# Hit enemy bullet
	if area.name == "bullet" or area.is_in_group("enemy_bullet"):
		area.queue_free()
		queue_free()

func _on_body_entered(body):
	if body.name == "boss" or body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage()
	queue_free()
 
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
 
