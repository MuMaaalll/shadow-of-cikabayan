extends Label

# Mengambil referensi langsung ke CharacterBody2D (Player) tempat script inventory berada
@onready var player: CharacterBody2D = $"../../.."

func _process(_delta: float) -> void:
	if not player: return
	
	# Bersihkan teks lama terlebih dahulu
	text = ""
	
	# Jika kantong player masih kosong melompong
	if player.inventory.is_empty():
		text = "Kosong"
		return
		
	# Looping semua item yang ada di dictionary inventory milik player
	for item_name in player.inventory:
		var jumlah = player.inventory[item_name]
		# Susun teksnya ke bawah secara otomatis
		text += item_name + ": " + str(jumlah) + "\n"
