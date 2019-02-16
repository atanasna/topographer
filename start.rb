require_relative "graph/network.rb"
require_relative "graph/vrf.rb"
require_relative "graph/vs.rb"
require_relative "graph/graph.rb"
require_relative "poller.rb"
require_relative "topographer.rb"
require "rgl/adjacency"
require "rgl/dot"
require "ipaddress"
require "awesome_print"

def print_vs_vrfs graph, vs_name
    puts "| #{vs_name} >>>".ljust(70,"=")
    puts "".ljust(70,"-")
    vs = graph.find vs_name
    vrfs = graph.get_vrfs_behind_vs vs
    vrfs.each do |vrf|
        puts "| #{vrf.name}".ljust(69," ") + "|"
    end
    puts "".ljust(70,"-")
end

def print_vs_networks graph, vs_name
    vs = graph.find vs_name
    networks = graph.get_networks_behind_vs vs
    puts "| #{vs_name} >>>".ljust(70,"=")
    puts "".ljust(70,"-")
    puts "| Vlan  | Network".ljust(69," ") + "|"
    puts "".ljust(70,"-")
    networks.each do |network|
        puts "| #{network.vlan.to_s.ljust(5)} | #{network.address.address}/#{network.address.prefix}".ljust(69," ") + "|"
    end
    puts "".ljust(70,"-")
end

def print_vs_all graph, vs_name
    puts "| #{vs_name} >>>".ljust(70,"=")
    puts "".ljust(70,"-")
    puts "| VRF".ljust(25) + "|" + 
    " Vlan".ljust(20) + "|" +
    " Network".ljust(22) + "|"
    
    vs = graph.find vs_name
    vrfs = graph.get_vrfs_behind_vs vs
    networks_all = graph.get_networks_behind_vs vs

    # print VRF connected networks
    vrfs.each do |vrf|
        network_num = 0
        networks = graph.get_networks_behind_vrf vrf

        puts "|".ljust(69,".") + "|"
        puts "| #{vrf.name}".ljust(25) + 
        "|" + " #{networks.first.vlan}".ljust(20) +
        "| #{networks.first.address.address} / #{networks.first.address.prefix}".ljust(23) + "|"
        networks_all.delete(networks.first)
        networks.delete(networks.first)
        networks.each do |network|
            puts "| ".ljust(25) + 
            "|" + " #{network.vlan}".ljust(20) +
            "| #{network.address.address} / #{network.address.prefix}".ljust(23) + "|"
            networks_all.delete(network)
        end
    end

    #print directly connected
    if networks_all.count != 0
        puts "|".ljust(69,".") + "|"
        puts "| Direct ".ljust(25) + 
        "|" + " #{networks_all.first.vlan}".ljust(20) + 
        "| #{networks_all.first.address.address} / #{networks_all.first.address.prefix}".ljust(23) + "|"
        networks_all.delete(networks_all.first)
        networks_all.each do |network|
            puts "| ".ljust(25) + 
            "|" + " #{network.vlan}".ljust(20) +
            "| #{network.address.address} / #{network.address.prefix}".ljust(23) + "|"
        end
    end
    
    puts "".ljust(70,"-")
    #puts "-------------------------------------------"
end

def tryme graph, input
    vrf = graph.vrfs.find_all{|vrf| vrf.name == input}.first
    if vrf.nil?
        vs = graph.vses.find_all{|vs| vs.name == input}.first
        if vs.nil?
            network = graph.networks.find_all{|network| network.vlan.to_s==input}.first
            if network.nil?
                network = graph.networks.find_all{|network| network.include? input}.first
                if network.nil?
                    puts "nothing to do here :)"
                else
                    print_info_for_network graph, network
                end
            else
                print_info_for_network graph, network
            end
        else
            print_vs_all graph, vs.name
            # show attached networks to the VRF
        end
    else
        puts vrf.name
    end
end

