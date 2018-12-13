require_relative "graph/vlan.rb"
require_relative "graph/vrf.rb"
require_relative "graph/vs.rb"
require_relative "graph/graph.rb"
require_relative "poller.rb"
require "ipaddress"
require "rgl/adjacency"
require "rgl/dot"

class Topographer
    attr_accessor :graph

    def initialize filename=nil
        @graph = Graph.new 
        
        if not filename.nil?
            @graph = Graph.from_json File.read(filename)
            #Manual
            vs1 = @graph.find "PROD_CORE_VS"
            vs2 = @graph.find "MGMT_VS"
            vs3 = @graph.find "PROD_GHO_VS"
            vs4 = @graph.find "PROD_DCSERVICES_VS"
            vs5 = @graph.find "PROD_PERIMETER_VS"
            r = @graph.find "PROD_CORE_VIRTUAL-ROU"

            vs6 = @graph.find "NONPROD_EBT_VS"
            vs7 = @graph.find "NONPROD_CORE_VS"
            vs8 = @graph.find "NONPROD_GHO_VS"
            vs9 = @graph.find "PP_DC_SERVICES_VS"
            vs10 = @graph.find "TS_DC_SERVICES_VS"
            vs11 = @graph.find "NONPROD_DCSERVICES_VS"
            r2 = @graph.find "NONPROD_CORE_VIRTUAL-"

            @graph.connect r,vs1
            @graph.connect r,vs2
            @graph.connect r,vs3
            @graph.connect r,vs4
            @graph.connect r,vs5

            @graph.connect r2,vs6
            @graph.connect r2,vs7
            @graph.connect r2,vs8
            @graph.connect r2,vs9
            @graph.connect r2,vs10
            @graph.connect r2,vs11
        end
    end
end


