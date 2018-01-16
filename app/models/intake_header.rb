class IntakeHeader < ActiveRecord::Base

  #attr_accessor :n_pallets_captured, :n_pallets_mapped

  has_many :depot_pallets,:dependent => :delete_all
  belongs_to :intake_type
  belongs_to :depot
  belongs_to :puc
  #belongs_to :account
  belongs_to :parties_role
  belongs_to :organization
  has_many :mapped_pallet_sequences,:dependent => :delete_all

  has_many :pallets, :order => "id asc"

  #=========================
  # VALIDATIONS
  #=========================
  validates_presence_of :intake_header_number
  validates_presence_of :consignment_note_number
  validates_presence_of :qty_pallets
  validates_presence_of :qty_cartons
  validates_presence_of :organization_code
  validates_presence_of :season

  #validates_presence_of :account_code
  #validates_presence_of :pack_order_number
  #validates_presence_of :inspector_number
  #validates_presence_of :inspection_point
  #validates_presence_of :order_number


  attr_accessor :user




  def after_create
    self.update_attribute(:updated_on, self.created_on)
  end

  def log_pallets
    log   = PalletDocumentLog.new
    query = "insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at)
                      select pallets.id, '#{self.consignment_note_number}','intake_header_depot','depot_intakes','#{self.user}','#{Time.new().to_formatted_s(:db)}'
                     from pallets where pallets.consignment_note_number = '#{self.consignment_note_number}'"
    self.connection.execute(query)

  end





  def  rmt_creatable?

    updated_sequences = Array.new
    line              = Line.find_by_line_code("DEPOT")
    mapped_sequences  = MappedPalletSequence.find_all_by_intake_header_id(self.id)
    seq_rmt_groups    = mapped_sequences.group(['commodity', 'variety', 'class_code', 'pc_code'], nil, true)
    shift             = Shift.find_by_shift_code('UNKNOWN')
    raise MesScada::InfoError,"Shift: 'UNKNOWN' does not exist. Needed for depot runs" if !shift
    for seq_rmt_group in seq_rmt_groups

      variety_rec = Variety.find_all_by_commodity_code_and_marketing_variety_code(seq_rmt_group[0].commodity, seq_rmt_group[0].variety)[0]
      raise "A variety(variety map) record not found for commodity: " + seq_rmt_group[0].commodity + " and marketing variety: " + seq_rmt_group[0].variety if !variety_rec

      rmt_variety_code     = variety_rec.rmt_variety_code

      commodity_group_code = Commodity.find_by_commodity_code(seq_rmt_group[0].commodity).commodity_group_code

      input_variety        = RmtVariety.find_by_rmt_variety_code_and_commodity_code(rmt_variety_code, seq_rmt_group[0].commodity)


      ripe_point_rec       = RipePoint.find_all_by_pc_code_code(seq_rmt_group[0].pc_code)[0]
      raise MesScada::InfoError, "no ripe point found for pc-code: " + seq_rmt_group[0].pc_code if !ripe_point_rec
      ripe_point   = ripe_point_rec.ripe_point_code

      #find first matching rmt product
      #rmt_sql = "select * from rmt_products where(commodity_code='#{seq_rmt_group[0].commodity}' and variety_code='#{rmt_variety_code}' and ripe_point_code='#{ripe_point}' and size_code = 'UNS' and rmt_product_type_code = 'orchard_run') order by rmt_product_code ASC"

      rmt_sql      = "SELECT rmt_products.* FROM ripe_points INNER JOIN rmt_products ON (ripe_points.id =rmt_products.ripe_point_id) WHERE commodity_code = '#{seq_rmt_group[0].commodity}'  AND variety_code = '#{rmt_variety_code}'  AND
                 ripe_points.pc_code_code = '#{seq_rmt_group[0].pc_code.to_s}' AND size_code = 'UNS' AND rmt_product_type_code = 'orchard_run' order by rmt_product_code ASC"


      rmt_products = RmtProduct.find_by_sql(rmt_sql)
      raise MesScada::InfoError,"A raw material product could not be found. PLEASE ENSURE THAT THE PICK REF IS CORRECT.<BR> Sql is: " + rmt_sql if !rmt_products[0]

      return nil
    end

  end




  def reverse_engineer_schedules_and_runs
    #----------------------------------------------------------------------------------------------------------------------------------------
    #2]  Group the mapped_pallet_sequences by:
    #     commodity,variety,class,pc_code
    #     For each group:
    #       i)lookup:
    #        -> first variety record for commodity and variety record
    #        -> commodity_group_code
    #        -> ripe_point_code (from pc_code_code)
    #       ii)find the first rmt_product record by:
    #          commodity,variety,class,size('UNS'),rmt_product_type('orchard_run'),treatment_type_code ('PACKHOUSE')
    #       iii) create a production_schedule record and a rmt_setup record
    #       iv) group this group by puc sub-groups
    #            For each puc subgroup:
    #            a) create a production_run record (set batch to header's created date formatted to 'ddmmyyyy',
    #                                                set farm_code to 'DEPOT_UNKNOWN',
    #                                                 set schedule_code and id to context schedule
    #
    #            b) update the production_run_id and production_run_code of each mapped_pallet_sequence + set the erp_cultivar
    #
    #--------------------------------------------------------------------------------------------------------------------------------------------
    updated_sequences = Array.new
    line              = Line.find_by_line_code("DEPOT")
    mapped_sequences  = MappedPalletSequence.find_all_by_intake_header_id(self.id)
    seq_rmt_groups    = mapped_sequences.group(['commodity', 'variety', 'class_code', 'pc_code'], nil, true)
    shift             = Shift.find_by_shift_code('UNKNOWN')
    raise "Shift: 'UNKNOWN' does not exist. Needed for depot runs" if !shift
    for seq_rmt_group in seq_rmt_groups

      variety_rec = Variety.find_all_by_commodity_code_and_marketing_variety_code(seq_rmt_group[0].commodity, seq_rmt_group[0].variety)[0]
      raise "A variety(variety map) record not found for commodity: " + seq_rmt_group[0].commodity + " and marketing variety: " + seq_rmt_group[0].variety if !variety_rec

      rmt_variety_code     = variety_rec.rmt_variety_code

      commodity_group_code = Commodity.find_by_commodity_code(seq_rmt_group[0].commodity).commodity_group_code

      input_variety        = RmtVariety.find_by_rmt_variety_code_and_commodity_code(rmt_variety_code, seq_rmt_group[0].commodity)


      ripe_point_rec       = RipePoint.find_all_by_pc_code_code(seq_rmt_group[0].pc_code)[0]
      raise "no ripe point found for pc-code: " + seq_rmt_group[0].pc_code if !ripe_point_rec
      ripe_point   = ripe_point_rec.ripe_point_code

      #find first matching rmt product
      #rmt_sql = "select * from rmt_products where(commodity_code='#{seq_rmt_group[0].commodity}' and variety_code='#{rmt_variety_code}' and ripe_point_code='#{ripe_point}' and size_code = 'UNS' and rmt_product_type_code = 'orchard_run') order by rmt_product_code ASC"

      rmt_sql      = "SELECT rmt_products.* FROM ripe_points INNER JOIN rmt_products ON (ripe_points.id =rmt_products.ripe_point_id) WHERE commodity_code = '#{seq_rmt_group[0].commodity}'  AND variety_code = '#{rmt_variety_code}'  AND
                 ripe_points.pc_code_code = '#{seq_rmt_group[0].pc_code.to_s}' AND size_code = 'UNS' AND rmt_product_type_code = 'orchard_run' order by rmt_product_code ASC"


      rmt_products = RmtProduct.find_by_sql(rmt_sql)
      raise "A raw material product could not be found. Sql is: " + rmt_sql if !rmt_products[0]
      rmt_product = rmt_products[0]

      schedule    = ProductionSchedule.new
      season      = Season.find_by_season_code(self.season + "_" + seq_rmt_group[0].commodity.upcase)
      raise "Season not found for season_code " + self.season + "_" + seq_rmt_group[0].commodity.upcase if !season
      schedule.season_code = season.season_code
      schedule.season_id   = season.id
      if !self.doc_source #kromco uses swap around of last and first char
        iso_week_code = seq_rmt_group[0].pick_reference.slice(3, 1) +seq_rmt_group[0].pick_reference.slice(0, 1)
        #iso_week = IsoWeek.find_by_iso_week_code(seq_rmt_group[0].pick_reference.slice(3,1) +seq_rmt_group[0].pick_reference.slice(0,1))
      else #external parties (edi docs) uses 2nd and 3rd char)
        iso_week_code = seq_rmt_group[0].pick_reference.slice(1, 1) +seq_rmt_group[0].pick_reference.slice(2, 1)
        #iso_week = IsoWeek.find_by_iso_week_code(seq_rmt_group[0].pick_reference.slice(1,1) +seq_rmt_group[0].pick_reference.slice(2,1))
      end
      iso_week = IsoWeek.find_by_iso_week_code(iso_week_code)
      if iso_week.nil? && iso_week_code[0, 1] == '0'
        iso_week = IsoWeek.find_by_iso_week_code(iso_week_code[1, 1])
      end
      raise "IsoWeek not found for iso_week_code: #{iso_week_code}." if iso_week.nil?

      schedule.iso_week_code                   = iso_week.iso_week_code.to_s
      schedule.iso_week_id                     = iso_week.id


      schedule.variety_code                    = rmt_variety_code
      schedule.production_schedule_status_code = "depot"
      schedule.planned_start_date              = self.created_on
      schedule.planned_end_date                = Time.now
      schedule.farm_pack                       = false
      schedule.is_depot_schedule               = true
      schedule.create

      rmt_setup                          = RmtSetup.new
      rmt_setup.commodity_code           = rmt_product.commodity_code
      rmt_setup.variety_code             = rmt_product.variety_code
      rmt_setup.size_code                = rmt_product.size_code
      rmt_setup.product_class_code       = rmt_product.product_class_code
      rmt_setup.ripe_point_code          = rmt_product.ripe_point_code
      rmt_setup.treatment_code           = rmt_product.treatment_code
      rmt_setup.pc_code                  = seq_rmt_group[0].pc_code
      rmt_setup.rmt_product_id           = rmt_product.id
      rmt_setup.production_schedule_id   = schedule.id
      rmt_setup.production_schedule_name = schedule.production_schedule_name
      rmt_setup.rmt_product_code         = rmt_product.rmt_product_code
      rmt_setup.cold_store_code          = "NO"
      rmt_setup.create

      puc_groups = seq_rmt_group.group(['puc'], nil, true)
      puc_groups.each do |puc_group|
        run                          = ProductionRun.new
        run.is_depot_run             = true
        run.production_schedule_name = schedule.production_schedule_name
        run.production_schedule_id   = schedule.id
        run.farm_code                = "DEPOT_UNKNOWN"
        run.day_line_batch_number    = ProductionRun.next_line_day_sequence_number(line.id)
        run.batch_code               = puc_group[0].batch_code
        run.line_code                = line.line_code
        run.line_id                  = line.id
        run.shift_code               = 'UNKNOWN'
        run.shift_id                 = shift.id
        run.puc_code                 = puc_group[0].puc
        run.production_run_stage     = "depot_run"
        run.production_run_status    = "depot_run"
        run.create
        puc_group.each do |mapped_sequence|
          mapped_sequence.production_run_code = run.production_run_code
          mapped_sequence.production_run_id   = run.id
          mapped_sequence.erp_cultivar        = input_variety.rmt_variety_code + "_" + input_variety.rmt_variety_description.to_s
          mapped_sequence.update

        end

      end

    end

    return mapped_sequences
  end

  #record must be of type FixedLenRecord
  def IntakeHeader.create_from_pdf417(fixed_len_record)

    #---------------------------------------------------------------------------------
    #intake can only take place if no pallets have been taken in with this consignment
    #---------------------------------------------------------------------------------
    if Pallet.find_by_consignment_note_number(fixed_len_record.fields['consignment_note_number'])
      #raise "An intake for pallets with this consignment: " + fixed_len_record.fields.consignment_note_number + " has already been done"
    end

    header = IntakeHeader.new
    header.import(fixed_len_record.fields)
    header.intake_header_number = MesControlFile.next_seq_web(5)
    header.intake_type_code     = "FI"
    header.order_number         = fixed_len_record.fields['pack_order_number']
    header.header_status        = "EDI_RECEIVED"
    header.doc_source           = "pdf417"
    header.save!
    return header

  end

  #----------------------------------------------------------------------------------------------------------------
  #  This is called after depot pallet and cartons have been created. It creates a ppecb inspection record and then
  #  copies the fields
  #  Change as from 280814: ppecb record created for every pallet on intake
  #-----------------------------------------------------------------------------------------------------------------
  def create_inspection_records
    #existing_inspection = get_existing_inspection
    self.transaction do
     # if !existing_inspection
      self.pallets.each do |pallet|

       # pallet                           = self.pallets[0]
        depot_pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(pallet.pallet_number, self.id)

        inspection_date = depot_pallet.inspection_date == nil ? self.inspection_date : depot_pallet.inspection_date
        inspection_point = depot_pallet.inspection_point == nil ? self.inspection_point : depot_pallet.inspection_point
        inspector_number = depot_pallet.inspector_number == nil ? self.inspector_number : depot_pallet.inspector_number


        carton                           = pallet.cartons[0]

        inspection                       = PpecbInspection.new
        inspection.carton_id             = carton.id
        inspection.carton_number         = carton.carton_number
        inspection.carton_qty            = pallet.cartons.length()
        inspection.inspection_report     = self.id.to_s

        inspection.created_at            = inspection_date
        inspection.grade_code            = carton.grade_code
        inspection.inspection_level_code = 'RESULT-TRANSFER'

        inspection.inspection_point      = inspection_point

        inspection.inspection_type_code  = self.inspection_type_code
        inspection.inspection_type_id    = InspectionType.find_by_inspection_type_code_and_grade_code(self.inspection_type_code, carton.grade_code).id
        inspection.inspector_number      =  inspector_number
        inspection.pallet_id             = pallet.id
        inspection.pallet_number         = pallet.pallet_number
        inspection.passed                = true
        inspection.target_market_code    = carton.target_market_code
        inspection.ignore_cascade_ctn_updates   = true
        inspection.save!
     # end



      #update all pallets without an inspection
      pallet_update_query = ActiveRecord::Base.extend_update_sql_with_request("update pallets set ppecb_inspection_id = #{inspection.id}, qc_status_code = 'INSPECTED',qc_result_status = 'PASSED'
                     WHERE pallets.id = #{pallet.id} ")

      Pallet.connection.execute(pallet_update_query)

      carton_update_query = ActiveRecord::Base.extend_update_sql_with_request("update cartons set ppecb_inspection_id = #{inspection.id}, qc_status_code = 'INSPECTED',qc_result_status = 'PASSED'
                               where cartons.pallet_id = #{pallet.id}
                               ")

      Pallet.connection.execute(carton_update_query)
    end
  end


  end


  def get_existing_inspection

    query = "SELECT
            pallets.pallet_number,pallets.ppecb_inspection_id,pallets.qc_result_status, pallets.qc_status_code, ppecb_inspections.*
            FROM
            pallets
             join ppecb_inspections on
            pallets.ppecb_inspection_id = ppecb_inspections.id

           where pallets.ppecb_inspection_id is null and
           pallets.intake_header_id = #{self.id}

           order by pallets.id asc limit 1 "

    return self.connection.select_one(query)


  end


  def validate
    is_valid = true

#    if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:org_short_description=>self.org_short_description}], self,true)
#    end
#    if is_valid
#      is_valid = set_organization
#    end
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:intake_type_code=>self.intake_type_code}], self)
    end

    if self.intake_type_code=='FI' && is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:account_code => self.account_code}],self)
    end

    if is_valid
      is_valid = set_intake_type
    end

    if self.new_record? && is_valid
      unique?
    end

 #   if is_valid
 #     is_valid = ModelHelper::Validations.validate_combos([{:depot_code=>self.depot_code}], self,true)
 #   end
 #   if is_valid
 #     is_valid = set_depot_code
 #   end
