class Shift < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


  belongs_to :shift_type


#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :shift_type_code, :line_code, :user


  attr_accessor :time_quarters

  # validate :calendar_date_time_quarter
  #
  # def calendar_date_time_quarter
  #   if self.calendar_date.blank? || !self.calendar_date_time_quarter_range.include?(self.calendar_date.strftime("%M"))
  #     self.errors.add(:calendar_date, "is blank or not in allowed range")
  #   end
  # end
  #
  # #the validation
  # def calendar_date_time_quarter_range
  #   time_quarters = ["00","15","30","45"]
  #   return time_quarters
  # end

  def self.current_shift?(line_code)
      query = "select * from shifts where now() between start_date_time and end_date_time and line_code = '#{line_code}'"
      shifts = Shift.find_by_sql(query)
      if shifts.length() > 0
        return shifts[0]
      else
        return nil
      end

  end




#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:shift_type_code => self.shift_type_code}, {:calendar_date => self.calendar_date}], self)
    end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_shift_type
    end

    if self.new_record? && is_valid
      #MM122015 - change from PopupDateSelector to PopupDateTimeSelector
      #MM122015 - change date-selector to capture times (currently only days) + validate that selected time is a quarter (00, 15, 30 or 45 )
      time_quarters_minutes = self.time_quarters.to_i*60
      self.start_date_time = self.calendar_date.to_time().at_beginning_of_day + self.start_time.hours + time_quarters_minutes#.mins
      if self.start_time < self.end_time
        self.end_date_time = self.calendar_date.to_time().at_beginning_of_day + self.end_time.hours + time_quarters_minutes#.mins
      else
        self.end_date_time = self.calendar_date.to_time().tomorrow.at_beginning_of_day + self.end_time.hours + time_quarters_minutes#.mins
      end
      #validates uniqueness for this record
      validate_overlap
    end
  end


  def Shift.get_shift_details(line_code)
    query  = "select * from shifts where now() between start_date_time and end_date_time and line_code = '#{line_code}'"
    shifts = Shift.find_by_sql(query)
    return "More than one shift is defined for the current date-time and line: #{line_code}" if shifts.length > 1
    return "No shift has been defined for the current date-time and line: #{line_code}" if shifts.length == 0
    return shifts[0]

  end


  def validate_overlap

    #query  = "select * from shifts where line_code = '#{self.line_code}' and (start_date_time between '#{self.start_date_time.to_formatted_s(:db)}' and '#{self.end_date_time.to_formatted_s(:db)}' or end_date_time between '#{self.start_date_time.to_formatted_s(:db)}' and '#{self.end_date_time.to_formatted_s(:db)}') "
    query  = "select * from shifts where line_code = '#{self.line_code}' and (start_date_time between '#{self.start_date_time.to_formatted_s(:db)}' and cast('#{self.end_date_time.to_formatted_s(:db)}' as timestamp) - interval '1 seconds' or end_date_time - interval '1 seconds' between '#{self.start_date_time.to_formatted_s(:db)}' and '#{self.end_date_time.to_formatted_s(:db)}') "
    #puts     query
    shifts = Shift.find_by_sql(query)

    if shifts.length() > 0
      errors.add_to_base("There already exists a shift for the selected line and between the start and end times")
    end
  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_shift_type

    shift_type = ShiftType.find_by_shift_type_code(self.shift_type_code)
    if shift_type != nil
      self.shift_type = shift_type #setting the values to be sent to the browser since they are now label fields
      self.start_time = shift_type.start_time
      self.end_time   = shift_type.end_time
      return true
    else
      errors.add_to_base("shift Type not found")
      return false
    end
  end


  def after_create
    #MM122015 - change from PopupDateSelector to PopupDateTimeSelector
    #MM122015 - change date-selector to capture times (currently only days) + validate that selected time is a quarter (00, 15, 30 or 45 )
    # self.shift_code = self.shift_type_code + ":" + self.line_code + ":" + self.start_date_time.strftime("%d-%b-%Y %Hh00") + " to " + self.end_date_time.strftime("%d-%b-%Y %Hh00")
    self.shift_code = self.shift_type_code + ":" + self.line_code + ":" + self.start_date_time.strftime("%d-%b-%Y %Hh%M") + " to " + self.end_date_time.strftime("%d-%b-%Y %Hh%M")
  end

#	===========================
#	 lookup methods:
#	====== =====================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: shift_type_id
#	------------------------------------------------------------------------------------------

  def self.get_all_shift_type_codes

    shift_type_codes = ShiftType.find_by_sql('select distinct shift_type_code from shift_types').map { |g| [g.shift_type_code] }
  end


  def self.get_all_start_times

    start_times = ShiftType.find_by_sql('select distinct start_time from shift_types').map { |g| [g.start_time] }
  end

#new change
  def self.get_all_end_times

    end_times = ShiftType.find_by_sql('select distinct end_time from shift_types').map { |g| [g.end_time] }
  end


#shift codes for shift_type_codes
  def self.shift_codes_for_shift_type_code(shift_type_code)

    start_times = ShiftType.find_by_sql("Select distinct start_time from shift_types where shift_type_code = '#{shift_type_code}'").map { |g| [g.start_time] }

    start_times.unshift("<empty>")
  end


#new change
  def self.shift_codes_for_shift_type_code(shift_type_code)

    end_times = ShiftType.find_by_sql("Select distinct end_time from shift_types where shift_type_code = '#{shift_type_code}'").map { |g| [g.end_time] }

    end_times.unshift("<empty>")
  end


end
