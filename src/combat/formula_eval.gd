extends Node
## ==========================================================================
## formula_eval.gd — Element Weakness and Formula Evaluator
## Shadow of Cikabayan | Godot 4.6
## ==========================================================================

enum EnemyElementType {
	OPTICS_PHYSICS,    # Satpam Terbang — weakness: light reflection
	BIO_CHEMISTRY,     # Kuyang / Kunti — weakness: acidic compounds
	BOTANY_HERBICIDE,  # Zombie Cikabayan — weakness: herbicide formulas
	BIO_PHARMACY,      # Sosok Hitam — weakness: aromatherapy / calming agents
	AGROECOLOGY        # Penjaga Hutan (Final Boss) — weakness: ecosystem restoration
}

const FORMULA_MATRIX: Dictionary = {
	# Key format: "FormulaID|ElementType"
	"Reflective_Mirror|0":  { "multiplier": 2.5, "effect": "STUN" },
	"Acidic_Extract|1":     { "multiplier": 2.0, "effect": "NONE" },
	"Herbicide_Spray|2":    { "multiplier": 2.0, "effect": "NONE" },
	"Aromatherapy|3":       { "multiplier": 0.0, "effect": "RESTORE_SAN_30" },
	"Compost_Enzyme|4":     { "multiplier": 2.0, "effect": "WEAKEN" },
}

const DEFAULT_WRONG_RESULT = { "multiplier": 0.0, "effect": "SHIELD_RESTORED" }
const DEFAULT_NORMAL_RESULT = { "multiplier": 1.0, "effect": "NONE" }

func evaluate(formula_id: String, element: int) -> Dictionary:
	var key = formula_id + "|" + str(element)
	if FORMULA_MATRIX.has(key):
		return FORMULA_MATRIX[key]
	return DEFAULT_WRONG_RESULT