#
#     if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:puc_code=>self.puc_code}], self,true)
#    end
#    if is_valid
#      is_valid = set_puc_code
#    end
#
#    if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:account_code=>self.account_code}], self,true)
#    end
#    if is_valid
#      is_valid = set_account
#    end
#
#     if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:supplier=>self.supplier}], self,true)
#    end
#    if is_valid
#      is_valid = set_supplier
#    end
#
#
  end


  def unique?
    exists = self.connection.select_one("select id from intake_headers where consignment_note_number = '#{self.consignment_note_number}' and upper(header_status) <> 'EDI_RECEIVED' and upper(header_status) <> 'CANCELED'")
    if exists
      errors.add_to_base("A header with consignment #{self.consignment_note_number} already exists ")
      return false
    end
    return true
  end

  def set_intake_type
    intake_type = IntakeType.find_by_intake_type_code(self.intake_type_code)
    if intake_type
      self.intake_type = intake_type
      return true
    else
      errors.add_to_base("You must select 'intake_type_code'")
      return false
    end
  end

  def set_depot_code
    depot = Depot.find_by_depot_code(self.depot_code)
    if depot
      self.depot = depot
      return true
    else
      errors.add_to_base("You must select 'depot_code'")
      return false
    end
  end

  def set_puc_code
    puc = Puc.find_by_puc_code(self.puc_code)
    if puc
      self.puc = puc
      return true
    else
      errors.add_to_base("You must select 'puc_code'")
      return false
    end
  end

  def set_account
    account = Account.find_by_account_code(self.account_code)
    if account
      self.account = account
    else
      errors.add_to_base("You must select 'account_code'")
      return false
    end
  end

  def set_supplier
    parties_role = PartiesRole.find_by_party_name_and_role_name(self.supplier, "SUPPLIER")
    if parties_role
      self.parties_role = parties_role
      return true
    else
      errors.add_to_base("You must select a 'supplier' please")
      return false
    end
  end

  def set_organization
    organization = Organization.find_by_short_description(self.org_short_description)
    if organization
      self.organization = organization
      return true
    else
      errors.add_to_base("You must select an 'organization' please!")
      return false
    end
  end

  def IntakeHeader.get_missing_master_files(intake_header_id, return_hash_of_missing_mf=nil)
    #intake_header = session[:intake_header]
    puc_query             = "SELECT DISTINCT pallet_sequences.puc FROM (pallet_sequences JOIN depot_pallets ON(pallet_sequences.depot_pallet_id=depot_pallets.id) "
    puc_query             += " JOIN intake_headers ON(depot_pallets.intake_header_id=intake_headers.id)) "
    puc_query             += " WHERE intake_headers.id='#{intake_header_id}'"

    target_market_query   = "SELECT DISTINCT pallet_sequences.target_market FROM (pallet_sequences JOIN depot_pallets ON(pallet_sequences.depot_pallet_id=depot_pallets.id) "
    target_market_query   += " JOIN intake_headers ON(depot_pallets.intake_header_id=intake_headers.id)) "
    target_market_query   += " WHERE intake_headers.id='#{intake_header_id}'"

    inventory_code_query  = "SELECT DISTINCT pallet_sequences.inventory_code FROM (pallet_sequences JOIN depot_pallets ON(pallet_sequences.depot_pallet_id=depot_pallets.id) "
    inventory_code_query  += " JOIN intake_headers ON(depot_pallets.intake_header_id=intake_headers.id)) "
    inventory_code_query  += " WHERE intake_headers.id='#{intake_header_id}'"

    header                = IntakeHeader.find(intake_header_id)
    pfp_query             = "select depot_pallet_number from depot_pallets where intake_header_id= #{intake_header_id.to_s} and pallet_format_product_code is null"

    pucs                  = ActiveRecord::Base.connection.select_all(puc_query)
    target_markets        = ActiveRecord::Base.connection.select_all(target_market_query)
    inventory_codes       = ActiveRecord::Base.connection.select_all(inventory_code_query)
    pallet_nums           = DepotPallet.find_by_sql(pfp_query).map { |p| p.depot_pallet_number.to_s }

    missing_master_files  = 0

    pucs_array            = Array.new
    target_markets_array  = Array.new
    inventory_codes_array = Array.new
    if pucs.length != 0
      pucs.each do |puc_code|
        puc = Puc.find_by_puc_code(puc_code["puc"].strip())
        if !puc
          pucs_array.push puc_code["puc"]
          missing_master_files += 1
        end
      end
      #missing_master_files += pucs.length
    end
    if target_markets.length != 0
      target_markets.each do |tm_code|
        tm = TargetMarket.find_by_target_market_name(tm_code["target_market"].strip())
        if !tm
          target_markets_array.push tm_code["target_market"]
          missing_master_files += 1
        end
      end
      #missing_master_files += target_markets.length
    end
    if inventory_codes.length != 0
      inventory_codes.each do |inv_code|
        inv = InventoryCode.find_by_inventory_code(inv_code["inventory_code"].strip())
        if !inv
          inventory_codes_array.push inv_code["inventory_code"]
          missing_master_files += 1
        end
      end
      #missing_master_files += inventory_codes.length
    end


    missing_master_files += pallet_nums.length()

    missing_master_files += 1 if !header.location_code

    if return_hash_of_missing_mf != nil
      mf_hash                    = Hash.new
      mf_hash["pucs"]            = pucs_array
      mf_hash["target_markets"]  = target_markets_array
      mf_hash["inventory_codes"] = inventory_codes_array
      mf_hash["pallet_nums"]     = pallet_nums
      mf_hash['no_location'] = true if !header.location_code
      return mf_hash
    else
      return missing_master_files
    end
  end


  def send_edi()

    doc_type = self.intake_type_code.upcase == "TI" ? "ti" : "pi"
    EdiOutProposal.send_doc(self, doc_type)
  end

  def set_status

    if self.id
      old_state = IntakeHeader.find(self.id)
      if old_state.header_status != self.header_status || @new_rec
        intake_header_status                         = IntakeHeaderStatus.new
        intake_header_status.intake_header_id        = self.id
        intake_header_status.intake_status_code      = self.header_status
        intake_header_status.intake_status_date_time = Time.now.to_formatted_s(:db)
        intake_header_status.create
        if self.header_status == "LOAD_RECEIVED"
          if self.transfer_inspection_records
             create_inspection_records
          end
          send_edi()
          log_pallets
        end

      else
        new_status = calc_status
        self.header_status = new_status if  new_status
        if old_state.header_status != self.header_status
          intake_header_status                         = IntakeHeaderStatus.new
          intake_header_status.intake_header_id        = self.id
          intake_header_status.intake_status_code      = self.header_status
          intake_header_status.intake_status_date_time = Time.now.to_formatted_s(:db)
          intake_header_status.create
        end
      end

    end

  end

  def after_create
    @new_rec = true
    set_status
  end


  def before_update
    set_status
  end


  def calc_status()

    return nil if  self.header_status.upcase == "MAPPING_COMPLETE"||self.header_status.upcase == "LOAD_RECEIVED"||self.header_status.upcase.index("EDI")

    intake_header    = self
    depot_pallets    = DepotPallet.find_by_sql("SELECT * FROM depot_pallets WHERE intake_header_id='#{self.id}'")

    mapping_complete = IntakeHeader.mapping_complete?(self.id)
    missing_mf       = IntakeHeader.get_missing_master_files(self.id)
    if mapping_complete && missing_mf == 0 && self.location_code
      self.reverse_engineer_schedules_and_runs
      return "MAPPING_COMPLETE"
    elsif mapping_complete && missing_mf > 0
      return "FRUITSPEC_MAPPED"
    elsif intake_header.qty_pallets == depot_pallets.length
      return "PALLETS_CAPTURED"
    elsif depot_pallets.length > 0 && depot_pallets.length < intake_header.qty_pallets
      return "CAPTURING_PALLETS"
    else
      return self.header_status
    end
  end

  def IntakeHeader.mapping_complete?(intake_header_id)
    intake_header    = IntakeHeader.find(intake_header_id)
    mapped_query     = "SELECT DISTINCT mapped_pallet_sequences.id FROM
   (depot_pallets INNER JOIN intake_headers ON(depot_pallets.intake_header_id = intake_headers.id)
    INNER JOIN pallet_sequences ON(intake_headers.id = pallet_sequences.intake_header_id)
    INNER JOIN mapped_pallet_sequences ON(pallet_sequences.id = mapped_pallet_sequences.pallet_sequence_id))
    WHERE intake_headers.id = #{intake_header.id}"

    mapped_sequences = ActiveRecord::Base.connection.select_all(mapped_query).length()
    sequences        = Carton.connection.select_one("select count(*) from pallet_sequences where intake_header_id = #{intake_header.id}")['count'].to_i

    if mapped_sequences == sequences && sequences > 0
      return true
    else
      return false
    end

  end

end
