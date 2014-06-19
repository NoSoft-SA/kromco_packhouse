class PoolGradedCull < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :pool_graded_summary
 
  # Get the QcInspection for a PoolGradedSummary and summarise the cull measurements.
  def self.summarise( pool_graded_summary )
    cull_inspection_type = QcInspectionType.find_by_qc_inspection_type_code(PoolGradedSummary::QCINSPECTION_TYPE)
    cull_inspection      = QcInspection.find_by_qc_inspection_type_id_and_business_object_id(cull_inspection_type.id, pool_graded_summary.id)
    qc_test              = cull_inspection.qc_inspection_tests.find(:first, :conditions => 'cull_test = true')
    qc_result            = qc_test.qc_results.first
    test_tot             = cull_inspection.population_size || 1
    test_tot             = 1 if test_tot == 0
    test_tot             = test_tot.to_f

    query  = "SELECT a.qc_measurement_description, SUM(cast(a.class_2 as integer)) as class_2,
                    SUM(cast(a.class_3 as integer)) as class_3,
                    SUM(cast(a.class_2 as float)) / #{test_tot} * 100 as class_2_p,
                    SUM(cast(a.class_3 as float)) / #{test_tot} * 100 as class_3_p
              FROM (
                SELECT qc_measurement_description,
                  CASE annotation_1
                   WHEN 'Class 2' THEN measurement
                    ELSE '0' END as class_2,
                  CASE annotation_1
                   WHEN 'Class 3' THEN measurement
                    ELSE '0' END as class_3
                FROM qc_result_measurements
                WHERE qc_result_id = #{qc_result.id}
                AND measurement IS NOT NULL
                ) a
              GROUP BY a.qc_measurement_description
              ORDER BY a.qc_measurement_description"
    conn = PoolGradedCull.connection
    conn.select_all(query)
  end

end
