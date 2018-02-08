class Delivery < ActiveRecord::Base
	attr_accessor :treatment_code, :ripe_code, :advised_ripe_point_code, :ripe_point_code, :advised_rmt_product_code, :rmt_product_type_code, :representative_orchard
#	===========================
# 	Association declarations:
#	===========================
    belongs_to :farm
    belongs_to :rmt_product
    has_many :delivery_sample_bins
    belongs_to :rmt_variety
    has_many :delivery_route_steps
    belongs_to :season
    belongs_to :pack_material_product
    has_many :mrl_labels
    has_many :delivery_track_indicators
    has_many :bins
    has_many :delivery_scans,:dependent => :destroy
    has_many :delivery_bin_scans,:dependent => :destroy
    belongs_to :orchard

#	==========================
#	 Validations declarations:
#	============================

  def before_save
    changed_fields?
    # if(@changed_fields && @changed_fields.keys.include?('rmt_product_id') && ((bins = Bin.find_all_by_delivery_id(self.id)).length>0))
    #   raise "sorry cannot change rmt_product of this delivery , #{bins.length} bin(s) have already been scanned for this delivery"
    # end
  end

  def before_create
    validate
  end

  def after_create
    self.updated_at = Time.now
    create_route_steps
    generate_sample_bins
  end

  def after_save
    set_bins_rmt_product
  end

  def self.do_mrl_test_for_commodity(commodity_code)
    commodity = Commodity.find_by_commodity_code(commodity_code)
    if(commodity && commodity.grower_commitment_required)
      return true
    end
    return false
  end

  def create_route_steps
    route_step_type = RouteStepType.find_by_route_step_type_code("rmt_delivery")
    route_steps = route_step_type.route_steps

    if(route_steps && !DeliveryRouteStep.find_by_delivery_id(self.id))
      grower_commitment_season = Season.find(self.season_id)
      grower_commitment_record = GrowerCommitment.find_by_sql("select grower_commitments.* from grower_commitments join spray_program_results on spray_program_results.grower_commitment_id=grower_commitments.id where grower_commitments.farm_id=#{self.farm_id} and grower_commitments.season='#{grower_commitment_season.season}' and spray_program_results.rmt_variety_code='#{self.rmt_variety_code}' ")[0] if (grower_commitment_season)
      for route_step in route_steps
        delivery_route_step = DeliveryRouteStep.new
        delivery_route_step.route_step_code = route_step.route_step_code
        delivery_route_step.route_step_id = route_step.id
        delivery_route_step.delivery_number = self.delivery_number
        delivery_route_step.delivery_id = self.id
        if (delivery_route_step.route_step_code == "grower_commitment_data_captured" && grower_commitment_record)
          delivery_route_step.date_activated = grower_commitment_record.grower_commitment_data_capture_date_time
          delivery_route_step.date_completed = grower_commitment_record.grower_commitment_data_capture_date_time
          Delivery.update(self.id, {:delivery_status => delivery_route_step.route_step_code})
        elsif (delivery_route_step.route_step_code == "mrl_data_capture_completed" && grower_commitment_record)
          delivery_route_step.date_activated = grower_commitment_record.mrl_data_capture_date_time
          delivery_route_step.date_completed = grower_commitment_record.mrl_data_capture_date_time
          Delivery.update(self.id, {:delivery_status => delivery_route_step.route_step_code})
        end
        delivery_route_step.save
      end
    end
  end

  def generate_sample_bins
    sample_percentage = RmtVariety.find_by_rmt_variety_code_and_commodity_code(self.rmt_variety_code, self.commodity_code).sample_percentage
    if sample_percentage || self.commodity_code == "PL"
      quantity_full_bins = self.quantity_full_bins
      if (self.commodity_code == "PL")
        array = Array.new
        (1..quantity_full_bins).each do |x|
          array.push x
        end
      else
        sample_size = (sample_percentage.to_f / 100) * quantity_full_bins
        size = sample_size.round
        size = 1 if (size < 1)
        array = RandomGenerator.new(size, quantity_full_bins).generate_sequence_numbers
      end

      if array.length()!=0
        array.each do |number|
          delivery_sample_bin = DeliverySampleBin.new
          delivery_sample_bin.sample_bin_sequence_number = number
          delivery_sample_bin.delivery_id = self.id
          delivery_sample_bin.save
        end
      end
    end
  end

  def set_bins_rmt_product
    intake_bin_scanning=DeliveryRouteStep.find_by_delivery_id_and_route_step_code(self.id, 'intake_bin_scanning')
    if(intake_bin_scanning && (intake_bin_scanning.date_activated && !intake_bin_scanning.date_completed))
      raise "cannot update delivery: intake_bin_scanning in progress"
    end

    if(self.rmt_product_id && (Bin.find(:first, :conditions=>"delivery_id=#{self.id} and (rmt_product_id is null or rmt_product_id<>#{self.rmt_product_id})")))
      self.connection.execute("update bins set rmt_product_id=#{self.rmt_product_id} where delivery_id=#{self.id}")
    end
  end

   def self.delivery_mrl_passed?(delivery_id)

