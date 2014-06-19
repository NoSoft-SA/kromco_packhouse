
require 'rexml/document'

class XmlParser
  include REXML
  
  attr_accessor :root, :doc, :first_level_array, :second_level_array, :third_level_array, :fourth_level_array
  
  def initialize(xmlFile)
    @input = File.new(xmlFile)
    @doc = Document.new(@input)
    @root = @doc.root
    
    #Arrays initialization
    @first_level_array = Array.new
    @second_level_array = Array.new
    @third_level_array = Array.new
    @fourth_level_array = Array.new
    
    elements_extractor(@root)
  end
  
  def elements_extractor(root)
    root.each_element('//Menu') do |node|
      type = node.attributes["Type"]
      #=============================================
      if (type.to_s.length == 3)
        if type.to_s.index("0")!=nil # First Level Menu
          name = node.attributes["Name"]
          nodeType = node.attributes["NodeType"]
          hash = {type.to_s=>{:name=>name.to_s, :node_type=>nodeType.to_s}}
          @first_level_array.push(hash)
        else # Second Level Menu
          first_chr = type.to_s[0,1]
          parent = ""
          @first_level_array.each do |first|
            first.each do |k,v|
              if k.to_s.index(first_chr)!=nil
                parent = k.to_s
              end
            end
          end
          second_level_menu = parent.to_s + "," + type.to_s
          name = node.attributes["Name"]
          nodeType = node.attributes["NodeType"]
          hash = {second_level_menu.to_s=>{:name=>name.to_s, :node_type=>nodeType.to_s}}
          @second_level_array.push(hash)
        end
      elsif (type.to_s.length==5) # Third Level Menu
        type_part = type.to_s[0,3]
        parent = ""
        @second_level_array.each do |sec|
          sec.each do |k,v|
            k_a = k.to_s.split(",")
            t = k_a[1]
            p = k_a[0]
            if t.to_s == type_part.to_s
              parent = p.to_s + "," + t.to_s
            end
          end
        end
        third_lev_menu = parent.to_s + "," + type.to_s
        name = node.attributes["Name"]
        nodeType = node.attributes["NodeType"]
        hash = {third_lev_menu.to_s=>{:name=>name.to_s, :node_type=>nodeType.to_s}}
        @third_level_array.push(hash)
      elsif (type.to_s.length==7) # Fourth Level Menu
        type_part = type.to_s[0,5]
        parent = ""
        @third_level_array.each do |third|
          third.each do |k,v|
            k_a = k.to_s.split(",")
            t = k_a[2]
            m = k_a[1]
            p = k_a[0]
            if t.to_s ==type_part.to_s
              parent = p.to_s + "," + m.to_s + "," + t.to_s
            end
          end
        end
        fourth_lev_menu = parent.to_s + "," + type.to_s
        name = node.attributes["Name"]
        nodeType = node.attributes["NodeType"]
        hash = {fourth_lev_menu.to_s=>{:name=>name.to_s, :node_type=>nodeType.to_s}}
        @fourth_level_array.push(hash)
      end
      #=============================================
    end
  end

end