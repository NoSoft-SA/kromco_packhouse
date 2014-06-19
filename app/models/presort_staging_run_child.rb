class PresortStagingRunChild < ActiveRecord::Base
	
#	===========================
# 	Association declarations:
#	===========================
    belongs_to :presort_staging_run
    belongs_to :farm
    has_many :bins

#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
   def PresortStagingRunChild.active_chidren(parent_id)
     active_babies=PresortStagingRunChild.find_by_sql("select * from presort_staging_run_children
                   where presort_staging_run_id=#{parent_id} and status='ACTIVE'")
     return active_babies
   end

  def PresortStagingRunChild.editing_chidren(parent_id)
    editing_babies=PresortStagingRunChild.find_by_sql("select * from presort_staging_run_children
                   where presort_staging_run_id=#{parent_id} and status='EDITING'")
    return editing_babies
  end

  def PresortStagingRunChild.get_bins_per_location_farm(location_code,farm_code,season_id,rmt_variety_id,track_slms_indicator_id,farm_id,ripe_point_id)
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
    where locations.location_code='#{location_code}' and farms.farm_code='#{farm_code}' and  ripe_points.id=#{ripe_point_id} and
    seasons.id=#{season_id} and rmt_varieties.id=#{rmt_variety_id} and bins.track_indicator1_id=#{track_slms_indicator_id}
    and farms.id=#{farm_id} and bins.presort_staging_run_child_id is null and
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null and bins.delivery_id is not null
     "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end

  def PresortStagingRunChild.get_available_locations(season_id,rmt_variety_id,track_slms_indicator_id,farm_group_id,farm_id,ripe_point_id)
    list_query="
    select
    COUNT(bins.bin_number) as qty_bins_available,MIN(bins.created_on) as bin_age,
    farms.farm_code,
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
    where  ripe_points.id=#{ripe_point_id} and  ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND
    bins.presort_staging_run_child_id is null and seasons.id=#{season_id} and farm_groups.id =#{farm_group_id} and rmt_varieties.id=#{rmt_variety_id}
    and track_slms_indicators.id=#{track_slms_indicator_id}  and farms.id=#{farm_id}
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null and
     bins.delivery_id is not null
    group by   farms.farm_code,locations.location_code"
    locations= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [locations ,list_query]
  end

  def PresortStagingRunChild.bins_staged(child_id)
    list_query="
    select bins.*,ripe_points.ripe_point_code,
    --deliveries.delivery_number ,
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
    left join presort_staging_runs on bins.presort_staging_run_id=presort_staging_runs.id
    where   bins.presort_staging_run_child_id = #{child_id}
 "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]
  end


  def PresortStagingRunChild.get_bins_available(season_id,rmt_variety_id,track_slms_indicator_id,farm_group_id,farm_id,ripe_point_id)
    list_query="
    select bins.*, ripe_points.ripe_point_code,
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
    where   bins.presort_staging_run_child_id is null and   ripe_points.id=#{ripe_point_id} and ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%')  AND
    seasons.id=#{season_id} and farm_groups.id =#{farm_group_id} and rmt_varieties.id=#{rmt_variety_id} and bins.track_indicator1_id=#{track_slms_indicator_id} and farms.id=#{farm_id}
    and bins.exit_ref is null and bins.production_run_rebin_id is null and bins.bin_order_load_detail_id is null and
     bins.delivery_id is not null "
    bins= ActiveRecord::Base.connection.select_all("#{list_query}")
    return [bins ,list_query]

  end

  def before_save
    #if self.new_record?
    if self.status=='STAGED'
      self.completed_on =Time.now()
    end
    self.presort_staging_run_child_code =calc_presort_run_code  if  self.new_record?
    self.update
    #end
  end

  def calc_presort_run_code
    parent=PresortStagingRun.find(self.presort_staging_run_id)
    farm_code = Farm.find(self.farm_id).farm_code
    sequence_num=calc_sequence
    presort_staging_run_child_code=parent.presort_run_code.to_s + "_" +  farm_code.to_s + "_" +  sequence_num.to_s
    return presort_staging_run_child_code
  end

  def calc_sequence()
      seq=PresortStagingRun.find_by_sql("select count(*) from presort_staging_run_children where presort_staging_run_id=#{self.presort_staging_run_id}")[0]['count']
      sequence = seq.to_i + 1
    return sequence
  end

def validate 
#	first check whether combo fields have been selected
	 is_valid = true
   if is_valid
     is_valid = ModelHelper::Validations.validate_combos([{:farm_id => self.farm_id}],self)
   end
end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================



end
