extends Node
class_name SeatComponent

signal activate

@export var driver_seat: bool
@export var car: Node3D

var passenger: Node3D = null

func interact_seat(player: Node3D):
	if passenger == null:
		player.get_parent().remove_child(player)
		car.add_child(player)

		player.global_position = car.player_seat.global_position
		player.get_node('CameraArm').global_rotation = car.player_seat.global_rotation

		player.get_node('PlayerShape').disabled = true
		player.freeze = true

		passenger = player
		var player_movement_component = player.get_node('MovementComponent')
		player_movement_component.state_override(player_movement_component.PlayerState.DRIVING)

		if driver_seat:
			activate.emit(true)

	elif not passenger == null:
		car.remove_child(player)
		car.get_parent().add_child(player)

		player.global_position = car.exit_point.global_position

		player.get_node('PlayerShape').disabled = false
		player.freeze = false

		passenger = null
		var player_movement_component = player.get_node('MovementComponent')
		player_movement_component.state_override(player_movement_component.PlayerState.AIR)

		if driver_seat:
			activate.emit(false)
