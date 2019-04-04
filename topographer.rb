require_relative "graph/network.rb"
require_relative "graph/vrf.rb"
require_relative "graph/vs.rb"
require_relative "graph/graph.rb"
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
                #vs1 = @graph.find "PROD_CORE_VS"
                #vs2 = @graph.find "MGMT_VS"
                #vs3 = @graph.find "PROD_GHO_VS"
                #vs4 = @graph.find "PROD_DCSERVICES_VS"
                #vs5 = @graph.find "PROD_PERIMETER_VS"
                #r = @graph.find "PROD_CORE_VR"

                #vs6 = @graph.find "NONPROD_EBT_VS"
                #vs7 = @graph.find "NONPROD_CORE_VS"
                #vs8 = @graph.find "NONPROD_GHO_VS"
                #vs9 = @graph.find "PP_DC_SERVICES_VS"
                #vs10 = @graph.find "TS_DC_SERVICES_VS"
                #vs11 = @graph.find "NONPROD_DCSERVICES_VS"
                #r2 = @graph.find "NONPROD_CORE_VR"

                #@graph.connect r,vs1
                #@graph.connect r,vs2
                #@graph.connect r,vs3
                #@graph.connect r,vs4
                #@graph.connect r,vs5
                #@graph.connect r2,vs6
                #@graph.connect r2,vs7
                #@graph.connect r2,vs8
                #@graph.connect r2,vs9
                #@graph.connect r2,vs10
                #@graph.connect r2,vs11
        end
    end

    def to_json file
        js = JSON.pretty_generate( JSON.parse(@graph.to_json) ).split('\n')
        File.open(file, "w+") do |f|
            js.each { |element| f.puts(element) }
        end
    end

    def print_shortest_path p_start, p_end
        puts "".ljust(70,"-")
        if not p_start.nil? and not p_end.nil?
            path = @graph.shortest_path p_start, p_end

            puts "A(start)".bold
            puts " | ".gray
            path.each_with_index do |vertex,i|
                if (vertex.class.name == "Network")
                    puts "#{vertex.name}(#{vertex.vlan})".cyan
                end
                if (vertex.class.name == "Vs")
                    puts "#{vertex.name}(FW)".magenta
                end
                if (vertex.class.name == "Vrf")
                    puts "#{vertex.name}(#{vertex.class.name})".green
                end
                if (vertex.class.name == "Interface")
                    puts "#{vertex.name}(#{vertex.class.name})".gray
                end
                if not (vertex.class.name == "Network" or vertex.class.name == "Vs" or vertex.class.name == "Vrf" or vertex.class.name == "Interface")
                    puts "#{vertex.name}(#{vertex.class.name})"
                end

                if path[i].class.name == "Vs" or path[i].class.name == "Vrf"
                else
                    if not (path[i+1].class.name == "Vs" or path[i+1].class.name == "Vrf")
                        puts " | ".gray
                    end
                end
                
            end

            puts "B(end)".bold
            puts "".ljust(70,"-")
        else
            puts "Sorry cant find information about these networkS"
        end
    end

    def tryme input
        vrf = @graph.vrfs.find_all{|vrf| vrf.name == input}.first
        if vrf.nil?
            vs = @graph.vses.find_all{|vs| vs.name == input}.first
            if vs.nil?
                vlan = @graph.networks.find_all{|network| network.vlan.to_s==input}.first
                if vlan.nil?
                    network = @graph.networks.find_all{|network| network.include? input}.first
                    if network.nil?
                        puts "nothing to do here :)"
                    else
                        print_info_for_network network
                    end
                else
                    print_info_for_network vlan
                end
            else
                print_vs_all vs.name
                # show attached networks to the VRF
            end
        else
            puts vrf.name
        end
    end

    def print_info_for_network network

        if network.nil?
            puts "No networks with this ID"
        else
            puts "---------------------------------------------------"
            puts "Vlan: #{network.vlan}"
            puts "Network: #{network.address.address} / #{network.address.prefix}"
            puts "Path to Internet: "
            vs = @graph.vertices.find{|vs| vs.name == "PER_EXT"}

            print_shortest_path network, vs
        end
    end
end


