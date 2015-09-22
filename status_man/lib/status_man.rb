class StatusMan

  def self.validate_child(child, required_parent_status_type_code)
    table = child[:child_ar_class_name].tableize
    require "app/models/#{table.singularize}.rb"
    child_object = eval("#{table.singularize.camelize}.find(#{child[:list][0]})")

    if  child[:list] && child[:list].empty?
      raise "CHILD STATUS CODE,CHILD STATUS TYPE CODE,CHILD AR CLASS NAME and LIST OF IDs should be passed"
    end

    if   child[:child_new_status_code] == nil || child[:child_status_type] ==nil ||child[:child_ar_class_name] == nil || child[:list]==nil
      raise "CHILD STATUS CODE,CHILD STATUS TYPE CODE,CHILD AR CLASS NAME and LIST OF IDs should be passed"
    end

    current_status = get_current_status(child[:child_status_type], child_object)
    if current_status
      current_status =current_status.strip().upcase
    end
    new_status_check = TransactionStatus.find_by_status_type_code_and_status_code(child[:child_new_status_code], child[:child_status_type])
    if new_status_check !=nil
      new_status_check=new_status_check.status_code
      if current_status.upcase == new_status_check.upcase
        raise "CHILD CURRENT STATUS:#{current_status} is the same as NEW STATUS: #{new_status_check}"
      end
    end
    status =Status.find_by_status_code_and_status_type_code(child[:child_new_status_code], child[:child_status_type])
    if status ==nil
      create_status(child[:child_new_status_code],child[:child_status_type])

      #raise "A status record is not yet configured for status: " + child[:child_new_status_code] + " and status type " + child[:child_status_type] if !status
    end
#that the child_status_type has a parent status_type matching the passed-in status_type
    child_status_type =StatusType.find_by_status_type_code(child[:child_status_type])
    parent_status_type=StatusType.find(child_status_type.parent_id)
    if parent_status_type.status_type_code != required_parent_status_type_code && required_parent_status_type_code!=nil
      raise " CHILD PARENT STATUS TYPE is : #{parent_status_type.status_type_code.to_s.upcase}, REQUIRED TYPE is #{required_parent_status_type_code.upcase}"
    end
#    and that the child ar_class_name matches the defined ar_class_name of looked up child status_type
    if child_status_type.ar_class_name != child[:child_ar_class_name]
      raise " CHILD STATUS TYPE is of type #{child_status_type.ar_class_name.to_s.upcase}, REQUIRED TYPE is #{child[:child_ar_class_name].upcase}"
    end

#    check that passed in children are of type defined by passed ar_class_name
    if child_object.class.to_s != child[:child_ar_class_name]
      raise child[:child_status_type_code].upcase + "REQUIRES A LIST OF  OBJECTS OF TYPE " + child[:child_ar_class_name].upcase
    end
  end
  def self.set_status(new_status_code, status_type, object, user_name, parent_object = nil, child=nil, parent_already_logged=nil)
