# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("resolution.jl")

include("consistency.jl")
include("in_out.jl")

###################################################################################################################
############Heuristiques to branch
###################################################################################################################

"""
Branchement sur les variables
	-	option : random, average, domainMin, unbound, other(=in the order of the variables)
"""
function variable_selection(model::Model,var_non_instancie::Array{Variable,1}, option)
	if option == "random"
		r = var_non_instancie[rand(1:end)]
		return r
	elseif option == "average"
		moyen = div(1 + length(var_non_instancie), 2)
		return var_non_instancie[moyen]
	elseif option == "domainMin"
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
	-	option : minConflict, maxConflict, other(=in the order of the variables)
"""

function valueSelection!(model::Model, var_non_instancie::Array{Variable,1}, option)	
	if option == "minConflict"
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
	
	elseif option=="maxConflict"	
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
	- 	nodes : 0(means nothing), Frwd, AC3, AC4 ?
	-	varSelection : mode de selection des variables : 
			-	"random", "average", "domainMin", "unbound", 
				any other would do it in the order of variables
	-	valueSelection : mode de selection des valeurs :
			- minConflict, maxConflict, other(=in the order of the variables)
"""

function Backtrack(model::Model, time_, var_instancie::Array{Variable,1}, root="AC4", nodes="Frwd", varSelection="domainMin", valueSelection="maxConflict")
	
	if isempty(var_instancie) #Si on n'a pas encore commencé le backtrack
		global nd_numero = 0
		start_root = time()
		if root == "AC3"
			AC3!(model)
		elseif root == "AC4"
			AC4!(model)
		end
		model.root_time = time() - start_root
		global start = time()
	end
	
	nd_numero += 1

	while time()-start < time_
		if !verification(model, var_instancie) #Si une contrainte est violée parmi les variables déjà instanciées
			return false
		end
		if !is_consistent(model)
			return false
		end
		variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
		if isempty(variables_non_instancie) #if all the variables are instantiated the problem is solved
			model.solved = true
			return true
		end
			
		x = variable_selection(model,variables_non_instancie, varSelection) #variable to branch
		push!(var_instancie, x) #add the new variable to branch to the variables instantiated
		
		valueSelection!(model, variables_non_instancie, valueSelection) #order the values of x.domain according to valueSelection
		nb_values = 0
		for v in x.domain
			nb_values += 1
			x.value = v #add the new value to the instance
			if nodes == "Fwrd" || nodes == "AC3" || nodes == "AC4"
				#We need to keep the domains for the ohter branches
				domains = keeps_domains(model)
				if nodes == "Fwrd"
					forward_checking!(model, var_instancie, x)
				elseif nodes == "AC3"
					AC3!(model)
				elseif nodes == "AC4"
					AC4!(model)
				end
			end
			if Backtrack(model, time_, var_instancie, root, nodes, varSelection, valueSelection )
				return true
			elseif nodes == "Fwrd" || nodes == "AC3" || nodes == "AC4"
				back_domains(model, domains)
			end
		end
		x.value = -1
		var_instancie = filter!(y->y!=x, var_instancie)
		
		return false
	end
	return false
end

"""
Solve one instance
"""
function solve!(model::Model, time_=100, root="AC4", nodes="Fwrd", varSelection="domainMin", valueSelection="minConflict")
	println(" solve!(", time_, ",", root, ",", nodes, ",", varSelection, ",", valueSelection, ")")
	var_instancie = Array{Variable,1}(undef,0)
	
	starting_time = time()
	b=Backtrack(model, time_, var_instancie, root, nodes, varSelection, valueSelection)
	
	model.resolution_time = time() - starting_time
	model.nb_nodes = nd_numero

	println("\nNb de noeuds parcourus : ", model.nb_nodes, "\n")
	write_solution(stdout,model)
	return b
end
"""
Solve all the instances contained in "instances" through several options

The results are written in "res/options"

Remark: If an instance has previously been solved it will not be solved again
"""
function solve_instances(time_=100, type_="queens", method="Best")
	println("solve_instances(", time_, ",", type_, ",", method, ")")
    dataFolder = "instances/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods
	if method == "root"
		methodOptions = ["None", "AC3", "AC4"]
		nodes = "None"
		varSelection = "None"
		valueSelection = "None"
	elseif method == "nodes"
		methodOptions = ["None", "Fwrd", "AC3", "AC4"]
		root = "AC4"
		varSelection = "None"
		valueSelection = "None"
	elseif method == "varSelection"
		methodOptions = ["None", "domainMin"]
		root = "AC4"
		nodes = "Fwrd"
		valueSelection = "None"
	elseif method == "valueSelection"
		methodOptions = ["None", "MinConflicts", "MaxConflicts"]
		root = "AC4"
		nodes = "Fwrd"
		varSelection = "None"
	else
		methodOptions = ["Best"]
		root = "AC4"
		nodes = "AC4"
		varSelection = "domainMin"
		valueSelection = "MaxConflicts"
	end
                
    # For each instance
	if type_ == "queens"
		for n in 16:30
			println("\n-- Resolution of the ", n, " queens problem")
			model = creation_queens(n)
			for m in methodOptions
				print("---- " * method * " = " * m * " : ")
				folder = resFolder * "queens/" * method * "/" * m
				if method=="root"
					root = m
				elseif method=="nodes"
					nodes = m
				elseif method=="varSelection"
					varSelection = m
				elseif method=="valueSelection"
					valueSelection = m
				elseif method=="Best"
					folder = resFolder * "queens/" * method
				end
				
				if !isdir(folder)
					mkdir(folder)
				end
				outputFile = folder * "/queens" * string(n) * ".res"
				if !isfile(outputFile)
					fout = open(outputFile, "w")
					solve!(model,time_, root, nodes, varSelection, valueSelection) 
					write_solution(fout,model)
					close(fout)
				end
			end
		end
	elseif type_ == "coloration"
		# (for each file in folder data_folder which ends by ".col")
		for file in filter(x->occursin(".col", x), readdir(dataFolder))
			println("-- Resolution of ", file)
			model = creation_coloration(file)
			
			# For each resolution method
			for m in methodOptions
				print("---- " * method * " = " * m * " : ")
				if method=="root"
					root = m
				elseif method=="nodes"
					nodes = m
				elseif method=="varSelection"
					varSelection = m
				elseif method=="valueSelection"
					valueSelection = m
				end
				folder = resFolder * "coloration/" * method * "/" * m 
				if !isdir(folder)
					println(pwd())
					println(folder)
					mkdir(folder)
				end
				outputFile = folder * "/" * SubString(file,1,length(file)-4) * ".res"
				#println("root " * rootId)
				# If the instance has not already been solved by this method
				if !isfile(outputFile)
					fout = open(outputFile, "w")  
					solve!(model, time_, root, nodes, varSelection, valueSelection)
					write_solution(fout,model)
					close(fout)
				end
			end
		end 
	end

end

#################################################################################################################
#end of solver
