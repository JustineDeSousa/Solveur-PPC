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
x2.value=0


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

#Algorithme de forward checking
function forward_checking!(model::Model, next_choose::Variable, var_instancie::Array{Variable,1},RestrictDom::Array{Int,1})
        for y in setdiff(model.variables, var_instancie)
            taille = length(y.domain)
            Dom2 = deepcopy(y.domain)
            ix = deepcopy(taille) + 1
            pos_actuel = 1
            for b in y.domain[1:taille]
				for cstr in model.constraints
					if Set([next_choose,y])== cstr.var
						if !((next_choose.value,b) in cstr.couples) #if the combination of the value choosen and some value of some variable non instantiated is not in the constraints, we move that value to the end of the domain
							splice!(Dom2, ix:(ix-1), b)
							splice!(Dom2, pos_actuel)
							ix -= 1
						else
							pos_actuel += 1
						end
					end
				end
            end
            y.domain = Dom2 #update the domain
            RestrictDom[findall(x->x==y,model.variables)[1]] = ix - 1 #update the lenght of the domain, to not consider the values that are not in the constraints
        end
    end


function Backtrack(model::Model, var_instancie::Array{Variable,1}, domaine_long::Array{Int,1}, frwd=true)
	global nd_numero += 1
	
	
	if !verification(model) #Si une contrainte est violée
        print("the constraints are not verify")
		return false	
	end
	
	if length(var_instancie) == length(model.variables) #if all the variables are instantiated the problem is solved
		print("Nombre de noeuds parcourus: ")
        println(nd_numero)
        print("Temps de résolution ")
        return true
	end
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
    
	next_choose = variables_non_instancie[rand(1:end)] #variable to branch
    
	push!(var_instancie, next_choose) #add the new variable to branch to the variables instantiated
	
	for val in next_choose.domain
        next_choose.value = val #add the new value to the instance
        Restric2 = deepcopy(domaine_long) #we need this to select some part of the domains without change the domain in case we need that values in other branch
        #last_choose = (next_choose, val)
		if frwd
            forward_checking!(model, next_choose, var_instancie, Restric2) #apply forward checking
        end

        if Backtrack(model, var_instancie, Restric2)
                     #println(arc)
            return true
        end
        #delete!(instance , next_choose)
    end

    current_choose = pop!(var_instancie)
    return false

    print("Nombre de noeuds parcourus: ")
    println(nd_numero)
	
	
end


var_instancie=Array{Variable,1}(undef,0)

nd_numero=0

restr = Int[length(v.domain) for v in model.variables]
	

@time Backtrack(model, var_instancie, restr)

for x in 1:length(model.variables)
	print("variable ",x, " ")
	println(model.variables[x].value)
end
