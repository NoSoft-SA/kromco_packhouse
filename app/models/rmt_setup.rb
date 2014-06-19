class RmtSetup < ActiveRecord::Base
  
  belongs_to :rmt_product
  belongs_to :production_schedule
  
  validates_presence_of :track_indicator_code
  
  attr_accessor :track_indicator_description
  
  def before_create
   #add store type and party_name for db FK to stores
   self.store_type_code = "cold_store"
   self.party_name = "KR"
  end
  
  def RmtSetup.varieties_for_season(season)
  
       query = "SELECT public.rmt_setups.variety_code FROM
          public.rmt_setups
          INNER JOIN public.production_schedules ON 
          (public.rmt_setups.production_schedule_id = public.production_schedules.id)
          WHERE
          (public.production_schedules.season_code = '#{season}')"
          varieties = self.find_by_sql(query).map{|g|[g.variety_code]}
  
   end

  def RmtSetup.is_orchard_run_rmt_product(schedule_id)
     return RmtSetup.find_by_production_schedule_id(schedule_id).rmt_product.rmt_product_type_code == "orchard_run"
  end
  
  def validate
    ModelHelper::Validations.validate_combos([{:ca_cold_room_code => self.ca_cold_room_code}],self,true) 
  
  end
  
  def before_save
    #------------------------------------------------------------------------------
    #Jan 09 changes: cascade track_indicator code changes to rebin setup if changed
    #------------------------------------------------------------------------------
    if !self.new_record?
     old_record = RmtSetup.find(self.id)
     if self.track_indicator_code && self.track_indicator_code != ""
       if self.track_indicator_code != old_record.track_indicator_code
        self.production_schedule.rebin_setups.each do |rebin_setup|
          if rebin_setup.rebin_template
             rebin_setup.rebin_template.track_indicator_code = self.track_indicator_code
             rebin_setup.rebin_template.update
          end
          if rebin_setup.rebin_label_setup
             rebin_setup.rebin_label_setup.rmt_description = TrackIndicator.find_by_track_indicator_code(self.track_indicator_code).description
             rebin_setup.rebin_label_setup.rmt_code = self.track_indicator_code
             rebin_setup.rebin_label_setup.update 
          end
        end
       end
     end
    end
  end
  
  
  
  
end
