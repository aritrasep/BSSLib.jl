#########################################################################################################
#  This file is part of the julia module for  computing rebalancing operations in bike sharing systems 	#
#  (c) Copyright 2015-17 by Aritra Pal                                                                  #
#  Permission is granted for academic research use.                                                     #
#  For other uses,  contact the author for licensing options.                                           #
#  Use at your own risk. I make no guarantees about the correctness or  usefulness of this code.        #
#########################################################################################################

#####################################################################
# NLNS+VND for 1-PDTSP Instances                                    #
#####################################################################

@inbounds function nlns_vnd_1_pdtsp(nodes::Int64,instance::Int64,Q::Int64,alpha::Int64)
	try
		instance::BikeShareData = read_1_pdtsp_test_case(nodes,instance,Q,alpha)
		solution::BikeShareSolution = nlns_vnd(instance)
	catch
	end
end

#####################################################################
# NLNS+VND for USF Instances                                        #
#####################################################################

@inbounds function nlns_vnd_usf(nodes::Int64,operations::Int64,V::Int64=1,Q::Int64=5,speed::Float64=4.4704,l_ul_time::Int64=60)
	try
		instance::BikeShareData = read_test_case(nodes,operations,V,Q,speed,l_ul_time)
		solution::BikeShareSolution = nlns_vnd(instance)
	catch
	end
end

@inbounds function nlns_vnd_usf(nodes::Float64,operations::Float64,V::Float64,Q::Float64,speed::Float64,l_ul_time::Float64)
	try
		nlns_vnd_usf(round(Int64,nodes),round(Int64,operations),round(Int64,V),round(Int64,Q),speed,round(Int64,l_ul_time))
	catch
	
	end
end

#####################################################################
# NLNS+VND for Divvy Instances                                      #
#####################################################################

@inbounds function nlns_vnd_divvy(nodes::Int64,operations::Int64,V::Int64=1,Q::Int64=5,speed::Float64=4.4704,l_ul_time::Int64=60)
	try
		instance::BikeShareData = read_divvy_test_case(nodes,operations,V,Q,speed,l_ul_time)
		solution::BikeShareSolution = nlns_vnd(instance)
	catch
	end
end

@inbounds function nlns_vnd_divvy(nodes::Float64,operations::Float64,V::Float64,Q::Float64,speed::Float64,l_ul_time::Float64)
	try
		nlns_vnd_divvy(round(Int64,nodes),round(Int64,operations),round(Int64,V),round(Int64,Q),speed,round(Int64,l_ul_time))
	catch
	
	end
end
