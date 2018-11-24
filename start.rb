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


def print_info_by_ip seed, input
    vlans = seed.vlans.find_all{|vlan| vlan.include? input}
    if vlans.empty?
        puts "No VLANs contain this ip address"
    else
        vlans.each do |vlan|
            puts "#{vlan.id} - #{vlan.net.address} / #{vlan.net.prefix} -> #{vlan.vrf.name} -> #{vlan.vrf.vs.name}"
        end
    end
end

def print_info_by_vlan seed, input
    vlan=nil
    vlan = seed.vlans.find{|vlan| vlan.id == input.to_i}
    if vlan.nil?
        puts "No VLANs with this ID"
    else
        puts "#{vlan.id} - #{vlan.net.address} / #{vlan.net.prefix} -> #{vlan.vrf.name} -> #{vlan.vrf.vs.name}"
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




new_graph = Graph.new

puts "Do you want to update the DB [y/n]"
resp = gets.chomp
if resp == "y"
    puts "passcode?: "
    passcode = gets.chomp
    poll_all "nikata", passcode, "vsx_util_interfaces"
end
new_graph.load_from_db
new_graph.load_from_db
graph = Graph.from_json new_graph.to_json

#graph.write_to_graphic_file 'jpg'
while true
    puts "Pick an option"
    puts "1. Show VRFs behind VS"
    puts "2. Show VLANs behind VS"
    puts "3. Show EVERYTHING per VS"
    puts "4. Find by IP"
    puts "5. Find by Vlan"
    puts "q. Exit"
    resp = gets.chomp
    if resp=="1"
        print_vs_list graph.vses
        fw = gets.chomp
        system("clear")
        print_vs_vrfs graph, graph.vses[fw.to_i-1].name
        puts "Press ENTER key to go back to Menu"
        gets.chomp
    end
    if resp=="2"
        print_vs_list graph.vses
        fw = gets.chomp
        system("clear")
        print_vs_networks graph, graph.vses[fw.to_i-1].name
        puts "Press ENTER key to go back to Menu"
        gets.chomp
    end
    if resp=="3"
        print_vs_list graph.vses
        fw = gets.chomp
        system("clear")
        print_vs_all graph, graph.vses[fw.to_i-1].name
        puts "Press ENTER to go back to Menu"
        gets.chomp
    end
    if resp=="4"
        puts "IP?: "
        input = gets.chomp
        #print_info_by_ip s, input
        system("clear")
        puts "Press ENTER to go back to Menu"
        gets.chomp
    end
    if resp=="5"
        puts "VLAN?: "
        input = gets.chomp
        #print_info_by_vlan s, input
        system("clear")
        puts "Press ENTER to go back to Menu"
        gets.chomp
    end

    if resp=="6"
        puts "name:"
        input = gets.chomp
        node = graph.vrfs.find{|vrf| vrf.name == input}
        if node.nil?
            node = graph.vses.find{|vs| vs.name == input}
        end
        if not node.nil?
            pp graph.adjacent_vertices node
        end



        #print_info_by_vlan s, input
        system("clear")
        puts "Press ENTER to go back to Menu"
        gets.chomp
    end
    if resp=="q"
        break
    end
end
