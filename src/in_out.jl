include("model.jl")
using Plots

"""
Write a solution in an output stream

Arguments
- fout: the output stream (usually an output file)
- model: contains the variables with their values
"""
function write_solution(fout, model::Model)
	n = length(model.variables)
	print(fout, "solution = (")
	for i in 1:1:n-1
		tup=(model.variables[i].name,model.variables[i].value)
		print(fout, string(tup)*"," )
	end
	tup=(model.variables[n].name,model.variables[n].value)
	println(fout, string(tup) * ")")
	println(fout, "resolution_time = " * string(round(model.resolution_time, sigdigits=6)))
	println(fout, "root_time = " * string(round(model.root_time, sigdigits=6)))
	println(fout, "nb_nodes = " * string(model.nb_nodes))
	println(fout, "is_solved = " * string(model.solved) * "\n")
end 

"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "resolution_time" and a variable "is_solved"
"""
function performanceDiagram(type_="queens", method="root")
    resultFolder = "res/" * type_ * "/" * method * "/"
	println("resultFolder = ", resultFolder)
    maxSize = 0# Maximal number of files in a subfolder
    subfolderCount = 0	# Number of subfolders
    folderName = Array{String, 1}()

	if method=="Best"
		path = resultFolder
		println("path = ", path)
		folderName = ["Best"]
		folderSize = size(readdir(path), 1)
		if maxSize < folderSize
			maxSize = folderSize
		end
		subfolderCount = 1
	else
		# For each file in the result folder
		for file in readdir(resultFolder)
			path = resultFolder * file
			if isdir(path)	# If it is a subfolder
				folderName = vcat(folderName, file)
				subfolderCount += 1
				folderSize = size(readdir(path), 1)
				if maxSize < folderSize
					maxSize = folderSize
				end
			end
		end
	end
	
    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxresolution_time = 0

	if method=="Best"
		path = resultFolder
		folderCount = 1
		fileCount = 0
		for resultFile in filter(x->occursin(".res", x), readdir(path))
			fileCount += 1
			include("../" * path * "/" * resultFile)
			if is_solved
				results[folderCount, fileCount] = resolution_time
				if resolution_time > maxresolution_time
					maxresolution_time = resolution_time
				end 
			end 
		end 
			
	else
		# For each subfolder
		for file in readdir(resultFolder)
			path = resultFolder * file
			if isdir(path)
				folderCount += 1
				fileCount = 0
				# For each text file in the subfolder
				for resultFile in filter(x->occursin(".res", x), readdir(path))
					fileCount += 1
					include("../" * path * "/" * resultFile)
					if is_solved
						results[folderCount, fileCount] = resolution_time
						if resolution_time > maxresolution_time
							maxresolution_time = resolution_time
						end 
					end 
				end 
			end
		end 
	end

	results = sort(results, dims=2)    # Sort each row increasingly
	println("Max solve time: ", maxresolution_time)
    

    for dim in 1: size(results, 1)	# For each line to plot
        x = Array{Float64, 1}()
        y = Array{Float64, 1}()

        # x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0

        append!(x, previousX)
        append!(y, previousY)
            
        currentId = 1	# Current position in the line

        # While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf
			identicalValues = 1# Number of elements which have the value previousX
            # While the value is the same
            while currentId < size(results, 2) && results[dim, currentId] == previousX
                currentId += 1
                identicalValues += 1
            end
            # Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)
            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            previousX = results[dim, currentId]
            previousY = currentId - 1
        end
        append!(x, maxresolution_time)
        append!(y, currentId - 1)

        
        if dim == 1# If it is the first subfolder
            
			if method=="Best"
				outputFile = "diagram_" * type_ * "_" * method
				savefig(plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3), outputFile)
			else
				# Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)
			end
		# Otherwise 
        else
            # Add the new curve to the created plot
			outputFile = "diagram_" * type_ * "_" * method
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "resolution_time" and a variable "is_solved"
"""
function resultsArray(type_="queens", method="Best")
    resultFolder = "res/" * type_ * "/" * method * "/"
    
    maxSize = 0	# Maximal number of files in a subfolder
    subfolderCount = 0	# Number of subfolders
	outputFile = "array_" * type_ * "_" * method * ".tex"
    fout = open(outputFile, "w")	# Open the latex output file

    # Print the latex file output
    println(fout, raw"""
	\documentclass[main.tex]{subfiles}
	%\newmargin{0.5cm}{0.5cm}
	\begin{document}
	\thispagestyle{empty}
	""")

    header = raw"""
	\begin{landscape}
	\begin{center}
	\begin{table}[h]
	\centering
	\caption{}
	\label{}
	\renewcommand{\arraystretch}{1.4} 
	\begin{tabular}{|l|"""

    folderName = Array{String, 1}()	# Name of the subfolder of the result folder (i.e, the resolution methods used)
    solvedInstances = Array{String, 1}()# List of all the instances solved by at least one resolution method

	if method=="Best"
		path = resultFolder
		println("path = ", path)
		folderSize = size(readdir(path), 1)
		for file2 in filter(x->occursin(".res", x), readdir(path))
			solvedInstances = vcat(solvedInstances, file2)
		end 
		if maxSize < folderSize
			maxSize = folderSize
		end
	
	else
		# For each file in the result folder
		for file in readdir(resultFolder)
			path = resultFolder * file
			println("path = ", path)
			if isdir(path)        # If it is a subfolder
				folderName = vcat(folderName, file)	# Add its name to the folder list
				subfolderCount += 1
				folderSize = size(readdir(path), 1)
				# Add all its files in the solvedInstances array
				for file2 in filter(x->occursin(".res", x), readdir(path))
					solvedInstances = vcat(solvedInstances, file2)
				end 
				if maxSize < folderSize
					maxSize = folderSize
				end
			end
		end
	end
	
	
    unique(solvedInstances)	# Only keep one string for each instance solved

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "cccc|"
    end
	if method=="Best"
		header *= "cccc|"
	end

    header *= "}\n\t\\hline\n\\textbf{" * method * " method :}"
	replace(header, "_" => "\\_")
	println(header)

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{4}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Solved ?} & \\textbf{(s)} & \\textbf{Nodes} & \\textbf{(s)/Nd}"
    end
	if method=="Best"
		header *= " & \\textbf{Solved ?} & \\textbf{(s)} & \\textbf{Nodes} & \\textbf{(s)/Nd}"
	end

    header *= "\\\\\\hline\n"

    footer = raw"""
	\hline\end{tabular}
	\end{table}
	\end{center}
	\end{landscape}
	"""
    println(fout, header)	# Replace the potential underscores '_' in file names

    maxInstancePerPage = 32	# On each page an array will contain at most maxInstancePerPage lines with results
    id = 1

    # For each solved files
	println("solvedInstances = ", solvedInstances)
    for solvedInstance in solvedInstances
        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        print(fout, replace(solvedInstance, "_" => "\\_"))	# Replace the potential underscores '_' in file names

		if method=="Best"
			path = resultFolder * "/" * solvedInstance
			if isfile(path)	# If the instance has been solved by this method
				println("../"*path)
				include("../"*path)
				print(fout, " & ")
				if is_solved
					print(fout, "\$\\times\$")
				end 
			#If the instance has not been solved by this method
			else
				print(fout, " & - & - ")
			end
			println(fout, " & ", round(resolution_time, digits=2), " & ", nb_nodes, " & ", round((resolution_time-root_time)/nb_nodes, sigdigits=2))
		else
			# For each resolution method
			println("folderName= ", folderName)
			for method in folderName
				path = resultFolder * method * "/" * solvedInstance
				if isfile(path)	# If the instance has been solved by this method
					println("../"*path)
					include("../"*path)
					print(fout, " & ")
					if is_solved
						print(fout, "\$\\times\$")
					end 
				#If the instance has not been solved by this method
				else
					print(fout, " & - & - ")
				end
				println(fout, " & ", round(resolution_time, digits=2), " & ", nb_nodes, " & ", round((resolution_time-root_time)/nb_nodes, sigdigits=2))
			end
		end
        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)
    println(fout, "\\end{document}")
    close(fout)
end 

