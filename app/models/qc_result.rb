class QcResult < ActiveRecord::Base

  belongs_to :qc_inspection_test
  belongs_to :qc_test
  has_many   :qc_result_measurements, :dependent => :destroy

  # Take a QcMeasurementType and apply its rules to adding cull measurements.
  # The possible values in annotation_1 act as "columns" for the cull type, so a
  # result_measurement needs to be created for each "column".
  # eg. measure desc = 'Bruising', annotation_1_values == 'Class 2,Class 3'
  #            +---------+---------+
  #            | Class 2 | Class 3 |
  #   ---------+---------+---------+
  #   Bruising | [_____] | [_____] |
  #   ---------+---------+---------+
  def add_cull_measurement( qc_measurement_type )
    if qc_measurement_type.annotation_1_possible_values.nil? || qc_measurement_type.annotation_1_possible_values == ''
      possible_values = ['']
    else
      possible_values = qc_measurement_type.annotation_1_possible_values.split(/,\s*/)
    end

    possible_values.each do |possible_value|
      qc_result_measurement = QcResultMeasurement.new( :qc_measurement_type_id => qc_measurement_type.id, :sample_no => 1)
      ['qc_measurement_code', 'qc_measurement_description', 'test_uom', 'test_criteria',
       'test_method'
      ].each {|a| qc_result_measurement.send(a+'=', qc_measurement_type.attributes[a]) }
      if possible_value.strip != ''
        qc_result_measurement.annotation_1 = possible_value
      end
      unless self.qc_result_measurements << qc_result_measurement
        qc_result_measurement.errors.each_full do |msg|
          errors.add_to_base "QC Result Measurement: #{msg}"
        end
      end
    end
    
  end

  # Build a 2D array of cull measurements.
  def cull_measurements( qc_measurement_type=nil )
    measurements = []
    qc_inspection_type_test = self.qc_inspection_test.qc_inspection_type_test
    if qc_inspection_type_test.cull_columns.nil? || qc_inspection_type_test.cull_columns == ''
      col_array = []
    else
      col_array = qc_inspection_type_test.cull_columns.split(/,\s*/)
    end

    prev_code = ''
    this_ar   = []
    max_cols  = 0
    self.qc_result_measurements.find(:all, :order => 'qc_measurement_code, annotation_1').each do |qc_result_measurement|
      unless qc_measurement_type.nil?
        next unless qc_result_measurement.qc_measurement_type_id == qc_measurement_type.id
      end
      if prev_code != qc_result_measurement.qc_measurement_code
        measurements << this_ar.clone unless this_ar.empty?
        max_cols  = [this_ar.length, max_cols].max
        this_ar.clear
        col_array.length.times { this_ar << nil }
        prev_code = qc_result_measurement.qc_measurement_code
      end
      pos = col_array.index qc_result_measurement.annotation_1
      if pos.nil?
        this_ar << qc_result_measurement
      else
        this_ar[pos] = qc_result_measurement
      end
    end
    measurements << this_ar unless this_ar.empty?

    # Adjust the number of columns if need be.
    while col_array.length < max_cols do
      col_array << nil
    end
    # Place column array at the head of the measurements array.
    measurements.unshift col_array

    measurements
  end

  def cull_summary( sample_size )
    cols = self.qc_inspection_test.qc_inspection_type_test.cull_columns.split(/\s*,\s*/)
    summary = {}
    self.qc_result_measurements.each do |qc_result_measurement|
      if cols.include? qc_result_measurement.annotation_1
        summary[qc_result_measurement.annotation_1] ||= {:amount => 0.0, :percentage => 0.0}
        summary[qc_result_measurement.annotation_1][:amount] += qc_result_measurement.cull_amount
      end
    end
    tot = 0
    summary.each do |k,v|
      tot += v[:amount]
      v[:percentage] = v[:amount] / sample_size.to_f * 100.0
    end
    summary['unclassified'] = {:amount => sample_size - tot, :percentage => (sample_size - tot) / sample_size.to_f * 100.0}
    summary
  end

end