#    ActiveRecord::Base.transaction do
      if parent_already_logged==true
        if child!=nil  && child[:list].length > 0
          if parent_already_logged==nil
            status_type =nil
          else
            status_type=status_type
          end
          validate_child(child, status_type)
          parent_trans_status=TransactionStatus.find_by_sql("select * from transaction_statuses where status_type_code='#{status_type}' order by created_on desc")[0]
          table              = child[:child_ar_class_name].tableize
          object_ids_ary     =Array.new
          for id in child[:list]
            object_ids_ary << "#{table}.id = " + id.to_s
          end
          object_ids   =object_ids_ary.join(" OR ")
          update_query ="Update #{table} set status = '#{child[:child_new_status_code]}' where #{object_ids}"
          ActiveRecord::Base.connection.execute(update_query)
          #-------------update transactions_statuses--------------------------
          insert_select_query="
                insert into transaction_statuses (object_id, created_on, status_type_code, status_code, username,parent_id)
                select #{table}.id,'#{Time.now().to_formatted_s(:db)}','#{child[:child_status_type]}','#{child[:child_new_status_code]}','#{user_name}',#{parent_trans_status.id}
                from #{table} where (#{object_ids})"
          ActiveRecord::Base.connection.execute(insert_select_query)
        end
      else

        if  (new_status_code == nil || status_type ==nil ||object == nil)
          raise "NEW STATUS CODE,STATUS TYPE and OBJECT should be passed"
        end

        current_status = get_current_status(status_type, object)
        if current_status
          current_status =current_status.strip().upcase
        end
        new_status_check = TransactionStatus.find_by_status_type_code_and_status_code(new_status_code, status_type)
        if new_status_check !=nil
          new_status_check=new_status_check.status_code
          if current_status.upcase == new_status_check.upcase
            raise "Current status:#{current_status} is the same as new status: #{new_status_check}"
          end
        end

        status =Status.find_by_status_code_and_status_type_code(new_status_code, status_type)
        if status ==nil
          create_status(new_status_code,status_type)

          #raise "A status record is not yet configured for status: " + new_status_code + " and status type " + status_type if !status
        end

        #--------validate object's class----------------------------------------------------------------------
        status_type_rec=StatusType.find_by_status_type_code(status_type)

        if object.class.to_s != status_type_rec.ar_class_name
          raise " OBJECT is of type #{object.class.to_s.upcase}, REQUIRED TYPE is #{status_type_rec.ar_class_name.upcase}"
        end
        #--------validate presence and validity of parent object--------------------------------------------

        if status_type_rec.parent_id != nil

          if parent_object ==nil
            raise status_type.upcase + "REQUIRES A PARENT OBJECT OF TYPE " + status_type_rec.status_type_code.upcase
          end
          required_parent=StatusType.find(status_type_rec.parent_id)
          if parent_object.class.to_s != required_parent.ar_class_name
            raise "PARENT OBJECT is of type #{parent_object.class.to_s.upcase}, REQUIRED TYPE is #{required_parent.ar_class_name.upcase}"
          end
          trans_statuses=TransactionStatus.find_by_sql(
              "select * from transaction_statuses where status_type_code='#{required_parent.status_type_code}' and
                                           object_id =#{parent_object.id} order by created_on DESC")
          if !trans_statuses.empty?
            trans_status=trans_statuses[0]
          end

        end
        #------------------------------------------------------------------------------------------------

        preceded        = status.preceded_by.split(",")
        preceded_by_ary = Array.new
        for element in preceded
          if element =="" || element ==nil || element == "nil" || element =='nil'
            preceded_by_ary << element
          else
            preceded_by_ary << element.strip().upcase
          end
        end

        if (preceded_by_ary.include?(current_status) || current_status ==nil || current_status ==""||current_status == new_status_code || status_type_rec.ignore_status_sequence==true)


          wd = Dir.getwd.to_s
          if FileTest.exist?("#{wd}"+"/status_man/lib/#{status_type.downcase}_status_event.rb")

            require "#{wd}"+"/status_man/lib/#{status_type.downcase}_status_event.rb"
            klass                   = "#{status_type.downcase}_status_event".camelize
            instance                = eval("#{klass}.new")
            valid_status_change_msg =instance.valid_status_change(current_status, new_status_code, object)
            if valid_status_change_msg != nil
              raise valid_status_change_msg
            else
              calc_status_msg =instance.calc_status(current_status, object)
              instance.on_status_change_action(current_status, new_status_code, object)

              if calc_status_msg != nil
                if parent_already_logged == nil || parent_already_logged == false
                  transaction_status                  = TransactionStatus.new
                  transaction_status.status_code      = calc_status_msg
                  transaction_status.created_on       = Time.now
                  transaction_status.username         =user_name
                  transaction_status.status_type_code =status_type
                  transaction_status.object_id        = object.id
                  transaction_status.parent_id = trans_status.id if trans_status
                  transaction_status.save

                  #----------------------error_status----------------------------------------------------
                  if object.attributes.has_key?("error_status")
                    is_error_status= Status.find_by_status_code(new_status_code).is_error_status
                    if is_error_status==true
                      object.error_status=new_status_code
                      object.update
                    else
                      object.error_status=nil
                      object.update
                    end
                  end


                  if object.attributes.has_key?("location_status")
                    object.location_status =new_status_code
                    object.update
                  else
                    object.status =new_status_code
                    object.update
                  end
                end
                if child!=nil && child[:list].length > 0
                  if parent_already_logged==nil
                    status_type =nil
                  else
                    status_type=status_type
                  end
                  validate_child(child, status_type)
                  table         = child[:child_ar_class_name].tableize
                  object_ids_ary=Array.new
                  for id in child[:list]
                    object_ids_ary << "#{table}.id = " + id.to_s
                  end
                  object_ids   =object_ids_ary.join(" OR ")
                  update_query ="Update #{table} set status = '#{child[:child_new_status_code]}' where #{object_ids}"
                  ActiveRecord::Base.connection.execute(update_query)
                  #-------------update transactions_statuses--------------------------
                  insert_select_query="
                insert into transaction_statuses (object_id, created_on, status_type_code, status_code, username,parent_id)
                select #{table}.id,'#{Time.now().to_formatted_s(:db)}','#{child[:child_status_type]}','#{child[:child_new_status_code]}','#{user_name}',#{transaction_status.id}
                from #{table} where (#{object_ids})"
                  ActiveRecord::Base.connection.execute(insert_select_query)
                end
                return
              else
                if parent_already_logged == nil || parent_already_logged == false
                  transaction_status                  = TransactionStatus.new
                  transaction_status.status_code      = new_status_code
                  transaction_status.created_on       = Time.now
                  transaction_status.username         =user_name
                  transaction_status.status_type_code =status_type
                  transaction_status.object_id        = object.id
                  transaction_status.parent_id = trans_status.id if trans_status
                  transaction_status.save
#----------------------error_status----------------------------------------------------
                  if object.attributes.has_key?("error_status")
                    is_error_status= Status.find_by_status_code(new_status_code).is_error_status
                    if is_error_status==true
                      object.error_status=new_status_code
                      object.update
                    else
                      object.error_status=nil
                      object.update
                    end
                  end


                  if object.attributes.has_key?("location_status")
                    object.location_status =new_status_code
                    object.update
                  else
                    object.status =new_status_code
                    object.update
                  end
                end

                #-------------updating and logging child records----------------------------------------------

                if child!=nil && child[:list].length > 0
                  if parent_already_logged==nil
                    status_type =nil
                  else
                    status_type=status_type
                  end
                  validate_child(child, status_type)
                  table         = child[:child_ar_class_name].tableize
                  object_ids_ary=Array.new
                  for id in child[:list]
                    object_ids_ary << "#{table}.id = " + id.to_s
                  end
                  object_ids   =object_ids_ary.join(" OR ")
                  update_query ="Update #{table} set status = '#{child[:child_new_status_code]}' where #{object_ids}"
                  ActiveRecord::Base.connection.execute(update_query)
                  #-------------update transactions_statuses--------------------------
                  insert_select_query="
                insert into transaction_statuses (object_id, created_on, status_type_code, status_code, username,parent_id)
                select #{table}.id,'#{Time.now().to_formatted_s(:db)}','#{child[:child_status_type]}','#{child[:child_new_status_code]}','#{user_name}',#{transaction_status.id}
                from #{table} where (#{object_ids})"
                  ActiveRecord::Base.connection.execute(insert_select_query)
                  return
                end

                #-----------------------------------------------------------------------------------------------------------
              end
            end
          else
            if parent_already_logged == nil || parent_already_logged == false
              transaction_status                  = TransactionStatus.new
              transaction_status.status_code      = new_status_code
              transaction_status.created_on       = Time.now
              transaction_status.username         =user_name
              transaction_status.status_type_code =status_type
              transaction_status.object_id        = object.id
              transaction_status.parent_id = trans_status.id if trans_status
              transaction_status.save

              #----------------------error_status----------------------------------------------------
              if object.attributes.has_key?("error_status")
                is_error_status= Status.find_by_status_code(new_status_code).is_error_status
                if is_error_status==true
                  object.error_status=new_status_code
                  object.update
                else
                  object.error_status=nil
                  object.update
                end
              end

              if object.attributes.has_key?("location_status")
                object.location_status =new_status_code
                object.update
              else
                object.status =new_status_code
                object.update
              end
            end
            if child!=nil && child[:list].length > 0
              validate_child(child, status_type)
              table         = child[:child_ar_class_name].tableize
              object_ids_ary=Array.new
              for id in child[:list]
                object_ids_ary << "#{table}.id = " + id.to_s
              end
              object_ids   =object_ids_ary.join(" OR ")
              update_query ="Update #{table} set status = '#{child[:child_new_status_code]}' where #{object_ids}"
              ActiveRecord::Base.connection.execute(update_query)
              #-------------update transactions_statuses--------------------------
              insert_select_query="
                insert into transaction_statuses (object_id, created_on, status_type_code, status_code, username,parent_id)
                select #{table}.id,'#{Time.now().to_formatted_s(:db)}','#{child[:child_status_type]}','#{child[:child_new_status_code]}','#{user_name}',#{transaction_status.id}
                from #{table} where (#{object_ids})"
              ActiveRecord::Base.connection.execute(insert_select_query)
              return
            end
          end

        else
          raise "Config error: The new status of #{object.class}: #{new_status_code} must include the current status(#{current_status}) in its preceded_by_list"
        end
      end
#    end
  end


  def self.create_status(status_code,status_type)
    current_status=Status.find_by_sql("select * from statuses where status_type_code='#{status_type}' order by id desc limit 1")[0]
    if  current_status
      status_preceded_by=current_status.preceded_by
      status=Status.new
      status.status_type_code=status_type
      status.status_code=status_code
      status.preceded_by=status_preceded_by.gsub(/\r/, "\n").gsub(/\n+/, "\n").chomp.split("\n").map {|r| r.strip }.join(',')
      status.is_terminal_status=current_status.is_terminal_status
      status.position=current_status.position
      status.is_error_status=current_status.is_error_status
      status.save
    else
      raise "A status record is not yet configured for status: " + status_code + " and status type " + status_type
    end
  end


  def self.get_current_status(status_type, object)
    object_attributes = object.attributes
    if object_attributes.has_key?("location_status")
      current_status = object.location_status
    else
      current_status = object.status
    end


  end

  def self.next_statuses(status_type, object)
    ActiveRecord::Base.transaction do
      if  status_type == nil ||object == nil
        raise "status_type and object should be passed"
      end
      wd = Dir.getwd.to_s


      if FileTest.exist?("#{wd}"+"/status_man/lib/#{status_type.downcase}_status_event.rb")
        require "#{wd}"+"/status_man/lib/#{status_type.downcase}_status_event.rb"
        klass            = "#{status_type.downcase}_status_event".camelize
        instance         = eval("#{klass}.new")
        next_instace_msg = instance.next_status(status_type, object)
        if next_instace_msg.kind_of?(Array)
          raise next_instace_msg
        else
          current_status =get_current_status(status_type, object)
          current_status = "EMPTY" if (current_status== "" ||current_status == nil)
          statuses     =Status.find_by_sql("select * from statuses where status_type_code='#{status_type.upcase}'")
          status_codes =Array.new
          for status in statuses
            preceded        = status.preceded_by.split(",")
            preceded_by_ary = Array.new
            for element in preceded
              if element =="" || element ==nil || element == "nil" || element =='nil'
                preceded_by_ary << element
              else
                preceded_by_ary << element.strip().upcase
              end
            end
            if preceded_by_ary.include?(current_status)
              status_code = status.status_code
              status_codes << status_code
            end
          end
          return status_codes
        end
      else
        current_status =get_current_status(status_type, object)
        current_status = "EMPTY" if (current_status== "" ||current_status == nil)
        statuses     =Status.find_by_sql("select * from statuses where status_type_code='#{status_type.upcase}'")
        status_codes =Array.new
        for status in statuses
          preceded        = status.preceded_by.split(",")
          preceded_by_ary = Array.new
          for element in preceded
            preceded_by_ary << element.strip().upcase
          end
          if preceded_by_ary.include?(current_status.upcase)
            status_code = status.status_code.strip()
            status_codes << status_code
          end
        end
        return status_codes
      end
    end
  end

  def self.log_sent_mail(transaction_status_id, object_id, process_name, attachment_content, alert_code, recipients, message, subject)
    email_log = EmailLog.new({:transaction_status_id=>transaction_status_id, :object_id=>object_id, :process_name=>process_name,
                              :attachment_content   => attachment_content, :alert_code=>alert_code, :recipients=>recipients,
                              :message              =>message, :subject=>subject})
    email_log.save
  end


end