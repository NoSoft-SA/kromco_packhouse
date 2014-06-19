class ProductionSchedule < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
    attr_accessor :variety,:has_runs,:ripe_point_code,:class_code,:size_code,:rmt_type,:source_rmt_product,:bin_type,
                  :organization_marketing,:organization_retailer,:mark_retail_unit_description,
                  :target_market_description

  attr_writer :pc_code,:track_indicator_code
    
	belongs_to :iso_week
	belongs_to :season
	has_one :rmt_setup,:dependent => :destroy
	has_one :bintip_criterium,:dependent => :destroy
	has_many :production_runs
	has_many :carton_setups,:dependent => :destroy
	has_many :rebin_setups,:dependent => :destroy
  has_many :trade_environment_setups,:dependent => :destroy
  has_many :processing_setups,:dependent => :destroy
  has_one :pallet_criterium,:dependent => :destroy
    
    
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :farm_group_code
#	=====================
#	 Complex validations:
#	=====================

  #-------------------------------------------------------------------------------------------------------------------------------
  #
  #Attribute readers for columns that does not belong to this model, but for which attr_writers have been defined in order to set
  #default values on the search form- we need the readers, so that grid can find them
  #-------------------------------------------------------------------------------------------------------------------------------
  def pc_code
   if @pc_code
     return @pc_code
   else
     return self.attributes['pc_code']
   end
  end
  
  def track_indicator_code
   if @track_indicator_code
     return @track_indicator_code
   else
     return self.attributes['track_indicator_code']
   end
  end


 def update_all_carton_setups_templates_and_labels
   n_build = 0
    #if self.production_schedule_status_code == "re_opened"
       self.transaction do
          self.carton_setups.each do |carton_setup|
            if carton_setup.carton_template 
                if !carton_setup.carton_setup_update_timestamp||carton_setup.carton_template.last_update_date_time == nil
                   carton_setup.fg_setup.build_templates_and_labels
                   n_build += 1
                elsif carton_setup.carton_template.last_update_date_time < carton_setup.carton_setup_update_timestamp.last_update_timestamp
                   carton_setup.fg_setup.build_templates_and_labels
                   n_build += 1
                end
            else
              carton_setup.fg_setup.build_templates_and_labels
              n_build += 1
            end
          end
       end
    #end
    return n_build
 end
#-----------------------------------------------------------------------
#This method creates copies of all setup data linked to the schedule that
#was chosen to use as a template for a new schedule
#---------------------------------------------------------------
def create_from_template(new_schedule_data)
  new_schedule = nil
 self.transaction do
  new_schedule = ProductionSchedule.new(new_schedule_data)
  new_schedule.variety_code = self.variety_code
  new_schedule.production_schedule_status_code = "open"
  new_schedule.save
  new_schedule.add_variety_to_schedule_name(self.variety_code)
  new_schedule.update
  
  #copy trade environment setup data
  self.trade_environment_setups.each do |trade_env|
    new_trade_env = TradeEnvironmentSetup.new
    trade_env.export_attributes(new_trade_env,true)
    new_trade_env.production_schedule = new_schedule
    new_trade_env.production_schedule_code = new_schedule.production_schedule_name
    new_trade_env.create
    
  end
  
  #copy rmt_setup
  if self.rmt_setup
    new_rmt_setup = RmtSetup.new
    
    #------------------------------------------------------------------------------
    #See if user provided a different size, class or ripe point or rmt type, if so:
    # -> try to find an matching rmt_product
    # -> IF not existing, create new one
    # -> overwrite relevant rmt_setup fields
    #------------------------------------------------------------------------------
    if self.size_code != self.rmt_setup.size_code||self.ripe_point_code != self.rmt_setup.ripe_point_code ||self.class_code != self.rmt_setup.product_class_code||self.rmt_type != self.rmt_setup.rmt_product.rmt_product_type_code
      
      rmt_product = RmtProduct.create_if_needed(self.rmt_type,self.rmt_setup.rmt_product.commodity_group_code,self.rmt_setup.commodity_code,self.rmt_setup.variety_code,self.size_code,self.class_code,self.ripe_point_code,self.rmt_setup.treatment_code,self.bin_type)
      rmt_product.export_attributes(new_rmt_setup)
      new_rmt_setup.rmt_product = rmt_product
     
      new_rmt_setup.pc_code = rmt_product.ripe_point.pc_code.pc_code
      new_rmt_setup.cold_store_code  = rmt_product.ripe_point.cold_store_type.cold_store_type_code
      new_rmt_setup.track_indicator_code = self.rmt_setup.track_indicator_code
      new_rmt_setup.output_track_indicator_code = self.rmt_setup.output_track_indicator_code
    else
       self.rmt_setup.export_attributes(new_rmt_setup,true)
       
    end
    new_rmt_setup.production_schedule = new_schedule
    
    new_rmt_setup.production_schedule_name = new_schedule.production_schedule_name
  
    new_rmt_setup.create
    new_schedule.rmt_setup = new_rmt_setup
 
  end
  
  #copy bintip criteria
  if self.bintip_criterium
    new_bintip_criteria = BintipCriterium.new
    self.bintip_criterium.export_attributes(new_bintip_criteria,true)
    new_bintip_criteria.production_schedule = new_schedule
    new_bintip_criteria.create
    #new_schedule.bintip_criterium = new_bintip_criteria
  end
  
  #copy pallet criteria
  if self.pallet_criterium
    new_pallet_criteria = PalletCriterium.new
    self.pallet_criterium.export_attributes(new_pallet_criteria,true)
    new_pallet_criteria.production_schedule = new_schedule
    new_pallet_criteria.create
    new_schedule.pallet_criterium = new_pallet_criteria
  end
  
  #copy processing setups
  self.processing_setups.each do |procc_setup|
     new_procc_setup = ProcessingSetup.new
     procc_setup.export_attributes(new_procc_setup,true)
     new_procc_setup.production_schedule = new_schedule
     new_procc_setup.production_schedule_code = new_schedule.production_schedule_name
     new_procc_setup.create
  
  end
  
  
  #copy rebin setups
  self.rebin_setups.each do |rebin_setup|
   rebin_setup.clone_setup(new_schedule)
   
  end
  
  #copy carton setups
  self.carton_setups.each do |carton_setup|
    #change the production schedue and code, but dont save, so we can use the 'clone'
    #feature of the existing record to copy the entire carton setup structure
    carton_setup.production_schedule = new_schedule
    carton_setup.production_schedule_code = new_schedule.production_schedule_name
    carton_setup.clone_setup #a new record will be created by this method, but referencing our new schedule

  end
  
 end
 
 return new_schedule
 
