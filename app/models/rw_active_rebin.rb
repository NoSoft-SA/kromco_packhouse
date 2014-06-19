class RwActiveRebin < ActiveRecord::Base

  belongs_to :rebin
  belongs_to :rw_run
  belongs_to :rw_receipt_rebin
  belongs_to :production_run
  
  attr_accessor :rebin_time_search,:farm_code,:production_schedule_name,:season_code,:input_variety,:trans_date_from,:trans_date_to,:line_code,:pc_code
   
   def hello
     
   end
   
   
  def scrap(reason,user)
     self.transaction do
      scrap_rebin = RwScrapRebin.new
      self.rw_receipt_rebin.export_attributes(scrap_rebin,true)
      scrap_rebin.rw_reason_id = reason.id
      scrap_rebin.username = user.user_name
      now = Time.now
      scrap_rebin.rw_scrap_datetime = now
      scrap_rebin.person = user.person.last_name + "," + user.person.first_name
      scrap_rebin.rw_receipt_rebin = self.rw_receipt_rebin
      scrap_rebin.create
      
      self.destroy
      end
  
  end
  
  
    def before_save
      if self.rmt_product_code
        rmt_product = RmtProduct.find_by_rmt_product_code(self.rmt_product_code)
        self.size_code = rmt_product.size_code
        self.class_code = rmt_product.product_class_code
        self.ripe_point_code = rmt_product.ripe_point_code
        self.marketing_variety_code = rmt_product.variety_code
        self.commodity_code = rmt_product.commodity_code
      end
      if self.production_run_code != nil
        run = ProductionRun.find_by_production_run_code(self.production_run_code)
        self.production_run = run
        self.farm_id = run.farm_code
        self.line_code = run.line_code
        self.erp_bin_type = self.product_code_pm_bintype
        self.orchard_code = self.production_run.farm_code + "_" + self.track_indicator_code
      end




     #String orchard_code =  run.getFarm_code() + "_" + rebin_template.getTrack_indicator_code ();

    
   end
   
   
  
  
  
end
