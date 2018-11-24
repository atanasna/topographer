require 'securerandom'
require 'json'

class Vertex
    attr_accessor :name, :graph
    attr_reader :vid

    def initialize name, vid=nil
        @name = name
        @graph = nil
        if vid.nil? or vid.empty?
            @vid = SecureRandom.hex
        else
            @vid = vid
        end
    end

    #HELPERS
    def connected? vertex
        if @graph.connected? self,vertex
            return true
        else
            return false
        end
    end
    def shortest_path vertex
        return @graph.shortest_path self,vertex
    end

    #JSON
    def to_json
        {'class' => self.class.name, 'vid' => @vid, 'name' => @name}.to_json
    end

    def self.from_json string
        data = JSON.load string
        self.new data['name'], data['vid']
    end
end