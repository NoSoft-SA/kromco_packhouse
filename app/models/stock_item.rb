class StockItem < ActiveRecord::Base
  attr_accessor :reference_number, :transaction_business_name_code, :transaction_type_code, :farm_code, :truck_code
  attr_accessor :inventory_receipt_reference_number, :party_type_name, :party_name
  #attr_accessor :party_name
  #	===========================
  # 	Association declarations:
  #	===========================
    belongs_to :stock_type
    #belongs_to :location
    belongs_to :inventory_transaction
    belongs_to :parties_role
    belongs_to :status
   belongs_to  :location
    #belongs_to :party
 
  #	============================
  #	 Validations declarations:
  #	============================
#	validates_presence_of :stock_type_code
#	validates_presence_of :location_code
#	validates_presence_of :inventory_reference
#	#validates_presence_of :party_role_id
#	validates_presence_of :inventory_quantity
#	validates_presence_of :status_code
#	#validates_presence_of :object_id
#	#validates_presence_of :current_reference_id
#	validates_numericality_of :inventory_quantity
#	validates_numericality_of :inventory_reference
#  validates_uniqueness_of :inventory_reference
#	#validates_numericallity_of :party_role_id
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
     # first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:stock_type_code => self.stock_type_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_stock_type
#	 end
#
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_location
#	 end
#
#	 #if is_valid
#	 #   is_valid = ModelHelper::Validations.validate_combos([{:party_name => self.party_name}],self)
#	 #end
#	 #if is_valid
#	 #   is_valid = set_party
#	 #end
#
#	 if is_valid
#	    is_valid = set_parties_role
#	 end
#
#	 #if is_valid
#	 #  is_valid = set_current_location
#	 #end
#
#    if is_valid
#      is_valid = set_status
#    end
	 
  end
  
  
#  def after_find
#     #puts "STOCK ITEM After find method entered!"
#     set_derived_fields
#     #puts "REF NO. : " + self.reference_number.to_s
#  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  def set_stock_type
    stock_type = StockType.find_by_stock_type_code(self.stock_type_code);
    if stock_type != nil
      self.stock_type = stock_type
      return true
    else
      errors.add_to_base("Field: 'stock_type_code' is invalid- it must be unique")
      return false
    end
  end
  
  def set_location
    location = Location.find_by_location_code(self.location_code)
    if location != nil
      self.location_code = location.location_code
      self.location_id = location.id
      return true
    else
      errors.add_to_base("Field: 'location_code' is invalid- it must be unique")
      return false
    end
  end
  
  def set_party
    party = Party.find_by_party_name(self.party_name)
    if party
       self.party = party
       return true
    else
      errors.add_to_base("Field: 'party_name' is invalid- it must be unique")
      return false
    end
  end
  
  def set_current_location
     if self.location_code
        self.current_location = self.location_code
        return true
     else
       errors.add_to_base("Could not assign current_location code!")
       return false
     end
  end
  
  def set_parties_role
     parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name, self.party_name, self.parties_role_name)
     if parties_role
        self.parties_role = parties_role
        return true
     else
        errors.add_to_base("combination of: 'party_role_name' is invalid- it must be unique")
        return false
     end
  end

  def set_status
    status = Status.find_by_status_code(self.status_code)
    if status
      self.status = status
      return true
    else
      errors.add_to_base("Combination of : 'status_code' is invalid- it must be unique")
      return false
    end
  end
 
  
  def set_derived_fields
     inventory_transaction = self.inventory_transaction
     inventory_receipt = self.inventory_transaction.inventory_receipt
     self.reference_number = inventory_transaction.reference_number
     self.transaction_business_name_code = inventory_transaction.transaction_business_name_code
     self.transaction_type_code = inventory_transaction.transaction_type_code
     self.farm_code = inventory_receipt.farm_code
     self.truck_code = inventory_receipt.truck_code
  end
  
  def process_derived_fields(params)
     self.reference_number = params[:reference_number]
     self.transaction_business_name_code = params[:transaction_business_name_code]
     self.transaction_type_code = params[:transaction_type_code]
     self.farm_code = params[:farm_code]
     self.truck_code = params[:truck_code]
  end

  def update_changed_fields
    changed_fields = self.changed_fields
    if changed_fields != nil && changed_fields.length > 0
      if changed_fields.has_key?("parties_role_name")
        parties_role_name = changed_fields.fetch("parties_role_name")[1]
        parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name, self.party_name, parties_role_name)
        self.parties_role = parties_role
        self.party_name = self.party_name
      end
      if changed_fields.has_key?("location_code")
        location_code = changed_fields.fetch("location_code")[1]
        location = Location.find_by_location_code(location_code)
        self.location_code = location.location_code
        #self.current_location = location.location_code
        self.location_id = location.id
      end
    end
  end
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end