extends Node
class_name InteractableComponent

signal interacted

func interact(interactor: Node):
	interacted.emit(interactor)
