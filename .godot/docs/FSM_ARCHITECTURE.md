# FSM Architecture — Shadow of Cikabayan

> **For AI Agents:** This document specifies the Finite State Machine design for both
> the Player Controller and the Turn-Based Combat system.
> Implementation language: GDScript 4.x
> Owner: Melandri Rasya Arindhi

---

## 1. Player Movement FSM

### States

```
┌─────────────────────────────────────────────┐
│               PLAYER FSM                     │
│                                              │
│   IDLE ◄──────────────────────────┐         │
│     │                             │         │
│     ▼  (input detected)           │         │
│   WALK ─────────── (no input) ────┘         │
│     │                                        │
│     ▼  (near interactable + E pressed)       │
│   INTERACT ── (animation done) ──► IDLE      │
│     │                                        │
│     ▼  (enter combat zone)                   │
│   IN_COMBAT ── (combat ends) ──► IDLE        │
└─────────────────────────────────────────────┘
```

### State Enum & Transitions

```gdscript
# src/entities/player/player.gd

enum PlayerState {
    IDLE,
    WALK,
    INTERACT,
    IN_COMBAT
}

var current_state: PlayerState = PlayerState.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        PlayerState.IDLE:      _state_idle()
        PlayerState.WALK:      _state_walk(delta)
        PlayerState.INTERACT:  _state_interact()
        PlayerState.IN_COMBAT: pass  # Combat manager takes over

func _change_state(new_state: PlayerState) -> void:
    current_state = new_state
    match new_state:
        PlayerState.IDLE:
            $AnimatedSprite2D.play("idle_" + facing_direction)
        PlayerState.WALK:
            $AnimatedSprite2D.play("walk_" + facing_direction)
        PlayerState.INTERACT:
            $AnimatedSprite2D.play("interact")
```

---

## 2. Combat FSM

### Battle Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│                   COMBAT FSM                         │
│                                                      │
│   InitBattle                                         │
│       │  Load Irving & EnemyResource data            │
│       ▼                                              │
│   CheckSpeed                                         │
│       │  Compare speed stats → determine turn order  │
│       ▼                                              │
│   ActionTurn ◄──────────────────────────────┐       │
│       │  Wait for player input OR            │       │
│       │  Execute enemy AI action             │       │
│       ▼                                      │       │
│   EvalFormula                                │       │
│       │  Look up FORMULA_MATRIX              │       │
│       │  Apply damage / effect               │       │
│       ▼                                      │       │
│   CheckWinLoseCondition ─── CONTINUE ────────┘       │
│       │                                              │
│       ├─── VICTORY  (enemy contamination = 0)        │
│       └─── DEFEAT   (Irving HP or SAN = 0)           │
└─────────────────────────────────────────────────────┘
```

### Full State Enum & Implementation

```gdscript
# src/combat/combat_manager.gd

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
var current_formula_id: String = ""

func start_battle(enemy_res: EnemyResource) -> void:
    battle_state = BattleState.INIT_BATTLE
    _process_state()

func _process_state() -> void:
    match battle_state:
        BattleState.INIT_BATTLE:   _init_battle()
        BattleState.CHECK_SPEED:   _check_speed()
        BattleState.ACTION_TURN:   _action_turn()
        BattleState.EVAL_FORMULA:  _eval_formula()
        BattleState.CHECK_WIN_LOSE: _check_win_lose()
        BattleState.VICTORY:       _trigger_victory()
        BattleState.DEFEAT:        _trigger_defeat()

func _init_battle() -> void:
    # Load enemy resource, initialize UI
    battle_state = BattleState.CHECK_SPEED
    _process_state()

func _check_speed() -> void:
    var irving_speed = PlayerStats.speed
    var enemy_speed  = current_enemy.speed
    is_player_turn = irving_speed >= enemy_speed
    battle_state = BattleState.ACTION_TURN
    _process_state()

func _eval_formula() -> void:
    var result = FormulaEval.evaluate(current_formula_id, current_enemy.element_type)
    # Apply result.multiplier to damage calculation
    # Apply result.effect (STUN, RESTORE_SAN, SHIELD_RESTORED)
    battle_state = BattleState.CHECK_WIN_LOSE
    _process_state()
```

---

## 3. State Ownership Table

| State | Trigger | Owner Script |
|-------|---------|-------------|
| `INIT_BATTLE` | `Area2D` combat zone entered | `combat_manager.gd` |
| `CHECK_SPEED` | Auto after init | `combat_manager.gd` |
| `ACTION_TURN` | Auto, waits for input signal | `combat_manager.gd` + UI |
| `EVAL_FORMULA` | Signal: `item_used(formula_id)` | `formula_eval.gd` |
| `CHECK_WIN_LOSE` | After every formula eval | `combat_manager.gd` |
| `VICTORY` | Enemy HP/contamination = 0 | `game_manager.gd` |
| `DEFEAT` | Irving HP or SAN = 0 | `game_manager.gd` |
