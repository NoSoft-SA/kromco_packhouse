class IntakeHeadersProduction < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================

  attr_accessor :user

#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :organization_code
  validates_presence_of :order_number
  validates_presence_of :location_type_code
  validates_presence_of :location_code
#  validates_presence_of :markerting_org_code
#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true
  end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================

  def after_create
    self.update_attribute(:updated_on,self.created_on)
  end

  def log_pallets
    log = PalletDocumentLog.new
    query = "insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at)
                      select pallets.id, '#{self.consignment_note_number}','intake_header_production','kromco_intakes','#{self.user}','#{Time.new().to_formatted_s(:db)}'
                     from pallets where pallets.consignment_note_number = '#{self.consignment_note_number}'"
    self.connection.execute(query)

  end


  def change_header_status(header_status, user)
    old_status = self.header_status
    if  old_status != header_status
      self.header_status = header_status
      header_status_rec = IntakeHeaderProductionStatus.new
      #status = Status.find_by_status_code(header_status)
      header_status_rec.intake_status_code = header_status
      header_status_rec.intake_status_date_time = Time.now
      header_status_rec.intake_status_username = user
      header_status_rec.intake_header_production_id = self.id
      #header_status.status_id = status.id if status
      header_status_rec.save
      self.update
      if  header_status.upcase == "INTAKE_HEADER_ACCEPTED"
        #NewOutboxRecord.new("kromco_intake_accepted", self) if old_status != "INTAKE_HEADER_RECONFIGURING"
        log_pallets
      end

      send_edi(user) #UNCOMMENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      RwRun.complete_intake_header(self.id) if header_status.upcase == "INTAKE_HEADER_ACCEPTED" && (old_status == "INTAKE_HEADER_RECONFIGURING" || old_status == "INTAKE_HEADER_MARKED_FOR_DELETION")
    end

  end

  def self.can_change?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_ACCEPTED")
      return true
    end
    return false
  end

  def self.can_cancel?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_CREATED")
      return true
    end
    return false
  end

  def self.can_mark_for_delete?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_ACCEPTED")
      return true
    end
    return false
  end

  def self.can_delete?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_MARKED_FOR_DELETION")
      return true
    end
    return false
  end

  def self.can_send_edi?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_ACCEPTED" || header_status.upcase == "INTAKE_HEADER_MARKED_FOR_DELETION")
      return true
    end
    return false
  end

  def self.can_print?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_ACCEPTED" || header_status.upcase == "INTAKE_HEADER_MARKED_FOR_DELETION")
      return true
    end
    return false
  end

  def self.can_edit?(header_status)
    if (header_status.upcase == "INTAKE_HEADER_CREATED" || header_status.upcase == "INTAKE_HEADER_RECONFIGURING")
      return true
    end
    return false
  end

  def self.can_view?(header_status)
    true
  end


  def send_edi(user)
    if (self.header_status.upcase == "INTAKE_HEADER_ACCEPTED")
      EdiOutProposal.send_doc(self, 'PI')
     
      self.update_attribute(:intake_header_edi_status, "PI_EDI_REQUESTED")

      intake_edi_status = IntakeEdiStatus.new
      intake_edi_status.intake_edi_status_code = "PI_EDI_REQUESTED" #status.status_code
      intake_edi_status.intake_edi_status_date = Time.now
      intake_edi_status.intake_edi_status_username = user
      intake_edi_status.intake_header_id = self.id
#    intake_edi_status.status_id = status.id
      intake_edi_status.save!
    elsif (self.header_status.upcase == "INTAKE_HEADER_MARKED_FOR_DELETION")
      #EdiOutProposal.send_doc(self,'PD')
      EdiOutProposal.send_doc(self,'PI')

      self.update_attribute(:intake_header_edi_status, "DELETE_EDI_REQUESTED")

      intake_edi_status = IntakeEdiStatus.new
      intake_edi_status.intake_edi_status_code = "DELETE_EDI_REQUESTED" #status.status_code
      intake_edi_status.intake_edi_status_date = Time.now
      intake_edi_status.intake_edi_status_username = @user
      intake_edi_status.intake_header_id = self.id

      intake_edi_status.save!
    end


  end

 def find_intake_pallets(query)

    query << "select distinct pallets.id,cartons.season_code,cartons.organization_code,cartons.commodity_code,cartons.grade_code,marks.brand_code
              ,cartons.variety_short_long,cartons.target_market_code,cartons.puc,pallets.account_code,cartons.inventory_code
              ,pallets.build_status,cartons.sell_by_code,cartons.inspection_type_code,cartons.qc_result_status
               ,cartons.qc_status_code,pallets.is_depot_pallet,cartons.carton_number
               ,pallets.pallet_format_product_code,cartons.pallet_number,cartons.actual_size_count_code,cartons.old_pack_code
                from pallets
                 INNER JOIN cartons ON (pallets.id = cartons.pallet_id)
                INNER JOIN marks ON (cartons.carton_mark_code = marks.mark_code)
                INNER JOIN  (SELECT min(public.cartons.id) AS id,public.cartons.pallet_id FROM public.cartons
                INNER JOIN public.pallets ON (public.cartons.pallet_id = public.pallets.id)
                where pallet_id > 360000 and public.pallets.quarantine is null
                and (pallets.consignment_note_number = '#{self.consignment_note_number}')  GROUP BY public.cartons.pallet_id,public.pallets.consignment_note_number) as min_cartons   ON (cartons.id = min_cartons.id)
              where(pallets.consignment_note_number = '#{self.consignment_note_number}')"


    return ActiveRecord::Base.connection.select_all(query)

  end

  def calc_missing_gtin_pallets(intake_header_pallets)
    invalid_pallets = Hash.new
    invalid_pallets[:gtin] = 0
    invalid_pallets[:tm] = 0
        
    intake_header_pallets.each do |con_pallet|
      found_gtin = Gtin.get_gtin(self.created_on, self.organization_code, con_pallet.commodity_code, con_pallet.variety_short_long.split("_")[0], con_pallet.brand_code, con_pallet.old_pack_code, con_pallet.actual_size_count_code, con_pallet.inventory_code.split('_')[0], con_pallet.grade_code)
      if (found_gtin)
        con_pallet["gtin_found"] = true
        tm_name = con_pallet['target_market_code'].split("_")[0]
#        puts "Foung Gtin for pallet = " + con_pallet.pallet_number + " ::  " + found_gtin.to_s
        gtin_tm = GtinTargetMarket.find_by_gtin_code_and_target_market_code(found_gtin, tm_name)
        if gtin_tm
          con_pallet["gtin_tm"] = true
#          puts "Found GtinTm  for Gtin = " + found_gtin.to_s + " ::  " + gtin_tm[0].to_s
        else
          invalid_pallets[:tm] += 1
          con_pallet["gtin_tm"] = false
        end
      else
        invalid_pallets[:gtin] += 1
        con_pallet["gtin_found"] = false
      end
    end
    return invalid_pallets
  end

end
