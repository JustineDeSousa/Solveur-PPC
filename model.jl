# EXECUTION : dans une console Julia : 
# Se déplacer vers le bon répertoire :
# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# Exécuter le fichier : 
# include("model.jl")

##################################################################################
#Definition of the model
##################################################################################

###################################################
# Variable
###################################################
mutable struct Variable
	name::String
	domain::Array{Int64}
	value::Int64
	#Constructor that verify if the value is part of the domain
	Variable(name, domain, value) = value in domain ? error("Value out of the domain") : new(name, domain, value)
	Variable(name, domain) = new(name, domain, -1) #assign the value -1 if not given
end

#Just a way to write x1+x2 <= 2 for the type Variable
import Base.+, Base.-, Base.==, Base.!=, Base.<, Base.>, Base.<=, Base.>=
	+(x1::Variable, x2::Variable) = x1.value + x2.value
	-(x1::Variable, x2::Variable) = x1.value - x2.value
	==(x1::Variable, x2::Variable) = x1.value == x2.value
	!=(x1::Variable, x2::Variable) = x1.value != x2.value
	<(x1::Variable, x2::Variable) = x1.value < x2.value
	>(x1::Variable, x2::Variable) = x1.value > x2.value
	<=(x1::Variable, x2::Variable) = x1.value <= x2.value
	>=(x1::Variable, x2::Variable) = x1.value >= x2.value

import Base.println
function println(x::Variable)
	print(x.name, ": ")
	print(x.domain, " = ", x.value, "\n")
end
###################################################

###################################################
# Constraint
###################################################
mutable struct Constraint
	var::Tuple{Variable, Variable}
	couples::Array{Tuple{Int64,Int64}}
end

import Base.println
function println(cstr::Constraint)
	println(cstr.var[1])
	println(cstr.var[2])
	println(cstr.couples)
	println()
end
function other(cstr::Constraint, x::Variable)
	if !(x in cstr.var)
		return false
	end
	if x == cstr.var[1]
		return cstr.var[2]
	elseif x == cstr.var[2]
		return cstr.var[1]
	end
end
###################################################

###################################################
# Model
###################################################
mutable struct Model
	variables::Array{Variable} #Tableau de variables
	constraints::Array{Constraint}
end

function println(model::Model)
	println("########## Model ##########")
	println("## Variables : ")
	for x in model.variables
		println(x)
	end
	println("\n## Contraintes : ")
	for cstr in model.constraints
		println(cstr)
	end
	println("###########################")
end
###################################################

##################################################################################
##################################################################################
# Modification du modèle
##################################################################################

function add_constraint(model, z::Tuple{Variable,Variable}, couples)
	cstr = Constraint(z, couples)
	push!(model.constraints, cstr)
end

function wrap(model::Model, (x,y)::Tuple{Variable,Variable}, constr)
	couples = [(val_x,val_y) for val_x in x.domain for val_y in y.domain if constr(val_x,val_y)]
	add_constraint(model, (x,y), couples)
	return couples
end
##################################################################################

##################################################################################
# Fonctions sur le modèle
##################################################################################
function exists_constraint(model::Model, (x,y)::Tuple{Variable,Variable})
	for cstr in model.constraints
		if Set(cstr.var) == Set((x,y))
			return true
		end
	end
	return false
end


# Return the constraints concerning x
function constraints(model::Model, x::Variable)
	cstrs = []
	for cstr in model.constraints
		if x in cstr.var
			push!(cstrs, cstr)
		end
	end
	return cstrs
end
# Return the constraints concerning x et y
function constraints(model::Model, x::Variable, y::Variable)
	if x == y
		return []
	end
	cstrs = []
	for cstr in model.constraints
		if Set((x,y)) == Set(cstr.var)
			push!(cstrs, cstr)
		end
	end
	return cstrs
end



#Définition du modèle Voiture du cours
domain = [0,1,2] #bleu, rouge, jaune

caisse = Variable("caisse", domain)
enjoliveurs = Variable("enjoliveurs", domain)
pare_choc = Variable("pare_choc", domain)
capote = Variable("capote", domain)
println(capote)

cstr = Constraint((caisse,enjoliveurs),  [(1,1), (2,2)])
println(cstr)

model = Model( [caisse, enjoliveurs, pare_choc, capote], [])
add_constraint(model, (caisse,enjoliveurs),  [(1,1), (2,2)])
add_constraint(model, (caisse,pare_choc),  [(0,0), (1,1), (2,2)])
add_constraint(model, (capote,pare_choc),  [(0,0), (1,1), (2,2)])
add_constraint(model, (caisse,capote),  [(0,0), (1,2), (2,1)])
println(model)

#ajout d'une contrainte 
#wrap(model, (x,y), (x,y) -> x+y>=3)



####################################################################################################



