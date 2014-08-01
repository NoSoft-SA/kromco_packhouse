# Edi fields are placed into fixed-length records as strings. This module provides some shortcut formatting codes.
# eg. +ZEROS+: left pads a field with zeroes up to the expected length.
#
# The format code is specified in the <tt>format=""</tt> attribute of the EDI in-transformer XML schema.
# Formats:
# _ZEROES_::    Left-pads a numeric with zeroes up to expected length. <b>(29 => 00029)</b> (-ve number will have - sign in place of left-most zero).
# _DECIMAL_::   Left-pads a numeric with zeroes up to expected length. 2 decimal places. <b>(29.3 => 00029.30, -12.01 => 00012.01)</b> (-ve number will have - sign in place of left-most zero).
# _SIGNED_::    Left-pads a numeric with zeroes up to expected length (with +/-sign). <b>(29 => +0029, -12 => -0012)</b>
# _SIGNDEC_::   Left-pads a numeric with zeroes up to expected length (with +/-sign). 2 decimal places. <b>(29.3 => +0029.30, -12.01 => -0012.01)</b>
# _TEMP_::      Temperature with sign. <b>(+23.45, -02.12)</b>
# <em>TEMP1DEC</em>::  Temperature with sign and single decimal. <b>(+23.4, -02.1)</b>
# _DATE_::      Date in YYYYMMDD format. <b>(20101225)</b>
# _DATETIME_::  Date and time in YYYYMMDDHH:MM format. <b>(2010122513:45)</b>
# _MMMDDYYYHMMAP_:: Date and time in MMM DD YYYY H:MMAM format. <b>(Jan 25 2011  8:57AM)</b>
# _HMS_::       Time as Hours:Minutes:Seconds. <b>(13:45:05)</b>
# _HM_::        Time as Hours:Minutes. <b>(13:45)</b>
module EdiFieldFormatter

  # Takes a raw value and returns a string representation using the format and desired length.
  #
  # The format can be a shortcut code (eg. +ZEROES+, +DATE+, +HMS+) or a valid Ruby +sprintf+ string.
  # If no format is provided the value is treated as a string and right-padded with spaces
  # up to the required length of the field.
  #--
  # NB:: If you add a format to this method, make sure you list and describe it
  # at the top of this file.
  #++
  def format_edi_field( raw_value, len, format_def )
    # If no format provided, right-pad with spaces up to the field length.
    return raw_value.to_s.ljust(len) if format_def.nil?  # || format_def == ''
    return ' ' * len if raw_value.nil?

    case format_def.upcase
    when 'ZEROES'
      sprintf("%0#{len}d", raw_value)
    when 'DECIMAL'
      sprintf("%0#{len}.2f", raw_value)
    when 'SIGNED'
      sprintf("%+0#{len}d", raw_value)
    when 'SIGNDEC'
      sprintf("%+0#{len}.2f", raw_value)
    when 'DATE' # Specify ISO etc
      raw_value.strftime('%Y%m%d')
    when 'DATETIME'
      raw_value.strftime('%Y%m%d%H:%M')
    when 'MMMDDYYYHMMAP'
      raw_value.strftime('%b %d %Y %l:%M%p')
    when 'HMS'
      raw_value.strftime('%H:%M:%S')
    when 'HM'
      raw_value.strftime('%H:%M')
    when 'TEMP' # +09.99, -09.99
      sprintf("%+0#{len}.2f", raw_value)
    when 'TEMP1DEC' # +09.99, -09.99
      sprintf("%+0#{len}.1f", raw_value)
    when '' || nil # Default to string padded with zeroes on the right TODO: Check if default of padding to length is OK or error
      raw_value.to_s.ljust(len)
    else
      sprintf(format_def, raw_value)
    end
  end

end