#     delivery_route_step = DeliveryRouteStep.find_by_sql("select *  from  delivery_route_steps  where delivery_id = #{delivery_id.to_s} and (route_step_code='mrl_data_capture_completed') order by id asc")[0]
#     if !delivery_route_step.date_completed
#       return "MRL NOT DONE OR FAILED"
#     else
#       return nil
#     end

    delivery = Delivery.find(delivery_id)

    return nil if(!Delivery.do_mrl_test_for_commodity(delivery.commodity_code))

    grower_commitment_season = Season.find(delivery.season_id)
    return mrl_passed_for_grower_commitment?(delivery.farm_code,grower_commitment_season.season,delivery.rmt_variety_code)
   end

  def self.delivery_mrl_passed_for_tripsheet?(tripsheet)
    delivery_route_steps_ary = ["MRL ERROR for bins:"]
    tripsheet_bins_deliveries = Delivery.find_by_sql("select distinct(deliveries.id)
                                from deliveries
                                inner join bins on bins.delivery_id=deliveries.id
                                inner join vehicle_job_units on vehicle_job_units.unit_reference_id= bins.bin_number
                                inner join vehicle_jobs  on vehicle_job_units.vehicle_job_id = vehicle_jobs.id
                                where vehicle_jobs.vehicle_job_number = '#{tripsheet}'")
    tripsheet_bins_deliveries.each do |delivery|
      error = delivery_mrl_passed?(delivery.id)
      if(error)
        failed_bins = Bin.find_by_sql("select bins.bin_number
                                from bins
                                inner join deliveries on bins.delivery_id=deliveries.id
                                inner join vehicle_job_units on vehicle_job_units.unit_reference_id= bins.bin_number
                                inner join vehicle_jobs  on vehicle_job_units.vehicle_job_id = vehicle_jobs.id
                                where vehicle_jobs.vehicle_job_number = '#{tripsheet}' and deliveries.id=#{delivery.id}
                      ")
        delivery_route_steps_ary += failed_bins.map{|b|[b.bin_number]}
        delivery_route_steps_ary += error
        return  delivery_route_steps_ary
      end
    end
    return nil
  end

  def self.mrl_passed_for_load_pallet?(farm_code,season,rmt_variety_code,commodity_code)
    return nil if(!Delivery.do_mrl_test_for_commodity(commodity_code))
    return mrl_passed_for_grower_commitment?(farm_code,season,rmt_variety_code)
  end

  def self.mrl_passed_for_grower_commitment?(farm_code,season,rmt_variety_code)
    farm = Farm.find_by_farm_code(farm_code)
    grower_commitment = GrowerCommitment.find_by_sql("select grower_commitments.*
    from grower_commitments join spray_program_results on grower_commitments.id=spray_program_results.grower_commitment_id
    where grower_commitments.farm_id=#{farm.id} and grower_commitments.season='#{season}'
     and spray_program_results.rmt_variety_code='#{rmt_variety_code}' and spray_program_results.cancelled is not true
    order by id asc ")[0]

    return ["MRL FAILED. ROEP VOORMAN - GIFTIGE VRUGTE:","no grower_commitment[#{farm_code},#{season},#{rmt_variety_code}]"] if(!grower_commitment)

    spray_program_results = SprayProgramResult.find_by_sql("select spray_program_results.*
                            from spray_program_results
                            where spray_program_results.grower_commitment_id=#{grower_commitment.id}
                            and spray_program_results.cancelled is not true")

    return ["MRL FAILED. ROEP VOORMAN - GIFTIGE VRUGTE:","no spray_program_results for grower_commitment"] if(spray_program_results.length == 0)

    spray_program_results.each do |spray_program_result|
      if(spray_program_result.rmt_variety_code == rmt_variety_code)
        if(spray_program_result.spray_result.upcase == "FAILED")
          return ["MRL FAILED. ROEP VOORMAN - GIFTIGE VRUGTE:","spray_program_result[#{spray_program_result.rmt_variety_code} - (#{farm_code},#{season})] has failed"]
        else
          return ["MRL FAILED. ROEP VOORMAN - GIFTIGE VRUGTE:","no mrl_results for spray_program_result[#{spray_program_result.rmt_variety_code} - (#{farm_code},#{season})]"] if(spray_program_result.mrl_results.length == 0)
          spray_program_result.mrl_results.each do |mrl_result|
            return ["MRL FAILED. ROEP VOORMAN - GIFTIGE VRUGTE:","mrl_result[#{mrl_result.sample_no}] for spray_program_result[#{spray_program_result.rmt_variety_code}] has failed"] if(mrl_result.mrl_result.upcase == "FAILED")
          end
        end
      end
    end

    return nil
  end


  #validates_presence_of :rmt_product_id

  def set_virtual_attributes
    if(self.rmt_product_id)
      rmt_product = RmtProduct.find(self.rmt_product_id)
      if rmt_product
        self.treatment_code = rmt_product.treatment_code
        self.ripe_point_code = rmt_product.ripe_point_code
        self.rmt_product_type_code = rmt_product.rmt_product_type_code
      end
      
      ripe_point = RipePoint.find_by_ripe_point_code(self.ripe_point_code)
      if(ripe_point)
        self.ripe_code = ripe_point.ripe_code
#        self.treatment_code = ripe_point.treatment_code
      end
    end
  end


  def delivery_process_at_completion?

    weighing_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("sample_bin_weigh_completed",self.id)
    if weighing_step && weighing_step.date_completed
       accepted_at_complex_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("accepted_at_complex",self.id)
      if accepted_at_complex_step && ! accepted_at_complex_step.date_completed
          return true
      end
    end

    return false

  end

    #MM112014 - remove validates_presence_of :orchard_code and add validates_presence_of :orchard_id
    validates_presence_of :farm_code, :pick_team, :orchard_id, :commodity_code, :rmt_variety_code
    validates_presence_of :delivery_number_preprinted, :truck_registration_number, :pack_material_product_code
    validates_uniqueness_of :delivery_number_preprinted
    validates_presence_of :season_code, :quantity_full_bins #, :quantity_partial_units, :quantity_empty_units, :quantity_damaged_units



	#validates_numericality_of :quantity_partial_units
	validates_numericality_of :quantity_full_bins
	#validates_numericality_of :delivery_number_preprinted
	#validates_numericality_of :quantity_damaged_units
	#validates_numericality_of :load_number
	#validates_numericality_of :quantity_empty_units
#	=====================
#	 Complex validations:
#	=====================
def validate
	#first check whether combo fields have been selected
	 is_valid = true

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}],self)
	 end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self)
	 end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:rmt_variety_code => self.rmt_variety_code}],self)
	 end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self)
	 end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:season_code => self.season_code}],self)
	 end

	 #now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm
	 end

	 if is_valid
		 is_valid = set_rmt_variety
	 end

	 if is_valid
		 is_valid = set_pack_material_product
	 end

	 if is_valid
		 is_valid = set_season
	 end

	#validates uniqueness for this record
