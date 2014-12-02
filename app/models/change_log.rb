class ChangeLog < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================
  belongs_to :change_logs, :foreign_key => 'parent_change_log_id'


#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================
  def fields_not_to_clean
    ['deleted_record','record_before','record_after']
  end

def ChangeLog.create_log(record_before,record_after,record,options = {},deleted_record=nil)
  action=nil
    if record_before.empty? && record_after.empty?
      deleted_record=record.to_map_str()
      action="delete"
    else
      record_before = record.class.new(record_before).to_map_str()
      record_after  = record.class.new(record_after).to_map_str()
      action="edit"
    end

    change_log = ChangeLog.new({:transaction_business_name=>record.class.to_s,:user_name=>ActiveRequest.get_active_request.user,
                                :transaction_reference=>options[:transaction_reference],
                                :doc_type=>options[:doc_type],:doc_name=>options[:doc_name],
                                :transaction_ref_record_type=>options[:transaction_ref_record_type],
                                :record_rails_id=>record.id,:record_type=>record.class.to_s,
                                :action=>action,
                                :record_before => record_before.to_s,
                                :record_after => record_after.to_s,
                                :deleted_record => deleted_record.to_s,
                                :table_name =>record.class.to_s.tableize
                               })
      change_log.affected_by_program = ActiveRequest.get_active_request.program if ActiveRequest.respond_to?("affected_by_program")
      change_log.affected_by_function = ActiveRequest.get_active_request.function if ActiveRequest.respond_to?("affected_by_function")
      change_log.affected_by_env = ActiveRequest.get_active_request.env if ActiveRequest..respond_to?("affected_by_env")

    change_log.save!
  change_log
end

  #
  #def ChangeLog.start_session(record,transaction_business_name,user_name,record_identifier_column,module_name,options = {})
  #  change_log = ChangeLog.new({:transaction_business_name=>transaction_business_name,:user_name=>user_name,
  #                              :record_identifier_column=>record_identifier_column,:module_name=>module_name,:action_context=>"change_log_session",
  #
  #                              :parent_change_log_id=>options[:parent_change_log_id],:transaction_reference=>options[:transaction_reference],
  #                              :doc_type=>options[:doc_type],:doc_name=>options[:doc_name],
  #                              :parent_record_id=>options[:parent_record_id],:transaction_ref_record_type=>options[:transaction_ref_record_type],
  #                              :parent_record_type=>options[:parent_record_type],:transaction_reference_id_column=>options[:transaction_reference_id_column],
  #
  #                              :deleted_record=>record.to_map_str(),
  #                              :record_rails_id=>self.id,:record_type=>record.class.to_s,
  #                              :record_identifier=>record.attributes[record_identifier_column],:action=>'create_session'
  #                             })
  #  if(change_log.save)
  #    return change_log.id
  #  end
  #  return nil
  #end


end
