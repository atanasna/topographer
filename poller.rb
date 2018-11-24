require "net/ssh"
load "graph/vlan.rb"
load "graph/vrf.rb"  
load "graph/vs.rb"
load "graph/graph.rb"
load "graph/global-vars.rb"


def poll_nexus_conf user, pass
    nodes_db_lines = Array.new
    edges_db_lines = Array.new
    conf = String.new

    Net::SSH.start('10.66.51.7', user, password: pass) do |session|
        conf = session.exec!("show run interface | inc \"interface |ip address|vrf\"")
        conf = conf.to_s.split("\n")
    end

    line_index = 0

    while true do
        line = conf[line_index]
        line_1 = conf[line_index+1]
        line_2 = conf[line_index+2]

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
                nodes_db_lines.push "vlan : #{vlan_id} : #{vlan_ip_string}"
            end

            if vrf_name != "none"
                nodes_db_lines.push "vrf : #{vrf_name}"
            end

            if vrf_name != "none" and vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
                edges_db_lines.push "#{vrf_name} : #{vlan_id}"
            end
        end

        line_index +=1
        if line_index == conf.count then break end
    end

    return nodes_db_lines, edges_db_lines
end

def poll_cp_conf filename
    objects_file = File.read(filename)
    objects_file_lines = objects_file.split(/\n+/)
    nodes_db_lines = Array.new
    edges_db_lines = Array.new

    bond_lines = objects_file_lines.find_all{|l| l[/bond/]}
    bond_lines.each do |line|
        vlan_id = 0
        vlan_ip_string = "255.255.255.255/32"
        vs_name = "none"

        vlan_id, vs_name, vlan_ip_string = line.match(/bond\d\.(\d+)\s+\|([a-z,A-Z,_,\-,0-9]+).+\|v4\s+(\d+\.\d+\.\d+\.\d+\/\d+)/i).captures
        vlan_id = vlan_id.to_i

        if vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
            nodes_db_lines.push "vlan : #{vlan_id} : #{vlan_ip_string}"
        end

        if vs_name != "none"
            nodes_db_lines.push "vs : #{vs_name}"
        end

        if vs_name != "none" and vlan_id != 0 and vlan_ip_string != "255.255.255.255/32"
            edges_db_lines.push "#{vs_name} : #{vlan_id}"
        end
    end

    return nodes_db_lines, edges_db_lines
end

def poll_all cisco_user, cisco_pass, cp_filename
    nodes_db_lines = Array.new
    edges_db_lines = Array.new

    out_nex = poll_nexus_conf cisco_user, cisco_pass
    out_cp = poll_cp_conf cp_filename

    nodes_db_lines = out_nex[0] + out_cp[0]
    edges_db_lines = out_nex[1] + out_cp[1]

    File.open($nodes_db, "w+") do |f|
        nodes_db_lines = nodes_db_lines.uniq
        nodes_db_lines.each { |element| f.puts(element) }
    end
    File.open($edges_db, "w+") do |f|
        edges_db_lines = edges_db_lines.uniq
        edges_db_lines.each { |element| f.puts(element) }
    end
end