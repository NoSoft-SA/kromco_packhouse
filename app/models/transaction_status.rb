class TransactionStatus < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :status

#  ============================
#   Validations declarations:
#  ============================
#  =====================
#   Complex validations:
#  =====================
def validate
#  first check whether combo fields have been selected
   is_valid = true
   if is_valid
     is_valid = ModelHelper::Validations.validate_combos([{:status_code => self.status_code}],self)
  end
  #now check whether fk combos combine to form valid foreign keys
   if is_valid
     is_valid = set_status
   end
end

#  ===========================
#   foreign key validations:
#  ===========================
def set_status

  status = Status.find_by_status_code(self.status_code)
   if status != nil
     self.status = status
     return true
   else
    errors.add_to_base("value of field: 'status_code' is invalid- it must be unique")
     return false
  end
end

  # Returns a set of rows for an instance of a particular model class.
  # If include_children is true, the rows will include children status transactions.
  def self.rows_for(klass, id, include_children=true)
    ar_class_name = klass.is_a?(Class) ? klass.name : klass
    status_types  = ActiveRecord::Base.connection.select_values("select status_type_code from status_types WHERE ar_class_name = '#{ar_class_name}'")
    raise MesScada::InfoError, "There is no StatusType for class name '#{ar_class_name}'." if status_types.empty?

# WHERE t.object_id = #{id} AND t.status_type_code = '#{status_type}'
    if include_children
      qry = <<EOS
SELECT t.object_id, t.created_on, t.status_type_code, t.status_code, t.username, t.id, t.parent_id,
       c.object_id child_object_id, c.created_on child_created_on, c.status_type_code child_status_type_code, c.status_code child_status_name, c.username child_username, c.id child_id, c.parent_id child_parent_id
FROM transaction_statuses t
LEFT OUTER JOIN transaction_statuses c ON c.parent_id = t.id
WHERE t.object_id = #{id} AND t.status_type_code IN ('#{status_types.join("','")}')
ORDER BY t.created_on, c.created_on
EOS
    else
      qry = <<EOS
SELECT t.object_id, t.created_on, t.status_type_code, t.status_code, t.username, t.id, t.parent_id,
y.ar_class_name, t.id,
(SELECT COUNT(*) FROM transaction_statuses c WHERE c.parent_id = t.id) AS no_children
FROM transaction_statuses t
LEFT OUTER JOIN transaction_statuses p ON p.id = t.parent_id
LEFT OUTER JOIN status_types y ON y.status_type_code = p.status_type_code
WHERE t.object_id = #{id} AND t.status_type_code IN ('#{status_types.join("','")}')
ORDER BY t.created_on
EOS
    end

    ActiveRecord::Base.connection.select_all(qry)
  end

  # Returns either an Array or a String of formatted entries for a given instance.
  # Can be called from the commandline like this:
  # script/runner "puts TransactionStatus.formatted_summary_for(Invoice,1190)"
  # - or to get the status of children as well:
  # script/runner "puts TransactionStatus.formatted_summary_for(Invoice,1190,true,true)"
  def self.formatted_summary_for(klass, id, as_str=true, include_children=false)
    if include_children
      ar = ["#{'User'.ljust(30)}#{'Status'.ljust(30)}#{'Date       Time'.ljust(20)}#{'Child type'.ljust(30)}#{'Child Id'.ljust(30)}"]
      ar << "#{'-' * 29} #{'-' * 29} #{'-' * 10} #{'-' * 8} #{'-' * 29} #{'-' * 29}"
      rows_for(klass, id).each do |row|
        time = row['child_created_on'].nil? ? '' : Time.parse(row['child_created_on']).strftime('%Y-%m-%d %H:%M:%S')
        ar << "#{row['username'].ljust(30)}#{row['status_code'].ljust(30)}#{Time.parse(row['created_on']).strftime('%Y-%m-%d %H:%M:%S').ljust(20)}#{(row['child_status_type_code'] || '').ljust(30)}#{(row['child_object_id'] || '').ljust(30)}"
      end
    else
      ar = ["#{'User'.ljust(30)}#{'Status'.ljust(30)}#{'Date       Time'.ljust(30)}"]
      ar << "#{'-' * 29} #{'-' * 29} #{'-' * 10} #{'-' * 8}"
      rows_for(klass, id, false).each do |row|
        ar << "#{row['username'].ljust(30)}#{row['status_code'].ljust(30)}#{Time.parse(row['created_on']).strftime('%Y-%m-%d %H:%M:%S').ljust(30)}"
      end
    end
    if as_str
      ar.join("\n")
    else
      ar
    end
  end


  def self.model_rows(klass, id)
    ar_class_name = klass.is_a?(Class) ? klass.name : klass
    status_types  = ActiveRecord::Base.connection.select_values("select status_type_code from status_types WHERE ar_class_name = '#{ar_class_name}'")
    raise MesScada::InfoError, "There is no StatusType for class name '#{ar_class_name}'." if status_types.empty?

    qry = <<-EOS
    SELECT t.object_id, t.created_on, t.status_type_code, t.status_code, t.username, t.id, t.parent_id,
    s.ar_class_name AS this_class_name, y.ar_class_name, t.id,
    (SELECT COUNT(*) FROM transaction_statuses c WHERE c.parent_id = t.id) AS no_children
    FROM transaction_statuses t
    JOIN status_types s ON s.status_type_code = t.status_type_code
    LEFT OUTER JOIN transaction_statuses p ON p.id = t.parent_id
    LEFT OUTER JOIN status_types y ON y.status_type_code = p.status_type_code
    WHERE t.object_id = #{id} AND t.status_type_code IN ('#{status_types.join("','")}')
    ORDER BY t.created_on
    EOS

    ActiveRecord::Base.connection.select_all(qry)
    #rows_for(klass, id, false)
  end

  def self.child_rows(id)
    qry = <<-EOS
    SELECT t.object_id, t.created_on, t.status_type_code, t.status_code, t.username, t.id, t.parent_id,
    s.ar_class_name AS this_class_name, y.ar_class_name, t.id,
    (SELECT COUNT(*) FROM transaction_statuses c WHERE c.parent_id = t.id) AS no_children
    FROM transaction_statuses t
    JOIN status_types s ON s.status_type_code = t.status_type_code
    LEFT OUTER JOIN transaction_statuses p ON p.id = t.parent_id
    LEFT OUTER JOIN status_types y ON y.status_type_code = p.status_type_code
    WHERE t.parent_id = #{id}
    ORDER BY t.created_on
    EOS
    ActiveRecord::Base.connection.select_all(qry)
  end

end
