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
	var::Set{Variable}
	couples::Array{Tuple{Int64,Int64}}
end


mutable struct Model
	variables::Array{Variable} #Tableau de variables x[1], x[2], ...
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
constraint = Constraint(Set([x1,x2]),couples)

#Définition du modèle
var = [x1, x2]
cstr = [constraint]
model = Model(var, cstr)

		

#ajout d'une contrainte 
#wrap(model, x1, x2, (x1,x2) -> x1+x2>=3)

# function to check if the variables in the instance comply with the constraints
function verification(model::Model)
        verif = true
        for x in model.variables
            for y in model.variables
                if x != y
					for cstr in model.constraints
						if cstr.var == Set([x,y])
							if !((x.value,y.value) in cstr.couples)
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

function Backtrack(model::Model, var_instancie::Array{Variable,1})
	global nd_numero += 1
	
	
	if !verification(model) #Si une contrainte est violée
		return false
	end
	
	if length(var_instancie) == length(model.variables)
		print("Nombre de noeuds parcourus: ")
        println(nd_numero)
        print("Temps de résolution ")
        return true
	end
	
	variables_non_instancie = setdiff(model.variables, var_instance) #make a set with the variables that are not instantiated
    
	x = variables_non_instancie[rand(1:end)] #variable to branch
    
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	
	for val in x.domain
        x.value = val #add the new value to the instance
        #Restric2 = deepcopy(domaine_long)
        #last_choose = (next_choose, val)

        if Backtrack(model, var_instancie)
                     #println(arc)
            return true
        end
        #delete!(instance , next_choose)
    end

    #current_choose = pop!(var_instancie)
    return false

    #print("Nombre de noeuds parcourus: ")
    #println(nd_numero)
	
	
end



var_instancie=Array{Variable,1}(undef,0)

nd_numero=0

@time Backtrack(model, var_instancie)
for x in model.variables
	print(x.value, " ")
end
