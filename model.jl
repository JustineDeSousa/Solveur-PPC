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
x2.value=2


#Définition d'une contrainte
couples = [ (0,0), (0,1), (1,0), (1,1) ] #x1 + x2 <= 2
constraint1 = Constraint(x1,x2,couples)

#Définition du modèle
var = [x1, x2]
cstr = [constraint1]
model1 = Model(var, cstr)

		

#ajout d'une contrainte 
#wrap(model1, x1, x2, (x1,x2) -> x1+x2>=3)

# function to check if the variables in the instance comply with the constraints
function verification(instance ::Dict{Variable, Int},
                     model::Model)
        verif = true
        for x in keys(instance)
            for y in keys(instance)
                if x != y
					for cstr in model1.constraints
						if (cstr.var1 == x && cstr.var2 == y) || (cstr.var1 == y && cstr.var2 == x)
							if !((instance[x],instance[y]) in cstr.couples)
								verif = false
								break
							end
						end                                                                
                    end
                end
            end
        end
    return verif
end

function Backtrack(instance::Dict{Variable, Int},
                     model::Model,
					 var_instance::Array{Variable,1},  #array with the already set variables
					 domaine_long::Array{Int,1} ) #length of the domain of each variable
					 
	global nd_numero += 1
	if !verification(instance, model)
		return false
	end
	if length(keys(instance)) == length(model.x)
		print("Nombre de noeuds parcourus: ")
        println(nd_numero)
        print("Temps de résolution ")
        return true
	end
	variables_non_instance = setdiff(model.x, var_instance) #make a set with the variables that are not instantiated
    next_choose = model.x[rand(1:end)] #variable to branch
    long_nc = domaine_long[next_choose.value] #lenght of the domain of the choosen variable
    push!(var_instance, next_choose) #add the new variable to branch to the variables instantiated
	for val in model.x[next_choose.value].domain
        instance[next_choose] = val #add the new value to the instance
        Restric2 = deepcopy(domaine_long)
        last_choose = (next_choose, val)

        if Backtrack(instance , model, var_instance, Restric2)
                     #println(arc)

            return true
        end
        delete!(instance , next_choose)
    end

    current_choose = pop!(var_instance)
    return false

    print("Nombre de noeuds parcourus: ")
    println(nd_numero)
	
	
end


instance = Dict{Variable, Int}() #empty dictionary
var_instance=Array{Variable,1}(undef,0)
domain_long= Array{Int,1}(undef,0)
nd_numero=0
for var in model1.x
	push!(domain_long,length(var.domain))
end
@time Backtrack(instance, model1, var_instance, domain_long)
println(instance)