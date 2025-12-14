extends CharacterBody2D
@onready var player = get_parent().find_child("player")
@onready var sprite = $Sprite2D 
@onready var progress_bar = $ui/ProgressBar
 
var direction : Vector2
var DEF = 0
var is_dashing = false  # Track if boss is in dash state
 
var health = 100:
	set(value):
		health = value
		progress_bar.value = value
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
			handle_boss_death()
			
func handle_boss_death():
	# Get the AnimationPlayer and wait for death animation
	var anim_player = find_child("AnimationPlayer")
	if anim_player:
		await anim_player.animation_finished
	
	# Stop the game timer
	var game_timer = get_tree().root.find_child("GameTimer", true, false)
	if game_timer and game_timer.has_method("stop_timer"):
		game_timer.stop_timer()
	get_tree().change_scene_to_file("res://scenes/PlayerWinUI.tscn")

func _ready():
	set_physics_process(false)
	add_to_group("boss")  # Add boss to group for clone targeting

func _process(_delta):
	direction = player.position - position
 
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
 
func _physics_process(delta):
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)

func take_damage():
	var damage = 1
	damage -= DEF * 0.2  # Each DEF point reduces damage by 20%
	health -= max(0.5, damage)  # Minimum 0.5 damage so it's never immortal
	# Add charge to player's clone meter when boss takes damage
	if player and player.has_method("add_clone_charge"):
		player.add_clone_charge(5.0)  # Adjust this value to control charge speed

# Functions to be called from attack states
func deal_melee_damage():
	if player and player.has_method("take_melee_damage"):
		player.take_melee_damage()

func deal_laser_damage():
	if player and player.has_method("take_laser_damage"):
		player.take_laser_damage()

func deal_dash_damage():
	if player and player.has_method("take_dash_damage"):
		player.take_dash_damage(global_position)

func deal_missile_damage():
	if player and player.has_method("take_missile_damage"):
		player.take_missile_damage()
