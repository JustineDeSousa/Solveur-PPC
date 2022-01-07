# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("coloration.jl")

include("resolution.jl")

#####################################################################################
# Reading file
#####################################################################################
function graphe(filename)
	arcs= Array{Tuple{String,String},1}(undef,0)
	n = 0
	m = 0
	open(filename) do f
		for line in eachline(f)
			ln = replace(line, "\n" => "")
			ln = split(line, " ")
			ln=[x for x in ln if x != ""]
			if ln[1] == "e"
				push!(arcs,( ln[2], ln[3]))
			elseif ln[1] == "p"
				n = parse(Int, ln[3]) #number of nodes
				m = parse(Int, ln[4]) #number of edges
			end
		end
	end
	return n, m, arcs
end

#######################################################################################
#Model
#######################################################################################
function creation_variables(n::Int,domain::Int)
	variables=Array{Variable,1}(undef,0)
	for node in 1:n
		name = string(node)
		a=Variable(name,collect(1:domain))
		push!(variables,a)
	end
	return variables
end
function creation_constraints!(model::Model,arcs::Array{Tuple{String,String},1})
	for var_x in model.variables
		for var_y in model.variables
			if (var_x.name!=var_y.name) && (var_x.name,var_y.name) in arcs
				wrap(model, (var_x,var_y), (a,b) -> a!=b)
			end
		end
	end
end
function creation_coloration()
	println("Insert name of file")
	instance = readline(stdin)
	n, m, arcs = graphe("instances/$instance")
	print("How many colors?")
	domain = parse(Int64, readline(stdin))
	#domain=10
	variables = creation_variables(n,domain)
	model = Model(variables,[])
	creation_constraints!(model,arcs)
	return model
end

###### Def model
model = creation_coloration()

###### Solve
solve(model)