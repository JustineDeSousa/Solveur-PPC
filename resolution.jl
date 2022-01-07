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
				max=cstr[1]
				for i in cstr
					#println("max",max)
					if i[2]<max[2]
						max=i
					end
				end
				cstr=filter!(v->v!=max, cstr)
				#println("vacio ", isempty(cstr))
				push!(domains,max[1])	
			end
			x.domain=domains
		end
	
	elseif option=="max_conflict"	
		for x in var_non_instancie
			domains=[]
			cstr=number_constr(model, x)
			#println("cstr",cstr)
			while !isempty(cstr)
				min=cstr[1]
				for i in cstr
					#println("max",max)
					if i[2]<min[2]
						min=i
					end
				end
				cstr=filter!(v->v!=min, cstr)
				#println("vacio ", isempty(cstr))
				push!(domains,min[1])	
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
	-	selection : mode de selection des variables : 
			-	"random", "average", "domain_min", "unbound", 
				any other would do it in the order of variables
	-	root : 0(means nothing), AC3, AC4 ?
	- 	nodes : 0(means nothing), frwd, AC3, AC4 ?
"""
function Backtrack(model::Model, var_instancie::Array{Variable,1}, selection="random", root="AC3", nodes="frwd",value_selection="min_conflict")
	
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
	if rem(nd_numero,10) == 0
		println(" ##### node ", nd_numero, ": ")
	end
	
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
		#println("Not arc-consistent")
		return false
	else
		#println("Model is consistent")
	end
	
	
	x = variable_selection(model,variables_non_instancie, selection) #variable to branch
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	#print("Branche sur ")
	nb_values = 0
	value_selection!(model, variables_non_instancie, value_selection)
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
		if Backtrack(model, var_instancie, selection, root, nodes )
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
function solve!(model::Model, selection="0", root="AC4", nodes="fwrd", value_selection="min_conflict")
	var_instancie = Array{Variable,1}(undef,0)
	
	starting_time = time()
	
	b=Backtrack(model, var_instancie, selection, root, nodes, value_selection)
	
	println("Nb de noeuds parcourus : ", nd_numero)
	
	model.resolution_time = time() - starting_time
	write_solution(stdout,model)
	return b
end
"""
Solve all the instances contained in "instances" through several options

The results are written in "res/options"

Remark: If an instance has previously been solved it will not be solved again
"""
function solve_coloration_instances()

    dataFolder = "instances/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
    selectionMethod = ["none", "domain_min"]
	rootMethod = ["none", "AC3", "AC4"]
	nodesMethod = ["none", "fwrd", "AC3", "AC4"]
	varSelectionMethod = ["none", "min_conflict", "max_conflict"]
	
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
			println(pwd())
			println("outputFile = ", outputFile)
            #include("../"*outputFile)

            println(resolutionFolder[methodId], " optimal: ", isOptimal)
            println(resolutionFolder[methodId], " time: " * string(round(resolutionTime, sigdigits=2)) * "s\n")
        end         
    end 
end

#################################################################################################################
#end of solver
