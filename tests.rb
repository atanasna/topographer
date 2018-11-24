load "graph/vlan.rb"
load "graph/graph.rb"
load "graph/vrf.rb"
load "graph/vertex.rb"

v1 = Vertex.new "nama1"
v2 = Vertex.new "nama2"
v3 = Vertex.new "nama3"

g = Graph.new

g.add_vertex v1
g.add_vertex v2
g.add_vertex v3

g.connect v1,v2
g.connect v2,v3

puts g.methods

