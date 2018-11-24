require "ipaddress"
load "graph/vertex.rb"

class Vlan < Vertex
    attr_reader :id, :net, :description, :type
    attr_accessor :vrf

    def initialize id, ip, type=nil, description="null"
        super(id.to_s)
        @id = id
        @net = (IPAddress ip).network
        @description = description
        if @type == nil
            if @net.prefix < 28 then @type = "H" end
            if @net.prefix == 28 then @type = "HT?" end
            if @net.prefix > 28 then @type = "T" end
        end
    end

    def include? ip
        ip = IPAddress ip
        if @net.include? ip
            return true
        else
            return false
        end
    end
end