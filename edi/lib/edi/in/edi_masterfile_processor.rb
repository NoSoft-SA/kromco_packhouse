# Handle the updating of EDI in Masterfiles.
module EdiMasterfileProcessor

  # Provides a hash of attribute names with the values to be used when the input record has a nil value.
  # This method is overridden in classes that include this module when they need to implement
  # default values for fields.
  # e.g.
  #   {'date_end' => Date.new( 2090, 1, 1 ) }
  def masterfile_defaults
    {}
  end

  def handle_record(record,action)

  end

  # Calls +masterfile_keys+ and +masterfile_klass+ to get the keys and model class.
  # Finds the masterfile record with matching key(s). If it exists, deletes it.
  # Checks the +update_flag+ of the input record and if it is not "D" for delete,
  # inserts the record.
  def apply_masterfile_rec(record, command)
    table_keys     = masterfile_keys
    table_klass    = masterfile_klass
    table_defaults = masterfile_defaults

    # Sometimes a field might have hashes in it, in which case it should be treated as 1
    record.fields.each {|k,v| if v == '#' * v.length then record.fields[k] = '1'; end }

    todo        = record.fields['update_flag']
    where       = table_keys.map {|k| "#{k} = ?"}.join(' AND ')
    values      = []
    table_keys.each {|k| values << record.fields[k] == '' ? table_defaults[k] : record.fields[k]}
    the_rec = table_klass.find(:first, :conditions => [where, *values])

    the_rec.destroy unless the_rec.nil?
    if todo != 'D'
      the_rec = table_klass.new
      the_rec.import(record.fields)
      # Apply default values to nil fields if required.
      table_defaults.each { |k,v| if the_rec.attributes[k].nil? then the_rec.send("#{k}=", v); end }
      the_rec.save!
    end


     handle_record(the_rec,todo) if the_rec

  rescue StandardError => error
    EdiHelper.transform_log.write "#{error} - #{error.backtrace.join("\n").to_s}"
    EdiHelper.edi_log.write error
    raise EdiInError, "Masterfile error (#{table_klass.name}) - #{error}", error.backtrace
  end
end
