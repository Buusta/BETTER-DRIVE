extends Node
class_name InventoryItemComponent

@export var inventory_item_struct: InventoryItemStruct
@export var collision_shape: CollisionShape3D

func start_holding():
	collision_shape.disabled = true

func stop_holding():
	collision_shape.disabled = false
