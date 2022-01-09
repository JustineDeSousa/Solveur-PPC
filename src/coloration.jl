# cd("D:\\M2\\PPC\\projet\\Solveur-PPC")
# include("src\\coloration.jl")

include("resolution.jl")

#####################################################################################
# Reading file
#####################################################################################
function graphe(filename)
	arcs= Array{Tuple{String,String},1}(undef,0)
	n = 0
	m = 0
	nb_col = 0
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
				nb_col = parse(Int, ln[5]) #optimal number of colors
			end
		end
	end
	return n, m, arcs, nb_col
end

#######################################################################################
#Model
#######################################################################################
function creation_variables(n::Int,nb_col::Int)
	variables=Array{Variable,1}(undef,0)
	for node in 1:n
		name = string(node)
		a=Variable(name,collect(1:nb_col))
		push!(variables,a)
	end
	return variables
end
function creation_constraints!(model::Model,arcs::Array{Tuple{String,String},1})
	for x in model.variables
		for y in model.variables
			if (x!=y) && (x.name,y.name) in arcs
				wrapper(model, (x,y), (a,b) -> a!=b)
			end
		end
	end
end
function creation_coloration(instance::String)
	n, m, arcs, nb_col = graphe("instances/$instance")
	#domain=10
	variables = creation_variables(n,nb_col)
	model = Model(variables,[])
	creation_constraints!(model,arcs)
	return model
end

##### Solve all instances
time_ = 100
type_ = "coloration"
methods_=["root","nodes","varSelection","valueSelection"]

#for met in methods_
met="best"
	solve_instances(time_,type_, met)
	resultsArray(type_, met)
	performanceDiagram(type_,met)
#end
println("Reussie")