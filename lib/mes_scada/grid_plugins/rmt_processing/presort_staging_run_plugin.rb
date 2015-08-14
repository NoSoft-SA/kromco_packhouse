module MesScada::GridPlugins
  module RmtProcessing
    class PresortStagingRunPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
      @env = env
      @request = request
      #calc_queries
      end

      def calc_queries
        #@child_runs=PresortStagingRunChild.find_by_sql("select count(id) as child_runs,presort_staging_run_id  from presort_staging_run_children group by presort_staging_run_id ")
        @active_child_runs=PresortStagingRunChild.find_by_sql("select count(id) as child_runs,presort_staging_run_id  from presort_staging_run_children where status='ACTIVE' group by presort_staging_run_id")
        @editing_child_runs=PresortStagingRunChild.find_by_sql("select count(id) as child_runs,presort_staging_run_id from presort_staging_run_children where status='EDITING' group by presort_staging_run_id")
        @staged_child_runs=PresortStagingRunChild.find_by_sql("select count(id) as child_runs,presort_staging_run_id from presort_staging_run_children where status='STAGED' group by presort_staging_run_id")
        bins_available=Bin.find_by_sql("
        select count(bins.bin_number) as bins_available,ripe_points.id as ripe_point_id,
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
        where bins.presort_staging_run_id is null and   ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')
        group by seasons.id ,farm_groups.id ,rmt_varieties.id,track_slms_indicators.id,ripe_points.id
        ")
        @bins_available=[]
        if !bins_available.empty?
          bins_available.group_by{|a|[a.farm_group_id,a.season_id,a.rmt_variety_id,a.track_indicator1_id]}.map{|p|@bins_available << p[1][0]}
        end
         @available_locations=Location.find_by_sql("
        select
        locations.location_code, ripe_points.id as ripe_point_id,
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
        seasons.id=presort_staging_runs.season_id and farm_groups.id =presort_staging_runs.farm_group_id and   ripe_points.id=presort_staging_runs.ripe_point_id and
        rmt_varieties.id=presort_staging_runs.rmt_variety_id and bins.track_indicator1_id=presort_staging_runs.track_slms_indicator_id
        where bins.presort_staging_run_id is null and  ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')
        group by   locations.location_code,
        seasons.id ,farm_groups.id  ,rmt_varieties.id ,track_slms_indicators.id,ripe_points.id ")
        bins_staged=Bin.find_by_sql("
        select count(bins.bin_number) as bins_staged,ripe_points.id as ripe_point_id,
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
        seasons.id=presort_staging_runs.season_id and farm_groups.id =presort_staging_runs.farm_group_id and   ripe_points.id=presort_staging_runs.ripe_point_id and
        rmt_varieties.id=presort_staging_runs.rmt_variety_id and bins.track_indicator1_id=presort_staging_runs.track_slms_indicator_id
        where   bins.presort_staging_run_id is not null
        group by seasons.id ,farm_groups.id  ,rmt_varieties.id,track_slms_indicators.id,ripe_points.id " )

        @bins_staged=[]
        if !bins_staged.empty?
          bins_staged.group_by{|a|[a.farm_group_id,a.season_id,a.rmt_variety_id,a.track_indicator1_id]}.map{|p|@bins_staged  << p[1][0]}
        end
      end

      #def render_cell(column_name, cell_value, record)
      #  if column_name=="active_child_runs"
      #    active_child_runs=@active_child_runs.find_all { |p| p.presort_staging_run_id.to_i==record['id'].to_i }
      #    if  active_child_runs.empty?
      #      active_child_runs=0
      #    else
      #      active_child_runs=active_child_runs[0].child_runs
      #    end
      #    column_config = {:id_value      =>record['id'],
      #                     :link_text     =>active_child_runs,
      #                     :host_and_port =>@request.host_with_port.to_s,
      #                     :controller    => "rmt_processing/presort_staging_run_child",
      #                     :target_action =>'parent_active_child_runs'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name=="editing_child_runs"
      #   editing_child_runs=@editing_child_runs.find_all { |p| p.presort_staging_run_id.to_i==record['id'].to_i }
      #   if  editing_child_runs.empty?
      #     editing_child_runs=0
      #   else
      #     editing_child_runs=editing_child_runs[0].child_runs
      #     end
      #    column_config = {:id_value      =>record['id'],
      #                     :link_text     =>editing_child_runs,
      #                     :host_and_port =>@request.host_with_port.to_s,
      #                     :controller    => "rmt_processing/presort_staging_run_child",
      #                     :target_action =>'parent_editing_child_runs'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name=="staged_child_runs"
      #    staged_child_runs=@staged_child_runs.find_all { |p| p.presort_staging_run_id.to_i==record['id'].to_i }
      #    if  staged_child_runs.empty?
      #      staged_child_runs=0
      #    else
      #      staged_child_runs=staged_child_runs[0].child_runs
      #    end
      #    column_config = {:id_value      =>record['id'],
      #                     :link_text     =>staged_child_runs,
      #                     :host_and_port =>@request.host_with_port.to_s,
      #                     :controller    => "rmt_processing/presort_staging_run_child",
      #                     :target_action =>'parent_staged_child_runs'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name=="bins_available"
      #    bins_available=@bins_available.find_all { |p|
      #                    (p.season_id.to_i == record['season_id'].to_i &&
      #                     p.farm_group_id.to_i == record['farm_group_id'].to_i &&
      #                     p.rmt_variety_id.to_i == record['rmt_variety_id'].to_i &&
      #                     p.track_indicator1_id.to_i == record['track_slms_indicator_id'].to_i) &&
      #                     p.ripe_point_id.to_i == record.ripe_point_id.to_i}
      #    if  bins_available.empty?
      #      bins_available=0
      #    else
      #      bins_available=bins_available[0].bins_available
      #    end
      #    column_config = {:id_value      =>record['id'],
      #                      :link_text     =>bins_available,
      #                      :host_and_port =>@request.host_with_port.to_s,
      #                      :controller    => @request.path_parameters['controller'].to_s,
      #                      :target_action =>'bins_available'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name=="bins_available_locations"
      #     available_locations=@available_locations.find_all { |p|
      #                         (p.season_id.to_i == record['season_id'].to_i &&
      #                          p.farm_group_id.to_i == record['farm_group_id'].to_i &&
      #                          p.rmt_variety_id.to_i == record['rmt_variety_id'].to_i &&
      #                          p.track_indicator1_id.to_i == record['track_slms_indicator_id'].to_i) &&
      #                          p.ripe_point_id.to_i == record.ripe_point_id.to_i}
      #    column_config = {:id_value      =>record['id'],
      #                      :link_text     =>available_locations.length,
      #                      :host_and_port =>@request.host_with_port.to_s,
      #                      :controller    => @request.path_parameters['controller'].to_s,
      #                      :target_action =>'bins_available_locations'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name=="bins_staged"
      #    bins_staged=@bins_staged.find_all { |p|
      #                (p.season_id.to_i == record['season_id'].to_i &&
      #                 p.farm_group_id.to_i == record['farm_group_id'].to_i &&
      #                 p.rmt_variety_id.to_i == record['rmt_variety_id'].to_i &&
      #                 p.track_indicator1_id.to_i == record['track_slms_indicator_id'].to_i) &&
      #                 p.ripe_point_id.to_i == record.ripe_point_id.to_i}
      #    if  bins_staged.empty?
      #      bins_staged=0
      #    else
      #      bins_staged=bins_staged[0].bins_staged
      #    end
      #    column_config = {
      #                :id_value      =>record['id'],
      #                :link_text     => bins_staged,
      #                :host_and_port =>@request.host_with_port.to_s,
      #                :controller    => @request.path_parameters['controller'].to_s,
      #                :target_action =>'show_bins_staged'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #
      #  if column_name == "child_runs"
      #    child_runs=@child_runs.find_all { |p| p.presort_staging_run_id.to_i==record['id'].to_i }
      #    if  child_runs.empty?
      #      child_runs=0
      #    else
      #      child_runs=child_runs[0].child_runs
      #    end
      #    column_config = {:id_value      =>record['id'],
      #    :link_text     =>child_runs,
      #    :host_and_port =>@request.host_with_port.to_s,
      #    :controller    => "rmt_processing/presort_staging_run_child",
      #    :target_action =>'list_main_grid_run_children'}
      #    popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
      #    return popup_link.build_control
      #  end
      #end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def row_cell_colouring(record)
        return :lightgray  if record['status'].upcase =='CANCELLED'
        return :gray  if record['status'].upcase =='STAGED'
        return :green  if record['status'].upcase =='ACTIVE'
        return :red  if record['status'].upcase =='EDITING'
      end

    end
  end
end