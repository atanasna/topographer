require "awesome_print"
require "ipaddress"

require_relative "ConfigPoller.rb"
require_relative "../config/globals.rb"
require_relative "../graph/network.rb"
require_relative "../graph/interface.rb"
require_relative "../graph/vrf.rb"
require_relative "../graph/vs.rb"
require_relative "../graph/graph.rb"

class ConfigParser
    
    def self.parse_checkpoint_vsx config, graph

        vs_configs = config.slice_before{|line| line.match(/######## /)}.to_a    
        warp_interfaces = Array.new

        vs_configs.each do |vs_config|

            # Parse VS
            vs_name = vs_config.first.sub!("######## ","")
            if vs_name == "0" then next end
            vs = Vs.new(vs_name)
            graph.add_vertex vs

            # Parsing Interfaces
            interface_configs = vs_config.select{|line| line.match(/ipv4/)}
            interface_configs.each do |int_config|
                # Checks
                #if int_config.match(/Not Configured/) then next end

                # Parsing
                interface_name = nil
                interface_address = nil
                network_address = nil
                vlan_id = nil
                
                
                interface_name = int_config.match(/(.+)\s+-.+/i).captures.first
                interface_address = int_config.match(/ipv4-address (.+)/i).captures.first
                network_address = interface_address
                if interface_name.match(/bond\d+\.(\d+)/)
                    vlan_id = interface_name.match(/bond\d+\.(\d+)/i).captures.first
                end
 
                ap "#{vs.name} : #{interface_name} : #{interface_address} : #{network_address}"
                
                # Graph creation
                interface = Interface.new interface_name, interface_address

                network_address = IPAddress(network_address).network
                network = graph.find "#{network_address.address.to_s}/#{network_address.prefix.to_s}"
                if network.nil?  
                    network = Network.new interface_address, vlan_id
                end

                graph.add_vertex interface
                graph.connect vs, interface

                if interface.name.match(/wrp/)
                    warp_interfaces.push interface
                    if interface.name.match(/wrp\d/)
                        warp_interface_num = interface.name.match(/wrp(\d+)/i).captures.first
                        other_warp_interface = warp_interfaces.find{|interface| interface.name.match(/wrpj#{warp_interface_num}/)}

                        if other_warp_interface
                            graph.connect interface, other_warp_interface
                        end
                    end
                    if interface.name.match(/wrpj\d/)
                        warp_interface_num = interface.name.match(/wrpj(\d+)/i).captures.first
                        other_warp_interface = warp_interfaces.find{|interface| interface.name.match(/wrp#{warp_interface_num}/)}
                        
                        if other_warp_interface
                            graph.connect interface, other_warp_interface
                        end
                    end
                else
                    graph.add_vertex network
                    graph.connect interface, network
                end
            end
        end
    end
    
    def self.parse_cisco_generic config, graph
        # Parse VRFs
            vrfs_configs = config.select{|line| line.match(/vrf context/)}.uniq
            vrfs_configs.each do |vrf|
                vrf_name = vrf.match(/vrf context (.+)/i).captures.first
                graph.add_vertex Vrf.new(vrf_name)
            end

        # Parse interfaces
            # Get all interfaces configuration
            interface_configs = config.slice_before{|line| line.match(/^interface/)}.to_a
            interface_configs.shift

            interface_configs.each do |int_config|
                # Checks if interface is active and L3
                if int_config.find{|line| line.match(/no shut/)}.nil? then next end
                if int_config.find{|line| line.match(/ip address/)}.nil? then next end    
                
                # Parsing
                interface_name = nil
                interface_address = nil
                network_address = nil
                vlan_id = nil
                vrf_name = nil

                interface_name = int_config.first.match(/interface (.+)/i).captures.first
                interface_address = int_config.find{|line| line.match(/ip address/)}.match(/ip address (.+)/i).captures.first
                network_address = interface_address
                if interface_name.match(/Vlan/)
                    vlan_id = interface_name.match(/Vlan(.+)/i).captures.first
                end
                if int_config.find{|line| line.match(/vrf/)}
                    vrf_name = int_config.find{|line| line.match(/vrf/)}.match(/vrf member (.+)/i).captures.first
                end

                # Graph creation
                interface = Interface.new interface_name, interface_address

                network_address = IPAddress(network_address).network
                network = graph.find "#{network_address.address.to_s}/#{network_address.prefix.to_s}"
                if network.nil?  
                    network = Network.new interface_address, vlan_id
                end

                vrf = graph.find vrf_name

                graph.add_vertex interface
                graph.add_vertex network
                graph.connect vrf, interface
                graph.connect interface, network
            end
    end

    def self.parse_cisco_nexus config, graph
        vdc_configs = config.slice_before{|line| line.match(/switchto vdc /)}.to_a   
        
        vdc_configs.each do |config|
            ConfigurationParser.parse_cisco_generic config, graph
        end
    end
end