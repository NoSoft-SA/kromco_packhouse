class ActiveReworksDevice < ActiveRecord::Base
 
  belongs_to :production_run
  belongs_to :device_type
  has_one :active_device_history
  
  
  def ActiveReworksDevice.get_active_run_devices(device_code)
    
    query = "SELECT public.active_devices.*
             FROM
             public.active_reworks_devices
             INNER JOIN public.production_runs ON (public.active_devices.production_run_id = public.production_runs.id)
             WHERE
             (public.active_devices.active_device_code = '#{device_code}' AND
             public.production_runs.production_run_stage <> 'rebinning' AND
             public.production_runs.production_run_stage <> 'bintipping_only' AND
             (production_runs.production_run_status = 'reconfiguring' OR
             production_runs.production_run_status = 'active'))"
             
  
    return ActiveReworksDevice.find_by_sql(query)
  
  end
  
end
