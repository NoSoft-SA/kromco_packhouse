class PdtMethod
 attr_accessor :method_name, :disabled, :class_name, :menu_level, :program_name, :parent_class_name
 
 def initialize(method_name,disabled,class_name,menu_level,program_name, parent_class_name=nil)
   puts "___________________________ program_name = " + program_name.to_s
   puts "___________________________ parent_class_name = " + parent_class_name.to_s
    puts "___________________________ class_name = " + class_name.to_s

   @method_name = method_name
   @disabled = disabled
   @class_name = class_name
   @menu_level = menu_level
   @program_name = program_name
   @parent_class_name = parent_class_name
 end
 
end