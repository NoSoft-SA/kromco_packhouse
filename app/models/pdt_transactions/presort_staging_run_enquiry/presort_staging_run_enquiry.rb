class PresortStagingRunEnquiry < PDTTransaction
  attr_accessor :presort_staging_run_id

  def build_default_screen
    active_run= PresortStagingRun.find_by_sql("select distinct  p.*,ripe_points.ripe_point_code,    pcs.product_class_code ,tm.treatment_code,sizes.size_code,
     s.season_code ,fg.farm_group_code,r.rmt_variety_code,t.track_slms_indicator_code,farms.farm_code,pc.farm_id
     from presort_staging_runs p
     LEFT join presort_staging_run_children pc on pc.presort_staging_run_id=p.id AND pc.status='ACTIVE'
     LEFT join seasons s on p.season_id=s.id
     LEFT join farm_groups fg on p.farm_group_id=fg.id
     LEFT join rmt_varieties r on p.rmt_variety_id=r.id
     LEFT join track_slms_indicators t on p.track_slms_indicator_id=t.id
     LEFT join ripe_points on p.ripe_point_id=ripe_points.id
     LEFT join farms on pc.farm_id=farms.id
     LEFT join product_classes pcs on p.product_class_id=pcs.id
     LEFT join  treatments tm on p.treatment_id=tm.id
     LEFT join  sizes on p.size_id=sizes.id
     where p.status='ACTIVE' ")
    if !active_run.empty?
      active_run=active_run[0]
      class_treatment_size_filter=PresortStagingRun.get_class_treatment_size_filter(active_run)
      locations_sql= "select
      COUNT(bins.bin_number) as qty_bins_available,
      locations.location_code,MIN(bins.created_on) as age,farms.farm_code
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
      LEFT join product_classes pc on rmt_products.product_class_id=pc.id
      LEFT join  treatments tm on rmt_products.treatment_id=tm.id
      LEFT join  sizes on rmt_products.size_id=sizes.id
      where   ripe_points.id=#{active_run.ripe_point_id} and    ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND
      bins.presort_staging_run_child_id is null and seasons.id=#{active_run.season_id} and farm_groups.id =#{active_run.farm_group_id} and stock_items.stock_type_code in ('BIN','PRESORT')
      and rmt_varieties.id=#{active_run.rmt_variety_id} and track_slms_indicators.id=#{active_run.track_slms_indicator_id} and (destroyed = false or destroyed is null)
      and bins.farm_id= #{active_run.farm_id}    #{class_treatment_size_filter['treatment_filter']} #{class_treatment_size_filter['product_class_filter']} #{class_treatment_size_filter['size_filter']}
      group by   farms.farm_code,locations.location_code order by MIN(bins.created_on) asc limit 30"
      locations_available= ActiveRecord::Base.connection.select_all("#{locations_sql}")
    end
    field_configs = Array.new
    field_configs[field_configs.length] = {:type => "text_line", :name => "presort_run_code", :value => active_run.presort_run_code.upcase.to_s + ":"}
    field_configs[field_configs.length] = {:type => "static_text", :name => "season_code", :value => active_run.season_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "rmt_variety_code", :value => active_run.rmt_variety_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "ripe_point_code", :value => active_run.ripe_point_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "track_slms_indicator_code", :value => active_run.track_slms_indicator_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "farm_group_code", :value => active_run.farm_group_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "product_class_code", :value => active_run.product_class_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "treatment_code", :value => active_run.treatment_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "size_code", :value => active_run.size_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "active_farm_code", :value => active_run.farm_code}
    field_configs[field_configs.length] = {:type => "static_text", :name => "LOCATIONS", :value => "QTY BINS AVAILABLE"}
    locations_available = locations_available.sort_by { |p| "#{p.age}#{p.age}" }
    if !locations_available.empty?
      locations_available.each do |location|
        field_configs[field_configs.length] = {:type => "static_text", :name => "#{location.location_code}" + "#{location.farm_code}", :value => location.qty_bins_available.to_s + "    " + "(" + location.age.to_s + ")"}
      end
    end
    screen_attributes = {:auto_submit => "false", :content_header_caption => "active presort_staging_run_enquiry", :current_menu_item => "2.2.7"}
    buttons = {"B3Label" => "", "B2Label" => "refresh", "B2Submit" => "presort_staging_run_enquiry", "B1Submit" => "", "B1Label" => "", "B1Enable" => "false", "B2Enable" => "true", "B3Enable" => "false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def presort_staging_run_enquiry
    build_default_screen
  end


end