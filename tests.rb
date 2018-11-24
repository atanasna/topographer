load "graph/vlan.rb"
load "graph/vrf.rb"
load "graph/vs.rb"
require "ipaddress"
load "graph/graph.rb"
require "rgl/adjacency"
require "rgl/dot"
load "poller.rb"

graph = Graph.new

puts graph.methods
graph.load_from_db
new_graph = Graph.from_json graph.to_json


puts graph.vertices.count
puts new_graph.vertices.count
puts graph.edges.count
puts new_graph.edges.count