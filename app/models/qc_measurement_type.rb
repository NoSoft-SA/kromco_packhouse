class QcMeasurementType < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================

  belongs_to :qc_test
  has_many   :qc_result_measurements

  validates_presence_of :qc_measurement_code, :qc_measurement_description, :test_uom

  # Possible values can contain queries.
  #NAE 20160229 ADD ANNOTATIONS 4 AND 5
  def fields_not_to_clean
    ['annotation_1_possible_values', 'annotation_2_possible_values', 'annotation_3_possible_values','annotation_4_possible_values','annotation_5_possible_values']
  end

  # Rules for display of measurement and annotations.
  def measurement_rules
    rules = {
      :annotation_1 => {:active => !annotation_1_label.nil? && annotation_1_label.strip != '',
                        :label  => annotation_1_label,
                        :type   => annotation_1_field_type,
                        :values => annotation_1_possible_values},
      :annotation_2 => {:active => !annotation_2_label.nil? && annotation_2_label.strip != '',
                        :label  => annotation_2_label,
                        :type   => annotation_2_field_type,
                        :values => annotation_2_possible_values},
      :annotation_3 => {:active => !annotation_3_label.nil? && annotation_3_label.strip != '',
                        :label  => annotation_3_label,
                        :type   => annotation_3_field_type,
                        :values => annotation_3_possible_values},
      :annotation_4 => {:active => !annotation_4_label.nil? && annotation_4_label.strip != '',
                        :label  => annotation_4_label,
                        :type   => annotation_4_field_type,
                        :values => annotation_4_possible_values},
      :annotation_5=> {:active => !annotation_5_label.nil? && annotation_5_label.strip != '',
                        :label  => annotation_5_label,
                        :type   => annotation_5_field_type,
                        :values => annotation_5_possible_values}			
    }
    # Convert queries to lists
    rules.each do |k,v|
      if v[:active] && v[:values] =~ /^\s*select/i # SQL query
        v[:values] = ActiveRecord::Base.connection.select_all(v[:values]).map{|r| r.values.first}.join(',')
      end
    end
    rules
  end

end
