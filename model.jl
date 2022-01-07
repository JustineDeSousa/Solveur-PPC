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
	Variable(name, domain, value) = value in domain ? new(name, domain, value) : error("Value out of the domain") 
	Variable(name, domain) = new(name, domain, -1) #assign the value -1 if not given
end

import Base.==, Base.!=
	==(x::Variable, y::Variable) = x.name == y.name
	!=(x::Variable, y::Variable) = x.name != y.name
	
import Base.println
function println(x::Variable)
	print(x.name, ": ")
	#print(x.domain)
	x.value == -1 ? println(" = __") : println(" = ", x.value)
end
###################################################

###################################################
# Constraint
###################################################
mutable struct Constraint
	var::Tuple{Variable, Variable}
	couples::Array{Tuple{Int64,Int64}}
end

function println(cstr::Constraint)
	println(cstr.var[1], " <-> ", cstr.var[2])
	println(cstr.couples)
end
function which_place(cstr::Constraint, x::Variable)
	if !(x in cstr.var)
		return 0
	end
	if x == cstr.var[1]
		return 1
	elseif x == cstr.var[2]
		return 2
	end
	return 0
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
	println("## ", length(model.variables), " variables : ")
	for x in model.variables
		println(x)
	end
	println("\n## ", length(model.constraints), " contraintes : ")
	for cstr in model.constraints
		println(cstr)
	end
	println("###########################")
end
function is_consistent(model::Model)
	consistent = true
	for x in model.variables
		if isempty(x.domain)
			consistent = false
			break
		end
	end
	return consistent
end
###################################################

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
function affiche_solution(model::Model)
	println(" ########## Solution : ")
	for x in model.variables
		println(x)
	end
end
# is there a constraint between x et y
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
		if (x,y) == cstr.var
			push!(cstrs, cstr)
		end
	end
	return cstrs
end
##################################################################################




#ajout d'une contrainte 
#wrap(model, (x,y), (x,y) -> x.value+y.value>=3)




