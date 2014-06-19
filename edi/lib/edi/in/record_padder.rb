
class RecordPadder

  # Reads the record_sizes YAML file to find the required length of a fixed-length record 
  def self.required_record_length(flow_type, record_type, current_length, must_have_size=false)
    record_sizes = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/record_sizes.yaml'))
    if record_sizes[flow_type.upcase] && record_sizes[flow_type.upcase][record_type]
      record_sizes[flow_type.upcase][record_type]
    else
      if must_have_size
        raise EdiValidationError, "No record length for flow type #{flow_type.upcase}, record_type #{record_type}."
      else
        current_length
      end
    end
  end

  # Before processing a record, call before_process.
  # The default before_process does nothing. Only subclasses provide functionality.
  def before_record(text_line)
    new_line = before_process(text_line)
    return new_line.nil? ? '' : pad_record(new_line)
  end

  # Process a record. Call pre_process (which may be implemented in a subclass) and then pad_record.
  def process_record(text_line)
    text_line = pre_process(text_line)
    return pad_record(text_line)
  end

  # After processing a record, call after_process.
  # The default after_process does nothing. Only subclasses provide functionality.
  def after_record(text_line)
    new_line = after_process(text_line)
    return new_line.nil? ? '' : pad_record(new_line)
  end

  # This method should be overrridden by subclasses who want to add custom processing before padding is done
  def pre_process(text_line)
    text_line
  end

  # This method should be overridden by subclasses that need to add a line
  # before the one being processed. (If a header is missing for example)
  # The overridden method must return nil if no before extra line needs to
  # be added
  def before_process(text_line)
    nil
  end

  # This method should be overridden by subclasses that need to add a line
  # after the one being processed.
  # The overridden method must return nil if no after extra line needs to
  # be added.
  def after_process(text_line)
    nil
  end

  # Pad the +text_line+ with spaces up to the width required (specified in required_record_length).
  def pad_record(text_line)
    flow_type   = Inflector.underscore(self.class.to_s).split("_")[0].upcase()
    record_type = text_line.slice(0..1).upcase()
    text_line.ljust(RecordPadder.required_record_length(flow_type, record_type, text_line.length))
  end

end
