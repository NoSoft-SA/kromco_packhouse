
class FixedLenRecord

  attr_accessor :fields

  #------------------------------------------------------------------------------------------------------------------------
  #params: raw_text: text string where field values occupies set character positions or ranges
  #schema: a list of field descriptors. Each descriptor has a 'name' property and a 'size' property and a type property
  #        the 'type' property must denote the type for the intended destination table field, string is default
  #        other types: number,date
  #-------------------------------------------------------------------------------------------------------------------------
  def initialize(raw_text,field_descriptors,record_type)
    @raw_text = raw_text
    @field_descriptors = field_descriptors
    @fields = Hash.new
    @record_type = record_type
    @logger = EdiHelper::transform_log
    @logger.write "\n----------\nRECORD: " + record_type + "\n-----------"
     extract_fields
  end

  def extract_fields

    cursor_pos = 0
    name = nil

    @field_descriptors.each do |config|
      begin
        #extract properties
        if !config.attribute('name')
          raise EdiValidationError, "field: " + config.to_s + " has no name property"
        else
          name = config.attribute('name').to_s
          @logger.write "field: " + name
        end
         if !config.attribute('size')
          raise EdiValidationError, "field: " + config.to_s + " has no size property"
        else
          size = config.attribute('size').to_s.to_i
        end
         if !config.attribute('type')
          type = "text"
        else
          type = config.attribute('type').to_s
        end
         if !config.attribute('required')
           required = "true"
        else
          required = config.attribute('required').to_s
         end

        if !config.attribute('map_to')
           map_to = name
        else
          map_to = config.attribute('map_to').to_s
        end


        value = @raw_text.slice(cursor_pos..cursor_pos-1 + size)
        raise EdiValidationError, "value required for field: " + config.to_s if required == "true" && value.strip() == ""
        #convert field value to correct type
        
          value = case type
          when "date" then value.to_datetime
          when "number" then value.to_i
          when "text" then value
          else
            raise EdiValidationError, "fixed_len record does not support type: " + type
          end
        

        if value.class.to_s == "String"
          value.gsub!("'","\'")
          value.gsub!("\"","\'")
          value.strip!()
        end
        @logger.write "value: " + value.to_s
        fields.store(map_to, value)
        cursor_pos += size

      rescue
        raise EdiValidationError, "Parsing of field: " + name + " for record_type: #{@record_type} failed. Cursor position is: " + cursor_pos.to_s + ". reported error is: " + $!
      end
    end
    
  end

end

