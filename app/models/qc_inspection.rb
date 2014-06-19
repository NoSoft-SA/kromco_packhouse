class QcInspection < ActiveRecord::Base
	belongs_to :qc_inspection_type
	has_and_belongs_to_many :qc_reasons
	has_many   :qc_inspection_tests

  #validates_presence_of :inspection_reference, :inspection_number, :username
  validates_presence_of :inspection_number, :username, :population_size

  before_save :clear_tm

  # Status field values
  STATUS_CREATED     = 'QC INSPECTION CREATED'
  STATUS_CANCELED    = 'QC INSPECTION CANCELED'
  STATUS_IN_PROGRESS = 'QC INSPECTION IN PROGRESS'
  STATUS_COMPLETED   = 'QC INSPECTION COMPLETED'

  # Place business info attributes on the QcInspection instance.
  def set_business_info( inspection_type, business_object_id )
    self.business_object_id = business_object_id
    filter_record   = get_filter_context( inspection_type )
    unless filter_record.nil?
      self.inspection_reference = filter_record.attributes[inspection_type.inspection_ref_column]
      info_hash = {}
      inspection_type.business_info_columns_list.split(/\s*,\s*/).each do |col|
        info_hash[col] = filter_record.attributes[col]
      end
      self.business_info = info_hash.to_yaml
    end
  end

  # Get the value of a specific attribute in the business_info hash
  def business_info_value( attribute )
    return nil if business_info.nil?
    YAML.load(business_info)[attribute]
  end

  # Create an inspection record. Get the QcInspectionType and related tests and measures.
  def create_inspection
    is_ok = false
    QcInspection.transaction do
      self.inspection_number = MesControlFile.next_seq_web(MesControlFile::QC_INSPECTION)
      if self.save
        set_status STATUS_CREATED
        inspection_type = self.qc_inspection_type
        filter_record   = get_filter_context( inspection_type )
        unless filter_record.nil?
          self.inspection_reference = filter_record.attributes[self.qc_inspection_type.inspection_ref_column]
          info_hash = {}
          self.qc_inspection_type.business_info_columns_list.split(/\s*,\s*/).each do |col|
            info_hash[col.strip] = filter_record.attributes[col.strip] || ' '
          end
          self.business_info = info_hash.to_yaml
          self.save!
          is_ok = create_tests( inspection_type, filter_record )
        end
      end
      raise ActiveRecord::Rollback unless is_ok
    end
   is_ok 
  end

  # Find the business object record linked to this inspection.
  def get_filter_context( inspection_type )
    qry = inspection_type.qc_filter_context_search || ''
    if qry.strip == ''
      errors.add_to_base "QC Inspection Type '#{inspection_type.qc_inspection_type_code}' does not have a filter context search."
      return nil
    end

    qry.gsub!('{business_object_id}', self.business_object_id.to_s)
    records = QcInspection.find_by_sql( qry )
    if records.nil? || records.empty?
      errors.add_to_base "filter context search returned no values for business object id #{self.business_object_id}." 
      nil
    else
      records.first
    end
  end

  # Create the tests and measures for this inspection type based on the filters that match the filter record.
  # Returns false if unable to create tests.
  def create_tests( inspection_type, filter_record )

    inspection_type.qc_inspection_type_tests.each do |inspection_type_test|
      #next if filter_record.attributes[inspection_type_test.filter_column] != inspection_type_test.filter_value
      # filter_value can have a comma-separated list of codes, so split them out into an array:
      filter_checks = inspection_type_test.filter_value.split(/\s*,\s*/)
      next unless filter_checks.include?(filter_record.attributes[inspection_type_test.filter_column])

      # Create a test
      qc_inspection_test = QcInspectionTest.new( :qc_inspection_id => self.id,
                                                 :passed    => false,
                                                 :username  => self.username,
                                                 :status    => QcInspectionTest::STATUS_CREATED,
                                                 :optional  => inspection_type_test.optional,
                                                 :cull_test => inspection_type_test.cull_test,
                                                 :qc_inspection_type_test_id => inspection_type_test.id)
      qc_inspection_test.inspection_test_number = MesControlFile.next_seq_web(MesControlFile::QC_INSPECTION_TEST)
      unless qc_inspection_test.save
        qc_inspection_test.errors.each_full do |msg|
          errors.add_to_base "Inspection Test: #{msg}"
        end
        return false
      end

      # Create Cull result and measurements:
      if qc_inspection_test.cull_test?
        qc_result = QcResult.new( :qc_test_id => inspection_type_test.qc_test_id, :sample_no => 1)
        if qc_inspection_test.qc_results << qc_result
          inspection_type_test.qc_test.qc_measurement_types.each do |qc_measurement_type|
              qc_result.add_cull_measurement( qc_measurement_type )
          end
        else
          qc_result.errors.each_full do |msg|
            errors.add_to_base "QC Result: #{msg}"
          end
          return false
        end
      else
        # Optimized insert for non-cull tests:

        # NB. This uses PostgreSQL-specific generate_series function:
        query = "INSERT INTO qc_results(qc_inspection_test_id, qc_test_id, sample_no)
                select #{qc_inspection_test.id}, #{inspection_type_test.qc_test_id}, sample_no
                from generate_series(1,#{inspection_type_test.sample_size}) x(sample_no)"
        self.connection.execute(query)

        # Insert measurements while bypassing validation:
        query = "INSERT INTO qc_result_measurements(qc_measurement_type_id, qc_result_id, qc_measurement_code, 
                 qc_measurement_description, test_uom, test_criteria, test_method, sample_no)
                 select qc_measurement_types.id, qc_results.id, qc_measurement_types.qc_measurement_code,
                 qc_measurement_types.qc_measurement_description, qc_measurement_types.test_uom,
                 qc_measurement_types.test_criteria, qc_measurement_types.test_method, qc_results.sample_no
                 from qc_measurement_types
                 join qc_results on qc_results.qc_test_id = qc_measurement_types.qc_test_id
                 where qc_measurement_types.qc_test_id = #{inspection_type_test.qc_test_id}
                 and qc_results.qc_inspection_test_id = #{qc_inspection_test.id}"
        self.connection.execute(query)
      end
    end
    true
  end

  # Add samples to a test (qc_result and qc_result_measurements)
  def add_samples( no_samples, from_qc_inspection_test )
    max_old_sample = from_qc_inspection_test.qc_results.find(:first, :select => 'sample_no', :order => 'sample_no DESC').sample_no

    self.qc_inspection_tests.each do |qc_inspection_test|
      inspection_type_test = qc_inspection_test.qc_inspection_type_test
      next if inspection_type_test.cull_test # Doesn't apply to cull tests.

      no_samples.times do |cnt|
        qc_result = QcResult.new( :qc_test_id => inspection_type_test.qc_test_id, :sample_no => max_old_sample + cnt + 1)
        if qc_inspection_test.qc_results << qc_result
          inspection_type_test.qc_test.qc_measurement_types.each do |qc_measurement_type|
            qc_result_measurement = QcResultMeasurement.new( :qc_measurement_type_id => qc_measurement_type.id, :sample_no => max_old_sample + cnt + 1)
            ['qc_measurement_code', 'qc_measurement_description', 'test_uom', 'test_criteria',
             #'test_method', 'measurement', 'annotation_1', 'annotation_2', 'annotation_3'
             'test_method'
            ].each {|a| qc_result_measurement.send(a+'=', qc_measurement_type.attributes[a]) }

            unless qc_result.qc_result_measurements << qc_result_measurement
              qc_result_measurement.errors.each_full do |msg|
                errors.add_to_base "QC Result Measurement: #{msg}"
              end
              raise "Unable to add measurement for extra sample: #{self.errors.full_messages.to_s}"
            end
          end
        else
          qc_result.errors.each_full do |msg|
            errors.add_to_base "QC Result: #{msg}"
          end
          raise "Unable to add result for extra sample: #{self.errors.full_messages.to_s}"
        end
      end
    end
    from_qc_inspection_test.qc_results.find(:all, :conditions => "sample_no > #{max_old_sample}", :order => 'sample_no')
  end

  def all_tests_complete?
    self.qc_inspection_tests.find(:all, :select => 'status').all? {|t| t.status == QcInspectionTest::STATUS_COMPLETED}
  end

  def set_status( new_status )
    self.status = new_status
    self.save!
    if self.status == STATUS_COMPLETED && self.qc_inspection_type.qc_inspection_type_code == 'QTYFS'
      delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("100_fruit_sample_completed",
                                              self.business_object_id)
      raise "Delivery Route Step missing for
            '100_fruit_sample_completed', delivery no
            '#{self.inspection_reference}'." if delivery_route_step.nil?
      delivery_route_step.date_activated = Time.now
      delivery_route_step.date_completed = Time.now
      delivery_route_step.save!
    end
    # History to come later
  end

  def validate
    if !self.passed && self.failed_for_target_market
      tm = TargetMarket.find(:first, :conditions => ['target_market_name = ?', self.failed_target_market])
      self.errors.add(:failed_for_target_market, 'must exist') if tm.nil?
    end
  end

  # Sort out attributes that may have been hidden with values in them.
  def clear_tm
    self.failed_for_target_market = false if self.passed
    self.failed_target_market     = nil unless self.failed_for_target_market
    true
  end

  # To re_edit an inspection, reset its status.
  def revert_complete
    QcInspection.transaction do
      self.set_status STATUS_IN_PROGRESS
    end
  end

end
