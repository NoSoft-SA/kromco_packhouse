require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RmtProcessingPlugins
  class PresortStagingRunChildPlugin < ApplicationHelper::GridPlugin
    def initialize(env = nil, request = nil)
      @env = env
      @request = request
      @parent=PresortStagingRun.find(env.session.data[:active_doc]['presort_staging_run'])
      #calc_queries
    end

  def calc_queries

    @child_runs=PresortStagingRunChild.find_by_sql("select * from presort_staging_run_children ")
    bins_available=Bin.find_by_sql("
    select count( bins.bin_number) as bins_available,farms.id as farm_id,ripe_points.id as ripe_point_id,
    seasons.id as season_id,farm_groups.id as farm_group_id ,rmt_varieties.id as rmt_variety_id,track_slms_indicators.id as track_indicator1_id
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
    inner join presort_staging_runs on
    seasons.id=presort_staging_runs.season_id and farm_groups.id =presort_staging_runs.farm_group_id and  ripe_points.id=presort_staging_runs.ripe_point_id and
    rmt_varieties.id=presort_staging_runs.rmt_variety_id and track_slms_indicators.id=presort_staging_runs.track_slms_indicator_id
    where bins.presort_staging_run_child_id is null and  ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')
    group by farms.id , seasons.id ,farm_groups.id ,rmt_varieties.id,track_slms_indicators.id,ripe_points.id
    ")
    @bins_available=[]
    if !bins_available.empty?
     bins_available.group_by{|a|[a.farm_group_id,a.season_id,a.rmt_variety_id,a.track_indicator1_id,a.farm_id]}.map{|p|@bins_available << p[1][0]}
    end
    @available_locations=Location.find_by_sql("
    select
    locations.location_code,farms.id as farm_id, ripe_points.id as ripe_point_id,
    seasons.id as season_id,farm_groups.id as farm_group_id ,rmt_varieties.id as rmt_variety_id,track_slms_indicators.id as track_indicator1_id
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
    inner join presort_staging_runs on
    seasons.id=presort_staging_runs.season_id and farm_groups.id =presort_staging_runs.farm_group_id and  ripe_points.id=presort_staging_runs.ripe_point_id and
    rmt_varieties.id=presort_staging_runs.rmt_variety_id and bins.track_indicator1_id=presort_staging_runs.track_slms_indicator_id
     where bins.presort_staging_run_child_id is null and ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')
    group by   locations.location_code,farms.id,
    seasons.id ,farm_groups.id  ,rmt_varieties.id ,track_slms_indicators.id,ripe_points.id ")
    bins_staged=Bin.find_by_sql("
    select count( bins.bin_number) as bins_staged,farms.id as farm_id,bins.presort_staging_run_child_id,ripe_points.id as ripe_point_id,
    seasons.id as season_id,farm_groups.id as farm_group_id ,rmt_varieties.id as rmt_variety_id,track_slms_indicators.id as track_indicator1_id
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
    inner join presort_staging_runs on
    seasons.id=presort_staging_runs.season_id and farm_groups.id =presort_staging_runs.farm_group_id and ripe_points.id=presort_staging_runs.ripe_point_id and
    rmt_varieties.id=presort_staging_runs.rmt_variety_id and bins.track_indicator1_id=presort_staging_runs.track_slms_indicator_id
    where   bins.presort_staging_run_child_id is not null
    group by farms.id ,   seasons.id ,farm_groups.id  ,rmt_varieties.id,track_slms_indicators.id,bins.presort_staging_run_child_id,ripe_points.id " )
    @bins_staged=[]
    if !bins_staged.empty?
      bins_staged.group_by{|a|[a.farm_group_id,a.season_id,a.rmt_variety_id,a.track_indicator1_id,a.farm_id]}.map{|p| @bins_staged << p[1][0]}
    end
  end

    #def cancel_cell_rendering(column_name, cell_value, record)
    #  if column_name == "bins_available" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
    #    return true
    #  elsif column_name == "bins_available_locations" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
    #    return true
    #  elsif column_name == "bins_staged" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
    #    return true
    #  elsif column_name == "status" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
    #    return true
    #  else
    #    return false
    #  end
    #end

    #def render_cell(column_name, cell_value, record)
    #    if column_name=="bins_available"
    #      bins_available= @bins_available.find_all { |p|
    #                      (p.season_id.to_i == @parent.season_id.to_i &&
    #                      p.farm_group_id.to_i == @parent.farm_group_id.to_i &&
    #                      p.rmt_variety_id.to_i == @parent.rmt_variety_id.to_i &&
    #                      p.track_indicator1_id.to_i == @parent.track_slms_indicator_id.to_i &&
    #                      p.farm_id.to_i == record['farm_id'].to_i) &&
    #                      p.ripe_point_id.to_i == @parent.ripe_point_id.to_i}
    #      if  bins_available.empty?
    #        bins_available=0
    #      else
    #        bins_available=bins_available[0].bins_available
    #      end
    #      column_config = {:id_value      =>record['id'],
    #                       :link_text     =>bins_available,
    #                       :host_and_port =>@request.host_with_port.to_s,
    #                       :controller    => @request.path_parameters['controller'].to_s,
    #                       :target_action =>'bins_available'}
    #      popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
    #      return popup_link.build_control
    #    end
    #
    #    if column_name=="bins_available_locations"
    #     available_locations= @available_locations.find_all { |p|
    #        (p.season_id.to_i == @parent.season_id.to_i &&
    #            p.farm_group_id.to_i == @parent.farm_group_id.to_i &&
    #            p.rmt_variety_id.to_i == @parent.rmt_variety_id.to_i &&
    #            p.track_indicator1_id.to_i == @parent.track_slms_indicator_id.to_i &&
    #            p.farm_id.to_i == record['farm_id'].to_i) &&
    #            p.ripe_point_id.to_i == @parent.ripe_point_id.to_i}
    #      column_config = {:id_value      =>record['id'],
    #                       :link_text     =>available_locations.length,
    #                       :host_and_port =>@request.host_with_port.to_s,
    #                       :controller    => @request.path_parameters['controller'].to_s,
    #                       :target_action =>'bins_available_locations'}
    #      popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
    #      return popup_link.build_control
    #    end
    #
    #    if column_name=="bins_staged"
    #      bins_staged=@bins_staged.find_all { |p|
    #        (p.season_id.to_i == @parent['season_id'].to_i &&
    #            p.farm_group_id.to_i == @parent['farm_group_id'].to_i &&
    #            p.rmt_variety_id.to_i == @parent['rmt_variety_id'].to_i &&
    #            p.track_indicator1_id.to_i == @parent['track_slms_indicator_id'].to_i &&
    #            p.farm_id.to_i == record['farm_id'].to_i  &&
    #            p.presort_staging_run_child_id.to_i == record['id'].to_i)&&
    #            p.ripe_point_id.to_i == @parent.ripe_point_id.to_i}
    #      if  bins_staged.empty?
    #        bins_staged=0
    #      else
    #        bins_staged=bins_staged[0].bins_staged
    #      end
    #      column_config = {:id_value      =>record['id'],
    #                       :link_text     =>bins_staged,
    #                       :host_and_port =>@request.host_with_port.to_s,
    #                       :controller    => @request.path_parameters['controller'].to_s,
    #                       :target_action =>'show_bins_staged'}
    #      popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
    #      return popup_link.build_control
    #    end
    #
    #    if column_name == "status"
    #      column_config = {:id_value      =>record['id'],
    #                       :link_text     =>record['status'],
    #                       :host_and_port =>@request.host_with_port.to_s,
    #                       :controller    => @request.path_parameters['controller'].to_s,
    #                       :target_action =>'edit_child_status'}
    #      popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
    #      return popup_link.build_control
    #    end
    #  else
    #    if column_name=="bins_available"
    #    end
    #
    #    if column_name=="bins_available_locations"
    #
    #    end
    #
    #    if column_name=="bins_staged"
    #
    #    end
    #
    #    if column_name == "status"
    #
    #    end
    #  #end
    #end

    def before_cell_render_styling(column_name, cell_value, record)
      if column_name=="id"
      else
        return "<font color = 'light gray'>"  if record['status'].upcase =='CANCELLED'
        return "<font color = 'gray'>"  if record['status'].upcase =='STAGED'
        return "<font color = 'green'>"  if record['status'].upcase =='ACTIVE'
        return "<font color = 'red'>"  if record['status'].upcase =='EDITING'
      end
    end

  end
end