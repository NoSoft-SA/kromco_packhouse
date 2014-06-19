class PoolGradedRebin < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================

  belongs_to :pool_graded_summary

  validates_numericality_of :graded_size, :graded_class, :allow_nil => true

  # Create the PoolGradedRebin instances for a PoolGradedSummary given a ProductionRun code.
  def self.create_rebins_for_summary( pool_graded_summary, production_run_code )
    child_codes = ProductionRun.find(:all, :select => 'production_run_code',
                                     :conditions => ['parent_run_code = ?',
                                      production_run_code]).map {|c| c.production_run_code }
    pr_codes = [production_run_code] + child_codes
    query = "SELECT rmt_products.product_class_code, rmt_products.size_code,
             COUNT(bins.*) as rebins_quantity, SUM(bins.weight) as total_rebin_mass
             FROM bins
             JOIN production_runs on production_runs.id = bins.production_run_rebin_id
             JOIN rmt_products ON rmt_products.id = bins.rmt_product_id
             WHERE production_runs.production_run_code IN ('#{pr_codes.join("', '")}' )
               AND bins.rebin_status = 'printed'
               AND (bins.exit_ref IS NULL OR bins.exit_ref <> 'scrapped')
             GROUP BY rmt_products.product_class_code, rmt_products.size_code"
    rebins = PoolGradedRebin.connection.select_all(query)

    rebins.each do |rebin|
      pool_graded_rebin = PoolGradedRebin.new(:class_code => rebin.product_class_code,
                                 :size_code        => rebin.size_code,
                                 :total_rebin_mass => rebin.total_rebin_mass,
                                 :rebins_quantity  => rebin.rebins_quantity,
                                 :graded_class     => rebin.product_class_code[/\d/],
                                 :graded_size      => pool_graded_summary.rebins_default_size,
                                 :graded_weight    => rebin.total_rebin_mass,
                                 :is_split_rebin   => false
                                 )
      pool_graded_summary.pool_graded_rebins << pool_graded_rebin
    end
  end

  # Once the summed weights of cartons and rebins are compared to the
  # summed weight of the tipped bins, any difference is added to the rebins as waste.
  def self.add_waste_weight( pool_graded_summary, waste_weight )
    pool_graded_rebin = PoolGradedRebin.new(:class_code       => 'WASTE',
                               :size_code        => 'UNS',
                               :total_rebin_mass => waste_weight,
                               :rebins_quantity  => 1,
                               :graded_class     => 3,
                               :graded_size      => pool_graded_summary.rebins_default_size,
                               :graded_weight    => waste_weight,
                               :is_split_rebin   => false
                               )
    pool_graded_summary.pool_graded_rebins << pool_graded_rebin
  end

  # A Rebin can be split into two - so that each part can be graded differently.
  def split_rebin
    PoolGradedRebin.transaction do
      pool_graded_rebin = PoolGradedRebin.new(:class_code       => self.class_code.dup,
                                 :size_code        => self.size_code.dup,
                                 :total_rebin_mass => 0.0,
                                 :rebins_quantity  => 0,
                                 :graded_class     => self.graded_class,
                                 :graded_size      => self.graded_size,
                                 :graded_weight    => 0.0,
                                 :is_split_rebin   => true
                                 )
      self.pool_graded_summary.pool_graded_rebins << pool_graded_rebin

      # Reset the summary status.
      self.pool_graded_summary.status = PoolGradedSummary::STATUS_IN_PROGRESS
      self.pool_graded_summary.save!
    end
  end

end
