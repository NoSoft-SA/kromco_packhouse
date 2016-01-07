class InstrumentsRfmSession < ActiveRecord::Base
  class ImportSessionError < StandardError; end

  has_many :instruments_rfm_measurements,:order => "id"

  # Perform the import of test measurements for QcInspection.
  # Returns nil on success or else an error message.
  def import_for( qc_inspection )
    msg = nil
    sugars = []
    self.instruments_rfm_measurements.each do |measurement|
      sugars << measurement.measurement if measurement.measurement && measurement.measurement > 0.0
    end

    begin
      if sugars.empty?
        msg = 'No non-zero sugar measurements'
      else
	if qc_inspection.qc_inspection_type.qc_inspection_type_code == 'QTYFS'	      
             import_sugars( qc_inspection, sugars ) unless sugars.empty?
	elsif qc_inspection.qc_inspection_type.qc_inspection_type_code == 'PRETIP'
		import_sugars_pretip( qc_inspection, sugars ) unless sugars.empty?		
	end	     
      end
    rescue ImportSessionError => e
      msg = e.message
    end
    msg
  end

  # Apply the measurements to the sugar test for the given QcInspection.
  # All existing results are deleted and only the number of imported measuremetns are created.
  def import_sugars( qc_inspection, sugars )
    return if sugars.empty?
    qc_test           = QcTest.find(:first, :conditions => ['qc_test_code = ?', 'SUG'])
    raise ImportSessionError, 'No sugar test definition for this inspection' if qc_test.nil?
    test_ids          = QcInspectionTypeTest.find(:all,
                          :select => 'id',
                          :conditions => ['qc_test_id = ? AND qc_inspection_type_id = ?',
                            qc_test.id, qc_inspection.qc_inspection_type_id]).map {|r| r.id }

    sugar_test        = qc_inspection.qc_inspection_tests.find(:first,
                          :conditions => ['qc_inspection_type_test_id IN (?)', test_ids])
    raise ImportSessionError, 'This inspection has no sugar test' if sugar_test.nil?
    measurement_types = qc_test.qc_measurement_types.find(:all)

    index             = 0
    # Delete qc_results & qc_result_measurements & then create from array...
    if QcResult.exists?(:qc_inspection_test_id => sugar_test.id)
      sugar_test.qc_results.each do |result|
        result.qc_result_measurements.delete_all
      end
      sugar_test.qc_results.delete_all
    end

    sample_no = 0
    while index < sugars.length do
      sample_no += 1
      result = sugar_test.qc_results.create!(:qc_test_id => qc_test.id, :sample_no => sample_no)
      measurement_types.each do |measurement_type|
        if measurement_type.qc_measurement_code == 'SUG' && index < sugars.length
          result.qc_result_measurements.create!(:qc_measurement_type_id    => measurement_type.id,
                                               :qc_measurement_code        => measurement_type.qc_measurement_code,
                                               :qc_measurement_description => measurement_type.qc_measurement_description,
                                               :test_uom                   => measurement_type.test_uom,
                                               :test_criteria              => measurement_type.test_criteria,
                                               :test_method                => measurement_type.test_method,
                                               :sample_no                  => sample_no,
                                               :measurement                => sugars[index].to_s)
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
    sugar_test.passed = true
    # Complete the test?
    sugar_test.set_status( QcInspectionTest::STATUS_COMPLETED )
  end
  
  # Apply the measurements to the sugar test for the given QcInspection.
  # All existing results are deleted and only the number of imported measuremetns are created.
  def import_sugars_pretip( qc_inspection, sugars )
    return if sugars.empty?
    qc_test           = QcTest.find(:first, :conditions => ['qc_test_code = ?', 'PRETIP_AP'])
    raise ImportSessionError, 'No sugar test definition for this inspection' if qc_test.nil?
    test_ids          = QcInspectionTypeTest.find(:all,
                          :select => 'id',
                          :conditions => ['qc_test_id = ? AND qc_inspection_type_id = ?',
                            qc_test.id, qc_inspection.qc_inspection_type_id]).map {|r| r.id }

    sugar_test        = qc_inspection.qc_inspection_tests.find(:first,
                          :conditions => ['qc_inspection_type_test_id IN (?)', test_ids])
    raise ImportSessionError, 'This inspection has no sugar test' if sugar_test.nil?
    measurement_types = qc_test.qc_measurement_types.find(:all)

    index             = 0
    # Delete qc_results & qc_result_measurements & then create from array...
    if !QcResult.exists?(:qc_inspection_test_id => sugar_test.id)
       raise ImportSessionError, 'QCResult does not exist' 
    end

    sample_no = 0
    while index < sugars.length do
      sample_no += 1
      result = sugar_test.qc_results.find(:first, :conditions => ['qc_test_id = ? and sample_no = ?', qc_test.id,sample_no])   
      measurement_types.each do |measurement_type|
	if index <= sugars.length
		if ['SUG'].include?( measurement_type.qc_measurement_code) 
		  qc_measure = result.qc_result_measurements.find(:first, :conditions => ['qc_measurement_code = ? and sample_no = ?', 'SUG',sample_no])
		  qc_measure.measurement = sugars[index].to_s
		  qc_measure.update
		  index += 1
		end
	end
      end
    end

    # Pass the test?
    sugar_test.passed = true
    # Complete the test?
    sugar_test.set_status( QcInspectionTest::STATUS_COMPLETED )
  end

end
