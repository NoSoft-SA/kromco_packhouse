class ProcessAlert < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :process_alert_def
 
     def ProcessAlert.archive_alerts(alerts)
       ActiveRecord::Base.transaction do
        alerts_ids=alerts.map{|i|"id="+ i['id'].to_s}.join(" OR ")
        ActiveRecord::Base.connection.execute("
        insert into archived_process_alerts(process_alert_def_id,created_on,transaction_status_id,process_alert_name,description)
        select process_alert_def_id,created_on,transaction_status_id,process_alert_name,description
        from process_alerts where #{alerts_ids}
        ")
        ActiveRecord::Base.connection.execute("
        delete from process_alerts where #{alerts_ids}
       ")
      end
     end


def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:trigger_name => self.trigger_name}],self)
#	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_process_alert_def
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
#	 exists = ProcessAlert.find_by_process_alert_def_id(self.process_alert_def_id)
#	 if exists != nil
#		errors.add_to_base("There already exists a record with the combined values of fields: 'process_alert_def_id' ")
#	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_process_alert_def

#	process_alert_def = ProcessAlertDef.find(self.process_alert_def_id)
#	 if process_alert_def != nil
#		 self.process_alert_def = process_alert_def
#		 return true
#	 else
#		errors.add_to_base("combination of: 'trigger_name'  is invalid- it must be unique")
#		 return false
#	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: process_alert_def_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_trigger_names

	trigger_names = ProcessAlertDef.find_by_sql('select distinct trigger_name from process_alert_defs').map{|g|[g.trigger_name]}
end






end
