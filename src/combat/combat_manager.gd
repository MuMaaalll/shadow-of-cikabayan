extends Node2D
## ==========================================================================
## combat_manager.gd — Battle Finite State Machine with UI Updates
## Shadow of Cikabayan | Godot 4.6
## ==========================================================================

enum BattleState {
	INIT_BATTLE,
	CHECK_SPEED,
	ACTION_TURN,
	EVAL_FORMULA,
	CHECK_WIN_LOSE,
	VICTORY,
	DEFEAT
}

var battle_state: BattleState = BattleState.INIT_BATTLE
var is_player_turn: bool = true
var current_enemy: EnemyResource = null
var enemy_hp: int = 100
var enemy_shield: int = 50

# UI Node References
@onready var enemy_name_label: Label = %Name
@onready var enemy_hp_bar: ProgressBar = %HPBar
@onready var enemy_shield_bar: ProgressBar = %ShieldBar
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_sanity_bar: ProgressBar = %PlayerSanityBar
@onready var battle_log: Label = %BattleLog

@onready var btn_acid: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/MarginContainer/VBoxContainer/Formula1
@onready var btn_mirror: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/MarginContainer/VBoxContainer/Formula2
@onready var btn_run: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/MarginContainer/VBoxContainer/RunButton

@onready var formula_eval = preload("res://src/combat/formula_eval.gd").new()

func _ready() -> void:
	# Load active enemy from GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.active_enemy:
		current_enemy = game_manager.active_enemy
	else:
		# Fallback default enemy
		current_enemy = EnemyResource.new()
	
	enemy_hp = current_enemy.max_hp
	enemy_shield = current_enemy.contamination_level
	
	# Set up initial progress bar ranges
	enemy_hp_bar.max_value = current_enemy.max_hp
	enemy_shield_bar.max_value = current_enemy.contamination_level
	
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		player_hp_bar.max_value = stats.max_hp
		player_sanity_bar.max_value = stats.max_sanity
	
	# Connect UI buttons programmatically
	if btn_acid:
		btn_acid.pressed.connect(func(): use_combat_formula("Acidic_Extract"))
	if btn_mirror:
		btn_mirror.pressed.connect(func(): use_combat_formula("Reflective_Mirror"))
	if btn_run:
		btn_run.pressed.connect(run_away)
	
	_update_ui()
	_change_state(BattleState.INIT_BATTLE)

func _change_state(new_state: BattleState) -> void:
	battle_state = new_state
	match battle_state:
		BattleState.INIT_BATTLE:
			_state_init_battle()
		BattleState.CHECK_SPEED:
			_state_check_speed()
		BattleState.ACTION_TURN:
			_state_action_turn()
		BattleState.VICTORY:
			_state_victory()
		BattleState.DEFEAT:
			_state_defeat()

func _update_ui() -> void:
	# Update Enemy
	enemy_name_label.text = current_enemy.enemy_name.to_upper()
	enemy_hp_bar.value = enemy_hp
	enemy_shield_bar.value = enemy_shield
	
	# Update Player
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		player_hp_bar.value = stats.current_hp
		player_sanity_bar.value = stats.current_sanity
		
	# Disable buttons if not player turn
	btn_acid.disabled = not is_player_turn
	btn_mirror.disabled = not is_player_turn
	btn_run.disabled = not is_player_turn

func _state_init_battle() -> void:
	_log_message("A wild " + current_enemy.enemy_name + " appeared! Break its contamination shield!")
	await get_tree().create_timer(1.5).timeout
	_change_state(BattleState.CHECK_SPEED)

func _state_check_speed() -> void:
	var irving_speed = 10
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		irving_speed = stats.speed
		
	is_player_turn = irving_speed >= current_enemy.speed
	_update_ui()
	
	if is_player_turn:
		_log_message("Irving is faster! Choose a science formula to attack.")
	else:
		_log_message(current_enemy.enemy_name + " is faster and prepares to attack!")
		
	await get_tree().create_timer(1.2).timeout
	_change_state(BattleState.ACTION_TURN)

func _state_action_turn() -> void:
	_update_ui()
	if not is_player_turn:
		_enemy_attack()

func _enemy_attack() -> void:
	var damage = current_enemy.attack_damage
	_log_message(current_enemy.enemy_name + " attacks and deals " + str(damage) + " damage!")
	
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		stats.current_hp = max(0, stats.current_hp - damage)
		_update_ui()
		await get_tree().create_timer(1.5).timeout
		if stats.current_hp <= 0:
			_change_state(BattleState.DEFEAT)
			return
	
	is_player_turn = true
	_log_message("Your turn! Choose an option.")
	_update_ui()

func use_combat_formula(formula_id: String) -> void:
	if not is_player_turn:
		return
	
	_log_message("Irving uses " + formula_id.replace("_", " ") + "!")
	await get_tree().create_timer(1.2).timeout
	
	var eval_result = formula_eval.evaluate(formula_id, current_enemy.element_type)
	var base_damage = 30
	var final_damage = int(base_damage * eval_result["multiplier"])
	
	if eval_result["effect"] == "SHIELD_RESTORED":
		enemy_shield = min(current_enemy.contamination_level, enemy_shield + 20)
		_log_message("Ineffective formula! The contamination shield absorbs the energy and regenerates!")
	else:
		if enemy_shield > 0:
			enemy_shield = max(0, enemy_shield - final_damage)
			_log_message("Direct hit to contamination shield! Deals " + str(final_damage) + " shield damage.")
		else:
			enemy_hp = max(0, enemy_hp - final_damage)
			_log_message("Vulnerable hit! Deals " + str(final_damage) + " HP damage to " + current_enemy.enemy_name + "!")
	
	if eval_result["effect"] == "RESTORE_SAN_30":
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.current_sanity = min(stats.max_sanity, stats.current_sanity + 30)
			_log_message("Calming aroma restores 30 Sanity (SAN) to Irving.")
	
	_update_ui()
	await get_tree().create_timer(1.5).timeout
	
	if enemy_hp <= 0:
		_change_state(BattleState.VICTORY)
		return
		
	is_player_turn = false
	_update_ui()
	_change_state(BattleState.ACTION_TURN)

func run_away() -> void:
	_log_message("Irving threw a smoke bomb and escaped!")
	await get_tree().create_timer(1.2).timeout
	_state_victory()

func _state_victory() -> void:
	_log_message("Victory! Irving defeated the contamination ghost.")
	await get_tree().create_timer(1.5).timeout
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.end_battle(true)

func _state_defeat() -> void:
	_log_message("Irving fainted...")
	await get_tree().create_timer(1.5).timeout
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Restore player health to 50% so they can continue playing
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.current_hp = stats.max_hp / 2
		game_manager.end_battle(false)

func _log_message(msg: String) -> void:
	print("[CombatLog] ", msg)
	battle_log.text = msg
