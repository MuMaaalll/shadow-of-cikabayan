extends Node2D

@export var enemy_hp_bar: ProgressBar
@export var enemy_shield_bar: ProgressBar
@export var player_hp_bar: ProgressBar
@export var turn_label: Label

enum BattleState {
	INIT_BATTLE,
	CHECK_SPEED,
	ACTION_TURN,
	EVAL_FORMULA,
	CHECK_WIN_LOSE,
	VICTORY,
	DEFEAT
}

# ── SLOT INSPECTOR (WAJIB DI-DRAG & DROP DI EDITOR) ────────────────────────
@export var btn_formula1: Button
@export var btn_formula2: Button
@export var btn_run: Button
# ───────────────────────────────────────────────────────────────────────────

var battle_state: BattleState = BattleState.INIT_BATTLE
var is_player_turn: bool = true
var current_enemy: EnemyResource = null
var enemy_hp: int = 100
var enemy_shield: int = 50

var formula_eval

func _ready() -> void:
	# Paksa scene combat ini agar TETAP BERPROSES meskipun world di-disable
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Inisialisasi script evaluator rumus kimia/formula dengan aman
	var formula_script = load("res://src/combat/formula_eval.gd")
	if formula_script:
		formula_eval = formula_script.new()
		if formula_eval is Node:
			add_child(formula_eval)

	# Load active enemy dari GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.active_enemy:
		current_enemy = game_manager.active_enemy
	else:
		# Fallback data keras jika dites standalone tanpa lewat world map
		current_enemy = EnemyResource.new()
		current_enemy.enemy_name = "Kunti (Test)"
		current_enemy.max_hp = 100
		current_enemy.contamination_level = 50
		current_enemy.speed = 5
		current_enemy.attack_damage = 15
	
	# Ambil data HP dan Shield secara solid dari resource
	enemy_hp = current_enemy.max_hp
	enemy_shield = current_enemy.contamination_level
	
	# ── FIX: set batas maksimal progress bar sesuai data musuh ─────────────
	if enemy_hp_bar:
		enemy_hp_bar.max_value = current_enemy.max_hp
		enemy_hp_bar.min_value = 0
	else:
		push_error("[CombatManager] ERROR: enemy_hp_bar belum di-assign di Inspector! UI HP gak akan pernah update.")
	
	if enemy_shield_bar:
		enemy_shield_bar.max_value = current_enemy.contamination_level
		enemy_shield_bar.min_value = 0
	else:
		push_error("[CombatManager] ERROR: enemy_shield_bar belum di-assign di Inspector! UI Shield gak akan pernah update.")
	
	# ── FIX: setup player HP bar ────────────────────────────────────────────
	var player_stats = get_node_or_null("/root/PlayerStats")
	if player_hp_bar:
		if player_stats:
			player_hp_bar.max_value = player_stats.max_hp
			player_hp_bar.min_value = 0
			player_hp_bar.value = player_stats.current_hp
		else:
			push_error("[CombatManager] ERROR: /root/PlayerStats gak ketemu, player_hp_bar gak bisa di-init!")
	else:
		push_error("[CombatManager] ERROR: player_hp_bar belum di-assign di Inspector! Darah player gak akan kelihatan berkurang.")
	# ─────────────────────────────────────────────────────────────────────
	
	print("[CombatManager] Starting battle against: ", current_enemy.enemy_name)
	print("[CombatManager] Enemy HP: ", enemy_hp, " | Shield: ", enemy_shield)
	
	# ── SAMBUNGKAN SIGNAL BUTTONS VIA EXPORT ─────────────────────────────────
	if btn_formula1:
		btn_formula1.pressed.connect(func(): use_combat_formula("Acidic_Extract"))
		print("[CombatManager] Terhubung: Tombol Formula 1")
	else:
		push_error("[CombatManager] ERROR: Tombol Formula 1 belum di-assign di Inspector!")

	if btn_formula2:
		btn_formula2.pressed.connect(func(): use_combat_formula("Reflective_Mirror"))
		print("[CombatManager] Terhubung: Tombol Formula 2")

	if btn_run:
		btn_run.pressed.connect(run_away)
		print("[CombatManager] Terhubung: Tombol Run")
	# ───────────────────────────────────────────────────────────────────────────
	
	# ── FIX: render UI awal biar bar gak kosong/salah pas battle mulai ─────
	update_ui_visual()
	# ─────────────────────────────────────────────────────────────────────
	
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

func _state_init_battle() -> void:
	print("[CombatManager] Init Battle UI...")
	_change_state(BattleState.CHECK_SPEED)

func _state_check_speed() -> void:
	var irving_speed = 10 # Default base speed player
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		irving_speed = stats.speed
		
	is_player_turn = irving_speed >= current_enemy.speed
	print("[CombatManager] Speed Check: Player turn? ", is_player_turn)
	_change_state(BattleState.ACTION_TURN)

func _state_action_turn() -> void:
	# ── FIX: lock/unlock tombol sesuai giliran, biar turn-based kerasa ─────
	_set_buttons_enabled(is_player_turn)
	if turn_label:
		turn_label.text = "Giliranmu!" if is_player_turn else "Giliran Musuh..."
	# ─────────────────────────────────────────────────────────────────────
	
	if is_player_turn:
		print("[CombatManager] Waiting for Player action... (Silakan klik tombol)")
	else:
		print("[CombatManager] Enemy attacks!")
		# Delay dikit biar keliatan turn musuh beneran jalan, bukan instan
		await get_tree().create_timer(0.6).timeout
		_enemy_attack()

