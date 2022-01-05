# EXECUTION : dans une console Julia : 
# Se déplacer vers le bon répertoire :
# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# Exécuter le fichier : 
# include("resolution.jl")

include("model.jl")

###################################################################################################################
#Beginning of the solver
###################################################################################################################

# function to check if the variables in the instance comply with the constraints
function verification(model::Model)
		verif = true
        for x in model.variables
            for y in model.variables
				if x != y
					
					for cstr in constraints(model, x, y)
						if !((x.value,y.value) in cstr.couples)
							verif = false
							break
						end                                                                
                    end
                end
            end
        end
    return verif
end
verification(model)
###################################################################################################################

#Algorithme of forward checking
function forward_checking!(model::Model, var_instancie::Array{Variable,1}, x::Variable)
	# x is the variable that just has been instanciated
	for y in setdiff(model.variables, var_instancie)
		#taille = length(y.domain)
		#Dom2 = deepcopy(y.domain)
		#ix = deepcopy(taille) + 1
		#pos_actuel = 1
		if exists_constraint(model, (x,y)) #Si il existe une cte entre x et y
			for b in y.domain
				if !((x.value,b) in cstr.couples) 
				#if (x.value,b) is not in the constraint we remove b from the y domain
					pop!(y.domain, b)
				end
			end
		end
	end
end







################################################################################################################
###########Algorithmes ARC
################################################################################################################
#function to test if a couple of values are in the constraints or not
function is_admissible(model::Model, (x,y)::Tuple{Variable,Variable}, couple::Tuple{Int,Int})
	for cstr in model.constraints
		if Set((x,y)) == Set(cstr.var)
			if (couple in cstr.couples)
				return true
			end
		end
	end
	return false
end
function is_supported(cstr::Constraint, x::Variable, a::Int64)
	supported = false
	if cstr.var[1] == x
		for b in cstr.var[2].domain
			if (a,b) in cstr.couples
				supported = true
				break
			end
		end
	elseif cstr.var[2] == x
		for b in cstr.var[1].domain
			if (b,a) in cstr.couples
				supported = true
				break
			end
		end
	end
	return supported
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

# function is_consistent(model::Model, x::Variable, a::Int64)
	# for cstr in constraints(model,x)
		# if !is_consistent(cstr, x, a)
			# x.domain = filter!(x->x!=a, x.domain)
		# end
	# end
	# return false
# end

# AC1
function AC1!(model::Model)
	println("AC1 : ")
	term = false
	while !term
		term = true
		for cstr in model.constraints
			x = cstr.var[1]
			for a in x.domain
				if !is_supported(cstr, x, a)
					x.domain = filter!(x->x!=a, x.domain)
				end
			end
			y = cstr.var[2]
			for b in y.domain
				if !is_supported(cstr, y, b)
					y.domain = filter!(x->x!=b, y.domain)
				end
			end	
		end
	end
end
@time AC1!(model)
println(model)

#AC3
function AC3!(model::Model)
	println("AC3 : ")
	aTester = Array{Constraint}(undef,0)
	for cstr in model.constraints
		push!(aTester, cstr)
	end
	# for x in model.variables 
	  # if x in var_instancie
		  # Restrict[findall(y->y==x,model.variables)[1]] = 1 #lenght of the domain for the variables in the instance
		  # position = findall(e->e==x.value, x.domain)[1] #position of the value of the variable in its domain
		  # splice!(x.domain, position) #delate the value in the domain
		  # splice!(x.domain, 1:0, x.value) #add the value of the variable in the first place of the domain
	  # end
	# end
	#this is to move the value of the variable in the instance to the first place in the domain
	# for x in model.variables
	  # for y in model.variables
		  # if x != y
			  # push!(aTester, (x,y)) #add all the possible combinations of variables to test
		  # end
	  # end
	# end
	while !isempty(aTester)
		cstr = pop!(aTester) #remove the last constraint of the list to test and save it in a tuple to work with
		(x,y) = cstr.var
		for a in x.domain
			if !is_supported(cstr, x, a)
				x.domain = filter!(x->x!=a, x.domain)
				for cstr in constraints(model, x)
					z = other(cstr, x)
					if z!=y
						push!(aTester, cstr)
					end
				end
			end
		end

	  # aux_place_x=findall(e->e==x,model.variables)[1]
	  # aux_place_y=findall(e->e==y,model.variables)[1]
	  # for a in x.domain[1:Restrict[aux_place_x]]
		  # unsupported = true
		  # count_y_index = 1 #counter to move in the domain of y
		  # while (unsupported  && count_y_index < Restrict[aux_place_y]+1)
			  # b = y.domain[count_y_index]
			  # if test(model, x, y, (a,b))
				  # unsupported = false
				  # break
			  # end
			  # count_y_index+=1
		  # end
		  # if unsupported
			  # place = Restrict[aux_place_x] + 1
			  # position = findall(e-> e==a, x.domain)[1]
			  # splice!(x.domain, place:(place-1), a) #add the unsupported value at the end of the domain array
			  # splice!(x.domain, position) #errased the unsupported value from the initial position in the domain
			  # Restrict[aux_place_x] -= 1 #cut the domain lenght, to not test again the same value that we already know that is unsupported
			  # for z in model.variables
				  # if (z != y  && z != x)
					  # push!(aTester, (z,x)) #add all the combinations of variables (x,z) to the atester list
				  # end
			  # end
		  # end
	  # end
	end
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

