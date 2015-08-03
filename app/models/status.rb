class Status < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================
  has_many :process_alert_defs
  belongs_to :status_type


#  ============================
#   Validations declarations:
#  ============================
  validates_presence_of :status_code,:status_type_code
#  =====================
#   Complex validations:
#  =====================

def validate
  is_valid = true
  preceded_by = self.preceded_by
  if preceded_by ==  nil  || preceded_by == ""
    errors.add_to_base("preceded_by can not be blank")
  end


  if preceded_by != nil
   valid_preceded_values
   validate_preceded_first_value
   validate_status_code
  end

end
#  ====================================
# validate uniqueness of status code
#  ====================================
  def validate_status_code
    status_code = self.status_code
    status_type = self.status_type_code

    if self.new_record?
    status = Status.find_by_status_code_and_status_type_code(status_code,status_type)
      if status != nil
        errors.add_to_base("status code already exists")
      end
    end
  end


#  ====================================
# validate preceded_by values
#  ====================================

  def validate_preceded_first_value
    status_type = self.status_type_code
    status = Status.find_by_sql("select * from statuses where statuses.status_type_code = '#{status_type}' order by statuses.id desc " )
    if status.empty? && self.preceded_by != "EMPTY"
     errors.add_to_base("First preceded_by value should be EMPTY")
    end
  end

#  ====================================
# validate preceded_by values
#  ====================================

  def valid_preceded_values
     statuses = Status.find_all_by_status_type_code(self.status_type_code).map{|s| s.status_code}
     preceded_by_splits = preceded_by.strip.split(",")
     if !statuses.empty?
       for preceded_by_split in preceded_by_splits
         preceded = preceded_by_split
#        unless statuses.include?(preceded.strip)
#         errors.add_to_base("invalid value(s) in preceded_by")
#        end
      end
     end
  end


  def before_save
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end
  def before_update
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end

  def before_create
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end

  # Return a value or the SQL keyword +NULL+ if the value is nil.
  def self.n_f(val)
    val.nil? ? 'NULL' : val
  end

  def self.t_f(val)
    val.nil? ? 'NULL' : 'f' == val ? 'false' : 'true'
  end

  # Returns a String of SQL statements for populating another database with the exact same
  # StatusType, Status & alerts...
  def self.export_all_as_sql
    ar = []
    StatusType.find(:all, :conditions => 'parent_id IS NULL', :order => 'id').each do |f|
      ar << "INSERT INTO status_types(status_type_code, ar_class_name, friendly_name, description, ignore_status_sequence)
            VALUES('#{f.status_type_code}','#{n_f f.ar_class_name}','#{n_f f.friendly_name}','#{n_f f.description}',#{t_f f.ignore_status_sequence});".gsub("'NULL'", 'NULL')
    end
    StatusType.find(:all, :conditions => 'parent_id IS NOT NULL', :order => 'id').each do |f|
      ar << <<-EOS.gsub("'NULL'", 'NULL')
      INSERT INTO status_types(status_type_code, ar_class_name, friendly_name, description, ignore_status_sequence, parent_id)
      SELECT '#{f.status_type_code}','#{n_f f.ar_class_name}','#{n_f f.friendly_name}',
             '#{n_f f.description}',#{t_f f.ignore_status_sequence}, status_types.id
      FROM status_types WHERE status_type_code = '#{f.parent.status_type_code}';
      EOS
    end

    Status.find(:all, :order => 'id').each do |f|
      ar << <<-EOS.gsub("'NULL'", 'NULL')
      INSERT INTO statuses(status_code, description, status_type_code, preceded_by, is_terminal_status, "position", is_error_status)
      VALUES('#{n_f f.status_code}', '#{n_f f.description}', '#{n_f f.status_type_code}', '#{n_f f.preceded_by}', #{t_f f.is_terminal_status}, #{n_f f.position}, #{t_f f.is_error_status});
      EOS
    end

    ProcessAlertTrigger.find(:all, :order => 'id').each do |f|
      ar << "INSERT INTO process_alert_triggers(trigger_name) VALUES('#{f.trigger_name}');"
    end

    ar << "UPDATE mes_control_files SET sequence_number = 0 WHERE object_type = #{MesControlFile::PROCESS_ALERT} AND sequence_number IS NULL;"

    # process_alert_defs
    ProcessAlertDef.find(:all, :order => 'id').each do |f|
      ar << "UPDATE mes_control_files SET sequence_number = (SELECT sequence_number FROM mes_control_files WHERE object_type = #{MesControlFile::PROCESS_ALERT})+1 WHERE object_type = #{MesControlFile::PROCESS_ALERT};"
      ar << <<-EOS.gsub("'NULL'", 'NULL')
 INSERT INTO process_alert_defs(process_alert_name, description, status_id, trigger_name,
             alert_time_frame, process_interval, send_email_alert, email_recipients, email_message, mode, recipient_rules)
 SELECT '#{f.process_alert_name.split('_').slice(0..-2).join('_')}' || '_' || (SELECT cast(sequence_number as character varying) FROM mes_control_files WHERE object_type = #{MesControlFile::PROCESS_ALERT}), '#{n_f f.description}', s.id, '#{f.trigger_name}', #{f.alert_time_frame}, #{f.process_interval}, #{t_f f.send_email_alert}, '#{n_f f.email_recipients}', '#{n_f f.email_message}', '#{f.mode}', '#{n_f f.recipient_rules}'
 FROM statuses s
 WHERE s.status_code = '#{f.status.status_code}'
 AND s.status_type_code = '#{f.status.status_type_code}';
      EOS
    end

    ar.join("\n")
  end

end
