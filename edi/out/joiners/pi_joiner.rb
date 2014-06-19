# Join several PI edi output files into one new one.
class PiJoiner < EdiFileJoiner

  # Add up all the counts of all the trailers into the last (only) trailer in the combined file.
  def make_trailer
    #puts 'trailer'
    EdiHelper.edi_log.write "Updating trailer record..."

    @final_trailer['batch_number'] = @out_seq
    @final_trailer['record_count'] = @record_count

    i_fields = %w{ic_record_count is_record_count ip_record_count total_ic_cartons total_is_cartons total_ip_cartons}
    f_fields = %w{total_ic_pallets total_is_pallets total_ip_pallets}
    total_i = Hash.new(0)
    total_f = Hash.new(0.0)
    @trailers.each do |trailer|
      i_fields.each {|i| total_i[i] += trailer[i].to_i }
      f_fields.each {|f| total_f[f] += trailer[f].to_f }
    end
    i_fields.each {|i| @final_trailer[i] = total_i[i] }
    f_fields.each {|f| @final_trailer[f] = total_f[f] }
    EdiHelper.edi_log.write "Trailer record updated."
  end
  
end
