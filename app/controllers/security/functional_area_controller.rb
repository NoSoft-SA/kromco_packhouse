class  Security::FunctionalAreaController < ApplicationController
 
def program_name?
	"functional_area"
end

def list_functional_areas
	return if authorise_for_web('functional_area','read') == false

	@functional_area_pages = Paginator.new self, FunctionalArea.count, 20,params['page']
	 @functional_areas = FunctionalArea.find(:all,
			 :limit => @functional_area_pages.items_per_page,
			 :offset => @functional_area_pages.current.offset)
	session[:functional_areas] = @functional_areas
	render_list_functional_areas
end


def render_list_functional_areas
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	render :inline => %{
      <% grid            = build_functional_area_grid(@functional_areas,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all functional_areas' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@functional_area_pages) if @functional_area_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_functional_areas_flat
	return if authorise_for_web('functional_area','read')== false
	@is_flat_search = true 
	render_functional_area_search_form
end

def render_functional_area_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  functional_areas'"%> 

		<%= build_functional_area_search_form(nil,'submit_functional_areas_search','submit_functional_areas_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_functional_areas_search
	session[:functional_areas] = nil
	@functional_area_pages = Paginator.new self, FunctionalArea.count, 20,params['page']
	if params[:page]== nil
		 @functional_areas = dynamic_search(params[:functional_area] ,'functional_areas','FunctionalArea')
	else
		@functional_areas = eval(session[:query])
	end
	if @functional_areas.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_functional_area_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_functional_areas
		end
	else
		session[:functional_areas] = @functional_areas
		@functional_areas = session[:functional_areas]
		render_list_functional_areas
	end
end

 
def delete_functional_area
	return if authorise_for_web('functional_area','delete')== false
	id = params[:id]
	if id && functional_area = FunctionalArea.find(id)
		functional_area.destroy
		session[:alert] = " Record deleted."
#		 update in-memory recordset
		@functional_areas = session[:functional_areas]
		 delete_record(@functional_areas,id)
		session[:functional_areas] = @functional_areas
		render_list_functional_areas
	end
end
 
def new_functional_area
	return if authorise_for_web('functional_area','create')== false
		render_new_functional_area
end
 
def create_functional_area
	 @functional_area = FunctionalArea.new(params[:functional_area])
	 if @functional_area.save
	#update in-memory list- if it exists
		if session[:functional_areas]
			 session[:functional_areas].push @functional_area
		end
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_functional_area
	 end
end

def render_new_functional_area
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new functional_area'"%> 

		<%= build_functional_area_form(@functional_area,'create_functional_area','create_functional_area',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_functional_area
	return if authorise_for_web('functional_area','edit')==false 
	 id = params[:id]
	 if id && @functional_area = FunctionalArea.find(id)

   #@functional_area.update_attribute(:display_name,@functional_area.display_name)
    @functional_area.save

   list_functional_areas
   return

		render_edit_functional_area

	 end
end


def render_edit_functional_area
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit functional_area'"%> 

		<%= build_functional_area_form(@functional_area,'update_functional_area','update_functional_area',true)%>

		}, :layout => 'content'
end
 
def update_functional_area
	 id = params[:functional_area][:id]
	 if id && @functional_area = FunctionalArea.find(id)
		 if @functional_area.update_attributes(params[:functional_area])
#		update the in-memory recordset- to save db call
			update_record(session[:functional_areas],@functional_area.attributes,id)
			@functional_areas = session[:functional_areas]
			render_list_functional_areas
		else
			 render_edit_functional_area

		 end
	 end
 end
 
def generate_pdt_menu_structure
  pdt_programs = FunctionalArea.find_all_by_is_non_web_program(true,:order=>'functional_area_name ASC')
  pdt_simulator_menu_structure_document = REXML::Document.new
  pdt_device_menu_structure_document = REXML::Document.new
  
  pdt_simulator_root = pdt_simulator_menu_structure_document.add_element("SystemSchema")
  pdt_device_root = pdt_device_menu_structure_document.add_element("SystemSchema")
  
  #-----------------------------------------------------------------------
  #--------------- PdtSimulator Statically Defined Tags ------------------
  #-----------------------------------------------------------------------
  pdt_simulator_root.add_attributes({'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance','xsi:noNamespaceSchemaLocation'=>'d\:Pmm\Config\systemschema.xsd'})
    namespace = pdt_simulator_root.add_element("Namespace")
    namespace.add_text("xs")

    ns_url = pdt_simulator_root.add_element("nsURL")
    ns_url.add_text("http://www.w3.org/2001/XMLSchema")

    boot_records = pdt_simulator_root.add_element("BootRecords")
    boot_records.add_attributes({'Name'=>'RFS-01','File'=>'rf/RFS-01.xml'})
      mesware = boot_records.add_element("Mesware")
      mesware.add_attributes({'Status'=>'true','Operation'=>'remote','Config'=>'mwpdt','License'=>'KRM0053601414314161'})

      ip_data = boot_records.add_element("IPData")
      ip_data.add_attributes({'Server'=>'192.168.10.179','ListenPort'=>'2000','ServerPort'=>'2020','HTTPPort'=>'2080'})

      device = boot_records.add_element("Device")
      device.add_attributes({'Message'=>'true','DeviceName'=>'Symbol','DeviceAddress'=>'0','DevicePort'=>'1','Enable'=>'true','DriverName'=>'MC9090G'})

      buttons = boot_records.add_element("Buttons")
      buttons.add_attributes({'B2Enable'=>'true','B3Enable'=>'true','B1Label'=>'Yes','B1Enable'=>'true','B3Label'=>'Cancel','B2Label'=>'No'})

      input_fields = boot_records.add_element("InputFields")
      input_fields.add_attributes({'Input3Enable'=>'true','Input1Enable'=>'true','Input2Enable'=>'true','Input3Label'=>'Scan 3','Input2Label'=>'Scan 2','Input1Label'=>'Scan 1'})

      server1 = boot_records.add_element("Server")
      server1.add_attributes({'Item'=>'0','List'=>'2'})
      server2 = boot_records.add_element("Server")
      server2.add_attributes({'Status'=>'true','Name'=>'SRV-01','IP'=>'192.168.10.179','Item'=>'1','ServerPort'=>'2020'})
      server3 = boot_records.add_element("Server")
      server3.add_attributes({'Status'=>'true','Name'=>'SRV-02','IP'=>'192.168.10.17','Item'=>'2','ServerPort'=>'2020'})

      printer1 = boot_records.add_element("Printer")
      printer1.add_attributes({'Item'=>'0','List'=>'2'})
      printer2 = boot_records.add_element("Printer")
      printer2.add_attributes({'Status'=>'true','Name'=>'PRN-01','Port'=>'8375','IP'=>'192.168.10.177','Item'=>'1'})
      printer3 = boot_records.add_element("Printer")
      printer3.add_attributes({'Status'=>'true','Name'=>'PRN-02','Port'=>'8375','IP'=>'192.168.10.178','Item'=>'2'})

      choice1 = boot_records.add_element("Choice")
      choice1.add_attributes({'Name'=>'None','Number'=>'1','Enable'=>'true','Item'=>'0'})
      choice2 = boot_records.add_element("Choice")
      choice2.add_attributes({'Name'=>'Goldens','Number'=>'1','Enable'=>'true','Item'=>'1'})
      choice3 = boot_records.add_element("Choice")
      choice3.add_attributes({'Name'=>'Grannies','Number'=>'1','Enable'=>'true','Item'=>'2'})

  #-----------------------------------------------------------------------
  #--------------- PdtDevice Statically Defined Tags ---------------------
  #-----------------------------------------------------------------------
  pdt_device_root.add_attributes({'xmlns:xsi'=>'http://www.w3.org/2001/XMLSchema-instance','xsi:noNamespaceSchemaLocation'=>'d\:Pmm\Config\systemschema.xsd'})
    pdt_device_namespace = pdt_device_root.add_element("Namespace")
    pdt_device_namespace.add_text("xs")

    pdt_device_ns_url = pdt_device_root.add_element("nsURL")
    pdt_device_ns_url.add_text("http://www.w3.org/2001/XMLSchema")

    configuration_records = pdt_device_root.add_element("ConfigurationRecords")
    configuration_records.add_attributes({'Name'=>'RFS-03','File'=>'c:/jmt/mwserver/config/rf/mwrf_a.xml'})
      pdt_device_mesware = configuration_records.add_element("Mesware")
      pdt_device_mesware.add_attributes({'Status'=>'true','Operation'=>'remote','Config'=>'mwpdt','License'=>'KRM0053601414314161'})

      pdt_device_ip_data = configuration_records.add_element("IPData")
      pdt_device_ip_data.add_attributes({'ListenPort'=>'2000','Server'=>'192.168.10.179','ServerPort'=>'2020','HTTPPort'=>'2080' })

      pdt_device_web_data = configuration_records.add_element("WebData")
      pdt_device_web_data.add_attributes({'URL'=>'192.168.10.9','HTTPPort'=>'8080','HTTPSPort'=>'9080','HTTPOOPort'=>'2082'})

      pdt_device_device = configuration_records.add_element("Device")
      pdt_device_device.add_attributes({'DeviceName'=>'intermec','DevicePort'=>'1','DriverName'=>'ck3','Enable'=>'true','Message'=>'true','DeviceAddress'=>'0'})

      pdt_device_buttons = configuration_records.add_element("Buttons")
      pdt_device_buttons.add_attributes({'B1Label'=>'Yes','B1Enable'=>'false','B2Label'=>'No','B2Enable'=>'false','B3Label'=>'Cancel','B3Enable'=>'false'})

      pdt_device_input_fields = configuration_records.add_element("InputFields")
      pdt_device_input_fields.add_attributes({'Input1Label'=>'Scan 1','Input1Enable'=>'true','Input2Label'=>'Scan 2','Input2Enable'=>'true','Input3Label'=>'Scan 3','Input3Enable'=>'true'})

      pdt_device_server1 = configuration_records.add_element("Server")
      pdt_device_server1.add_attributes({'Item'=>'1','Status'=>'true','Name'=>'SRV-01','IP'=>'192.168.10.179','ServerPort'=>'2020'})

      pdt_device_server2 = configuration_records.add_element("Server")
      pdt_device_server2.add_attributes({'Item'=>'2','Status'=>'true','Name'=>'SRV-02','IP'=>'192.168.10.17','ServerPort'=>'2020'})

      pdt_device_printer1 = configuration_records.add_element("Printer")
      pdt_device_printer1.add_attributes({'Item'=>'1','Status'=>'true','Name'=>'PRN-01','IP'=>'192.168.10.177','Port'=>'8375'})

      pdt_device_printer2 = configuration_records.add_element("Printer")
      pdt_device_printer2.add_attributes({'Item'=>'2','Status'=>'true','Name'=>'PRN-02','IP'=>'192.168.10.178','Port'=>'8375'})

      



  #-----------------------------------------------------------------------
  #--------------- End of Statically Defined Tags ------------------------
  #-----------------------------------------------------------------------
      menus = boot_records.add_element("menus")
        menu1 = menus.add_element("menu")
        menu1.add_attributes({'node_type'=>'.','display'=>'Mesware','value'=>'0.0'})
        menu2 = menus.add_element("menu")
        menu2.add_attributes({'node_type'=>'0','display'=>'SLMS','value'=>'1.0'})

        pdt_device_slms = configuration_records.add_element("Menu")
        pdt_device_slms.add_attributes({'Item'=>'0.0','Name'=>'SLMS','NodeType'=>'0'})

        pdt_programs.each do |prog|
          generate_menu(menu2,prog,configuration_records)
        end

    choice0 = configuration_records.add_element("Choice")
    choice0.add_attributes({'Number'=>'1','Item'=>'0','Name'=>'None','Enable'=>'true'})

    choice1 = configuration_records.add_element("Choice")
    choice1.add_attributes({'Number'=>'1','Item'=>'1','Name'=>'None','Enable'=>'true'})

    choice2 = configuration_records.add_element("Choice")
    choice2.add_attributes({'Number'=>'1','Item'=>'2','Name'=>'None','Enable'=>'true'})


  pdt_simulator_menu_structure_document << REXML::XMLDecl.new("1.0","UTF-8")
  pdt_device_menu_structure_document << REXML::XMLDecl.new("1.0","UTF-8")

  pdt_simulator_file_name = "public/security_configs/pdt_menu_structures/pdt_simulator_menu_spec.xml"
  pdt_device_file_name = "public/security_configs/pdt_menu_structures/pdt_device_menu_spec.xml"

  simulator_structure = ""
  pdt_simulator_menu_structure_document.write(simulator_structure,3)
  File.open(pdt_simulator_file_name,"w") do |f|
    f.write(simulator_structure)
    f.close
  end


  device_structure = ""
  pdt_device_menu_structure_document.write(device_structure,0)
  File.open(pdt_device_file_name,"w") do |g|
    g.write(device_structure.gsub("'", "\"") { |match|  })
    g.close
  end

  flash[:notice] = "pdt menu strutures created successfully"
  redirect_to_index("pdt menu strutures created successfully")
end

def generate_menu(parent,menu,configuration_records)
  if(menu.kind_of?(FunctionalArea))
    func_area = parent.add_element("menu")
    func_area.add_attributes({'node_type'=>'1','display'=>menu.display_name,'value'=>menu.functional_area_name})

    pdt_device_func_area = configuration_records.add_element("Menu")
    pdt_device_func_area.add_attributes({'Item'=>menu.functional_area_name,'Name'=>menu.display_name,'Enable'=>'true','NodeType'=>'1'})
  
    menu.programs.sort_list(["program_name"]).each do |prog|
      generate_menu(func_area,prog,configuration_records)
    end
  elsif(menu.kind_of?(Program))
    program = parent.add_element("menu")
    node_type = '1'
    node_type = '2' if menu.is_leaf
    program.add_attributes({'node_type'=>node_type,'display'=>menu.display_name,'value'=>menu.program_name})

    pdt_device_program = configuration_records.add_element("Menu")
    pdt_device_program.add_attributes({'Item'=>menu.program_name,'Name'=>menu.display_name,'Enable'=>'true','NodeType'=>node_type})#,'Port'=>'2020','AutoTrigger'=>'true','B1Label'=>'Yes','B1Enable'=>'false','B2Label'=>'No','B2Enable'=>'false','B3Label'=>'Cancel','B3Enable'=>'true','Input1Label'=>'Scan 1','Input1Enable'=>'true','Input2Label'=>'Scan 2','Input2Enable'=>'false','Input3Label'=>'Scan 3','Input3Enable'=>'false'})
  
    menu.program_functions.sort_list(["name"]).each do |prog|
      generate_menu(program,prog,configuration_records)
    end
  elsif(menu.kind_of?(ProgramFunction))
    program = parent.add_element("menu")
    program.add_attributes({'node_type'=>'2','display'=>menu.display_name,'value'=>menu.name})

    pdt_device_program_function = configuration_records.add_element("Menu")
    pdt_device_program_function.add_attributes({'Item'=>menu.name,'Name'=>menu.display_name,'Enable'=>'true','NodeType'=>'2'})#,'Port'=>'2020','AutoTrigger'=>'true','B1Label'=>'Yes','B1Enable'=>'false','B2Label'=>'No','B2Enable'=>'false','B3Label'=>'Cancel','B3Enable'=>'true','Input1Label'=>'Scan 1','Input1Enable'=>'true','Input2Label'=>'Scan 2','Input2Enable'=>'false','Input3Label'=>'Scan 3','Input3Enable'=>'false'})
  end
end

end
