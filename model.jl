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
	domain::Array{Int64}
	value::Int64
	#Constructor that verify if the value is part of the domain
	Variable(domain,value) = value in domain ? error("Value out of the domain") : new(domain,value)
	Variable(domain) = new(domain,-1) #assign the value -1 if not given
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

ops = [+, -, ==, !=, <, >, <=, >= ] #Not sure I need it
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
	println("########## Constraint : ")
	for x in cstr.var
		println("\t",x)
	end
	println("\tCouples = ", cstr.couples)
	println("########################")
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
	println("########################### Model ############################")
	for x in model.variables
		println(x)
	end
	for cstr in model.constraints
		println(cstr)
	end
	println("##############################################################")
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

#Définition d'un modèle
domain = [0,1,2,3]
x = Variable(domain)
y = Variable(domain)
cstr = Constraint((x,y), [(x_val,y_val) for x_val in x.domain for y_val in y.domain])
model = Model( [x,y], [cstr])

#ajout d'une contrainte 
wrap(model, (x,y), (x,y) -> x+y>=3)



####################################################################################################



