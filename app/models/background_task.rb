class BackgroundTask < ActiveRecord::Base

   validates_presence_of :task_id,:task_type,:script_file_name

  def validate

    if  BackgroundTask.find_by_task_id_and_task_type(self.task_id,self.task_type)
      errors.add(:task_id,"combination of task_id and task_type must be unique")
    end

  end


end
