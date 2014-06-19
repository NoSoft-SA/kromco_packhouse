require  'dir_diff_grid'
require 'find'



 class Diagnostics::DirectoryController < ApplicationController




# def  new_dir
# @content_header_caption = "'Compare directories'"
#render :file =>'app\views\directory_management\directory\uploadfile.rhtml',:layout => "content"
# end

def  compare_dirs
 @content_header_caption = "'Compare directories'"
render :file =>'app\views\diagnostics\directory\directory_compare.rhtml',:layout => "content"
 end


def dir_dir
 #	 render (inline) the edit template
 render :inline => %{
 <% @content_header_caption = "'compare dirs'"%>

 <%= build_directory_form(@dir,'create_dir','compare_dir',false,@is_create_retry)%>

 }, :layout => 'content'
 end

  def  file_diffs
     id = params[:id].to_s
     ary =  session[:ary]

            @content_header_caption = '"View File Differences"'

     render :inline => %{
         <%= build_file_diffs_form %>
         },:layout => 'content'

   end
     def view_diffs_form
  @content_header_caption = "'add score'"

  render :inline => %{
  <%=build_score_entry_form %>
 },:layout => 'content'

end






 def create_dir
 dir1 = params[:dirr][:dir_name1]
 dir2 = params[:dirr][:dir_name2]
  session[:a] = dir1
  session[:b] = dir2

  @ary =dir_diff_grid(dir1,dir2)
  fi =  session[:files]
 session[:files] =fi
  session[:ary]= session[:ary]
  ary =  @ary
  session[:ary]  =  ary

  render :inline => %{
      <% grid            = build_dir_grid( @ary) %>
      <% grid.caption    = 'Directory comparison' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
 end














=begin
   def display_contents
     id = params[:id].to_s
    ary =  session[:ary]



     for record in ary do
      if record["id"].to_s == id
        file1 = record["ffile"]
         @ary = Array.new
         counter = 1
        @ary = File.open("#{file1}").readlines
         #TODO:try to create a hash here {pos=>counter;line=>line}
         @ary = File.open("#{file1}", "r")
          while (line1 = file.gets)
            counter = counter + 1
           end
          end
       end
   end
=end

   def display_contents
        id = params[:id].to_s
       ary =  session[:ary]



        for record in ary do
         if record["id"].to_s == id
           @file1 = record["ffile"]
            @ary = Array.new
           @ary = File.open("#{@file1}").readlines



                  #File.open("#{file1}",'rb') do |file|
                 #while line = file.gets
                #@ary.push(line)
                  #puts line

                    #s= IO.readlines("#{file1}",'').to_s
                    #puts s
                 #end
             end
          end
        end



   def  get_file1_methods(pos1,pos2,fil)

       file1_arrays= Array.new
       counter = 1
            array2 = Array.new
              file = File.open(fil, "r")
              while (line1 = file.gets )  && counter <= pos2
                    if counter >= pos1 && counter <= pos2
                  stripped_line = line1.strip
                  line_length=stripped_line.length
                    if line_length !=0
                      file1_arrays<< line1
                    end
                 end
               counter = counter + 1
              end
              return  file1_arrays
   end

   def get_file2_methods(pos1,pos2,fil2)
     counter = 1
        file2_arrays = Array.new
              file = File.open(fil2, "r")
              while (line2 = file.gets)
                     if counter >= pos1 && counter <= pos2
                  stripped_line = line2.strip
                  line_length=stripped_line.length
                    if line_length !=0
                      file2_arrays << line2
                    end
                 end
               counter = counter + 1
              end

              return file2_arrays
    end

        def view_differences2(fil2)


            file2_methods = Array.new
            counter = 1
            file = File.open(fil2, "r")
            while (line = file.gets)
              puts "#{counter}: #{line}"
                   if line =~ /\bdef/ ||  line =~ /\bclass/
                       if line =~ /\bdef/
                         cntr =1
                          pos1 = counter
                       else
                          cntr =1
                       end
                    end

                    if line =~ /\bif/ ||line =~ /\bdo/ || line =~ /\bfor/ || line =~ /\bcase/||  line =~ /\bwhile/
                          if cntr != 0 && cntr > 0
                           line_pos= counter
                           cntr +=1
                           puts "CNTR IS #{cntr}"
                          end
                     end

                    if line =~ /\bend/
                       cntr -=1
                       puts "CNTR IS #{cntr}"
                     end

                     if cntr == 0   && line != "\n"&& line =~ /\bend/
                        fil2 = fil2
                        pos2 = counter
                        file2_methods  << get_file2_methods(pos1,pos2,fil2)
                     end
                       counter = counter + 1
                end
                return file2_methods
      end

def view_differences  #--Method to display the difference in files.
      #----------------------------------------------
      #If method is incorrect ,for instance it has many if statements
      #and unmatching ends(closing tags) it wil not reflect in the comparison ,it wil be treated as not existing
      #-----------------------------------------------------
      @file_method_diffs = Array.new


      id = params[:id].to_s
      dir1 = session[:a]
      dir2 = session[:b]
      fi=session[:files]
     ary =  session[:ary]

           for record in ary
               if record["id"].to_s == id
                 @file1 = record["ffile"]
                 file1_base_name = File.basename(@file1)
                 dir2_base_nams = dir2_base_names(file1_base_name,dir2)

                  if  dir2_base_names(file1_base_name,dir2).has_key?(file1_base_name)
                      dir2_base_nams = dir2_base_names(file1_base_name,dir2)
                      @file2 = dir2_base_nams["#{file1_base_name}"]
                      #@file2=fi["#{@file1}"]
                      @file2
                  end

               end

           end
               if !@file1.index(".rb")
                   file1 = @file1
                   file2 = @file2
                   ary2 = File.open("#{@file2}").readlines
                   ary1 = File.open("#{@file1}").readlines
                   display_diffs(file1,file2,ary1,ary2)
               else
                @file2 = @file2 
          file1_methods = Array.new
           counter = 1
           file = File.open( @file1, "r")
            while (line = file.gets)
              puts "#{counter}: #{line}"
                    if line =~ /\bdef/ ||  line =~ /\bclass/
                       if line =~ /\bdef/
                         cntr =1
                         d =  cntr
                          pos1 = counter
                       else
                          cntr =1
                       end
                    end

        if  line =~ /\Aif/ ||line =~ /\bdo/ || line =~ /\bfor/ || line =~ /\bcase/||  line =~ /\bwhile/

                          if cntr != 0 && cntr > 0
                            line_pos= counter
                           cntr +=1
                           puts "CNTR IS #{cntr}"
                          end
                     end

                    if line =~ /\bend/
                       cntr -=1
                       puts "CNTR IS #{cntr}"
                     end


                     if cntr == 0   && line != "\n"&& line =~ /\bend/
                       fil = @file1
                       pos2 = counter
                       file1_methods<< get_file1_methods(pos1,pos2,fil)
                     end
                     counter = counter + 1
               end
      file.close
      fil2 = @file2
      file2_methods = view_differences2(fil2)

         @diffs_file1=file1_methods-file2_methods
         @diffs_file2 = file2_methods-file1_methods

           @file_method_diffs << @diffs_file1
           @file_method_diffs << @diffs_file2

           @file_method_diffs
           end

end

 def display_diffs(file1,file2,ary1,ary2)
   @ary1 =ary1
   @ary2 = ary2
   @file1= file1
   @file2=file2
   @content_header_caption = "'View differences'"
  render :file =>'app\views\diagnostics\directory\display_diffs.rhtml',:layout => "content"
 end


 def dir1_base_nams (file1_base_name,dir1)
   dir1_base_names= Hash.new
   for dir in dir1
      Find.find(dir) do |file1|
             if !File.directory?(file1)
                file_basename = File.basename(file1)
                dir1_base_names["#{file_basename}"] ="#{file1}"

             end

             end

   end

   return dir1_base_names
 end





   end





































































