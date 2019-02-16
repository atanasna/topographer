require_relative "poller/ConfigPoller.rb"
require_relative "poller/ConfigParser.rb"
require_relative "topographer.rb"
require "awesome_print"

topo = Topographer.new

#ap "---- Checkpoint GW ----"
ap "---- Checkpoint ProdVSX ----"
#vsx_conf = ConfigurationPoller.poll_checkpoint_vsx "127.0.0.1","svcT_locqualys","Qu@lys$(ann3r"
vsx_conf = ConfigPoller.poll_checkpoint_vsx "admin", "W23ht@=", "127.0.0.1", 6022
ConfigParser.parse_checkpoint_vsx vsx_conf, topo.graph

ap "---- Checkpoint NonProdVSX ----"
#vsx_conf = ConfigurationPoller.poll_checkpoint_vsx "127.0.0.1","svcT_locqualys","Qu@lys$(ann3r"
vsx_conf = ConfigPoller.poll_checkpoint_vsx "admin", "W23ht@=", "127.0.0.1", 7022
ConfigParser.parse_checkpoint_vsx vsx_conf, topo.graph

ap "---- Cisco Nexus ----"
nexus_conf = ConfigPoller.poll_cisco_nexus "svcT_locqualys", "Qu@lys$(ann3r", "127.0.0.1", 5022
ConfigParser.parse_cisco_nexus nexus_conf, topo.graph

topo.to_json "new_json_graph2"
