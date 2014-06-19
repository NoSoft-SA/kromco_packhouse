class PoolGradedCarton < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================

  belongs_to :pool_graded_summary

  validates_numericality_of :graded_size, :graded_class, :allow_nil => true

  # Create the PoolGradedCarton instances for a PoolGradedSummary given a ProductionRun code.
  # Creates two sets of instances - one set for Primary Line and another for Secondary Line.
  # Calls make_cartons to insert the records.
  def self.create_cartons_for_summary( pool_graded_summary, production_run_code )
    # 1) Create from parent production run
    primary_cartons = get_cartons( pool_graded_summary, [production_run_code] )
    make_cartons( pool_graded_summary, primary_cartons, 'Primary Line')

    # 2) Create from child runs
    child_codes = ProductionRun.find(:all, :select => 'production_run_code',
                                     :conditions => ['parent_run_code = ?', production_run_code]).map {|c| c.production_run_code }
    unless child_codes.empty?
      secondary_cartons = get_cartons( pool_graded_summary, child_codes )
      make_cartons( pool_graded_summary, secondary_cartons, 'Secondary Line')
    end

  end

  # Get summarised cartons for a given array of ProductionRun codes.
  def self.get_cartons( pool_graded_summary, pr_codes )
    query = " SELECT cartons.actual_size_count_code, cartons.product_class_code, cartons.fg_code_old,
 cartons.variety_short_long, cartons.grade_code, cartons.old_pack_code, cartons.organization_code,
 cartons.inspection_type_code, cartons.target_market_code, cartons.inventory_code,
 item_pack_products.standard_size_count_value,
 SUM(cartons.carton_fruit_nett_mass) as schedule_weight,
 COUNT(cartons.*) as cartons_quantity,
 COUNT(cartons.is_inspection_carton = true) as qty_inspected,
 COUNT(distinct ppecb_inspections.id) as qty_failed
 FROM cartons
 LEFT OUTER JOIN ppecb_inspections ON ppecb_inspections.id = cartons.ppecb_inspection_id
 AND ppecb_inspections.passed = false
 JOIN fg_products on fg_products.fg_product_code = cartons.fg_product_code
 JOIN item_pack_products on item_pack_products.item_pack_product_code = fg_products.item_pack_product_code
 WHERE cartons.production_run_code IN ('#{pr_codes.join("', '")}')
   AND (cartons.exit_ref IS NULL OR cartons.exit_ref = 'Notscrapped')
   AND cartons.pallet_id IS NOT NULL
 GROUP BY cartons.actual_size_count_code, cartons.product_class_code, cartons.fg_code_old,
 cartons.variety_short_long, cartons.grade_code, cartons.old_pack_code, cartons.organization_code,
 cartons.inspection_type_code, cartons.target_market_code, cartons.inventory_code,
 item_pack_products.standard_size_count_value

 ORDER BY cartons.actual_size_count_code, cartons.product_class_code, cartons.fg_code_old,
 cartons.variety_short_long, cartons.grade_code"
    PoolGradedCarton.connection.select_all(query)
  end

  # Create PoolGradedCarton instances and associate them with PoolGradedSummary.
  def self.make_cartons( pool_graded_summary, cartons, line_type )
    cartons.each do |carton|
      pool_graded_carton = PoolGradedCarton.new(:actual_size_count_code => carton.actual_size_count_code,
                                   :product_class_code     => carton.product_class_code,
                                   :fg_code_old            => carton.fg_code_old,
                                   :variety_short_long     => carton.variety_short_long,
                                   :grade_code             => carton.grade_code,
                                   :old_pack_code          => carton.old_pack_code,
                                   :organization_code      => carton.organization_code,
                                   :inspection_type_code   => carton.inspection_type_code,
                                   :target_market_code     => carton.target_market_code,
                                   :inventory_code         => carton.inventory_code,
                                   :schedule_weight        => carton.schedule_weight,
                                   :cartons_quantity       => carton.cartons_quantity.to_i,
                                   :line_type              => line_type,
                                   :graded_size            => carton.standard_size_count_value,
                                   :graded_class           => carton.product_class_code[/\d/], # Grab the first digit in the string, else nil
                                   :qty_not_inspected      => carton.cartons_quantity.to_i - carton.qty_inspected.to_i,
                                   :qty_inspected          => carton.qty_inspected,
                                   :qty_failed             => carton.qty_failed
                                  )
      pool_graded_summary.pool_graded_cartons << pool_graded_carton
    end
  end

end
