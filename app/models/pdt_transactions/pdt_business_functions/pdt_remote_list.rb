class PdtRemoteList

  def PdtRemoteList.get_stored_pdt_processes_user_process_name(params={})
    StoredPdtProcess.find_by_sql("select transaction_name,user_process_name from stored_pdt_processes where stored_pdt_processes.transaction_name='#{params["transaction_name"]}'")
  end

  def PdtRemoteList.get_stored_pdt_processes_transaction_name(params={})
    StoredPdtProcess.find_by_sql("select distinct transaction_name from stored_pdt_processes")
  end

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

end