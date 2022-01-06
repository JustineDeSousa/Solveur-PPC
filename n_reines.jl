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
end

############Model definition
#Parameters
print("Number of Queens: ")
N = readline(stdin)
n = parse(Int64, N)

#variables
variables=crear_var_reines(n)
#Model
model=Model(variables,[])
#add constraints
create_constraints!(model,n)
# Solve
var_instancie=Array{Variable,1}(undef,0)
nd_numero=0
println("Forward checking ? true or false ?")
ans=readline(stdin)
if ans=="true"
	frwd = true
end

println("Should we use an algorithme of arc consistance? (No, ARC3, ARC4)")
ARC = readline(stdin)
println("Which selection of variables should we use ? (random, average, domain_min, unbound)")
selection = readline(stdin)

@time Backtrack(model, var_instancie, selection, frwd, ARC)
for var in model.variables
	println(var)
end
