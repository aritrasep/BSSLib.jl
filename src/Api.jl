#########################################################################################################
#  This file is part of the julia module for  computing rebalancing operations in bike sharing systems 	#
#  (c) Copyright 2015-17 by Aritra Pal                                                                  #
#  Permission is granted for academic research use.                                                     #
#  For other uses,  contact the author for licensing options.                                           #
#  Use at your own risk. I make no guarantees about the correctness or  usefulness of this code.        #
#########################################################################################################

#####################################################################
# Reading functions                                                 #
#####################################################################

#####################################################################
# Reading test cases generated based on USF data                    #
#####################################################################

function read_test_case(nodes::Int64,operations::Int64,V::Int64=1,Q::Int64=5,speed::Float64=4.4704,L_UL_time::Int64=60)
	test_case_path::AbstractString = Pkg.dir("BSSLib/instances/USF/General/")
	data::Array{Int64,2} = round(Int64,readcsv(string(test_case_path,"$nodes","_$operations.csv")))
	O::Vector{Int64} = [data[4,:]...]
	distance::Array{Float64,2} = data[5:4+nodes,:]
	BikeShareData(nodes,O,V,Q,L_UL_time,round(Int64,distance/speed))
end

function read_real_test_case(nodes::Int64,operations::Int64,V::Int64=1,Q::Int64=5,speed::Float64=4.4704,L_UL_time::Int64=60)
	test_case_path::AbstractString = Pkg.dir("BSSLib/instances/USF/Real/")
	data::Array{Int64,2} = round(Int64,readcsv(string(test_case_path,"$nodes","_$operations.csv")))
	O::Vector{Int64} = [data[4,:]...]
	distance::Array{Float64,2} = data[5:4+nodes,:]
	BikeShareData(nodes,O,V,Q,L_UL_time,round(Int64,distance/speed))
end

#####################################################################
# Reading 1-PDTSP Instances                                         #
#####################################################################

@inbounds function read_1_pdtsp_test_case(nodes::Int64,instance::Int64=1,Q::Int64=10,alpha::Int64=1)
	read_1_pdtsp_test_case(Pkg.dir("BSSLib/instances/1-PDTSP Instances/n$(nodes)q$(Q)$(["A","B","C","D","E","F","G","H","I","J"][instance]).tsp"),alpha)
end

@inbounds function read_1_pdtsp_test_case(file_name::AbstractString,alpha::Int64)
	f = open(file_name)
	lines = readlines(f)
	N::Int64, Q::Int64, O::Vector{Int64} = parse(Int64,lines[3][12:end-1]), parse(Int64,lines[4][11:end-1]), [0]
	for i in 2:N
    	@match i begin
			2:9 => push!(O,parse(Int64,lines[2N+8+i][3:end-1]))
			10:99 => push!(O,parse(Int64,lines[2N+8+i][4:end-1]))
			_ => push!(O,parse(Int64,lines[2N+8+i][5:end-1]))
		end
	end	
	if sum(O) != 0
    	push!(O,-sum(O))
	end
	Coord = zeros(length(O),2)
	for i in 2:N
		tmp_lines = @match i begin
			2:9 => lines[6+i][2:end]
			10:99 => lines[6+i][3:end]
			_ => lines[6+i][4:end]
		end
    	Pos1, Pos2, Pos3 = 1, 1, 1
    	for j in 1:length(tmp_lines)	    
        	if tmp_lines[j] != ' ' && Pos1 == 1 && Pos2 == 1 && Pos3 == 1
            	Pos1 = j
        	end
        	if tmp_lines[j] == ' ' && Pos1 != 1 && Pos2 == 1 && Pos3 == 1
           	 	Pos2 = j-1
        	end
        	if tmp_lines[j] != ' ' && Pos1 != 1 && Pos2 != 1 && Pos3 == 1
            	Pos3 = j
        	end
    	end
    	Coord[i,1], Coord[i,2] = float(tmp_lines[Pos1:Pos2]), float(tmp_lines[Pos3:end-1])
	end
	N = length(O)

	Inv::Vector{Int64}, O, Capacity::Vector{Int64}, Distance::Array{Float64,2} = fill(alpha*10,N), O * alpha, fill(alpha*20,N), zeros(N,N)
	Target::Vector{Int64} = Inv + O
	for i in 1:N,j in i+1:N
    	Distance[j,i] = round(sqrt((Coord[i,1]-Coord[j,1])^2 + (Coord[i,2]-Coord[j,2])^2))
    	Distance[i,j] = Distance[j,i]
	end
	ind::Vector{Int64} = [1]
    	for i in 2:N
    		if O[i] != 0
    			push!(ind,i)
    		end
    	end
	BikeShareData(length(ind),O[ind],1,Q,0,Distance[ind,ind])
end

#####################################################################
# Reading test cases generated based on Divvy data                  #
#####################################################################

function read_divvy_test_case(nodes::Int64,operations::Int64,V::Int64=1,Q::Int64=5,speed::Float64=4.4704,L_UL_time::Int64=60)
	test_case_path::AbstractString = Pkg.dir("BSSLib/instances/Divvy/")
	data::Array{Int64,2} = round(Int64,readcsv(string(test_case_path,"$nodes","_$operations.csv")))
	O::Vector{Int64} = [data[4,:]...]
	distance::Array{Float64,2} = data[5:4+nodes,:]
	BikeShareData(nodes,O,V,Q,L_UL_time,round(Int64,distance/speed))
end

#####################################################################
# Creating Operations Matrix                                        #
#####################################################################

function create_operations_matrix(additional_info::Array{Float64,2},solution::BikeShareSolution)
	data::Array{Float64,2} = zeros(length(solution.Tour[1]),5)
	data[:,1:3] = additional_info[solution.Tour[1],1:3]
	data[:,4] = [ solution.Instructions[1][i]>0?solution.Instructions[1][i]:0 for i in 1:length(solution.Instructions[1]) ]
	data[:,5] = [ solution.Instructions[1][i]<0?abs(solution.Instructions[1][i]):0 for i in 1:length(solution.Instructions[1]) ]
	writecsv(".././test/USF/Real Time Data/Output.csv",data)
	data
end
