class PalletSequence < ActiveRecord::Base

  attr_accessor :consignment_note_number, :intake_header_number, :pucs, :target_markets, :inventory_codes,:pallet_nums,:no_location
  
  belongs_to :pallet
  belongs_to :depot_pallet
  has_many :mapped_pallet_sequences ,:dependent=> :delete_all

  validates_presence_of :depot_pallet_number
  #validates_presence_of :pallet_sequence_number
  
  def validate
    is_valid = true

    if is_valid
      is_valid = is_valid_prick_ref?
    end

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:depot_pallet_number=>self.depot_pallet_number, :intake_header_id=>self.intake_header_id}], self)
    end
    if is_valid
      is_valid = check_depot_pallet_number_and_intake_header_id
    end

    self.pack_date_time = DepotPallet.calc_packdate_from_pick_ref(self.pick_reference,self.depot_pallet.intake_header.created_on.year) if is_valid

  end

  def is_valid_prick_ref?
    if(self.pick_reference)
      iso_week = (self.pick_reference.to_s[3,4] + self.pick_reference.to_s[0,1]).to_i
      if(iso_week < 0 || iso_week > 52)
        self.errors.add(:pick_reference,"is invalid : you entered a pick ref iso week #{iso_week}")
        return false
      end
    end
    return true
  end
  
  def before_update
    old_rec = PalletSequence.find(self.id)
    mapped_seq = MappedPalletSequence.find_by_pallet_sequence_id(self.id)
    @need_header_update = false
    if  mapped_seq
      if old_rec.organization != self.organization ||old_rec.commodity != self.commodity ||old_rec.variety != self.variety || old_rec.grade != self.grade ||old_rec.count != self.count||old_rec.brand != self.brand||old_rec.pack_type != self.pack_type ||old_rec.class_code != self.class_code
         mapped_seq.destroy
         self.mapped_date_time = nil
        @need_header_update = true
      end

      if  !@need_header_update && (old_rec.target_market != self.target_market || old_rec.inventory_code != self.inventory_code || old_rec.pick_reference != self.pick_reference ||old_rec.channel != self.channel || old_rec.puc != self.puc || old_rec.sell_by_date != self.sell_by_date ||old_rec.product_characteristics != self.product_characteristics ||old_rec.batch_code != self.batch_code ||old_rec.class_code != self.class_code)
          mapped_seq.target_market = self.target_market
          mapped_seq.inventory_code = self.inventory_code
          mapped_seq.pick_reference = self.pick_reference
          mapped_seq.channel = self.channel
          mapped_seq.puc = self.puc
          mapped_seq.sell_by_date =self.sell_by_date
          mapped_seq.product_characteristics = self.product_characteristics
          mapped_seq.batch_code = self.batch_code
          mapped_seq.class_code = self.class_code
          @need_header_update = true
      end
    end
  end

  def after_update
       IntakeHeader.find(self.intake_header_id).update if  @need_header_update
       @need_header_update = nil
  end


  def check_depot_pallet_number_and_intake_header_id
    depot_pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(self.depot_pallet_number, self.intake_header_id)
    if depot_pallet
      self.depot_pallet = depot_pallet
      return true
    else
      errors.add_to_base("depot pallet number doesn't exist!")
      return false
    end
  end

end
