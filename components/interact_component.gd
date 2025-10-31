extends Node
class_name InteractComponent

@export var interact_ray: RayCast3D

func _on_input_component_interact(interactor: Node) -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()

		var interactable = collider.get_node_or_null("InteractableComponent")
		if interactable:
			interactable.interact(interactor)
