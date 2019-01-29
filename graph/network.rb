require "ipaddress"
require_relative "vertex.rb"

class Network < Vertex
    attr_reader :address, :vlan, :desc, :type

    def initialize address, vlan_id = nil, vid=nil
        @vlan = vlan_id
        @address = (IPAddress address).network
        super("#{@address.to_s}/#{@address.prefix.to_s}", vid)
        @desc = desc
    end

    def include? ip
        begin
            ip = IPAddress ip
            if @address.include? ip
                return true
            else
                return false
            end
        rescue
            return nil
        end
    end

    def address=address
        @address = (IPAddress address).network
        @name = "#{address.to_s}/#{address.prefix.to_s}"
    end

    def address
        return @address
    end

    #JSON
        def to_json(options = {})
            js = JSON.parse super
            js['vlan'] = @vlan
            js['address'] = @address.address.to_s + "/" + @address.prefix.to_s
            
            return js.to_json
        end

        def self.from_json string
            data = JSON.load string
            self.new data['address'], data['vlan'], data['vid']
        end
end