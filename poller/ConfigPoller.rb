require "net/ssh" 
require "awesome_print"
require_relative "../config/globals.rb"

class ConfigPoller

    #Checkpoints
        def self.poll_checkpoint_gw user, password, address, port=22
            configuration = nil

            Net::SSH.start(address, user, password: password, port:port) do |session|
                configuration = session.exec!("clish -c 'show configuration'").to_s.split("\n")
            end

            return configuration
        end

        #[Expert@WOK-FW1:0]# ifconfig | grep 'inet' -B 1 | grep -v '\-\-' | awk 'NR!=1{print x''$0}{x=$0}' | grep -e '^\w' | sed -e 's/ \+/ /g'
        #Mgmt Link encap:Ethernet HWaddr 00:1C:7F:33:E0:E3 inet addr:10.66.51.131 Bcast:10.66.51.255 Mask:255.255.255.128
        #eth2-04 Link encap:Ethernet HWaddr 00:1C:7F:61:F1:29 inet addr:192.168.30.1 Bcast:192.168.30.255 Mask:255.255.255.0
        #lo Link encap:Local Loopback inet addr:127.0.0.1 Mask:255.0.0.0

        def self.poll_checkpoint_vsx user, password, address, port=22
            configuration = Array.new

            Net::SSH.start(address, user, password: password, port:port) do |session|
                vses = Hash.new
                output = session.exec!("clish -c 'show virtual-system all' | sed 1,2d").to_s.split("\n")

                #vses.map!{|line| line.strip.sub(/\s+/," ").split(" ").pop}
                output.each do |line|
                    line_args = line.strip.sub(/\s+/," ").split(" ")
                    vses[line_args[0].to_i] = line_args[1]
                end
                vses[0] = session.exec!("hostname").to_s

                vses.each do |vs_id,vs_name|
                    configuration.push "######## #{vs_name}"
                    configuration.push "#### Interfaces"
                    interface_list = session.exec!("vsenv #{vs_id}; ifconfig | grep Link; vsenv 0").to_s.split("\n")
                    interface_list.pop
                    interface_list.shift
                    interface_list.each do |interface_list_entry|
                        if interface_list_entry.match(/^lo/) then next end
                        interface_name = interface_list_entry.match(/(.+)\s+Link/i).captures.first
                        interface_config = session.exec!("clish -c 'show interface #{interface_name}'").to_s.split("\n")
                        configuration.push "#{interface_name} - #{interface_config.find{|line| line.match(/ipv4-address/)}}".gsub!(/\s+/," ")
                    end
                end
                ap configuration
            end

            return configuration
        end

    #Cisco
        def self.poll_cisco_generic user, password, address, port=22
            configuration = nil

            Net::SSH.start(address, user, password: password, port: port) do |session|
                configuration = session.exec!("show run").to_s.split("\n")
            end

            return configuration
        end

        def self.poll_cisco_nexus user, password, address, port=22
            configuration = nil

            Net::SSH.start(address, user, password: password, port: port) do |session|
                configuration = session.exec!("show run vdc-all").to_s.split("\n")
            end

            return configuration
        end

    #Juniper
        def self.poll_juniper_gw user, password, address, port=22
            configuration = "alaabala"

            Net::SSH.start(address, user, password: password, port:port) do |session|
                configuration = session.exec!("get hostname")
                puts configuration
            end

            return configuration
        end
end