# To change this template, choose Tools | Templates
# and open the template in the editor.

class ScanPutawayLocation < PDTTransactionState
  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line",:name=>"static_field",:value=>"Please scan any one of the ff locations :"}
    self.parent.to_location_list.each do |locn|
#      field_configs[field_configs.length] = {:type=>"static_text",:name=>"static_field", :label=>"",:value=>locn}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"static_line", :label=>"",:value=>locn}
    end
    field_configs[field_configs.length] = {:type=>"text_line",:name=>"static_field",:value=>""}
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_location", :label=>"scan location", :is_required=>"true",:scan_field => true, :submit_form => true}

    screen_attributes = {:auto_submit=>"true",:content_header_caption=>"scan put away location",:auto_submit_to=>'put_away_location_submit'}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"put_away_location_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def scan_putaway_location
    build_default_screen
  end
  
  def put_away_location_submit
    if(error = validate_input)
      PDTTransaction.build_msg_screen_definition(nil, nil, nil, [error])
    else
      @parent.putaway_trans()
    end
  end

  def validate_input
    return valid_location?
  end

  def valid_location?()
    location_barcode = self.pdt_screen_def.get_control_value("scan_location").to_s.strip
    location = Location.find_by_location_barcode(location_barcode)
    if location
      self.parent.location_code = location.location_code.to_s
      if location.location_status == "off_line"
        return "The location is offline!"
      else
        if (location.units_in_location + 1) > location.location_maximum_units
          return "Location specified is full"
        else
#          #precool_job = PrecoolJob.find_by_location_id_and_precool_job_status(location.id, "loading")
#          job = Job.find(location.current_job_reference_id)
#          if job  #precool_job
#            if job.job_type_code == "recooling" && job.current_job_status == "JOB_LOADED"
#              return "The Location scanned has recool job with JOB_LOADED status"
#            else
#              if location_rules_passed?
#                return true
#              else
#                return "Location rules were not passed"
#              end
#            end
#          else
#            if location_rules_passed?
#              return true
#            else
#              return "Location rules were not passed"
#            end
#          end
          if(!self.parent.to_location_list.include?(self.parent.location_code))
            return "Force move denied. Please one of the valid locations"
          end
        end
      end
    else
      return "Location not found!"
    end
  end
end
