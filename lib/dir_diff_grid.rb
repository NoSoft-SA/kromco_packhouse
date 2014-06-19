  require 'find'

def dir_diff_grid(dir1,dir2)

 f = Hash.new
    dir2_base_names = Hash.new
    dir1_base_names=Hash.new
   hash_of_files = Hash.new
 Find.find(dir1) do |file1|
 #excludes = ["CVS","classes","images","lib","tlds","png","gif","rhtml","yml","css","xls","log","db","js","properties","ico"]

 if !File.directory?(file1) && (file1.index('.rb')|| file1.index('.css')|| file1.index('.html')|| file1.index('.yaml')|| file1.index('.rhtml')|| file1.index('.xml')|| file1.index('.css')||file1.index('.txt'))
   file1_name = File.basename(file1)
   if  dir2_base_names.empty?
   dir2_base_names = dir2_base_names(file1_name,dir2)
   end
      if  dir2_base_names.has_key?(file1_name)
       file2 = dir2_base_names["#{file1_name}"]
     end

      date1 = File.mtime(file1)
      size1 =File.size(file1)
 if   !dir2_base_names.has_key?(file1_name)
  #if !File.exist?(file2)
f["#{file1}"] ="Not_Exist_Target_Directory"
  else
          date2 = File.mtime(file2)
          size2 =File.size(file2)
          if (  date1  ==   date2)
             else
                   if (  date1 >   date2)
                     if (size1 != size2)
                     f["#{file1}"] ="Newer_in_size"
                     else
                         f["#{file1}"] ="Newer_in_date"
                      end


                   else
                     if (date1 < date2)
                       if (size1 != size2)
                       f["#{file1}"] ="Older_in_size"
                       else
                     f["#{file1}"] = "Older_in_date"
                       end
                     end

                 end
          end

 end


 end
 end

 Find.find(dir2) do |file2|
 if !File.directory?(file2) && (file2.index('.rb')||file2.index('.css')|| file2.index('.html')|| file2.index('.yaml')|| file2.index('.rhtml')|| file2.index('.xml')|| file2.index('.css')|| file2.index('.txt') )
  file2_name = File.basename(file2)
  if  dir1_base_names.empty?
   dir1_base_names = dir1_base_names(file2_name,dir1)
   end
     if   !dir1_base_names.has_key?(file2_name)
       f["#{file2}"] ="Not_In_Source_Directory"
     end

 end

 end

#-------------------------------------------------
#Create an array to hold the elements of the hash f
#-------------------------------------------------
ary = Array.new

 file_id = 0
 id = 0
   for element in f
     ext = File.extname("#{element[0]}")
      file_id += 1
      id +=1
new_hash= {"ffile"=> "#{element[0]}","difference"=>"#{element[1]}","type"=> "#{ext}","id"=> "#{id}","file_id"=> "#{file_id}"}
ary.push(new_hash)

 #hash2 =  {"ffile"=> "#{elememt[0]}"}
 # hash2.each_value {|value|
                      #str = IO.read("#{value}")
                       #puts str
                 #}


end

ary = [] if !ary
@ary = ary if ary
ary = @ary
 session[:files]=hash_of_files
 return @ary


end

 def dir1_base_names (file2_name,dir1)
  dir1_base_names= Hash.new
  for dir in dir1
     Find.find(dir) do |file2|
            if !File.directory?(file2)
              #puts file1
              file_basename = File.basename(file2)
              #hash  ={"#{file_basename}" => "#{file1}"}
              dir1_base_names["#{file_basename}"] ="#{file2}"

            end

            end

  end

  return dir1_base_names
end


def dir2_base_names (file1_name,dir2)
  dir2_base_names= Hash.new
  for dir in dir2
     Find.find(dir) do |file1|
            if !File.directory?(file1)
               file_basename = File.basename(file1)
               dir2_base_names["#{file_basename}"] ="#{file1}"

            end

            end

  end

  return dir2_base_names
end
