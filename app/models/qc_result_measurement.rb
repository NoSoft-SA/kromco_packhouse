class QcResultMeasurement < ActiveRecord::Base

  belongs_to :qc_result
  belongs_to :qc_measurement_type

  before_save :check_float_measurement

  def cull_summary( sample_size )
    {:description => self.qc_measurement_description,
     :annotation  => self.annotation_1,
     :amount      => self.cull_amount,
     :percentage  => self.cull_percentage(sample_size) }
  end

  def cull_amount
    self.measurement.nil? ? 0.0 : self.measurement.to_i
  end

  def cull_percentage(sample_size)
    cull_amount / sample_size.to_f * 100
  end

private

  def check_float_measurement
    # If the measure contains 1 period and it is the last character, assume it is a float and add a trailing '0'
    # ("62." => "62.0")
    return true if self.measurement.nil?

    if self.measurement.strip.index('.') == self.measurement.strip.length-1
      self.measurement = self.measurement.strip << '0'
    end
  end

end
