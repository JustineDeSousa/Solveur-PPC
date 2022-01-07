# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("n_reines.jl")

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
			if x.name!=y.name
				wrap(model, (x,y), (a,b) -> a!=b)
			end
		end
	end
	for j in 1:n
		for i in 1:j-1
			a=model.variables[j]
			b=model.variables[i]
			wrap(model, (a,b), (a,b) -> abs(a-b)!=(j-i))
		end
	end	
	return model
end
function creation_queens()
	print("Number of Queens: ")
	n = parse( Int64, readline(stdin) )
	model = Model(crear_var_reines(n),[])
	create_constraints!(model,n)
	return model
end
############ Model definition
model = creation_queens()

############ Solve
solve(model)

