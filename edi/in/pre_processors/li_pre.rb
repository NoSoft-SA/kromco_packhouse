# Pre-processor for LI flow.
class LiPre < RecordPadder

  # Create an LH record from the first LD if there isn't one.
  def before_process(text_line)
    if text_line.slice(0..1)== "LH"
      @load_header_present = true
    end

    # Are we at the 1st detail record and we have not found a header yet?
    if text_line.slice(0..1)== "LD" && (text_line.slice(14..20) != 'XXXXXXX') && !@load_header_present
      @load_header_present = true
      # Make an LH record from this LD and return it.
      make_load_header text_line
    else
      nil
    end
  end

  # If there are LD records with Xs in the location code turn them into DH or DT records.
  # DH is a 'Detail Header' and DT is a 'Detail Trailer'. These are not part of the LI spec,
  # but they are not true LD (Load Detail) records, so they are changed here so that the
  # Transformers can deal with them differently from the true LD records.
  def pre_process(text_line)
    processed_line = ""
    if text_line.slice(0..1)== "LD" && text_line.slice(14..20) == 'XXXXXXX'
      if @false_header_loaded
        processed_line = "DT" + text_line.slice(2..text_line.length())
      else
        processed_line = "DH" + text_line.slice(2..text_line.length())
      end
    elsif text_line.slice(0..1)== "LD"
      @false_header_loaded = true
      processed_line = text_line
    else
      processed_line = text_line
    end

    return processed_line

  end

  # Take an LD record and manufacture an LH record.
  def make_load_header(text_line)
    EdiHelper::edi_log.write "LI PreProcessor: Creating missing LH record from LD record...",0

    detail_data   = RawFixedLenRecord.new('LI', 'LD', text_line)
    header_data   = RawFixedLenRecord.new('LI', 'LH')
    ignore_fields = ['load_date', 'instruction_quantity']
    line = header_data.populate_with_values_from( detail_data, ignore_fields )

    EdiHelper::edi_log.write "LI PreProcessor: Created missing LH record from LD record.",0
    line
  end

end
