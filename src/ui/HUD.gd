extends Node

# Dictionary untuk menyimpan data inventory. Formatnya -> "Nama_Item": Jumlah
var inventory: Dictionary = {}

## Fungsi untuk menambah item ke inventory
func add_item(item_name: String, amount: int = 1) -> void:
	if inventory.has(item_name):
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	
	print("Inventory Terkini: ", inventory) # Debug di console

## Fungsi untuk mengecek jumlah item (berguna untuk syarat quest/crafting)
func get_item_count(item_name: String) -> int:
	if inventory.has(item_name):
		return inventory[item_name]
	return 0
