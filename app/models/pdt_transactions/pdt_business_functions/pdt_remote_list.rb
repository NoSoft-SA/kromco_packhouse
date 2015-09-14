class PdtRemoteList

  def PdtRemoteList.get_fg_setups_for_bay(params={})

    query = "SELECT
              fruit_packing_fg_setups.fg_setup_code
            FROM
              public.active_run_resources,
              public.fruit_packing_fg_setups, product_setups
            WHERE
              active_run_resources.product_setup_id = product_setups.id and
              fruit_packing_fg_setups.id = product_setups.setup_detail_id AND
              active_run_resources.resource_code = '#{params['bay']}'"

    setups = ActiveRecord::Base.connection.select_all(query)
    setups.unshift({'fg_setup_code' => "Select a value from bays"}) if setups.length == 0
    return setups
  end


  def PdtRemoteList.get_palletizing_bays_for_pdt(params={})

    ip = params.keys.include?('ip') ? params['ip'] : params['request'].env['REMOTE_ADDR']

    query = "select distinct resources.resource_code as bay from resources,resource_types

               where resources.id in(SELECT
                public.resource_associations.resource1_id
              FROM
                public.resources,
                public.resource_types,
                public.resource_associations
              WHERE
                resources.resource_type_id = resource_types.id AND

                resource_associations.resource2_id = resources.id AND
                resource_types.resource_type_code = 'PDT' and resources.ip_address = '#{ip}') and
                  resources.resource_type_id = resource_types.id and resource_types.resource_type_code = 'PALLETIZING_BAY' ORDER BY resources.resource_code asc"



    ActiveRecord::Base.connection.select_all(query)
  end

  def PdtRemoteList.get_pallet_format_product_codes(params={})
    PalletFormatProduct.find_by_sql("SELECT distinct pallet_format_product_code from pallet_format_products")
  end


  def PdtRemoteList.get_production_runs_results(params={})
    ProductionRun.find_by_sql("select distinct line_code,farm_code,account_code from production_runs")
  end

  def PdtRemoteList.get_production_runs_line_code(params={})
    ProductionRun.find_by_sql("select distinct line_code from production_runs")
  end

  def PdtRemoteList.get_production_runs_farm_code(params={})
    ProductionRun.find_by_sql("select distinct farm_code from production_runs where line_code = '#{params["line_code"].to_s}'")
  end

  def PdtRemoteList.get_production_runs_account_code(params={})
    ProductionRun.find_by_sql("select distinct account_code from production_runs where line_code = '#{params["line_code"].to_s}' and farm_code = '#{params["farm_code"].to_s}'")
  end

  def PdtRemoteList.get_stored_pdt_processes_user_process_name(params={})
    StoredPdtProcess.find_by_sql("select transaction_name,user_process_name from stored_pdt_processes where stored_pdt_processes.transaction_name='#{params["transaction_name"].to_s}'")
  end

  def PdtRemoteList.get_stored_pdt_processes_transaction_name(params={})
    StoredPdtProcess.find_by_sql("select distinct transaction_name from stored_pdt_processes")
  end

  def PdtRemoteList.get_temperature_device_type_list(params={})
    TemperatureDeviceType.find_by_sql("select distinct temperature_device_type_code from temperature_device_types").unshift(TemperatureDeviceType.new({:temperature_device_type_code=> ""}))
  end

  def PdtRemoteList.get_unit_type_list(params={})
    UnitType.find_by_sql("select distinct unit_type_code from unit_types").unshift(UnitType.new({:unit_type_code=> ""}))
  end

  def PdtRemoteList.get_loading_vehicle_numbers(params={})
    LoadVehiclesProcessVar.find_by_sql("select vehicle_number from load_vehicles_process_vars").unshift(LoadVehiclesProcessVar.new({:vehicle_number=> ""}))
  end

  def PdtRemoteList.get_offload_tripsheets(params={})
    OffloadVehiclesProcessVar.find_by_sql("select tripsheet_number from offload_vehicles_process_vars").unshift(OffloadVehiclesProcessVar.new({:tripsheet_number=> ""}))
  end

  def PdtRemoteList.list_drench_lines(params={})
    DrenchLine.find(:all)
  end

  def PdtRemoteList.list_drenches(params={})
    DrenchStation.find(:all)
  end

  def PdtRemoteList.list_drench_concentrates(params={})
    DrenchConcentrate.find(:all)
  end

  def PdtRemoteList.list_concentrate_product_types(params={})
    ConcentrateProduct.find(:all)
  end

  def PdtRemoteList.list_forecasts(params={})
    Forecast.find(:all)
  end
end