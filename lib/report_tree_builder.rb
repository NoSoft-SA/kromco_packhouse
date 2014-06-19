class ReportTreeBuilder

#----------------------------------------------------------------
# This method constructs an array tree structure of yaml files read
# from a file structure.You pass in the path to the root file,and 
# it will read its contents into a tree structure
#----------------------------------------------------------------
@@key = 0
 def build_tree(root)
  arra = Dir.new(root)
  tree_struct = Array.new
#__________________________________________
  branch_name_array = root.split("/")
  branch_name = branch_name_array[branch_name_array.length - 1]
  branch = Hash.new
  branch[@@key.to_s] = branch_name
  @@key += 1
  tree_struct[0] = branch#branch_name
#___________________________________________
     arra.each do |x|
       if File.stat( root + "/" + x ).directory? == false
         extension = x.split(".")
         if extension[extension.length - 1] == "yml" #Show .YML files only
           puts "We have a yml  == " + x
          #____
           leaf = Hash.new
           leaf[@@key.to_s] = root + "/" + x
           @@key += 1
          #____
          tree_struct.push(leaf)
         end
         
            if Dir.entries(root).index(x) == Dir.entries(root).length-1
              puts "I quit"
                return tree_struct
            end
         
       else
          #____________
             if x == "." 
             elsif  x == ".." 
             else
 puts "                  I enter = " + root 
                root = root + "/" + x
                tree_struct.push(build_tree(root))
                                       file_path = root.split("/")
                     w=0
                     root = ""
                     
                     (file_path.length-1).times do
                       root += file_path[w] + "/"
                       w+=1
                     end
                    root = root.chop
  puts "                After I return = " + root
            end
          #____________
       end
     
   end
      arra.close
    return tree_struct
 end

 
 def display_tree(tree_array,root_branch_node)
 z=1
    (tree_array.length-1).times do
       if  tree_array[z].class.name == "Array"

          id = tree_array[z][0].keys[0]
          branch_node = root_branch_node.add_child(tree_array[z][0].values[0],"branch",id)
       
          display_tree( tree_array[z],branch_node)

      else
          #_________________________________
          # id = tree_array[z].to_s.chop #PROBLEM : might not be unique in the tree
          #_________________________________
          id = tree_array[z].keys[0]
          leaf_value = tree_array[z].values[0].split("/")
          caption = leaf_value[leaf_value.length - 1]
          puts "URL = " + caption
          leaf_node = root_branch_node.add_child(caption,"leaf",id)

        end 
   z+=1
   end
   
 end
 
@@url = ""
 def get_file_location(tree_structure,file_id)

   z=1
    (tree_structure.length-1).times do
    
      if tree_structure[z].class.name == "Array"
           if tree_structure[z].length > 1
       
            get_file_location(tree_structure[z],file_id)
           else
            
           end
         else
            if tree_structure[z].keys[0] == file_id
            
              puts "Found a match on :::: (" + tree_structure[z].keys[0] +" , " + tree_structure[z].values[0] + ")   " 
              @@url = tree_structure[z].values[0]
            else
             
            end
         end
       
   z+=1   
    end
    return @@url
 end
  
end