# EXECUTION : dans une console Julia : 
# Se déplacer vers le bon répertoire :
# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# Exécuter le fichier : 
# include("model.jl")

##################################################################################
#Definition of the model
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
####################################################################################################
#Beginning of the solver
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
###################################################################################################################
#Algorithme of forward checking
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

#function to test if a couple of values are in the constraint or not
function test(model::Model, var1::Variable, var2::Variable, values::Tuple{Int,Int})
			for cstr in model.constraints
				if Set([var1,var2])==cstr.var
					if (values in cstr.couples)
						return true
					end
				end
			end
			return false
end

################################################################################################################
#Algorithmes ARC
function AC3!(model::Model,Restrict::Array{Int,1}, var_instancie::Array{Variable,1})
              aTester = Array{Tuple{Variable,Variable}}(undef,0)
              for x in model.variables 
                  if x in var_instancie
                      Restrict[findall(y->y==x,model.variables)[1]] = 1 #lenght of the domain for the variables in the instance
                      position = findall(e->e==x.value, x.domain)[1] #position of the value of the variable in its domain
                      splice!(x.domain, position) #delate the value in the domain
                      splice!(x.domain, 1:0, x.value) #add the value of the variable in the first place of the domain
                  end
              end
			  #this is to move the value of the variable in the instance to the first place in the domain
              for x in model.variables
                  for y in model.variables
                      if x != y
                          push!(aTester, (x,y)) #add all the possible combinations of variables to test
                      end
                  end
              end
              while length(aTester) != 0
                  #println("reste a tester :" ,length(aTester))
                  (x,y)=pop!(aTester) #remove the last tuple of the list to test and save it in a tuple to work with
				  aux_place_x=findall(e->e==x,model.variables)[1]
				  aux_place_y=findall(e->e==y,model.variables)[1]
                  for a in x.domain[1:Restrict[aux_place_x]]
                      unsupported = true
                      count_y_index = 1 #counter to move in the domain of y
                      while (unsupported  && count_y_index < Restrict[aux_place_y]+1)
                          b = y.domain[count_y_index]
                          if test(model, x, y, (a,b))
                              unsupported = false
                              break
                          end
                          count_y_index+=1
                      end
                      if unsupported
                          place = Restrict[aux_place_x] + 1
                          position = findall(e-> e==a, x.domain)[1]
                          splice!(x.domain, place:(place-1), a) #add the unsupported value at the end of the domain array
                          splice!(x.domain, position) #errased the unsupported value from the initial position in the domain
                          Restrict[aux_place_x] -= 1 #cut the domain lenght, to not test again the same value that we already know that is unsupported
                          for z in model.variables
                              if (z != y  && z != x)
                                  push!(aTester, (z,x)) #add all the combinations of variables (x,z) to the atester list
                              end
                          end
                      end
                  end
              end
end


function initAC4!(model::Model, var_instancie::Array{Variable,1}, Restrict::Array{Int,1})
        taille_Dom = maximum([length(x.domain) for x in model.variables])
        Q = Array{Tuple{Variable,Int}}(undef,0)
        S = [Array{Tuple{Variable,Int}}(undef,0) for k in 1:length(model.variables), m in 1:taille_Dom]
        count = fill(0, size(Array{Int,3}(undef, length(model.variables), length(model.variables), taille_Dom)))
        # All instanciated values get fixed to their values
        for x in model.variables
            if x in var_instancie
                Restrict[findall(e->e==x,model.variables)[1]] = 1
                position = findall(e->e==x.value, x.domain)[1]
                splice!(x.domain, position)
                splice!(x.domain, 1:0, x.value)
            end
        end
        for x in model.variables
		aux_pos_x=findall(e->e==x,model.variables)[1]
            for y in model.variables
			aux_pos_y=findall(e->e==y,model.variables)[1]
                if x != y
                    for a in x.domain[1:Restrict[aux_pos_x]]
                        total = 0
                        for b in y.domain[1:Restrict[aux_pos_y]]
                            if test(model, x, y, (a,b)) #if the values a and b are in the constraints we add the couple varx and value a to s(<vary,b>)
                                total += 1
                                push!(S[aux_pos_y,b+1], (x,a))
                            end
                        end
                        count[aux_pos_x,aux_pos_y,a+1] = total #we set the counter in the amount of values that are consistent for the variable x, y with x=a
                        if count[aux_pos_x,aux_pos_y,a+1] == 0 #if the counter is 0 we remove the value a of the domain
                            place = Restrict[aux_pos_x] + 1
                            position = findall(e->e==a, x.domain)[1]
                            splice!(x.domain, place:(place-1), a)
                            splice!(x.domain, position)
                            Restrict[aux_pos_x] -= 1
                            push!(Q, (x,a)) #we add the variable x and the value a (this combination is not consistant with any value of y) to the list Q
                        end
                    end
                end
            end
        end
        return Q, S, count
    end
function AC4!(model::Model,Restrict::Array{Int,1}, var_instancie::Array{Variable,1})
        Q, S, count = initAC4!(model, var_instancie, Restrict)
        while length(Q) != 0
            (y,b) = pop!(Q) #we took a couple from list Q
			aux_pos_y=findall(e->e==y,model.variables)[1]
            for (x,a) in S[aux_pos_y,b+1] #we take all the combinations of variable and value that are consistant with the couple from list Q
				aux_pos_x=findall(e->e==x,model.variables)[1]
                count[aux_pos_x,aux_pos_y,a+1] -= 1
                if count[aux_pos_x,aux_pos_y,a+1] == 0 && a in x.domain[1:Restrict[aux_pos_x]] #if the counter is 0 and a is in the domain of x, we eliminate a from the domain and we add the couple x,a to the list Q
                    place = Restrict[aux_pos_x] + 1
                    position = find(e->e==a, x.domain)
                    splice!(x.domain, place:(place-1), a)
                    splice!(x.domain, position)
                    push!(Q, (x,a))
                end
            end
        end
    end

#####################################################################################################################
#bactracking
function Backtrack(model::Model, var_instancie::Array{Variable,1}, domaine_long::Array{Int,1}, frwd=true, arc="ARC4")
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
	
	if arc == "ARC3"
        AC3!(model,domaine_long, var_instancie)
        #println(" on reboucle ")
        if 0 in domaine_long
			print("Not arc-consistante")
            return false
        else
            println("AC 3 succes")
        end
    end
	if arc == "ARC4"
        AC4!(model,domaine_long, var_instancie)
        if 0 in domaine_long
			print("Not arc-consistante")
            return false
        else
            println("AC 4 reussie ")
        end
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
#################################################################################################################
#end of solver

var_instancie=Array{Variable,1}(undef,0)

nd_numero=0

restr = Int[length(v.domain) for v in model.variables]
	

@time Backtrack(model, var_instancie, restr)

for x in 1:length(model.variables)
	print("variable ",x, " ")
	println(model.variables[x].value)
end