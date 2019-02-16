require 'securerandom'
require 'json'

class Vertex
    attr_accessor :name, :graph
    attr_reader :vid

    def initialize name=nil, vid=nil
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
        return @graph.connected? self,vertex
    end

    def shortest_path vertex
        return @graph.shortest_path self,vertex
    end

    #JSON
        def to_json(options = {})
            return {'class' => self.class.name, 'vid' => @vid, 'name' => @name}.to_json
        end

        def self.from_json string
            data = JSON.load string
            self.new data['name'], data['vid']
        end

    # OVERWRITES
        def to_s
            return "#{@name}(#{self.class.name})"
        end
end