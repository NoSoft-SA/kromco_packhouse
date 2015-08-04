class EdiOutJoinerHistory < ActiveRecord::Base

  # Given an edi file name, find out which file it was joined into.
  # If it has not yet been joined, return the original file name.
  def self.joined_file_for(edi_file_name)
    joined_file = EdiOutJoinerHistory.find(:first, :conditions => ['edi_out_filename = ?', edi_file_name])
    if joined_file.nil?
      edi_file_name
    else
      joined_file.edi_joined_filename
    end
  end
end
