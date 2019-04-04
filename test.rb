require_relative "topographer.rb"
require "awesome_print"
require 'rgl/adjacency' 
require 'rgl/dot' 

topographer = Topographer.new "graph_export.json"
topographer.graph.write_to_graphic_file('jpg')

