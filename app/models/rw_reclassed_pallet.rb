class RwReclassedPallet < ActiveRecord::Base
  def RwReclassedPallet.exclude_in_rw_histories_comparisons
    ['created_at','affected_by_function','affected_by_program','updated_at','updated_by','created_by','reworks_action','tablename',
     'rw_receipt_datetime','record_id','date_time_completed']
  end
end
 