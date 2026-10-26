
extends Node

signal inventory_changed(
	bones: int,
	organs: int,
	eyeballs: int
)

var bones: int = 30
var organs: int = 15
var eyeballs: int = 3


func add_resources(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	bones += bone_amount
	organs += organ_amount
	eyeballs += eyeball_amount

	inventory_changed.emit(
		bones,
		organs,
		eyeballs
	)


func can_afford(
	bone_cost: int,
	organ_cost: int,
	eyeball_cost: int
) -> bool:
	return (
		bones >= bone_cost
		and organs >= organ_cost
		and eyeballs >= eyeball_cost
	)


func spend_resources(
	bone_cost: int,
	organ_cost: int,
	eyeball_cost: int
) -> bool:
	var success = false

	if can_afford(
		bone_cost,
		organ_cost,
		eyeball_cost
	):
		bones -= bone_cost
		organs -= organ_cost
		eyeballs -= eyeball_cost

		inventory_changed.emit(
			bones,
			organs,
			eyeballs
		)

		success = true

	return success
