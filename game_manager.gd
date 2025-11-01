extends Node3D

var cars: Array[Node3D]
var players: Array[Node3D]
@export var ufos: Array[Node3D]

func register_cars(car: Node3D):
	if not cars.has(car):
		cars.append(car)

func register_players(player: Node3D):
	if not players.has(player):
		players.append(player)

func register_ufos(ufo: Node3D):
	if not ufos.has(ufo):
		ufos.append(ufo)
