class PoolGradedSummary < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================

  belongs_to :production_run
  belongs_to :farm
  has_many   :pool_graded_cartons, :dependent => :destroy
  has_many   :pool_graded_details, :dependent => :destroy
  has_many   :pool_graded_farm_details, :dependent => :destroy
  has_many   :pool_graded_farms, :dependent => :destroy
  has_many   :pool_graded_rebins, :dependent => :destroy
#  has_many   :pool_graded_culls, :dependent => :destroy

  STATUS_IN_PROGRESS = 'GRADING IN PROGRESS'
  STATUS_GRADED      = 'GRADED'
  STATUS_COMPLETE    = 'GRADING COMPLETE'

  QCINSPECTION_TYPE  = 'GGRD'

  # create the PoolGradedSummary, PoolGradedCarton and PoolGradedRebin records.
  def self.create_from( production_run_code )
    # Do bins query for prod run & child to get bin count and mass.
    bin_count, bin_mass = get_bin_count_and_mass( production_run_code )

    production_run = ProductionRun.find_by_production_run_code( production_run_code )
    rmt_setup      = production_run.production_schedule.rmt_setup
    farm           = Farm.find_by_farm_code( production_run.farm_code )
    single_bin     = production_run.tipped_bins.find(:first, :select => 'season_code')

    pool_graded_summary = nil
    PoolGradedSummary.transaction do
			pool_graded_summary = PoolGradedSummary.create(
                                :production_run_id         => production_run.id,
                                :production_run_code       => production_run_code,
                                :production_schedule_name  => production_run.production_schedule_name,
                                :farm_id                   => farm.id,
                                :farm_code                 => farm.farm_code,
                                :commodity_code            => rmt_setup.commodity_code,
                                :season_code               => single_bin.season_code,
                                :bin_count                 => bin_count,
                                :bin_mass                  => bin_mass,
                                :status                    => STATUS_IN_PROGRESS)

			# Set ProductionRun grower grading status to in_progress
			production_run.grower_grading_status = STATUS_IN_PROGRESS
			production_run.save!

			# Then get summary of cartons to create pool_graded_cartons.
      PoolGradedFarm.create_farms_for_summary( pool_graded_summary, production_run_code )

			# Then get summary of cartons to create pool_graded_cartons.
      PoolGradedCarton.create_cartons_for_summary( pool_graded_summary, production_run_code )

			# Then get summary of rebins to create pool_graded_rebins.
      PoolGradedRebin.create_rebins_for_summary( pool_graded_summary, production_run_code )

			# Calculate difference in bin-weight:
			#  = bin mass on summary - (total carton weight + total rebin weight)
      total_carton_weight = pool_graded_summary.pool_graded_cartons.sum(:schedule_weight) || 0.0
      total_rebin_weight  = pool_graded_summary.pool_graded_rebins.sum(:total_rebin_mass) || 0.0
      waste_weight = pool_graded_summary.bin_mass - (total_carton_weight + total_rebin_weight)
			# Create a special pool_graded_rebins record with this value as "WASTE"
      PoolGradedRebin.add_waste_weight( pool_graded_summary, waste_weight ) if waste_weight > 0.0
    end
    pool_graded_summary
  end

  def self.get_bin_count_and_mass( production_run_code )
    query = "SELECT SUM(unioned.bin_count) as bin_count, SUM(unioned.bin_mass) as bin_mass
            FROM (
            SELECT COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
            FROM bins
            JOIN production_runs on production_runs.id = bins.production_run_tipped_id
            WHERE production_runs.production_run_code = '#{production_run_code}'

            UNION ALL

            SELECT COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
            FROM bins
            JOIN production_runs on production_runs.id = bins.production_run_tipped_id
            WHERE production_runs.parent_run_code = '#{production_run_code}'
            ) unioned"

    bins = self.connection.select_all(query)
    return bins[0]['bin_count'], bins[0]['bin_mass']
  end

  # Make sure that all carton and rebin records have had their size and class graded
  # before they can be summarised to PoolGradedDetail.
  # Raises an exception if not ok to summarise.
  def validate_ok_to_summarise( cartons, rebins )
    raise "Cannot summarise yet. Not all cartons have values." if cartons.any? {|rec| rec[0].any? {|r| r.nil? } || rec[1].nil? }
    raise "Cannot summarise yet. Not all rebins have values."  if rebins.any?  {|rec| rec[0].any? {|r| r.nil? } || rec[1].nil? }

    # cull_inspection_type = QcInspectionType.find_by_qc_inspection_type_code(QCINSPECTION_TYPE)
    # cull_inspection = QcInspection.find_by_qc_inspection_type_id_and_business_object_id(cull_inspection_type.id, self.id)
    # raise "Cannot summarise yet. Cull Inspection has not been done."  if cull_inspection.nil?
    # raise "Cannot summarise yet. Cull Test has not been completed."  unless cull_inspection.qc_inspection_tests.first.status == QcInspectionTest::STATUS_COMPLETED
    # tot_counts, population_size = cull_quantity_totals( cull_inspection )
    # raise "Cannot summarise yet. Total of cull measures (#{tot_counts}) does not add up to Inspection population size (#{population_size})." unless tot_counts == population_size

    weight_diff, rebin_weight, carton_weight = calculate_weight_diffs
    raise "Cannot summarise yet. Rebin (#{sprintf('%0.2f', rebin_weight)}) + Carton (#{sprintf('%0.2f', carton_weight)}) weights do not match Bin weight (#{sprintf('%0.2f', self.bin_mass)}). Difference is #{sprintf('%0.2f', weight_diff)}." if weight_diff != 0.0 
  end

  # Check the difference between the total weight of bins and of the total rebins + total cartons.
  # Allow for rounding errors of up to 1.0.
  def calculate_weight_diffs
    weight_diff   = 0.0
    rebin_weight  = self.pool_graded_rebins.sum('graded_weight') || 0.0
    carton_weight = self.pool_graded_cartons.sum('schedule_weight') || 0.0

    weight_diff   = self.bin_mass - (rebin_weight + carton_weight)
    weight_diff   = 0.0 if (weight_diff.abs < 1.0)

    return weight_diff, rebin_weight, carton_weight
  end

  # Is the summary complete?
  def complete?
    STATUS_COMPLETE == self.status
  end

  # Take the PoolGradedCarton and PoolGradedRebin records and summarise into the PoolGradedDetail model.
  # Change the PoolGradedSummary state to GRADED.
  def summarise_to_detail
    return if self.complete?
    cartons = self.pool_graded_cartons.find(:all, :select => 'graded_size, graded_class, schedule_weight').map do |rec|
      [[rec.graded_size, rec.graded_class], rec.schedule_weight]
    end
    rebins  = self.pool_graded_rebins.find(:all, :select => 'graded_size, graded_class, graded_weight').map do |rec|
      [[rec.graded_size, rec.graded_class], rec.graded_weight]
    end

    # First check cartons, rebins & culls
    validate_ok_to_summarise( cartons, rebins )

   # cull_measurements = PoolGradedCull.summarise( self )

    # tot_class_2 = 0.0
    # tot_class_3 = 0.0
    # cull_measurements.each do |cull_measurement|
    #   tot_class_2 += cull_measurement.class_2.to_f || 0.0
    #   tot_class_3 += cull_measurement.class_3.to_f || 0.0
    # end
    # If there is no data for a particular class, this will ensure that the percentage
    # calculation below when creating PoolGradedCull will not return NaN for divide-by-zero error.
    # tot_class_2 = 1.0 if tot_class_2 == 0.0
    # tot_class_3 = 1.0 if tot_class_3 == 0.0

    self.transaction do
      # Delete any existing details first.
      PoolGradedSummary.connection.execute("DELETE FROM pool_graded_details WHERE pool_graded_summary_id = #{self.id}")
      PoolGradedSummary.connection.execute("DELETE FROM pool_graded_farm_details WHERE pool_graded_summary_id = #{self.id}")
