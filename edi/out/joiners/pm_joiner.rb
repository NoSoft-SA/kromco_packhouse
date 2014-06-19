# Join several PM edi output files into one new one.
class PmJoiner < EdiFileJoiner

  # Add up all the counts of all the trailers into the last (only) trailer in the combined file.
  def make_trailer
    EdiHelper.edi_log.write "Updating trailer record..."

    @final_trailer['batch_number'] = @out_seq
    @final_trailer['record_count'] = @record_count

    EdiHelper.edi_log.write "Trailer record updated."
  end
  
end

