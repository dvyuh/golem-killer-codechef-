extends CharacterBody2D
@export var bullet_node: PackedScene
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var clone_duration: float = 5.0
@export var clone_shoot_interval: float = 0.3
@export var max_ammo: int = 40
@export var reload_time: float = 1.5
@export var fire_rate: float = 0.1  # Time between shots in seconds
@export var clone_scale: float = 1.5  #

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var ammo_label: Label = $AmmoLabel

var boss_contact_damage: int = 100
var can_take_contact_damage: bool = true
var contact_damage_cooldown: float = 0.5
var contact_damage_timer: float = 0.0

var player_health: int = 100
var is_dead: bool = false

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0

# Clone system
var clone_charge: float = 0.0
var max_clone_charge: float = 100.0
var clone_active: bool = false
var clone_timer: float = 0.0
var clone_shoot_timer: float = 0.0
var clone_sprite: Sprite2D = null

# Ammo system
var current_ammo: int = 40
var is_reloading: bool = false
var reload_timer: float = 0.0
var can_shoot: bool = true
var shoot_cooldown_timer: float = 0.0

func check_boss_contact():
	if is_dead:
		return
	
	# Find the boss
	var boss = get_tree().get_first_node_in_group("boss")
	if not boss:
		return
	var distance = global_position.distance_to(boss.global_position)
	if distance < 30:  # Adjust collision distance as needed
		if can_take_contact_damage:
			player_health -= boss_contact_damage
			can_take_contact_damage = false
			contact_damage_timer = contact_damage_cooldown
			print("Player touched boss! Health: ", player_health)
			%PlayerHealth.value = player_health
			check_death()

func _physics_process(delta):
	if is_dashing:
		# Handle dash movement
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		
		if dash_timer <= 0:
			is_dashing = false
	else:
		# Normal movement
		velocity = Input.get_vector("left","right","up","down") * 250
	
	move_and_slide()
	
	# Handle contact damage cooldown
	if not can_take_contact_damage:
		contact_damage_timer -= delta
		if contact_damage_timer <= 0:
			can_take_contact_damage = true
	
	# Check if touching boss
	check_boss_contact()
	# Handle cooldown
	if not can_dash:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_dash = true
	
	# Handle shoot cooldown
	if not can_shoot:
		shoot_cooldown_timer -= delta
		if shoot_cooldown_timer <= 0:
			can_shoot = true
	
	# Handle reload
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			is_reloading = false
			current_ammo = max_ammo
			update_ammo_display()
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = clone_charge
	
	# Handle clone
	if clone_active:
		clone_timer -= delta
		clone_shoot_timer -= delta
		
		# Deplete charge over time
		clone_charge -= (max_clone_charge / clone_duration) * delta
		clone_charge = max(0, clone_charge)
		
		# Clone shoots at intervals
		if clone_shoot_timer <= 0:
			clone_shoot()
			clone_shoot_timer = clone_shoot_interval
		
		# Deactivate clone when charge depletes
		if clone_timer <= 0 or clone_charge <= 0:
			deactivate_clone()

func shoot():
	# Check if can shoot
	if is_reloading or current_ammo <= 0 or not can_shoot:
		return
	
	var bullet = bullet_node.instantiate()
	bullet.position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	get_tree().current_scene.call_deferred("add_child",bullet)
	
	# Consume ammo
	current_ammo -= 1
	update_ammo_display()
	
	# Start shoot cooldown
	can_shoot = false
	shoot_cooldown_timer = fire_rate
	
	# Auto reload when empty
	if current_ammo <= 0:
		start_reload()

func start_reload():
	if not is_reloading and current_ammo < max_ammo:
		is_reloading = true
		reload_timer = reload_time
		update_ammo_display()

func update_ammo_display():
	if ammo_label:
		if is_reloading:
			ammo_label.text = "RELOADING..."
		else:
			ammo_label.text = str(current_ammo) + " / " + str(max_ammo)

