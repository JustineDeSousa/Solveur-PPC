# EXECUTION : dans une console Julia : 
# Se déplacer vers le bon répertoire :
# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# Exécuter le fichier : 
# include("model.jl")


mutable struct Variable
	domain::Array{Int64}
	value::Int64
	
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


mutable struct Constraint
	var1::Variable
	var2::Variable
	couples::Array{Tuple{Int64,Int64}}
end

mutable struct Constraint
	var::Set{Variable}
	couples::Array{Tuple{Int64,Int64}}
end

for cstr in model1.constraints
	if var == Set([x1,x3])
		##What you want to do
	end
end

mutable struct Model
	x::Array{Variable} #Tableau de variables x[1], x[2], ...
	constraints::Array{Constraint}
end

function add_constraint(model, var1, var2, couples)
	cstr = Constraint(var1, var2, couples)
	push!(model.constraints, cstr)
end

function wrap(model::Model, var1::Variable, var2::Variable, constr)
	couples = []
	for val1 in var1.domain
		for val2 in var2.domain
			if constr(val1,val2)
				push!(couples, (val1,val2))
			end
		end
	end
	add_constraint(model, var1, var2, couples)
end

# Définition du domaine
domain1 = [0,1,2,3]

# Définition des variables
x1 = Variable(domain1, domain1[1])
x2 = Variable(domain1, domain1[1])

println("Value of x1 : ", x1.value)
x1.value = 1
println("Value of x1 : ", x1.value)


#Définition d'une contrainte
couples = [ (0,0), (0,1), (1,0), (1,1) ] #x1 + x2 <= 2
constraint1 = Constraint(x1,x2,couples)

#Définition du modèle
var = [x1, x2]
cstr = [constraint1]
model1 = Model(var, cstr)

		

#ajout d'une contrainte 
wrap(model1, x1, x2, (x1,x2) -> x1+x2>=3)