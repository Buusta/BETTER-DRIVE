extends Node
class_name InventoryComponent

@export var hold_point: Node3D
@export var world_access: WorldAccess
@export var number_slots := 5

var slots: Array[Node3D]
var held_slot: int = -1

func _try_add_item(item: Node3D, _inventory_item: InventoryItemStruct):
	if len(slots) < number_slots and not slots.has(item):
		slots.append(item)

		item.get_parent().remove_child(item)
		hold_point.add_child(item)

		item.freeze = true
		item.get_node('InventoryItemComponent').start_holding()
		item.global_transform = hold_point.global_transform

		if held_slot == -1:
			held_slot = slots.find(item)
		else:
			item.visible = false

func hold_slot(slot: int):
	print(slot)
	if slot <= len(slots):
		if not slots[slot - 1] == null:
			var item = slots[slot - 1]
			if held_slot == slot - 1:
				item.visible = false
				held_slot = -1
				return
			elif not held_slot == -1:
				print(held_slot)
				slots[held_slot].visible = false

			item.visible = true
			held_slot = slot - 1

func drop_item():
	if not held_slot == -1:
		var item = slots[held_slot]
		var held_transform = item.global_transform

		item.freeze = false
		item.visible = true
		item.get_node('InventoryItemComponent').stop_holding()

		hold_point.remove_child(item)
		world_access.world.add_child(item)
		item.global_transform = held_transform

		slots[held_slot] = null
		held_slot = -1
