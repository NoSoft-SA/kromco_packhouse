class Probe < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================

 def before_create
    @new_rec = true
  end

  def after_create
    set_status
  end

  def before_save
       set_status
  end

  def before_update
     set_status
  end

  def before_destroy
     set_status
  end

  def set_status
    if(!@new_rec)
      old_rec = Probe.find(self.id)
      if old_rec.probe_status_code != self.probe_status_code
        probe_status_hist = ProbeStatusHistory.new
        probe_status_hist.probe_status_code = self.probe_status_code
        probe_status_hist.probe_id = self.id
        probe_status_hist.date_from = Time.now.to_formatted_s(:db)
        status =Status.find_by_status_code(self.probe_status_code)
        probe_status_hist.status_id = status.id if status
        probe_status_hist.create
      end
    else
      probe_status_hist = ProbeStatusHistory.new
      probe_status_hist.probe_status_code = self.probe_status_code
      probe_status_hist.probe_id = self.id
      probe_status_hist.date_from = Time.now.to_formatted_s(:db)
      status =Status.find_by_status_code(self.probe_status_code)
      probe_status_hist.status_id = status.id if status
      probe_status_hist.create
    end

  end
  
#	============================
#	 Validations declarations:
#	============================
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



end
