extends Node

var camera: RigidBody3D

func take_picture():
	if not camera == null:
		camera._take_photo(.02)
