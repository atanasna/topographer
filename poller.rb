require "net/ssh"
require_relative "graph/network.rb"
require_relative "graph/vrf.rb"  
require_relative "graph/vs.rb"
require_relative "graph/graph.rb"
require_relative "poller/ConfigPoller.rb"
require_relative "poller/ConfigParser.rb"
require_relative "topographer.rb"
require "awesome_print"

topo = Topographer.new

#ap "---- Cisco Nexus ----"
#nexus_conf = ConfigPoller.poll_cisco_nexus "svcT_locqualys", "Qu@lys$(ann3r", "127.0.0.1", 10037
#ConfigParser.parse_cisco_nexus nexus_conf, topo.graph
#
#ap "---- Checkpoint ProdVSX ----"
#vsx_conf = ConfigPoller.poll_checkpoint_vsx "admin", "W23ht@=", "127.0.0.1", 10131
#ConfigParser.parse_checkpoint_vsx vsx_conf, topo.graph
#
#ap "---- Checkpoint NonProdVSX ----"
#vsx_conf = ConfigPoller.poll_checkpoint_vsx "admin", "W23ht@=", "127.0.0.1", 10136
#ConfigParser.parse_checkpoint_vsx vsx_conf, topo.graph
#
#ap "---- Checkpoint Perimeter ----"
#cp_conf = ConfigPoller.poll_checkpoint_gw "admin", "W23ht@=", "127.0.0.1", 60038
#ConfigParser.parse_checkpoint_gw cp_conf, topo.graph

ap "---- Juniper 3WIG ----"
jun_conf = ConfigPoller.poll_juniper_gw "tufin", "Welcome01", "10.67.1.17", 22
ap jun_conf
#ConfigParser.parse_juniper_gw jun_conf, topo.graph

#topo.to_json "graph_export3.json"