@time AC3!(model)
println(model)


	


# function initAC4!(model::Model, var_instancie::Array{Variable,1}, Restrict::Array{Int,1})
	# taille_Dom = maximum([length(x.domain) for x in model.variables])
	# Q = Array{Tuple{Variable,Int}}(undef,0)
	# S = [Array{Tuple{Variable,Int}}(undef,0) for k in 1:length(model.variables), m in 1:taille_Dom]
	# count = fill(0, size(Array{Int,3}(undef, length(model.variables), length(model.variables), taille_Dom)))
	# All instanciated values get fixed to their values
	# for x in model.variables
		# if x in var_instancie
			# Restrict[findall(e->e==x,model.variables)[1]] = 1
			# position = findall(e->e==x.value, x.domain)[1]
			# splice!(x.domain, position)
			# splice!(x.domain, 1:0, x.value)
		# end
	# end
	# for x in model.variables
	# aux_pos_x=findall(e->e==x,model.variables)[1]
		# for y in model.variables
		# aux_pos_y=findall(e->e==y,model.variables)[1]
			# if x != y
				# for a in x.domain[1:Restrict[aux_pos_x]]
					# total = 0
					# for b in y.domain[1:Restrict[aux_pos_y]]
						# if test(model, x, y, (a,b)) #if the values a and b are in the constraints we add the couple varx and value a to s(<vary,b>)
							# total += 1
							# push!(S[aux_pos_y,b+1], (x,a))
						# end
					# end
					# count[aux_pos_x,aux_pos_y,a+1] = total #we set the counter in the amount of values that are consistent for the variable x, y with x=a
					# if count[aux_pos_x,aux_pos_y,a+1] == 0 #if the counter is 0 we remove the value a of the domain
						# place = Restrict[aux_pos_x] + 1
						# position = findall(e->e==a, x.domain)[1]
						# splice!(x.domain, place:(place-1), a)
						# splice!(x.domain, position)
						# Restrict[aux_pos_x] -= 1
						# push!(Q, (x,a)) #we add the variable x and the value a (this combination is not consistant with any value of y) to the list Q
					# end
				# end
			# end
		# end
	# end
	# return Q, S, count
# end

#AC4
function initAC4!(model::Model)
	println("initAC4 : ")
	Q = []
	S = Dict()
	for x in model.variables
		for a in x.domain
			S[ (x,a) ] = []
		end
	end
	count_ = Dict()
	
	for cstr in model.constraints
		(x,y) = cstr.var
		for a in x.domain
			total = 0
			for b in y.domain
				if (a,b) in cstr.couples
					total += 1
					push!( S[(y,b)], (x,a) )
				end
			end
			count_[(x,y,a)] = total
			if count_[(x,y,a)] == 0
				x.domain = filter!(x->x!=a, x.domain)
				push!(Q, (x,a))
			end
		end
		#do the opposite (y,x)
	end
	
	return Q, S, count_
end
function AC4!(model::Model)
	println("AC4 : ")
	Q, S, count_ = initAC4!(model)
	while !isempty(Q)
		(y,b) = pop!(Q) #we took a couple from list Q
		#aux_pos_y=findall(e->e==y,model.variables)[1]
		for (x,a) in S[(y,b)]
			#aux_pos_x=findall(e->e==x,model.variables)[1]
			count_[(x,y,a)] -= 1
			if count_[(x,y,a)] == 0 && a in x.domain
				#place = Restrict[aux_pos_x] + 1
				#position = find(e->e==a, x.domain)
				#splice!(x.domain, place:(place-1), a)
				#splice!(x.domain, position)
				x.domain = filter!(x->x!=a, x.domain)
				push!(Q, (x,a))
			end
		end
	end
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

@time AC4!(model)
println(model)





#####################################################################################################################
#bactracking
function Backtrack(model::Model, var_instancie::Array{Variable,1}, frwd = true, arc = "ARC3")
	global nd_numero += 1
	println("Backtrack : node num ", nd_numero, ": ")
	
	if !verification(model) #Si une contrainte est violée
        println("the constraints are not verify")
		return false	
	end
	
	if length(var_instancie) == length(model.variables) #if all the variables are instantiated the problem is solved
		print("Nombre de noeuds parcourus: ")
        println(nd_numero)
        print("Temps de résolution ")
        return true
	end
	
	if !is_consistent(model)
		return false
	else
		
	end
	
	if arc == "ARC3"
		print("ARC3 ")
        AC3!(model)
	elseif arc == "ARC4"
		print("ARC4 ")
		AC4!(model, var_instancie)
	end
	if !is_consistent(model)
		print("Not arc-consistante")
		return false
	else
		println("succes")
	end
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
	x = variables_non_instancie[rand(1:end)] #variable to branch   
	print("branche sur ")
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	
	for val in x.domain
        x.value = val #add the new value to the instance
        if Backtrack(model, var_instancie)
            return true
        end
    end

    return false
end
#################################################################################################################
#end of solver





# var_instancie=Array{Variable,1}(undef,0)
# nd_numero=0

#restr = Int[length(v.domain) for v in model.variables]
	

# @time Backtrack(model, var_instancie, false, "none")

# for x in 1:length(model.variables)
	# print("variable ",x, " ")
	# println(model.variables[x].value)
# end