func _set_buttons_enabled(enabled: bool) -> void:
	if btn_formula1:
		btn_formula1.disabled = not enabled
	if btn_formula2:
		btn_formula2.disabled = not enabled
	if btn_run:
		btn_run.disabled = not enabled

func _enemy_attack() -> void:
	var damage = current_enemy.attack_damage
	var stats = get_node_or_null("/root/PlayerStats")
	if stats:
		stats.current_hp = max(0, stats.current_hp - damage)
		print("[CombatManager] Player hit for ", damage, " damage. Current HP: ", stats.current_hp)
		
		# ── FIX: gambar ulang HP bar player setelah kena damage ────────────
		if player_hp_bar:
			player_hp_bar.value = stats.current_hp
		# ─────────────────────────────────────────────────────────────────
		
		if stats.current_hp <= 0:
			_change_state(BattleState.DEFEAT)
			return
	else:
		push_error("[CombatManager] ERROR: /root/PlayerStats gak ketemu, damage ke player gak tercatat!")
	
	# Kembalikan giliran ke player
	is_player_turn = true
	_change_state(BattleState.ACTION_TURN)

func use_combat_formula(formula_id: String) -> void:
	if not is_player_turn:
		print("[CombatManager] Bukan giliranmu, boi!")
		return
	
	if not formula_eval:
		print("[CombatManager] ERROR: formula_eval gagal dimuat!")
		return
		
	print("[CombatManager] Player used formula: ", formula_id)
	var eval_result = formula_eval.evaluate(formula_id, current_enemy.element_type)
	
	# Kalkulasi damage dasar
	var base_damage = 25
	var final_damage = int(base_damage * eval_result["multiplier"])
	
	# JALANKAN LOGIKA EFEK FORMULA SECARA KETAT
	if eval_result["effect"] == "SHIELD_RESTORED":
		enemy_shield = min(current_enemy.contamination_level, enemy_shield + 20)
		print("[CombatManager] Shield restored! Current Shield: ", enemy_shield)
		
		# ── FIX: update bar setelah shield berubah ──────────────────────────
		update_ui_visual()
		# ─────────────────────────────────────────────────────────────────
		
		# Karena cuma restore, langsung oper turn tanpa ngecek HP musuh (anti-stuck victory)
		_oper_turn_ke_musuh()
		return
		
	else:
		# Blok ini dieksekusi jika formula bersifat menyerang
		if enemy_shield > 0:
			enemy_shield = max(0, enemy_shield - final_damage)
			print("[CombatManager] Shield damaged! Current Shield: ", enemy_shield)
		else:
			enemy_hp = max(0, enemy_hp - final_damage)
			print("[CombatManager] Enemy HP hit! Current Enemy HP: ", enemy_hp)
	
	# Efek tambahan pemulihan Sanity
	if eval_result["effect"] == "RESTORE_SAN_30":
		var stats = get_node_or_null("/root/PlayerStats")
		if stats:
			stats.current_sanity = min(stats.max_sanity, stats.current_sanity + 30)
			print("[CombatManager] Sanity restored +30. Current Sanity: ", stats.current_sanity)
	
	# ── FIX: update bar setelah HP/shield berubah dari serangan ─────────────
	update_ui_visual()
	# ─────────────────────────────────────────────────────────────────────
	
	# CEK KONDISI MENANG (Hanya jalan setelah musuh diserang)
	if enemy_hp <= 0:
		_change_state(BattleState.VICTORY)
		return
		
	# Oper giliran jika musuh masih hidup
	_oper_turn_ke_musuh()

func _oper_turn_ke_musuh() -> void:
	is_player_turn = false
	_change_state(BattleState.ACTION_TURN)

func run_away() -> void:
	if not is_player_turn:
		print("[CombatManager] Bukan giliranmu, gak bisa run!")
		return
	print("[CombatManager] Ran away successfully!")
	_change_state(BattleState.VICTORY)

func _state_victory() -> void:
	print("[CombatManager] Victory! Ending battle...")
	_set_buttons_enabled(false)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.end_battle(true)
	else:
		# ── FIX: fallback biar scene battle gak macet kalau standalone test ──
		push_error("[CombatManager] GameManager gak ketemu! Kembali ke scene sebelumnya secara manual.")
		_fallback_exit_battle()

func _state_defeat() -> void:
	print("[CombatManager] Defeat... Game Over.")
	_set_buttons_enabled(false)
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.end_battle(false)
	else:
		push_error("[CombatManager] GameManager gak ketemu! Kembali ke scene sebelumnya secara manual.")
		_fallback_exit_battle()

func _fallback_exit_battle() -> void:
	# Ganti path ini sesuai scene world map/menu utama project lu
	# Ini cuma jaga-jaga biar battle scene gak nyangkut selamanya pas dites standalone
	var world_scene_path = "res://src/world/world_map.tscn"
	if ResourceLoader.exists(world_scene_path):
		get_tree().change_scene_to_file(world_scene_path)
	else:
		push_error("[CombatManager] Scene fallback '%s' gak ketemu. Ganti path-nya di _fallback_exit_battle() sesuai project lu." % world_scene_path)

func update_ui_visual() -> void:
	print("[CombatManager] update_ui_visual() dipanggil -> HP: ", enemy_hp, " | Shield: ", enemy_shield)
	if enemy_hp_bar:
		enemy_hp_bar.value = enemy_hp
	else:
		push_error("[CombatManager] enemy_hp_bar NULL saat update_ui_visual dipanggil!")
	if enemy_shield_bar:
		enemy_shield_bar.value = enemy_shield
	else:
		push_error("[CombatManager] enemy_shield_bar NULL saat update_ui_visual dipanggil!")