end


#generate the production_schedule_name field
#set the production_schedule_status_code to 'active'
def before_create

  next_id = ProductionSchedule.next_id
  if self.production_schedule_status_code != "depot"
   self.production_schedule_status_code = "active"
   self.production_schedule_name = self.season_code + "_" + self.iso_week_code + "_" +  self.farm_group_code + "_" + next_id.to_s
  else
    self.production_schedule_name = "DEPOT_" + self.season_code + "_" + self.iso_week_code  + "_" + variety_code + "_" + next_id.to_s
  end
end

def before_update
 if self.rmt_setup && self.production_schedule_status_code != "depot"
   self.rmt_setup.production_schedule_name = self.production_schedule_name
 end
end
 
 def ProductionSchedule.num_runs_for_schedule(schedule_id)
  
   query = "select id from production_runs where production_schedule_id = '#{schedule_id}'"
   return connection.select_all(query).length
 
 end

def add_variety_to_schedule_name(variety)
  
  self.production_schedule_name = self.season_code + "_" + self.iso_week_code + "_" +  self.farm_group_code + "_" + variety + "_" + self.id.to_s

end

def after_create

  #self.production_schedule_name = self.season_code + "_isow" + self.iso_week_code + "_" +
  #self.id.to_s
  #self.save

end

def ProductionSchedule.next_id
  query = "select last_value from production_schedules_id_seq"
  return connection.select_all(query)[0]["last_value"].to_i + 1

end


def validate 
 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:iso_week_code => self.iso_week_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_iso_week
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:season_code => self.season_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_season
	 end
	 
end

def after_find

 self.variety = self.rmt_setup.variety_code if self.rmt_setup != nil

end
#	===========================
#	 foreign key validations:
#	===========================
def set_iso_week

	iso_week = IsoWeek.find_by_iso_week_code(self.iso_week_code)
	 if iso_week != nil 
		 self.iso_week = iso_week
		 return true
	 else
		errors.add_to_base("'iso_week_code'  is invalid")
		 return false
	end
end
 
def set_season
   
	season = Season.find_by_season_code(self.season_code)
	
	 if season != nil 
		 self.season = season
		 return true
	 else
		errors.add_to_base("'season_code'  is invalid")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: iso_week_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_iso_week_codes

	iso_week_codes = IsoWeek.find_by_sql('select distinct iso_week_code from iso_weeks').map{|g|[g.iso_week_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: season_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_season_codes

	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
end




end
