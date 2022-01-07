include("model.jl")
"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- model: contains the variables with their values
"""
function write_solution(fout, model::Model)
	if model.solved
		print(fout, "solution = (")
		for x in model.variables
			print(fout, string(x.value) * ", ")
		end 
		println(fout, ")\n")
	else
		println(fout, "No solution found")
	end
	
	println("resolution_time = ", string(round(model.resolution_time, sigdigits=4)) * "s" )
	println("is_solved = ", model.solved)
end 