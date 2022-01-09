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
############ Solve one instance
# n=20
# model = creation_queens(n)
# time_ = 100
# root = "AC4"
# nodes = "Frwd"
# varSelection = "domainMin"
# valueSelection = "None"
# solve!(model, time_, root, nodes, varSelection, valueSelection)


############ Solve all instances
time_ = 1000
type_ = "queens"
#methods_=["root","nodes","varSelection","valueSelection"]
# for met in methods_
#met = "Best"
	#solve_instances(time_,type_, met)
	#resultsArray(type_, met)
	#performanceDiagram(type_,met)
# end
##########Solve one instance
print("How many queens?")
n = parse( Int64, readline(stdin) )
print("root ? (AC3, AC4, 0(=nothing) )")
root = readline(stdin)
print("nodes ? (fwrd, AC3, AC4, 0(=nothing) )")
nodes = readline(stdin)
print("Heuristic of selection of variables ? (0(=in order), random, average, domain_min, unbound)")
varSelection = readline(stdin) 
print("Heuristic of selection of value ? (0(=in order), MinConflicts, MaxConflicts)")
valueSelection = readline(stdin) 
model = creation_queens(n)
solve!(model, time_, root, nodes, varSelection, valueSelection)



println("Reussie")
