class PoolGradedFarm < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================


  belongs_to :pool_graded_summary
  belongs_to :farm

  #	============================
  #	 Validations declarations:
  #	============================
  validates_numericality_of :bin_count

  # Create the PoolGradedFarm instances for a PoolGradedSummary given a ProductionRun code.
  # Calculate the total mass from the Bin table for the production run
  # per farm and track slms indicator and create a record for each combination.
  def self.create_farms_for_summary( pool_graded_summary, production_run_code )
    query = "SELECT unioned.farm_id, unioned.farm_code, unioned.track_slms_indicator_code,
            SUM(unioned.bin_count) as bin_count, SUM(unioned.bin_mass) as bin_mass
            FROM (
            SELECT bins.farm_id, farms.farm_code, track_slms_indicators.track_slms_indicator_code,
            COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
            FROM bins
            JOIN farms on farms.id = bins.farm_id
            JOIN track_slms_indicators on track_slms_indicators.id = bins.track_indicator1_id
            JOIN production_runs on production_runs.id = bins.production_run_tipped_id
            WHERE production_runs.production_run_code = '#{production_run_code}'
            GROUP BY bins.farm_id, farms.farm_code, track_slms_indicators.track_slms_indicator_code

            UNION ALL

            SELECT bins.farm_id, farms.farm_code, track_slms_indicators.track_slms_indicator_code,
            COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
            FROM bins
            JOIN farms on farms.id = bins.farm_id
            JOIN track_slms_indicators on track_slms_indicators.id = bins.track_indicator1_id
            JOIN production_runs on production_runs.id = bins.production_run_tipped_id
            WHERE production_runs.parent_run_code = '#{production_run_code}'
            GROUP BY bins.farm_id, farms.farm_code, track_slms_indicators.track_slms_indicator_code
            ) unioned
            GROUP BY unioned.farm_id, unioned.farm_code, unioned.track_slms_indicator_code"

    bins = self.connection.select_all(query)
    bins.each do |bin|
      pool_graded_farm = PoolGradedFarm.new(
                                :farm_id                   => bin['farm_id'],
                                :farm_code                 => bin['farm_code'],
                                :track_slms_indicator_code => bin['track_slms_indicator_code'],
                                :bin_count                 => bin['bin_count'],
                                :bin_mass                  => bin['bin_mass'],
                                :pro_rata_factor           => (bin['bin_mass'].to_f / pool_graded_summary.bin_mass)
      )
      pool_graded_summary.pool_graded_farms << pool_graded_farm
    end
  end

end
