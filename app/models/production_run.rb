class ProductionRun < ActiveRecord::Base


  belongs_to :production_schedule
  belongs_to :line
  belongs_to :shift
  belongs_to :farm_puc_account
  has_many :pack_groups, :dependent => :destroy
  has_one :run_bintip_criterium, :dependent => :destroy
  has_many :carton_links, :dependent => :destroy
  has_many :rebin_links, :dependent => :destroy
  has_many :active_carton_links, :dependent => :destroy
  has_many :active_rebin_links, :dependent => :destroy
  has_many :run_palletizing_criteria, :dependent => :destroy
  has_many :production_run_statuses, :dependent => :destroy
  has_many :active_devices, :dependent => :destroy
  has_many :production_run_stage_histories, :dependent => :destroy
  has_one :production_run_stat, :dependent => :destroy
  has_many :cartons
  belongs_to :ripe_point

  has_many :tipped_bins, :class_name => 'Bin', :foreign_key => 'production_run_tipped_id'
  has_many :rebins, :class_name => 'Bin', :foreign_key => 'production_run_rebin_id'

  attr_accessor :complete_entire_run, :is_cloning


  validates_presence_of :line_code


  def sync_run_stat
    if !ProductionRunStat.find_by_production_run_id(self.id)
      run_stats                     = ProductionRunStat.new
      run_stats.rebins_printed      = self.rebins_printed
      run_stats.rebins_weight       = self.rebins_weight
      run_stats.cartons_printed     = self.cartons_printed
      run_stats.cartons_weight      = self.cartons_weight
      run_stats.bins_tipped         = self.bins_tipped
      run_stats.bins_tipped_weight  = self.bins_tipped_weight
      run_stats.pallets_completed   = self.pallets_completed
      run_stats.production_run      = self
      run_stats.production_run_code = self.production_run_code

      run_stats.create

    end

  end


  #create an instance of tables: run_bintip_criteria and production_run_pack_materials

  def ProductionRun.runs_for_input_rmt(commodity, variety)
    sql = "SELECT
         public.production_runs.production_run_code
         FROM
         public.production_runs
         INNER JOIN public.production_schedules ON (public.production_runs.production_schedule_id = public.production_schedules.id)
         INNER JOIN public.rmt_setups ON (public.production_schedules.id = public.rmt_setups.production_schedule_id)
         WHERE
         (public.rmt_setups.commodity_code = '#{commodity}') AND
         (public.rmt_setups.variety_code = '#{variety}')"

    return ProductionRun.find_by_sql(sql)

  end


  def after_save
    validate_parent_and_child
  end


  def after_create

    validate_parent_and_child

    return if self.is_depot_run
    puts "RUN AFTER CREATE"
    run_stats                     = ProductionRunStat.new
    run_stats.rebins_printed      = 0
    run_stats.rebins_weight       = 0
    run_stats.cartons_printed     = 0
    run_stats.cartons_weight      = 0
    run_stats.bins_tipped         = 0
    run_stats.bins_tipped_weight  = 0
    run_stats.pallets_completed   = 0
    run_stats.production_run_code = self.production_run_code
    run_stats.production_run      = self
    run_stats.create


    run_bintip_criterium = RunBintipCriterium.new
    raise "No bintip criteria defined for schedule!" if !self.production_schedule.bintip_criterium
    self.production_schedule.bintip_criterium.export_attributes(run_bintip_criterium)
    run_bintip_criterium.production_run = self
    run_bintip_criterium.create


    if !self.is_cloning


      create_pack_groups

    end
  end

  #------------------------------------------------------------------------------------------------------------
  #This method auto-completes the allocation of fg_products to pack_stations for all stations
  # where the context(drop-count-allocation within pack-groups) dictates that there can only
  # be one logical choice
  #Algorythm
  # 1) Get list of all pack_stations
  #    note: the after_find method of each pack_station instance will populate the pack_station's context, i.e.
  #          fields: color_percentage,grade,size_count,marketing_variety and (existing)fg_product allocation
  #                  and 'additional_groups' (meaning more than one pack_group context applies for station)
  # 2) FOR EACH PACK STATION:
  #    IF the pack_station has a context associated with it and ONLY ONE context
  #         (i.e no additional pack groups and field standard_size_count has a value) and there is
  #          no existing fg_product allocation
  #      -> Get a list of potential fg_product_codes for station context
  #      IF there's only one fg_product_code
  #        -> Get a list of carton_setup_codes for the fg_product
  #        IF there's only one carton_setup_code
  #         -> allocate the carton_setup_code to the station (create new carton_link record)
  #-------------------------------------------------------------------------------------------------------------
  def auto_complete_fg_allocation

    outlets = PackGroupOutlet.find(:all, :conditions=> "pack_group_outlets.production_run_id = '#{self.id}' and pack_group_outlets.size_code is null",
                                   :include         => "pack_group", :order => "pack_group_outlets.id")

    #CartonPackStation.set_production_run_id(self.id)
    CartonPackStation.set_outlets(outlets, self.id)


    #---------------------------
    #Get list of pack stations
    #---------------------------
    stations_query = "SELECT
           public.carton_pack_stations.station_code,carton_pack_stations.id,
           public.tables.table_code as table_code,
           public.tables.id as table_id,
           public.drops.drop_code as drop_code,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.drops ON (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.tables ON (public.drops.id = public.tables.drop_id)
           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
           WHERE
           (public.lines.id = '#{self.line.id}')  order BY drop_code,table_code,station_code "

    pack_stations  = CartonPackStation.find_by_sql(stations_query)
    pack_stations.each do |station|
      station.set_product_context(self.id)
    end

    n_allocated = 0
    self.transaction do

      pack_stations.each do |station|
        if station.size_count
          station.production_schedule_name = self.production_schedule.production_schedule_name
          station.production_run_number    = self.production_run_number
          fg_codes                         = FgSetup.fg_codes_for_station_link_context(station, self).map { |f| f.fg_product_code }
          if fg_codes.length == 1
            link = CartonLink.find_by_production_run_id_and_station_code(self.id, station.station_code)
            if !link #existing allocation not overwritten
              carton_setups = CartonSetup.find_all_by_production_schedule_code_and_fg_product_code_and_active(station.production_schedule_name, fg_codes[0],true)
              if carton_setups.length == 1 && !station.more_groups
                #----------------------
                #create new carton_link
                #----------------------
                carton_setup            = carton_setups[0]

                link                    = CartonLink.new
                link.carton_setup       = carton_setup
                link.carton_label_setup = carton_setup.carton_label_setup
                link.pallet_label_setup = carton_setup.pallet_label_setup
                link.pallet_template    = carton_setup.pallet_template
                link.carton_template    = carton_setup.carton_template
                link.production_run     = self
                link.station_code       = station.station_code
                link.drop_code          = station.drop_code
                link.line_code          = self.line_code
                link.fg_product_code    = fg_codes[0]
                link.carton_setup_code  = carton_setup.carton_setup_code

                link.drop_side_code     = station.table.drop.drop_side_code
                if link.save
                  station.fg_product_code   = fg_codes[0]
                  station.carton_setup_code = carton_setup.carton_setup_code
                  n_allocated               += 1
                else
                  raise "carton setup: " + carton_setup.carton_setup_code + " could not be allocated to station: " + station.station_code + "<BR>. Reason: " + link.errors.to_s
                  return
                end
              end
            end
          end
        end
      end
    end
    return n_allocated.to_s + " pack stations could be auto populated."
  end


  def set_status(status, created_by_user, do_not_update = nil)

    self.production_run_status = status
    prod_status                = ProductionRunStatus.new
    prod_status.created_by     = created_by_user.first_name + " " + created_by_user.last_name
    prod_status.status_code    = status
    prod_status.production_run = self

    #self.production_run_statuses.push(prod_status)
    if !prod_status.create
      raise prod_status.errors.full_messages.to_s
    end

  end


  def create_sizer_template(new_template)

    template = SizerTemplate.find_by_template_name(self.applied_sizer_template)

    self.transaction do

      new_template.commodity_group_code = Commodity.find_by_commodity_code(new_template.commodity_code).commodity_group_code

      #new_template.line_config_code = template.line_config_code
      new_template.line_config_code     = self.line.line_config.line_config_code

      if !new_template.save
        raise "new template could not be created. Reason: " + new_template.errors.full_messages.to_s
      end
      #go through all pack groups and for each: find a matching group in the template
      #if a match is found apply the template by delegating to the pack group

      self.pack_groups.each do |group|
        new_group                       = PackGroupTemplate.new
        new_group.do_not_create_outlets = true
        group.export_attributes(new_group)
        new_group.sizer_template_id = new_template.id
        new_group.commodity_code    = new_template.commodity_code
        new_group.rmt_variety_code  = new_template.rmt_variety_code
        if !new_group.save
          raise "Group could not be created.Reason: " + !new_group.errors.full_messages.to_s
        end

        group.pack_group_outlets.each do |outlet|
          new_outlet = PackGroupTemplateOutlet.new
          outlet.export_attributes(new_outlet)
          new_outlet.pack_group_template_id = new_group.id
          if !new_outlet.save
            raise "Group outlet could not be created.Reason: " + !new_group.errors.full_messages.to_s
          end
        end
      end
    end

  end


  def save_to_sizer_template(template)
    n_groups_applied = 0
    self.transaction do

      #go through all pack groups and for each: find a matching group in the template
      #if a match is found apply the template by delegating to the pack group
      i = 0
      self.pack_groups.each do |group|
        conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code = '#{group.grade_code}'"
        conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code is null" if !group.grade_code


        if template_group = template.pack_group_templates.find(:first, :conditions => conditions, :include => "pack_group_template_outlets")

          puts "group: " + n_groups_applied.to_s + ": " + group.pack_group_outlets.length().to_s
          group.save_to_sizer_template(template_group)
          n_groups_applied += 1
        end
      end

    end

    return n_groups_applied
  end

  def apply_sizer_template(template)
    n_groups_applied = 0
    self.transaction do

      #go through all pack groups and for each: find a matching group in the template
      #if a match is found apply the template by delegating to the pack group
      i = 0
      self.pack_groups.each do |group|
        conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code = '#{group.grade_code}'"
        conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code is null" if !group.grade_code


        if template_group = template.pack_group_templates.find(:first, :conditions => conditions, :include => "pack_group_template_outlets")

          puts "group: " + n_groups_applied.to_s + ": " + group.pack_group_outlets.length().to_s
          group.apply_sizer_template(template_group)
          n_groups_applied += 1
        end
      end

    end
    if n_groups_applied > 0
      self.applied_sizer_template = template.template_name
      self.update
    end
    return n_groups_applied
  end


  # def apply_sizer_template(template)
  #  puts "in apply sizer template"
  #   n_groups_applied = 0
  #
  #    #go through all pack groups and for each: find a matching group in the template
  #    #if a match is found apply the template by delegating to the pack group
  #    i = 0
  #    self.pack_groups.each do |group|
  #     conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code = '#{group.grade_code}'"
  #     conditions = "color_sort_percentage = '#{group.color_sort_percentage}' and grade_code is null" if !group.grade_code
  #
  #
  #      if template_group = template.pack_group_templates.find(:first,:conditions => conditions,:include => "pack_group_template_outlets")
  #
  #        puts "group: " + n_groups_applied.to_s + ": " + group.pack_group_outlets.length().to_s
  #        group.apply_sizer_template(template_group)
  #
  #        n_groups_applied += 1
  #      end
  #
  #  end if
  #  if n_groups_applied > 0
  #    self.applied_sizer_template = template.template_name
  #    self.update
  #  end
  #  return n_groups_applied
  # end


  #-------------------------------------------------------------------------------
  #This method clones the entire data structure of a production run: that is:
  #-> the run record itself
  #-> pack_groups and pack group outlets
  #-> carton_links
  #-> rebin_links
  #-> run_bintip_criterium
  #-> palletizing criteria
  #
  # LIVE data (active devices and status histories) are not cloned
  # The new run will be created with a status of 'editing'
  #-------------------------------------------------------------------------------
  def clone_run
    cloned_run = ProductionRun.new
    self.transaction do

      #------------------
      #Clone run itself
      #------------------

      self.export_attributes(cloned_run, true, ["parent_run_code", "child_run_code","rank"])
      cloned_run.is_cloning            = true
      cloned_run.production_run_status = "configuring"
      cloned_run.production_run_stage  = nil
      cloned_run.day_line_batch_number = ProductionRun.next_line_day_sequence_number(self.line.id)
      cloned_run.shift_id              = nil #shift stuff will be calculated on execution
      cloned_run.shift_code            = nil
      cloned_run.batch_code            = nil
      cloned_run.day_line_batch_code   = nil
      cloned_run.start_date_time       = nil
      cloned_run.production_run_number = ProductionRun.next_run_id(self.production_schedule_name)
      cloned_run.end_date_time         = nil
      cloned_run.cartons_printed       = 0
      cloned_run.pallets_completed     = 0
      cloned_run.rebins_printed        = 0
      cloned_run.bins_tipped           = 0
      cloned_run.cartons_weight        = 0
      cloned_run.rebins_weight         = 0
      cloned_run.bins_tipped_weight    = 0

      cloned_run.create #the run code will be calculated on before_create

      #------------------------------------------------
      #Clone pack groups and each  pack group's outlets
      #------------------------------------------------
      self.pack_groups.each do |pack_group|
        cloned_pack_group = PackGroup.new
        pack_group.export_attributes(cloned_pack_group)
        cloned_pack_group.production_run = cloned_run
        cloned_pack_group.create
        pack_group.pack_group_outlets.each do |outlet|
          cloned_outlet = PackGroupOutlet.new
          outlet.export_attributes(cloned_outlet)
          cloned_outlet.production_run = cloned_run
          cloned_outlet.pack_group     = cloned_pack_group
          cloned_outlet.create
        end
      end

      #------------------
      #Clone carton_links
      #------------------
      self.carton_links.each do |carton_link|
        cloned_carton_link = CartonLink.new
        carton_link.export_attributes(cloned_carton_link, true)

        cloned_carton_link.production_run = cloned_run
        cloned_carton_link.create
      end

      #------------------
      #Clone rebin_links
      #------------------
      self.rebin_links.each do |rebin_link|
        cloned_rebin_link = RebinLink.new
        rebin_link.export_attributes(cloned_rebin_link, true)
        seq_nr = cloned_run.day_line_batch_number.to_s
        seq_nr = "0" + seq_nr if seq_nr.length == 1
        cloned_rebin_link.day_line_batch_number = nil #Time.now.wday.to_s + self.line_code + seq_nr
        cloned_rebin_link.production_run        = cloned_run
        cloned_rebin_link.create

      end


      self.run_palletizing_criteria.each do |palletize_crit|
        palletize_clone = RunPalletizingCriterium.new
        palletize_crit.export_attributes(palletize_clone)
        palletize_clone.production_run = cloned_run
        palletize_clone.create

      end


    end

    return cloned_run

  end


  def clear_links

    RebinLink.delete_all("production_run_id = '#{self.id}'")
    CartonLink.delete_all("production_run_id = '#{self.id}'")

  end

  def complete_current_stage

    carton_station_type     = DeviceType.find_by_device_type_code("CPS")
    rebin_station_type      = DeviceType.find_by_device_type_code("BS")
    rebin_sort_station_type = DeviceType.find_by_device_type_code("BSS")
    #self.transaction do
    stage_hist              = ProductionRunStageHistory.new
    case self.production_run_stage
      when "bintipping_only"
        self.production_run_stage    = "bintipping_plus"
        stage_hist.run_stage_entered = "bintipping_plus"
        #populate active devices from carton_links
        self.carton_links.each do |carton_link|
          device                       = ActiveDevice.new
          device.active_device_code    = carton_link.station_code
          device.device_type           = carton_station_type
          device.device_type_code      = carton_station_type.device_type_code
          device.day_line_batch_number = self.day_line_batch_code
          device.production_run_start  = self.start_date_time
          device.production_run        = self
          device.production_run_code   = self.production_run_code
          device.line_code             = self.line.line_code
          device.create

          active_link = ActiveCartonLink.new
          carton_link.export_attributes(active_link, true)
          active_link.create

        end

        #-------------
        #Rebin links:
        #-------------
        #-------------------------------------------------
        #TODO Create active_rebin_links from rebin_links
        #-------------------------------------------------
        self.rebin_links.each do |rebin_link|
          device                    = ActiveDevice.new
          device.active_device_code = rebin_link.station_code
          if rebin_link.is_sort_station == false
            device.device_type = rebin_station_type
          else
            device.device_type = rebin_sort_station_type
          end

          device.device_type_code      = device.device_type.device_type_code
          device.day_line_batch_number = self.day_line_batch_code
          device.production_run_start  = self.start_date_time
          device.production_run        = self
          device.production_run_code   = self.production_run_code
          device.line_code             = self.line.line_code
          device.create

          active_link= ActiveRebinLink.new
          rebin_link.export_attributes(active_link, true)
          active_link.day_line_batch_number = self.day_line_batch_code
          active_link.create

        end

      when "bintipping_plus"
        self.production_run_stage    = "carton_labeling_plus"
        stage_hist.run_stage_entered = "carton_labeling_plus"
        clear_active_devices("bin_tipping")

      when "carton_labeling_plus"
        self.production_run_stage    = "rebinning"
        stage_hist.run_stage_entered = "rebinning"
        set_reworks_devices(self.active_devices)
        clear_active_devices("rebinning")
        clear_active_devices("carton_labeling")
        clear_active_carton_links

      when "rebinning"
        #self.production_run_stage = "completed"
        stage_hist.run_stage_entered = "completed"
        clear_active_devices("rebinning")
        clear_active_rebin_links
        clear_active_carton_links
        clear_reworks_devices

    end

    stage_hist.production_run = self
    stage_hist.create
    self.update
    #end
  end

  def clear_reworks_devices
    ActiveReworksDevice.delete_all("production_run_id = '#{self.id}'")

  end

  def set_reworks_devices(active_devices)

    active_devices.each do |active_device|
      reworks_device = ActiveReworksDevice.new
      active_device.export_attributes(reworks_device, true)
      reworks_device.create
    end

  end


  def ProductionRun.get_bins_tipped_count_for_run_and_line(run_code, line_id)

    #  query = "SELECT
    #          COUNT(public.bins_tipped.id) AS n_bins
    #          FROM
    #          public.production_runs
    #          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
    #          inner join public.bins_tipped on (public.bins_tipped.production_run_code = public.production_runs.production_run_code)
    #          WHERE
    #          (((public.production_runs.production_run_status = 'active') OR
    #          (public.production_runs.production_run_status = 'reconfiguring')) AND
    #          (public.lines.id = '#{line_id}') AND
    #          ( public.production_runs.production_run_code = '#{run_code}' ) and
    #          (public.bins_tipped.id is not null ) and
    #          (public.lines.id is not null))"

    val = connection.select_one(query)
    if val["n_bins"]== nil
      return 0
    else
      return val["n_bins"]
    end

  end


  def ProductionRun.get_bins_tipped_invalid_count_for_run_and_line(run_code, line_id)

    #  query = "SELECT
    #          COUNT(public.bins_tipped_invalid.id) AS n_bins
    #          FROM
    #          public.production_runs
    #          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
    #          inner join public.bins_tipped_invalid on (public.bins_tipped_invalid.production_run_code = public.production_runs.production_run_code)
    #          WHERE
    #          (((public.production_runs.production_run_status = 'active') OR
    #          (public.production_runs.production_run_status = 'reconfiguring')) AND
    #          (public.lines.id = '#{line_id}') AND
    #          ( public.production_runs.production_run_code = '#{run_code}' ) and
    #          (public.bins_tipped_invalid.id is not null ) and
    #          (public.lines.id is not null))"

    val = connection.select_one(query)
    if val["n_bins"]== nil
      return 0
    else
      return val["n_bins"]
    end

  end


  def ProductionRun.get_carton_count_for_run_and_line(run_code, line_id)

    query = "SELECT
          COUNT(public.cartons.id) AS n_cartons
          FROM
          public.production_runs
          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
          inner join public.cartons on (public.cartons.production_run_code = public.production_runs.production_run_code)
          WHERE
          (((public.production_runs.production_run_status = 'active') OR
          (public.production_runs.production_run_status = 'reconfiguring')) AND
          (public.lines.id = '#{line_id}') AND
          ( public.production_runs.production_run_code = '#{run_code}' ) and
          (public.cartons.id is not null ) and
          (public.lines.id is not null))"

    val   = connection.select_one(query)
    if val["n_cartons"]== nil
      return 0
    else
      return val["n_cartons"]
    end

  end


  def ProductionRun.get_oldest_rebin_date_time(line_id, run_id)

    query = "SELECT
          MIN(public.rebins.date_time_created) AS created_on
          FROM
          public.production_runs
          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
          inner join public.rebins on (public.rebins.production_run_id = public.production_runs.id)
          WHERE
          (((public.production_runs.production_run_status = 'active') OR
          (public.production_runs.production_run_status = 'reconfiguring')) AND
          (public.lines.id = '#{line_id}') AND
          ( public.production_runs.id = '#{run_id}' ) and
          (public.rebins.id is not null ) and
          (public.lines.id is not null))"

    val   = connection.select_one(query)

    return val["created_on"]


  end

  def ProductionRun.get_last_completed_pallet_date_time(line_id, run_id)

    query = "SELECT
          MAX(public.pallets.date_time_completed) AS last_completed_on
          FROM
          public.production_runs
          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
          inner join public.pallets on (public.pallets.production_run_id = public.production_runs.id)
          WHERE
          (((public.production_runs.production_run_status = 'active') OR
          (public.production_runs.production_run_status = 'reconfiguring')) AND
          (public.lines.id = '#{line_id}') AND
          ( public.production_runs.id = '#{run_id}' ) and
          (public.pallets.id is not null ) and
          (public.lines.id is not null) and
          (public.pallets.process_status = 'PALLETIZED'))"

    val   = connection.select_one(query)

    return val["last_completed_on"]


  end


  def ProductionRun.get_completed_pallet_count_for_run_and_line(run_code, line_id)

    #  query = "SELECT
    #          COUNT(public.pallets.id) AS n_pallets
    #          FROM
    #          public.production_runs
    #          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
    #          inner join public.pallets on (public.pallets.production_run_id = public.production_runs.id)
    #          WHERE
    #          (((public.production_runs.production_run_status = 'active') OR
    #          (public.production_runs.production_run_status = 'reconfiguring')) AND
    #          (public.lines.id = '#{line_id}') AND
    #          ( public.production_runs.production_run_code = '#{run_code}' ) and
    #          (public.pallets.id is not null ) and
    #          (public.lines.id is not null) and
    #          (public.pallets.process_status = 'PALLETIZED'))"


    val = connection.select_one(query)
    if val["n_pallets"]== nil
      return 0
    else
      return val["n_pallets"]
    end

  end


  def ProductionRun.get_rebin_count_for_run_and_line(run_code, line_id)

    #  query = "SELECT
    #          COUNT(public.rebins.id) AS n_rebins
    #          FROM
    #          public.production_runs
    #          INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
    #          inner join public.rebins on (public.rebins.production_run_id = public.production_runs.id)
    #          WHERE
    #          (((public.production_runs.production_run_status = 'active') OR
    #          (public.production_runs.production_run_status = 'reconfiguring')) AND
    #          (public.lines.id = '#{line_id}') AND
    #          ( public.production_runs.production_run_code = '#{run_code}' ) and
    #          (public.rebins.id is not null ) and
    #          (public.lines.id is not null))"
    #
    val = connection.select_one(query)
    if val["n_rebins"]== nil
      return 0
    else
      return val["n_rebins"]
    end

  end


  def running_carton_links?

    query = "SELECT
            active_carton_links.station_code
            FROM
            public.active_carton_links,
            public.active_devices
            WHERE
            active_carton_links.station_code = active_devices.active_device_code and active_carton_links.production_run_id = '#{self.id.to_s}'
            AND active_devices.production_run_id <> '#{self.id.to_s}'"

    links = ActiveCartonLink.find_by_sql(query)
    if links.length() > 0
      return links.map { |c| c.station_code }.join(",")
    else
      return nil
    end

  end


  def get_active_child_runs()

    return nil if !self.parent_run_code

    query = "select production_run_code from production_runs where
            (id <> '#{self.id.to_s}') AND
            (parent_run_code = '#{self.parent_run_code}')"

    runs  = ProductionRun.find_by_sql(query)
    if runs.length > 0
      return runs[0].production_run_code
    else
      return nil
    end

  end




  def ProductionRun.get_active_bintipping_run_on_line(line_id)

    active_runs = ProductionRun.get_active_runs_for_line(line_id)
    active_runs.each do |run|
      if run.production_run_stage == "bintipping_plus"||run.production_run_stage == "bintipping_only"
        return run.production_run_code
      end
    end
    return nil

  end

  def ProductionRun.get_active_labeling_run_on_line(line_id)
    code        = nil
    active_runs = ProductionRun.get_active_runs_for_line(line_id)
    active_runs.each do |run|

      if run.production_run_stage == "bintipping_plus"||run.production_run_stage == "carton_labeling_plus"
        return run.production_run_code
      end
    end

    return nil

  end

  def ProductionRun.get_active_runs_for_line(line_id)

    query = "SELECT public.production_runs.*,product_classes.product_class_code,track_indicators.track_indicator_code,treatments.treatment_code,
            rank,sizes.size_code
            FROM
            public.production_runs
            INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
            left join product_classes on product_classes.id = production_runs.product_class_id
            left join treatments on treatments.id = production_runs.treatment_id
            left join track_indicators on track_indicators.id = production_runs.track_indicator_id
            left join sizes on sizes.id = production_runs.size_id

            WHERE
            (((public.production_runs.production_run_status = 'active') OR
            (public.production_runs.production_run_status = 'reconfiguring')) AND
            (public.lines.id = '#{line_id}') AND
            (public.production_runs.id is not null ))ORDER BY
            production_runs.production_run_stage"

    return runs = ProductionRun.find_by_sql(query)

  end



  def is_dp_run?
    return  self.line_code.to_i > 40 && self.line_code.to_i < 49
  end

  def ProductionRun.get_editing_runs_for_line(line_id)


    #get active run on line and use its schedule to filter editing runs
    active_run_schedule_rec = ProductionRun.connection.select_one("select production_schedule_id from production_runs
                                           INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
                                           WHERE public.lines.id = '#{line_id}' AND (upper(production_run_stage) like '%TIP%' or
                                          upper(production_run_stage) like '%CARTON%') order by production_runs.id DESC LIMIT 1")


    if active_run_schedule_rec && active_run_schedule_id = active_run_schedule_rec['production_schedule_id']


      query = "SELECT public.production_runs.*,product_classes.product_class_code,track_indicators.track_indicator_code,treatments.treatment_code,
              rank,sizes.size_code
              FROM
              public.production_runs
              INNER JOIN public.lines ON (public.production_runs.line_id = public.lines.id)
              left join product_classes on product_classes.id = production_runs.product_class_id
              left join treatments on treatments.id = production_runs.treatment_id
              left join track_indicators on track_indicators.id = production_runs.track_indicator_id
              left join sizes on sizes.id = production_runs.size_id

              WHERE
              ((public.production_runs.production_run_status = 'configuring') AND
               (production_schedule_id = #{active_run_schedule_id}) AND
              (public.lines.id = '#{line_id}') AND
              (public.production_runs.id is not null ))ORDER BY
              production_runs.rank asc"

      return runs = ProductionRun.find_by_sql(query)
    else
      return nil
    end
  end

  def get_bins

    #BinManager.new(self).get_bins
  end




  def restore_reworks_devices(rebin_links)

    rebin_station_type      = DeviceType.find_by_device_type_code("BS")
    rebin_sort_station_type = DeviceType.find_by_device_type_code("BSS")
    rebin_links.each do |rebin_link|
      device                    = ActiveReworksDevice.new
      device.active_device_code = rebin_link.station_code
      if rebin_link.is_sort_station == false
        device.device_type = rebin_station_type
      else
        device.device_type = rebin_sort_station_type
      end

      device.device_type_code      = device.device_type.device_type_code
      device.day_line_batch_number = self.day_line_batch_code
      device.production_run_start  = self.start_date_time
      device.production_run        = self
      device.production_run_code   = self.production_run_code
      device.line_code             = self.line.line_code
      device.create

      active_link= ActiveRebinLink.new
      rebin_link.export_attributes(active_link, true)
      active_link.day_line_batch_number = self.day_line_batch_code
      active_link.create

    end


  end


  #=========================
  #OLD EXECUTE ALGORHYTHM
  #=========================
  #------------------------------------------------------------------------
  #Executing a run, involves the following:
  #A: for a run being executed for the first time (i.e. with status 'configuring')
  #1) creating a day line batch number
  #2) setting the status to 'active' (done by controller) and run_stage to 'bintipping'
  #3) Fetching all bins from legacy store that match the active bintip criteria
  #   and populating our bins table
  #4) Populating the active devices table. This involves:
  #   -> All rebin links
  #   -> All bintip stations for the active line config
  #B: for a run being executed from a 'reconfiguring' state
  #1) get all the active devices for the run and copy to 'active_devices_histories
  #2) delete all the current active devices for the run
  #3) refresh bins? and populate devices up to current run stage, i.e.
  #   :if run_stage = 'bintipping' -> bintipping devices & rebin devices
  #                   'carton_labeling -> carton_labeling devices & rebin devices
  #                   'palletizing & rebinning -> rebin devices
  #4) do step A:4
  #-------------------------------------------------------------------------------


  #========================================================================================================
  #Executing a run, involves the following:
  #A: for a run being executed for the first time (i.e. with status 'configuring')
  #1) creating a day line batch number
  #2) setting the status to 'active' (done by controller) and run_stage to 'bintipping_plus' OR
  #   'bintipping_only'
  #3) Fetching all bins from legacy store that match the active bintip criteria
  #   and populating our bins table
  #4) Populating the active devices table. This involves:
  #   -> All rebin links
  #   -> All bintip stations for the active line config
  #   -> All Carton Links
  #
  #B: for a run being executed from a 'reconfiguring' state
  #1) get all the active devices for the run and copy to 'active_devices_histories
  #2) delete all the current active devices for the run
  #3) refresh bins? and populate devices up to current run stage, i.e.
  #   :if run_stage = 'bintipping_only' -> bintipping devices & rebin devices
  #                   'bintipping_plus' -> bintipping devices  & carton_labeling devices & rebin devices
  #                   'carton_labeling -> carton_labeling devices & rebin devices
  #                   'rebinning -> rebin devices
  #4) do step A:4
  #==========================================================================================================
  def execute(shift_details = nil, user = nil)
    # begin

    BinfillSortStation.clear_product_allocation_data(self.id)
    BinfillStation.clear_product_allocation_data(self.id)
    CartonPackStation.clear_product_allocation_data(self.id)
    #get basic device types
    self.transaction do

      #--------------------------------------------------------------------------
      #Update the child_run attribute on parent_run if this run has a parent run
      #--------------------------------------------------------------------------
      if self.parent_run_code
        parent_run                = ProductionRun.find_by_production_run_code(self.parent_run_code)
        parent_run.child_run_code = self.production_run_code
        parent_run.update
      end

      carton_station_type     = DeviceType.find_by_device_type_code("CPS")
      rebin_station_type      = DeviceType.find_by_device_type_code("BS")
      rebin_sort_station_type = DeviceType.find_by_device_type_code("BSS")
      bintip_station_type     = DeviceType.find_by_device_type_code("BT")

      #------------------------------------------------------
      #Determine if the new status should be bintipping_only
      #------------------------------------------------------

      bintipping_only         = (ProductionRun.get_active_labeling_run_on_line(line_id)!= nil)
      bintip_stage            = "bintipping_plus"
      bintip_stage = "bintipping_only" if bintipping_only

      self.production_run_stage = bintip_stage if !self.production_run_stage

      if self.production_run_status == "configuring"
        #Bin.delete_all("line_code = '#{self.line_code}'")
        self.start_date_time = Time.now
        self.day_line_batch_number = ProductionRun.next_line_day_sequence_number(self.line.id) if !self.day_line_batch_number
        seq_nr = self.day_line_batch_number.to_s
        seq_nr = "0" + seq_nr if seq_nr.length == 1
        self.day_line_batch_code  = Time.now.wday.to_s + self.line_code + seq_nr
        self.batch_code           = "0" + self.line_code + self.production_schedule.id.to_padded_s(5) + self.production_run_number.to_padded_s(3) #Time.now.strftime("%m%d%y") + "0" + self.line_code + seq_nr
        self.production_run_stage = bintip_stage
        #TODO Is this format for batch number correct?

      end

      #---------------------------------------------------------------------------
      #Update all rebin_links for this run with the day_line_batch_code(called
      #'day_line_sequence_number' in rebin_links table). This is needed to ensure
      #the uniqueness of rebin_links, since they accrue across runs in that table
      #THIS ONLY APPLIES TO REBINS
      #STAGING (FEB 2008) IMPACT
      # This update is no longer necessary, since the 'rebin_links' table is never
      # active. New table: 'active_rebin_links' get the batch code
      #----------------------------------------------------------------------------
      #    self.rebin_links.each do |rebin_link|
      #     rebin_link.day_line_batch_number = self.day_line_batch_code
      #     rebin_link.update
      #    end

      if self.production_run_status == "reconfiguring"||self.production_run_status == "restored"
        clear_active_devices
        clear_active_carton_links #TODO: NEW METHOD
        clear_active_rebin_links #TODO: NEW METHOD
        if self.production_run_stage == "rebinning"
          clear_reworks_devices
          restore_reworks_devices(self.rebin_links)
        end
      end
      #-------------
      #Carton links:
      #-------------
      if self.production_run_stage == "bintipping_plus" ||self.production_run_stage == "carton_labeling_plus"

        #-------------------------------------------------
        #TODO Create active_carton_links from carton_links
        #-------------------------------------------------

        self.carton_links.each do |carton_link|
          device                       = ActiveDevice.new
          device.active_device_code    = carton_link.station_code
          device.device_type           = carton_station_type
          device.device_type_code      = carton_station_type.device_type_code
          device.day_line_batch_number = self.day_line_batch_code
          device.production_run_start  = self.start_date_time
          device.production_run        = self
          device.production_run_code   = self.production_run_code
          device.line_code             = self.line.line_code
          device.create

          active_link = ActiveCartonLink.new
          carton_link.export_attributes(active_link, true)
          active_link.create
        end

        #-------------
        #Rebin links:
        #-------------

        #-----------------------------------------------
        #TODO Create active_rebin_links from rebin_links
        #-----------------------------------------------
        self.rebin_links.each do |rebin_link|
          device                    = ActiveDevice.new
          device.active_device_code = rebin_link.station_code
          if rebin_link.is_sort_station == false
            device.device_type = rebin_station_type
          else
            device.device_type = rebin_sort_station_type
          end

          device.device_type_code      = device.device_type.device_type_code
          device.day_line_batch_number = self.day_line_batch_code
          device.production_run_start  = self.start_date_time
          device.production_run        = self
          device.production_run_code   = self.production_run_code
          device.line_code             = self.line.line_code
          device.create

          active_link= ActiveRebinLink.new
          rebin_link.export_attributes(active_link, true)
          active_link.day_line_batch_number = self.day_line_batch_code
          active_link.create

        end
      end


      #-------------------------------------------------------------------------------
      #Bintip stations: create a device for every bintip station connected to the line
      #-------------------------------------------------------------------------------
      if self.production_run_stage == "bintipping_plus"||self.production_run_stage == "bintipping_only"
        self.line.line_config.bintip_stations.each do |bintip_station|
          device                       = ActiveDevice.new
          device.active_device_code    = bintip_station.ip_address
          device.device_type           = bintip_station_type
          device.day_line_batch_number = self.day_line_batch_code
          device.production_run_start  = self.start_date_time
          device.device_type_code      = bintip_station_type.device_type_code
          device.production_run        = self
          device.production_run_code   = self.production_run_code
          device.line_code             = self.line.line_code
          device.create
        end
      end

      #set shift
      if shift_details
        shift           = Shift.set_shift(shift_details, self.line_code)
        self.shift      = shift
        self.shift_code = shift_details.shift_str
      end


      if self.production_run_status == "configuring"
        self.production_run_stage    = bintip_stage
        stage_hist                   = ProductionRunStageHistory.new
        stage_hist.run_stage_entered = bintip_stage
        stage_hist.production_run    = self
        stage_hist.create
      end

      self.set_status('active', user, true)
      if !self.update
        raise self.errors.full_messages.to_s
      end

    end
    #rescue
    # raise "The run could not be executed.The following exception occurred: <br>" + $!
    #end
  end


  def clear_active_carton_links
    ActiveCartonLink.delete_all("production_run_id = '#{self.id}'")

  end

  def clear_active_rebin_links
    ActiveRebinLink.delete_all("production_run_id = '#{self.id}'")

  end

  #----------------------------------------------------------------
  #This method is called for the staged closing of a run or when
  #a run is closed entirely- regardless of run stage or when
  #a run is set to 'reconfiguring'
  #----------------------------------------------------------------
  def clear_active_devices(device_type =nil)

    devices      = nil
    delete_query = nil

    if !device_type
      devices                      = self.active_devices
      stage_hist                   = ProductionRunStageHistory.new
      stage_hist.production_run    = self
      stage_hist.run_stage_entered = "completed"
      stage_hist.create
      delete_query = "production_run_id = '#{self.id}'"
    elsif device_type == "bin_tipping"
      devices      = self.active_devices.find(:all, :conditions => "device_type_code = 'BT'")
      delete_query = "production_run_id = '#{self.id}' and device_type_code = 'BT'"
    elsif device_type == "carton_labeling"
      devices      = self.active_devices.find(:all, :conditions => "device_type_code = 'CPS'")
      delete_query = "production_run_id = '#{self.id}' and device_type_code = 'CPS'"
    elsif device_type == "rebinning"
      devices      = self.active_devices.find(:all, :conditions => "device_type_code = 'BSS' or device_type_code = 'BS'")
      delete_query = "production_run_id = '#{self.id}' and (device_type_code = 'BSS' or device_type_code = 'BS')"
    end

    if devices
      devices.each do |active_device|
        device_hist = ActiveDevicesHistory.new
        active_device.export_attributes(device_hist)
        device_hist.create
      end
    end

    ActiveDevice.delete_all(delete_query)

  end

  def refresh_run

    original_run = ProductionRun.find(self.id)
    #force loading of original run's pack_groups in memory
    original_run.pack_groups.each do |g|
      g.pack_group_outlets.each do |o|
        f= o.id
      end
    end

    #re-create pack groups
    self.transaction do
      self.pack_groups.each do |pack_group|
        pack_group.destroy
      end
      self.reload
      create_pack_groups
      self.pack_groups.each do |group|
        group.reload
      end

      if self.applied_sizer_template
        template = SizerTemplate.find_by_template_name(self.applied_sizer_template)
        apply_sizer_template(template)
      end
      re_add_non_template_drops(original_run)

    end
  end

  def re_add_non_template_drops(original_run)
    original_run.pack_groups.each do |g|
      conditions = nil
      if g.grade_code
        conditions = "production_run_id = #{self.id} and color_sort_percentage = #{g.color_sort_percentage} and grade_code = '#{g.grade_code}'"
      else
        conditions = "production_run_id = #{self.id} and color_sort_percentage = #{g.color_sort_percentage} and grade_code is null"
      end
      curr_group = self.pack_groups.find(:first, :conditions => conditions)
      if curr_group
        g.pack_group_outlets.each do |orig_outlet|
          #get corresponding new outlet
          if orig_outlet.standard_size_count_value
            new_outlet = curr_group.pack_group_outlets.find(:first, :conditions => "standard_size_count_value = #{orig_outlet.standard_size_count_value}")
          else
            new_outlet = curr_group.pack_group_outlets.find(:first, :conditions => "size_code = '#{orig_outlet.size_code}'")
          end
          #overwrite new outlet values with originals
          new_outlet.outlet1 = orig_outlet.outlet1 if orig_outlet.outlet1 && orig_outlet.outlet1 != "n.a"
          new_outlet.outlet2 = orig_outlet.outlet2 if orig_outlet.outlet2 && orig_outlet.outlet2 != "n.a"
          new_outlet.outlet3 = orig_outlet.outlet3 if orig_outlet.outlet3 && orig_outlet.outlet3 != "n.a"
          new_outlet.outlet4 = orig_outlet.outlet4 if orig_outlet.outlet4 && orig_outlet.outlet4 != "n.a"
          new_outlet.outlet5 = orig_outlet.outlet5 if orig_outlet.outlet5 && orig_outlet.outlet5 != "n.a"
          new_outlet.outlet6 = orig_outlet.outlet6 if orig_outlet.outlet6 && orig_outlet.outlet6 != "n.a"
          new_outlet.outlet7 = orig_outlet.outlet7 if orig_outlet.outlet7 && orig_outlet.outlet7 != "n.a"
          new_outlet.outlet8 = orig_outlet.outlet8 if orig_outlet.outlet8 && orig_outlet.outlet8 != "n.a"
          new_outlet.outlet9 = orig_outlet.outlet9 if orig_outlet.outlet9 && orig_outlet.outlet9 != "n.a"
          new_outlet.outlet10 = orig_outlet.outlet10 if orig_outlet.outlet10 && orig_outlet.outlet10 != "n.a"
          new_outlet.outlet11 = orig_outlet.outlet11 if orig_outlet.outlet11 && orig_outlet.outlet11 != "n.a"
          new_outlet.outlet12 = orig_outlet.outlet12 if orig_outlet.outlet12 && orig_outlet.outlet12 != "n.a"

          new_outlet.update
        end
      end
    end

  end

  #---------------------------------------------------------------------------------
  #Create a list of unique color_perc and grade combinations found in the
  #carton setup and rebin setup records. Do the following
  #1) Get unique list from carton_setups
  #
  #2) Get unique list from rebin_setups
  #3) Using the cartons list as base, check whether the rebins list contains
  #   a combination, not found in the cartons list
  #4) Create, for each record in the cartons list, and each 'extra' rebin record, as per 3,
  #   a pack_group record
  #---------------------------------------------------------------------------------
  def create_pack_groups

    query               = "select distinct color_percentage,grade_code from carton_setups where
            production_schedule_code = '#{self.production_schedule_name}'"

    carton_setup_groups = self.connection.select_all(query)

    rebin_setup_groups  = RebinSetup.find_by_sql("select distinct color_percentage,grade_code from rebin_setups where
                                               production_schedule_code = '#{self.production_schedule_name}'and standard_size_count_from > -1")
    group_number        = 0

    group_list          = Array.new

    pack_groups         = Array.new
    carton_setup_groups.each do |carton_setup_group|
      pack_group                          = PackGroup.new
      group_number                        += 1
      #find a 'real' carton setup- we need some info. Although carton setup group is
      #an instance of carton setup, the 'distinc' query disallowed the retrieval of all attributes
      carton_setup                        = CartonSetup.find(:first, :conditions => "color_percentage =\'#{carton_setup_group['color_percentage']}\'
                      and grade_code = '#{carton_setup_group['grade_code']}\' and production_schedule_code = '#{self.production_schedule_name}'")

      pack_group.pack_group_number        = group_number
      pack_group.commodity_code           = carton_setup.retail_item_setup.item_pack_product.commodity_code
      pack_group.marketing_variety_code   = carton_setup.marketing_variety_code
      pack_group.color_sort_percentage    = carton_setup.color_percentage
      pack_group.grade_code               = carton_setup.grade_code
      pack_group.production_run_number    = self.production_run_number
      pack_group.production_schedule_name = self.production_schedule_name
      pack_group.production_run           = self
      pack_group.create
      group_list.push pack_group
      #self.pack_groups.push(pack_group)

    end

    #---------------------------------------------------------------------------------------------------
    #See if the rebin_groups contain a group (color,grade combo) not found in the groups we already have
    #If not create a new group and add it
    #---------------------------------------------------------------------------------------------------

    rebin_setup_groups.each do |rebin_group|
      if !(rebin_group.color_percentage == -1 && !rebin_group.grade_code)&& !group_list.find { |p| p.color_sort_percentage == rebin_group.color_percentage && p.grade_code == rebin_group.grade_code }
        #missing roup, add new one
        pack_group   = PackGroup.new
        group_number += 1
        #find a 'real' rebin setup- we need some info. Although rebin setup group is
        #an instance of rebin setup, the 'distinc' query disallowed the retrieval of all attributes
        rebin_setup  = nil
        if rebin_group.grade_code
          rebin_setup = RebinSetup.find(:first, :conditions => ["color_percentage = ? and grade_code = ? and production_schedule_code = ?", rebin_group.color_percentage, rebin_group.grade_code, self.production_schedule_name])
        else
          rebin_setup = RebinSetup.find(:first, :conditions => ["color_percentage = ? and grade_code is null and production_schedule_code = ?", rebin_group.color_percentage, self.production_schedule_name])
        end

        pack_group.pack_group_number        = group_number
        pack_group.commodity_code           = rebin_setup.rmt_product.commodity_code
        pack_group.marketing_variety_code   = rebin_setup.variety_output_description
        pack_group.color_sort_percentage    = rebin_setup.color_percentage
        pack_group.grade_code               = rebin_setup.grade_code
        pack_group.production_run_number    = self.production_run_number
        pack_group.production_schedule_name = self.production_schedule_name
        pack_group.production_run           = self
        pack_group.create
        self.pack_groups.push(pack_group)

      end
    end


  end


  def ProductionRun.next_run_id(schedule_name)

    query = "SELECT max(production_runs.production_run_number)as maxval
           FROM
           public.production_runs where
           (production_runs.production_schedule_name = '#{schedule_name}')"

    val   = connection.select_one(query)
    if val["maxval"]== nil
      return 1
    else
      return val["maxval"].to_i + 1
    end
  end


  def ProductionRun.get_new_day_batch_code(line_id, line_code)

    begin
      puts "1"
      line    = Line.find_by_line_code(line_code)

      new_seq = ProductionRun.next_line_day_sequence_number(line.id.to_s)
      puts "3"
      new_day_line_batch_code = new_seq.to_s
      puts "4"
      new_day_line_batch_code = "0" + new_day_line_batch_code if new_day_line_batch_code.length == 1
      puts "5"
      new_day_line_batch_code = Time.now.wday.to_s + line_code + new_day_line_batch_code

      return new_day_line_batch_code
    rescue
      raise "new_day_line_batch_code could not be determined. Reason: " + $!
    end
  end


  def ProductionRun.get_occupying_batch_codes(new_day_line_batch_code)
    begin

      query = "select distinct production_run_code from active_devices where day_line_batch_number = '#{new_day_line_batch_code}'"
      puts query
      codes = ActiveDevice.find_by_sql(query).map { |c| c.production_run_code }
      return codes
    rescue
      raise "Occupying batch codes could not be determined. Reason: " + $!
    end
  end


  def ProductionRun.next_line_day_sequence_number(line_id)

    now                = Time.now
    year               = now.year
    month              = now.month
    day                = now.day

    tomorrow           = now.tomorrow
    tomorrow_year      = tomorrow.year
    tomorrow_month     = tomorrow.month
    tomorrow_day       = tomorrow.day

    twelve_am_today    = Time.local(year, month, (day), 0).to_formatted_s(:db)
    twelve_am_tomorrow = Time.local(tomorrow_year, tomorrow_month, (tomorrow_day), 0).to_formatted_s(:db)

    query              = "SELECT max(production_runs.day_line_batch_number)as maxval
           FROM
           public.production_runs where
           (production_runs.line_id = '#{line_id}' and start_date_time > '#{twelve_am_today}' and
           start_date_time < '#{twelve_am_tomorrow}'
            )"

    puts query
    val = connection.select_one(query)
    if val["maxval"]== nil
      return 1
    else
      return val["maxval"].to_i + 1
    end

  end


  def before_create
    puts "RUN before create"
    self.use_alternate_account = false
    self.production_run_number = ProductionRun.next_run_id(self.production_schedule_name)
    farm_code                  = ""
    farm_code = "_" + self.farm_code if self.farm_code
    self.production_run_code = self.production_schedule.season_code + "_" + self.production_schedule.id.to_s + "_" + self.production_run_number.to_s + farm_code
    self.bins_tipped_weight  = 0
    self.rebins_weight       = 0
    self.cartons_weight      = 0
    self.bins_tipped         = 0
    self.rebins_printed      = 0
    self.cartons_printed     = 0
    self.pallets_completed   = 0

  end

  def update_run_code
    farm_code = ""
    farm_code = "_" + self.farm_code if self.farm_code
    self.production_run_code = self.production_schedule.season_code + "_" + self.production_schedule.id.to_s + "_" + self.production_run_number.to_s + farm_code
    if ProductionRun.find(self.id).production_run_code != self.production_run_code
      self.update_attribute(:production_run_code, self.production_run_code)
    end

  end


  def validate_parent_and_child

    codes = []
    codes << self.production_run_code
    codes << self.parent_run_code if self.parent_run_code
    codes << self.child_run_code if self.child_run_code

    size = codes.size
    if size != codes.uniq.size
      raise MesScada::InfoError, "run-code, parent-code and child-code must all be different: <BR> #{codes.join(",")}"
    end
    #all items must be unique



  end



  def validate
    is_valid = true



    if self.production_schedule.farm_pack == true
      if is_valid
        is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}], self)
      end
        #is_valid = ModelHelper::Validations.validate_combos([{:rmt_product_type_id => self.rmt_product_type_id}], self, nil, true)
        #is_valid = ModelHelper::Validations.validate_combos([{:commodity_id => self.commodity_id}], self, nil, true)
        #is_valid = ModelHelper::Validations.validate_combos([{:variety_id => self.variety_id}], self, nil, true)

    else
      if is_valid
        #is_valid = ModelHelper::Validations.validate_combos([{:rmt_product_type_id => self.rmt_product_type_id}], self, nil, true)
        #is_valid = ModelHelper::Validations.validate_combos([{:commodity_id => self.commodity_id}], self, nil, true)
        #is_valid = ModelHelper::Validations.validate_combos([{:variety_id => self.variety_id}], self, nil, true)

      end

    end

    #ModelHelper::Validations.validate_combos([{:account_code => self.account_code}],self,true)

    # self.account_code = nil if !self.use_alternate_account

    if is_valid
      set_line
    end

  end

  def set_line
    packhouse_code = Facility.active_pack_house.facility_code
    line           = Line.get_line_for_packhouse_and_line_code(packhouse_code, self.line_code)

    if !line.line_config_id
      self.errors.add_to_base("Line " + self.line_code + " has no line configuration attached to it. You must first set a line_config for the line (under resources tab)")

    else
      self.line = line
    end
  end


  # def set_farm_puc_account
  #
  #    #-------------------------------------------------------------------------------------------
  #    #A ref to farm_puc_account only needs to be set if 'use_alternate_account' is set to true
  #    #
  #    #
  #    #
  #    #-------------------------------------------------------------------------------------------
  #	farm_puc_account = FarmPucAccount.find_by_farm_code_and_account_code_and_puc_code(self.farm_code,self.account_code,self.puc_code)
  #	 if farm_puc_account != nil
  #		 self.farm_puc_account = farm_puc_account
  #		 return true
  #	 else
  #		errors.add_to_base("combination of: 'farm_code' and 'account_code' and 'puc_code'  is invalid- not found in database")
  #		 return false
  #	end
  #end


  #  def self.account_codes_for_farm_code(farm_code)
  #
  #	account_codes = FarmPucAccount.find_by_sql("Select distinct account_code from farm_puc_accounts where farm_code = '#{farm_code}'").map{|g|[g.account_code]}
  #
  #	account_codes.unshift("<empty>")
  #
  # end
  #
  #
  # def self.puc_codes_for_account_code_and_farm_code(account_code, farm_code)
  #
  #	puc_codes = FarmPucAccount.find_by_sql("Select distinct puc_code from farm_puc_accounts where account_code = '#{account_code}' and farm_code = '#{farm_code}'").map{|g|[g.puc_code]}
  #
  #	puc_codes.unshift("<empty>")
  # end
  #


end

