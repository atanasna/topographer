load "graph/vlan.rb"
load "graph/vrf.rb"
load "graph/vs.rb"
require "ipaddress"
load "graph/graph.rb"
require "rgl/adjacency"
require "rgl/dot"
load "poller.rb"


 
#poll_all "nikata","86136123"
lines = File.read("json_graph").split(/\n+/)
graph = Graph.from_json lines.first

#Manual
vs1 = graph.find "PROD_CORE_VS"
vs2 = graph.find "MGMT_VS"
vs3 = graph.find "PROD_GHO_VS"
vs4 = graph.find "PROD_DCSERVICES_VS"
vs5 = graph.find "PROD_PERIMETER_VS"
r = graph.find "PROD_CORE_VIRTUAL-ROU"


vs6 = graph.find "NONPROD_EBT_VS"
vs7 = graph.find "NONPROD_CORE_VS"
vs8 = graph.find "NONPROD_GHO_VS"
vs9 = graph.find "PP_DC_SERVICES_VS"
vs10 = graph.find "TS_DC_SERVICES_VS"
vs11 = graph.find "NONPROD_DCSERVICES_VS"
r2 = graph.find "NONPROD_CORE_VIRTUAL-"

graph.connect r,vs1
graph.connect r,vs2
graph.connect r,vs3
graph.connect r,vs4
graph.connect r,vs5

graph.connect r2,vs6
graph.connect r2,vs7
graph.connect r2,vs8
graph.connect r2,vs9
graph.connect r2,vs10
graph.connect r2,vs11

neo4j = graph.to_neo4j

File.open("neo4j.json", "w+") do |f|
    f.puts(neo4j)
end
puts graph.vertices.count
puts graph.edges.count