extends RigidBody3D

@export var inventory_item_component: InventoryItemComponent

func interacted(player: Node3D):
	player.get_node('InventoryComponent')._try_add_item(self, inventory_item_component.inventory_item_struct)
