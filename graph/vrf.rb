load "graph/vlan.rb"
load "graph/vertex.rb"

class Vrf < Vertex
    attr_reader :name, :vlans
    attr_accessor :vs

    def initialize name
        super(name)
    end
end