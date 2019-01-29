require "awesome_print"
require "ipaddress"

require_relative "ConfigurationPoller.rb"
require_relative "../config/globals.rb"
require_relative "../graph/network.rb"
require_relative "../graph/interface.rb"
require_relative "../graph/vrf.rb"
require_relative "../graph/vs.rb"
require_relative "../graph/graph.rb"

class ConfigurationParser

    def self.parse_checkpoint_vsx config, graph

        vs_configs = config.slice_before{|line| line.match(/######## /)}.to_a    
        vs_configs.each do |vs_config|
            # Parse VS name
            vs_name = vs_config.first.sub!("######## ","")
            vs = Vs.new(vs_name)
            graph.add_vertex vs
            ap "Adding #{vs.name}(#{vs.class.name}) to graph"

            ap vs_config
            # Parse for networks
            #[0] "######## 0",
            #[1] "#### Interfaces",
            #[2] "Context is set to Virtual Device WOK-FW1 (ID 0).",
            #[3] "Mgmt Link encap:Ethernet HWaddr 00:1C:7F:33:E0:E3 inet addr:10.66.51.131 Bcast:10.66.51.255 Mask:255.255.255.128",
            #[4] "eth2-04 Link encap:Ethernet HWaddr 00:1C:7F:61:F1:29 inet addr:192.168.30.1 Bcast:192.168.30.255 Mask:255.255.255.0",
            #[5] "lo Link encap:Local Loopback inet addr:127.0.0.1 Mask:255.0.0.0",
            #[6] "Context is set to Virtual Device WOK-FW1 (ID 0)."

            # Find networks
            interfaces_conf = vs_config.select{|line| line.match(/Link encap/)}
            interfaces_conf.each do |line|
                if line.match(/127.0.0.1/) or line.match(/P-t-P/)

                    next
                end

                vlan_id = nil
                if line.match(/.+\..+\sLink/)
                    vlan_id = line.match(/.+\.(.+)\sLink/i).captures.first
                end
                net_addr, net_mask = line.match(/.+Link.+inet addr:(\d+\.\d+\.\d+\.\d+).+Mask:(\d+\.\d+\.\d+\.\d+)/i).captures
                if graph.interfaces.find{|network| network.address == IPAddress("#{net_addr}/#{net_mask}").network}.nil?
                    network = Network.new("#{net_addr}/#{net_mask}",vlan_id)
                    graph.add_vertex network
                    #ap "Adding #{network.name}(#{network.class.name}) - #{vlan_id} to graph"
                end
            end

            # Find interfaces

            #interfaces_conf = vs_config.select{|line| line.match(/Link encap/)}
            #interfaces_conf.each do |line|
#
            #    if line.match(/(\w+)\sLink.+inet addr:(\d+\.\d+\.\d+\.\d+).+Mask:(\d+\.\d+\.\d+\.\d+)/i)
#
            #        captures = line.match(/(.+)\sLink.+inet addr:(\d+\.\d+\.\d+\.\d+).+Mask:(\d+\.\d+\.\d+\.\d+)/i).captures
            #        int_name = captures[0]
            #        int_address = captures[1]
            #        int_netmask = captures[2]
#
            #        if int_address=="127.0.0.1"
            #            next
            #        end
            #        
            #        interface = Interface.new(int_name, IPAddress("#{int_address}/#{int_netmask}"), vs_name)
            #        graph.add_vertex interface
            #        #ap graph.vertices
            #        ap "Adding #{interface.name}(#{interface.class.name}) to graph"
#
            #        if line.match(/Bcast/) 
            #            bcast_int_dst_network = IPAddress("#{int_address}/#{int_netmask}").network
            #            dst_network = graph.networks.find{|network| network.address == bcast_int_dst_network}
            #            if dst_network
            #                graph.connect interface,dst_network
            #                ap "Connecting #{interface.name} <-> #{dst_network.name}"
            #            else
            #                vlan_id = nil
            #                if line.match(/\w+\.\d+\sLink/)
            #                    vlan_id = line.match(/\w+\.\d+\sLink/i).captures.first
            #                end
            #                network = Network.new "#{int_address}/#{int_netmask}", vlan_id
            #                graph.add_vertex network
            #                ap "Adding #{network.name}(#{network.class.name}) to graph"
            #                ap graph.vertices
            #                graph.connect interface,network
#
            #                ap "Connecting #{interface.name} <-> #{network.name}"
            #            end
            #        end
#
            #        if line.match(/P-t-P/)
            #            address = line.match(/P-t-P:(\d+\.\d+\.\d+\.\d+)/i).captures.first
            #            ptp_int_dst_address = IPAddress address
#
            #            #find if dst interfaces exists in graph
            #            dst_int = graph.interfaces.find{|interface| interface.address == ptp_int_dst_address}
            #            if dst_int
            #                graph.connect interface,dst_int
            #                ap "Connecting #{interface.name} <-> #{dst_network.name}"
            #            end
            #        end   
#
            #    end
#
            #    ap "#{interface} - #{type} - #{address}/#{netmask}"
#
            #end

        end
    end
    


end