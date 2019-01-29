require_relative "vertex.rb"

class Interface < Vertex
    attr_reader :address, :belongs_to, :connected_to, :type

    def initialize name, address, vid=nil
        super(name, vid)
        @address = IPAddress address
    end
end