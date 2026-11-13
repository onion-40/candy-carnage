
extends Node

signal inventory_changed(
	bones: int,
	organs: int,
	eyeballs: int
)

const START_BONES: int = 30
const START_ORGANS: int = 15
const START_EYEBALLS: int = 5

var bones: int = START_BONES
var organs: int = START_ORGANS
var eyeballs: int = START_EYEBALLS


# Autoloads survive scene reloads, so a restart must reset the inventory.
func reset() -> void:
	bones = START_BONES
	organs = START_ORGANS
	eyeballs = START_EYEBALLS

	inventory_changed.emit(bones, organs, eyeballs)


func add_resources(
	bone_amount: int,
	organ_amount: int,
	eyeball_amount: int
) -> void:
	bones += bone_amount
	organs += organ_amount
	eyeballs += eyeball_amount

	inventory_changed.emit(bones, organs, eyeballs)


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

	if can_afford(bone_cost, organ_cost, eyeball_cost):
		bones -= bone_cost
		organs -= organ_cost
		eyeballs -= eyeball_cost

		inventory_changed.emit(bones, organs, eyeballs)
		success = true

	return success