func dash():
	if can_dash and not is_dashing:
		# Get current movement direction
		var input_dir = Input.get_vector("left","right","up","down")
		
		# If player is moving, dash in that direction
		if input_dir.length() > 0:
			dash_direction = input_dir.normalized()
		else:
			# If not moving, dash towards mouse
			dash_direction = (get_global_mouse_position() - global_position).normalized()
		
		# Start dash
		is_dashing = true
		can_dash = false
		dash_timer = dash_duration
		cooldown_timer = dash_cooldown
		
		# Set collision mask to avoid damage (make invincible)
		set_collision_mask_value(1, false)  # Regular enemies/hazards
		set_collision_mask_value(2, false)  # Boss
		
		# Optional: Add visual feedback
		modulate = Color(1, 1, 1, 0.5)  # Make semi-transparent during dash
		
		# Schedule end of invincibility
		get_tree().create_timer(dash_duration).timeout.connect(_end_dash_invincibility)

func _end_dash_invincibility():
	# Restore collision for both layers
	set_collision_mask_value(1, true)  # Regular enemies/hazards
	set_collision_mask_value(2, true)  # Boss
	
	# Restore visual
	modulate = Color(1, 1, 1, 1)

func _input(event):
	if event.is_action("shoot"):
		shoot()
	
	if event.is_action_pressed("dash"):  # You'll need to add this action in Project Settings
		dash()
	
	if event.is_action_pressed("activate_clone"):  # Add this action mapped to E key
		activate_clone()
	
	if event.is_action_pressed("reload"):  # Add this action mapped to R key
		start_reload()

# Call this function when player damages an enemy
func add_clone_charge(amount: float = 20.0):
	if not clone_active:
		clone_charge += amount
		clone_charge = min(clone_charge, max_clone_charge)

func activate_clone():
	if clone_charge >= max_clone_charge and not clone_active:
		clone_active = true
		clone_timer = clone_duration
		clone_shoot_timer = 0.0
		
		# Create visual clone
		create_clone_visual()

func create_clone_visual():
	clone_sprite = Sprite2D.new()
	clone_sprite.scale *= clone_scale 
	# Set texture directly
	clone_sprite.texture = load("res://assets/Free 2D Animated Vector Game Character Sprites/Full body animated characters/Char 1/with hands/idle_0.png")
	clone_sprite.scale = Vector2(1, 1)
	
	# Make it look like a ghost
	clone_sprite.modulate = Color(0.5, 0.8, 1.0, 0.6)
	clone_sprite.position = global_position + Vector2(50, 0)
	
	get_tree().current_scene.add_child(clone_sprite)
	
	# Copy the player's sprite (adjust this based on your player's sprite node)
	if has_node("Sprite2D"):
		var player_sprite = get_node("Sprite2D")
		clone_sprite.texture = player_sprite.texture
		clone_sprite.scale = player_sprite.scale
		clone_sprite.hframes = player_sprite.hframes if "hframes" in player_sprite else 1
		clone_sprite.vframes = player_sprite.vframes if "vframes" in player_sprite else 1
		clone_sprite.frame = player_sprite.frame if "frame" in player_sprite else 0
	
	# Make it look like a ghost
	clone_sprite.modulate = Color(0.5, 0.8, 1.0, 0.6)  # Blue-ish transparent
	clone_sprite.position = global_position + Vector2(50, 0)  # Offset from player
	
	get_tree().current_scene.add_child(clone_sprite)

func clone_shoot():
	if not clone_sprite:
		return
	
	# Find the boss
	var boss = get_tree().get_first_node_in_group("boss")
	if not boss:
		return
	
	# Shoot at the boss
	var bullet = bullet_node.instantiate()
	bullet.position = clone_sprite.global_position
	bullet.direction = (boss.global_position - clone_sprite.global_position).normalized()
	get_tree().current_scene.call_deferred("add_child", bullet)

func deactivate_clone():
	clone_active = false
	clone_charge = 0.0
	
	if clone_sprite:
		clone_sprite.queue_free()
		clone_sprite = null
func check_death():
	if player_health <= 0:
		is_dead = true
		player_health = 0
		die()

func update_health_display():
	# Find PlayerHealth progress bar and update it
	var health_bar = get_tree().root.find_child("PlayerHealth", true, false)
	if health_bar:
		health_bar.value = player_health
		health_bar.max_value = 100

func die():
	# Stop all movement and actions
	set_physics_process(false)
	set_process_input(false)
	print("Player died!")
	get_tree().change_scene_to_file("res://scenes/PlayerDeathUI.tscn")

func take_bullet_damage(damage: int):
	if is_dead or is_dashing:
		return
	player_health -= damage
	%PlayerHealth.value = player_health
	print("Player hit by bullet! Health: ", player_health)
	check_death()
