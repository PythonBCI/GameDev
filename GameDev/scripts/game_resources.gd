class_name GameResources
extends Resource

@export var biomass: int = 10
@export var live_prey: int = 0
@export var genetic_material: int = 0
@export var minerals: int = 5
@export var secretions: int = 0
@export var eggs: int = 0

# Storage limits as per specification
const BIOMASS_LIMIT = 100
const LIVE_PREY_LIMIT = 100
const GENETIC_MATERIAL_LIMIT = 50
const MINERALS_LIMIT = 75
const SECRETIONS_LIMIT = 200
const EGGS_LIMIT = 10

func add_biomass(amount: int) -> bool:
	if biomass + amount <= BIOMASS_LIMIT:
		biomass += amount
		return true
	return false

func add_live_prey(amount: int) -> bool:
	if live_prey + amount <= LIVE_PREY_LIMIT:
		live_prey += amount
		return true
	return false

func add_genetic_material(amount: int) -> bool:
	if genetic_material + amount <= GENETIC_MATERIAL_LIMIT:
		genetic_material += amount
		return true
	return false

func add_minerals(amount: int) -> bool:
	if minerals + amount <= MINERALS_LIMIT:
		minerals += amount
		return true
	return false

func add_secretions(amount: int) -> bool:
	if secretions + amount <= SECRETIONS_LIMIT:
		secretions += amount
		return true
	return false

func add_eggs(amount: int) -> bool:
	if eggs + amount <= EGGS_LIMIT:
		eggs += amount
		return true
	return false

func can_afford(biomass_cost: int = 0, live_prey_cost: int = 0, genetic_material_cost: int = 0, 
				minerals_cost: int = 0, secretions_cost: int = 0, eggs_cost: int = 0) -> bool:
	return (biomass >= biomass_cost and 
			live_prey >= live_prey_cost and 
			genetic_material >= genetic_material_cost and
			minerals >= minerals_cost and
			secretions >= secretions_cost and
			eggs >= eggs_cost)

func spend_resources(biomass_cost: int = 0, live_prey_cost: int = 0, genetic_material_cost: int = 0,
					minerals_cost: int = 0, secretions_cost: int = 0, eggs_cost: int = 0) -> bool:
	if can_afford(biomass_cost, live_prey_cost, genetic_material_cost, minerals_cost, secretions_cost, eggs_cost):
		biomass -= biomass_cost
		live_prey -= live_prey_cost
		genetic_material -= genetic_material_cost
		minerals -= minerals_cost
		secretions -= secretions_cost
		eggs -= eggs_cost
		return true
	return false
