load "graph/vlan.rb"
load "graph/vrf.rb"  
load "graph/vs.rb"
require 'rgl/adjacency'
require "rgl/dijkstra"
require "json"
load "graph/global-vars.rb"

class Graph < RGL::AdjacencyGraph
      attr_reader :weights

      def initialize
            super
            @weights = Hash.new
      end
      
      # POPULATORS
            def add_vertex vertex
                vertex.graph = self
                if find(vertex.name).nil?
                    super
                else
                    #error
                end
            end

            def load_from_db
                  nodes_lines = File.read($nodes_db).split(/\n+/)
                  edges_lines = File.read($edges_db).split(/\n+/)

                  nodes_lines.each do |line|
                        if line.match(/^vs/)
                              vs_name = line.match(/^vs : ([a-z,A-Z,_,\-,0-9]+)/i).captures.first
                              if find(vs_name).nil?
                                    self.add_vertex Vs.new vs_name
                              end
                        end
                        if line.match(/^vlan/)
                              vlan_id, vlan_ip = line.match(/^vlan : (\d+) : (\d+\.\d+\.\d+\.\d+\/\d+)/i).captures
                              if find(vlan_id.to_s).nil?
                                    self.add_vertex Vlan.new vlan_id.to_i, vlan_ip
                              end
                        end
                        if line.match(/^vrf/)
                              vrf_name = line.match(/^vrf : ([a-z,A-Z,_,\-,0-9]+)/i).captures.first
                              if find(vrf_name).nil?
                                    self.add_vertex Vrf.new vrf_name
                              end
                        end
                  end
                  edges_lines.each do |line|
                        v1_name, v2_name = line.match(/([a-z,A-Z,_,\-,0-9]+)\s:\s([a-z,A-Z,_,\-,0-9]+)/).captures
                        v1 = self.find v1_name
                        v2 = self.find v2_name
                        if not (v1.nil? and v2.nil?)
                              if not connected? v1,v2
                                    connect v1,v2
                              end
                        end
                  end
            end
      
      #JSON
            def to_json
                data = Hash.new
                data["vertices"] = self.vertices
                data["edges"] = Array.new
                @weights.each do |key,val|
                    edge = Hash.new
                    edge["source"] = key[0].vid
                    edge["target"] = key[1].vid
                    edge["weight"] = val
                    data["edges"].push edge
                end
                data.to_json
            end

            def self.from_json string
                graph = self.new 

                data = JSON.parse string
                data["vertices"].each do |vertex|
                    if vertex["class"]=="Vrf"
                        graph.add_vertex Vrf.new vertex["name"],vertex["vid"]
                    end
                    if vertex["class"]=="Vs"
                        graph.add_vertex Vs.new vertex["name"],vertex["vid"]
                    end
                    if vertex["class"]=="Vlan"
                        graph.add_vertex Vlan.new vertex["id"],vertex["ip"],vertex["vid"],vertex["type"],vertex["desc"]
                    end
                end
                data["edges"].each do |edge|
                    puts edge["source"].class.name
                    puts edge["target"]
                    puts edge["wight"]
                    v1 = graph.find(edge["source"])
                    v2 = graph.find(edge["target"])
                    graph.connect v1,v2, edge["weight"]
                end
                return graph
            end

      # HELPERS
            def connect v1,v2,weight=1
                  if not (v1.nil? and v2.nil?)
                        @weights.merge!([v1, v2] => weight)
                        self.add_edge v1,v2
                  end
            end

            def connected? v1,v2
                  if self.adjacent_vertices(v1).include? v2 
                        true
                  else
                        false
                  end
            end

            def shortest_path source,target
                  return self.dijkstra_shortest_path(@weights, source, target)
            end


      # SEARCHES
            def vlans
                return self.vertices.find_all{|vertex| vertex.class.name=="Vlan"}
            end

            def vrfs
                return self.vertices.find_all{|vertex| vertex.class.name=="Vrf"}
            end

            def vses
                return self.vertices.find_all{|vertex| vertex.class.name=="Vs"}
            end

            def find string
                vertex =  self.vertices.find{|vertex| vertex.name == string}
                if vertex.nil?
                    vertex =  self.vertices.find{|vertex| vertex.vid == string} 
                end
                return vertex
            end
            
            def get_vrfs_behind_vs vs
                  vrfs = Array.new
                  nodes = self.adjacent_vertices vs
                  nodes.each do |node|
                        if node.class.name == "Vlan"
                              probable_vrfs = self.adjacent_vertices node
                              probable_vrfs.each do |probable_vrf|
                                    if probable_vrf.class.name == "Vrf"
                                          vrfs.push probable_vrf
                                    end
                              end
                        end
                  end
                  return vrfs
            end
            
            def get_vlans_behind_vs vs
                  vlans = Array.new
                  nodes = self.adjacent_vertices vs
                  nodes.each do |node|
                        if node.class.name == "Vlan"
                              vlans.push node
                        end
                        if node.class.name == "Vrf"
                              vlans += self.get_vlans_behind_vrf node
                        end
                  end
                  return vlans
            end

            def get_vlans_behind_vrf vrf
                  vlans = Array.new
                  nodes = self.adjacent_vertices vrf
                  nodes.each do |node|
                        if node.class.name == "Vlan"
                              vlans.push node
                        end
                  end
                  return vlans
            end

            
end