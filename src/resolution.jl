# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("resolution.jl")

include("consistency.jl")
include("in_out.jl")

###################################################################################################################
############Heuristiques to branch
###################################################################################################################

"""
Branchement sur les variables
	-	option : random, average, domain_min, unbound, other(=in the order of the variables)
"""
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
"""
Branchement sur les valeurs
	-	option : min_conflict, max_conflict, other(=in the order of the variables)
"""

function value_selection!(model::Model, var_non_instancie::Array{Variable,1}, option)	
	if option == "min_conflict"
		for x in var_non_instancie
			domains=[]
			cstr=number_constr(model, x)
			#println("cstr",cstr)
			while !isempty(cstr)
				max_=cstr[1]
				for i in cstr
					#println("max",max)
					if i[2]<max_[2]
						max_=i
					end
				end
				cstr=filter!(v->v!=max_, cstr)
				#println("vacio ", isempty(cstr))
				push!(domains,max_[1])	
			end
			x.domain=domains
		end
	
	elseif option=="max_conflict"	
		for x in var_non_instancie
			domains=[]
			cstr=number_constr(model, x)
			#println("cstr",cstr)
			while !isempty(cstr)
				min_=cstr[1]
				for i in cstr
					#println("max",max)
					if i[2]<min_[2]
						min_=i
					end
				end
				cstr=filter!(v->v!=min_, cstr)
				#println("vacio ", isempty(cstr))
				push!(domains,min_[1])	
			end
			x.domain=domains
		end	
	end
	return true
end	

	
#####################################################################################################################	
#####################################################################################################################

"""
bactracking : options : 
	
	-	root : 0(means nothing), AC3, AC4 ?
	- 	nodes : 0(means nothing), frwd, AC3, AC4 ?
	-	var_selection : mode de selection des variables : 
			-	"random", "average", "domain_min", "unbound", 
				any other would do it in the order of variables
	-	value_selection : mode de selection des valeurs :
			- min_conflict, max_conflict, other(=in the order of the variables)
"""
function Backtrack(model::Model, var_instancie::Array{Variable,1}, root="AC4", nodes="frwd", var_selection="domain_min", value_selection="min_conflict")
	
	if isempty(var_instancie) #Si on n'a pas encore commencé le backtrack
		global nd_numero = 0
		#println(" #################### Backtrack ####################")
		#println("	##### root = ", root, " #####")
		if root == "AC3"
			AC3!(model)
		elseif root == "AC4"
			AC4!(model)
		end
	end
	
	nd_numero += 1
	# if rem(nd_numero,1000) == 0
		# println(" ##### node ", nd_numero, ": ")
	# end
	
	if !verification(model, var_instancie) #Si une contrainte est violée parmi les variables déjà instanciées
        #println("the constraints are not verified")
		return false
	end
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
	
	if isempty(variables_non_instancie) #if all the variables are instantiated the problem is solved
		model.solved = true
        return true
	end
	
	if !is_consistent(model)
		#println("Not arc-consistent")
		return false
	else
		#println("Model is consistent")
	end
	
	
	x = variable_selection(model,variables_non_instancie, var_selection) #variable to branch
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	#print("Branche sur ")
	nb_values = 0
	value_selection!(model, variables_non_instancie, value_selection) #order the values of x.domain according to value_selection
	for v in x.domain
		nb_values += 1
		x.value = v #add the new value to the instance
		#println(x)
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
		if Backtrack(model, var_instancie, root, nodes, var_selection, value_selection )
			return true
		elseif nodes == "fwrd" || nodes == "AC3" || nodes == "AC4"
			back_domains(model, domains)
		end
	end
	x.value = -1
	var_instancie = filter!(y->y!=x, var_instancie)
	#println(x)
	
    return false
end

"""
Solve one instance
"""
function solve!(model::Model, root="AC4", nodes="fwrd", var_selection="domain_min", value_selection="min_conflict")
	var_instancie = Array{Variable,1}(undef,0)
	
	starting_time = time()
	
	b=Backtrack(model, var_instancie, root, nodes, var_selection, value_selection)
	
	println("\nNb de noeuds parcourus : ", nd_numero, "\n")
	
	model.resolution_time = time() - starting_time
	write_solution(stdout,model)
	return b
end
"""
Solve all the instances contained in "instances" through several options

The results are written in "res/options"

Remark: If an instance has previously been solved it will not be solved again
"""
function solve_instances(type_="queens")

    dataFolder = "instances/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    rootMethod = ["None", "AC3", "AC4"]
	nodesMethod = ["None", "Fwrd", "AC3", "AC4"]
	varSelectionMethod = ["None", "domainMin"]
	valueSelectionMathod = ["None", "MinConflicts", "MaxConflicts"]
	
	
    # Array which contains the result folder of each resolution method
    # resolutionFolder = []
	# for r in rootMethod
		# push!(resolutionFolder, resFolder*r)
	# end
	# for s in selectionMethod
		# for r in rootMethod
			# for n in nodesMethod
				# push!( resolutionFolder, resFolder * s * r * n)
			# end
		# end
	# end

    # Create each result folder if it does not exist
    # for folder in resolutionFolder
        # if !isdir(folder)
			# println(folder)
            # mkdir(folder)
        # end
    # end
            
    global isOptimal = false
    global resolutionTime = -1

    # For each instance
	if type_ == "queens"
		for n in 5:15
			println("-- Resolution of ", n, " queens")
			model = creation_queens(n)
			for root in rootMethod
				folder = resFolder * "queens/root" * root
				if !isdir(folder)
					println(pwd())
					println(folder)
					mkdir(folder)
				end
				outputFile = folder * "/queens" * string(n) * ".res"
				if !isfile(outputFile)
					fout = open(outputFile, "w")
					resolutionTime = -1
					isOptimal = false 
					startingTime = time()
					# While the grid is not solved and less than 100 seconds are elapsed
					while !isOptimal && resolutionTime < 100
						solve!(model, root, "None", "None", "None")
						isOptimal  = model.solved
						resolutionTime = time() - startingTime
					end
					# Write the solution
					write_solution(fout,model)
					close(fout)
				end
				println("root", root, " optimal: ", isOptimal)
				println("root", root, " time: " * string(round(resolutionTime, sigdigits=2)) * "s\n")
			end
		end
	elseif type_ == "coloration"
		# (for each file in folder data_folder which ends by ".col")
		for file in filter(x->occursin(".col", x), readdir(dataFolder))
			println("-- Resolution of ", file)
			model = creation_coloration(file)
			
			# For each resolution method
			for rootId in rootMethod
				outputFile = resFolder * "/root" * rootId * "/" * file
				println("root " * rootId)
				# If the instance has not already been solved by this method
				if !isfile(outputFile)
					fout = open(outputFile, "w")  
					
					resolutionTime = -1
					isOptimal = false

					# Start a chronometer 
					startingTime = time()
					
					# While the grid is not solved and less than 100 seconds are elapsed
					while !isOptimal && resolutionTime < 100
						solve!(model, rootId, "None", "None", "None")
						isOptimal  = model.solved
						
						# Stop the chronometer
						resolutionTime = time() - startingTime
					end
					# Write the solution
					write_solution(fout,model)
					close(fout)
				end


				# Display the results obtained with the method on the current instance
				#include("../"*outputFile)

				# println(resolutionFolder[methodId], " optimal: ", isOptimal)
				# println(resolutionFolder[methodId], " time: " * string(round(resolutionTime, sigdigits=2)) * "s\n")
			end
		end 
	end

end

#################################################################################################################
#end of solver
