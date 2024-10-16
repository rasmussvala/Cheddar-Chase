extends Node

var score = 0
var max_score = 0
var time_taken: float = 0.0
var damage_taken: bool = false
var stars_earned: int = 0

@onready var player: CharacterBody2D = %player
@onready var death_menu: CanvasLayer = %death_menu
@onready var win_menu: CanvasLayer = %win_menu
@onready var level_time: Node = %level_time

func _ready() -> void:
	max_score = get_tree().get_node_count_in_group("Cheeses")
	time_taken = 0.0
	damage_taken = false
	call_deferred("update_initial_hud")
	if player:
		player.connect("player_take_damage", Callable(self, "_on_player_take_damage"))

func _process(delta: float) -> void:
	time_taken += delta
	print(time_taken)

func update_initial_hud() -> void:
	if player:
		player.hud.update_score(score, max_score)

func add_point() -> void:
	score += 1
	player.hud.update_score(score, max_score)
	
	if score >= max_score:
		var progress_data = save_manager.load_progress()
		var level_stars = progress_data["level_stars"]
		
		# Get the current level name (e.g., "1" or "2B")
		var current_level = extract_level_name(game_data.get_current_level())
		
		# Calculate stars earned for the current playthrough
		calculate_stars()
		
		# Update stars for the current level
		if not level_stars.has(current_level) or stars_earned > level_stars[current_level]:
			level_stars[current_level] = stars_earned
		
		# Update the highest level unlocked if necessary
		var current_level_number = extract_level_number(current_level)
		if progress_data["highest_level"] <= current_level_number:
			progress_data["highest_level"] = current_level_number + 1
		
		# Save the updated progress data
		if save_manager.save_progress(progress_data["highest_level"], level_stars):
			print("Stars saved successfully for level: ", current_level, " Stars: ", level_stars[current_level])
		else:
			print("Failed to save stars!")
		
		# Update all level icons to reflect the new star status
		for level in get_tree().get_nodes_in_group("level_icons"):
			if level is LevelIcon:
				level.update_level_state()
		
		win()  # Proceed with the victory/win flow

func extract_level_name(level_path: String) -> String:
	var regex = RegEx.new()
	regex.compile("level_(\\d+[A-Za-z]?)")
	var result = regex.search(level_path)
	
	if result:
		return result.get_string(1)
	else:
		push_error("Invalid level path format: " + level_path)
		return "1"

func extract_level_number(level_name: String) -> int:
	var regex = RegEx.new()
	regex.compile("^(\\d+)")
	var result = regex.search(level_name)
	
	if result:
		return int(result.get_string(1))
	else:
		push_error("Invalid level name format: " + level_name)
		return 1

func calculate_stars() -> void:
	stars_earned = 1  # Always get 1 star for completion
	if time_taken <= level_time.star_time:  # Example threshold for fast completion
		stars_earned += 1
	if not damage_taken:  # No damage taken
		stars_earned += 1

func _on_player_take_damage() -> void:
	damage_taken = true

func _on_player_trigger_death_menu() -> void:
	death_menu.fade_in()

func win() -> void:
	win_menu.fade_in()