def print_shortest_path graph, ip_a, ip_b
    network_a = graph.networks.find_all{|network| network.include? ip_a}.first
    network_b = graph.networks.find_all{|network| network.include? ip_b}.first
    puts "".ljust(70,"-")
    puts "node A IP: #{ip_a}"
    puts "node B IP: #{ip_b}"
    puts
    if not network_a.nil? and not network_b.nil?
        path = graph.shortest_path network_a,network_b

        print "A -> "
        path.each do |node|
            if (node.class.name == "Network")
                print "#{node.name}(#{node.vlan})"
            else
                print "#{node.name}(#{node.class.name})"
            end
            print " -> "
        end

        puts "B"
        #path.each_index do |i|
        #    if (path[i].class.name == "Network")
        #        print "#{path[i].name}(#{path[i].vlan})"
        #    else
        #        print "#{path[i].name}(#{path[i].class.name})"
        #    end
        #    if (path.size-1 > i)
        #        print " -> "
        #    end
        #end
    else
        puts "Sorry cant find information about these networkS"
    end
end

def print_info_for_network graph, network

    if network.nil?
        puts "No networks with this ID"
    else
        puts "---------------------------------------------------"
        puts "Vlan: #{network.vlan}"
        puts "Network: #{network.address.address} / #{network.address.prefix}"
        puts "Path out:"
        vs = graph.vses.find{|vs| vs.name == "PROD_PERIMETER_VS"}
        graph.shortest_path(network, vs).each do |v|
            print "#{v.name}(#{v.class}) -> "
        end
    end
end

def print_vs_list vses
    puts "Please specify VS:"
    cnt = 1 
    vses.each do |vs|
        puts "#{cnt}. #{vs.name}"
        cnt += 1
    end
    puts "--"
    print "Pick a firewall: "
end

# START---------------------------------------------------------------

#puts "Do you want to update the DB [y/n]"
#resp = gets.chomp
#if resp == "y"
#    puts "passcode?: "
#    passcode = gets.chomp
#    poll_all "nikata", passcode, "vsx_util_interfaces"
#end

topographer = Topographer.new "json_graph"

#Menu 
    while true
        system('cls')
        puts "Pick an option"
        puts "1. Show VRFs behind VS"
        puts "2. Show Networks behind VS"
        puts "3. Show EVERYTHING per VS"
        puts "4. Find path A -> B"
        puts "5. Try my superior intelligence"
        puts "q. Exit"
        resp = gets.chomp
        #1. Show VRFs behind VS
        if resp=="1"
            print_vs_list topographer.graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_vrfs topographer.graph, topographer.graph.vses[fw.to_i-1].name
            puts "Press ENTER key to go back to Menu"
            gets.chomp
        end
        #2. Show Networks behind VS
        if resp=="2"
            print_vs_list topographer.graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_networks topographer.graph, topographer.graph.vses[fw.to_i-1].name
            puts "Press ENTER key to go back to Menu"
            gets.chomp
        end
        #3. Show EVERYTHING per VS
        if resp=="3"
            print_vs_list topographer.graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_all topographer.graph, topographer.graph.vses[fw.to_i-1].name
            puts "Press ENTER to go back to Menu"
            gets.chomp
        end
        #4. Find by whatever is given
        if resp=="4"
            ip_a = nil
            ip_b = nil
            # get IP of node A
            while true
                print "Address of NodeA:"
                ip_a = gets.chomp
                if ip_a.match(/\d+\.\d+\.\d+\.\d+/)
                    break
                else
                    system('cls')
                    puts "Address was wrong please try again!"
                end
            end
            # get IP of node B
            while true
                print "Address of NodeB:"
                ip_b = gets.chomp
                if ip_b.match(/\d+\.\d+\.\d+\.\d+/)
                    break
                else
                    system('cls')
                    puts "Address was wrong please try again!"
                end
            end
            print_shortest_path topographer.graph, ip_a, ip_b
            puts "Press ENTER to go back to Menu"
            gets.chomp
        end

        #5. Find by whatever is given
        if resp=="5"
            print "give me something : "
            input = gets.chomp
            system('cls')
            tryme topographer.graph, input
            puts "Press ENTER to go back to Menu"
            gets.chomp
        end
        if resp=="q"
            break
        end
    end