#      PoolGradedSummary.connection.execute("DELETE FROM pool_graded_culls WHERE pool_graded_summary_id = #{self.id}")

      details = Hash.new(0.0)
      cartons.each { |rec| details[rec[0]] += rec[1] }
      rebins.each  { |rec| details[rec[0]] += rec[1] }

      details.each do |k,v|
        pd = PoolGradedDetail.new(:graded_size => k[0], :graded_class => k[1], :graded_weight => v, :weight_percentage => weight_percentage( v ) )
        unless self.pool_graded_details << pd
          raise "Unable to create PoolGraded Detail: #{pd.errors.full_messages.join(', ')}"
        end
        self.pool_graded_farms.each do |pool_graded_farm|
          pfd = PoolGradedFarmDetail.new(:pool_graded_farm_id => pool_graded_farm.id,
                                         :graded_size         => pd.graded_size,
                                         :graded_class        => pd.graded_class,
                                         :graded_weight       => pd.graded_weight * pool_graded_farm.pro_rata_factor,
                                         :weight_percentage   => pd.weight_percentage )
          unless self.pool_graded_farm_details << pfd
            raise "Unable to create PoolGraded Farm Detail: #{pfd.errors.full_messages.join(', ')}"
          end
        end
      end
      # cull_measurements.each do |measurement|
      #   pc = PoolGradedCull.new(:description     => measurement.qc_measurement_description,
      #                           :class_2         => measurement.class_2,
      #                           :class_3         => measurement.class_3,
      #                           :class_2_percent => measurement.class_2.to_f / tot_class_2 * 100.0,
      #                           :class_3_percent => measurement.class_3.to_f / tot_class_3 * 100.0 )
      #   unless self.pool_graded_culls << pc
      #     raise "Unable to create PoolGraded Cull: #{pc.errors.full_messages.join(', ')}"
      #   end
      # end
      self.status = STATUS_GRADED
      self.save!
    end
  end

  # Calculate a weight's percentage of the total bin mass.
  def weight_percentage( weight )
    (weight / self.bin_mass) * 100.0
  end

  # Set this PoolGradedSummary status and the ProductionRun grading status to complete.
  def complete_grading
    self.transaction do
      self.status = STATUS_COMPLETE
      self.save!

      # cull_inspection_type = QcInspectionType.find_by_qc_inspection_type_code(QCINSPECTION_TYPE)
      # cull_inspection      = QcInspection.find_by_qc_inspection_type_id_and_business_object_id(cull_inspection_type.id, self.id)
      # cull_inspection.set_status( QcInspection::STATUS_COMPLETED ) unless cull_inspection.status == QcInspection::STATUS_COMPLETED

      self.production_run.grower_grading_status  = STATUS_COMPLETE
      self.production_run.grower_graded_datetime = Time.now
      self.production_run.save!
    end
  end

  # Get the cull inspection related to this PoolGradedSummary.
  # If it does not exist, create it first.
  # def make_or_get_cull( inspection_type, user_name )
  #   qc_inspection_type = QcInspectionType.find_by_qc_inspection_type_code( inspection_type )

  #   qc_inspection = QcInspection.find(:first,
  #                                     :conditions => ['qc_inspection_type_id = ? AND business_object_id = ?',
  #                                       qc_inspection_type.id, self.id])
  #   if qc_inspection.nil?
  #     qc_inspection = QcInspection.new( :qc_inspection_type => qc_inspection_type,
  #                                       :business_object_id => self.id,
  #                                       :population_size    => qc_inspection_type.population_size,
  #                                       :username           => user_name)
  #     unless qc_inspection.create_inspection
  #       raise "Unable to create inspection: #{qc_inspection.errors.full_messages.join(', ')}"
  #     end
  #   end
  #   qc_inspection
  # end

  # Summarise PoolGradedDetail
  def grouped_detail
    # Get the slots:
    size_counts = self.pool_graded_details.find(:all, :select => 'DISTINCT graded_size', :order => 'graded_size').map {|s| s.graded_size }
    size_counts.sort!

    hs = {}
    tots = {:class1 => 0.0, :class2 => 0.0, :class3 => 0.0, :class4 => 0.0, :class1p => 0.0, :class2p => 0.0, :class3p => 0.0, :class4p => 0.0 }
    self.pool_graded_details.each do |pool_graded_detail|
      hs[pool_graded_detail.graded_size] ||= {}
      hs[pool_graded_detail.graded_size]["class#{pool_graded_detail.graded_class}p".to_sym] = pool_graded_detail.weight_percentage
      hs[pool_graded_detail.graded_size]["class#{pool_graded_detail.graded_class}".to_sym]  = pool_graded_detail.graded_weight
      tots["class#{pool_graded_detail.graded_class}p".to_sym] += pool_graded_detail.weight_percentage
      tots["class#{pool_graded_detail.graded_class}".to_sym]  += pool_graded_detail.graded_weight
    end
    # Make an array of sizes with the percentage in each class and the weight value in each class
    ar = Array.new(size_counts.size) {|i| [size_counts[i], sprintf('%0.1f', hs[size_counts[i]][:class1p] || 0.0),
                                                           sprintf('%0.1f', hs[size_counts[i]][:class2p] || 0.0),
                                                           sprintf('%0.1f', hs[size_counts[i]][:class3p] || 0.0),
                                                           sprintf('%0.1f', hs[size_counts[i]][:class4p] || 0.0),
                                                           sprintf('%d', hs[size_counts[i]][:class1] || 0.0),
                                                           sprintf('%d', hs[size_counts[i]][:class2] || 0.0),
                                                           sprintf('%d', hs[size_counts[i]][:class3] || 0.0),
                                                           sprintf('%d', hs[size_counts[i]][:class4] || 0.0)]}
    # Add a total line to the array
    ar << ['Total:', sprintf('%0.1f', tots[:class1p] || 0.0),
                     sprintf('%0.1f', tots[:class2p] || 0.0),
                     sprintf('%0.1f', tots[:class3p] || 0.0),
                     sprintf('%0.1f', tots[:class4p] || 0.0),
                     sprintf('%d', tots[:class1] || 0.0),
                     sprintf('%d', tots[:class2] || 0.0),
                     sprintf('%d', tots[:class3] || 0.0),
                     sprintf('%d', tots[:class4] || 0.0)]
    # Add a line containing the total of all classes - percentage and weight
    ar << ['Grand Total:', (tots[:class1p] || 0.0) + (tots[:class2p] || 0.0) + (tots[:class3p] || 0.0) + (tots[:class4p] || 0.0),
                     (tots[:class1] || 0.0) + (tots[:class2] || 0.0) + (tots[:class3] || 0.0) + (tots[:class4] || 0.0),
                     0,0,0,0,0,0]
  end

  # Return the total of class 2 and class 3 counts and the population size of the QcInspection for comparison.
  # def cull_quantity_totals( cull_inspection )
  #   tot_counts = 0
  #   cull_inspection.qc_inspection_tests.first.qc_results.first.qc_result_measurements.each do |qc_result_measurement|
  #     tot_counts += qc_result_measurement.measurement.to_i
  #   end
  #   return tot_counts, cull_inspection.population_size
  # end

  # Get the default size to be used for rebins from the Commodity.
  def rebins_default_size
    @rebins_default_size ||= begin
      commodity = Commodity.find_by_commodity_code( self.commodity_code )
      if commodity.nil?
        nil
      else
        commodity.rebins_default_size
      end
    end
  end

  def pool_graded_farm_list
    self.pool_graded_farms.map {|farm| farm.farm_code }.join(', ')
  end

end
