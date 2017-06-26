#########################################################################################################
#  This file is part of the julia module for  computing rebalancing operations in bike sharing systems 	#
#  (c) Copyright 2015-17 by Aritra Pal                                                                  #
#  Permission is granted for academic research use.                                                     #
#  For other uses,  contact the author for licensing options.                                           #
#  Use at your own risk. I make no guarantees about the correctness or  usefulness of this code.        #
#########################################################################################################

#####################################################################
# Reading USF data                                                  #
#####################################################################

function read_usf_data()
    bike_racks::DataFrame = readtable(".././instances/USF/Data/Share-A-Bull.csv", header=true)
    bike_racks[:X], bike_racks[:Y] = zeros(nrow(bike_racks)), zeros(nrow(bike_racks))
    for i in 1:nrow(bike_racks)
    	bike_racks[:X][i], bike_racks[:Y][i] = compute_coordinates(bike_racks[:Latitude][i],bike_racks[:Longitude][i])
   	end
   	delete!(bike_racks,[:Latitude,:Longitude])
   	bike_racks
end

function compute_coordinates(lat::Float64,long::Float64)
	begin_lat::Float64, begin_long::Float64 = 28.0529,-82.4306
	round(great_distance(begin_lat, begin_long, begin_lat, long)["distance"]), round(great_distance(begin_lat, begin_long, lat, begin_long)["distance"])
end

#####################################################################
# Reading Divvy data                                                #
#####################################################################

function read_divvy_data()
    bike_racks::DataFrame = readtable(".././instances/Divvy/Data/Divvy_Stations.csv", header=true)
    bike_racks[:X], bike_racks[:Y] = zeros(nrow(bike_racks)), zeros(nrow(bike_racks))
    for i in 1:nrow(bike_racks)
    	bike_racks[:X][i], bike_racks[:Y][i] = compute_divvy_coordinates(bike_racks[:Latitude][i],bike_racks[:Longitude][i])
   	end
   	delete!(bike_racks,[:Latitude,:Longitude])
   	bike_racks
end

function compute_divvy_coordinates(lat::Float64,long::Float64)
	begin_lat::Float64, begin_long::Float64 = 41.75712007, -87.73237045
	(round(Int64,dis.vincenty((begin_lat, begin_long), (begin_lat, long))[:meters]), round(Int64,dis.vincenty((begin_lat, begin_long), (lat, begin_long))[:meters]))
end

function minimum_distance(x::Int64,y::Int64,data::DataFrame)
    min::Float64, dist::Float64 = Inf, 0.0
    for i in 1:nrow(data)
        dist = sqrt((data[:X][i]-x)^2 + (data[:Y][i]-y)^2)
        if dist < min
            min = dist
        end
    end
    min
end

function generate_station_capacities(data::DataFrame)
    ceil(Int64,abs(randn(1)*std(data[:Capacity][2:end]) + mean(data[:Capacity][2:end])))
end

function generate_artificial_station!(data::DataFrame,lowerbound::Int64)
    x::Int64 = -1; y::Int64 = -1; count::Int64 = 1
    while true
        while true
            x = rand(0:3313,1)[1]
            y = rand(0:1950,1)[1]
            tmp_data = data[data[:X] .== x,:]
            if nrow(tmp_data) > 0
                tmp_data = tmp_data[tmp_data[:Y] .== y,:]
                if nrow(tmp_data) > 0
                    continue
                else
                    break
                end
            else
                break
            end
        end
        if minimum_distance(x,y,data) >= lowerbound
            break
        end
        if count == 2000
            break
        end
        count += 1
    end
    if minimum_distance(x,y,data) >= lowerbound
        push!(data,[generate_station_capacities(data)...,x,y])
        data
    else
        data
    end
end

function generate_artificial_stations(data::DataFrame)
    lowerbound::Int64 = 1000
    rows::Int64 = nrow(data)
    while nrow(data) <= 200
        generate_artificial_station!(data,lowerbound)
        if nrow(data) == rows
            lowerbound -= 1
        else
            rows = nrow(data)
            println("Stations created is $(rows-156) , lowerbound = $lowerbound")
        end
    end
    data
