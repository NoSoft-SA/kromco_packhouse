

class DevelopmentTools::RakeController < ApplicationController
  
  def program_name?
    "rake"
  end
  
  def clear_logs
  
   #@output = `rake_clear_logs.bat`
   @output = `rake log:clear`
   render_output
  
  end
  
  def restart_server
   @output = `\0x30`
   render_output
  end
  
   def stats
  
    #@output = `rake_stats.bat`
    @output = `rake stats`
    puts @output
    render_output
  
  end
  
  def render_output
    render :inline => %{
		<% @content_header_caption = "'rake output'"%> 
        
        
		<pre class = "test_output"><%= @output %></pre>

    }, :layout => 'content'
  
  
  end
  
 
  
  
end



