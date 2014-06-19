class Job < ActiveRecord::Base


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

  def set_status
    if !@new_rec
     old_rec = Job.find(self.id)
     if old_rec.current_job_status != self.current_job_status
       status_hist = JobStatusHistory.new
       status_hist.job_id = self.id
       status_hist.status_code = self.current_job_status
       status_hist.create
     end
    else
      status_hist = JobStatusHistory.new
       status_hist.job_id = self.id
       status_hist.status_code = self.current_job_status
       status_hist.create
    end
    
  end
  
end
