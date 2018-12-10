require "net/ssh"
load "graph/vlan.rb"
load "graph/vrf.rb"  
load "graph/vs.rb"
load "graph/graph.rb"

def poll_nexus_conf user, pass, ip, graph
    nodes_db_lines = Array.new
    edges_db_lines = Array.new
    conf = String.new

    Net::SSH.start(ip, user, password: pass) do |session|
        conf = session.exec!("show run interface | inc \"interface |ip address|vrf\"")
        conf = conf.to_s.split("\n")
    end

    line_index = 0

    while true do
        line = conf[line_index]
        line_1 = conf[line_index+1]
        line_2 = conf[line_index+2]

        vlan = nil
        vrf = nil

        vlan_id = 0
        vlan_ip_string = "255.255.255.255/32"
        vrf_name = "none"
        if line.match(/interface port-channel/) then break end
        if line.match(/interface Ethernet/) then break end

        if line.match(/interface Vlan/)
            vlan_id = line.match(/interface Vlan(\d+)/i).captures.first.to_i
            if line_1.match(/vrf member/)
                vrf_name = line_1.match(/vrf member ([a-z,A-Z,_,\-,0-9]+)/i).captures.first
            end
            if line_2.match(/ip address/)
                vlan_ip_string = line_2.match(/ip address (.+)/i).captures.first
            end


            if vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
                #nodes_db_lines.push "vlan : #{vlan_id} : #{vlan_ip_string}"
                graph.add_vertex Vlan.new vlan_id.to_i, vlan_ip_string
            end

            if vrf_name != "none"
                #nodes_db_lines.push "vrf : #{vrf_name}"
                graph.add_vertex Vrf.new vrf_name
            end

            if vrf_name != "none" and vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
                #edges_db_lines.push "#{vrf_name} : #{vlan_id}"
                vrf = graph.find vlan_id.to_s
                vlan = graph.find vrf_name
                graph.connect vrf,vlan
            end
        end

        line_index +=1
        if line_index == conf.count then break end
    end

    #return nodes_db_lines, edges_db_lines
    return graph
end

def poll_cp_conf filename, graph
    objects_file = File.read(filename)
    objects_file_lines = objects_file.split(/\n+/)
    nodes_db_lines = Array.new
    edges_db_lines = Array.new

    bond_lines = objects_file_lines.find_all{|l| l[/V bond/]}
    bond_lines.each do |line|
        vlan_id = 0
        vlan_ip_string = "255.255.255.255/32"
        vs_name = "none"

        vlan = nil
        vs = nil

        vlan_id, vs_name, vlan_ip_string = line.match(/bond\d\.(\d+)\s+\|([a-z,A-Z,_,\-,0-9]+).+\|v4\s+(\d+\.\d+\.\d+\.\d+\/\d+)/i).captures
        vlan_id = vlan_id.to_i

        if vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
            #nodes_db_lines.push "vlan : #{vlan_id} : #{vlan_ip_string}"
            vlan = Vlan.new vlan_id.to_i, vlan_ip_string
            graph.add_vertex vlan
        end

        if vs_name != "none"
            #nodes_db_lines.push "vs : #{vs_name}"
            vs = Vs.new vs_name
            graph.add_vertex vs
        end

        if vs_name != "none" and vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
            vs = graph.find vs_name
            vlan = graph.find vlan_id
            graph.connect vs, vlan
        end
    end

    #return nodes_db_lines, edges_db_lines
    return graph
end

def poll_all cisco_user, cisco_pass

    graph = Graph.new

    nodes_db_lines = Array.new
    edges_db_lines = Array.new

    graph = poll_nexus_conf '10.66.51.7', cisco_user, cisco_pass, graph
    graph = poll_cp_conf "vsx_util_interfaces_prod", graph
    graph = poll_cp_conf "vsx_util_interfaces_nonprod", graph
    #nodes_db_lines = out_nex[0] + out_cp[0]
    #edges_db_lines = out_nex[1] + out_cp[1]

    File.open("json_graph", "w+") do |f|
        json = graph.to_json
        f.puts(json)
    end
end