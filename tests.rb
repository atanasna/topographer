load "graph/vlan.rb"
load "graph/vrf.rb"
load "graph/vs.rb"
require "ipaddress"
load "graph/graph.rb"
require "rgl/adjacency"
require "rgl/dot"
load "poller.rb"

graph = Graph.new

#Manual nodes


#puts graph.methods
#graph.load_from_db
#
#vs1 = graph.find "PROD_CORE_VS"
#vs2 = graph.find "MGMT_VS"
#vs3 = graph.find "PROD_GHO_VS"
#vs4 = graph.find "PROD_DCSERVICES_VS"
#vs5 = graph.find "PROD_PERIMETER_VS"
#r = graph.find "PROD_CORE_VIRTUAL-ROU"
#
#graph.connect r,vs1
#graph.connect r,vs2
#graph.connect r,vs3
#graph.connect r,vs4
#graph.connect r,vs5
#graph.to_csv
#
poll_all "a","b","vsx_util_interfaces"
lines = File.read("json_graph").split(/\n+/)
graph = Graph.from_json lines.first

puts graph.vertices.count
puts graph.edges.count