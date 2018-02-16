class PresortStagingRun < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


	belongs_to :treatment
	belongs_to :size
	belongs_to :product_class
	belongs_to :track_slms_indicator
	belongs_to :farm_group
	belongs_to :season
	belongs_to :rmt_variety
	belongs_to :farm
	belongs_to :ripe_point
  has_many :presort_staging_run_children
  has_many :bins

  validates_presence_of :presort_unit

  def after_save
    if self.status=="STAGED"
      active_child=PresortStagingRunChild.find_by_presort_staging_run_id_and_status(self.id,"ACTIVE")
      child ={:list => [active_child.id],
              :child_new_status_code => self.status,
              :child_status_type => "presort_staging_run_child",
              :child_ar_class_name => "PresortStagingRunChild"}
      StatusMan.set_status(self.status,"presort_staging_run",self,ActiveRequest.get_active_request.user,nil,child,true)
    end
  end

  def PresortStagingRun.set_child_status(status,active_child,presort_staging_run,user)
    child ={:list => [ active_child.id],
            :child_new_status_code => status,
            :child_status_type => "presort_staging_run_child",
            :child_ar_class_name => "PresortStagingRunChild"}
    StatusMan.set_status(status,"presort_staging_run",presort_staging_run,user,nil,child,true)
  end

  def PresortStagingRun.new_child_run(farm_code,presort_staging_run,user)
    farm=Farm.find_by_farm_code(farm_code)
    presort_staging_run_child = PresortStagingRunChild.new({:farm_id=>farm.id,:created_by=>user})
    presort_staging_run_child.presort_staging_run_id=presort_staging_run.id
    presort_staging_run_child.save
    PresortStagingRun.set_child_status('ACTIVE',presort_staging_run_child,presort_staging_run,user)
  end

  def PresortStagingRun.new_activated_child(farm_code,user)
    active_child=PresortStagingRunChild.find_by_status("ACTIVE")
    presort_staging_run=PresortStagingRun.find(active_child.presort_staging_run_id)
    PresortStagingRun.set_child_status('STAGED',active_child,presort_staging_run,user)
    PresortStagingRun.new_child_run(farm_code,presort_staging_run,user)
  end

  def PresortStagingRun.get_bins_per_location_farm(location_code,farm_code,presort_run)
    class_treatment_size_filter=PresortStagingRun.get_class_treatment_size_filter(presort_run)
    list_query="
    select bins.*,ripe_points.ripe_point_code,pc.product_class_code ,tm.treatment_code,sizes.size_code,
    rmt_products.rmt_product_code,rmt_varieties.rmt_variety_code,
    farms.farm_code,
    track_slms_indicators.track_slms_indicator_code as indicator_code1,
    seasons.season_code,
    farm_groups.farm_group_code,
    commodities.commodity_code,
    locations.location_code
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    left  join product_classes pc on rmt_products.product_class_id=pc.id
    left  join  treatments tm on rmt_products.treatment_id=tm.id
    left  join  sizes on rmt_products.size_id=sizes.id
    where locations.location_code='#{location_code}' and farms.farm_code='#{farm_code}' and ripe_points.id=#{presort_run.ripe_point_id}    and
    seasons.id=#{presort_run.season_id} and rmt_varieties.id=#{presort_run.rmt_variety_id} and track_slms_indicators.id=#{presort_run.track_slms_indicator_id} and bins.presort_staging_run_child_id is null
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null   #{class_treatment_size_filter['treatment_filter']} #{class_treatment_size_filter['product_class_filter']} #{class_treatment_size_filter['size_filter']}
     "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end

  def PresortStagingRun.count_available_locations(presort_run)
    class_treatment_size_filter=PresortStagingRun.get_class_treatment_size_filter(presort_run)

    list_query="
    select
    locations.location_code
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    left  join product_classes pc on rmt_products.product_class_id=pc.id
    left  join  treatments tm on rmt_products.treatment_id=tm.id
    left  join  sizes on rmt_products.size_id=sizes.id
    where      ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND
    bins.presort_staging_run_child_id is null and seasons.id=#{presort_run.season_id} and farm_groups.id =#{presort_run.farm_group_id} and rmt_varieties.id=#{presort_run.rmt_variety_id} and track_slms_indicators.id=#{presort_run.track_slms_indicator_id} and ripe_points.id=#{presort_run.ripe_point_id}
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null   #{class_treatment_size_filter['treatment_filter']} #{class_treatment_size_filter['product_class_filter']} #{class_treatment_size_filter['size_filter']}
    group by   locations.location_code"
    locations= ActiveRecord::Base.connection.select_all("#{list_query}")
    return locations
  end

  def PresortStagingRun.get_available_locations(presort_staging_run)
    class_treatment_size_filter=PresortStagingRun.get_class_treatment_size_filter(presort_staging_run)

    list_query="
    select
    COUNT(bins.bin_number) as qty_bins_available,
    farms.farm_code,
    locations.location_code,MIN(bins.created_on) as age
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    --inner join deliveries on bins.delivery_id=deliveries.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    left  join product_classes pc on rmt_products.product_class_id=pc.id
    left  join  treatments tm on rmt_products.treatment_id=tm.id
    left  join  sizes on rmt_products.size_id=sizes.id
    where   ripe_points.id=#{presort_staging_run.ripe_point_id} and    ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND
    bins.presort_staging_run_child_id is null and seasons.id=#{presort_staging_run.season_id} and farm_groups.id =#{presort_staging_run.farm_group_id} and rmt_varieties.id=#{presort_staging_run.rmt_variety_id}
    and track_slms_indicators.id=#{presort_staging_run.track_slms_indicator_id}
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null   #{class_treatment_size_filter['treatment_filter']} #{class_treatment_size_filter['product_class_filter']} #{class_treatment_size_filter['size_filter']}
    group by   farms.farm_code,locations.location_code
    order by locations.location_code ASC"
    locations= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [locations ,list_query]
  end

  def PresortStagingRun.get_bins_available_for_live_staging(season_id,rmt_variety_id,track_slms_indicator_id,farm_group_id,ripe_point_id)
    list_query="
    select bins.*,ripe_points.ripe_point_code,
    --deliveries.delivery_number ,
    rmt_products.rmt_product_code,rmt_varieties.rmt_variety_code,
    farms.farm_code,
    track_slms_indicators.track_slms_indicator_code as indicator_code1,
    seasons.season_code,
    farm_groups.farm_group_code,
    commodities.commodity_code,
    locations.location_code
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    --inner join deliveries on bins.delivery_id=deliveries.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    where   ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND
    seasons.id=#{season_id} and farm_groups.id =#{farm_group_id} and rmt_varieties.id=#{rmt_variety_id} and track_slms_indicators.id=#{track_slms_indicator_id} and ripe_points.id=#{ripe_point_id} "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end

  def PresortStagingRun.get_class_treatment_size_filter(presort_run)
    class_treatment_size_filter={}
    class_treatment_size_filter['treatment_filter'] = presort_run.treatment_id ? " and rmt_products.treatment_id=#{presort_run.treatment_id}" : " and (true)"
    class_treatment_size_filter['product_class_filter']  = presort_run.product_class_id  ? " and rmt_products.product_class_id=#{presort_run.product_class_id}" : " and (true)"
    class_treatment_size_filter['size_filter']  = presort_run.size_id ? " and rmt_products.size_id=#{presort_run.size_id}" : " and (true)"

    return class_treatment_size_filter
  end

  def PresortStagingRun.get_bins_available(presort_run)
    class_treatment_size_filter=PresortStagingRun.get_class_treatment_size_filter(presort_run)
    list_query="
    select
    pc.product_class_code ,tm.treatment_code,sizes.size_code,
    bins.*,ripe_points.ripe_point_code,
    rmt_products.rmt_product_code,rmt_varieties.rmt_variety_code,
    farms.farm_code,
    track_slms_indicators.track_slms_indicator_code as indicator_code1,
    seasons.season_code,
    farm_groups.farm_group_code,
    commodities.commodity_code,
    locations.location_code
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    left  join product_classes pc on rmt_products.product_class_id=pc.id
    left  join  treatments tm on rmt_products.treatment_id=tm.id
    left  join  sizes on rmt_products.size_id=sizes.id
    where   bins.presort_staging_run_id is null and   ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')
    AND seasons.id=#{presort_run.season_id} and farm_groups.id =#{presort_run.farm_group_id} and rmt_varieties.id=#{presort_run.rmt_variety_id} and track_slms_indicators.id=#{presort_run.track_slms_indicator_id}
    and ripe_points.id=#{presort_run.ripe_point_id}     and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null    #{class_treatment_size_filter['treatment_filter']} #{class_treatment_size_filter['product_class_filter']} #{class_treatment_size_filter['size_filter']} "

    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end

  def PresortStagingRun.bins_staged(run_id)
    list_query="
    select bins.*,ripe_points.ripe_point_code,pc.product_class_code ,tm.treatment_code,sizes.size_code,
    deliveries.delivery_number ,
    rmt_products.rmt_product_code,rmt_varieties.rmt_variety_code,
    farms.farm_code,
    track_slms_indicators.track_slms_indicator_code as indicator_code1,
    presort_staging_runs.presort_run_code,
    seasons.season_code,
    farm_groups.farm_group_code,
    commodities.commodity_code,
    locations.location_code
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join deliveries on bins.delivery_id=deliveries.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    left join presort_staging_runs on bins.presort_staging_run_id=presort_staging_runs.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    left  join product_classes pc on rmt_products.product_class_id=pc.id
    left  join  treatments tm on rmt_products.treatment_id=tm.id
    left  join  sizes on rmt_products.size_id=sizes.id

    where   bins.presort_staging_run_id =#{run_id}
     "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end


  def before_save
    #if self.new_record?
      if self.status=='STAGED'
        self.completed_on =Time.now()
      end
      self.presort_run_code =calc_presort_run_code
      self.update
    #end
  end

  def calc_presort_run_code
    season_code=Season.find(self.season_id).season_code
    farm_group_code = FarmGroup.find(self.farm_group_id).farm_group_code
    rmt_variety_code=RmtVariety.find(self.rmt_variety_id).rmt_variety_code
    track_slms_indicator_code = TrackSlmsIndicator.find(self.track_slms_indicator_id).track_slms_indicator_code
    sequence_num=calc_sequence
    presort_run_code=season_code + "_" +  farm_group_code + "_" +  rmt_variety_code + "_" +  track_slms_indicator_code + "_" +  sequence_num.to_s
    return presort_run_code
  end

  def calc_sequence()
    if self.new_record?
     seq=PresortStagingRun.find_by_sql("select count(*) from presort_staging_runs where (season_id=#{self.season_id} and farm_group_id =#{self.farm_group_id} and rmt_variety_id=#{self.rmt_variety_id} and track_slms_indicator_id=#{self.track_slms_indicator_id})")[0]['count']
     sequence = seq.to_i + 1
    else
      sequence=self.presort_run_code.split("_").last
    end
     return sequence
  end


