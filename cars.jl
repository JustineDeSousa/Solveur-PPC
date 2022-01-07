include("resolution.jl")

#Définition du modèle Voiture du cours
function creation_variables()
	variables = []
	global caisse = Variable("caisse", [1,2,3])
	push!(variables, caisse )
	global enjoliveurs = Variable("enjoliveurs", [1,2,3])
	push!(variables, enjoliveurs )
	global pare_choc = Variable("pare_choc", [1,2,3])
	push!(variables, pare_choc )
	global capote = Variable("capote", [1,2,3])
	push!(variables, capote )
	return variables
end
function creation_constraints!(model::Model)
	add_constraint(model, (caisse,enjoliveurs),  [(2,2), (3,3)])
	add_constraint(model, (enjoliveurs,caisse),  [(2,2), (3,3)])
	add_constraint(model, (caisse,pare_choc),  [(1,1), (2,2), (3,3)])
	add_constraint(model, (pare_choc,caisse),  [(1,1), (2,2), (3,3)])
	add_constraint(model, (capote,pare_choc),  [(1,1), (2,2), (3,3)])
	add_constraint(model, (pare_choc,capote),  [(1,1), (2,2), (3,3)])
	add_constraint(model, (caisse,capote),  [(2,1), (2,3), (3,2)])
	add_constraint(model, (capote,caisse),  [(1,1), (2,3), (3,2)])
	return model
end
function creation_cars()
	model = Model( creation_variables(), [])
	creation_constraints!(model)
	return model
end

######## Model ########
model = creation_cars()

######## solve ########
solve(model)