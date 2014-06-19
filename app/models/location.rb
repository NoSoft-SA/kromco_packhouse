class Location < ActiveRecord::Base

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
  
  def before_update
    location_status=Location.find(self.id).location_status
    if location_status != "OPEN"  && self.location_status == "OPEN"
      sql="update bins set sealed_ca_open_date_time='#{Time.now.to_formatted_s(:db)}' where bins.id in (
      select  b.id from bins b join stock_items si on si.inventory_reference=b.bin_number  where si.location_id=#{self.id} and b.sealed_ca_location_id=#{self.id} and sealed_ca_open_date_time is null AND (destroyed = false or destroyed is null))"
      ActiveRecord::Base.connection.execute(sql)
    end
  end  

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

    

    def sync_units_in_location(stock_ids, trans_type,bus_context,inv_trans_id)

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
        InventoryLocationSyncLog.create({:trans_business_name => bus_context,:inv_trans_id => inv_trans_id,:trans_type => trans_type,:n_actual_bins => n_bins,
                                         :n_actual_pallets =>n_pallets,:units_in_location_before => orig_units,:units_in_location_after => n_actual_units,
                                         :correction_made => true,:stock_ids =>stock_ids.join(",")})
        return [orig_units,self.units_in_location]

      end

      InventoryLocationSyncLog.create({:trans_business_name => bus_context,:inv_trans_id => inv_trans_id,:trans_type => trans_type,:n_actual_bins => n_bins,
                                       :n_actual_pallets =>n_pallets,:units_in_location_before => self.units_in_location,:units_in_location_after => n_actual_units,
                                       :correction_made => false,:stock_ids =>stock_ids.join(",")})
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

    if   cold_store_type_id !=nil && new_treatment2_code != nil
      new_coldstore_type_code=ColdStoreType.find("#{cold_store_type_id}").cold_store_type_code.to_s
      existing_ripe_code =ripe_code

      new_ripe_point_code =RipePoint.find_by_sql("select * FROM  ripe_points WHERE treatment2_code='#{new_treatment2_code}' AND
                                              cold_store_type_code ='#{new_coldstore_type_code}' AND ripe_code='#{existing_ripe_code}'")
      if !new_ripe_point_code.empty?
        @new_ripe_point_code = new_ripe_point_code[0]['ripe_point_code']
      else
        @new_ripe_point_code=nil
      end
      new_rmt_products = RmtProduct.find_by_sql("select * FROM rmt_products WHERE
                                             commodity_code='#{product['commodity_code']}' AND
                                             variety_code='#{product['variety_code']}' AND
                                             size_code='#{product['size_code']}' AND
                                             product_class_code='#{product['product_class_code']}' AND
                                             treatment_code='#{product['treatment_code']}' AND
                                             ripe_point_code ='#{@new_ripe_point_code}'")


      if !new_rmt_products.empty?
        new_rmt_product =new_rmt_products[0]
        @new_rmt_product_code = new_rmt_product.rmt_product_code
      else
        @new_rmt_product_code=nil
      end
    else
      @new_ripe_point_code =nil
      @new_rmt_product_code = nil
    end
    result = Hash.new
    result['new_ripe_point_code']=@new_ripe_point_code
    result['new_rmt_product_code']= @new_rmt_product_code
    result['new_rmt_product']=new_rmt_product

    return result

  end

  def change_status(bins, rebins, rmt_products, new_status_code, user)
    begin
      ActiveRecord::Base.transaction do

        count = 0
	coldstore_type="CA"
        if rmt_products !=nil
          for rmt_product in rmt_products
            if  rmt_product['new_rmt_product_id']!=nil && (rmt_product['new_rmt_product_id']!= rmt_product['id'])
              bin_nums = Array.new
              for bin in bins
                if bin.rmt_product_id == rmt_product['id']
                  count = count + 1
                  bin_nums << "#{bin.bin_number}".to_s
                end
              end
              set_map = {}
              sealed_ca_date_time=Time.now.to_formatted_s(:db)
              set_map = {:rmt_product_id => "'#{rmt_product['new_rmt_product_id']}'"}
              if new_status_code.upcase.include?("SEALED")
                set_map.store("sealed_ca_location_id", self.id)
                set_map.store("sealed_ca_date_time", "'#{sealed_ca_date_time}'")
		set_map.store("coldstore_type", "'#{coldstore_type}'")
              end
              Bin.bulk_update(set_map, 'bin_number', bin_nums, nil) if !bin_nums.empty? && !set_map.empty?
            else
              bin_nums = Array.new
              for bin in bins
                count = count + 1
                bin_nums << "#{bin.bin_number}".to_s
              end
              sealed_ca_date_time=Time.now.to_formatted_s(:db)
              set_map = {}
              if new_status_code.upcase.include?("SEALED")
                set_map.store("sealed_ca_location_id", self.id)
                set_map.store("sealed_ca_date_time", "'#{sealed_ca_date_time}'")
		set_map.store("coldstore_type", "'#{coldstore_type}'")	
              end
              Bin.bulk_update(set_map, 'bin_number', bin_nums, nil) if !bin_nums.empty? && !set_map.empty?
            end
          end
        else
          bin_nums = Array.new
          for bin in bins
            count = count + 1
            bin_nums << "#{bin.bin_number}".to_s
          end
          sealed_ca_date_time=Time.now.to_formatted_s(:db)
          set_map = {}
          if new_status_code.upcase.include?("SEALED")
            set_map.store("sealed_ca_location_id", self.id)
            set_map.store("sealed_ca_date_time", "'#{sealed_ca_date_time}'")
	    set_map.store("coldstore_type", "'#{coldstore_type}'")	    
          end
          Bin.bulk_update(set_map, 'bin_number', bin_nums, nil) if !bin_nums.empty? && !set_map.empty?
        end

        #-----------------updating rebins sealed_ca_location_id-------------------------
        if !rebins.empty?
          bin_numbers=Array.new
          for rebin in rebins
            bin_numbers << rebin.bin_number.to_s
          end
          sealed_ca_date_time=Time.now.to_formatted_s(:db)
          if new_status_code.upcase.include?("SEALED")
            count = count + 1
            Bin.bulk_update({:sealed_ca_location_id => "'#{self.id}'", :sealed_ca_date_time => "'#{sealed_ca_date_time}'",:coldstore_type => "'#{coldstore_type}'"}, 'bin_number', bin_numbers, nil) if !bin_numbers.empty? && !set_map.empty?
          end
        end
        #-------------------------------------------------------------------------------
        #if count==0 && new_status_code.upcase.include?("SEALED")
        #  return "BINS RMT CODE HAS NOT CHANGED THEREFORE CANNOT  CHANGE LOCATION STATUS !"
        #end
        StatusMan.set_status(new_status_code, self.location_type_code, self, user.user_name)

        return nil
        #        end

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
# 
##	===========================
##	 lookup methods:
##	===========================
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: facility_id
##	------------------------------------------------------------------------------------------
# 
#def self.get_all_facility_type_codes
#
#	facility_type_codes = Facility.find_by_sql('select distinct facility_type_code from facilities').map{|g|[g.facility_type_code]}
#end
#
#
#
#def self.get_all_facility_codes
#
#	facility_codes = Facility.find_by_sql('select distinct facility_code from facilities').map{|g|[g.facility_code]}
#end
#
#
#
#def self.facility_codes_for_facility_type_code(facility_type_code)
#
#	facility_codes = Facility.find_by_sql("Select distinct facility_code from facilities where facility_type_code = '#{facility_type_code}'").map{|g|[g.facility_code]}
#
#	facility_codes.unshift("<empty>")
# end
#
#
#
#def self.get_all_ids
#
#	ids = Facility.find_by_sql('select distinct id from facilities').map{|g|[g.id]}
#end
#
#
#
#def self.ids_for_facility_code_and_facility_type_code(facility_code, facility_type_code)
#
#	ids = Facility.find_by_sql("Select distinct id from facilities where facility_code = '#{facility_code}' and facility_type_code = '#{facility_type_code}'").map{|g|[g.id]}
#
#	ids.unshift("<empty>")
# end
#


end