#	=====================
def validate
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:rmt_variety_id => self.rmt_variety_id}],self)
	end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:track_slms_indicator_id => self.track_slms_indicator_id}],self)
	end

	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_group_id => self.farm_group_id}],self)
	end


	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:season_id => self.season_id}],self)
	end
end


#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: track_slms_indicator_id
#	------------------------------------------------------------------------------------------

def self.get_all_track_slms_indicator_codes

	track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql('select distinct track_slms_indicator_code from track_slms_indicators').map{|g|[g.track_slms_indicator_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_group_id
#	------------------------------------------------------------------------------------------

def self.get_all_farm_group_codes

	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------

def self.get_all_season_codes

	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
end



def self.get_all_commodity_codes

	commodity_codes = Season.find_by_sql('select distinct commodity_code from seasons').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_season_code(season_code)

	commodity_codes = Season.find_by_sql("Select distinct commodity_code from seasons where season_code = '#{season_code}'").map{|g|[g.commodity_code]}

 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: rmt_variety_id
#	------------------------------------------------------------------------------------------

def self.get_all_commodity_codes

	commodity_codes = RmtVariety.find_by_sql('select distinct commodity_code from rmt_varieties').map{|g|[g.commodity_code]}
end



def self.get_all_rmt_variety_codes

	rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code from rmt_varieties').map{|g|[g.rmt_variety_code]}
end



def self.rmt_variety_codes_for_commodity_code(commodity_code)

	rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map{|g|[g.rmt_variety_code]}

 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_id
#	------------------------------------------------------------------------------------------

def self.get_all_farm_codes

	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
end






end
