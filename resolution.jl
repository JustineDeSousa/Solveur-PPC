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
function verification(model::Model, var_instancie::Array{Variable,1})
		verif = true
        for x in var_instancie
            for y in var_instancie
				if x.name != y.name
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
#verification(model)
###################################################################################################################

#Algorithme of forward checking
function forward_checking!(model::Model, var_instancie::Array{Variable,1}, x::Variable)
	# x is the variable that just has been instanciated
	for y in setdiff(model.variables, var_instancie)
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
#@time AC1!(model)
#println(model)

#AC3
function AC3!(model::Model)
	println("AC3 : ")
	aTester = Array{Constraint}(undef,0)
	for cstr in model.constraints
		push!(aTester, cstr)
	end
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
	end
end

#Définition du modèle Voiture du cours
#domain = [0,1,2] #bleu, rouge, jaune

#caisse = Variable("caisse", domain)
#enjoliveurs = Variable("enjoliveurs", domain)
#pare_choc = Variable("pare_choc", domain)
#capote = Variable("capote", domain)
#println(capote)

#cstr = Constraint((caisse,enjoliveurs),  [(1,1), (2,2)])
#println(cstr)

#model = Model( [caisse, enjoliveurs, pare_choc, capote], [])
#add_constraint(model, (caisse,enjoliveurs),  [(1,1), (2,2)])
#add_constraint(model, (caisse,pare_choc),  [(0,0), (1,1), (2,2)])
#add_constraint(model, (capote,pare_choc),  [(0,0), (1,1), (2,2)])
#add_constraint(model, (caisse,capote),  [(0,0), (1,2), (2,1)])
#println(model)

#@time AC3!(model)
#println(model)


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
		#now the same for (y,x)
		for b in y.domain
			total = 0
			for a in x.domain
				if (a,b) in cstr.couples
					total += 1
					push!( S[(x,a)], (y,b) )
				end
			end
			count_[(y,x,b)] = total
			if count_[(y,x,b)] == 0
				y.domain = filter!(x->x!=a, y.domain)
				push!(Q, (y,b))
			end
		end
	end
	
	return Q, S, count_
end
function AC4!(model::Model)
	println("AC4 : ")
	Q, S, count_ = initAC4!(model)
	while !isempty(Q)
		(y,b) = pop!(Q) #we took a couple from list Q
		for (x,a) in S[(y,b)]
			#aux_pos_x=findall(e->e==x,model.variables)[1]
			count_[(x,y,a)] -= 1
			if count_[(x,y,a)] == 0 && a in x.domain
				x.domain = filter!(x->x!=a, x.domain)
				push!(Q, (x,a))
			end
		end
	end
end


#Définition du modèle Voiture du cours
#domain = [0,1,2] #bleu, rouge, jaune

#caisse = Variable("caisse", domain)
#enjoliveurs = Variable("enjoliveurs", domain)
#pare_choc = Variable("pare_choc", domain)
#capote = Variable("capote", domain)
#println(capote)

#cstr = Constraint((caisse,enjoliveurs),  [(1,1), (2,2)])
#println(cstr)

#model = Model( [caisse, enjoliveurs, pare_choc, capote], [])
#add_constraint(model, (caisse,enjoliveurs),  [(1,1), (2,2)])
#add_constraint(model, (caisse,pare_choc),  [(0,0), (1,1), (2,2)])
#add_constraint(model, (capote,pare_choc),  [(0,0), (1,1), (2,2)])
#add_constraint(model, (caisse,capote),  [(0,0), (1,2), (2,1)])
#println(model)

#@time AC4!(model)
#println(model)

###################################################################################################################
############Heuristiques to branch
###################################################################################################################
function variable_selection(model::Model,var_non_instancie::Array{Variable,1}, option)
        if option == "random"
            r = var_non_instancie[rand(1:end)]
            return r
        elseif option == "average"
            moyen = div(1 + length(var_non_instancie), 2)
            return var_non_instancie[moyen]
        elseif option == "domain_min"
            min_var = var_non_instancie[1]
            for var in var_non_instancie
                if length(var.domain) < length(min_var.domain)
                    min_var = var
                end
            end
            return min_var
		elseif option== "unbound"
			cstr=[]
			for var in var_non_instancie
				if(length(constraints(model, var))==0)
					println(var)
					return var
				end
			end
			return var_non_instancie[1]
        else # without option
            return var_non_instancie[1]
        end
    end

<<<<<<< Updated upstream

#####################################################################################################################
#bactracking
function Backtrack(model::Model, var_instancie::Array{Variable,1}, frwd = true, arc = "ARC3")
	global nd_numero += 1
	println("Backtrack : node num ", nd_numero, ": ")
=======
#bactracking : options : 
#	-	selection : mode de selection des variables : 
#			-	"random", "average", "domain_min", "unbound", 
#				any other would do it in the order of variables
#	-	root : 0(means nothing), AC3, AC4 ?
#	- 	nodes : 0(means nothing), frwd, AC3, AC4 ?
function Backtrack(model::Model, var_instancie::Array{Variable,1}, selection="random", root = "AC3", nodes = "frwd")
	
	if isempty(var_instancie) #Si on n'a pas encore commencé le backtrack
		global nd_numero = 0
		println(" #################### Backtrack ####################")
		if root == "AC3"
			AC3!(model)
		elseif root == "AC4"
			AC4!(model)
		end		
	end
	
	nd_numero += 1
	println("\n ##### node ", nd_numero, ": ")
>>>>>>> Stashed changes
	
	if !verification(model,var_instancie) #Si une contrainte est violée
        println("the constraints are not verify")
		return false	
	end
	
	if length(var_instancie) == length(model.variables) #if all the variables are instantiated the problem is solved
		println("succes")
		print("Nombre de noeuds parcourus: ")
        println(nd_numero)
        print("Temps de résolution ")
        return true
	end
	
<<<<<<< Updated upstream
	if !is_consistent(model)
		return false
	else
		
	end
	
	if arc == "ARC3"
		#print("ARC3 ")
        AC3!(model)
	elseif arc == "ARC4"
		#print("ARC4 ")
		AC4!(model, var_instancie)
	end
	if !is_consistent(model)
		print("Not arc-consistante")
		return false
	else
		println("succes")
	end
=======
#	if arc == "AC1"
#		print("AC1 ")
#		AC1!(model)
#	elseif arc == "AC3"
#		print("ARC3 ")
#        AC3!(model)
#	elseif arc == "AC4"
#		print("AC4 ")
#		println(model.variables)
#		AC4!(model)
#		println(model.variables)
#	end
#	if !is_consistent(model)
#		println("Not arc-consistent")
#		return false
#	else
#		println("Model is consistent")
#	end
>>>>>>> Stashed changes
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
	x = variable_selection(model,variables_non_instancie, "random") #variable to branch   
	#print("branche sur ")
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





#var_instancie=Array{Variable,1}(undef,0)
#nd_numero=0

	

#@time Backtrack(model, var_instancie)
#println(model)

