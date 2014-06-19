
class ChildModels
  attr_accessor :child_models_array
  
  def initialize(model_name)
    @model_name = Inflector.singularize(model_name)
    @child_models_array = Array.new
    get_child_models
  end
  
  def get_child_models
    begin
      file_path = "app/models/" + @model_name.to_s + ".rb"
      file = File.open(file_path)
      file.each do |line|
        if (line.to_s.index("has_many")!=nil || line.to_s.index("has_one")!=nil || line.to_s.index("has_and_belongs_to_many")!=nil)
          relationship_hash = {}
          relationship_conditions = line.split(",")
          #------getting tablename ---
          table = relationship_conditions.shift.split(":")[1]
          relationship_hash.store(:table,table)
          #------getting tablename ---
          relationship_conditions.each do |condition|

              key_val = condition.split("=>")
              key = key_val[0]
              val = key_val[1]
              relationship_hash.store(eval(key),eval(val)) if ! key.index(":dependent")


          end

#          puts "RELATIONSHIP : #{relationship_hash.map{|key,value| "[" + key.to_s + "=>" + value.to_s + "],"}.to_s + "}"}"
#          puts "Proffessor : #{relationship_hash[:class_name]}"

#          @child_models_array.push(table)
          @child_models_array.push(relationship_hash)
        end
      end
    rescue
      raise $!
    end
  end
  
end