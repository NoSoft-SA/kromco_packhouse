class QcInspectionTest < ActiveRecord::Base

  belongs_to :qc_inspection
  belongs_to :qc_inspection_type_test
  has_many   :qc_results, :dependent => :destroy

  # Status field values
  STATUS_CREATED     = 'QC INSPECTION TEST CREATED'
  STATUS_COMPLETED   = 'QC INSPECTION TEST COMPLETED'

  # Virtual attribute for setting status to complete
  def complete
    @complete || false
  end
  def complete=(val)
    @complete = val
  end

  def set_status( new_status )
    self.status = new_status
    self.save!
    # History to come later
  end

  # Get a set of rules for the measurements used in this test
  def measurement_rules
    @measurement_rules ||= begin
      rules = {}
      self.qc_inspection_type_test.qc_test.qc_measurement_types.each do |measurement_type|
        rules[measurement_type.qc_measurement_code] = measurement_type.measurement_rules
      end
      rules
    end
  end

  # Check each measurement for this test to check which annotations need to be filled-in.
  def max_columns_for_measurements
    @max_columns_for_measurements ||= begin
      cnt = 1
      measurement_rules.each do |k,v|
        c = 1
        c += 1 if v[:annotation_1][:active]
        c += 2 if v[:annotation_2][:active]
        c += 3 if v[:annotation_3][:active]
        cnt = c if c > cnt
      end
      cnt
    end
  end

  def averages
    res = []
    measures = {}
    self.qc_results.each_with_index do |qc_result, index|
      qc_result.qc_result_measurements.each do |qc_result_measurement|
        measures[qc_result_measurement.qc_measurement_description] ||= Hash.new(0.0)
        measures[qc_result_measurement.qc_measurement_description][:min] = 9999 if index == 0
        measures[qc_result_measurement.qc_measurement_description][:count] += 1
        val = qc_result_measurement.measurement.nil? ? 0.0 : qc_result_measurement.measurement.to_f
        measures[qc_result_measurement.qc_measurement_description][:total] += val
        measures[qc_result_measurement.qc_measurement_description][:max] = val if val > measures[qc_result_measurement.qc_measurement_description][:max]
        measures[qc_result_measurement.qc_measurement_description][:min] = val if val < measures[qc_result_measurement.qc_measurement_description][:min]
      end
    end
    measures.each do |k,v|
      res << {:description => k, :value => v[:total] / v[:count], :max => v[:max], :min => v[:min]}
    end
    res
  end

end
