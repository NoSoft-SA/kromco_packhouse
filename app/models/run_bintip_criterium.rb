class RunBintipCriterium < ActiveRecord::Base

 belongs_to :production_run


  def before_create

    self.treatment_code=true
    self.commodity_code=true
    self.variety_code=true
    self.class_code=true
    self.pc_code=false
    self.track_indicator_code=true
    self.size_code=true
    self.ripe_point_code=false
    return true

  end

end
