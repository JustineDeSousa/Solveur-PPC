include("model.jl")

# function to check if the variables in the instance comply with the constraints
function verification(model::Model, var_instancie::Array{Variable,1})
	for x in var_instancie
		for y in var_instancie
			if x != y
				for cstr in constraints(model, x, y)
					if !((x.value,y.value) in cstr.couples)
						#println("(", x.name, ", ", y.name, ") = (", x.value, ", ", y.value, ") isnt in the constraint")
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
	#println(" ================== Forward checking ==================")
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
	#println(" ======================================================")
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
	term = false
	while !term
		term = true
		for cstr in model.constraints
			(x,y) = cstr.var
			for a in x.domain
				if !is_supported(cstr, x, a)
					x.domain = filter!(v->v!=a, x.domain)
					term = false
				end
			end
		end
	end
end

#AC3
function AC3!(model::Model)
	aTester = Array{Constraint}(undef,0)
	for cstr in model.constraints
		push!(aTester, cstr)
	end

	while !isempty(aTester)
		cstr = pop!(aTester) #remove the last constraint of the list to test and save it in a tuple to work with
		(x,y) = cstr.var
		for a in x.domain
			if !is_supported(cstr, y, a)
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
				x.domain = filter!(v->v!=a, x.domain)
				println("(", x.name, ", ", a, ") isnt supported by ", y.name)
				push!(Q, (x,a))
			end
		end
	end
	return Q, S, count_
end

function AC4!(model::Model)
	Q, S, count_ = initAC4!(model)
	while !isempty(Q)
		(y,b) = pop!(Q) #we took a couple from list Q
		for (x,a) in S[(y,b)]
			count_[(x,y,a)] -= 1
			if count_[(x,y,a)] == 0 && a in x.domain
				x.domain = filter!(v->v!=a, x.domain)
				push!(Q, (x,a))
			end
		end
	end
end