end

function generate_distance_matrix(data::DataFrame)
    distance_matrix::Array{Float64,2} = zeros(nrow(data),nrow(data))
    for i in 1:nrow(data)
        for j in i+1:nrow(data)
           	distance_matrix[i,j] = abs(data[:X][i]-data[:X][j]) + abs(data[:Y][i]-data[:Y][j])
			distance_matrix[j,i] = distance_matrix[i,j]
        end
    end
    distance_matrix
end

function satisfy_Δ_inequality{T<:Real}(data::Array{T,2})
    dist = 0
    count::Int64 = 0
    for i in 1:size(data)[1]
        for j in i+1:size(data)[1]
            dist = minimum(collect([data[i,k] + data[k,j] for k in setdiff([1:size(data)[1]],[i,j])]))
            if data[i,j] > dist
                count += 1
                println("$i to $j doesn't satishfy Δ inequality")
            end
        end
    end
    count
end

function generate_data_for_test_case()
    println("Started reading USF data")
    bike_racks::DataFrame = read_usf_data()
    println("Finished reading USF data")

    println("Started creating artificial stations")
    bike_racks = generate_artificial_stations(bike_racks)
    println("Finished Creating artificial stations")

    println("Started computing Distance and Time Matrix")
    distance_matrix = generate_distance_matrix(bike_racks)
    println("Finished computing Distance and Time Matrix")

   	#println("Checking Δ inequality of Distance Matrix")
    #if satisfy_Δ_inequality(distance_matrix) > 0
    #    println("Distance Matrix does not satisfy Δ inequality")
    #else
    #    println("Distance Matrix satisfy Δ inequality")
    #end
    (bike_racks,distance_matrix)
end

function generate_data_for_divvy_test_case()
	println("Started reading Divvy data")
    bike_racks::DataFrame = read_divvy_data()
    println("Finished reading Divvy data")

    println("Started computing Distance Matrix")
    distance_matrix = generate_distance_matrix(bike_racks)
    println("Finished computing Distance Matrix")

   	#println("Checking Δ inequality of Distance Matrix")
    #if satisfy_Δ_inequality(distance_matrix) > 0
    #    println("Distance Matrix does not satisfy Δ inequality")
    #else
    #    println("Distance Matrix satisfy Δ inequality")
    #end
    (bike_racks,distance_matrix)

end

#####################################################################
# Generating a test case                                            #
#####################################################################

function generate_test_cases(N::Int64,opr::Int64,C::Vector{Int64},Distance)
	if N < 146
		ind::Vector{Int64} = [1,sort(shuffle(2:147)[1:N])...]
	else
		ind = [1,sort(shuffle(2:200)[1:N])...]
    end
    O::Vector{Int64} = zeros(Int64,N+1)
    ind_pickup::Vector{Int64} = ind[sort(shuffle(2:N+1)[1:rand(maximum([N-round(Int64,opr/2),round(Int64,N/3)]):round(Int64,N/2))])]
    for i in ind_pickup
    	O[findin(ind,i)[1]] += 1
    end
    opr_p::Int64 = round(Int64,opr/2) - length(ind_pickup)
    pos::Int64 = 0
    tmp::Int64 = 0
    while opr_p > 0
    	pos = ind_pickup[rand(1:length(ind_pickup))]
    	if C[pos] == O[findin(ind,pos)[1]]
    		continue
    	end
    	tmp = rand(1:minimum([opr_p,C[pos]-O[findin(ind,pos)[1]]]))
    	O[findin(ind,pos)[1]] += tmp
    	opr_p -= tmp
    end

    ind_delivery::Vector{Int64} = sort(setdiff(ind[2:end],ind_pickup))
    for i in ind_delivery
    	O[findin(ind,i)[1]] += 1
    end
    opr_d::Int64 = round(Int64,opr/2) - length(ind_delivery)
    while opr_d > 0
    	pos = ind_delivery[rand(1:length(ind_delivery))]
    	if C[pos] == O[findin(ind,pos)[1]]
    		continue
    	end
    	tmp = rand(1:minimum([opr_d,C[pos]-O[findin(ind,pos)[1]]]))
    	O[findin(ind,pos)[1]] += tmp
    	opr_d -= tmp
    end
    for i in ind_delivery
    	O[findin(ind,i)[1]] = -1O[findin(ind,i)[1]]
    end

    Inv::Vector{Int64} = zeros(Int64,N+1)
    Target::Vector{Int64} = zeros(Int64,N+1)
    i = 2
    while i <= length(ind)
        if O[i] > 0
            Inv[i] = O[i]
        else
            Target[i] = -1*O[i]
        end
        i += 1
    end
    write_test_cases(N+1,opr,C[ind],Inv,Target,O,Distance[ind,ind],"real")
