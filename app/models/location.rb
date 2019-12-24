class Location < ActiveRecord::Base

  attr_accessor :status_changed_date_time

#	===========================
# 	Association declarations:
#	===========================
  has_many :stock_items
  has_many :inventory_transactions
  has_many :location_setups
  has_many :bin_location_setups
  has_many :precool_jobs

#    belongs_to :facility

#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :location_code

  def Location.check_location_status(location_barcode)
    location_status= Location.find_by_sql("select locations.location_status from locations
                                          where location_barcode='#{location_barcode}' and location_code like '%CA%' ")
    if !location_status.empty?
      location_status=location_status[0].location_status
      if location_status && location_status.upcase.index("SEALED")
        return  location_status
      elsif location_status && location_status.upcase.index("GAS")
        return  location_status
      else
        return nil
      end
    else
      return nil
    end
  end


  def Location.get_spaces_in_location(location,scanned_bins)
    spaces_left = ActiveRecord::Base.connection.select_one("
                        select
                        l.location_maximum_units - (COALESCE(l.units_in_location,0) + COALESCE(bpp.qty_bins_to_putaway,0)) as spaces_left
                        from  locations l
                        left join bin_putaway_plans bpp on bpp.putaway_location_id = l.id and bpp.completed is not true
                        where l.location_code = '#{location}'
                                      ")['spaces_left'] if location
    if scanned_bins==1
      #spaces_left = spaces_left.to_i - 1
    else
      spaces_left = spaces_left.to_i - scanned_bins
    end

    return spaces_left.to_i
    return nil if !spaces_left
  end


  #def before_update
  #  location_status=Location.find(self.id).location_status
  #  if location_status != "OPEN" && self.location_status == "OPEN"
  #    sql="update bins set sealed_ca_open_date_time='#{Time.now.to_formatted_s(:db)}' where bins.id in (
  #    select  b.id from bins b join stock_items si on si.inventory_reference=b.bin_number  where si.location_id=#{self.id} and b.sealed_ca_location_id=#{self.id} and sealed_ca_open_date_time is null AND (destroyed = false or destroyed is null))"
  #    ActiveRecord::Base.connection.execute(sql)
  #  end
  #end

  def Location.bin_age(location)
    age=Location.find_by_sql("
    select MIN(bins.created_on) as age
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join farms on bins.farm_id=farms.id
    where locations.location_code='#{location['location_code']}' and  farms.farm_code='#{location['farm_code']}'
    ")
    return age[0]['age']
  end



  def sync_units_in_location(stock_ids, trans_type, bus_context, inv_trans_id)

    n_pallets = ActiveRecord::Base.connection.select_one("select count(*) from pallets join
                                             stock_items on stock_items.inventory_reference = pallets.pallet_number
                                              WHERE (stock_items.destroyed is null OR stock_items.destroyed = false) AND stock_items.location_code = '#{self.location_code}'")['count'].to_i

    n_bins = ActiveRecord::Base.connection.select_one("select count(*) from bins join
                                             stock_items on stock_items.inventory_reference = bins.bin_number
                                              WHERE (stock_items.destroyed is null OR stock_items.destroyed = false) AND  stock_items.location_code = '#{self.location_code}'")['count'].to_i


    n_actual_units = n_bins + n_pallets

    if n_actual_units != self.units_in_location
      orig_units = self.units_in_location
      self.units_in_location = n_actual_units
      self.update
      InventoryLocationSyncLog.create({:trans_business_name => bus_context, :inv_trans_id => inv_trans_id, :trans_type => trans_type, :n_actual_bins => n_bins,
                                       :n_actual_pallets => n_pallets, :units_in_location_before => orig_units, :units_in_location_after => n_actual_units,
                                       :correction_made => true, :stock_ids => stock_ids.join(",")})
      return [orig_units, self.units_in_location]

    end

    InventoryLocationSyncLog.create({:trans_business_name => bus_context, :inv_trans_id => inv_trans_id, :trans_type => trans_type, :n_actual_bins => n_bins,
                                     :n_actual_pallets => n_pallets, :units_in_location_before => self.units_in_location, :units_in_location_after => n_actual_units,
                                     :correction_made => false, :stock_ids => stock_ids.join(",")})
    return nil

  end



#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true

    #if is_valid
    # is_valid = ModelHelper::Validations.validate_combos([{:facility_code => self.facility_code}],self)
    #end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_facility
    end

    if is_valid
      is_valid = set_location_type_code
    end
  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_facility

#	facility = Facility.find_by_facility_code(self.facility_code)
#	 if facility != nil
#		 self.facility = facility
#		 return true
#	 else
#		errors.add_to_base("Field: facility_code' and 'id'  is invalid- it must be unique")
#		 return false
#	end
  end

  def Location.create_new_ripe_point_code(cold_store_type_id, new_treatment2_code, ripe_code, product)

    if  cold_store_type_id == ""
      cold_store_type_id = nil
    end
    if  new_treatment2_code == ""
      new_treatment2_code = nil
    end
    new_ripe_point_code =nil
    new_rmt_product_code = nil
    new_rmt_product_id=nil
    if   cold_store_type_id !=nil && new_treatment2_code != nil
      new_coldstore_type_code=ColdStoreType.find("#{cold_store_type_id}").cold_store_type_code.to_s
      existing_ripe_code =ripe_code

      new_ripe_point_code =RipePoint.find_by_sql("select * FROM  ripe_points WHERE treatment2_code='#{new_treatment2_code}' AND
                                              cold_store_type_code ='#{new_coldstore_type_code}' AND ripe_code='#{existing_ripe_code}'")
      if !new_ripe_point_code.empty?
        new_ripe_point_code = new_ripe_point_code[0]['ripe_point_code']
      else
        new_ripe_point_code=nil
      end
      new_rmt_products = RmtProduct.find_by_sql("select * FROM rmt_products WHERE
                                             commodity_code='#{product['commodity_code']}' AND
                                             variety_code='#{product['variety_code']}' AND
                                             size_code='#{product['size_code']}' AND
                                             product_class_code='#{product['product_class_code']}' AND
                                             treatment_code='#{product['treatment_code']}' AND
                                             ripe_point_code ='#{new_ripe_point_code}'")


      if !new_rmt_products.empty?
        new_rmt_product =new_rmt_products[0]
        new_rmt_product_code = new_rmt_product.rmt_product_code
        new_rmt_product_id= new_rmt_product.rmt_product_id
      end
    end
    result = Hash.new
    result['new_ripe_point_code']=new_ripe_point_code
    result['new_rmt_product_code']= new_rmt_product_code
    result['new_rmt_product']=new_rmt_product
    result['new_rmt_product_id']=new_rmt_product_id

    return result

  end

  def extract_bin_numbers(bins, rmt_product_id=nil)
    non_sealed_bin_nums = []
    sealed_bin_nums=[]
    all_bins=[]
     bins.each do |bin|
          if bin.sealed_ca_location_id
            sealed_bin_nums << "#{bin.bin_number}".to_s
            all_bins << "#{bin.bin_number}".to_s
          else
            non_sealed_bin_nums << "#{bin.bin_number}".to_s
            all_bins << "#{bin.bin_number}".to_s
          end
    end
    return {"non_sealed_bin_nums" => non_sealed_bin_nums, "sealed_bin_nums" => sealed_bin_nums, "all_bins" => all_bins}
  end

  def update_bins(new_status_code, bin_numbers, status_changed_date_time, new_rmt_product_id=nil)
    coldstore_type="CA"
    set_map = {}
    sealed_bins_set_map = {}


    if  new_rmt_product_id
      set_map = {:rmt_product_id => "'#{new_rmt_product_id}'"}
    end

    sealed_ca_date_time=Time.now.to_formatted_s(:db)
    if new_status_code.upcase.include?("SEALED")
      set_map.store("sealed_ca_location_id", self.id)
      set_map.store("sealed_ca_date_time", "'#{sealed_ca_date_time}'")
      set_map.store("coldstore_type", "'#{coldstore_type}'")
    elsif  new_status_code.upcase.include?("OPEN")
      set_map.store("sealed_ca_open_date_time", "'#{status_changed_date_time}'")
      #sealed_bins_set_map.store("sealed_ca_open_date_time", "'#{status_changed_date_time}'")
    end
    Bin.bulk_update(set_map, 'bin_number', bin_numbers['all_bins'], nil) if !bin_numbers['all_bins'].empty? && !set_map.empty?
    # Bin.bulk_update(set_map, 'bin_number', bin_numbers['non_sealed_bin_nums'], nil) if !bin_numbers['non_sealed_bin_nums'].empty? && !set_map.empty?
    # Bin.bulk_update(sealed_bins_set_map, 'bin_number', bin_numbers['sealed_bin_nums'], nil) if !bin_numbers['sealed_bin_nums'].empty? && !sealed_bins_set_map.empty?
  end

  def change_status(bins, rebins, rmt_products, new_status_code, user, status_changed_date_time)
    begin
      ActiveRecord::Base.transaction do

        if rmt_products !=nil
          rmt_products.each do |rmt_product|
            rmt_product_bins=bins.find_all{|u|u['rmt_product_id'].to_i==rmt_product['id'].to_i}
            bin_numbers =extract_bin_numbers(rmt_product_bins)
            #bin_numbers =extract_bin_numbers(bins, rmt_product['id'])
            if  rmt_product['new_rmt_product_id']!=nil && (rmt_product['new_rmt_product_id']!= rmt_product['id'])
              update_bins(new_status_code, bin_numbers, status_changed_date_time, rmt_product['new_rmt_product_id'])
            else
              update_bins(new_status_code, bin_numbers, status_changed_date_time)
            end
          end
        else
          bin_numbers =extract_bin_numbers(bins)
          update_bins(new_status_code, bin_numbers, status_changed_date_time)
        end
        StatusMan.set_status(new_status_code, self.location_type_code, self, user.user_name)
        return nil

      end
    rescue
      return $!.to_s
    end
  end


  def set_location_type_code
    if self.location_type_code != ""
      errors.add_to_base("Field: Location_type_code is required. must be selected!")
      return false
    else
      return true
    end
  end






end
