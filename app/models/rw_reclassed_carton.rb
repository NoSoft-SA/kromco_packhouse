class RwReclassedCarton < ActiveRecord::Base
  def RwReclassedCarton.exclude_in_rw_histories_comparisons
    ['date_time_created','created_at','updated_at','affected_by_function','affected_by_program','updated_by','created_by','record_id',
     'rw_receipt_pallet_id','reworks_action','carton_id','tablename',
     'rw_reclassed_datetime','rw_receipt_datetime',

    'rw_receipt_intake_headers_production_id',

    'rw_reclassed_intake_headers_production_id']
  end
end
