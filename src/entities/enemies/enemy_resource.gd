extends Resource
class_name EnemyResource

enum EnemyElementType {
	OPTICS_PHYSICS,    # Satpam Terbang
	BIO_CHEMISTRY,     # Kuyang / Kunti
	BOTANY_HERBICIDE,  # Zombie Cikabayan
	BIO_PHARMACY,      # Sosok Hitam
	AGROECOLOGY        # Penjaga Hutan
}

@export var enemy_name: String = "Kunti"
@export var max_hp: int = 100
@export var contamination_level: int = 100
@export var speed: int = 8
@export var element_type: EnemyElementType = EnemyElementType.BIO_CHEMISTRY
@export var attack_damage: int = 15
@export var sprite_path: String = ""
