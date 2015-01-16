class Bin < ActiveRecord::Base

  belongs_to :production_run, :foreign_key => 'production_run_tipped_id'
  belongs_to :production_run, :foreign_key => 'production_run_rebin_id'

  has_many :bin_track_indicator
  has_many :rw_receipt_bin
  belongs_to :delivery
  belongs_to :rmt_product
  belongs_to :farm
  belongs_to :presort_staging_run
  belongs_to :presort_staging_run_child
  belongs_to :pack_material_product


  def before_save
    changed_fields?
    if(@changed_fields && @changed_fields.keys.include?('rmt_product_id') && self.delivery_id)
      raise "sorry cannot change rmt_product of this bin, bin[#{self.bin_number}] has already been scanned into a delivery"
    end
    puts
  end

  def Bin.valid_storage_locations?(bin_nr)
    bin = Bin.find_by_bin_number(bin_nr)

    track_indicator_rec  = TrackSlmsIndicator.find(bin.track_indicator1_id)

    query = " select DISTINCT locations.location_code,locations.location_maximum_units,locations.units_in_location,locations.location_status,locations.unavailable
              ,bin_location_setups.priority
              from locations
              join bin_location_setups on bin_location_setups.location_id=locations.id
              where ((bin_location_setups.track_slms_indicator_code='ALL' or bin_location_setups.track_slms_indicator_code='#{track_indicator_rec.track_slms_indicator_code}')
               and (bin_location_setups.farm_code='ALL' or bin_location_setups.farm_code='#{bin.farm.farm_code}')
               and (bin_location_setups.rmt_variety_code='ALL' or bin_location_setups.rmt_variety_code='#{bin.rmt_product.variety.rmt_variety_code}')
               and (bin_location_setups.commodity_code='ALL' or bin_location_setups.commodity_code='#{bin.rmt_product.commodity_code}')
               and (bin_location_setups.assignment_code='ALL' or bin_location_setups.assignment_code='#{bin.destination_process_var}')
               and (bin_location_setups.size_code='ALL' or bin_location_setups.size_code='#{bin.rmt_product.size_code}')
               and (bin_location_setups.ripe_point_code='ALL' or bin_location_setups.ripe_point_code='#{bin.rmt_product.ripe_point_code}')
               and (bin_location_setups.season='ALL' or bin_location_setups.season='#{bin.season_code}')
               and (bin_location_setups.product_class_code='ALL' or bin_location_setups.product_class_code='#{bin.rmt_product.product_class_code}')
               and (bin_location_setups.rmt_product_code='ALL' or bin_location_setups.rmt_product_code='#{bin.rmt_product.rmt_product_code}')
               and (bin_location_setups.rmt_product_type_code='ALL' or bin_location_setups.rmt_product_type_code='#{bin.rmt_product.rmt_product_type_code}')
               and (bin_location_setups.treatment_code='ALL' or bin_location_setups.treatment_code='#{bin.rmt_product.treatment_code}'))
              order by bin_location_setups.priority ASC
          "
    #RAILS_DEFAULT_LOGGER.info ("query: " + query )
    puts query
    ActiveRecord::Base.connection.select_all(query)
  end

  def Bin.is_on_tripsheet?(bin_number)
    vehicle_job=VehicleJob.find_by_sql("select vehicle_jobs.* from vehicle_jobs
                                        join vehicle_job_units on vehicle_job_units.vehicle_job_id=vehicle_jobs.id
                                        join bins on vehicle_job_units.unit_reference_id=bins.bin_number
                                        where bins.bin_number='#{bin_number}' and vehicle_jobs.date_time_offloaded is null")
    if vehicle_job.length > 0
       return   vehicle_job[0].vehicle_job_number.to_s
    else
      return nil
    end
  end

  def Bin.get_rebins(location_id)
     rebins=Bin.find_by_sql(" select bins.* from bins
        inner join stock_items on bins.bin_number=stock_items.inventory_reference
        inner join rmt_products on bins.rmt_product_id=rmt_products.id
        where  stock_items.location_id='#{location_id}' and stock_items.stock_type_code='REBIN' and (stock_items.destroyed is null or stock_items.destroyed = false) and sealed_ca_location_id is null")
    return rebins
  end

  def Bin.get_bins(stock_items)
    inventory_references=Array.new
    for item in stock_items
      inventory_reference = item.inventory_reference
      inventory_references << "bins.bin_number  = '#{inventory_reference}'"
    end
    inventory_references_join = inventory_references.join("  OR  ")  #TODO remove comment below!
    bins = Bin.find_by_sql("select bins.* from bins
          inner join stock_items on bins.bin_number=stock_items.inventory_reference
          inner join rmt_products on bins.rmt_product_id=rmt_products.id
          where  (#{inventory_references_join }) ")#and (stock_items.stock_type_code='BIN' OR stock_items.stock_type_code='PRESORT') and (stock_items.destroyed is null or stock_items.destroyed = false) and sealed_ca_location_id is null")
    return bins
  end

  def Bin.group_bins_by_rmt_product(bins)
    bin_groups     =bins.group(['rmt_product_id'], nil, true)
        rmt_products  = Array.new
        for bin_group in bin_groups
          count                                          = bin_group.length
          rmt_product                                    =RmtProduct.find(bin_group[0].rmt_product_id)
          rmt_product_attributes                         =rmt_product.attributes
          rmt_product_attributes['bins']                 =count
          rmt_product_attributes['new_ripe_point_code']  = nil
          rmt_product_attributes['new_rmt_product_code'] = nil
          rmt_product_attributes['new_rmt_product_id']   = nil
          rmt_products << rmt_product_attributes
        end
    return rmt_products
  end

  def Bin.remove_bin(selected_bins, bin_order_load_status, bin_order_id,user_name)
    begin
      ActiveRecord::Base.transaction do
        for bin in selected_bins

          bin_order        = BinOrder.find(bin_order_id)
          bin_order_product=BinOrderProduct.find_by_sql("
                           select  DISTINCT bin_order_products.* from bin_order_products
                           inner join bin_order_load_details on bin_order_load_details.bin_order_product_id=bin_order_products.id
                           inner join bins on bins.bin_order_load_detail_id=bin_order_load_details.id
                           where bin_order_load_details.id=#{bin.bin_order_load_detail_id}")[0]
          #remove bin
          Bin.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("update bins set bin_order_load_detail_id=null where id =#{bin.id}"))
          #undo move stock
          if  bin_order_load_status=="COMPLETE"
            stock_item=StockItem.find_by_inventory_reference(bin.bin_number)
            if stock_item.destroyed && bin.exit_ref
              Inventory.undo_destroy_stock([bin.bin_number], "BIN_SALES", bin_order.bin_order_number)
            end
          end
          Bin.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("update bins set exit_ref = null where id = #{bin.id}"))
          Bin.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("update bins set exit_reference_date_time = null where id = #{bin.id}"))
          load_details = BinOrderLoadDetail.find_by_sql("
                        select bin_order_load_details.* from bin_order_load_details
                        inner join bin_order_products on bin_order_products.id = bin_order_load_details.bin_order_product_id
                        inner join bin_orders on bin_orders.id=bin_order_products.bin_order_id
                        where bin_order_products.id =#{ bin_order_product.id.to_i} and bin_orders.id = #{ bin_order.id.to_i}")
          for load_detail in load_details
            bin_count = load_detail.bin_count?
            if bin_count == 0
              StatusMan.set_status("LOAD_DETAIL_CREATED", "bin_order_load_detail", load_detail,user_name)
              load_detail.date_time_reversed = Time.now
              load_detail.update
            else
              StatusMan.set_status("LOADING", "bin_order_load_detail", load_detail,user_name)
              load_detail.date_time_reversed = Time.now
              load_detail.update
            end


          end
          bin_order_loads=BinOrderLoad.find_by_sql("
                          select bin_order_loads.* from bin_order_loads
                          inner join bin_order_load_details on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                          where bin_order_load_details.bin_order_product_id=#{bin_order_product.id.to_i}")
          for bin_order_load in bin_order_loads
            load_detail_statuses = bin_order_load.order_load_details_status?
            if  load_detail_statuses=="loading"
              StatusMan.set_status("LOADING", "bin_order_load", bin_order_load,user_name)
              StatusMan.set_status("LOADING", "bin_load", bin_order_load.bin_load,user_name)
            else
              StatusMan.set_status("LOAD_CREATED", "bin_order_load", bin_order_load,user_name)
              StatusMan.set_status("LOAD_CREATED", "bin_load", bin_order_load.bin_load,user_name)
            end

          end


          StatusMan.set_status("ORDER_PRODUCT_CREATED", "bin_order_product", bin_order_product,user_name)
          order_load_statuses =bin_order.order_load_status?
          if order_load_statuses =="loading"
            StatusMan.set_status("LOADING", "bin_order", bin_order,user_name)
          else
            StatusMan.set_status("BIN_ORDER_CREATED", "bin_order", bin_order,user_name)
          end

        end

      end
    end
  end





  def self.bulk_update(set_map, condition_attr, bin_nums=nil, additional_criteria=nil)
    ActiveRecord::Base.transaction do
      updates = ""
      for key in set_map.keys
        updates += key.to_s + "=" + set_map[key].to_s + ","
      end
      updates.chop!

      conditions = ""
      if (bin_nums != nil)
        for bin_num in bin_nums
          bin_num    = "\'" + bin_num.to_s + "\'"
          conditions += condition_attr + "=" + bin_num.to_s + " or "
        end
      end

      if (additional_criteria != nil)
        for ikey in additional_criteria.keys
          conditions += ikey.to_s + "=" + additional_criteria[ikey].to_s + " or "
        end
      end

      conditions.chop!.chop!.chop! if conditions.length > 3
      puts "NULK UPDATE STMT = set(" + updates +")\n " + "where (" + conditions + ")"
      Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates,"bins"), conditions)

    end
  end


  def self.all_bins_of_same_location?(delivery_id)
    bins         = Bin.find_by_sql(" select DISTINCT stock_items.location_code FROM  bins inner join stock_items ON bins.bin_number = stock_items.inventory_reference where bins.delivery_id = '#{delivery_id}'").map { |s| s.location_code }
    bin_location = bins.map { |d| d + "," }
    if bins.length > 1
      error = ["Bins split among more than one location: list of complex names :'#{bin_location}' "]
      return error if error
    end

  end



end
