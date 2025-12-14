extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("player")

var acceleration: Vector2 = Vector2.ZERO 
var velocity: Vector2 = Vector2.ZERO

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
 
	acceleration = (player.position - position).normalized() * 700
 
	velocity += acceleration * delta
	rotation = velocity.angle()
 
	velocity = velocity.limit_length(150)
 
	position += velocity * delta

func _on_area_entered(area):
	# Hit by player bullet
	if area.is_in_group("player_bullet"):
		queue_free()
 
func _on_body_entered(body):
	if body.name == "player" or body.is_in_group("player"):
		if body.has_method("take_bullet_damage"):
			body.take_bullet_damage(10)
		queue_free()

 