end

function generate_divvy_test_cases(N::Int64,opr::Int64,C::Vector{Int64},Distance)
	ind::Vector{Int64} = [sort(shuffle([1:length(C)])[1:N+1])]
	O::Vector{Int64} = zeros(Int64,N+1)
    ind_pickup::Vector{Int64} = ind[sort(shuffle([2:N+1])[1:rand(maximum([N-round(Int64,opr/2),round(Int64,N/3)]):round(Int64,N/2))])]
    for i in ind_pickup
    	O[findin(ind,i)[1]] += 1
    end
    opr_p::Int64 = round(Int64,opr/2) - length(ind_pickup)
    pos::Int64 = 0
    tmp::Int64 = 0
    while opr_p > 0
    	pos = ind_pickup[rand(1:length(ind_pickup))]
    	if C[pos] == O[findin(ind,pos)[1]]
    		continue
    	end
    	tmp = rand(1:minimum([opr_p,C[pos]-O[findin(ind,pos)[1]]]))
    	O[findin(ind,pos)[1]] += tmp
    	opr_p -= tmp
    end

    ind_delivery::Vector{Int64} = sort(setdiff(ind[2:end],ind_pickup))
    for i in ind_delivery
    	O[findin(ind,i)[1]] += 1
    end
    opr_d::Int64 = round(Int64,opr/2) - length(ind_delivery)
    while opr_d > 0
    	pos = ind_delivery[rand(1:length(ind_delivery))]
    	if C[pos] == O[findin(ind,pos)[1]]
    		continue
    	end
    	tmp = rand(1:minimum([opr_d,C[pos]-O[findin(ind,pos)[1]]]))
    	O[findin(ind,pos)[1]] += tmp
    	opr_d -= tmp
    end
    for i in ind_delivery
    	O[findin(ind,i)[1]] = -1O[findin(ind,i)[1]]
    end

    Inv::Vector{Int64} = zeros(Int64,N+1)
    Target::Vector{Int64} = zeros(Int64,N+1)
    i = 2
    while i <= length(ind)
        if O[i] > 0
            Inv[i] = O[i]
        else
            Target[i] = -1*O[i]
        end
        i += 1
    end
    write_divvy_test_cases(N+1,opr,C[ind],Inv,Target,O,Distance[ind,ind])
end

#####################################################################
# Writing a test case                                               #
#####################################################################

function write_test_cases(nodes::Int64,operations::Int64,Capacity::Vector{Int64},Inventory::Vector{Int64},Target::Vector{Int64},O::Vector{Int64},Distance,real_or_general)
    data::Array{Int64,2} = zeros(Int64,nodes+4,nodes)
    data[1,:] = Capacity
    data[2,:] = Inventory
    data[3,:] = Target
    data[4,:] = O
    data[5:4+nodes,:] = Distance
    if contains(real_or_general,"real")
    	write_test_case_path = string(".././test/USF/Real/")
    else
    	write_test_case_path = string(".././test/USF/General/")
    end
    writecsv(string(write_test_case_path,"$nodes","_$operations.csv"),data)
end

global write_divvy_test_case_path = string(".././test/Divvy/")

