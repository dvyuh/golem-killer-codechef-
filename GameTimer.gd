extends CanvasLayer
var elapsed_time: float = 0.0
var is_running: bool = true
@onready var timer_label = $TimerLabel  # Add a Label node as child

func _ready():
	# Make sure timer label exists
	if not timer_label:
		print("Warning: TimerLabel not found!")

func _process(delta):
	if is_running:
		elapsed_time += delta
		update_timer_display()

func update_timer_display():
	if timer_label:
		var total_seconds: int = int(elapsed_time)
		var minutes: int = total_seconds / 60
		var seconds: int = total_seconds % 60
		var milliseconds: int = int(fmod(elapsed_time * 100.0, 100.0))
		timer_label.text = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func stop_timer():
	is_running = false

func get_time_string() -> String:
	var total_seconds: int = int(elapsed_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	var milliseconds: int = int(fmod(elapsed_time * 100.0, 100.0))
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
