require_relative "vertex.rb"

class Interface < Vertex
    attr_reader :address, :belongs_to, :connected_to, :type

    def initialize name, address, vid=nil
        super(name, vid)
        @address = IPAddress address
    end

    def to_json(options = {})
        js = JSON.parse super
        js['address'] = @address.address.to_s + "/" + @address.prefix.to_s
        return js.to_json
    end

    def self.from_json string
        data = JSON.load string
        self.new data['name'], data['address'], data['vid']
    end
end