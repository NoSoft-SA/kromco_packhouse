class ForecastVarietyIndicator < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
  has_many   :forecast_variety_indicators_track_slms_indicators
	belongs_to :track_slms_indicator
	belongs_to :forecast_variety
  has_one :bin_ticket
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :number_tickets_printed
	validates_numericality_of :quantity
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:track_slms_indicator_code => self.track_slms_indicator_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_track_slms_indicator
	 end
	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:rmt_variety_code => self.rmt_variety_code}],self)
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_forecast_variety
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_track_slms_indicator

	track_slms_indicator = TrackSlmsIndicator.find_by_track_slms_indicator_code(self.track_slms_indicator_code)
	 if track_slms_indicator != nil 
		 self.track_slms_indicator = track_slms_indicator
		 return true
	 else
		errors.add_to_base("value of field: 'track_slms_indicator_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_forecast_variety

	forecast_variety = ForecastVariety.find(self.forecast_variety_id)
	 if forecast_variety != nil 
		 self.forecast_variety = forecast_variety
		 return true
	 else
		errors.add_to_base("value of field: 'rmt_variety_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================

#======================================
#  Bin Ticket Printing by Happymore
#======================================

def print_bin_tickets(http_conn, qty_to_print, printer)
  begin

    @qty_to_print = qty_to_print
    data = build_bin_tickets_data
    return_string = build_print_instruction(data, printer)
    puts return_string
    print_instruction = return_string.split("$")[0]
    seed_num = return_string.split("$")[1]

    #create a single bin tickets record to represent the batch printing
    puts "NEW BIN TICKETS RECORD---->"
    bin_tickets_record = BinTicket.new
    bin_tickets_record.tickets_print_date_time = Time.now.to_formatted_s(:db)
    bin_tickets_record.number_tickets_printed = qty_to_print.to_i
    puts "SEED NUM: " + seed_num.to_s
    ticket_num_from = seed_num.to_i
    bin_tickets_record.ticket_number_from = ticket_num_from.to_i
    bin_tickets_record.ticket_number_to = seed_num.to_i +   (qty_to_print.to_i - 1)
    bin_tickets_record.binticket_label_data = print_instruction
    bin_tickets_record.binticket_label_format = "E3"
    bin_tickets_record.forecast_variety_indicator_id = self.id
    bin_tickets_record.binticket_print_date = Time.now.strftime("%d/%m/%Y")
    bin_tickets_record.save!
    puts "QTY: " + qty_to_print
    self.update_attribute(:number_tickets_printed, (self.number_tickets_printed + qty_to_print.to_i))

    #hans: uncomment
    http_conn.get("/" + print_instruction, nil)
    puts "bin ticket printed"

    return print_instruction
  rescue
    raise "Bin tickets could not be printed, Reason: " + $!
  end
end

def build_bin_tickets_data

  data = Hash.new

  forecast_variety = self.forecast_variety
  forecast = self.forecast_variety.forecast

  #fields to be printed
  quantity = self.quantity
  track_slms_indicator_code = self.track_slms_indicator_code
  puc_code = forecast.puc_code ? forecast.puc_code : ""

  track_slms_indicator_description = TrackSlmsIndicator.find_by_track_slms_indicator_code(track_slms_indicator_code).track_slms_indicator_description
  orchard_code = forecast_variety.orchard_code
  farm_group_code = forecast.farm.farm_group.farm_group_code
  farm_code = forecast.farm_code

  rmt_variety = RmtVariety.find_by_rmt_variety_code(self.forecast_variety.rmt_variety_code)
  rmt_variety_description = rmt_variety.rmt_variety_description
  f5 = ""
  if(rmt_variety_description.length < 11)
    f4 = rmt_variety_description
  elsif((parts=rmt_variety_description.split(" ")).length > 1)
    if(parts[0].length < 11)
      f4=parts[0]
    else
      f4 = parts[0][0..9]
      prefix = parts[0][10..(parts[0].length-1)] + " "
    end


    i=1
    f5 = prefix.to_s
    (parts.length-1).times do |a|
      f5 += parts[i].to_s + " "
      i+=1
    end
  else
    f4 = rmt_variety_description[0..9]
  end

  f5.to_s.strip!

  data.store("F1", "")
  data.store("F2", farm_code)
  data.store("F3", "[NR]")
  data.store("F4", "[NR]")
  data.store("F5", f4)
  data.store("F6", f5)
  data.store("F7", self.forecast_variety.rmt_variety_code)
  data.store("F8", puc_code)

  return data

end

def build_print_instruction(label_data, printer)

  seed_num = MesControlFile.next_seq_web(MesControlFile::BIN_TICKET,@qty_to_print.to_i,"kr")
  #puts seed_num.to_s

  start_num = seed_num.to_i - @qty_to_print.to_i
  #puts quantity.to_s
  label_instruction = "<ProductLabel PID=\"223\" Status=\"true\" Printer=\"#{printer}\" MC=\"[NR]\""

  #label_instruction += "BIN"
  label_instruction += " StartNr=\""
  label_instruction += start_num.to_s + "\" CountNr=\""
  label_instruction += @qty_to_print.to_s + "\" F0=\"" + "E3" + "\" "

  for i in 1..41
    key = "F" + i.to_s
    val = ""
    if label_data.has_key?(key)
      val = label_data[key].to_s
      field = key + "=\"" + val + "\""
      label_instruction += field + " "
    else
      field = key + "=\"\""
      label_instruction += field + " "
    end
  end
  label_instruction += "Msg=\"OK\" />"
  puts label_instruction
  return label_instruction + "$" + start_num.to_s + "$" + @qty_to_print.to_s

end

#======================================
# End Bin Ticket Printing by Happymore
#======================================
def has_forecast_variety_indicators_track_slms_indicator(track_slms_indicator)
  if(rec = ForecastVarietyIndicatorsTrackSlmsIndicator.find_by_forecast_variety_indicator_id_and_track_slms_indicator_id(self.id,track_slms_indicator.id))
    return true
  end
  return false
end

  def add_track_slms_indicator(track_slms_indicator)
    forecasts_variety_indicators_track_slms_indicator = ForecastVarietyIndicatorsTrackSlmsIndicator.new
    forecasts_variety_indicators_track_slms_indicator.track_slms_indicator_id = track_slms_indicator.id
    forecasts_variety_indicators_track_slms_indicator.forecast_variety_indicator_id = self.id

    if forecasts_variety_indicators_track_slms_indicator.save
      return true
    end
    return false
  end
end
