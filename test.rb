require_relative "poller/ConfigurationPoller.rb"
require_relative "poller/ConfigurationParser.rb"
require_relative "topographer.rb"
require "awesome_print"

topo = Topographer.new "json_graph"
topo2 = Topographer.new "json_graph2"


ap topo.graph.vertices.size
ap topo.graph.edges.size
ap topo2.graph.vertices.size
ap topo2.graph.edges.size
ap "KURO"


#ap "---- Checkpoint GW ----"
#ap "---- Checkpoint VSX ----"
#vsx_conf = ConfigurationPoller.get_checkpoint_vsx_config "127.0.0.1","admin","W23ht@="
#ap vsx_conf