#	 if self.new_record? && is_valid
#		 validate_uniqueness
#	 end
end

#def validate_uniqueness
#	 exists = Delivery.find_by_puc_code(self.puc_code)
#	 if exists != nil
#		errors.add_to_base("There already exists a record with the combined values of fields: 'puc_code' ")
#	end
#end
#	===========================
#	 foreign key validations:
#	===========================

def set_farm
    farm = Farm.find_by_farm_code(self.farm_code)
    if farm!=nil
        self.farm = farm
        return true
    else
        errors.add_to_base("combination of: 'farm_code'  is invalid- it must be unique")
    end
end

def set_rmt_variety
    rmt_variety = RmtVariety.find_by_rmt_variety_code(self.rmt_variety_code)
    if rmt_variety != nil
        self.rmt_variety = rmt_variety
        return true
    else
        errors.add_to_base("combination of: 'rmt_variety_code'  is invalid- it must be unique")
        return false
    end
end

def set_pack_material_product
    pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
    if pack_material_product != nil
        self.pack_material_product = pack_material_product
        return true
    else
        errors.add_to_base("combination of: 'pack_material_product_code'  is invalid- it must be unique")
        return false
    end
end

def set_season
    season = Season.find_by_season_code(self.season_code)
    if season != nil
        self.season = season
        return true
    else
        errors.add_to_base("combination of: 'season_code'  is invalid- it must be unique")
        return false
    end
end

#	===========================
#	 lookup methods:
#	===========================

def self.get_unit_type_codes
    query = "SELECT public.pack_material_products.pack_material_product_code FROM
            public.pack_material_sub_types
            INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
            INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
            WHERE (public.pack_material_types.pack_material_type_code = 'RMU')"

    return PackMaterialProduct.find_by_sql(query).map{|g|[g.pack_material_product_code]}
end

  def Delivery.pressure_rule1(grp5_qty, groups)
    if(grp5_qty > 9)
      return groups[4]
    end
    return nil
  end

  def Delivery.pressure_rule2(grp1_qty, groups)
    if(grp1_qty > 10)
      return groups[0]
    end
    return nil
  end

  def Delivery.pressure_rule3(summarised_pressure_readings, groups)
    cumul_total = 0
    index = 0
    summarised_pressure_readings.length.times do
      cumul_total += summarised_pressure_readings[index]
      if(cumul_total > 22)
        return groups[index]
      end
      index += 1
    end
    return nil
  end

  def Delivery.calc_pressure_indicator(pressure_reading_qtys, groups)
    if(grp5 = Delivery.pressure_rule1(pressure_reading_qtys[4], groups))
      return grp5
    elsif(grp1 = Delivery.pressure_rule2(pressure_reading_qtys[0], groups))
      return grp1
    else
      return Delivery.pressure_rule3(pressure_reading_qtys, groups)
    end
  end

end
