class  Services::PdtDataServiceController < ApplicationController
 def bypass_generic_security?
   true
 end

 def get_production_runs_results
   #-------------------------------- To be filtered client side -----------------------------------------------
    result_set = PdtRemoteList.get_production_runs_results(params)
   #-------------------------------- To be filtered client side -----------------------------------------------
    result = package_result_set(result_set)
    send_response(result)
 end
 
 def get_production_runs_line_code
   #-------------------------------- To be filtered here -----------------------------------------------
     result_set = PdtRemoteList.get_production_runs_line_code(params)
   #-------------------------------- To be filtered here -----------------------------------------------
    result = package_result_set(result_set)
    send_response(result)
  end

 def get_production_runs_farm_code
     line_code = params["line_code"].to_s
     result_set = PdtRemoteList.get_production_runs_farm_code(params)
     result = package_result_set(result_set)
     send_response(result)
 end

 def get_production_runs_account_code
     line_code = params["line_code"].to_s
     farm_code = params["farm_code"].to_s
     result_set = PdtRemoteList.get_production_runs_account_code(params)
     result = package_result_set(result_set)
     send_response(result)
 end

 def get_stored_pdt_processes_user_process_name
     transaction_name = params["transaction_name"].to_s
     stored_processes = PdtRemoteList.get_stored_pdt_processes_user_process_name(params)
     result = package_result_set(stored_processes)
     send_response(result)
 end

 def get_stored_pdt_processes_transaction_name
   stored_processes = PdtRemoteList.get_stored_pdt_processes_transaction_name(params)
   result = package_result_set(stored_processes)
   send_response(result)
 end

 def get_temperature_device_type_list
   temperature_device_type_codes = PdtRemoteList.get_temperature_device_type_list(params)
   result = package_result_set(temperature_device_type_codes)
   send_response(result)
 end

 def get_unit_type_list
   unit_type_codes = PdtRemoteList.get_unit_type_list(params)
   result = package_result_set(unit_type_codes)
   send_response(result)
 end

 def get_loading_vehicle_numbers
   load_vehicles_process_vars = PdtRemoteList.get_loading_vehicle_numbers(params)
   result = package_result_set(load_vehicles_process_vars)
   send_response(result)
 end

 def get_offload_tripsheets
   offload_vehicles_process_vars = PdtRemoteList.get_offload_tripsheets(params)
   result = package_result_set(offload_vehicles_process_vars)
   send_response(result)
 end









  def list_drench_lines
    drench_lines = PdtRemoteList.list_drench_lines(params)
    result = package_result_set(drench_lines)    
    send_response(result)
  end
  
  def list_drenches
    drenches = PdtRemoteList.list_drenches(params)
    result = package_result_set(drenches)
    
    send_response(result)
  end
  
  def list_drench_concentrates
    drench_concentrates = PdtRemoteList.list_drench_concentrates(params)
    result = package_result_set(drench_concentrates)
    send_response(result)
  end
  
  def list_concentrate_product_types
    drench_concentrate_products = PdtRemoteList.list_concentrate_product_types(params)
    result = package_result_set(drench_concentrate_products)
    send_response(result)
  end
  
  def list_forecasts
    forecasts = PdtRemoteList.list_forecasts(params)
    result = package_result_set(forecasts)
    
    send_response(result)
  end
  
  def package_result_set(result_set)
     record_set = "<recordset>"
      record = ""
       result_set.each do |drench|
         record = "<record "
           drench.attribute_names.each do |attr_name|
             record += attr_name.to_s + "='" + drench.attributes[attr_name].to_s + "' "
           end
         record += "/>"
         record_set += record
       end
     record_set += "</recordset>"
     
     return record_set
  end

  #=============================================
  #  Happy's List methods
  #=============================================
  def get_pallet_format_product_codes
    pallet_format_products = PdtRemoteList.get_stored_pdt_processes_user_process_name(params)
    result = package_result_set(pallet_format_products)
    send_response(result)
  end
  #=============================================
  #  Happy's List methods
  #=============================================
  
  def send_response(result)
  @result = result
  puts "Response/Result = " + result
   render :inline => %{
                       <%= @result %>
                        }
 end
 
 
  #def pdt_login
  #   @user = User.login(params[:user_name],params[:password])
  #    if @user != nil
  #       session[:pdt_user] = @user
  #       result = "<user user_name='" + @user.user_name + "'" + " logged_in='true' />"
  #       send_response(result)
  #       #render :template => '/tools/pdt_simulator/pdt_user_logged_in.rhtml'
  #       return
  #    else
  #    puts "FAILED !!!!"
  #      result = "<user user_name='' logged_in='false' />"
  #      send_response(result)
  #      #render :template => '/tools/pdt_simulator/pdt_login.rhtml'
  #       return
  #    end
  #end
 
end