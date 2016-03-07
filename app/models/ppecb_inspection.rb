class PpecbInspection < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================

  belongs_to :inspection_type
  belongs_to :carton
  belongs_to :pallet

  attr_accessor :production_run_code,:ignore_cascade_ctn_updates,
                :product_size,:line_code,:carton_number,:actual_size_count_code,:season,:puc,:no_bags_insp,:grade_code,:target_market_code,:no_fruit_insp ,:brand_code,:product_weight,:commodity_code,:variety,:pick_reference,:pallet_number,:batch_code


#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================


  def PpecbInspection.most_recent_inspection?(carton_num)
    carton = Carton.find_by_carton_number(carton_num)
    if !carton
      carton = RwActiveCarton.find_by_carton_number(carton_num)
    end

    if carton
      most_recent = PpecbInspection.find_by_sql("select * from ppecb_inspections where pallet_number = '#{carton.pallet_number}' order by updated_at desc limit 1")[0]
      return most_recent
    else
      return nil
    end
  end


  def after_create


    return true if self.inspection_level_code.index("HG")

    if !ignore_cascade_ctn_updates
      self.pallet.cartons.each do |ctn|
        ctn.qc_status_code      = self.pallet.qc_status_code
        ctn.qc_result_status    = self.pallet.qc_result_status
        ctn.ppecb_inspection_id = self.id
        ctn.update
      end
    end
    self.pallet.ppecb_inspection_id = self.id
    self.pallet.update

    if self.pallet.organization_code == "CA"
	EdiOutProposal.send_doc(self, 'PM') if self.inspection_level_code.upcase == "RE-INSPECTION"
    end
    
    return true
  end

  def validate


    self.updated_at = Time.now() if self.new_record?

    self.grade_code           = self.carton.grade_code
    self.target_market_code   = self.carton.target_market_code
    self.inspection_type_code = self.carton.inspection_type_code
    if self.carton.commodity_code.upcase == "AP"||self.carton.commodity_code.upcase == "PR"
      self.carton_qty = self.carton.pallet.cpp
    else
      self.carton_qty = self.carton.pallet.get_carton_count()
    end

    set_inspection_type



    if ActiveRequest.get_active_request.program.index("run")
      have_permission = authorise('runs', "can_inspect_for_#{self.inspection_type_code}", ActiveRequest.get_active_request.user)
      raise MesScada::InfoError, "You do not have permission for this inspection type. You need permission called: can_inspect_for_#{self.inspection_type_code}" if ! have_permission
    end


  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_inspection_type
    if self.inspection_level_code.upcase.index("HG")
          inspection_type = InspectionType.find_by_inspection_type_code_and_grade_code("KROMCO", self.grade_code)
          if inspection_type
            self.inspection_type_code = "KROMCO"
            self.inspection_type = inspection_type
            return true
          else
            errors.add_to_base("combination of: 'KROMCO' and 'grade_code' NOT FOUND")
            return false
          end

    else
        inspection_type = InspectionType.find_by_inspection_type_code_and_grade_code(self.inspection_type_code, self.grade_code)
        if inspection_type != nil
          self.inspection_type = inspection_type
          return true
        else
          errors.add_to_base("combination of: 'inspection_type_code' and 'grade_code'  is invalid- it must be unique")
          return false
        end
    end

  end

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: inspection_type_id
#	------------------------------------------------------------------------------------------

  def self.get_all_inspection_type_codes

    inspection_type_codes = InspectionType.find_by_sql('select distinct inspection_type_code from inspection_types').map { |g| [g.inspection_type_code] }
  end


  def self.get_all_grade_codes

    grade_codes = InspectionType.find_by_sql('select distinct grade_code from inspection_types').map { |g| [g.grade_code] }
  end


  def self.grade_codes_for_inspection_type_code(inspection_type_code)

    grade_codes = InspectionType.find_by_sql("Select distinct grade_code from inspection_types where inspection_type_code = '#{inspection_type_code}'").map { |g| [g.grade_code] }

    grade_codes.unshift("<empty>")
  end


end
