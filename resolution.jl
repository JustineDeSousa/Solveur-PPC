# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("resolution.jl")

include("model.jl")
include("in_out.jl")

###################################################################################################################
#Beginning of the solver
###################################################################################################################

# function to check if the variables in the instance comply with the constraints
function verification(model::Model, var_instancie::Array{Variable,1})
	for x in var_instancie
		for y in var_instancie
			if x != y
				for cstr in constraints(model, x, y)
					if !((x.value,y.value) in cstr.couples)
						println("(", x.name, ", ", y.name, ") = (", x.value, ", ", y.value, ") isnt in the constraint")
						return false
					end                                                                
				end
			end
		end
	end
    return true
end
###################################################################################################################

#Algorithme of forward checking
function forward_checking!(model::Model, var_instancie::Array{Variable,1}, x::Variable)
	println(" ================== Forward checking ==================")
	for cstr in constraints(model, x)
		y = other(cstr, x)
		if !(y in var_instancie)
			for b in y.domain
				#if (x.value,b) is not in the constraint we remove b from the y domain
				if ( x==cstr.var[1] && !((x.value,b) in cstr.couples) ) || 
				   ( x==cstr.var[2] && !((b,x.value) in cstr.couples) )
					y.domain = filter!(v->v!=b, y.domain)
				end
			end
			#println("\t", y.name, " = ", y)
		end
	end
	println(" ======================================================")
end
function keeps_domains(model::Model)
	domains = []
	#Save the domains for them to be restituted in case we change branch
	for x in model.variables
		deep_domain = deepcopy(x.domain)
		push!(domains, deep_domain)
	end
	return domains
end
function back_domains(model::Model, domains::Array{Any,1})
	# Assign back the domains to what they were before forward_checking
	for i in 1:1:length(model.variables)
		model.variables[i].domain = domains[i]
	end
end
# function forward_checking!(model::Model, var_instancie::Array{Variable,1}, next_choose::Variable,RestrictDom::Array{Int,1})
	# for y in setdiff(model.variables, var_instancie)
		# taille = length(y.domain)
		# Dom2 = deepcopy(y.domain)
		# ix = deepcopy(taille) + 1
		# pos_actuel = 1
		# for b in y.domain[1:taille]
			# for cstr in model.constraints
				# if Set([next_choose,y])== cstr.var
					# if !((next_choose.value,b) in cstr.couples) #if the combination of the value choosen and some value of some variable non instantiated is not in the constraints, we move that value to the end of the domain
						# splice!(Dom2, ix:(ix-1), b)
						# splice!(Dom2, pos_actuel)
						# ix -= 1
					# else
						# pos_actuel += 1
					# end
				# end
			# end
		# end
		# y.domain = Dom2 #update the domain
		# RestrictDom[findall(x->x==y,model.variables)[1]] = ix - 1 #update the lenght of the domain, to not consider the values that are not in the constraints
	# end
# end

################################################################################################################
###########Algorithmes ARC
################################################################################################################

#function to test if a couple of values are in the constraints or not
function is_admissible(model::Model, (x,y)::Tuple{Variable,Variable}, couple::Tuple{Int,Int})
	for cstr in model.constraints
		if (x,y) == cstr.var
			if (couple in cstr.couples)
				return true
			end
		end
	end
	return false
end

# Is the value a of x supported by the other variable y of the constraint ?
function is_supported(cstr::Constraint, x::Variable, a::Int64)
	supported = false
	for b in x.domain
		if (cstr.var[1] == x && (a,b) in cstr.couples) ||
		   (cstr.var[2] == x && (b,a) in cstr.couples )
			supported = true
			break
		end
	end
	return supported
end


# AC1
function AC1!(model::Model)
	println("AC1 : ")
	term = false
	while !term
		term = true
		for cstr in model.constraints
			(x,y) = cstr.var
			for a in x.domain
				if !is_supported(cstr, x, a)
					println("(",x.name,", ", a, ") is not supported by ", y.name)
					x.domain = filter!(v->v!=a, x.domain)
				end
			end
		end
	end
end

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
				println("(",x.name,", ", a, ") is not supported by ", y.name)
				x.domain = filter!(x->x!=a, x.domain)
				for cstr in constraints(model, x)
					z = other(cstr, x)
					if z != y
						push!(aTester, cstr)
					end
				end
			end
		end
	end
