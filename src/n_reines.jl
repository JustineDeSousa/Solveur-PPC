# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("src\\n_reines.jl")

include("resolution.jl")

##########################################################################################
##Model
##########################################################################################
function crear_var_reines(n::Int64)
	variables=Array{Variable,1}(undef,0)
	for reine in 1:1:n
		name="Reine "*string(reine)
		a=Variable(name,collect(1:n))
		push!(variables,a)
	end
	return variables
end
function create_constraints!(model::Model,n::Int64)
	for y in model.variables
		for x in model.variables
			if x!=y
				wrapper(model, (x,y), (a,b) -> a!=b)
			end
		end
	end
	for j in 1:n
		for i in 1:j-1
			x = model.variables[j]
			y = model.variables[i]
			wrapper(model, (x,y), (a,b) -> abs(a-b)!=(j-i))
		end
	end	
	return model
end
function creation_queens(n::Int64)
	model = Model(crear_var_reines(n),[])
	create_constraints!(model,n)
	return model
end

############ Solve
type_ = "queens"
method = "nodes"
#solve_instances(type_, method)
resultsArray(type_, method)
#performanceDiagram(type_, method)
