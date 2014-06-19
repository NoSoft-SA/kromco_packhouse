class  Services::PdtDataServiceController < ApplicationController
 def bypass_generic_security?
   true
 end

 def get_production_runs_results
   #-------------------------------- To be filtered client side -----------------------------------------------
    result_set = ProductionRun.find_by_sql("select distinct line_code,farm_code,account_code from production_runs")
   #-------------------------------- To be filtered client side -----------------------------------------------
    result = package_result_set(result_set)
    send_response(result)
 end
 
 def get_production_runs_line_code
   #-------------------------------- To be filtered here -----------------------------------------------
     result_set = ProductionRun.find_by_sql("select distinct line_code from production_runs")
   #-------------------------------- To be filtered here -----------------------------------------------
    result = package_result_set(result_set)
    send_response(result)
  end

 def get_production_runs_farm_code
     line_code = params["line_code"].to_s
     result_set = ProductionRun.find_by_sql("select distinct farm_code from production_runs where line_code = '#{line_code}'")
     result = package_result_set(result_set)
     send_response(result)
 end

 def get_production_runs_account_code
     line_code = params["line_code"].to_s
     farm_code = params["farm_code"].to_s
     result_set = ProductionRun.find_by_sql("select distinct account_code from production_runs where line_code = '#{line_code}' and farm_code = '#{farm_code}'")
     result = package_result_set(result_set)
     send_response(result)
 end

 def get_stored_pdt_processes_user_process_name
     transaction_name = params["transaction_name"].to_s
     stored_processes = StoredPdtProcess.find_by_sql("select transaction_name,user_process_name from stored_pdt_processes where stored_pdt_processes.transaction_name='#{transaction_name}'")
     result = package_result_set(stored_processes)
     send_response(result)
 end

 def get_stored_pdt_processes_transaction_name
   stored_processes = StoredPdtProcess.find_by_sql("select distinct transaction_name from stored_pdt_processes") #where stored_pdt_processes.user='#{@user}' and stored_pdt_processes.ip_address='#{@ip}'
   result = package_result_set(stored_processes)
   send_response(result)
 end

 def get_temperature_device_type_list
   temperature_device_type_codes = TemperatureDeviceType.find_by_sql("select distinct temperature_device_type_code from temperature_device_types").unshift(TemperatureDeviceType.new({:temperature_device_type_code=> ""}))
   result = package_result_set(temperature_device_type_codes)
   send_response(result)
 end

 def get_unit_type_list
   unit_type_codes = UnitType.find_by_sql("select distinct unit_type_code from unit_types").unshift(UnitType.new({:unit_type_code=> ""}))
   result = package_result_set(unit_type_codes)
   send_response(result)
 end

 def get_loading_vehicle_numbers
   load_vehicles_process_vars = LoadVehiclesProcessVar.find_by_sql("select vehicle_number from load_vehicles_process_vars").unshift(LoadVehiclesProcessVar.new({:vehicle_number=> ""}))
   result = package_result_set(load_vehicles_process_vars)
   send_response(result)
 end

 def get_offload_tripsheets
   offload_vehicles_process_vars = OffloadVehiclesProcessVar.find_by_sql("select tripsheet_number from offload_vehicles_process_vars").unshift(OffloadVehiclesProcessVar.new({:tripsheet_number=> ""}))
   result = package_result_set(offload_vehicles_process_vars)
   send_response(result)
 end









  def list_drench_lines
    drench_lines = DrenchLine.find(:all)
    result = package_result_set(drench_lines)    
    send_response(result)
  end
  
  def list_drenches
    drenches = DrenchStation.find(:all)
    result = package_result_set(drenches)
    
    send_response(result)
  end
  
  def list_drench_concentrates
    drench_concentrates = DrenchConcentrate.find(:all)
    result = package_result_set(drench_concentrates)
    send_response(result)
  end
  
  def list_concentrate_product_types
    drench_concentrate_products = ConcentrateProduct.find(:all)
    result = package_result_set(drench_concentrate_products)
    send_response(result)
  end
  
  def list_forecasts
    forecasts = Forecast.find(:all)
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
    pallet_format_products = PalletFormatProduct.find_by_sql("SELECT distinct pallet_format_product_code from pallet_format_products")
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