end




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
				println("(",x.name,", ", a, ") is not supported by ", y.name)
				x.domain = filter!(v->v!=a, x.domain)
				push!(Q, (x,a))
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
			count_[(x,y,a)] -= 1
			if count_[(x,y,a)] == 0 && a in x.domain
				println("(",x.name,", ", a, ") is not supported by ", y.name)
				x.domain = filter!(v->v!=a, x.domain)
				push!(Q, (x,a))
			end
		end
	end
end

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
	
	
#####################################################################################################################

#bactracking : options : 
#	-	selection : mode de selection des variables : 
#			-	"random", "average", "domain_min", "unbound", 
#				any other would do it in the order of variables
#	-	root : 0(means nothing), AC3, AC4 ?
#	- 	nodes : 0(means nothing), frwd, AC3, AC4 ?
function Backtrack(model::Model, var_instancie::Array{Variable,1}, selection="random", root="AC3", nodes="frwd")
	
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
	
	if !verification(model, var_instancie) #Si une contrainte est violée parmi les variables déjà instanciées
        #println("the constraints are not verified")
		return false
	end
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
	
	if isempty(variables_non_instancie) #if all the variables are instantiated the problem is solved
		model.solved = true
		println("Nombre de noeuds parcourus: ", nd_numero)
        return true
	end
	
	if !is_consistent(model)
		println("Not arc-consistent")
		return false
	else
		println("Model is consistent")
	end
	
	
	x = variable_selection(model,variables_non_instancie, selection) #variable to branch
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	print("Branche sur ")
	nb_values = 0
	for v in x.domain
		nb_values += 1
		x.value = v #add the new value to the instance
		println(x)
		if nodes == "fwrd" || nodes == "AC3" || nodes == "AC4"
			#We need to keep the domains for the ohter branches
			domains = keeps_domains(model)
			if nodes == "fwrd"
			forward_checking!(model, var_instancie, x)
			elseif nodes == "AC3"
				AC3!(model)
			elseif nodes == "AC4"
				AC4!(model)
			end
		end
		if Backtrack(model, var_instancie, selection, root, nodes )
			return true
		elseif nodes == "fwrd" || nodes == "AC3" || nodes == "AC4"
			back_domains(model, domains)
		end
	end
	x.value = -1
	var_instancie = filter!(y->y!=x, var_instancie)
	println(x)
	
    return false
end

function solve!(model::Model, selection="0", root="AC4", nodes="fwrd")
	var_instancie = Array{Variable,1}(undef,0)
	
	starting_time = time()
	
	b=Backtrack(model, var_instancie, selection, root, nodes)
	
	println("Nb de noeuds parcourus : ", nd_numero)
	
	model.resolution_time = time() - starting_time
	write_solution(stdout,model)
	return b
end
"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solve_coloration_instances()

    dataFolder = "instances/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    selectionMethod = ["none", "domain_min"]
	rootMethod = ["none", "AC3", "AC4"]
	nodesMethod = ["none", "fwrd", "AC3", "AC4"]
	
    # Array which contains the result folder of each resolution method
    resolutionFolder = []
	for s in selectionMethod
		for r in rootMethod
			for n in rootMethod
				push!( resolutionFolder, resFolder * s * "_" * r * "_" * n)
			end
		end
	end

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
			println(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global resolutionTime = -1

    # For each instance
    # (for each file in folder data_folder which ends by ".col")
    for file in filter(x->occursin(".col", x), readdir(dataFolder))
        println("-- Resolution of ", file)
        model = creation_coloration(file)
        
        # For each resolution method
        for methodId in 1:size(resolutionFolder, 1)
            outputFile = resolutionFolder[methodId] * "/" * file
            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                fout = open(outputFile, "w")  
				
                resolutionTime = -1
                isOptimal = false

				# Start a chronometer 
				startingTime = time()
				
				# While the grid is not solved and less than 100 seconds are elapsed
				while !isOptimal && resolutionTime < 100
					solve!(model)
					isOptimal  = model.solved
					
					# Stop the chronometer
					resolutionTime = time() - startingTime
				end
				# Write the solution
				write_solution(fout,model)
                close(fout)
            end


            # Display the results obtained with the method on the current instance

            include("../"*outputFile)

            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(resolutionTime, sigdigits=2)) * "s\n")
        end         
    end 
end

#################################################################################################################
#end of solver
