load "graph/vrf.rb"
load "graph/vertex.rb"

class Vs < Vertex
    attr_reader :name, :vrfs, :vlans, :edges

    def initialize name
        super(name)
    end
end