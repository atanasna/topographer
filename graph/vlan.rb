require "ipaddress"
load "graph/vertex.rb"

class Vlan < Vertex
    attr_reader :net, :desc, :type

    def initialize id, ip, vid=nil, type=nil, desc=String.new
        super(id.to_s, vid)
        @id = id
        @net = (IPAddress ip).network
        @desc = desc
        if @type == nil
            if @net.prefix < 28 then @type = "H" end
            if @net.prefix == 28 then @type = "HT?" end
            if @net.prefix > 28 then @type = "T" end
        end
    end

    def include? ip
        begin
            ip = IPAddress ip
            if @net.include? ip
                return true
            else
                return false
            end
        rescue
            return nil
        end
    end

    def id=id
        @id = id
        @name = id.to_s
    end

    def id
        return @id
    end

    #JSON
    def to_json(options = {})
        js = JSON.parse super
        js['type'] = @type
        js['id'] = @id
        js['ip'] = @net.address.to_s + "/" + @net.prefix.to_s
        js['desc'] = @desc
        js.to_json
    end

    def self.from_json string
        data = JSON.load string
        self.new data['name'], data['ip'], data['vid'], data['type'], data['desc']
    end
end