function write_divvy_test_cases(nodes::Int64,operations::Int64,Capacity::Vector{Int64},Inventory::Vector{Int64},Target::Vector{Int64},O::Vector{Int64},Distance)
    data::Array{Int64,2} = zeros(Int64,nodes+4,nodes)
    data[1,:] = Capacity
    data[2,:] = Inventory
    data[3,:] = Target
    data[4,:] = O
    data[5:4+nodes,:] = Distance
    writecsv(string(write_divvy_test_case_path,"$nodes","_$operations.csv"),data)
end

#####################################################################
# Generating and writing the test cases                             #
#####################################################################

function create_usf_real_test_cases(num_test_cases::Int64=5)
	Nodes::Vector{Int64} = round(Int64, sort(sample(50:130, num_test_cases, replace = false)))
    Operations::Vector{Int64} = zeros(Int64, num_test_cases)
    for i in 1:length(Operations)
    	Operations[i] = rand(Nodes[i]:126,1)[1]
    	if Operations[i] % 2 != 0
    		Operations[i] += 1
    	end
    end
    Capacity::Vector{Int64} = round(Int64,bike_racks[:Capacity])
    test_cases::Int64 = 1
	test_cases_details::DataFrame = DataFrame()
    test_cases_details[:Test_Case], test_cases_details[:Nodes], test_cases_details[:Operations] = Int64[], Int64[], Int64[]
	for i in 1:num_test_cases
        println("Nodes = $(Nodes[i]) , Operations = $(Operations[i])")
        generate_test_cases(Nodes[i]-1,Operations[i],Capacity,distance_matrix)
        push!(test_cases_details,[test_cases,Nodes[i],Operations[i]])
        test_cases += 1
    end
    #################################################################
	# Writing the details of the test cases in Details.csv          #
	#################################################################
    writetable(string(".././test/USF/Real/","Details.csv"),test_cases_details)
end

function create_usf_general_test_cases()
	(bike_racks,distance_matrix) = generate_data_for_test_case()
    Nodes::Vector{Int64} = [100,200,300,400]
    Operations::Vector{Int64} = [200,400,600]
    Capacity::Vector{Int64} = round(Int64,bike_racks[:Capacity])
    test_cases::Int64 = 1
	test_cases_details::DataFrame = DataFrame()
    test_cases_details[:Test_Case], test_cases_details[:Nodes], test_cases_details[:Operations] = Int64[], Int64[], Int64[]
	for opr in Operations, n in Nodes
		if opr == 200 && n > 200
			continue
		end
		if opr == 400 && n > 300
			continue
		end
        println("Nodes = $n , Operations = $opr")
        generate_test_cases(n-1,opr,Capacity,distance_matrix)
        push!(test_cases_details,[test_cases,n,opr])
        test_cases += 1
    end
    #################################################################
	# Writing the details of the test cases in Details.csv          #
	#################################################################
    writetable(string(".././test/USF/General/","Details.csv"),test_cases_details)
end

function create_divvy_test_cases()
	(bike_racks,distance_matrix) = generate_data_for_divvy_test_case()
    Nodes::Vector{Int64} = [450]
    Operations::Vector{Int64} = [1000, 2000, 3000, 4000, 5000, 6000]
    Capacity::Vector{Int64} = round(Int64,bike_racks[:Capacity])
    test_cases::Int64 = 1
	test_cases_details::DataFrame = DataFrame()
    test_cases_details[:Test_Case], test_cases_details[:Nodes], test_cases_details[:Operations] = Int64[], Int64[], Int64[]
	for opr in Operations, n in Nodes
		println("Nodes = $n , Operations = $opr")
        generate_divvy_test_cases(n-1,opr,Capacity,distance_matrix)
        push!(test_cases_details,[test_cases,n,opr])
        test_cases += 1
    end
    #################################################################
	# Writing the details of the test cases in Details.csv          #
	#################################################################
    writetable(string(write_divvy_test_case_path,"Details.csv"),test_cases_details)
end
