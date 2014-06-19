
require File.dirname(__FILE__) + '/../../../lib/tester.rb'

class DevelopmentTools::TestsController < ApplicationController
  
  def program_name?
    "tests"
  end
  
  def run_all_tests
  
   @output = `rake_func_test.bat`
   
   render :inline => %{
		<% @content_header_caption = "'test output'"%> 

		<pre class = "test_output"><%= @output %></pre>

  }, :layout => 'content'
  
  end
  
  def test_program
   tester = Tester.new
   @func_area_names = tester.func_areas.keys
   session[:tester]= tester
   render :inline => %{
		<% @content_header_caption = "'test program'"%> 

		<%= build_test_program_form(@func_area_names)%>

  }, :layout => 'content'
  
  end
  
  def test_program_function
   tester = Tester.new
   @func_area_names = tester.func_areas.keys
   session[:tester]= tester
   render :inline => %{
		<% @content_header_caption = "'test program function'"%> 

		<%= build_test_function_form(@func_area_names)%>

  }, :layout => 'content'
  
  end
  
  
  def test_program_submit
    #ruby test/functional/d.rb
    cmd = "ruby test/functional/" + params[:prog][:functional_area] + "/" + params[:prog][:program]
    @test_output = nil
     @test_name =  params[:prog][:functional_area] + "/" + params[:prog][:program]
    eval "@test_output = \`" + cmd + "\`"
      render :inline => %{
		<% @content_header_caption = "'test output for test: " + @test_name + "'"%> 

		<pre class = "test_output"><%= @test_output %></pre>

  }, :layout => 'content'
  
  end
  
  def test_function_submit
    
    cmd = "ruby test/functional/" + params[:prog][:functional_area] + "/" + params[:prog][:program] + " -n " + params[:prog][:function] 
    @test_output = nil
    @test_name =  params[:prog][:functional_area] + "/" + params[:prog][:program] + " => " + params[:prog][:function] 
    eval "@test_output = \`" + cmd + "\`"
      render :inline => %{
		<% @content_header_caption = "'test output for test: " + @test_name + "'"%> 

		<pre class = "test_output"><%= @test_output %></pre>

  }, :layout => 'content'
    
  
  
  end
  
  
  
  #---------------------------------------------
  #combo changed event handlers for program form
  #---------------------------------------------
  
  def prog_functional_area_changed
    func_area = get_selected_combo_value(params)
	@programs = session[:tester].func_areas[func_area]
	render :inline => %{
		<%= select('prog','program',@programs)%>

		}
  
  end
 
  
  
  #-----------------------------------------------
  #combo changed event handler for functions form
  #-----------------------------------------------
  def prog_functional_area_changed_f
    func_area = get_selected_combo_value(params)
	session[:test_program_form][:func_area_combo_selection] = func_area
	
    @programs = session[:tester].func_areas[func_area]

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('prog','program',@programs)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_prog_program'/>
		<%= observe_field('prog_program',:update => 'function_cell',:url => {:action => session[:test_program_form][:prog_observer][:remote_method]},:loading => "show_element('img_prog_program');",:complete => session[:test_program_form][:prog_observer][:on_completed_js])%>
		}
  
  end
  
  def prog_program_changed_f
  
    program = get_selected_combo_value(params)
    func_area = session[:test_program_form][:func_area_combo_selection]
    
    #require File.dirname(__FILE__) + '/../../../test/functional/security/program_function_controller_test.rb'
   
    @functions = session[:tester].get_functions(func_area,program)

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('prog','function',@functions)%>
		
		}
  
  end
  
 
end



