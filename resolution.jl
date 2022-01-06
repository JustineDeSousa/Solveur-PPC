# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("resolution.jl")

include("model.jl")

###################################################################################################################
#Beginning of the solver
###################################################################################################################

# function to check if the variables in the instance comply with the constraints
function verification(model::Model, var_instancie::Array{Variable,1})
	for x in var_instancie
		for y in var_instancie
			if x.name != y.name
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
	# x is the variable that just has been instanciated
	for y in setdiff(model.variables, var_instancie)
		if exists_constraint(model, (x,y)) #Si il existe une cte entre x et y
			for b in y.domain
				if !((x.value,b) in cstr.couples) #if (x.value,b) is not in the constraint we remove b from the y domain
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

# Is the value a of x supported by the other variable y of the constraint ?
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
			count_[(x,y,a)] -= 1
			if count_[(x,y,a)] == 0 && a in x.domain
				x.domain = filter!(x->x!=a, x.domain)
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

#bactracking
function Backtrack(model::Model, var_instancie::Array{Variable,1}, selection="random", frwd = true, arc = "ARC3")
	
	if isempty(var_instancie) #Si on n'a pas encore commencé le backtrack
		global nd_numero = 0
		println(" #################### Backtrack ####################")
	end
	
	nd_numero += 1
	println("\n ##### node ", nd_numero, ": ")
	
	if !verification(model, var_instancie) #Si une contrainte est violée parmi les variables déjà instanciées
        println("the constraints are not verified")
		return false	
	end
	
	variables_non_instancie = setdiff(model.variables, var_instancie) #make a set with the variables that are not instantiated
	
	if isempty(variables_non_instancie) #if all the variables are instantiated the problem is solved
		println("Nombre de noeuds parcourus: ", nd_numero)
        print("Temps de résolution ")
        return true
	end
	
	# if arc == "ARC3"
		# print("ARC3 ")
        # AC3!(model)
	# elseif arc == "ARC4"
		# print("ARC4 ")
		# AC4!(model, var_instancie)
	# end
	# if !is_consistent(model)
		# println("Not arc-consistante")
		# return false
	# else
		# println("Model is consistent")
	# end
	
	
	x = variable_selection(model,variables_non_instancie, selection) #variable to branch
	push!(var_instancie, x) #add the new variable to branch to the variables instantiated
	print("Branche sur ")
	nb_values = 0
	for v in x.domain
		nb_values += 1
		x.value = v #add the new value to the instance
		println(x)
		if Backtrack(model, var_instancie, frwd, arc)
			return true
		elseif nb_values == length(x.domain)
			nb_values == length(x.domain)
			x.value = -1
			var_instancie = filter!(y->y.name!=x.name, var_instancie)
			println(x)
		end
	end
	# if nb_values == length(x.domain)
		# x.value = -1
		# println(x)
	# end
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
