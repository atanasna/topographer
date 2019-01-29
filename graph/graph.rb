require_relative "network.rb"
require_relative "vrf.rb"  
require_relative "vs.rb"
require 'rgl/adjacency'
require "rgl/dijkstra"
require "json"

class Graph < RGL::AdjacencyGraph
    attr_reader :weights

    def initialize
        super
        @weights = Hash.new
    end

    # GETTERS
        def interfaces
            return self.vertices.find_all{|vertex| vertex.class.name=="Interface"}
        end

        def networks
            return self.vertices.find_all{|vertex| vertex.class.name=="Network"}
        end

        def vrfs
            return self.vertices.find_all{|vertex| vertex.class.name=="Vrf"}
        end

        def vses
            return self.vertices.find_all{|vertex| vertex.class.name=="Vs"}
        end

        def find input
            vertex = self.vertices.find{|vertex| vertex.name == input.to_s}
            if vertex.nil?
                vertex =  self.vertices.find{|vertex| vertex.vid == input.to_s} 
            end
            return vertex
        end
        
        def get_vrfs_behind_vs vs
            vrfs = Array.new
            nodes = self.adjacent_vertices vs
            nodes.each do |node|
                if node.class.name == "Network"
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
        
        def get_networks_behind_vs vs
            networks = Array.new
            nodes = self.adjacent_vertices vs
            vrfs = get_vrfs_behind_vs vs

            nodes.each do |node|
                if node.class.name == "Network"
                      networks.push node
                end
            end

            vrfs.each do |vrf|
                networks += self.get_networks_behind_vrf vrf
            end
            
            return networks.uniq
        end

        def get_networks_behind_vrf vrf
              networks = Array.new
              nodes = self.adjacent_vertices vrf
              nodes.each do |node|
                    if node.class.name == "Network"
                          networks.push node
                    end
              end
              return networks
        end      

    # POPULATORS
        def add_vertex vertex
            vertex.graph = self
            if find(vertex.vid).nil? and find(vertex.name).nil?
                super
            else
                #error
            end
        end

    # EXPORTERS
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
            return data.to_json
            #pretty export to json
            #js = JSON.pretty_generate( JSON.parse(graph.to_json) ).split('\n')
            #File.open("json_graph_pp", "w+") do |f|
            #    js.each { |element| f.puts(element) }
            #end
        end

        def self.from_json input
            graph = self.new 

            data = JSON.parse input
            data["vertices"].each do |vertex|
                if vertex["class"]=="Vrf"
                    graph.add_vertex Vrf.new vertex["name"],vertex["vid"]
                end
                if vertex["class"]=="Vs"
                    graph.add_vertex Vs.new vertex["name"],vertex["vid"]
                end
                if vertex["class"]=="Network"
                    graph.add_vertex Network.new vertex['address'], vertex['vlan'], vertex["vid"]
                end
            end
            data["edges"].each do |edge|
                v1 = graph.find(edge["source"])
                v2 = graph.find(edge["target"])
                graph.connect v1,v2, edge["weight"]
            end
            return graph
        end

        def to_csv
            edge_id = 0
            vertices_db_lines = Array.new
            edges_db_lines = Array.new
            vertices_db_lines.push "Id,Label,Timeset,Class"
            edges_db_lines.push "Source,Target,Type,Id,Label,timeset,Weight"

            self.vertices.each do |vertex|
                vertices_db_lines.push "#{vertex.vid},#{vertex.name},,#{vertex.class.name}"
            end

            @weights.each do |key,val|
                edges_db_lines.push "#{key[0].vid},#{key[1].vid},Undirected,#{edge_id},,,#{val}"
                edge_id+=1
            end

            return vertices_db_lines, edges_db_lines
            #File.open("vertices.csv", "w+") do |f|
            #    vertices_db_lines.each { |element| f.puts(element) }
            #end
            #File.open("edges.csv", "w+") do |f|
            #    edges_db_lines.each { |element| f.puts(element) }
            #end
        end

    # OPERATORS
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
end