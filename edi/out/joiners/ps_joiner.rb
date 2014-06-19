# Join several PS edi output files into one new one.
class PsJoiner < EdiFileJoiner

  # Add up all the counts of all the trailers into the last (only) trailer in the combined file.
  def make_trailer
    EdiHelper.edi_log.write "Updating trailer record..."

    @final_trailer['batch_number'] = @out_seq
    @final_trailer['record_count'] = @record_count

    i_fields = %w{ps_record_count total_cartons}
    total_i = Hash.new(0)
    @trailers.each do |trailer|
      i_fields.each {|i| total_i[i] += trailer[i].to_i }
    end
    i_fields.each {|i| @final_trailer[i] = total_i[i] }
    EdiHelper.edi_log.write "Trailer record updated."
  end
  
end

