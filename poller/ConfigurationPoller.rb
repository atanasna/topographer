require "net/ssh" 
require "awesome_print"
require_relative "../config/globals.rb"

class ConfigurationPoller

    def self.get_checkpoint_gw_config address, user, password
        configuration = nil

        Net::SSH.start(address, user, password: password) do |session|
            configuration = session.exec!("show configuration").to_s.split("\n")
        end

        return configuration
    end

    #[Expert@WOK-FW1:0]# ifconfig | grep 'inet' -B 1 | grep -v '\-\-' | awk 'NR!=1{print x''$0}{x=$0}' | grep -e '^\w' | sed -e 's/ \+/ /g'
    #Mgmt Link encap:Ethernet HWaddr 00:1C:7F:33:E0:E3 inet addr:10.66.51.131 Bcast:10.66.51.255 Mask:255.255.255.128
    #eth2-04 Link encap:Ethernet HWaddr 00:1C:7F:61:F1:29 inet addr:192.168.30.1 Bcast:192.168.30.255 Mask:255.255.255.0
    #lo Link encap:Local Loopback inet addr:127.0.0.1 Mask:255.0.0.0

    def self.get_checkpoint_vsx_config address, user, password
        configuration = Array.new

        Net::SSH.start(address, user, password: password, port:10022) do |session|
            vses = session.exec!("clish -c 'show virtual-system all' | sed 1,2d").to_s.split("\n")
            vses.map!{|line| line.strip.sub(/\s+/," ").split(" ").pop}
            vses.size.times do |vs_id|
                configuration.push "######## #{vses[vs_id]}"
                configuration.push "#### Interfaces"
                #configuration += session.exec!("vsenv #{vs_id}; ifconfig -v | grep 'inet' -B 1 | grep -v '\\-\\-' | awk 'NR!=1{print x''$0}{x=$0}' | grep -e '^\\w' | sed -e 's/ \\+/ /g'; vsenv 0;").to_s.split("\n")
                configuration += session.exec!("vsenv #{vs_id}; echo \"ifconfig -v | grep 'inet' -B 1 | grep -v '\\-\\-'\" > /tmp/get_ifconfig.sh; /bin/bash /tmp/get_ifconfig.sh; vsenv 0;").to_s.split("\n")
            end
        end

        return configuration
    end


    def self.get_cisco_config address, user, password
        configuration = nil

        Net::SSH.start(address, user, password: password) do |session|
            configuration = session.exec!("show run").to_s.split("\n")
        end

        return configuration
    end

    def self.get_cisco_nexus_config address, user, password
        configuration = nil

        Net::SSH.start(address, user, password: password) do |session|
            configuration = session.exec!("show run vdc-all").to_s.split("\n")
        end

        return configuration
    end
end