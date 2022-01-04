# EXECUTION : dans une console Julia : 
# Se déplacer vers le bon répertoire :
# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# Exécuter le fichier : 
# include("model.jl")


mutable struct Variable
	domain::Array{Int64}
	value::Int64
end

mutable struct Constraint
	var1::Variable
	var2::Variable
	couples::Array{Tuple{Int64,Int64}}
end

mutable struct Model
	x::Array{Variable} #Tableau de variables x[1], x[2], ...
	constraints::Array{Constraint}
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