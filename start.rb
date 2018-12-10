load "graph/vlan.rb"
load "graph/vrf.rb"
load "graph/vs.rb"
require "ipaddress"
load "graph/graph.rb"
require "rgl/adjacency"
require "rgl/dot"
load "poller.rb"

def print_vs_vrfs graph, vs_name
    puts "".ljust(70,"-")
    vs = graph.find vs_name
    vrfs = graph.get_vrfs_behind_vs vs
    vrfs.each do |vrf|
        puts "#{vrf.name}"
    end
    puts "".ljust(70,"-")
end

def print_vs_networks graph, vs_name
    vs = graph.find vs_name
    vlans = graph.get_vlans_behind_vs vs
    puts "".ljust(70,"-")
    vlans.each do |vlan|
        puts "#{vlan.id.to_s.ljust(5)} : #{vlan.net.address}/#{vlan.net.prefix}"
    end
    puts "".ljust(70,"-")
end

def print_vs_all graph, vs_name
    puts "\n\n"
    puts "========<<< #{vs_name} >>>".ljust(70,"=")
    puts "| VRF".ljust(25) + "|" + 
    " Vlan ID".ljust(10) + "|" +
    " Type".ljust(10) + "|" +
    " Network".ljust(21) + "|"
    
    vs = graph.find vs_name
    vrfs = graph.get_vrfs_behind_vs vs
    vlans_all = graph.get_vlans_behind_vs vs

    # print VRF connected vlans
    vrfs.each do |vrf|
        vlan_num = 0
        vlans = graph.get_vlans_behind_vrf vrf

        puts "|".ljust(69,".") + "|"
        puts "| #{vrf.name}".ljust(25) + 
        "|" + " #{vlans.first.id}".ljust(10) +  
        "|" + " #{vlans.first.type}".ljust(10) +
        "| #{vlans.first.net.address} / #{vlans.first.net.prefix}".ljust(22) + "|"
        vlans_all.delete(vlans.first)
        vlans.delete(vlans.first)
        vlans.each do |vlan|
            puts "| ".ljust(25) + 
            "|" + " #{vlan.id}".ljust(10) + 
            "|" + " #{vlan.type}".ljust(10)+
            "| #{vlan.net.address} / #{vlan.net.prefix}".ljust(22) + "|"
            vlans_all.delete(vlan)
        end
    end

    #print directly connected
    if vlans_all.count != 0
        puts "|".ljust(69,".") + "|"
        puts "| Direct ".ljust(25) + 
        "|" + " #{vlans_all.first.id}".ljust(10) +  
        "|" + " #{vlans_all.first.type}".ljust(10) +
        "| #{vlans_all.first.net.address} / #{vlans_all.first.net.prefix}".ljust(22) + "|"
        vlans_all.delete(vlans_all.first)
        vlans_all.each do |vlan|
            puts "| ".ljust(25) + 
            "|" + " #{vlan.id}".ljust(10) + 
            "|" + " #{vlan.type}".ljust(10)+
            "| #{vlan.net.address} / #{vlan.net.prefix}".ljust(22) + "|"
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
            vlan = graph.vlans.find_all{|vlan| vlan.name==input}.first
            if vlan.nil?
                vlan = graph.vlans.find_all{|vlan| vlan.include? input}.first
                if vlan.nil?
                    puts "nothing to do here :)"
                else
                    print_info_for_vlan graph, vlan
                end
            else
                print_info_for_vlan graph, vlan
            end
        else
            print_vs_all graph, vs.name
            # show attached networks to the VRF
        end
    else
        puts vrf.name
    end
end

def print_info_for_vlan graph, vlan

    if vlan.nil?
        puts "No VLANs with this ID"
    else
        puts "---------------------------------------------------"
        puts "VLAN:    #{vlan.id}"
        puts "Network: #{vlan.net.address} / #{vlan.net.prefix}"
        puts "Path out:"
        vs = graph.vses.find{|vs| vs.name == "PROD_PERIMETER_VS"}
        graph.shortest_path(vlan, vs).each do |v|
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

puts "Do you want to update the DB [y/n]"
resp = gets.chomp
if resp == "y"
    puts "passcode?: "
    passcode = gets.chomp
    poll_all "nikata", passcode, "vsx_util_interfaces"
end

graph = Graph.from_json File.read("json_graph")

#Manual Vertecies
    vs1 = graph.find "PROD_CORE_VS"
    vs2 = graph.find "MGMT_VS"
    vs3 = graph.find "PROD_GHO_VS"
    vs4 = graph.find "PROD_DCSERVICES_VS"
    vs5 = graph.find "PROD_PERIMETER_VS"
    r = graph.find "PROD_CORE_VIRTUAL-ROU"

    vs6 = graph.find "NONPROD_EBT_VS"
    vs7 = graph.find "NONPROD_CORE_VS"
    vs8 = graph.find "NONPROD_GHO_VS"
    vs9 = graph.find "PP_DC_SERVICES_VS"
    vs10 = graph.find "TS_DC_SERVICES_VS"
    vs11 = graph.find "NONPROD_DCSERVICES_VS"
    r2 = graph.find "NONPROD_CORE_VIRTUAL-"

    graph.connect r,vs1
    graph.connect r,vs2
    graph.connect r,vs3
    graph.connect r,vs4
    graph.connect r,vs5

    graph.connect r2,vs6
    graph.connect r2,vs7
    graph.connect r2,vs8
    graph.connect r2,vs9
    graph.connect r2,vs10
    graph.connect r2,vs11

#Menu 
    while true
        system('cls')
        puts "Pick an option"
        puts "1. Show VRFs behind VS"
        puts "2. Show VLANs behind VS"
        puts "3. Show EVERYTHING per VS"
        puts "4. Try my superior intelligence"
        puts "q. Exit"
        resp = gets.chomp
        #1. Show VRFs behind VS
        if resp=="1"
            print_vs_list graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_vrfs graph, graph.vses[fw.to_i-1].name
            puts "Press ENTER key to go back to Menu"
            gets.chomp
        end
        #2. Show VLANs behind VS
        if resp=="2"
            print_vs_list graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_networks graph, graph.vses[fw.to_i-1].name
            puts "Press ENTER key to go back to Menu"
            gets.chomp
        end
        #3. Show EVERYTHING per VS
        if resp=="3"
            print_vs_list graph.vses
            fw = gets.chomp
            system('cls')
            print_vs_all graph, graph.vses[fw.to_i-1].name
            puts "Press ENTER to go back to Menu"
            gets.chomp
        end
        #4. Find by whatever is given
        if resp=="4"
            print "give me something : "
            input = gets.chomp
            system('cls')
            tryme graph, input
            puts "Press ENTER to go back to Menu"
            gets.chomp
        end
        if resp=="q"
            break
        end
    end
