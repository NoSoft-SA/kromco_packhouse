class ObjectBuilder  
  def build_hash_object(hash)
    attributes = hash.keys
 
   built_obj = "class HashObject
                    attr_accessor :"
#-------------------CREATING THE CLASS ATTRIBUTES---------------
    i=0
    attributes.each {|x| 
                if i != attributes.length-1
                   built_obj += x.to_s+", :"
                else
                  built_obj += x.to_s
                end
                
                i += 1}
#--------------------------------------------------------------------------------- 
#---------defining attribute_names attribute-------------
   built_obj += ",:attribute_names,:attributes"
#-------------------------------------
   built_obj += " end

               hash_result = HashObject.new \n"

#-------------------SETTING THE OBJECT'S ATTRIBUTES---------------
    i=0
    attributes.each {|x| 
      #built_obj += "  hash_result."+hash.index(hash[x]).to_s+" = '#{hash[x]}' \n"
      built_obj += "  hash_result."+x.to_s+" = '#{hash[x]}' \n"
        i += 1
    }
#---------------------------------------------------------------------------------
#--------SETTING THE OBJECT'S attribute_names ATTRIBUTE-----
    #built_obj += "  hash_result.attribute_names.fill('#{attributes}') \n"
    built_obj += " hash_result.attribute_names = Array.new \n"
    built_obj += " hash_result.attributes = {} \n"
    i=0
    attributes.each {|x| 
                   built_obj += " hash_result.attribute_names.push('" + x.to_s + "') \n"
                   built_obj += " hash_result.attributes.store('" + x.to_s + "','#{hash[x]}') \n"
            i += 1
    }
#-------------

    built_obj += "\n return hash_result"

         hash_result = eval(built_obj)
  end

  def build_arbitrary_object(class_name,hash)
    attributes = hash.keys

    built_obj = "class #{class_name}
                    attr_accessor :"
#-------------------CREATING THE CLASS ATTRIBUTES---------------
    i=0
    attributes.each {|x|
      if i != attributes.length-1
        built_obj += x.to_s+", :"
      else
        built_obj += x.to_s
      end

      i += 1}
#---------------------------------------------------------------------------------
#---------defining attribute_names attribute-------------
    built_obj += ",:attribute_names,:attributes"
#-------------------------------------
    built_obj += " end

               hash_result = #{class_name}.new \n"

#-------------------SETTING THE OBJECT'S ATTRIBUTES---------------
    i=0
    attributes.each {|x|
      #built_obj += "  hash_result."+hash.index(hash[x]).to_s+" = '#{hash[x]}' \n"
      built_obj += "  hash_result."+x.to_s+" = '#{hash[x]}' \n"
      i += 1
    }
#---------------------------------------------------------------------------------
#--------SETTING THE OBJECT'S attribute_names ATTRIBUTE-----
#built_obj += "  hash_result.attribute_names.fill('#{attributes}') \n"
    built_obj += " hash_result.attribute_names = Array.new \n"
    built_obj += " hash_result.attributes = {} \n"
    i=0
    attributes.each {|x|
      built_obj += " hash_result.attribute_names.push('" + x.to_s + "') \n"
      built_obj += " hash_result.attributes.store('" + x.to_s + "','#{hash[x]}') \n"
      i += 1
    }
#-------------

    built_obj += "\n return hash_result"

    hash_result = eval(built_obj)
  end
end
