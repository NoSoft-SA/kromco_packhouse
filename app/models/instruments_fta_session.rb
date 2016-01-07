class InstrumentsFtaSession < ActiveRecord::Base
  class ImportSessionError < StandardError; end

  has_many :instruments_fta_measurements,:order => "id"

  # diameter can be measured in ANY mode...
  MODE_FIRM      = 1
  MODE_FIRM_DIA  = 2
  MODE_FIRM_MASS = 3
  MODE_MASS      = 4
  MODE_DIA       = 5
  FIRMNESS_MODES = [MODE_FIRM, MODE_FIRM_DIA, MODE_FIRM_MASS]

  # Perform the import of test measurements for QcInspection.
  # Returns nil on success or else an error message.
  def import_for( qc_inspection )
    msg = nil
    diameters = []
    pressures = []
    self.instruments_fta_measurements.each do |measurement|
      diameters << measurement.diameter if measurement.diameter && measurement.diameter > 0.0
      pressures << measurement.firmness if FIRMNESS_MODES.include?( measurement.mode ) && measurement.firmness && measurement.firmness > 0.0
    end

    begin
      if diameters.empty? && pressures.empty?
        msg = 'No non-zero pressure or diameter measurements'
      else
	if qc_inspection.qc_inspection_type.qc_inspection_type_code == 'QTYFS'
		import_diameters( qc_inspection, diameters ) unless diameters.empty?
		import_pressures( qc_inspection, pressures ) unless pressures.empty?
	elsif qc_inspection.qc_inspection_type.qc_inspection_type_code == 'PRETIP'
		import_pressures_pretip( qc_inspection, pressures ) unless pressures.empty?		
	end
      end
    rescue ImportSessionError => e
      msg = e.message
    end
    msg
  end

  # Apply the diameters to the diameter test for the given QcInspection.
  # All existing results are deleted and only the number of imported measuremetns are created.
  def import_diameters( qc_inspection, diameters )
    return if diameters.empty?
    qc_test           = QcTest.find(:first, :conditions => ['qc_test_code = ?', 'DIA'])
    raise ImportSessionError, 'No diameter test definition for this inspection' if qc_test.nil?
    test_ids          = QcInspectionTypeTest.find(:all,
                          :select => 'id',
                          :conditions => ['qc_test_id = ? AND qc_inspection_type_id = ?',
                            qc_test.id, qc_inspection.qc_inspection_type_id]).map {|r| r.id }

    diameter_test     = qc_inspection.qc_inspection_tests.find(:first,
                          :conditions => ['qc_inspection_type_test_id IN (?)', test_ids])
    raise ImportSessionError, 'This inspection has no diameter test' if diameter_test.nil?
    measurement_types = qc_test.qc_measurement_types.find(:all)
    index             = 0
    # Delete qc_results & qc_result_measurements & then create from array...
    if QcResult.exists?(:qc_inspection_test_id => diameter_test.id)
      diameter_test.qc_results.each do |result|
        result.qc_result_measurements.delete_all
      end
      diameter_test.qc_results.delete_all
    end

    sample_no = 0
    while index < diameters.length do
      sample_no += 1
      result = diameter_test.qc_results.create!(:qc_test_id => qc_test.id, :sample_no => sample_no)
      measurement_types.each do |measurement_type|
        if measurement_type.qc_measurement_code == 'DIA' && index < diameters.length
          result.qc_result_measurements.create!(:qc_measurement_type_id    => measurement_type.id,
                                               :qc_measurement_code        => measurement_type.qc_measurement_code,
                                               :qc_measurement_description => measurement_type.qc_measurement_description,
                                               :test_uom                   => measurement_type.test_uom,
                                               :test_criteria              => measurement_type.test_criteria,
                                               :test_method                => measurement_type.test_method,
                                               :sample_no                  => sample_no,
                                               :measurement                => diameters[index].to_s)
          index += 1
        else
          result.qc_result_measurements.create!(:qc_measurement_type_id    => measurement_type.id,
                                               :qc_measurement_code        => measurement_type.qc_measurement_code,
                                               :qc_measurement_description => measurement_type.qc_measurement_description,
                                               :test_uom                   => measurement_type.test_uom,
                                               :test_criteria              => measurement_type.test_criteria,
                                               :test_method                => measurement_type.test_method,
                                               :sample_no                  => sample_no)
        end
      end
    end

    # Pass the test?
    diameter_test.passed = true
    # Complete the test?
    diameter_test.set_status( QcInspectionTest::STATUS_COMPLETED )
  end

  # Apply the pressures to the pressure test for the given QcInspection.
  # All existing results are deleted and only the number of imported measuremetns are created.
  def import_pressures( qc_inspection, pressures )
    return if pressures.empty?
    qc_test           = QcTest.find(:first, :conditions => ['qc_test_code = ?', 'PRESS'])
    raise ImportSessionError, 'No pressure test definition for this inspection' if qc_test.nil?
    test_ids          = QcInspectionTypeTest.find(:all,
                          :select => 'id',
                          :conditions => ['qc_test_id = ? AND qc_inspection_type_id = ?',
                            qc_test.id, qc_inspection.qc_inspection_type_id]).map {|r| r.id }

    pressure_test     = qc_inspection.qc_inspection_tests.find(:first,
                          :conditions => ['qc_inspection_type_test_id IN (?)', test_ids])
    raise ImportSessionError, 'This inspection has no pressure test' if pressure_test.nil?
    measurement_types = qc_test.qc_measurement_types.find(:all)
    index             = 0
    # Delete qc_results & qc_result_measurements & then create from array...
    if QcResult.exists?(:qc_inspection_test_id => pressure_test.id)
      pressure_test.qc_results.each do |result|
        result.qc_result_measurements.delete_all
      end
      pressure_test.qc_results.delete_all
    end

    sample_no = 0
    while index < pressures.length do
      sample_no += 1
      result = pressure_test.qc_results.create!(:qc_test_id => qc_test.id, :sample_no => sample_no)
      measurement_types.each do |measurement_type|
        if ['PRESS1','PRESS2'].include?( measurement_type.qc_measurement_code) && index < pressures.length
          result.qc_result_measurements.create!(:qc_measurement_type_id    => measurement_type.id,
                                               :qc_measurement_code        => measurement_type.qc_measurement_code,
                                               :qc_measurement_description => measurement_type.qc_measurement_description,
                                               :test_uom                   => measurement_type.test_uom,
                                               :test_criteria              => measurement_type.test_criteria,
                                               :test_method                => measurement_type.test_method,
                                               :sample_no                  => sample_no,
                                               :measurement                => pressures[index].to_s)
          index += 1
        else
          result.qc_result_measurements.create!(:qc_measurement_type_id    => measurement_type.id,
                                               :qc_measurement_code        => measurement_type.qc_measurement_code,
                                               :qc_measurement_description => measurement_type.qc_measurement_description,
                                               :test_uom                   => measurement_type.test_uom,
                                               :test_criteria              => measurement_type.test_criteria,
                                               :test_method                => measurement_type.test_method,
                                               :sample_no                  => sample_no)
        end
      end
    end

    # Pass the test?
    pressure_test.passed = true
    # Complete the test?
    pressure_test.set_status( QcInspectionTest::STATUS_COMPLETED )
  end
  
  # Apply the pressures to the pressure test for the given QcInspection.
  # All existing results are deleted and only the number of imported measuremetns are created.
  def import_pressures_pretip( qc_inspection, pressures )
    return if pressures.empty?
    qc_test           = QcTest.find(:first, :conditions => ['qc_test_code = ?', 'PRETIP_AP'])
    raise ImportSessionError, 'No test definition for this inspection' if qc_test.nil?
    test_ids          = QcInspectionTypeTest.find(:all,
                          :select => 'id',
                          :conditions => ['qc_test_id = ? AND qc_inspection_type_id = ?',
                            qc_test.id, qc_inspection.qc_inspection_type_id]).map {|r| r.id }

    pressure_test     = qc_inspection.qc_inspection_tests.find(:first,
                          :conditions => ['qc_inspection_type_test_id IN (?)', test_ids])
    raise ImportSessionError, 'This inspection has no test' if pressure_test.nil?
    measurement_types = qc_test.qc_measurement_types.find(:all)
    index             = 0
    # Delete qc_results & qc_result_measurements & then create from array...
    if !QcResult.exists?(:qc_inspection_test_id => pressure_test.id)
       raise ImportSessionError, 'QCResult does not exist' 
    end

    sample_no = 0
    while index < pressures.length do
      sample_no += 1
      result = pressure_test.qc_results.find(:first, :conditions => ['qc_test_id = ? and sample_no = ?', qc_test.id,sample_no])   
      measurement_types.each do |measurement_type|
	if index <= pressures.length
		if ['PRESS1'].include?( measurement_type.qc_measurement_code) 
		  qc_measure = result.qc_result_measurements.find(:first, :conditions => ['qc_measurement_code = ? and sample_no = ?', 'PRESS1',sample_no])
		  qc_measure.measurement = pressures[index].to_s
		  qc_measure.update
		  index += 1
		end
		if ['PRESS2'].include?( measurement_type.qc_measurement_code) 
		  qc_measure = result.qc_result_measurements.find(:first, :conditions => ['qc_measurement_code = ? and sample_no = ?', 'PRESS2',sample_no])
		  qc_measure.measurement = pressures[index].to_s
		  qc_measure.update
		  index += 1
	       end
	end
      end
    end

    # Pass the test?
    #pressure_test.passed = true
    # Complete the test?
    #pressure_test.set_status( QcInspectionTest::STATUS_COMPLETED )
  end

end
